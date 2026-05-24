{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application OneNote
}

Program ONENOTE;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Graph
     {$ENDIF};

Procedure InitializeGraphics;
Var
 Driver, Mode: Integer;
 ErrCode: Integer;
Begin
 {$IFDEF FPC}
  Driver:=VGA;
  Mode:=VGAHi;
 {$ELSE}
  Driver:=Detect;
  Mode:=VGAHi;
 {$ENDIF}
 InitGraph(Driver,Mode,'');
 ErrCode:=GraphResult;
 If ErrCode=grOk Then Begin
  SetColor(White);
  SetLineStyle(0,0,1);
 End
  Else
 Begin
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
End;

{$IFNDEF FPC}
 Function MouseDriverFound: Boolean;
 Var
  Regs: Registers;
 Begin
  Regs.AX := 0;
  Intr($33, Regs);
  MouseDriverFound := Regs.AX = $FFFF;
 End;

 Procedure ShowMouse;
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0001;
  Intr($33, Regs);
 End;

 Procedure HideMouse;
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0002;
  Intr($33, Regs);
 End;

 Procedure GetMouseState(Var X, Y, Button: LongInt);
 Var
  Regs: Registers;
 Begin
  Regs.AX := $0003;
  Intr($33, Regs);
  Button := Regs.BX;
  X := Regs.CX;
  Y := Regs.DX;
 End;
{$ELSE}
 Function MouseDriverFound: Boolean;
 Begin
  MouseDriverFound := True;
 End;

 Procedure ShowMouse;
 Begin
  { Pas d'implémentation pour Free Pascal }
 End;

 Procedure HideMouse;
 Begin
  { Pas d'implémentation pour Free Pascal }
 End;
{$ENDIF}

{ ============================================================ }
{ ============   PHASE 1 : CHARPENTE UI + MODELE   ============ }
{ ============================================================ }

Const
 { Resolution VGAHi 640x480 16 couleurs }
 SCR_W              = 640;
 SCR_H              = 480;

 { Disposition verticale }
 MENU_H             = 16;
 TOOL_H             = 28;
 SECTION_H          = 22;
 STATUS_H           = 20;

 { Y de chaque bande }
 MENU_Y0            = 0;
 MENU_Y1            = MENU_Y0 + MENU_H - 1;          { 15 }
 TOOL_Y0            = MENU_H;                        { 16 }
 TOOL_Y1            = TOOL_Y0 + TOOL_H - 1;          { 43 }
 SECTION_Y0         = TOOL_Y1 + 1;                   { 44 }
 SECTION_Y1         = SECTION_Y0 + SECTION_H - 1;    { 65 }
 STATUS_Y0          = SCR_H - STATUS_H;              { 460 }
 STATUS_Y1          = SCR_H - 1;                     { 479 }
 CONTENT_Y0         = SECTION_Y1 + 1;                { 66 }
 CONTENT_Y1         = STATUS_Y0 - 1;                 { 459 }

 { Disposition horizontale }
 PAGELIST_W         = 110;
 PAGELIST_X0        = SCR_W - PAGELIST_W;            { 530 }
 PAGELIST_X1        = SCR_W - 1;                     { 639 }
 NOTE_X0            = 0;
 NOTE_X1            = PAGELIST_X0 - 1;               { 529 }

 { Menus }
 MENU_COUNT         = 7;

 { Toolbar }
 TB_ICON_W          = 22;
 TB_ICON_H          = 22;
 TB_ICON_PAD        = 2;
 TB_GROUP_GAP       = 8;
 TB_X0              = 4;
 TB_Y0              = TOOL_Y0 + 3;
 TB_ICON_COUNT      = 14;

 { Couleurs (palette EGA 16) }
 CLR_MENU_BG        = LightGray;
 CLR_MENU_FG        = Black;
 CLR_MENU_HL_BG     = Blue;
 CLR_MENU_HL_FG     = White;
 CLR_TOOL_BG        = LightGray;
 CLR_TOOL_ICON      = Black;
 CLR_TOOL_HOVER     = Cyan;
 CLR_TOOL_DOWN      = Blue;
 CLR_NOTE_BG        = White;
 CLR_NOTE_RULE      = LightGray;
 CLR_STATUS_BG      = LightGray;
 CLR_STATUS_FG      = Black;
 CLR_SEC_INACT      = LightGray;
 CLR_SEC_ACT_TXT    = White;
 CLR_PAGELIST_BG    = LightGray;
 CLR_PAGE_INACT     = LightGray;
 CLR_PAGE_ACT       = White;

 { Couleurs distinctives des onglets de sections }
 SEC_COLOR_COUNT    = 8;

 { Limites du modele (Phase 1 : minimaux pour la charpente) }
 MAX_SECTIONS       = 32;
 MAX_PAGES          = 64;
 MAX_PARA           = 256;
 MAX_PARA_LEN       = 240;
 SECTION_NAME_LEN   = 24;
 PAGE_TITLE_LEN     = 60;

 { Boutons souris }
 MB_LEFT            = 1;
 MB_RIGHT           = 2;
 MB_MIDDLE          = 4;

 { Etats de menu }
 MS_NONE            = 0;
 MS_DROPDOWN        = 1;

 { Outils courants (Phase 1 : pose-jalon) }
 TT_TEXT            = 0;
 TT_HIGHLIGHT       = 1;
 TT_PEN             = 2;
 TT_ERASER          = 3;
 TT_TAG             = 4;

 { Codes d'action des icones de la toolbar }
 ICN_NEW            = 1;
 ICN_OPEN           = 2;
 ICN_SAVE           = 3;
 ICN_PRINT          = 4;
 ICN_CUT            = 5;
 ICN_COPY           = 6;
 ICN_PASTE          = 7;
 ICN_UNDO           = 8;
 ICN_REDO           = 9;
 ICN_BOLD           = 10;
 ICN_ITALIC         = 11;
 ICN_UNDER          = 12;
 ICN_BULLET         = 13;
 ICN_IMAGE          = 14;

Type
 { Paragraphe simple - sera enrichi en Phase 3 (format) et 4 (containers) }
 TParagraph = Record
  Indent     : Byte;
  Bullet     : Boolean;
  Bold       : Boolean;
  Italic     : Boolean;
  Under      : Boolean;
  Tag        : Byte;     { 0 = aucun }
  Txt        : String[MAX_PARA_LEN];
 End;

 { Page : titre + paragraphes empiles (mode "simple" Phase 1) }
 TPage = Record
  Title      : String[PAGE_TITLE_LEN];
  ParaCount  : Integer;
  Para       : Array[1..MAX_PARA] Of TParagraph;
  CreatedTS  : LongInt;
 End;
 PPage = ^TPage;

 { Section : nom + couleur d'onglet + pages }
 TSection = Record
  Name       : String[SECTION_NAME_LEN];
  Color      : Byte;          { index couleur EGA }
  PageCount  : Integer;
  Pages      : Array[1..MAX_PAGES] Of TPage;
  CurPage    : Integer;
 End;
 PSection = ^TSection;

 { Bloc-notes }
 TNotebook = Record
  Name       : String[64];
  FilePath   : String[255];
  Modified   : Boolean;
  SectionCount: Integer;
  Sections   : Array[1..MAX_SECTIONS] Of TSection;
  CurSection : Integer;
 End;

Var
 { Modele global }
 Book               : TNotebook;

 { Etat UI }
 Language           : (LangFR, LangEN);
 CurrentTool        : Integer;

 { Etat menu deroulant }
 CurrentMenu        : Integer;     { 0 = aucun, 1..MENU_COUNT }
 MenuState          : Integer;
 HoveredMenuItem    : Integer;
 OldHoveredMenuItem : Integer;
 HoveredMenuOnBar   : Integer;
 MenuPositions      : Array[1..MENU_COUNT] Of Integer;
 MenuNamesFR        : Array[1..MENU_COUNT] Of String[16];
 MenuNamesEN        : Array[1..MENU_COUNT] Of String[16];

 { Souris }
 MsX, MsY           : LongInt;
 MsBtn              : LongInt;
 PrevMsX, PrevMsY   : LongInt;
 ToolHover          : Integer;     { index icone survolee, 0 = aucune }
 OldToolHover       : Integer;
 SectionHover       : Integer;     { onglet de section survole }
 PageHover          : Integer;     { ligne de page survolee }

 { Barre d'etat }
 StatusMsg          : String[120];

 { Boucle principale }
 LoopKey            : Char;
 LoopDone           : Boolean;
 ParamFileArg       : String;

 { Couleurs disponibles pour les onglets de sections }
 SecColors          : Array[1..SEC_COLOR_COUNT] Of Byte;

{ ============================================================ }
{ =====================  UTILITAIRES  ========================= }
{ ============================================================ }

Function I2S(L: LongInt): String;
Var S: String;
Begin
 Str(L, S); I2S := S;
End;

Function MinI(A, B: Integer): Integer;
Begin
 If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B: Integer): Integer;
Begin
 If A > B Then MaxI := A Else MaxI := B;
End;

Function UpCase1(C: Char): Char;
Begin
 If (C >= 'a') And (C <= 'z') Then UpCase1 := Char(Ord(C) - 32) Else UpCase1 := C;
End;

Function UpStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do R[I] := UpCase1(R[I]);
 UpStr := R;
End;

Procedure SetStatus(Const S: String);
Begin
 StatusMsg := S;
End;

Function L(Const FR, EN: String): String;
Begin
 If Language = LangFR Then L := FR Else L := EN;
End;

{ ============================================================ }
{ ===============  PRIMITIVES GRAPHIQUES  ==================== }
{ ============================================================ }

Procedure FillRect(X1, Y1, X2, Y2, Col: Integer);
Begin
 SetFillStyle(SolidFill, Col);
 Bar(X1, Y1, X2, Y2);
End;

Procedure FrameRect(X1, Y1, X2, Y2, Col: Integer);
Begin
 SetColor(Col);
 Rectangle(X1, Y1, X2, Y2);
End;

Procedure FrameRect3D(X1, Y1, X2, Y2, HiCol, LoCol: Integer);
Begin
 SetColor(HiCol);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 SetColor(LoCol);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y1, X2, Y2);
End;

Procedure DrawTextAt(X, Y: Integer; Col: Integer; Const S: String);
Begin
 SetColor(Col);
 OutTextXY(X, Y, S);
End;

{ ============================================================ }
{ ============   MODELE : INITIALISATION  ==================== }
{ ============================================================ }

Procedure ClearParagraph(Var P: TParagraph);
Begin
 P.Indent := 0;
 P.Bullet := False;
 P.Bold   := False;
 P.Italic := False;
 P.Under  := False;
 P.Tag    := 0;
 P.Txt    := '';
End;

Procedure ClearPage(Var Pg: TPage);
Var I: Integer;
Begin
 Pg.Title     := '';
 Pg.ParaCount := 0;
 Pg.CreatedTS := 0;
 For I := 1 To MAX_PARA Do ClearParagraph(Pg.Para[I]);
End;

Procedure ClearSection(Var Sec: TSection);
Var I: Integer;
Begin
 Sec.Name      := '';
 Sec.Color     := LightBlue;
 Sec.PageCount := 0;
 Sec.CurPage   := 1;
 For I := 1 To MAX_PAGES Do ClearPage(Sec.Pages[I]);
End;

Procedure AddParagraph(Var Pg: TPage; Const T: String; Bul: Boolean; Ind: Byte);
Begin
 If Pg.ParaCount >= MAX_PARA Then Exit;
 Inc(Pg.ParaCount);
 ClearParagraph(Pg.Para[Pg.ParaCount]);
 Pg.Para[Pg.ParaCount].Txt    := T;
 Pg.Para[Pg.ParaCount].Bullet := Bul;
 Pg.Para[Pg.ParaCount].Indent := Ind;
End;

Procedure InitDefaultNotebook;
Var I, J: Integer; Pg: PPage; Sec: PSection;
Begin
 FillChar(Book, SizeOf(Book), 0);
 Book.Name         := L('Mon bloc-notes', 'My Notebook');
 Book.FilePath     := '';
 Book.Modified     := False;
 Book.CurSection   := 1;
 Book.SectionCount := 3;

 For I := 1 To Book.SectionCount Do Begin
  ClearSection(Book.Sections[I]);
  Sec := @Book.Sections[I];
  Sec^.Color := SecColors[((I - 1) Mod SEC_COLOR_COUNT) + 1];
  Case I Of
   1: Sec^.Name := L('General',  'General');
   2: Sec^.Name := L('Projets',  'Projects');
   3: Sec^.Name := L('Idees',    'Ideas');
  End;
  Sec^.PageCount := 2;
  Sec^.CurPage   := 1;
  For J := 1 To Sec^.PageCount Do Begin
   Pg := @Sec^.Pages[J];
   ClearPage(Pg^);
   Pg^.Title := L('Page ', 'Page ') + I2S(J);
  End;
 End;

 { Quelques paragraphes par defaut sur la premiere page }
 Pg := @Book.Sections[1].Pages[1];
 Pg^.Title := L('Bienvenue', 'Welcome');
 AddParagraph(Pg^, L('Bienvenue dans le clone OneNote.',
                     'Welcome to the OneNote clone.'), False, 0);
 AddParagraph(Pg^, L('Cliquez sur un onglet de section en haut.',
                     'Click a section tab at the top.'), True, 0);
 AddParagraph(Pg^, L('Selectionnez une page a droite.',
                     'Select a page on the right.'), True, 0);
 AddParagraph(Pg^, L('Tapez votre texte ici.',
                     'Type your text here.'), True, 0);
End;

{ ============================================================ }
{ ====================  MENU SYSTEM  ========================== }
{ ============================================================ }

Procedure InitMenuSystem;
Var I, X: Integer;
Begin
 MenuNamesFR[1] := 'Fichier';
 MenuNamesFR[2] := 'Edition';
 MenuNamesFR[3] := 'Insertion';
 MenuNamesFR[4] := 'Format';
 MenuNamesFR[5] := 'Affichage';
 MenuNamesFR[6] := 'Outils';
 MenuNamesFR[7] := 'Aide';

 MenuNamesEN[1] := 'File';
 MenuNamesEN[2] := 'Edit';
 MenuNamesEN[3] := 'Insert';
 MenuNamesEN[4] := 'Format';
 MenuNamesEN[5] := 'View';
 MenuNamesEN[6] := 'Tools';
 MenuNamesEN[7] := 'Help';

 X := 8;
 For I := 1 To MENU_COUNT Do Begin
  MenuPositions[I] := X;
  If Language = LangFR Then
   X := X + Length(MenuNamesFR[I]) * 8 + 12
  Else
   X := X + Length(MenuNamesEN[I]) * 8 + 12;
 End;

 CurrentMenu     := 0;
 MenuState       := MS_NONE;
 HoveredMenuItem := 0;
End;

Function MenuName(I: Integer): String;
Begin
 If Language = LangFR Then MenuName := MenuNamesFR[I]
 Else MenuName := MenuNamesEN[I];
End;

Function GetMenuItemCount(MI: Integer): Integer;
Begin
 Case MI Of
  1: GetMenuItemCount := 14;   { Fichier }
  2: GetMenuItemCount := 10;   { Edition }
  3: GetMenuItemCount := 9;    { Insertion }
  4: GetMenuItemCount := 10;   { Format }
  5: GetMenuItemCount := 8;    { Affichage }
  6: GetMenuItemCount := 6;    { Outils }
  7: GetMenuItemCount := 3;    { Aide }
  Else GetMenuItemCount := 0;
 End;
End;

Function IsMenuSeparator(MI, II: Integer): Boolean;
Begin
 Case MI Of
  1: IsMenuSeparator := (II = 4) Or (II = 7) Or (II = 11) Or (II = 13);
  2: IsMenuSeparator := (II = 3) Or (II = 8);
  3: IsMenuSeparator := (II = 4) Or (II = 7);
  4: IsMenuSeparator := (II = 4) Or (II = 7);
  5: IsMenuSeparator := (II = 4) Or (II = 6);
  6: IsMenuSeparator := (II = 3);
  7: IsMenuSeparator := (II = 2);
  Else IsMenuSeparator := False;
 End;
End;

Procedure GetMenuItem(MI, II: Integer; Var Label_, Sc: String);
Begin
 Label_ := '-'; Sc := '';
 Case MI Of
  1: Begin { Fichier / File }
      Case II Of
       1:  Begin Label_ := L('Nouveau bloc-notes', 'New Notebook');     Sc := 'Ctrl+N'; End;
       2:  Begin Label_ := L('Ouvrir...',          'Open...');           Sc := 'Ctrl+O'; End;
       3:  Begin Label_ := L('Fermer',             'Close');             Sc := 'Ctrl+W'; End;
       5:  Begin Label_ := L('Enregistrer',        'Save');              Sc := 'Ctrl+S'; End;
       6:  Begin Label_ := L('Enregistrer sous...','Save As...');        Sc := 'F12';    End;
       8:  Begin Label_ := L('Importer .ONE...',   'Import .ONE...');    Sc := '';       End;
       9:  Begin Label_ := L('Exporter .ONEPKG...','Export .ONEPKG...'); Sc := '';       End;
       10: Begin Label_ := L('Exporter .ONETOC2...','Export .ONETOC2...');Sc:= '';       End;
       12: Begin Label_ := L('Imprimer...',        'Print...');          Sc := 'Ctrl+P'; End;
       14: Begin Label_ := L('Quitter',            'Exit');              Sc := 'Alt+F4'; End;
      End;
     End;
  2: Begin { Edition / Edit }
      Case II Of
       1:  Begin Label_ := L('Annuler',     'Undo');           Sc := 'Ctrl+Z'; End;
       2:  Begin Label_ := L('Retablir',    'Redo');           Sc := 'Ctrl+Y'; End;
       4:  Begin Label_ := L('Couper',      'Cut');            Sc := 'Ctrl+X'; End;
       5:  Begin Label_ := L('Copier',      'Copy');           Sc := 'Ctrl+C'; End;
       6:  Begin Label_ := L('Coller',      'Paste');          Sc := 'Ctrl+V'; End;
       7:  Begin Label_ := L('Supprimer',   'Delete');         Sc := 'Suppr';  End;
       9:  Begin Label_ := L('Rechercher...','Find...');       Sc := 'Ctrl+F'; End;
       10: Begin Label_ := L('Remplacer...','Replace...');     Sc := 'Ctrl+H'; End;
      End;
     End;
  3: Begin { Insertion / Insert }
      Case II Of
       1:  Begin Label_ := L('Nouvelle page',    'New Page');     Sc := 'Ctrl+M'; End;
       2:  Begin Label_ := L('Nouvelle section', 'New Section');  Sc := '';       End;
       3:  Begin Label_ := L('Container',        'Container');    Sc := '';       End;
       5:  Begin Label_ := L('Image...',         'Picture...');   Sc := '';       End;
       6:  Begin Label_ := L('Tableau',          'Table');        Sc := 'Ctrl+T'; End;
       8:  Begin Label_ := L('Date/Heure',       'Date/Time');    Sc := 'Alt+Maj+D'; End;
       9:  Begin Label_ := L('Etiquette (Tag)',  'Tag');          Sc := 'Ctrl+1'; End;
      End;
     End;
  4: Begin { Format }
      Case II Of
       1:  Begin Label_ := L('Gras',         'Bold');         Sc := 'Ctrl+B'; End;
       2:  Begin Label_ := L('Italique',     'Italic');       Sc := 'Ctrl+I'; End;
       3:  Begin Label_ := L('Souligne',     'Underline');    Sc := 'Ctrl+U'; End;
       5:  Begin Label_ := L('Puce',         'Bullet');       Sc := 'Ctrl+.'; End;
       6:  Begin Label_ := L('Numerotation', 'Numbering');    Sc := 'Ctrl+/'; End;
       8:  Begin Label_ := L('Augmenter retrait', 'Increase Indent'); Sc := 'Tab'; End;
       9:  Begin Label_ := L('Diminuer retrait',  'Decrease Indent'); Sc := 'Maj+Tab'; End;
       10: Begin Label_ := L('Style de page...',  'Page Style...');   Sc := ''; End;
      End;
     End;
  5: Begin { Affichage / View }
      Case II Of
       1:  Begin Label_ := L('Section precedente','Prev Section');   Sc := 'Ctrl+PgUp'; End;
       2:  Begin Label_ := L('Section suivante',  'Next Section');   Sc := 'Ctrl+PgDn'; End;
       3:  Begin Label_ := L('Liste pages',       'Page List');      Sc := ''; End;
       5:  Begin Label_ := L('Plein ecran',       'Full Screen');    Sc := 'F11'; End;
       7:  Begin Label_ := L('Zoom +',            'Zoom In');        Sc := 'Ctrl++'; End;
       8:  Begin Label_ := L('Zoom -',            'Zoom Out');       Sc := 'Ctrl+-'; End;
      End;
     End;
  6: Begin { Outils / Tools }
      Case II Of
       1:  Begin Label_ := L('Orthographe',  'Spell Check'); Sc := 'F7'; End;
       2:  Begin Label_ := L('Recherche...', 'Search...');   Sc := 'Ctrl+E'; End;
       4:  Begin Label_ := L('Langue (FR/EN)','Language (FR/EN)'); Sc := ''; End;
       5:  Begin Label_ := L('Preferences...','Preferences...'); Sc := ''; End;
       6:  Begin Label_ := L('Mot de passe...','Password...'); Sc := ''; End;
      End;
     End;
  7: Begin { Aide / Help }
      Case II Of
       1:  Begin Label_ := L('Sommaire',      'Contents');    Sc := 'F1'; End;
       3:  Begin Label_ := L('A propos...',   'About...');    Sc := ''; End;
      End;
     End;
 End;
End;

Function GetMenuAtPosition(X, Y: LongInt): Integer;
Var I, W: Integer;
Begin
 GetMenuAtPosition := 0;
 If (Y < 0) Or (Y > MENU_Y1) Then Exit;
 For I := 1 To MENU_COUNT Do Begin
  W := Length(MenuName(I)) * 8;
  If (X >= MenuPositions[I] - 4) And (X <= MenuPositions[I] + W + 4) Then Begin
   GetMenuAtPosition := I; Exit;
  End;
 End;
End;

Function GetDropDownItemAtPosition(MI: Integer; X, Y: LongInt): Integer;
Const ITEM_H = 14;
Var I, Cnt, MenuX, MenuY, MW: Integer;
Begin
 GetDropDownItemAtPosition := 0;
 Cnt := GetMenuItemCount(MI);
 If Cnt <= 0 Then Exit;
 MenuX := MenuPositions[MI] - 4;
 MenuY := MENU_Y1 + 1;
 MW    := 230;
 If (X < MenuX) Or (X > MenuX + MW) Then Exit;
 If (Y <= MenuY) Or (Y > MenuY + Cnt * ITEM_H) Then Exit;
 I := ((Y - MenuY - 1) Div ITEM_H) + 1;
 If (I < 1) Or (I > Cnt) Then Exit;
 GetDropDownItemAtPosition := I;
End;

{ ============================================================ }
{ ====================  ICONES VECTORIELLES  ================== }
{ ============================================================ }

Procedure DrawIcon_New(X, Y, C: Integer);
Begin
 SetColor(C);
 { Page avec coin plie }
 Rectangle(X+4, Y+2, X+15, Y+18);
 Line(X+11, Y+2, X+15, Y+6);
 Line(X+11, Y+2, X+11, Y+6);
 Line(X+11, Y+6, X+15, Y+6);
 { Petites lignes de texte }
 Line(X+6, Y+10, X+13, Y+10);
 Line(X+6, Y+13, X+13, Y+13);
 Line(X+6, Y+16, X+11, Y+16);
End;

Procedure DrawIcon_Open(X, Y, C: Integer);
Begin
 SetColor(C);
 { Dossier ouvert }
 Line(X+2, Y+6,  X+8, Y+6);
 Line(X+8, Y+6,  X+10, Y+8);
 Line(X+10, Y+8, X+18, Y+8);
 Line(X+18, Y+8, X+18, Y+17);
 Line(X+2, Y+6,  X+2, Y+17);
 Line(X+2, Y+17, X+18, Y+17);
 Line(X+2, Y+9,  X+18, Y+9);
End;

Procedure DrawIcon_Save(X, Y, C: Integer);
Begin
 SetColor(C);
 { Disquette }
 Rectangle(X+3, Y+3, X+17, Y+18);
 Rectangle(X+6, Y+3, X+14, Y+8);
 Line(X+12, Y+4, X+12, Y+7);
 Rectangle(X+5, Y+11, X+15, Y+17);
End;

Procedure DrawIcon_Print(X, Y, C: Integer);
Begin
 SetColor(C);
 { Imprimante : feuille en haut, corps, sortie }
 Rectangle(X+5, Y+2, X+15, Y+7);
 Rectangle(X+2, Y+7, X+18, Y+14);
 Rectangle(X+5, Y+14, X+15, Y+18);
 Line(X+5, Y+16, X+15, Y+16);
End;

Procedure DrawIcon_Cut(X, Y, C: Integer);
Begin
 SetColor(C);
 { Ciseaux : deux cercles + lignes croisees }
 Circle(X+5, Y+15, 3);
 Circle(X+15, Y+15, 3);
 Line(X+7, Y+13, X+15, Y+3);
 Line(X+13, Y+13, X+5, Y+3);
End;

Procedure DrawIcon_Copy(X, Y, C: Integer);
Begin
 SetColor(C);
 { Deux pages superposees }
 Rectangle(X+3, Y+3, X+12, Y+14);
 Rectangle(X+7, Y+7, X+17, Y+18);
End;

Procedure DrawIcon_Paste(X, Y, C: Integer);
Begin
 SetColor(C);
 { Presse-papier }
 Rectangle(X+4, Y+4, X+16, Y+18);
 Rectangle(X+7, Y+2, X+13, Y+6);
 Line(X+6, Y+8, X+14, Y+8);
 Line(X+6, Y+11, X+14, Y+11);
 Line(X+6, Y+14, X+12, Y+14);
End;

Procedure DrawIcon_Undo(X, Y, C: Integer);
Begin
 SetColor(C);
 { Fleche en arc qui revient en arriere }
 Arc(X+12, Y+12, 0, 180, 7);
 Line(X+5, Y+12, X+5, Y+8);
 Line(X+5, Y+12, X+9, Y+12);
End;

Procedure DrawIcon_Redo(X, Y, C: Integer);
Begin
 SetColor(C);
 { Fleche en arc vers l'avant }
 Arc(X+8, Y+12, 0, 180, 7);
 Line(X+15, Y+12, X+15, Y+8);
 Line(X+15, Y+12, X+11, Y+12);
End;

Procedure DrawIcon_Bold(X, Y, C: Integer);
Begin
 SetColor(C);
 OutTextXY(X+6, Y+5, 'B');
 OutTextXY(X+7, Y+5, 'B');   { double-frappe pour effet gras }
End;

Procedure DrawIcon_Italic(X, Y, C: Integer);
Begin
 SetColor(C);
 OutTextXY(X+7, Y+5, 'I');
 Line(X+6, Y+15, X+12, Y+15);
 Line(X+8, Y+5, X+14, Y+5);
End;

Procedure DrawIcon_Under(X, Y, C: Integer);
Begin
 SetColor(C);
 OutTextXY(X+7, Y+4, 'U');
 Line(X+5, Y+16, X+15, Y+16);
End;

Procedure DrawIcon_Bullet(X, Y, C: Integer);
Var I, YY: Integer;
Begin
 SetColor(C);
 For I := 0 To 2 Do Begin
  YY := Y + 4 + I * 5;
  Circle(X+5, YY+1, 1);
  Line(X+9, YY+1, X+16, YY+1);
 End;
End;

Procedure DrawIcon_Image(X, Y, C: Integer);
Begin
 SetColor(C);
 { Cadre + soleil + montagne }
 Rectangle(X+2, Y+3, X+18, Y+17);
 Circle(X+6, Y+7, 2);
 Line(X+8, Y+15, X+12, Y+9);
 Line(X+12, Y+9, X+17, Y+15);
End;

Procedure DrawIconByIndex(Idx, X, Y, C: Integer);
Begin
 Case Idx Of
  ICN_NEW    : DrawIcon_New(X, Y, C);
  ICN_OPEN   : DrawIcon_Open(X, Y, C);
  ICN_SAVE   : DrawIcon_Save(X, Y, C);
  ICN_PRINT  : DrawIcon_Print(X, Y, C);
  ICN_CUT    : DrawIcon_Cut(X, Y, C);
  ICN_COPY   : DrawIcon_Copy(X, Y, C);
  ICN_PASTE  : DrawIcon_Paste(X, Y, C);
  ICN_UNDO   : DrawIcon_Undo(X, Y, C);
  ICN_REDO   : DrawIcon_Redo(X, Y, C);
  ICN_BOLD   : DrawIcon_Bold(X, Y, C);
  ICN_ITALIC : DrawIcon_Italic(X, Y, C);
  ICN_UNDER  : DrawIcon_Under(X, Y, C);
  ICN_BULLET : DrawIcon_Bullet(X, Y, C);
  ICN_IMAGE  : DrawIcon_Image(X, Y, C);
 End;
End;

Function IconX(Idx: Integer): Integer;
Var X, I: Integer;
Begin
 X := TB_X0;
 For I := 1 To Idx - 1 Do Begin
  X := X + TB_ICON_W + TB_ICON_PAD;
  { Espaces de groupe : apres impression(4), apres coller(7), apres redo(9), apres bullet(13) }
  If (I = 4) Or (I = 7) Or (I = 9) Or (I = 13) Then X := X + TB_GROUP_GAP;
 End;
 IconX := X;
End;

Function FindIconAtPosition(X, Y: LongInt): Integer;
Var I, XX: Integer;
Begin
 FindIconAtPosition := 0;
 If (Y < TOOL_Y0) Or (Y > TOOL_Y1) Then Exit;
 For I := 1 To TB_ICON_COUNT Do Begin
  XX := IconX(I);
  If (X >= XX) And (X < XX + TB_ICON_W) And
     (Y >= TB_Y0) And (Y < TB_Y0 + TB_ICON_H) Then Begin
   FindIconAtPosition := I; Exit;
  End;
 End;
End;

Function IconLabel(I: Integer): String;
Begin
 Case I Of
  ICN_NEW    : IconLabel := L('Nouveau',     'New');
  ICN_OPEN   : IconLabel := L('Ouvrir',      'Open');
  ICN_SAVE   : IconLabel := L('Enregistrer', 'Save');
  ICN_PRINT  : IconLabel := L('Imprimer',    'Print');
  ICN_CUT    : IconLabel := L('Couper',      'Cut');
  ICN_COPY   : IconLabel := L('Copier',      'Copy');
  ICN_PASTE  : IconLabel := L('Coller',      'Paste');
  ICN_UNDO   : IconLabel := L('Annuler',     'Undo');
  ICN_REDO   : IconLabel := L('Retablir',    'Redo');
  ICN_BOLD   : IconLabel := L('Gras',        'Bold');
  ICN_ITALIC : IconLabel := L('Italique',    'Italic');
  ICN_UNDER  : IconLabel := L('Souligne',    'Underline');
  ICN_BULLET : IconLabel := L('Puce',        'Bullet');
  ICN_IMAGE  : IconLabel := L('Image',       'Picture');
  Else IconLabel := '';
 End;
End;

{ ============================================================ }
{ ====================  RENDERING  ============================ }
{ ============================================================ }

Procedure DrawMenuBar;
Var I, TX, TW: Integer;
Begin
 FillRect(0, MENU_Y0, SCR_W - 1, MENU_Y1, CLR_MENU_BG);
 SetColor(DarkGray);
 Line(0, MENU_Y1, SCR_W - 1, MENU_Y1);

 For I := 1 To MENU_COUNT Do Begin
  TX := MenuPositions[I];
  TW := Length(MenuName(I)) * 8;
  If (I = CurrentMenu) And (MenuState = MS_DROPDOWN) Then Begin
   FillRect(TX - 4, MENU_Y0 + 1, TX + TW + 4, MENU_Y1 - 1, CLR_MENU_HL_BG);
   DrawTextAt(TX, MENU_Y0 + 4, CLR_MENU_HL_FG, MenuName(I));
  End
  Else Begin
   DrawTextAt(TX, MENU_Y0 + 4, CLR_MENU_FG, MenuName(I));
  End;
 End;
End;

Procedure DrawDropDownMenu(MI: Integer);
Const ITEM_H = 14;
Var Cnt, I, MenuX, MenuY, MW: Integer;
    Label_, Sc: String;
Begin
 Cnt := GetMenuItemCount(MI);
 If Cnt <= 0 Then Exit;
 MenuX := MenuPositions[MI] - 4;
 MenuY := MENU_Y1 + 1;
 MW    := 230;

 { Fond + cadre 3D }
 FillRect(MenuX, MenuY, MenuX + MW, MenuY + Cnt * ITEM_H, CLR_MENU_BG);
 FrameRect3D(MenuX, MenuY, MenuX + MW, MenuY + Cnt * ITEM_H, White, DarkGray);

 For I := 1 To Cnt Do Begin
  GetMenuItem(MI, I, Label_, Sc);
  If IsMenuSeparator(MI, I) Then Begin
   SetColor(DarkGray);
   Line(MenuX + 4, MenuY + I * ITEM_H - ITEM_H Div 2,
        MenuX + MW - 4, MenuY + I * ITEM_H - ITEM_H Div 2);
  End
  Else Begin
   If I = HoveredMenuItem Then Begin
    FillRect(MenuX + 2, MenuY + (I-1) * ITEM_H + 1,
             MenuX + MW - 2, MenuY + I * ITEM_H,
             CLR_MENU_HL_BG);
    DrawTextAt(MenuX + 8, MenuY + (I-1) * ITEM_H + 3, CLR_MENU_HL_FG, Label_);
    If Sc <> '' Then
     DrawTextAt(MenuX + MW - Length(Sc) * 8 - 6, MenuY + (I-1) * ITEM_H + 3,
                CLR_MENU_HL_FG, Sc);
   End
   Else Begin
    DrawTextAt(MenuX + 8, MenuY + (I-1) * ITEM_H + 3, CLR_MENU_FG, Label_);
    If Sc <> '' Then
     DrawTextAt(MenuX + MW - Length(Sc) * 8 - 6, MenuY + (I-1) * ITEM_H + 3,
                DarkGray, Sc);
   End;
  End;
 End;
End;

Procedure DrawToolbar;
Var I, X: Integer; BgC: Integer;
Begin
 FillRect(0, TOOL_Y0, SCR_W - 1, TOOL_Y1, CLR_TOOL_BG);
 SetColor(DarkGray);
 Line(0, TOOL_Y1, SCR_W - 1, TOOL_Y1);

 For I := 1 To TB_ICON_COUNT Do Begin
  X := IconX(I);
  If I = ToolHover Then BgC := CLR_TOOL_HOVER Else BgC := CLR_TOOL_BG;
  FillRect(X, TB_Y0, X + TB_ICON_W - 1, TB_Y0 + TB_ICON_H - 1, BgC);
  If I = ToolHover Then
   FrameRect3D(X, TB_Y0, X + TB_ICON_W - 1, TB_Y0 + TB_ICON_H - 1, White, DarkGray);
  DrawIconByIndex(I, X, TB_Y0, CLR_TOOL_ICON);
 End;
End;

Procedure DrawSectionTabs;
Var I, X, W, TW: Integer; Sec: PSection;
Begin
 FillRect(0, SECTION_Y0, SCR_W - 1, SECTION_Y1, LightGray);
 SetColor(DarkGray);
 Line(0, SECTION_Y1, SCR_W - 1, SECTION_Y1);

 X := 4;
 For I := 1 To Book.SectionCount Do Begin
  Sec := @Book.Sections[I];
  W := Length(Sec^.Name) * 8 + 16;
  If I = Book.CurSection Then Begin
   { Onglet actif : couleur pleine + texte blanc }
   FillRect(X, SECTION_Y0 + 2, X + W, SECTION_Y1, Sec^.Color);
   FrameRect3D(X, SECTION_Y0 + 2, X + W, SECTION_Y1, White, Black);
   DrawTextAt(X + 8, SECTION_Y0 + 7, CLR_SEC_ACT_TXT, Sec^.Name);
  End
  Else Begin
   { Onglet inactif : bande de couleur fine en haut, texte noir }
   FillRect(X, SECTION_Y0 + 5, X + W, SECTION_Y1, CLR_SEC_INACT);
   FillRect(X, SECTION_Y0 + 2, X + W, SECTION_Y0 + 4, Sec^.Color);
   FrameRect(X, SECTION_Y0 + 2, X + W, SECTION_Y1, DarkGray);
   DrawTextAt(X + 8, SECTION_Y0 + 7, CLR_MENU_FG, Sec^.Name);
  End;
  X := X + W + 2;
  If X > SCR_W - 80 Then Break;
 End;

 { Bouton + (nouvelle section) }
 TW := 18;
 If X + TW < SCR_W - 4 Then Begin
  FillRect(X, SECTION_Y0 + 5, X + TW, SECTION_Y1 - 2, LightGray);
  FrameRect3D(X, SECTION_Y0 + 5, X + TW, SECTION_Y1 - 2, White, DarkGray);
  DrawTextAt(X + 6, SECTION_Y0 + 8, Black, '+');
 End;
End;

Procedure DrawPageList;
Var Sec: PSection; I, Y, Cnt: Integer; T: String;
Const PAGE_H = 22;
Begin
 FillRect(PAGELIST_X0, CONTENT_Y0, PAGELIST_X1, CONTENT_Y1, CLR_PAGELIST_BG);
 SetColor(DarkGray);
 Line(PAGELIST_X0, CONTENT_Y0, PAGELIST_X0, CONTENT_Y1);

 { En-tete }
 DrawTextAt(PAGELIST_X0 + 6, CONTENT_Y0 + 4, Black, L('Pages', 'Pages'));
 SetColor(DarkGray);
 Line(PAGELIST_X0 + 2, CONTENT_Y0 + 16, PAGELIST_X1 - 2, CONTENT_Y0 + 16);

 If (Book.CurSection < 1) Or (Book.CurSection > Book.SectionCount) Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 Cnt := Sec^.PageCount;

 For I := 1 To Cnt Do Begin
  Y := CONTENT_Y0 + 20 + (I - 1) * PAGE_H;
  If Y + PAGE_H > CONTENT_Y1 Then Break;
  If I = Sec^.CurPage Then Begin
   FillRect(PAGELIST_X0 + 2, Y, PAGELIST_X1 - 2, Y + PAGE_H - 2, CLR_PAGE_ACT);
   FrameRect(PAGELIST_X0 + 2, Y, PAGELIST_X1 - 2, Y + PAGE_H - 2, Sec^.Color);
  End
  Else If I = PageHover Then Begin
   FillRect(PAGELIST_X0 + 2, Y, PAGELIST_X1 - 2, Y + PAGE_H - 2, Cyan);
  End;
  T := Sec^.Pages[I].Title;
  If T = '' Then T := L('(sans titre)', '(untitled)');
  If Length(T) > 12 Then T := Copy(T, 1, 11) + '.';
  DrawTextAt(PAGELIST_X0 + 6, Y + 6, Black, T);
 End;

 { Bouton "+ Ajouter une page" }
 Y := CONTENT_Y0 + 20 + Cnt * PAGE_H;
 If Y + 18 < CONTENT_Y1 Then Begin
  DrawTextAt(PAGELIST_X0 + 6, Y + 2, Blue, '+ ' + L('Page', 'Page'));
 End;
End;

Procedure DrawNoteArea;
Var Sec: PSection; Pg: PPage; I, Y, X: Integer; P: TParagraph;
    LeftMargin, LineH: Integer; T: String;
Begin
 FillRect(NOTE_X0, CONTENT_Y0, NOTE_X1, CONTENT_Y1, CLR_NOTE_BG);

 If (Book.CurSection < 1) Or (Book.CurSection > Book.SectionCount) Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (Sec^.CurPage > Sec^.PageCount) Then Exit;
 Pg := @Sec^.Pages[Sec^.CurPage];

 LeftMargin := NOTE_X0 + 24;
 LineH := 14;

 { Titre }
 T := Pg^.Title;
 If T = '' Then T := L('(Titre de la page)', '(Page title)');
 DrawTextAt(LeftMargin, CONTENT_Y0 + 12, Black, T);
 SetColor(DarkGray);
 Line(LeftMargin, CONTENT_Y0 + 28, NOTE_X1 - 24, CONTENT_Y0 + 28);
 { Date }
 DrawTextAt(LeftMargin, CONTENT_Y0 + 32, DarkGray,
            L('Cree : ', 'Created: ') + L('aujourd''hui', 'today'));

 Y := CONTENT_Y0 + 56;
 For I := 1 To Pg^.ParaCount Do Begin
  P := Pg^.Para[I];
  X := LeftMargin + P.Indent * 16;
  If P.Bullet Then Begin
   SetColor(Black);
   Circle(X + 4, Y + 4, 2);
   FillEllipse(X + 4, Y + 4, 2, 2);
   X := X + 14;
  End;
  DrawTextAt(X, Y, Black, P.Txt);
  Y := Y + LineH;
  If Y > CONTENT_Y1 - LineH Then Break;
 End;
End;

Procedure DrawStatusBar;
Var Sec: PSection; Pg: PPage; Info, Modi: String;
Begin
 FillRect(0, STATUS_Y0, SCR_W - 1, STATUS_Y1, CLR_STATUS_BG);
 SetColor(DarkGray);
 Line(0, STATUS_Y0, SCR_W - 1, STATUS_Y0);

 If (Book.CurSection >= 1) And (Book.CurSection <= Book.SectionCount) Then Begin
  Sec := @Book.Sections[Book.CurSection];
  Info := Book.Name + ' > ' + Sec^.Name;
  If (Sec^.CurPage >= 1) And (Sec^.CurPage <= Sec^.PageCount) Then Begin
   Pg := @Sec^.Pages[Sec^.CurPage];
   Info := Info + ' > ' + Pg^.Title;
  End;
 End
 Else Info := Book.Name;

 If Book.Modified Then Modi := ' [*] ' Else Modi := ' ';

 DrawTextAt(6, STATUS_Y0 + 6, CLR_STATUS_FG, Info + Modi);
 If StatusMsg <> '' Then
  DrawTextAt(SCR_W Div 2, STATUS_Y0 + 6, Blue, StatusMsg);
End;

Procedure RefreshScreen;
Begin
 HideMouse;
 DrawMenuBar;
 DrawToolbar;
 DrawSectionTabs;
 DrawNoteArea;
 DrawPageList;
 DrawStatusBar;
 If (MenuState = MS_DROPDOWN) And (CurrentMenu > 0) Then
  DrawDropDownMenu(CurrentMenu);
 ShowMouse;
End;

{ ============================================================ }
{ ===============  ACTIONS (stubs Phase 1)  =================== }
{ ============================================================ }

Procedure FileNew;
Begin
 InitDefaultNotebook;
 SetStatus(L('Nouveau bloc-notes cree', 'New notebook created'));
End;

Procedure FileOpen;
Begin
 SetStatus(L('Ouvrir : a implementer en Phase 5/8', 'Open: see Phase 5/8'));
End;

Procedure FileClose;
Begin
 SetStatus(L('Fermer : a implementer', 'Close: TBD'));
End;

Procedure FileSave;
Begin
 SetStatus(L('Enregistrer : Phase 7 (.ONE)', 'Save: Phase 7 (.ONE)'));
End;

Procedure FileSaveAs;
Begin
 SetStatus(L('Enregistrer sous : Phase 5/7', 'Save As: Phase 5/7'));
End;

Procedure FileImportONE;
Begin
 SetStatus(L('Importer .ONE : Phase 8', 'Import .ONE: Phase 8'));
End;

Procedure FileExportPKG;
Begin
 SetStatus(L('Exporter .ONEPKG : Phase 10', 'Export .ONEPKG: Phase 10'));
End;

Procedure FileExportTOC;
Begin
 SetStatus(L('Exporter .ONETOC2 : Phase 9', 'Export .ONETOC2: Phase 9'));
End;

Procedure FilePrint;
Begin
 SetStatus(L('Imprimer : a implementer', 'Print: TBD'));
End;

Function FileExit: Boolean;
Begin
 FileExit := True;   { signal au main loop }
End;

Procedure EditUndo;     Begin SetStatus(L('Annuler', 'Undo')); End;
Procedure EditRedo;     Begin SetStatus(L('Retablir', 'Redo')); End;
Procedure EditCut;      Begin SetStatus(L('Couper', 'Cut')); End;
Procedure EditCopy;     Begin SetStatus(L('Copier', 'Copy')); End;
Procedure EditPaste;    Begin SetStatus(L('Coller', 'Paste')); End;
Procedure EditDelete;   Begin SetStatus(L('Supprimer', 'Delete')); End;
Procedure EditFind;     Begin SetStatus(L('Rechercher', 'Find')); End;
Procedure EditReplace;  Begin SetStatus(L('Remplacer', 'Replace')); End;

Procedure InsertPage;
Var Sec: PSection; Pg: PPage;
Begin
 If Book.CurSection < 1 Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If Sec^.PageCount >= MAX_PAGES Then Begin
  SetStatus(L('Nombre max de pages atteint', 'Max pages reached')); Exit;
 End;
 Inc(Sec^.PageCount);
 Pg := @Sec^.Pages[Sec^.PageCount];
 ClearPage(Pg^);
 Pg^.Title := L('Sans titre', 'Untitled');
 Sec^.CurPage := Sec^.PageCount;
 Book.Modified := True;
 SetStatus(L('Page ajoutee', 'Page added'));
End;

Procedure InsertSection;
Var Sec: PSection;
Begin
 If Book.SectionCount >= MAX_SECTIONS Then Begin
  SetStatus(L('Max sections atteint', 'Max sections reached')); Exit;
 End;
 Inc(Book.SectionCount);
 Sec := @Book.Sections[Book.SectionCount];
 ClearSection(Sec^);
 Sec^.Name := L('Section ', 'Section ') + I2S(Book.SectionCount);
 Sec^.Color := SecColors[((Book.SectionCount - 1) Mod SEC_COLOR_COUNT) + 1];
 Sec^.PageCount := 1;
 Sec^.CurPage   := 1;
 Sec^.Pages[1].Title := L('Sans titre', 'Untitled');
 Book.CurSection := Book.SectionCount;
 Book.Modified := True;
 SetStatus(L('Section ajoutee', 'Section added'));
End;

Procedure InsertContainer;
Begin SetStatus(L('Container : Phase 4', 'Container: Phase 4')); End;

Procedure InsertImage;
Begin SetStatus(L('Image : Phase 6', 'Picture: Phase 6')); End;

Procedure InsertTable;
Begin SetStatus(L('Tableau : Phase 12', 'Table: Phase 12')); End;

Procedure InsertDateTime;
Begin SetStatus(L('Date/Heure : a implementer', 'Date/Time: TBD')); End;

Procedure InsertTag;
Begin SetStatus(L('Tag : Phase 3', 'Tag: Phase 3')); End;

Procedure FormatBold;     Begin SetStatus(L('Gras', 'Bold')); End;
Procedure FormatItalic;   Begin SetStatus(L('Italique', 'Italic')); End;
Procedure FormatUnder;    Begin SetStatus(L('Souligne', 'Underline')); End;
Procedure FormatBullet;   Begin SetStatus(L('Puce', 'Bullet')); End;
Procedure FormatNumber;   Begin SetStatus(L('Numerotation', 'Numbering')); End;
Procedure FormatIndent;   Begin SetStatus(L('Indenter', 'Indent')); End;
Procedure FormatOutdent;  Begin SetStatus(L('Desindenter', 'Outdent')); End;
Procedure FormatPageStyle;Begin SetStatus(L('Style page', 'Page style')); End;

Procedure ViewPrevSection;
Begin
 If Book.CurSection > 1 Then Begin
  Dec(Book.CurSection);
  SetStatus(L('Section precedente', 'Previous section'));
 End;
End;

Procedure ViewNextSection;
Begin
 If Book.CurSection < Book.SectionCount Then Begin
  Inc(Book.CurSection);
  SetStatus(L('Section suivante', 'Next section'));
 End;
End;

Procedure ViewPrevPage;
Var Sec: PSection;
Begin
 If Book.CurSection < 1 Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If Sec^.CurPage > 1 Then Begin
  Dec(Sec^.CurPage); SetStatus(L('Page precedente', 'Previous page'));
 End;
End;

Procedure ViewNextPage;
Var Sec: PSection;
Begin
 If Book.CurSection < 1 Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If Sec^.CurPage < Sec^.PageCount Then Begin
  Inc(Sec^.CurPage); SetStatus(L('Page suivante', 'Next page'));
 End;
End;

Procedure ViewPageList;  Begin SetStatus(L('Liste pages', 'Page list')); End;
Procedure ViewFullScreen;Begin SetStatus(L('Plein ecran', 'Full screen')); End;
Procedure ViewZoomIn;    Begin SetStatus(L('Zoom +', 'Zoom In')); End;
Procedure ViewZoomOut;   Begin SetStatus(L('Zoom -', 'Zoom Out')); End;

Procedure ToolsSpell;    Begin SetStatus(L('Orthographe', 'Spell check')); End;
Procedure ToolsSearch;   Begin SetStatus(L('Recherche globale', 'Global search')); End;
Procedure ToolsLanguage;
Begin
 If Language = LangFR Then Language := LangEN Else Language := LangFR;
 InitMenuSystem;
 SetStatus(L('Langue : francais', 'Language: English'));
End;
Procedure ToolsPrefs;    Begin SetStatus(L('Preferences', 'Preferences')); End;
Procedure ToolsPassword; Begin SetStatus(L('Mot de passe', 'Password')); End;

Procedure HelpContents;
Begin
 SetStatus(L('Aide : F1 - clone OneNote v0.1 (Phase 1)',
             'Help: F1 - OneNote clone v0.1 (Phase 1)'));
End;

Procedure HelpAbout;
Begin
 SetStatus(L('Clone OneNote en Pascal - (c) 2026',
             'OneNote clone in Pascal - (c) 2026'));
End;

{ ============================================================ }
{ ============  DISPATCHEURS DE MENU DEROULANT  =============== }
{ ============================================================ }

Function ExecuteFileMenu(II: Integer): Boolean;
Begin
 ExecuteFileMenu := False;
 Case II Of
  1:  FileNew;
  2:  FileOpen;
  3:  FileClose;
  5:  FileSave;
  6:  FileSaveAs;
  8:  FileImportONE;
  9:  FileExportPKG;
  10: FileExportTOC;
  12: FilePrint;
  14: ExecuteFileMenu := FileExit;
 End;
End;

Procedure ExecuteEditMenu(II: Integer);
Begin
 Case II Of
  1:  EditUndo;
  2:  EditRedo;
  4:  EditCut;
  5:  EditCopy;
  6:  EditPaste;
  7:  EditDelete;
  9:  EditFind;
  10: EditReplace;
 End;
End;

Procedure ExecuteInsertMenu(II: Integer);
Begin
 Case II Of
  1: InsertPage;
  2: InsertSection;
  3: InsertContainer;
  5: InsertImage;
  6: InsertTable;
  8: InsertDateTime;
  9: InsertTag;
 End;
End;

Procedure ExecuteFormatMenu(II: Integer);
Begin
 Case II Of
  1:  FormatBold;
  2:  FormatItalic;
  3:  FormatUnder;
  5:  FormatBullet;
  6:  FormatNumber;
  8:  FormatIndent;
  9:  FormatOutdent;
  10: FormatPageStyle;
 End;
End;

Procedure ExecuteViewMenu(II: Integer);
Begin
 Case II Of
  1: ViewPrevSection;
  2: ViewNextSection;
  3: ViewPageList;
  5: ViewFullScreen;
  7: ViewZoomIn;
  8: ViewZoomOut;
 End;
End;

Procedure ExecuteToolsMenu(II: Integer);
Begin
 Case II Of
  1: ToolsSpell;
  2: ToolsSearch;
  4: ToolsLanguage;
  5: ToolsPrefs;
  6: ToolsPassword;
 End;
End;

Procedure ExecuteHelpMenu(II: Integer);
Begin
 Case II Of
  1: HelpContents;
  3: HelpAbout;
 End;
End;

Function DispatchMenu(MI, II: Integer): Boolean;
Begin
 DispatchMenu := False;
 Case MI Of
  1: DispatchMenu := ExecuteFileMenu(II);
  2: ExecuteEditMenu(II);
  3: ExecuteInsertMenu(II);
  4: ExecuteFormatMenu(II);
  5: ExecuteViewMenu(II);
  6: ExecuteToolsMenu(II);
  7: ExecuteHelpMenu(II);
 End;
End;

Procedure ExecuteIcon(Idx: Integer);
Begin
 Case Idx Of
  ICN_NEW    : FileNew;
  ICN_OPEN   : FileOpen;
  ICN_SAVE   : FileSave;
  ICN_PRINT  : FilePrint;
  ICN_CUT    : EditCut;
  ICN_COPY   : EditCopy;
  ICN_PASTE  : EditPaste;
  ICN_UNDO   : EditUndo;
  ICN_REDO   : EditRedo;
  ICN_BOLD   : FormatBold;
  ICN_ITALIC : FormatItalic;
  ICN_UNDER  : FormatUnder;
  ICN_BULLET : FormatBullet;
  ICN_IMAGE  : InsertImage;
 End;
End;

{ ============================================================ }
{ ===============  CLICS SECTION + PAGE  ====================== }
{ ============================================================ }

Function FindSectionAtX(X, Y: LongInt): Integer;
Var I, Xc, W: Integer; Sec: PSection;
Begin
 FindSectionAtX := 0;
 If (Y < SECTION_Y0) Or (Y > SECTION_Y1) Then Exit;
 Xc := 4;
 For I := 1 To Book.SectionCount Do Begin
  Sec := @Book.Sections[I];
  W := Length(Sec^.Name) * 8 + 16;
  If (X >= Xc) And (X <= Xc + W) Then Begin
   FindSectionAtX := I; Exit;
  End;
  Xc := Xc + W + 2;
 End;
 { Bouton + }
 If (X >= Xc) And (X <= Xc + 18) Then FindSectionAtX := -1;
End;

Function FindPageAtY(X, Y: LongInt): Integer;
Const PAGE_H = 22;
Var Sec: PSection; I, Yc: Integer;
Begin
 FindPageAtY := 0;
 If (X < PAGELIST_X0) Or (Y < CONTENT_Y0 + 20) Then Exit;
 If Book.CurSection < 1 Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 For I := 1 To Sec^.PageCount Do Begin
  Yc := CONTENT_Y0 + 20 + (I - 1) * PAGE_H;
  If (Y >= Yc) And (Y < Yc + PAGE_H - 2) Then Begin
   FindPageAtY := I; Exit;
  End;
 End;
 { Zone "+ Page" }
 Yc := CONTENT_Y0 + 20 + Sec^.PageCount * PAGE_H;
 If (Y >= Yc) And (Y < Yc + 18) Then FindPageAtY := -1;
End;

Procedure HandleLeftClick(X, Y: LongInt);
Var MI, II, IcIdx, SecIdx, PgIdx: Integer; Exit_: Boolean;
Begin
 { 1) Si un menu deroulant est ouvert, gerer le clic dedans }
 If (MenuState = MS_DROPDOWN) And (CurrentMenu > 0) Then Begin
  II := GetDropDownItemAtPosition(CurrentMenu, X, Y);
  If (II > 0) And Not IsMenuSeparator(CurrentMenu, II) Then Begin
   Exit_ := DispatchMenu(CurrentMenu, II);
   MenuState := MS_NONE; CurrentMenu := 0; HoveredMenuItem := 0;
   RefreshScreen;
   If Exit_ Then LoopDone := True;
   Exit;
  End;
  { Clic ailleurs : verifier la barre de menu }
  MI := GetMenuAtPosition(X, Y);
  If MI > 0 Then Begin
   CurrentMenu := MI; HoveredMenuItem := 0;
   RefreshScreen; Exit;
  End;
  { Sinon fermer }
  MenuState := MS_NONE; CurrentMenu := 0; HoveredMenuItem := 0;
  RefreshScreen; Exit;
 End;

 { 2) Clic sur la barre de menu : ouvrir le deroulant }
 MI := GetMenuAtPosition(X, Y);
 If MI > 0 Then Begin
  CurrentMenu := MI; MenuState := MS_DROPDOWN; HoveredMenuItem := 0;
  RefreshScreen; Exit;
 End;

 { 3) Clic sur la toolbar }
 IcIdx := FindIconAtPosition(X, Y);
 If IcIdx > 0 Then Begin
  ExecuteIcon(IcIdx); RefreshScreen; Exit;
 End;

 { 4) Clic sur un onglet de section }
 SecIdx := FindSectionAtX(X, Y);
 If SecIdx > 0 Then Begin
  Book.CurSection := SecIdx;
  SetStatus(L('Section : ', 'Section: ') + Book.Sections[SecIdx].Name);
  RefreshScreen; Exit;
 End
 Else If SecIdx = -1 Then Begin
  InsertSection; RefreshScreen; Exit;
 End;

 { 5) Clic sur la liste des pages }
 PgIdx := FindPageAtY(X, Y);
 If PgIdx > 0 Then Begin
  Book.Sections[Book.CurSection].CurPage := PgIdx;
  SetStatus(L('Page : ', 'Page: ') +
            Book.Sections[Book.CurSection].Pages[PgIdx].Title);
  RefreshScreen; Exit;
 End
 Else If PgIdx = -1 Then Begin
  InsertPage; RefreshScreen; Exit;
 End;
End;

Procedure HandleRightClick(X, Y: LongInt);
Begin
 { Phase 1 : pas de menu contextuel - sera ajoute en Phase 4 }
 SetStatus(L('Clic droit : menu contextuel a venir',
             'Right click: context menu TBD'));
 RefreshScreen;
End;

{ ============================================================ }
{ ====================  CLAVIER  ============================== }
{ ============================================================ }

Procedure OpenMenu(MI: Integer);
Begin
 CurrentMenu := MI; MenuState := MS_DROPDOWN; HoveredMenuItem := 1;
 { Sauter le 1er separateur eventuel }
 While IsMenuSeparator(MI, HoveredMenuItem) And
       (HoveredMenuItem < GetMenuItemCount(MI)) Do Inc(HoveredMenuItem);
 RefreshScreen;
End;

Procedure HandleKey(K: Char);
Var K2: Char; Cnt: Integer; Exit_: Boolean;
Begin
 If (MenuState = MS_DROPDOWN) And (CurrentMenu > 0) Then Begin
  Cnt := GetMenuItemCount(CurrentMenu);
  If K = #13 Then Begin
   If (HoveredMenuItem >= 1) And (HoveredMenuItem <= Cnt) And
      Not IsMenuSeparator(CurrentMenu, HoveredMenuItem) Then Begin
    Exit_ := DispatchMenu(CurrentMenu, HoveredMenuItem);
    MenuState := MS_NONE; CurrentMenu := 0; HoveredMenuItem := 0;
    RefreshScreen;
    If Exit_ Then LoopDone := True;
   End;
   Exit;
  End;
  If K = #27 Then Begin
   MenuState := MS_NONE; CurrentMenu := 0; HoveredMenuItem := 0;
   RefreshScreen; Exit;
  End;
  If K = #0 Then Begin
   K2 := ReadKey;
   Case K2 Of
    #72: Begin { fleche haut }
          If HoveredMenuItem <= 0 Then HoveredMenuItem := Cnt + 1;
          Repeat
           Dec(HoveredMenuItem);
           If HoveredMenuItem < 1 Then HoveredMenuItem := Cnt;
          Until Not IsMenuSeparator(CurrentMenu, HoveredMenuItem);
          RefreshScreen;
         End;
    #80: Begin { fleche bas }
          Repeat
           Inc(HoveredMenuItem);
           If HoveredMenuItem > Cnt Then HoveredMenuItem := 1;
          Until Not IsMenuSeparator(CurrentMenu, HoveredMenuItem);
          RefreshScreen;
         End;
    #75: Begin { gauche : menu precedent }
          CurrentMenu := ((CurrentMenu - 2 + MENU_COUNT) Mod MENU_COUNT) + 1;
          HoveredMenuItem := 1; RefreshScreen;
         End;
    #77: Begin { droite : menu suivant }
          CurrentMenu := (CurrentMenu Mod MENU_COUNT) + 1;
          HoveredMenuItem := 1; RefreshScreen;
         End;
   End;
  End;
  Exit;
 End;

 { Aucun menu ouvert : raccourcis globaux }
 Case K Of
  #27: LoopDone := True;                 { Esc : quitter }
  #14: Begin FileNew;  RefreshScreen; End;  { Ctrl+N }
  #15: Begin FileOpen; RefreshScreen; End;  { Ctrl+O }
  #19: Begin FileSave; RefreshScreen; End;  { Ctrl+S }
  #16: Begin FilePrint;RefreshScreen; End;  { Ctrl+P }
  #23: Begin FileClose;RefreshScreen; End;  { Ctrl+W }
  #26: Begin EditUndo; RefreshScreen; End;  { Ctrl+Z }
  #25: Begin EditRedo; RefreshScreen; End;  { Ctrl+Y }
  #24: Begin EditCut;  RefreshScreen; End;  { Ctrl+X }
  #3 : Begin EditCopy; RefreshScreen; End;  { Ctrl+C }
  #22: Begin EditPaste;RefreshScreen; End;  { Ctrl+V }
  #6 : Begin EditFind; RefreshScreen; End;  { Ctrl+F }
  #8 : Begin EditReplace; RefreshScreen; End; { Ctrl+H }
  #2 : Begin FormatBold; RefreshScreen; End; { Ctrl+B }
  #9 : Begin FormatItalic; RefreshScreen; End; { Ctrl+I/Tab - on prefere Tab }
  #21: Begin FormatUnder; RefreshScreen; End; { Ctrl+U }
  #13: Begin InsertPage; RefreshScreen; End; { Ctrl+M Pas dispo ; on prend Enter en page-list }
  #0 : Begin
        K2 := ReadKey;
        Case K2 Of
         #59:  Begin HelpContents; OpenMenu(7); End; { F1 }
         #134: Begin FileSaveAs; RefreshScreen; End; { F12 }
         #85:  Begin FileSaveAs; RefreshScreen; End; { F12 alt }
         #93:  Begin { F11 plein ecran }
                ViewFullScreen; RefreshScreen;
               End;
         { Navigation pages avec PgUp/PgDn }
         #73:  Begin ViewPrevPage; RefreshScreen; End; { PgUp }
         #81:  Begin ViewNextPage; RefreshScreen; End; { PgDn }
         { Ctrl+PgUp/PgDn : navigation sections }
         #132: Begin ViewPrevSection; RefreshScreen; End; { Ctrl+PgUp }
         #118: Begin ViewNextSection; RefreshScreen; End; { Ctrl+PgDn }
         { Alt+F4 }
         #107: LoopDone := True;
         { Alt+lettre : ouvrir menus }
         #33:  OpenMenu(1);   { Alt+F }
         #18:  OpenMenu(2);   { Alt+E }
         #23:  OpenMenu(3);   { Alt+I }
         #50:  OpenMenu(4);   { Alt+M }
         #30:  OpenMenu(5);   { Alt+A }
         #24:  OpenMenu(6);   { Alt+O }
         #35:  OpenMenu(7);   { Alt+H }
        End;
       End;
 End;
End;

{ ============================================================ }
{ ====================  TOOLTIP TOOLBAR  ====================== }
{ ============================================================ }

Procedure DrawTooltip(Idx: Integer);
Var X, Y, W: Integer; T: String;
Begin
 If Idx < 1 Then Exit;
 T := IconLabel(Idx);
 If T = '' Then Exit;
 W := Length(T) * 8 + 8;
 X := IconX(Idx);
 Y := TB_Y0 + TB_ICON_H + 2;
 If X + W > SCR_W - 2 Then X := SCR_W - 2 - W;
 FillRect(X, Y, X + W, Y + 12, Yellow);
 FrameRect(X, Y, X + W, Y + 12, Black);
 DrawTextAt(X + 4, Y + 2, Black, T);
End;

{ ============================================================ }
{ =======================  MAIN LOOP  ========================= }
{ ============================================================ }

Procedure ProcessMouse;
Var IcNow, MoveDone: Integer;
Begin
 If Not MouseDriverFound Then Exit;
 GetMouseState(MsX, MsY, MsBtn);

 { Survol toolbar }
 IcNow := FindIconAtPosition(MsX, MsY);
 If IcNow <> ToolHover Then Begin
  OldToolHover := ToolHover;
  ToolHover := IcNow;
  RefreshScreen;
  If ToolHover > 0 Then Begin
   HideMouse; DrawTooltip(ToolHover); ShowMouse;
  End;
 End;

 { Survol menu deroulant (souris bouge) }
 If (MenuState = MS_DROPDOWN) And (CurrentMenu > 0) And
    ((MsX <> PrevMsX) Or (MsY <> PrevMsY)) Then Begin
  { Bascule sur autre menu de la barre }
  MoveDone := GetMenuAtPosition(MsX, MsY);
  If (MoveDone > 0) And (MoveDone <> CurrentMenu) Then Begin
   CurrentMenu := MoveDone; HoveredMenuItem := 0; RefreshScreen;
  End
  Else Begin
   OldHoveredMenuItem := HoveredMenuItem;
   HoveredMenuItem := GetDropDownItemAtPosition(CurrentMenu, MsX, MsY);
   If HoveredMenuItem <> OldHoveredMenuItem Then RefreshScreen;
  End;
 End;

 PrevMsX := MsX; PrevMsY := MsY;

 { Boutons }
 If (MsBtn And MB_LEFT) = MB_LEFT Then Begin
  HandleLeftClick(MsX, MsY);
  { Attendre relachement }
  Repeat
   GetMouseState(MsX, MsY, MsBtn);
  Until (MsBtn And MB_LEFT) = 0;
 End
 Else If (MsBtn And MB_RIGHT) = MB_RIGHT Then Begin
  HandleRightClick(MsX, MsY);
  Repeat
   GetMouseState(MsX, MsY, MsBtn);
  Until (MsBtn And MB_RIGHT) = 0;
 End;
End;

Procedure InitSecColors;
Begin
 SecColors[1] := LightBlue;
 SecColors[2] := LightGreen;
 SecColors[3] := LightRed;
 SecColors[4] := Yellow;
 SecColors[5] := LightMagenta;
 SecColors[6] := LightCyan;
 SecColors[7] := Brown;
 SecColors[8] := LightGray;
End;

BEGIN
 Language := LangFR;
 ParamFileArg := '';
 If (ParamStr(1) = '/?') Or (ParamStr(1) = '--help') Or (ParamStr(1) = '-h') Then Begin
  WriteLn('ONENOTE : Clone OneNote en Pascal (Phase 1 - charpente UI)');
  WriteLn;
  WriteLn('Syntaxe : ONENOTE [fichier.ONE | fichier.ONEPKG]');
  Halt;
 End;
 If ParamCount >= 1 Then ParamFileArg := ParamStr(1);

 InitSecColors;
 InitializeGraphics;
 InitMenuSystem;
 InitDefaultNotebook;

 ToolHover     := 0;
 OldToolHover  := 0;
 SectionHover  := 0;
 PageHover     := 0;
 CurrentTool   := TT_TEXT;
 MsX := 0; MsY := 0; MsBtn := 0;
 PrevMsX := -1; PrevMsY := -1;
 StatusMsg := L('Pret', 'Ready');

 If MouseDriverFound Then ShowMouse;

 If ParamFileArg <> '' Then Begin
  Book.FilePath := ParamFileArg;
  SetStatus(L('Fichier passe en parametre (chargement Phase 8) : ',
              'File arg (loading in Phase 8): ') + ParamFileArg);
 End;

 RefreshScreen;

 LoopDone := False;
 Repeat
  ProcessMouse;
  If KeyPressed Then Begin
   LoopKey := ReadKey;
   HandleKey(LoopKey);
  End;
 Until LoopDone;

 If MouseDriverFound Then HideMouse;
 CloseGraph;
END.