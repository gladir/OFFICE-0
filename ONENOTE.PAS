{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application OneNote
}

Program ONENOTE;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse,Dos
     {$ELSE}
      Crt,Graph,Dos
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

 { Phase 2 : modes d'edition }
 EM_NONE            = 0;
 EM_BODY            = 1;
 EM_TITLE           = 2;
 { Phase 4 : edition d'un container libre }
 EM_EXTRA           = 3;

 { Phase 2 : geometrie de la zone de notes }
 NOTE_LEFT_MARGIN   = 24;          { marge interne du contenu }
 NOTE_LINE_H        = 14;          { hauteur d'une ligne paragraphe }
 NOTE_TITLE_Y       = CONTENT_Y0 + 12;
 NOTE_PARA_Y0       = CONTENT_Y0 + 56;
 NOTE_CHAR_W        = 8;           { largeur fixe du font 8x8 }
 NOTE_CURSOR_H      = 12;

 { Phase 3 : tags par paragraphe }
 TAG_NONE           = 0;
 TAG_TODO           = 1;
 TAG_DONE           = 2;
 TAG_STAR           = 3;
 TAG_QUESTION       = 4;
 TAG_IMPORTANT      = 5;
 TAG_IDEA           = 6;
 TAG_COUNT          = 6;
 NOTE_TAG_W         = 14;          { largeur reservee a l'icone de tag }
 NOTE_BULLET_W      = 14;          { largeur reservee a la puce }
 NOTE_INDENT_W      = 16;          { decalage par niveau d'indent }

 { Phase 4 : containers libres (style OneNote) }
 MAX_EXTRAS         = 8;
 EXTRA_DEFAULT_W    = 180;
 EXTRA_DEFAULT_H    = 56;
 EXTRA_MIN_W        = 60;
 EXTRA_MIN_H        = 24;
 EXTRA_BORDER       = 4;           { tolerance de detection bord }
 EXTRA_PAD          = 4;           { padding interne }
 EXTRA_TXT_LEN      = 200;

 { Phase 6 : images BMP }
 MAX_IMG_W          = 320;
 MAX_IMG_H          = 200;
 BMP_SIGNATURE      = 19778;       { 'BM' little-endian = $4D42 }

 { Phase 12 : dessin libre (strokes par page) }
 MAX_STROKES        = 8;
 MAX_STROKE_PTS     = 24;

 { Phase 12 : tableaux encodes en-bande dans Txt }
 TBL_MARKER_C1      = #27;         { ESC }
 TBL_MARKER_C2      = #84;         { 'T' }
 TBL_MAX_ROWS       = 6;
 TBL_MAX_COLS       = 4;

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

 { Phase 4 : container libre (zone de texte positionnable) }
 TExtra = Record
  X, Y, W, H : Integer;
  Bold       : Boolean;
  Italic     : Boolean;
  Under      : Boolean;
  Tag        : Byte;
  Txt        : String[EXTRA_TXT_LEN];
  IsImage    : Boolean;            { Phase 6 : extra contient une image }
  ImgW, ImgH : Integer;            { dimensions effectives de l'image }
  Pixels     : Pointer;            { ^Array[0..ImgW*ImgH-1] Of Byte EGA }
 End;

 { Phase 12 : point d'un trait de dessin libre }
 TStrokePt = Packed Record
  X, Y       : Word;
 End;

 { Phase 12 : trait (polyligne) }
 TStroke = Record
  Color      : Byte;
  PtCount    : Word;
  Pts        : Array[1..MAX_STROKE_PTS] Of TStrokePt;
 End;

 { Page : titre + paragraphes + containers libres (Phase 4) + strokes (Phase 12) }
 TPage = Record
  Title       : String[PAGE_TITLE_LEN];
  ParaCount   : Integer;
  Para        : Array[1..MAX_PARA] Of TParagraph;
  CreatedTS   : LongInt;
  ExtraCount  : Integer;
  Extras      : Array[1..MAX_EXTRAS] Of TExtra;
  StrokeCount : Integer;
  Strokes     : Array[1..MAX_STROKES] Of TStroke;
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

 { Phase 12 : etat recherche }
 LastSearch         : String;
 LastSecIdx         : Integer;
 LastPgIdx          : Integer;
 LastParaIdx        : Integer;

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

 { Phase 2 : etat d'edition de texte }
 EditMode           : Integer;     { 0=aucun, 1=corps, 2=titre }
 EdParaIdx          : Integer;     { paragraphe courant (1..ParaCount) }
 EdCharPos          : Integer;     { position du caret (0..Length(Txt)) }
 CursorVisible      : Boolean;
 BlinkCounter       : Integer;
 PrevEdParaIdx      : Integer;
 PrevEdCharPos      : Integer;
 PrevEditMode       : Integer;

 { Phase 4 : extra (container libre) en cours d'edition }
 EdExtraIdx         : Integer;

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

Procedure ClearExtra(Var E: TExtra);
Begin
 E.X := 0; E.Y := 0; E.W := EXTRA_DEFAULT_W; E.H := EXTRA_DEFAULT_H;
 E.Bold := False; E.Italic := False; E.Under := False;
 E.Tag := 0; E.Txt := '';
 E.IsImage := False; E.ImgW := 0; E.ImgH := 0; E.Pixels := Nil;
End;

Procedure FreeExtraImage(Var E: TExtra);
Begin
 If E.IsImage And (E.Pixels <> Nil) Then
  FreeMem(E.Pixels, LongInt(E.ImgW) * E.ImgH);
 E.IsImage := False; E.Pixels := Nil; E.ImgW := 0; E.ImgH := 0;
End;

Procedure ClearPage(Var Pg: TPage);
Var I: Integer;
Begin
 Pg.Title       := '';
 Pg.ParaCount   := 0;
 Pg.CreatedTS   := 0;
 Pg.ExtraCount  := 0;
 Pg.StrokeCount := 0;
 For I := 1 To MAX_PARA    Do ClearParagraph(Pg.Para[I]);
 For I := 1 To MAX_EXTRAS  Do ClearExtra(Pg.Extras[I]);
 For I := 1 To MAX_STROKES Do Begin
  Pg.Strokes[I].Color := 0;
  Pg.Strokes[I].PtCount := 0;
 End;
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
Var Cnt, I, MenuX, MenuY, MW, MH: Integer;
    Label_, Sc: String;
Begin
 Cnt := GetMenuItemCount(MI);
 If Cnt <= 0 Then Exit;
 MenuX := MenuPositions[MI] - 4;
 MenuY := MENU_Y1 + 1;
 MW    := 230;

 { Hauteur : au moins assez pour couvrir toolbar + onglets de section,
   sinon le bas des onglets depasse sous un menu court (ex. Aide). }
 MH := Cnt * ITEM_H;
 If MenuY + MH < SECTION_Y1 + 2 Then MH := SECTION_Y1 + 2 - MenuY;

 { Fond + cadre 3D }
 FillRect(MenuX, MenuY, MenuX + MW, MenuY + MH, CLR_MENU_BG);
 FrameRect3D(MenuX, MenuY, MenuX + MW, MenuY + MH, White, DarkGray);

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

{ Phase 3 : rendu d'une icone de tag a (X,Y) - zone NOTE_TAG_W large }
Procedure DrawTagIcon(X, Y, Tag: Integer);
Var Cx, Cy: Integer;
Begin
 Case Tag Of
  TAG_TODO: Begin
   SetColor(Black);
   Rectangle(X + 1, Y + 1, X + 11, Y + 11);
  End;
  TAG_DONE: Begin
   SetColor(Black);
   Rectangle(X + 1, Y + 1, X + 11, Y + 11);
   SetColor(Green);
   Line(X + 3, Y + 6, X + 5, Y + 9);
   Line(X + 5, Y + 9, X + 10, Y + 3);
   Line(X + 3, Y + 7, X + 5, Y + 10);
   Line(X + 5, Y + 10, X + 10, Y + 4);
  End;
  TAG_STAR: Begin
   Cx := X + 6; Cy := Y + 6;
   SetColor(Yellow);
   Line(Cx, Cy - 5, Cx + 1, Cy - 1);
   Line(Cx + 1, Cy - 1, Cx + 5, Cy - 1);
   Line(Cx + 5, Cy - 1, Cx + 2, Cy + 2);
   Line(Cx + 2, Cy + 2, Cx + 3, Cy + 5);
   Line(Cx + 3, Cy + 5, Cx, Cy + 3);
   Line(Cx, Cy + 3, Cx - 3, Cy + 5);
   Line(Cx - 3, Cy + 5, Cx - 2, Cy + 2);
   Line(Cx - 2, Cy + 2, Cx - 5, Cy - 1);
   Line(Cx - 5, Cy - 1, Cx - 1, Cy - 1);
   Line(Cx - 1, Cy - 1, Cx, Cy - 5);
  End;
  TAG_QUESTION: Begin
   DrawTextAt(X + 2, Y, Blue, '?');
   DrawTextAt(X + 3, Y, Blue, '?');
  End;
  TAG_IMPORTANT: Begin
   DrawTextAt(X + 3, Y, LightRed, '!');
   DrawTextAt(X + 4, Y, LightRed, '!');
  End;
  TAG_IDEA: Begin
   SetColor(Yellow);
   Circle(X + 6, Y + 5, 3);
   FillEllipse(X + 6, Y + 5, 3, 3);
   SetColor(Black);
   Line(X + 4, Y + 9, X + 8, Y + 9);
   Line(X + 5, Y + 10, X + 7, Y + 10);
  End;
 End;
End;

Function TagName(Tag: Integer): String;
Begin
 Case Tag Of
  TAG_NONE     : TagName := L('aucun',      'none');
  TAG_TODO     : TagName := L('a faire',    'to do');
  TAG_DONE     : TagName := L('fait',       'done');
  TAG_STAR     : TagName := L('important',  'star');
  TAG_QUESTION : TagName := L('question',   'question');
  TAG_IMPORTANT: TagName := L('urgent',     'important');
  TAG_IDEA     : TagName := L('idee',       'idea');
 Else
  TagName := '';
 End;
End;

{ Rendu d'une chaine avec attributs Gras/Italique/Souligne }
Procedure DrawStyledText(X, Y, Col: Integer; Const S: String;
                        Bold, Italic, Under: Boolean);
Var W: Integer;
Begin
 If S = '' Then Begin
  If Under Then Begin
   SetColor(Col); Line(X, Y + 10, X + NOTE_CHAR_W, Y + 10);
  End;
  Exit;
 End;
 DrawTextAt(X, Y, Col, S);
 If Italic Then DrawTextAt(X + 1, Y - 1, Col, S);
 If Bold Then Begin
  DrawTextAt(X + 1, Y, Col, S);
  If Italic Then DrawTextAt(X + 2, Y - 1, Col, S);
 End;
 If Under Then Begin
  W := Length(S) * NOTE_CHAR_W;
  If Bold Then Inc(W);
  SetColor(Col);
  Line(X, Y + 10, X + W, Y + 10);
 End;
End;

{ Position X du debut du texte (apres indent, tag, puce) }
Function ParaTextX(Const P: TParagraph): Integer;
Var X: Integer;
Begin
 X := NOTE_X0 + NOTE_LEFT_MARGIN + P.Indent * NOTE_INDENT_W;
 If P.Tag <> TAG_NONE Then X := X + NOTE_TAG_W;
 If P.Bullet           Then X := X + NOTE_BULLET_W;
 ParaTextX := X;
End;

{ Phase 12 : detection / acces a un container tableau.
  Encodage en-bande dans Txt :
    Txt[1]=#27 Txt[2]='T' Txt[3]=Chr(Rows) Txt[4]=Chr(Cols)
    Txt[5..] = cellules separees par #9 (colonne) et #10 (ligne). }
Function IsTableExtra(Const E: TExtra): Boolean;
Begin
 IsTableExtra := (Length(E.Txt) >= 4) And
                 (E.Txt[1] = TBL_MARKER_C1) And (E.Txt[2] = TBL_MARKER_C2);
End;

Function TableRows(Const E: TExtra): Integer;
Begin
 If IsTableExtra(E) Then TableRows := Ord(E.Txt[3]) Else TableRows := 0;
End;

Function TableCols(Const E: TExtra): Integer;
Begin
 If IsTableExtra(E) Then TableCols := Ord(E.Txt[4]) Else TableCols := 0;
End;

Procedure DrawTableExtra(Var E: TExtra);
Var Rows, Cols, R, C, ColW, RowH: Integer;
    P: Integer; Ch: Char; Cell: String;
    BaseX, BaseY: Integer;
Begin
 Rows := TableRows(E); Cols := TableCols(E);
 If (Rows < 1) Or (Cols < 1) Then Exit;
 ColW := (E.W - 2 * EXTRA_PAD) Div Cols;
 RowH := (E.H - 2 * EXTRA_PAD) Div Rows;
 If (ColW < 8) Or (RowH < 8) Then Exit;
 BaseX := E.X + EXTRA_PAD; BaseY := E.Y + EXTRA_PAD;
 SetColor(Black);
 For R := 0 To Rows Do
  Line(BaseX, BaseY + R * RowH, BaseX + Cols * ColW, BaseY + R * RowH);
 For C := 0 To Cols Do
  Line(BaseX + C * ColW, BaseY, BaseX + C * ColW, BaseY + Rows * RowH);
 { Texte des cellules }
 P := 5; R := 0; C := 0; Cell := '';
 While P <= Length(E.Txt) Do Begin
  Ch := E.Txt[P];
  If (Ch = #9) Or (Ch = #10) Then Begin
   If (R < Rows) And (C < Cols) And (Cell <> '') Then
    DrawTextAt(BaseX + C * ColW + 2, BaseY + R * RowH + 4, Black, Cell);
   Cell := '';
   If Ch = #9 Then Inc(C)
   Else Begin Inc(R); C := 0; End;
  End
  Else If Length(Cell) < 32 Then Cell := Cell + Ch;
  Inc(P);
 End;
 If (R < Rows) And (C < Cols) And (Cell <> '') Then
  DrawTextAt(BaseX + C * ColW + 2, BaseY + R * RowH + 4, Black, Cell);
End;

{ Phase 6 : rendu d'une image EGA dans l'interieur d'un container. }
Procedure DrawExtraImage(Var E: TExtra; X, Y: Integer);
Type
 TByteArr = Array[0..0] Of Byte;
 PByteArr = ^TByteArr;
Var Px, Py: Integer; Buf: PByteArr; Idx: LongInt;
Begin
 If (Not E.IsImage) Or (E.Pixels = Nil) Then Exit;
 If (E.ImgW <= 0) Or (E.ImgH <= 0) Then Exit;
 Buf := E.Pixels;
 For Py := 0 To E.ImgH - 1 Do
  For Px := 0 To E.ImgW - 1 Do Begin
   Idx := LongInt(Py) * E.ImgW + Px;
   PutPixel(X + Px, Y + Py, Buf^[Idx]);
  End;
End;

Procedure DrawNoteArea;
Var Sec: PSection; Pg: PPage; I, Y, X: Integer; P: TParagraph;
    LeftMargin, LineH: Integer; T: String;
    TitleStr: String;
    CurX, CurY: Integer;
Begin
 FillRect(NOTE_X0, CONTENT_Y0, NOTE_X1, CONTENT_Y1, CLR_NOTE_BG);

 If (Book.CurSection < 1) Or (Book.CurSection > Book.SectionCount) Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (Sec^.CurPage > Sec^.PageCount) Then Exit;
 Pg := @Sec^.Pages[Sec^.CurPage];

 LeftMargin := NOTE_X0 + NOTE_LEFT_MARGIN;
 LineH := NOTE_LINE_H;

 { Titre - rendu en gras }
 TitleStr := Pg^.Title;
 If (TitleStr = '') And (EditMode <> EM_TITLE) Then
  T := L('(Titre de la page)', '(Page title)')
 Else
  T := TitleStr;
 DrawStyledText(LeftMargin, NOTE_TITLE_Y, Black, T, True, False, False);
 SetColor(DarkGray);
 Line(LeftMargin, CONTENT_Y0 + 28, NOTE_X1 - 24, CONTENT_Y0 + 28);
 { Date }
 DrawTextAt(LeftMargin, CONTENT_Y0 + 32, DarkGray,
            L('Cree : ', 'Created: ') + L('aujourd''hui', 'today'));

 Y := NOTE_PARA_Y0;
 For I := 1 To Pg^.ParaCount Do Begin
  P := Pg^.Para[I];
  X := LeftMargin + P.Indent * NOTE_INDENT_W;
  If P.Tag <> TAG_NONE Then Begin
   DrawTagIcon(X, Y, P.Tag);
   X := X + NOTE_TAG_W;
  End;
  If P.Bullet Then Begin
   SetColor(Black);
   Circle(X + 4, Y + 4, 2);
   FillEllipse(X + 4, Y + 4, 2, 2);
   X := X + NOTE_BULLET_W;
  End;
  DrawStyledText(X, Y, Black, P.Txt, P.Bold, P.Italic, P.Under);
  Y := Y + LineH;
  If Y > CONTENT_Y1 - LineH Then Break;
 End;

 { Phase 4 : containers libres }
 For I := 1 To Pg^.ExtraCount Do Begin
  X := Pg^.Extras[I].X; Y := Pg^.Extras[I].Y;
  If (EditMode = EM_EXTRA) And (I = EdExtraIdx) Then SetColor(Blue)
  Else SetColor(DarkGray);
  Rectangle(X, Y, X + Pg^.Extras[I].W, Y + Pg^.Extras[I].H);
  Rectangle(X + 1, Y + 1, X + Pg^.Extras[I].W - 1, Y + Pg^.Extras[I].H - 1);
  { Petite "poignee" en haut a gauche pour signaler le drag }
  FillRect(X + 2, Y + 2, X + 8, Y + 6, LightGray);
  If Pg^.Extras[I].IsImage And (Pg^.Extras[I].Pixels <> Nil) Then
   DrawExtraImage(Pg^.Extras[I], X + EXTRA_PAD, Y + EXTRA_PAD)
  Else If IsTableExtra(Pg^.Extras[I]) Then
   DrawTableExtra(Pg^.Extras[I])
  Else Begin
   If Pg^.Extras[I].Tag <> TAG_NONE Then
    DrawTagIcon(X + EXTRA_PAD, Y + EXTRA_PAD + 2, Pg^.Extras[I].Tag);
   DrawStyledText(X + EXTRA_PAD + Ord(Pg^.Extras[I].Tag <> TAG_NONE) * NOTE_TAG_W,
                  Y + EXTRA_PAD + 8, Black, Pg^.Extras[I].Txt,
                  Pg^.Extras[I].Bold, Pg^.Extras[I].Italic, Pg^.Extras[I].Under);
  End;
 End;

 { Phase 12 : strokes (dessin libre) }
 For I := 1 To Pg^.StrokeCount Do
  With Pg^.Strokes[I] Do
   If PtCount >= 2 Then Begin
    SetColor(Color);
    For X := 1 To PtCount - 1 Do
     Line(Pts[X].X, Pts[X].Y, Pts[X + 1].X, Pts[X + 1].Y);
   End;

 { Curseur d'edition }
 If CursorVisible And (EditMode <> EM_NONE) Then Begin
  If EditMode = EM_TITLE Then Begin
   CurX := LeftMargin + EdCharPos * NOTE_CHAR_W;
   CurY := NOTE_TITLE_Y;
   SetColor(Black);
   Line(CurX, CurY, CurX, CurY + NOTE_CURSOR_H);
  End
  Else If EditMode = EM_BODY Then Begin
   If (EdParaIdx >= 1) And (EdParaIdx <= Pg^.ParaCount) Then Begin
    P := Pg^.Para[EdParaIdx];
    CurX := ParaTextX(P) + EdCharPos * NOTE_CHAR_W;
    CurY := NOTE_PARA_Y0 + (EdParaIdx - 1) * LineH;
    If (CurY >= CONTENT_Y0) And (CurY + NOTE_CURSOR_H <= CONTENT_Y1) Then Begin
     SetColor(Black);
     Line(CurX, CurY, CurX, CurY + NOTE_CURSOR_H);
    End;
   End;
  End
  Else If EditMode = EM_EXTRA Then Begin
   If (EdExtraIdx >= 1) And (EdExtraIdx <= Pg^.ExtraCount) Then Begin
    CurX := Pg^.Extras[EdExtraIdx].X + EXTRA_PAD +
            Ord(Pg^.Extras[EdExtraIdx].Tag <> TAG_NONE) * NOTE_TAG_W +
            EdCharPos * NOTE_CHAR_W;
    CurY := Pg^.Extras[EdExtraIdx].Y + EXTRA_PAD + 8;
    SetColor(Black);
    Line(CurX, CurY, CurX, CurY + NOTE_CURSOR_H);
   End;
  End;
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
{ ===============  IMAGES BMP + DITHER EGA (Phase 6)  ========= }
{ ============================================================ }

Const
 EGA_R : Array[0..15] Of Byte =
  (  0,   0,   0,   0, 168, 168, 168, 168,  84,  84,  84,  84, 252, 252, 252, 252);
 EGA_G : Array[0..15] Of Byte =
  (  0,   0, 168, 168,   0,   0,  84, 168,  84,  84, 252, 252,  84,  84, 252, 252);
 EGA_B : Array[0..15] Of Byte =
  (  0, 168,   0, 168,   0, 168,   0, 168,  84, 252,  84, 252,  84, 252,  84, 252);

Function NearestEGA16(R, G, B: Integer): Byte;
Var I, BestI: Integer; D, BestD, DR, DG, DB: LongInt;
Begin
 BestI := 0; BestD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - EGA_R[I];
  DG := LongInt(G) - EGA_G[I];
  DB := LongInt(B) - EGA_B[I];
  D  := DR*DR + DG*DG + DB*DB;
  If D < BestD Then Begin BestD := D; BestI := I; End;
 End;
 NearestEGA16 := Byte(BestI);
End;

{ Dithering Floyd-Steinberg sur un buffer RGB (RGBRGB...) -> indices EGA. }
Procedure DitherRgbToEga(W, H: Integer; RgbBuf, OutBuf: Pointer);
Type
 TByteArr = Array[0..0] Of Byte;
 PByteArr = ^TByteArr;
 TLongArr = Array[0..0] Of LongInt;
 PLongArr = ^TLongArr;
Var Rgb: PByteArr; Outp: PByteArr;
    ErrR, ErrG, ErrB: PLongArr;
    X, Y, Cur, Nxt: Integer;
    Idx: LongInt;
    R, G, B, Best, Er, Eg, Eb: Integer;
    Stride: LongInt;
    Sz: LongInt;
Begin
 If (W <= 0) Or (H <= 0) Then Exit;
 Rgb  := RgbBuf;
 Outp := OutBuf;
 Stride := LongInt(W) + 2;
 Sz := Stride * 2 * SizeOf(LongInt);
 GetMem(ErrR, Sz); GetMem(ErrG, Sz); GetMem(ErrB, Sz);
 If (ErrR = Nil) Or (ErrG = Nil) Or (ErrB = Nil) Then Begin
  If ErrR <> Nil Then FreeMem(ErrR, Sz);
  If ErrG <> Nil Then FreeMem(ErrG, Sz);
  If ErrB <> Nil Then FreeMem(ErrB, Sz);
  Exit;
 End;
 FillChar(ErrR^, Sz, 0);
 FillChar(ErrG^, Sz, 0);
 FillChar(ErrB^, Sz, 0);
 Cur := 0; Nxt := 1;
 For Y := 0 To H - 1 Do Begin
  For X := 0 To W + 1 Do Begin
   ErrR^[Nxt * Stride + X] := 0;
   ErrG^[Nxt * Stride + X] := 0;
   ErrB^[Nxt * Stride + X] := 0;
  End;
  For X := 0 To W - 1 Do Begin
   Idx := (LongInt(Y) * W + X) * 3;
   R := Rgb^[Idx]     + (ErrR^[Cur * Stride + X + 1] Div 16);
   G := Rgb^[Idx + 1] + (ErrG^[Cur * Stride + X + 1] Div 16);
   B := Rgb^[Idx + 2] + (ErrB^[Cur * Stride + X + 1] Div 16);
   If R < 0 Then R := 0 Else If R > 255 Then R := 255;
   If G < 0 Then G := 0 Else If G > 255 Then G := 255;
   If B < 0 Then B := 0 Else If B > 255 Then B := 255;
   Best := NearestEGA16(R, G, B);
   Outp^[LongInt(Y) * W + X] := Byte(Best);
   Er := R - EGA_R[Best];
   Eg := G - EGA_G[Best];
   Eb := B - EGA_B[Best];
   ErrR^[Cur * Stride + X + 2] := ErrR^[Cur * Stride + X + 2] + Er * 7;
   ErrG^[Cur * Stride + X + 2] := ErrG^[Cur * Stride + X + 2] + Eg * 7;
   ErrB^[Cur * Stride + X + 2] := ErrB^[Cur * Stride + X + 2] + Eb * 7;
   ErrR^[Nxt * Stride + X]     := ErrR^[Nxt * Stride + X]     + Er * 3;
   ErrG^[Nxt * Stride + X]     := ErrG^[Nxt * Stride + X]     + Eg * 3;
   ErrB^[Nxt * Stride + X]     := ErrB^[Nxt * Stride + X]     + Eb * 3;
   ErrR^[Nxt * Stride + X + 1] := ErrR^[Nxt * Stride + X + 1] + Er * 5;
   ErrG^[Nxt * Stride + X + 1] := ErrG^[Nxt * Stride + X + 1] + Eg * 5;
   ErrB^[Nxt * Stride + X + 1] := ErrB^[Nxt * Stride + X + 1] + Eb * 5;
   ErrR^[Nxt * Stride + X + 2] := ErrR^[Nxt * Stride + X + 2] + Er * 1;
   ErrG^[Nxt * Stride + X + 2] := ErrG^[Nxt * Stride + X + 2] + Eg * 1;
   ErrB^[Nxt * Stride + X + 2] := ErrB^[Nxt * Stride + X + 2] + Eb * 1;
  End;
  Cur := 1 - Cur; Nxt := 1 - Nxt;
 End;
 FreeMem(ErrR, Sz); FreeMem(ErrG, Sz); FreeMem(ErrB, Sz);
End;

{ Charge un BMP (1/4/8/24 bpp non compresse) dans un extra.
  Le BMP est echantillonne en nearest-neighbor a une taille max
  MAX_IMG_W x MAX_IMG_H avec ratio preserve, puis dithere en EGA 16. }
Function LoadBMPToExtra(Const FN: String; Var E: TExtra): Boolean;
Type
 TBMPFile = Packed Record
  bfType   : Word;
  bfSize   : LongInt;
  bfRes1   : Word;
  bfRes2   : Word;
  bfOffBits: LongInt;
 End;
 TBMPInfo = Packed Record
  biSize       : LongInt;
  biWidth      : LongInt;
  biHeight     : LongInt;
  biPlanes     : Word;
  biBitCount   : Word;
  biCompression: LongInt;
  biSizeImage  : LongInt;
  biXPel       : LongInt;
  biYPel       : LongInt;
  biClrUsed    : LongInt;
  biClrImp     : LongInt;
 End;
 TRGBQ = Packed Record B, G, R, X: Byte; End;
 TByteArr = Array[0..0] Of Byte;
 PByteArr = ^TByteArr;
Var F: File; FH: TBMPFile; IH: TBMPInfo; Got: Word;
    RowSize: LongInt;
    SrcW, SrcH, OutW, OutH: Integer;
    PalN, I, X, Y, Sx, Sy, SrcY: Integer;
    RowBuf: PByteArr;
    Pal: Array[0..255] Of TRGBQ;
    RgbBuf, OutBuf: PByteArr;
    RgbSz, OutSz: LongInt;
    Scale: LongInt;
    Bv: Byte; Bp: Integer;
    Rb, Gb, Bb: Byte;
    OutOff: LongInt;
    RowOff: LongInt;
Begin
 LoadBMPToExtra := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, FH, SizeOf(FH), Got);
 If (Got <> SizeOf(FH)) Or (FH.bfType <> BMP_SIGNATURE) Then Begin
  Close(F); Exit;
 End;
 BlockRead(F, IH, SizeOf(IH), Got);
 If Got <> SizeOf(IH) Then Begin Close(F); Exit; End;
 SrcW := IH.biWidth;
 If IH.biHeight < 0 Then SrcH := -IH.biHeight
                    Else SrcH := IH.biHeight;
 If (SrcW <= 0) Or (SrcH <= 0) Then Begin Close(F); Exit; End;
 If IH.biCompression <> 0 Then Begin Close(F); Exit; End;
 If Not (IH.biBitCount In [1, 4, 8, 24]) Then Begin Close(F); Exit; End;
 RowSize := ((LongInt(SrcW) * IH.biBitCount + 31) Div 32) * 4;
 If RowSize > 32000 Then Begin Close(F); Exit; End;
 { Determine la taille de sortie en preservant le ratio. }
 Scale := 1;
 While ((LongInt(SrcW) Div Scale) > MAX_IMG_W) Or
       ((LongInt(SrcH) Div Scale) > MAX_IMG_H) Do Inc(Scale);
 OutW := SrcW Div Scale; If OutW < 1 Then OutW := 1;
 OutH := SrcH Div Scale; If OutH < 1 Then OutH := 1;
 { Palette pour 1/4/8 bpp. }
 If IH.biBitCount <= 8 Then Begin
  If IH.biClrUsed > 0 Then PalN := IH.biClrUsed
                      Else PalN := 1 Shl IH.biBitCount;
  BlockRead(F, Pal, PalN * 4, Got);
  For I := PalN To 255 Do Begin
   Pal[I].B := 0; Pal[I].G := 0; Pal[I].R := 0; Pal[I].X := 0;
  End;
 End;
 GetMem(RowBuf, RowSize);
 RgbSz := LongInt(OutW) * OutH * 3;
 OutSz := LongInt(OutW) * OutH;
 GetMem(RgbBuf, RgbSz);
 GetMem(OutBuf, OutSz);
 If (RowBuf = Nil) Or (RgbBuf = Nil) Or (OutBuf = Nil) Then Begin
  If RowBuf <> Nil Then FreeMem(RowBuf, RowSize);
  If RgbBuf <> Nil Then FreeMem(RgbBuf, RgbSz);
  If OutBuf <> Nil Then FreeMem(OutBuf, OutSz);
  Close(F); Exit;
 End;
 FillChar(RgbBuf^, RgbSz, 0);
 { On lit ligne par ligne en sautant aux scanlines necessaires. }
 For Y := 0 To OutH - 1 Do Begin
  { Coordonnee source verticale }
  Sy := (LongInt(Y) * SrcH) Div OutH;
  If IH.biHeight > 0 Then SrcY := SrcH - 1 - Sy
                     Else SrcY := Sy;
  RowOff := FH.bfOffBits + LongInt(SrcY) * RowSize;
  Seek(F, RowOff);
  BlockRead(F, RowBuf^, RowSize, Got);
  For X := 0 To OutW - 1 Do Begin
   Sx := (LongInt(X) * SrcW) Div OutW;
   Rb := 0; Gb := 0; Bb := 0;
   Case IH.biBitCount Of
    1: Begin
     Bv := RowBuf^[Sx Shr 3]; Bp := 7 - (Sx And 7);
     I  := (Bv Shr Bp) And 1;
     Rb := Pal[I].R; Gb := Pal[I].G; Bb := Pal[I].B;
    End;
    4: Begin
     Bv := RowBuf^[Sx Shr 1];
     If (Sx And 1) = 0 Then I := (Bv Shr 4) And 15
                       Else I := Bv And 15;
     Rb := Pal[I].R; Gb := Pal[I].G; Bb := Pal[I].B;
    End;
    8: Begin
     I := RowBuf^[Sx];
     Rb := Pal[I].R; Gb := Pal[I].G; Bb := Pal[I].B;
    End;
    24: Begin
     Bb := RowBuf^[Sx * 3];
     Gb := RowBuf^[Sx * 3 + 1];
     Rb := RowBuf^[Sx * 3 + 2];
    End;
   End;
   OutOff := (LongInt(Y) * OutW + X) * 3;
   RgbBuf^[OutOff]     := Rb;
   RgbBuf^[OutOff + 1] := Gb;
   RgbBuf^[OutOff + 2] := Bb;
  End;
 End;
 Close(F);
 FreeMem(RowBuf, RowSize);
 DitherRgbToEga(OutW, OutH, RgbBuf, OutBuf);
 FreeMem(RgbBuf, RgbSz);
 { Attache l'image a l'extra (libere l'ancienne si presente). }
 FreeExtraImage(E);
 E.IsImage := True;
 E.ImgW    := OutW;
 E.ImgH    := OutH;
 E.Pixels  := OutBuf;
 { Ajuste la taille du conteneur pour englober l'image. }
 E.W := OutW + EXTRA_PAD * 2;
 E.H := OutH + EXTRA_PAD * 2;
 LoadBMPToExtra := True;
End;

{ ============================================================ }
{ ===============  DIALOGUE OUVRIR/ENREGISTRER (Phase 5)  ===== }
{ ============================================================ }

Const
 OFD_W            = 520;
 OFD_H            = 320;
 OFD_TBH          = 22;
 OFD_PAD          = 10;
 OFD_BTN_W        = 80;
 OFD_BTN_H        = 22;
 OFD_ROW_H        = 12;
 OFD_FILTER_COUNT = 7;
 OFD_MAX_ENTRIES  = 256;

Type
 TFDEntry = Record
  Name : String[60];
  IsDir: Boolean;
  Size : LongInt;
 End;

Var
 FD_X, FD_Y    : Integer;
 FD_Entries    : Array[1..OFD_MAX_ENTRIES] Of TFDEntry;
 FD_Count      : Integer;
 FD_Scroll     : Integer;
 FD_Sel        : Integer;
 FD_Path       : String[255];
 FD_Filter     : Integer;
 FD_Input      : String[80];
 FD_Save       : Boolean;
 FD_Done       : Boolean;
 FD_OK         : Boolean;

Function OFD_VisibleRows: Integer;
Begin
 OFD_VisibleRows := (OFD_H - 130) Div OFD_ROW_H;
End;

Function OFD_FilterMask(Idx: Integer): String;
Begin
 Case Idx Of
  0: OFD_FilterMask := '*.ONE';
  1: OFD_FilterMask := '*.ONEPKG';
  2: OFD_FilterMask := '*.ONETOC2';
  3: OFD_FilterMask := '*.ONECACHE';
  4: OFD_FilterMask := '*.ONEPART';
  5: OFD_FilterMask := '*.BMP';
  6: OFD_FilterMask := '*.MSONEBIN';
 Else
  OFD_FilterMask := '*.*';
 End;
End;

Function OFD_FilterDesc(Idx: Integer): String;
Begin
 Case Idx Of
  0: OFD_FilterDesc := L('Section OneNote (*.ONE)',     'OneNote Section (*.ONE)');
  1: OFD_FilterDesc := L('Bloc-notes (*.ONEPKG)',       'Notebook (*.ONEPKG)');
  2: OFD_FilterDesc := L('Sommaire (*.ONETOC2)',        'Table of contents (*.ONETOC2)');
  3: OFD_FilterDesc := L('Cache (*.ONECACHE)',          'Cache (*.ONECACHE)');
  4: OFD_FilterDesc := L('Partage (*.ONEPART)',         'Share (*.ONEPART)');
  5: OFD_FilterDesc := L('Image Bitmap (*.BMP)',        'Bitmap image (*.BMP)');
  6: OFD_FilterDesc := L('Binaire mono (*.MSONEBIN)',   'Monolithic (*.MSONEBIN)');
 Else
  OFD_FilterDesc := L('Tous fichiers (*.*)',            'All files (*.*)');
 End;
End;

Procedure OFD_GoUp;
Var I: Integer;
Begin
 If Length(FD_Path) <= 3 Then Exit;
 If FD_Path[Length(FD_Path)] = '\' Then
  FD_Path[0] := Chr(Length(FD_Path) - 1);
 I := Length(FD_Path);
 While (I > 0) And (FD_Path[I] <> '\') Do Dec(I);
 If I > 0 Then FD_Path := Copy(FD_Path, 1, I);
End;

Procedure OFD_ScanDir;
Var SR: SearchRec; Mask: String;
Begin
 FD_Count := 0;
 If Length(FD_Path) > 3 Then Begin
  Inc(FD_Count);
  FD_Entries[FD_Count].Name  := '..';
  FD_Entries[FD_Count].IsDir := True;
  FD_Entries[FD_Count].Size  := 0;
 End;
 FindFirst(FD_Path + '*.*', Directory, SR);
 While DosError = 0 Do Begin
  If ((SR.Attr And Directory) <> 0) And
     (SR.Name <> '.') And (SR.Name <> '..') Then
   If FD_Count < OFD_MAX_ENTRIES Then Begin
    Inc(FD_Count);
    FD_Entries[FD_Count].Name  := SR.Name;
    FD_Entries[FD_Count].IsDir := True;
    FD_Entries[FD_Count].Size  := 0;
   End;
  FindNext(SR);
 End;
 FindClose(SR);
 Mask := OFD_FilterMask(FD_Filter);
 FindFirst(FD_Path + Mask, AnyFile, SR);
 While DosError = 0 Do Begin
  If (SR.Attr And Directory) = 0 Then
   If FD_Count < OFD_MAX_ENTRIES Then Begin
    Inc(FD_Count);
    FD_Entries[FD_Count].Name  := SR.Name;
    FD_Entries[FD_Count].IsDir := False;
    FD_Entries[FD_Count].Size  := SR.Size;
   End;
  FindNext(SR);
 End;
 FindClose(SR);
 FD_Scroll := 0;
 If FD_Count > 0 Then FD_Sel := 1 Else FD_Sel := 0;
End;

Procedure OFD_Draw;
Var X0, Y0, X1, Y1, I, RY, Rows, EI, ListBot: Integer;
    S, T: String;
Begin
 RefreshScreen;
 X0 := FD_X; Y0 := FD_Y;
 X1 := X0 + OFD_W; Y1 := Y0 + OFD_H;
 Rows := OFD_VisibleRows;
 ListBot := Y0 + OFD_TBH + 22 + Rows * OFD_ROW_H + 2;
 FillRect(X0 + 4, Y1, X1 + 4, Y1 + 4, DarkGray);
 FillRect(X1, Y0 + 4, X1 + 4, Y1 + 4, DarkGray);
 FillRect(X0, Y0, X1, Y1, LightGray);
 FrameRect(X0, Y0, X1, Y1, Black);
 FillRect(X0, Y0, X1, Y0 + OFD_TBH, Blue);
 If FD_Save Then T := L('Enregistrer sous', 'Save As')
            Else T := L('Ouvrir', 'Open');
 DrawTextAt(X0 + 8, Y0 + 7, White, T);
 DrawTextAt(X0 + OFD_PAD, Y0 + OFD_TBH + 6, Black,
            L('Chemin : ', 'Path: ') + FD_Path);
 FillRect(X0 + OFD_PAD, Y0 + OFD_TBH + 22,
          X1 - OFD_PAD - 16, ListBot, White);
 FrameRect(X0 + OFD_PAD, Y0 + OFD_TBH + 22,
           X1 - OFD_PAD - 16, ListBot, DarkGray);
 For I := 1 To Rows Do Begin
  EI := FD_Scroll + I;
  If EI > FD_Count Then Break;
  RY := Y0 + OFD_TBH + 24 + (I - 1) * OFD_ROW_H;
  If EI = FD_Sel Then
   FillRect(X0 + OFD_PAD + 1, RY - 1,
            X1 - OFD_PAD - 17, RY + OFD_ROW_H - 1, Blue);
  If FD_Entries[EI].IsDir Then S := '[' + FD_Entries[EI].Name + ']'
                          Else S := FD_Entries[EI].Name;
  If Length(S) > 38 Then S := Copy(S, 1, 35) + '...';
  If EI = FD_Sel Then
   DrawTextAt(X0 + OFD_PAD + 4, RY, White, S)
  Else If FD_Entries[EI].IsDir Then
   DrawTextAt(X0 + OFD_PAD + 4, RY, Blue, S)
  Else
   DrawTextAt(X0 + OFD_PAD + 4, RY, Black, S);
  If Not FD_Entries[EI].IsDir Then Begin
   T := I2S(FD_Entries[EI].Size);
   If EI = FD_Sel Then
    DrawTextAt(X1 - OFD_PAD - 20 - Length(T) * 8, RY, White, T)
   Else
    DrawTextAt(X1 - OFD_PAD - 20 - Length(T) * 8, RY, DarkGray, T);
  End;
 End;
 FillRect(X1 - OFD_PAD - 14, Y0 + OFD_TBH + 22,
          X1 - OFD_PAD, Y0 + OFD_TBH + 36, LightGray);
 FrameRect(X1 - OFD_PAD - 14, Y0 + OFD_TBH + 22,
           X1 - OFD_PAD, Y0 + OFD_TBH + 36, Black);
 DrawTextAt(X1 - OFD_PAD - 10, Y0 + OFD_TBH + 26, Black, #24);
 FillRect(X1 - OFD_PAD - 14, ListBot - 14,
          X1 - OFD_PAD, ListBot, LightGray);
 FrameRect(X1 - OFD_PAD - 14, ListBot - 14,
           X1 - OFD_PAD, ListBot, Black);
 DrawTextAt(X1 - OFD_PAD - 10, ListBot - 10, Black, #25);
 DrawTextAt(X0 + OFD_PAD, Y1 - 70, Black, L('Nom :', 'Name:'));
 FillRect(X0 + OFD_PAD + 48, Y1 - 74, X1 - OFD_PAD, Y1 - 56, White);
 FrameRect(X0 + OFD_PAD + 48, Y1 - 74, X1 - OFD_PAD, Y1 - 56, DarkGray);
 DrawTextAt(X0 + OFD_PAD + 52, Y1 - 70, Black, FD_Input + '_');
 DrawTextAt(X0 + OFD_PAD, Y1 - 46, Black, L('Type :', 'Type:'));
 FillRect(X0 + OFD_PAD + 48, Y1 - 50, X1 - OFD_PAD - 200, Y1 - 32, White);
 FrameRect(X0 + OFD_PAD + 48, Y1 - 50, X1 - OFD_PAD - 200, Y1 - 32, DarkGray);
 DrawTextAt(X0 + OFD_PAD + 52, Y1 - 46, Black, OFD_FilterDesc(FD_Filter));
 FillRect(X1 - OFD_PAD - OFD_BTN_W * 2 - 8, Y1 - 26,
          X1 - OFD_PAD - OFD_BTN_W - 8, Y1 - 4, LightGray);
 FrameRect3D(X1 - OFD_PAD - OFD_BTN_W * 2 - 8, Y1 - 26,
             X1 - OFD_PAD - OFD_BTN_W - 8, Y1 - 4, White, DarkGray);
 If FD_Save Then S := L('Enregistrer', 'Save')
            Else S := L('Ouvrir', 'Open');
 DrawTextAt(X1 - OFD_PAD - OFD_BTN_W * 2 - 8 +
            (OFD_BTN_W - Length(S) * 8) Div 2,
            Y1 - 19, Black, S);
 FillRect(X1 - OFD_PAD - OFD_BTN_W, Y1 - 26,
          X1 - OFD_PAD, Y1 - 4, LightGray);
 FrameRect3D(X1 - OFD_PAD - OFD_BTN_W, Y1 - 26,
             X1 - OFD_PAD, Y1 - 4, White, DarkGray);
 S := L('Annuler', 'Cancel');
 DrawTextAt(X1 - OFD_PAD - OFD_BTN_W + (OFD_BTN_W - Length(S) * 8) Div 2,
            Y1 - 19, Black, S);
End;

Procedure OFD_Confirm;
Var Nm: String;
Begin
 If (FD_Sel >= 1) And (FD_Sel <= FD_Count) And FD_Entries[FD_Sel].IsDir Then Begin
  Nm := FD_Entries[FD_Sel].Name;
  If Nm = '..' Then OFD_GoUp
  Else FD_Path := FD_Path + Nm + '\';
  OFD_ScanDir;
  Exit;
 End;
 If FD_Input = '' Then Begin
  If (FD_Sel >= 1) And (FD_Sel <= FD_Count) And
     Not FD_Entries[FD_Sel].IsDir Then
   FD_Input := FD_Entries[FD_Sel].Name;
 End;
 If FD_Input = '' Then Exit;
 FD_Done := True;
 FD_OK   := True;
End;

Procedure OFD_HandleClick(MX, MY: Integer);
Var X0, Y0, X1, Y1, Rows, ListBot, EI, Row: Integer;
    LX0, LX1, BX0, BX1: Integer;
Begin
 X0 := FD_X; Y0 := FD_Y;
 X1 := X0 + OFD_W; Y1 := Y0 + OFD_H;
 Rows := OFD_VisibleRows;
 ListBot := Y0 + OFD_TBH + 22 + Rows * OFD_ROW_H + 2;
 LX0 := X0 + OFD_PAD;
 LX1 := X1 - OFD_PAD - 16;
 If (MX >= LX0) And (MX <= LX1) And
    (MY >= Y0 + OFD_TBH + 22) And (MY <= ListBot) Then Begin
  Row := (MY - (Y0 + OFD_TBH + 24)) Div OFD_ROW_H + 1;
  EI := FD_Scroll + Row;
  If (EI >= 1) And (EI <= FD_Count) Then Begin
   If EI = FD_Sel Then OFD_Confirm
                  Else FD_Sel := EI;
  End;
  Exit;
 End;
 If (MX >= X1 - OFD_PAD - 14) And (MX <= X1 - OFD_PAD) Then Begin
  If (MY >= Y0 + OFD_TBH + 22) And (MY <= Y0 + OFD_TBH + 36) Then Begin
   If FD_Scroll > 0 Then Dec(FD_Scroll);
   Exit;
  End;
  If (MY >= ListBot - 14) And (MY <= ListBot) Then Begin
   If FD_Scroll + Rows < FD_Count Then Inc(FD_Scroll);
   Exit;
  End;
 End;
 BX0 := X0 + OFD_PAD + 48;
 BX1 := X1 - OFD_PAD - 200;
 If (MX >= BX0) And (MX <= BX1) And
    (MY >= Y1 - 50) And (MY <= Y1 - 32) Then Begin
  Inc(FD_Filter);
  If FD_Filter >= OFD_FILTER_COUNT Then FD_Filter := 0;
  OFD_ScanDir;
  Exit;
 End;
 BX0 := X1 - OFD_PAD - OFD_BTN_W * 2 - 8;
 BX1 := X1 - OFD_PAD - OFD_BTN_W - 8;
 If (MX >= BX0) And (MX <= BX1) And
    (MY >= Y1 - 26) And (MY <= Y1 - 4) Then Begin
  OFD_Confirm;
  Exit;
 End;
 BX0 := X1 - OFD_PAD - OFD_BTN_W;
 BX1 := X1 - OFD_PAD;
 If (MX >= BX0) And (MX <= BX1) And
    (MY >= Y1 - 26) And (MY <= Y1 - 4) Then Begin
  FD_Done := True;
  FD_OK   := False;
 End;
End;

Function ShowFileDialog(SaveMode: Boolean;
                        Const DefName: String;
                        InitFilter: Integer;
                        Var Chosen: String): Boolean;
Var Btn, OldBtn, MX, MY: LongInt;
    Ch, Ch2: Char;
    Dir: String;
Begin
 FD_Save  := SaveMode;
 FD_Input := DefName;
 GetDir(0, Dir);
 If Dir[Length(Dir)] <> '\' Then Dir := Dir + '\';
 FD_Path   := Dir;
 If (InitFilter < 0) Or (InitFilter >= OFD_FILTER_COUNT) Then
  FD_Filter := 0
 Else
  FD_Filter := InitFilter;
 FD_Done   := False;
 FD_OK     := False;
 FD_X := (SCR_W - OFD_W) Div 2;
 FD_Y := (SCR_H - OFD_H) Div 2;
 OFD_ScanDir;
 HideMouse; OFD_Draw; ShowMouse;
 OldBtn := 0;
 Repeat
  If KeyPressed Then Begin
   Ch := ReadKey;
   If Ch = #0 Then Begin
    Ch2 := ReadKey;
    Case Ch2 Of
     #72: If FD_Sel > 1 Then Begin
           Dec(FD_Sel);
           If FD_Sel < FD_Scroll + 1 Then Dec(FD_Scroll);
          End;
     #80: If FD_Sel < FD_Count Then Begin
           Inc(FD_Sel);
           If FD_Sel > FD_Scroll + OFD_VisibleRows Then Inc(FD_Scroll);
          End;
     #73: Begin
           FD_Sel := FD_Sel - OFD_VisibleRows;
           If FD_Sel < 1 Then FD_Sel := 1;
           FD_Scroll := FD_Sel - 1;
           If FD_Scroll < 0 Then FD_Scroll := 0;
          End;
     #81: Begin
           FD_Sel := FD_Sel + OFD_VisibleRows;
           If FD_Sel > FD_Count Then FD_Sel := FD_Count;
           FD_Scroll := FD_Sel - OFD_VisibleRows;
           If FD_Scroll < 0 Then FD_Scroll := 0;
          End;
     #71: Begin FD_Sel := 1; FD_Scroll := 0; End;
     #79: Begin
           FD_Sel := FD_Count;
           FD_Scroll := FD_Count - OFD_VisibleRows;
           If FD_Scroll < 0 Then FD_Scroll := 0;
          End;
    End;
   End
   Else Case Ch Of
    #13: OFD_Confirm;
    #27: Begin FD_Done := True; FD_OK := False; End;
    #9 : Begin
          Inc(FD_Filter);
          If FD_Filter >= OFD_FILTER_COUNT Then FD_Filter := 0;
          OFD_ScanDir;
         End;
    #8 : If Length(FD_Input) > 0 Then
          FD_Input[0] := Chr(Length(FD_Input) - 1);
   Else
    If (Ch >= #32) And (Length(FD_Input) < 80) Then
     FD_Input := FD_Input + Ch;
   End;
   HideMouse; OFD_Draw; ShowMouse;
  End;
  GetMouseState(MX, MY, Btn);
  If ((Btn And MB_LEFT) = MB_LEFT) And ((OldBtn And MB_LEFT) = 0) Then Begin
   HideMouse;
   OFD_HandleClick(Integer(MX), Integer(MY));
   OFD_Draw;
   ShowMouse;
  End;
  OldBtn := Btn;
  Delay(10);
 Until FD_Done;
 If FD_OK Then Chosen := FD_Path + FD_Input;
 HideMouse; RefreshScreen; ShowMouse;
 ShowFileDialog := FD_OK;
End;

{ ============================================================ }
{ ===========  SAUVEGARDE BINAIRE .ONE (Phase 7)  ============= }
{ ============================================================ }

Const
 ONE_MAGIC   : String[8] = 'ONENOTE0';
 ONE_VERSION = 2;     { Phase 12 : v2 ajoute le bloc strokes par page }
 ONE_VER_V1  = 1;

Type
 TOneHeader = Packed Record
  Magic       : Array[1..8] Of Char;
  Version     : Word;
  Reserved    : Word;
  SectionCount: Word;
 End;
 TOneSecHdr = Packed Record
  Color       : Byte;
  PageCount   : Word;
  CurPage     : Word;
 End;
 TOnePgHdr = Packed Record
  CreatedTS   : LongInt;
  ParaCount   : Word;
  ExtraCount  : Word;
 End;
 TOneParaHdr = Packed Record
  Indent      : Byte;
  Flags       : Byte;   { b0=Bullet b1=Bold b2=Italic b3=Under }
  Tag         : Byte;
  TxtLen      : Word;
 End;
 TOneExtraHdr = Packed Record
  X, Y, W, H  : Integer;
  Flags       : Byte;   { b0=Bold b1=Italic b2=Under b3=IsImage }
  Tag         : Byte;
  TxtLen      : Word;
  ImgW, ImgH  : Word;
 End;

Procedure SaveWrStr(Var F: File; Const S: String);
Var L: Byte;
Begin
 L := Length(S);
 BlockWrite(F, L, 1);
 If L > 0 Then BlockWrite(F, S[1], L);
End;

{ Phase 12 : ecrit le bloc strokes d'une page (toujours en v2). }
Procedure SaveWrStrokes(Var F: File; Var Pg: TPage);
Var I: Integer; W: Word; B: Byte;
Begin
 W := Pg.StrokeCount;
 BlockWrite(F, W, 2);
 For I := 1 To Pg.StrokeCount Do Begin
  B := Pg.Strokes[I].Color;
  BlockWrite(F, B, 1);
  W := Pg.Strokes[I].PtCount;
  BlockWrite(F, W, 2);
  If W > 0 Then
   BlockWrite(F, Pg.Strokes[I].Pts[1], LongInt(W) * SizeOf(TStrokePt));
 End;
End;

{ Phase 12 : lit le bloc strokes d'une page (uniquement si Version >= 2). }
Function LoadRdStrokes(Var F: File; Var Pg: TPage): Boolean;
Var I: Integer; W, N: Word; B: Byte;
Begin
 LoadRdStrokes := False;
 {$I-} BlockRead(F, N, 2); {$I+}
 If IOResult <> 0 Then Exit;
 If N > MAX_STROKES Then Exit;
 Pg.StrokeCount := N;
 For I := 1 To N Do Begin
  BlockRead(F, B, 1);
  Pg.Strokes[I].Color := B;
  BlockRead(F, W, 2);
  If W > MAX_STROKE_PTS Then Exit;
  Pg.Strokes[I].PtCount := W;
  If W > 0 Then
   BlockRead(F, Pg.Strokes[I].Pts[1], LongInt(W) * SizeOf(TStrokePt));
 End;
 LoadRdStrokes := True;
End;

Function SaveOneFile(Const FN: String): Boolean;
Var F: File;
    H : TOneHeader;
    SH: TOneSecHdr;
    PH: TOnePgHdr;
    PaH: TOneParaHdr;
    EH : TOneExtraHdr;
    Sec: PSection;
    Pg : PPage;
    Pa : ^TParagraph;
    Ex : ^TExtra;
    PB : ^Byte;
    I, J, K  : Integer;
    ImgSz    : LongInt;
    OK       : Boolean;
Begin
 OK := False;
 Assign(F, FN);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin SaveOneFile := False; Exit; End;

 { Header global. }
 For I := 1 To 8 Do H.Magic[I] := ONE_MAGIC[I];
 H.Version := ONE_VERSION;
 H.Reserved := 0;
 H.SectionCount := Book.SectionCount;
 {$I-} BlockWrite(F, H, SizeOf(H)); {$I+}
 If IOResult <> 0 Then Begin Close(F); SaveOneFile := False; Exit; End;

 { Nom du bloc-notes. }
 SaveWrStr(F, Book.Name);

 For I := 1 To Book.SectionCount Do Begin
  Sec := @Book.Sections[I];
  SaveWrStr(F, Sec^.Name);
  SH.Color     := Sec^.Color;
  SH.PageCount := Sec^.PageCount;
  SH.CurPage   := Sec^.CurPage;
  BlockWrite(F, SH, SizeOf(SH));

  For J := 1 To Sec^.PageCount Do Begin
   Pg := @Sec^.Pages[J];
   SaveWrStr(F, Pg^.Title);
   PH.CreatedTS  := Pg^.CreatedTS;
   PH.ParaCount  := Pg^.ParaCount;
   PH.ExtraCount := Pg^.ExtraCount;
   BlockWrite(F, PH, SizeOf(PH));

   For K := 1 To Pg^.ParaCount Do Begin
    Pa := @Pg^.Para[K];
    PaH.Indent := Pa^.Indent;
    PaH.Flags  := 0;
    If Pa^.Bullet Then PaH.Flags := PaH.Flags Or 1;
    If Pa^.Bold   Then PaH.Flags := PaH.Flags Or 2;
    If Pa^.Italic Then PaH.Flags := PaH.Flags Or 4;
    If Pa^.Under  Then PaH.Flags := PaH.Flags Or 8;
    PaH.Tag    := Pa^.Tag;
    PaH.TxtLen := Length(Pa^.Txt);
    BlockWrite(F, PaH, SizeOf(PaH));
    If PaH.TxtLen > 0 Then BlockWrite(F, Pa^.Txt[1], PaH.TxtLen);
   End;

   For K := 1 To Pg^.ExtraCount Do Begin
    Ex := @Pg^.Extras[K];
    EH.X := Ex^.X; EH.Y := Ex^.Y;
    EH.W := Ex^.W; EH.H := Ex^.H;
    EH.Flags := 0;
    If Ex^.Bold    Then EH.Flags := EH.Flags Or 1;
    If Ex^.Italic  Then EH.Flags := EH.Flags Or 2;
    If Ex^.Under   Then EH.Flags := EH.Flags Or 4;
    If Ex^.IsImage Then EH.Flags := EH.Flags Or 8;
    EH.Tag    := Ex^.Tag;
    EH.TxtLen := Length(Ex^.Txt);
    If Ex^.IsImage Then Begin
     EH.ImgW := Ex^.ImgW;
     EH.ImgH := Ex^.ImgH;
    End Else Begin
     EH.ImgW := 0;
     EH.ImgH := 0;
    End;
    BlockWrite(F, EH, SizeOf(EH));
    If EH.TxtLen > 0 Then BlockWrite(F, Ex^.Txt[1], EH.TxtLen);
    If Ex^.IsImage And (Ex^.Pixels <> Nil) Then Begin
     ImgSz := LongInt(Ex^.ImgW) * Ex^.ImgH;
     If ImgSz > 0 Then Begin
      PB := Ex^.Pixels;
      BlockWrite(F, PB^, ImgSz);
     End;
    End;
   End;
   { Phase 12 : bloc strokes en fin de page }
   SaveWrStrokes(F, Pg^);
  End;
 End;
 OK := True;

 Close(F);
 SaveOneFile := OK;
End;

{ ============================================================ }
{ ============  LECTURE BINAIRE .ONE (Phase 8)  =============== }
{ ============================================================ }

Procedure FreeBookImages;
Var I, J, K: Integer; Pg: PPage;
Begin
 For I := 1 To Book.SectionCount Do
  For J := 1 To Book.Sections[I].PageCount Do Begin
   Pg := @Book.Sections[I].Pages[J];
   For K := 1 To Pg^.ExtraCount Do
    FreeExtraImage(Pg^.Extras[K]);
  End;
End;

Function LoadRdStr(Var F: File): String;
Var L: Byte; S: String;
Begin
 S := '';
 BlockRead(F, L, 1);
 S[0] := Chr(L);
 If L > 0 Then BlockRead(F, S[1], L);
 LoadRdStr := S;
End;

Function LoadRdSized(Var F: File; L: Word; MaxLen: Integer): String;
Var ReadL: Integer; Skip: LongInt; B: Byte; S: String;
Begin
 S := '';
 If L = 0 Then Begin LoadRdSized := S; Exit; End;
 ReadL := L;
 If ReadL > MaxLen Then ReadL := MaxLen;
 If ReadL > 255    Then ReadL := 255;
 If ReadL > 0 Then Begin
  S[0] := Chr(ReadL);
  BlockRead(F, S[1], ReadL);
 End;
 Skip := LongInt(L) - ReadL;
 While Skip > 0 Do Begin BlockRead(F, B, 1); Dec(Skip); End;
 LoadRdSized := S;
End;

Function LoadOneFile(Const FN: String): Boolean;
Var F  : File;
    H  : TOneHeader;
    SH : TOneSecHdr;
    PH : TOnePgHdr;
    PaH: TOneParaHdr;
    EH : TOneExtraHdr;
    Sec: PSection;
    Pg : PPage;
    Pa : ^TParagraph;
    Ex : ^TExtra;
    PB : ^Byte;
    I, J, K  : Integer;
    ImgSz    : LongInt;
    MagicOK  : Boolean;
Begin
 LoadOneFile := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 {$I-} BlockRead(F, H, SizeOf(H)); {$I+}
 If IOResult <> 0 Then Begin Close(F); Exit; End;

 MagicOK := True;
 For I := 1 To 8 Do
  If H.Magic[I] <> ONE_MAGIC[I] Then MagicOK := False;
 If (Not MagicOK) Or ((H.Version <> 1) And (H.Version <> 2)) Then Begin
  Close(F); Exit;
 End;
 If H.SectionCount > MAX_SECTIONS Then Begin Close(F); Exit; End;

 { Liberer toutes les images existantes, puis tout remettre a zero. }
 FreeBookImages;
 FillChar(Book, SizeOf(Book), 0);

 Book.FilePath     := FN;
 Book.Modified     := False;
 Book.SectionCount := H.SectionCount;
 Book.CurSection   := 1;
 Book.Name         := LoadRdStr(F);

 For I := 1 To H.SectionCount Do Begin
  Sec := @Book.Sections[I];
  Sec^.Name := LoadRdStr(F);
  BlockRead(F, SH, SizeOf(SH));
  Sec^.Color := SH.Color;
  If SH.PageCount > MAX_PAGES Then Begin Close(F); Exit; End;
  Sec^.PageCount := SH.PageCount;
  Sec^.CurPage   := SH.CurPage;
  If Sec^.CurPage < 1 Then Sec^.CurPage := 1;
  If Sec^.CurPage > Sec^.PageCount Then Sec^.CurPage := Sec^.PageCount;
  If Sec^.PageCount = 0 Then Sec^.CurPage := 1;

  For J := 1 To SH.PageCount Do Begin
   Pg := @Sec^.Pages[J];
   Pg^.Title := LoadRdStr(F);
   BlockRead(F, PH, SizeOf(PH));
   If PH.ParaCount > MAX_PARA Then Begin Close(F); Exit; End;
   If PH.ExtraCount > MAX_EXTRAS Then Begin Close(F); Exit; End;
   Pg^.CreatedTS  := PH.CreatedTS;
   Pg^.ParaCount  := PH.ParaCount;
   Pg^.ExtraCount := PH.ExtraCount;

   For K := 1 To PH.ParaCount Do Begin
    Pa := @Pg^.Para[K];
    BlockRead(F, PaH, SizeOf(PaH));
    Pa^.Indent := PaH.Indent;
    Pa^.Bullet := (PaH.Flags And 1) <> 0;
    Pa^.Bold   := (PaH.Flags And 2) <> 0;
    Pa^.Italic := (PaH.Flags And 4) <> 0;
    Pa^.Under  := (PaH.Flags And 8) <> 0;
    Pa^.Tag    := PaH.Tag;
    Pa^.Txt    := LoadRdSized(F, PaH.TxtLen, MAX_PARA_LEN);
   End;

   For K := 1 To PH.ExtraCount Do Begin
    Ex := @Pg^.Extras[K];
    BlockRead(F, EH, SizeOf(EH));
    Ex^.X := EH.X; Ex^.Y := EH.Y;
    Ex^.W := EH.W; Ex^.H := EH.H;
    Ex^.Bold    := (EH.Flags And 1) <> 0;
    Ex^.Italic  := (EH.Flags And 2) <> 0;
    Ex^.Under   := (EH.Flags And 4) <> 0;
    Ex^.IsImage := (EH.Flags And 8) <> 0;
    Ex^.Tag     := EH.Tag;
    Ex^.Txt     := LoadRdSized(F, EH.TxtLen, EXTRA_TXT_LEN);
    Ex^.ImgW    := EH.ImgW;
    Ex^.ImgH    := EH.ImgH;
    Ex^.Pixels  := Nil;
    If Ex^.IsImage Then Begin
     If (Ex^.ImgW <= 0) Or (Ex^.ImgH <= 0) Or
        (Ex^.ImgW > MAX_IMG_W) Or (Ex^.ImgH > MAX_IMG_H) Then Begin
      Close(F); Exit;
     End;
     ImgSz := LongInt(Ex^.ImgW) * Ex^.ImgH;
     GetMem(Ex^.Pixels, ImgSz);
     PB := Ex^.Pixels;
     BlockRead(F, PB^, ImgSz);
    End;
   End;
   { Phase 12 : bloc strokes (uniquement en v2). }
   If H.Version >= 2 Then Begin
    If Not LoadRdStrokes(F, Pg^) Then Begin Close(F); Exit; End;
   End
   Else Pg^.StrokeCount := 0;
  End;
 End;
 Close(F);
 LoadOneFile := True;
End;

{ ============================================================ }
{ ===============  SOMMAIRE .ONETOC2 (Phase 9)  =============== }
{ ============================================================ }

Const
 TOC_MAGIC   : Array[1..8] Of Char = ('O','N','E','T','O','C','2',#0);
 TOC_VERSION = 1;

Type
 TTocHeader = Packed Record
  Magic       : Array[1..8] Of Char;
  Version     : Word;
  Reserved    : Word;
  SectionCount: Word;
  CurSection  : Word;
 End;
 TTocEntry = Packed Record
  Color       : Byte;
  PageCount   : Word;
 End;

Function PathDir(Const P: String): String;
Var I: Integer;
Begin
 PathDir := '';
 For I := Length(P) DownTo 1 Do
  If (P[I] = '\') Or (P[I] = '/') Then Begin
   PathDir := Copy(P, 1, I); Exit;
  End;
End;

Function PathName(Const P: String): String;
Var I: Integer;
Begin
 PathName := P;
 For I := Length(P) DownTo 1 Do
  If (P[I] = '\') Or (P[I] = '/') Then Begin
   PathName := Copy(P, I + 1, 255); Exit;
  End;
End;

Function PathExtUp(Const P: String): String;
Var I, J: Integer; R: String;
Begin
 R := '';
 For I := Length(P) DownTo 1 Do Begin
  If (P[I] = '\') Or (P[I] = '/') Then Break;
  If P[I] = '.' Then Begin
   R := Copy(P, I, Length(P) - I + 1);
   For J := 1 To Length(R) Do R[J] := UpCase(R[J]);
   PathExtUp := R; Exit;
  End;
 End;
 PathExtUp := '';
End;

Function SanitizeSecName(Const Name: String): String;
Var I: Integer; R: String; C: Char;
Begin
 R := '';
 For I := 1 To Length(Name) Do Begin
  C := Name[I];
  If ((C >= 'A') And (C <= 'Z')) Or
     ((C >= 'a') And (C <= 'z')) Or
     ((C >= '0') And (C <= '9')) Or
     (C = '_') Or (C = '-') Then R := R + C
  Else R := R + '_';
 End;
 If R = '' Then R := 'SECTION';
 If Length(R) > 32 Then R := Copy(R, 1, 32);
 SanitizeSecName := R;
End;

{ Ecrit une section unique dans un fichier .ONE (SectionCount=1). }
Function SaveSectionAsOneFile(Const FN: String; SecIdx: Integer): Boolean;
Var F  : File;
    H  : TOneHeader;
    SH : TOneSecHdr;
    PH : TOnePgHdr;
    PaH: TOneParaHdr;
    EH : TOneExtraHdr;
    Sec: PSection;
    Pg : PPage;
    Pa : ^TParagraph;
    Ex : ^TExtra;
    PB : ^Byte;
    I, J, K: Integer;
    ImgSz: LongInt;
Begin
 SaveSectionAsOneFile := False;
 If (SecIdx < 1) Or (SecIdx > Book.SectionCount) Then Exit;
 Sec := @Book.Sections[SecIdx];
 Assign(F, FN);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 For I := 1 To 8 Do H.Magic[I] := ONE_MAGIC[I];
 H.Version := ONE_VERSION;
 H.Reserved := 0;
 H.SectionCount := 1;
 BlockWrite(F, H, SizeOf(H));

 SaveWrStr(F, Book.Name);
 SaveWrStr(F, Sec^.Name);
 SH.Color     := Sec^.Color;
 SH.PageCount := Sec^.PageCount;
 SH.CurPage   := Sec^.CurPage;
 BlockWrite(F, SH, SizeOf(SH));

 For J := 1 To Sec^.PageCount Do Begin
  Pg := @Sec^.Pages[J];
  SaveWrStr(F, Pg^.Title);
  PH.CreatedTS  := Pg^.CreatedTS;
  PH.ParaCount  := Pg^.ParaCount;
  PH.ExtraCount := Pg^.ExtraCount;
  BlockWrite(F, PH, SizeOf(PH));

  For K := 1 To Pg^.ParaCount Do Begin
   Pa := @Pg^.Para[K];
   PaH.Indent := Pa^.Indent;
   PaH.Flags  := 0;
   If Pa^.Bullet Then PaH.Flags := PaH.Flags Or 1;
   If Pa^.Bold   Then PaH.Flags := PaH.Flags Or 2;
   If Pa^.Italic Then PaH.Flags := PaH.Flags Or 4;
   If Pa^.Under  Then PaH.Flags := PaH.Flags Or 8;
   PaH.Tag    := Pa^.Tag;
   PaH.TxtLen := Length(Pa^.Txt);
   BlockWrite(F, PaH, SizeOf(PaH));
   If PaH.TxtLen > 0 Then BlockWrite(F, Pa^.Txt[1], PaH.TxtLen);
  End;

  For K := 1 To Pg^.ExtraCount Do Begin
   Ex := @Pg^.Extras[K];
   EH.X := Ex^.X; EH.Y := Ex^.Y;
   EH.W := Ex^.W; EH.H := Ex^.H;
   EH.Flags := 0;
   If Ex^.Bold    Then EH.Flags := EH.Flags Or 1;
   If Ex^.Italic  Then EH.Flags := EH.Flags Or 2;
   If Ex^.Under   Then EH.Flags := EH.Flags Or 4;
   If Ex^.IsImage Then EH.Flags := EH.Flags Or 8;
   EH.Tag    := Ex^.Tag;
   EH.TxtLen := Length(Ex^.Txt);
   If Ex^.IsImage Then Begin
    EH.ImgW := Ex^.ImgW;
    EH.ImgH := Ex^.ImgH;
   End Else Begin
    EH.ImgW := 0;
    EH.ImgH := 0;
   End;
   BlockWrite(F, EH, SizeOf(EH));
   If EH.TxtLen > 0 Then BlockWrite(F, Ex^.Txt[1], EH.TxtLen);
   If Ex^.IsImage And (Ex^.Pixels <> Nil) Then Begin
    ImgSz := LongInt(Ex^.ImgW) * Ex^.ImgH;
    If ImgSz > 0 Then Begin
     PB := Ex^.Pixels;
     BlockWrite(F, PB^, ImgSz);
    End;
   End;
  End;
  { Phase 12 : bloc strokes en fin de page }
  SaveWrStrokes(F, Pg^);
 End;
 Close(F);
 SaveSectionAsOneFile := True;
End;

{ Lit une section depuis un fichier .ONE mono-section dans Sec. }
Function LoadSectionFromOne(Const FN: String; Var Sec: TSection): Boolean;
Var F  : File;
    H  : TOneHeader;
    SH : TOneSecHdr;
    PH : TOnePgHdr;
    PaH: TOneParaHdr;
    EH : TOneExtraHdr;
    Pg : PPage;
    Pa : ^TParagraph;
    Ex : ^TExtra;
    PB : ^Byte;
    I, J, K: Integer;
    ImgSz: LongInt;
    MagicOK: Boolean;
    Dummy: String;
Begin
 LoadSectionFromOne := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 {$I-} BlockRead(F, H, SizeOf(H)); {$I+}
 If IOResult <> 0 Then Begin Close(F); Exit; End;

 MagicOK := True;
 For I := 1 To 8 Do
  If H.Magic[I] <> ONE_MAGIC[I] Then MagicOK := False;
 If (Not MagicOK) Or ((H.Version <> 1) And (H.Version <> 2)) Or (H.SectionCount < 1) Then Begin
  Close(F); Exit;
 End;

 Dummy := LoadRdStr(F);   { Book.Name ignore }

 { Libere les images de la section cible. }
 For I := 1 To Sec.PageCount Do
  For J := 1 To Sec.Pages[I].ExtraCount Do
   FreeExtraImage(Sec.Pages[I].Extras[J]);
 FillChar(Sec, SizeOf(Sec), 0);

 Sec.Name := LoadRdStr(F);
 BlockRead(F, SH, SizeOf(SH));
 Sec.Color := SH.Color;
 If SH.PageCount > MAX_PAGES Then Begin Close(F); Exit; End;
 Sec.PageCount := SH.PageCount;
 Sec.CurPage   := SH.CurPage;
 If Sec.CurPage < 1 Then Sec.CurPage := 1;
 If Sec.CurPage > Sec.PageCount Then Sec.CurPage := Sec.PageCount;
 If Sec.PageCount = 0 Then Sec.CurPage := 1;

 For J := 1 To SH.PageCount Do Begin
  Pg := @Sec.Pages[J];
  Pg^.Title := LoadRdStr(F);
  BlockRead(F, PH, SizeOf(PH));
  If (PH.ParaCount > MAX_PARA) Or (PH.ExtraCount > MAX_EXTRAS) Then Begin
   Close(F); Exit;
  End;
  Pg^.CreatedTS  := PH.CreatedTS;
  Pg^.ParaCount  := PH.ParaCount;
  Pg^.ExtraCount := PH.ExtraCount;

  For K := 1 To PH.ParaCount Do Begin
   Pa := @Pg^.Para[K];
   BlockRead(F, PaH, SizeOf(PaH));
   Pa^.Indent := PaH.Indent;
   Pa^.Bullet := (PaH.Flags And 1) <> 0;
   Pa^.Bold   := (PaH.Flags And 2) <> 0;
   Pa^.Italic := (PaH.Flags And 4) <> 0;
   Pa^.Under  := (PaH.Flags And 8) <> 0;
   Pa^.Tag    := PaH.Tag;
   Pa^.Txt    := LoadRdSized(F, PaH.TxtLen, MAX_PARA_LEN);
  End;

  For K := 1 To PH.ExtraCount Do Begin
   Ex := @Pg^.Extras[K];
   BlockRead(F, EH, SizeOf(EH));
   Ex^.X := EH.X; Ex^.Y := EH.Y;
   Ex^.W := EH.W; Ex^.H := EH.H;
   Ex^.Bold    := (EH.Flags And 1) <> 0;
   Ex^.Italic  := (EH.Flags And 2) <> 0;
   Ex^.Under   := (EH.Flags And 4) <> 0;
   Ex^.IsImage := (EH.Flags And 8) <> 0;
   Ex^.Tag     := EH.Tag;
   Ex^.Txt     := LoadRdSized(F, EH.TxtLen, EXTRA_TXT_LEN);
   Ex^.ImgW    := EH.ImgW;
   Ex^.ImgH    := EH.ImgH;
   Ex^.Pixels  := Nil;
   If Ex^.IsImage Then Begin
    If (Ex^.ImgW <= 0) Or (Ex^.ImgH <= 0) Or
       (Ex^.ImgW > MAX_IMG_W) Or (Ex^.ImgH > MAX_IMG_H) Then Begin
     Close(F); Exit;
    End;
    ImgSz := LongInt(Ex^.ImgW) * Ex^.ImgH;
    GetMem(Ex^.Pixels, ImgSz);
    PB := Ex^.Pixels;
    BlockRead(F, PB^, ImgSz);
   End;
  End;
  { Phase 12 : bloc strokes (uniquement en v2). }
  If H.Version >= 2 Then Begin
   If Not LoadRdStrokes(F, Pg^) Then Begin Close(F); Exit; End;
  End
  Else Pg^.StrokeCount := 0;
 End;
 Close(F);
 LoadSectionFromOne := True;
End;

Function SaveTocFile(Const FN: String): Boolean;
Var F : File;
    TH: TTocHeader;
    TE: TTocEntry;
    Dir, OneFN, RelFN, SafeName: String;
    I: Integer;
    OK: Boolean;
Begin
 SaveTocFile := False;
 Dir := PathDir(FN);

 { Sauve chaque section dans son propre .ONE a cote du TOC. }
 OK := True;
 For I := 1 To Book.SectionCount Do Begin
  SafeName := SanitizeSecName(Book.Sections[I].Name);
  OneFN := Dir + SafeName + '.ONE';
  If Not SaveSectionAsOneFile(OneFN, I) Then OK := False;
 End;
 If Not OK Then Exit;

 Assign(F, FN);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 For I := 1 To 8 Do TH.Magic[I] := TOC_MAGIC[I];
 TH.Version      := TOC_VERSION;
 TH.Reserved     := 0;
 TH.SectionCount := Book.SectionCount;
 TH.CurSection   := Book.CurSection;
 BlockWrite(F, TH, SizeOf(TH));

 SaveWrStr(F, Book.Name);

 For I := 1 To Book.SectionCount Do Begin
  SafeName := SanitizeSecName(Book.Sections[I].Name);
  RelFN := SafeName + '.ONE';
  SaveWrStr(F, RelFN);
  SaveWrStr(F, Book.Sections[I].Name);
  TE.Color     := Book.Sections[I].Color;
  TE.PageCount := Book.Sections[I].PageCount;
  BlockWrite(F, TE, SizeOf(TE));
 End;

 Close(F);
 SaveTocFile := True;
End;

Function LoadTocFile(Const FN: String): Boolean;
Var F : File;
    TH: TTocHeader;
    TE: TTocEntry;
    Dir, RelFN, FullFN, NotebookName, SecName: String;
    I: Integer;
    MagicOK: Boolean;
    NSec: Integer;
Begin
 LoadTocFile := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 {$I-} BlockRead(F, TH, SizeOf(TH)); {$I+}
 If IOResult <> 0 Then Begin Close(F); Exit; End;

 MagicOK := True;
 For I := 1 To 8 Do
  If TH.Magic[I] <> TOC_MAGIC[I] Then MagicOK := False;
 If (Not MagicOK) Or (TH.Version <> TOC_VERSION) Or
    (TH.SectionCount > MAX_SECTIONS) Then Begin
  Close(F); Exit;
 End;

 NotebookName := LoadRdStr(F);
 Dir := PathDir(FN);

 { Reinitialise le bloc-notes. }
 FreeBookImages;
 FillChar(Book, SizeOf(Book), 0);
 Book.FilePath := FN;
 Book.Name     := NotebookName;
 Book.Modified := False;
 NSec := TH.SectionCount;
 Book.SectionCount := NSec;
 Book.CurSection   := TH.CurSection;
 If Book.CurSection < 1 Then Book.CurSection := 1;
 If Book.CurSection > NSec Then Book.CurSection := NSec;
 If NSec = 0 Then Book.CurSection := 1;

 For I := 1 To NSec Do Begin
  RelFN   := LoadRdStr(F);
  SecName := LoadRdStr(F);
  BlockRead(F, TE, SizeOf(TE));
  Book.Sections[I].Name  := SecName;
  Book.Sections[I].Color := TE.Color;
  FullFN := Dir + RelFN;
  If Not LoadSectionFromOne(FullFN, Book.Sections[I]) Then Begin
   { Fallback : on garde nom + couleur du TOC, mais aucune page. }
   Book.Sections[I].Name      := SecName;
   Book.Sections[I].Color     := TE.Color;
   Book.Sections[I].PageCount := 0;
   Book.Sections[I].CurPage   := 1;
  End;
 End;
 Close(F);
 LoadTocFile := True;
End;

{ ============================================================ }
{ ===============  PAQUET .ONEPKG (Phase 10)  ================ }
{ ============================================================ }
{ Format : archive ZIP (methode 0 = stored, sans compression),
  contenant 1 entree .ONETOC2 + 1 entree .ONE par section.
  CRC32 standard PKZIP, en-tetes Little-Endian. }

Const
 PKG_LFH_SIG     : LongInt = $04034B50;
 PKG_CDH_SIG     : LongInt = $02014B50;
 PKG_EOCD_SIG    : LongInt = $06054B50;
 PKG_CRC32_POLY  : LongInt = -306674912;  { = $EDB88320 non-signe }
 MAX_PKG_ENT     = 40;                    { 1 toc + jusqu'a MAX_SECTIONS }
 PKG_BUF_SZ      = 1024;
 PKG_EOCD_SCAN   = 65557;

Var
 PkgCrcTab    : Array[0..255] Of LongInt;
 PkgCrcInited : Boolean;
 PkgF         : File;
 PkgOk        : Boolean;
 PkgEntCount  : Integer;
 PkgEntStart  : Array[1..MAX_PKG_ENT] Of LongInt;
 PkgEntCRCs   : Array[1..MAX_PKG_ENT] Of LongInt;
 PkgEntSizes  : Array[1..MAX_PKG_ENT] Of LongInt;
 PkgEntNames  : Array[1..MAX_PKG_ENT] Of String[64];
 PkgBuf       : Array[0..PKG_BUF_SZ-1] Of Byte;

Procedure PkgInitCrc;
Var I, J: Integer; C: LongInt;
Begin
 If PkgCrcInited Then Exit;
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := LongInt(C Shr 1) Xor PKG_CRC32_POLY
   Else C := C Shr 1;
  PkgCrcTab[I] := C;
 End;
 PkgCrcInited := True;
End;

Procedure PkgWrL(L: LongInt);
Var B: Array[0..3] Of Byte;
Begin
 B[0] := Byte(L And $FF);
 B[1] := Byte((L Shr 8) And $FF);
 B[2] := Byte((L Shr 16) And $FF);
 B[3] := Byte((L Shr 24) And $FF);
 BlockWrite(PkgF, B, 4);
End;

Procedure PkgWrW(W: Word);
Var B: Array[0..1] Of Byte;
Begin
 B[0] := Byte(W And $FF);
 B[1] := Byte((W Shr 8) And $FF);
 BlockWrite(PkgF, B, 2);
End;

{ Lit 4 octets little-endian sur F (untyped, record size = 1). }
Function PkgRdL(Var F: File): LongInt;
Var B: Array[0..3] Of Byte;
Begin
 BlockRead(F, B, 4);
 PkgRdL := LongInt(B[0]) Or (LongInt(B[1]) Shl 8) Or
           (LongInt(B[2]) Shl 16) Or (LongInt(B[3]) Shl 24);
End;

Function PkgRdW(Var F: File): Word;
Var B: Array[0..1] Of Byte;
Begin
 BlockRead(F, B, 2);
 PkgRdW := Word(B[0]) Or (Word(B[1]) Shl 8);
End;

{ Ajoute le contenu de SrcPath comme entree EntName (methode 0). }
Function PkgAddFromFile(Const EntName, SrcPath: String): Boolean;
Var SrcF: File;
    Sz, Off, Remain, EndPos: LongInt;
    ToRead, I, NL: Integer;
    CRC: LongInt;
Begin
 PkgAddFromFile := False;
 If Not PkgOk Then Exit;
 Assign(SrcF, SrcPath);
 {$I-} Reset(SrcF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 Sz := FileSize(SrcF);

 Off := FilePos(PkgF);
 PkgWrL(PKG_LFH_SIG);
 PkgWrW(20);          { version needed }
 PkgWrW(0);           { flags }
 PkgWrW(0);           { method = stored }
 PkgWrW(0);           { mod time }
 PkgWrW(17185);       { mod date (~2013-09-01) }
 PkgWrL(0);           { CRC placeholder }
 PkgWrL(Sz);          { csize }
 PkgWrL(Sz);          { usize }
 NL := Length(EntName);
 PkgWrW(Word(NL));
 PkgWrW(0);
 If NL > 0 Then BlockWrite(PkgF, EntName[1], NL);

 CRC := LongInt($FFFFFFFF);
 Remain := Sz;
 While Remain > 0 Do Begin
  If Remain > PKG_BUF_SZ Then ToRead := PKG_BUF_SZ
                         Else ToRead := Remain;
  BlockRead(SrcF, PkgBuf, ToRead);
  For I := 0 To ToRead - 1 Do
   CRC := PkgCrcTab[Byte((CRC Xor LongInt(PkgBuf[I])) And $FF)] Xor
          LongInt(CRC Shr 8);
  BlockWrite(PkgF, PkgBuf, ToRead);
  Remain := Remain - ToRead;
 End;
 Close(SrcF);
 CRC := CRC Xor LongInt($FFFFFFFF);

 { Patch CRC dans le LFH (offset +14 depuis sig). }
 EndPos := FilePos(PkgF);
 Seek(PkgF, Off + 14);
 PkgWrL(CRC);
 Seek(PkgF, EndPos);

 If PkgEntCount < MAX_PKG_ENT Then Begin
  Inc(PkgEntCount);
  PkgEntStart[PkgEntCount] := Off;
  PkgEntCRCs[PkgEntCount]  := CRC;
  PkgEntSizes[PkgEntCount] := Sz;
  PkgEntNames[PkgEntCount] := EntName;
 End;
 PkgAddFromFile := True;
End;

Procedure PkgWriteCentralDir;
Var CdStart, CdSize: LongInt;
    I, NL: Integer;
Begin
 If Not PkgOk Then Exit;
 CdStart := FilePos(PkgF);
 For I := 1 To PkgEntCount Do Begin
  NL := Length(PkgEntNames[I]);
  PkgWrL(PKG_CDH_SIG);
  PkgWrW(20);   { version made by }
  PkgWrW(20);   { version needed }
  PkgWrW(0);    { flags }
  PkgWrW(0);    { method }
  PkgWrW(0);    { time }
  PkgWrW(17185);{ date }
  PkgWrL(PkgEntCRCs[I]);
  PkgWrL(PkgEntSizes[I]);
  PkgWrL(PkgEntSizes[I]);
  PkgWrW(Word(NL));
  PkgWrW(0);    { extra len }
  PkgWrW(0);    { comment len }
  PkgWrW(0);    { disk number }
  PkgWrW(0);    { internal attr }
  PkgWrL(0);    { external attr }
  PkgWrL(PkgEntStart[I]);
  If NL > 0 Then BlockWrite(PkgF, PkgEntNames[I][1], NL);
 End;
 CdSize := FilePos(PkgF) - CdStart;
 PkgWrL(PKG_EOCD_SIG);
 PkgWrW(0);
 PkgWrW(0);
 PkgWrW(Word(PkgEntCount));
 PkgWrW(Word(PkgEntCount));
 PkgWrL(CdSize);
 PkgWrL(CdStart);
 PkgWrW(0);    { comment len }
End;

{ Renvoie le chemin du repertoire temporaire, avec separateur final. }
Function PkgTempDir: String;
Var S: String;
Begin
 S := GetEnv('TEMP');
 If S = '' Then S := GetEnv('TMP');
 If S = '' Then S := '.';
 If (Length(S) > 0) And (S[Length(S)] <> '\') And (S[Length(S)] <> '/') Then
  S := S + '\';
 PkgTempDir := S;
End;

Function PkgTempSubDir: String;
Begin
 PkgTempSubDir := PkgTempDir + 'ONEPKGTMP\';
End;

Procedure PkgCleanTempDir;
Var Sr: SearchRec;
    Dir: String;
Begin
 Dir := PkgTempSubDir;
 FindFirst(Dir + '*.*', AnyFile, Sr);
 While DosError = 0 Do Begin
  If (Sr.Name <> '.') And (Sr.Name <> '..') Then Begin
   {$I-} Assign(PkgF, Dir + Sr.Name); Erase(PkgF); {$I+}
   If IOResult <> 0 Then ;
  End;
  FindNext(Sr);
 End;
 FindClose(Sr);
 {$I-} RmDir(Dir); {$I+} If IOResult <> 0 Then ;
End;

Function PkgEnsureTempDir: Boolean;
Var Dir: String;
Begin
 Dir := PkgTempSubDir;
 { Si le dossier existe deja, le vider. }
 {$I-} ChDir(Dir); {$I+}
 If IOResult = 0 Then Begin
  { On y est : retour racine puis nettoyage. }
  ChDir(PkgTempDir);
  PkgCleanTempDir;
 End;
 {$I-} MkDir(Dir); {$I+}
 PkgEnsureTempDir := (IOResult = 0);
End;

Function SavePkgFile(Const FN: String): Boolean;
Var TempDir, TocFN, OneFN, SafeName: String;
    I: Integer;
    OK: Boolean;
Begin
 SavePkgFile := False;
 PkgInitCrc;
 PkgOk := False;
 PkgEntCount := 0;

 If Not PkgEnsureTempDir Then Exit;
 TempDir := PkgTempSubDir;
 TocFN := TempDir + 'NOTEBOOK.ONETOC2';

 { 1. Genere TOC + tous les .ONE dans le dossier temporaire. }
 If Not SaveTocFile(TocFN) Then Begin
  PkgCleanTempDir; Exit;
 End;

 { 2. Ouvre le .ONEPKG en sortie. }
 Assign(PkgF, FN);
 {$I-} Rewrite(PkgF, 1); {$I+}
 If IOResult <> 0 Then Begin PkgCleanTempDir; Exit; End;
 PkgOk := True;

 { 3. Ajoute d'abord le TOC, puis chaque section. }
 OK := PkgAddFromFile('NOTEBOOK.ONETOC2', TocFN);
 If OK Then
  For I := 1 To Book.SectionCount Do Begin
   SafeName := SanitizeSecName(Book.Sections[I].Name);
   OneFN := TempDir + SafeName + '.ONE';
   If Not PkgAddFromFile(SafeName + '.ONE', OneFN) Then Begin
    OK := False; Break;
   End;
  End;

 If OK Then PkgWriteCentralDir;
 Close(PkgF);
 PkgOk := False;
 PkgCleanTempDir;
 SavePkgFile := OK;
End;

{ Extrait l'entree courante (positionnee sur son LFH) vers DstPath. }
Function PkgExtractEntryAt(Var F: File; LfhOff, Sz: LongInt;
                           Const DstPath: String): Boolean;
Var DstF: File;
    Sig: LongInt;
    NameLen, ExtraLen: Word;
    Remain: LongInt;
    ToRead: Integer;
Begin
 PkgExtractEntryAt := False;
 Seek(F, LfhOff);
 Sig := PkgRdL(F);
 If Sig <> PKG_LFH_SIG Then Exit;
 PkgRdW(F); PkgRdW(F); PkgRdW(F); PkgRdW(F); PkgRdW(F);  { ver,flg,mth,t,d }
 PkgRdL(F); PkgRdL(F); PkgRdL(F);                        { crc,cs,us }
 NameLen  := PkgRdW(F);
 ExtraLen := PkgRdW(F);
 Seek(F, FilePos(F) + NameLen + ExtraLen);

 Assign(DstF, DstPath);
 {$I-} Rewrite(DstF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 Remain := Sz;
 While Remain > 0 Do Begin
  If Remain > PKG_BUF_SZ Then ToRead := PKG_BUF_SZ
                         Else ToRead := Remain;
  BlockRead(F, PkgBuf, ToRead);
  BlockWrite(DstF, PkgBuf, ToRead);
  Remain := Remain - ToRead;
 End;
 Close(DstF);
 PkgExtractEntryAt := True;
End;

Function LoadPkgFile(Const FN: String): Boolean;
Var F: File;
    FSize, EocdPos, CdOff, CdSize: LongInt;
    ScanBuf: ^Byte;
    ScanLen, K: LongInt;
    ScanByte: ^Byte;
    TotalEnt, EI: Integer;
    Sig: LongInt;
    Mth, Flg, NameLen, ExtraLen, CommentLen: Word;
    CSize, USize, LfhOff: LongInt;
    EntName: String;
    TempDir, DstPath, TocPath: String;
    ExtractedToc: Boolean;
    I: Integer;
    Ext: String;
Begin
 LoadPkgFile := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 FSize := FileSize(F);
 If FSize < 22 Then Begin Close(F); Exit; End;

 { Recherche EOCD en queue. }
 ScanLen := FSize;
 If ScanLen > PKG_EOCD_SCAN Then ScanLen := PKG_EOCD_SCAN;
 GetMem(ScanBuf, ScanLen);
 Seek(F, FSize - ScanLen);
 BlockRead(F, ScanBuf^, ScanLen);
 EocdPos := -1;
 K := ScanLen - 22;
 While K >= 0 Do Begin
  ScanByte := ScanBuf; Inc(ScanByte, K);
  If ScanByte^ = 80 Then Begin
   Inc(ScanByte); If ScanByte^ = 75 Then Begin
    Inc(ScanByte); If ScanByte^ = 5 Then Begin
     Inc(ScanByte); If ScanByte^ = 6 Then Begin
      EocdPos := (FSize - ScanLen) + K; Break;
     End; End; End; End;
  Dec(K);
 End;
 FreeMem(ScanBuf, ScanLen);
 If EocdPos < 0 Then Begin Close(F); Exit; End;

 Seek(F, EocdPos + 10);
 TotalEnt := PkgRdW(F);
 CdSize   := PkgRdL(F);
 CdOff    := PkgRdL(F);
 If (TotalEnt <= 0) Or (CdOff <= 0) Or (CdOff >= FSize) Then Begin
  Close(F); Exit;
 End;

 If Not PkgEnsureTempDir Then Begin Close(F); Exit; End;
 TempDir := PkgTempSubDir;
 ExtractedToc := False;
 TocPath := '';

 Seek(F, CdOff);
 For EI := 1 To TotalEnt Do Begin
  Sig := PkgRdL(F);
  If Sig <> PKG_CDH_SIG Then Break;
  PkgRdW(F); PkgRdW(F);
  Flg := PkgRdW(F);
  Mth := PkgRdW(F);
  PkgRdW(F); PkgRdW(F);
  PkgRdL(F);
  CSize := PkgRdL(F);
  USize := PkgRdL(F);
  NameLen    := PkgRdW(F);
  ExtraLen   := PkgRdW(F);
  CommentLen := PkgRdW(F);
  PkgRdW(F); PkgRdW(F); PkgRdL(F);
  LfhOff := PkgRdL(F);
  If NameLen > 64 Then NameLen := 64;
  EntName[0] := Char(NameLen);
  If NameLen > 0 Then BlockRead(F, EntName[1], NameLen);
  If ExtraLen   > 0 Then Seek(F, FilePos(F) + ExtraLen);
  If CommentLen > 0 Then Seek(F, FilePos(F) + CommentLen);

  If Mth <> 0 Then Continue;  { stored uniquement }

  { Nom de sortie = base name. }
  I := Length(EntName);
  While (I > 0) And (EntName[I] <> '\') And (EntName[I] <> '/') Do Dec(I);
  If I > 0 Then EntName := Copy(EntName, I + 1, Length(EntName));
  If EntName = '' Then Continue;

  DstPath := TempDir + EntName;
  { Sauve la position dans le CD avant extraction. }
  Sig := FilePos(F);
  If PkgExtractEntryAt(F, LfhOff, USize, DstPath) Then Begin
   Ext := PathExtUp(EntName);
   If (Not ExtractedToc) And (Ext = '.ONETOC2') Then Begin
    TocPath := DstPath;
    ExtractedToc := True;
   End;
  End;
  Seek(F, Sig);  { reprend la lecture du CD }
 End;
 Close(F);

 If ExtractedToc Then Begin
  If LoadTocFile(TocPath) Then Begin
   Book.FilePath := FN;
   LoadPkgFile := True;
  End;
 End;
 PkgCleanTempDir;
End;

{ ============================================================ }
{ ===  FORMATS SIDECAR .MSONEBIN/.ONECACHE/.ONEPART (P.11) === }
{ ============================================================ }
{ - .MSONEBIN : enveloppe binaire monolithique du bloc-notes
                (= header + payload .ONE complet).
  - .ONEPART  : export d'une seule section
                (= header + payload .ONE mono-section).
  - .ONECACHE : snapshot index (noms + structure, sans contenu),
                charge un squelette modifiable.                       }

Const
 MSB_MAGIC  : Array[1..8] Of Char = ('M','S','O','N','E','B','N','0');
 PART_MAGIC : Array[1..8] Of Char = ('O','N','E','P','A','R','T','0');
 CACHE_MAGIC: Array[1..8] Of Char = ('O','N','E','C','A','C','H','0');
 SIDECAR_VER = 1;

Type
 TSidecarHdr = Packed Record
  Magic       : Array[1..8] Of Char;
  Version     : Word;
  Reserved    : Word;
  PayloadSize : LongInt;
 End;
 TCacheHdr = Packed Record
  Magic       : Array[1..8] Of Char;
  Version     : Word;
  Reserved    : Word;
  SectionCount: Word;
 End;
 TCacheSecHdr = Packed Record
  Color       : Byte;
  PageCount   : Word;
 End;
 TCachePageHdr = Packed Record
  ParaCount   : Word;
  ExtraCount  : Word;
 End;

Function MagicEqual(Const A, B: Array Of Char): Boolean;
Var I: Integer;
Begin
 MagicEqual := False;
 For I := 0 To 7 Do If A[I] <> B[I] Then Exit;
 MagicEqual := True;
End;

{ Encapsule SrcOnePath dans une enveloppe (Magic+Hdr+Payload). }
Function SidecarWrap(Const DstFN, SrcOnePath: String;
                     Const Magic: Array Of Char): Boolean;
Var SrcF, DstF: File;
    H: TSidecarHdr;
    Sz, Remain: LongInt;
    ToRead, I: Integer;
Begin
 SidecarWrap := False;
 Assign(SrcF, SrcOnePath);
 {$I-} Reset(SrcF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 Sz := FileSize(SrcF);

 Assign(DstF, DstFN);
 {$I-} Rewrite(DstF, 1); {$I+}
 If IOResult <> 0 Then Begin Close(SrcF); Exit; End;

 For I := 1 To 8 Do H.Magic[I] := Magic[I - 1];
 H.Version     := SIDECAR_VER;
 H.Reserved    := 0;
 H.PayloadSize := Sz;
 BlockWrite(DstF, H, SizeOf(H));

 Remain := Sz;
 While Remain > 0 Do Begin
  If Remain > PKG_BUF_SZ Then ToRead := PKG_BUF_SZ Else ToRead := Remain;
  BlockRead(SrcF, PkgBuf, ToRead);
  BlockWrite(DstF, PkgBuf, ToRead);
  Remain := Remain - ToRead;
 End;
 Close(SrcF);
 Close(DstF);
 SidecarWrap := True;
End;

{ Extrait le payload .ONE de SrcFN vers DstOnePath en verifiant Magic. }
Function SidecarUnwrap(Const SrcFN, DstOnePath: String;
                       Const ExpectMagic: Array Of Char): Boolean;
Var SrcF, DstF: File;
    H: TSidecarHdr;
    I: Integer;
    Remain: LongInt;
    ToRead: Integer;
    MagicArr: Array[0..7] Of Char;
Begin
 SidecarUnwrap := False;
 Assign(SrcF, SrcFN);
 {$I-} Reset(SrcF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 If FileSize(SrcF) < SizeOf(H) Then Begin Close(SrcF); Exit; End;
 {$I-} BlockRead(SrcF, H, SizeOf(H)); {$I+}
 If IOResult <> 0 Then Begin Close(SrcF); Exit; End;

 For I := 0 To 7 Do MagicArr[I] := H.Magic[I + 1];
 If Not MagicEqual(MagicArr, ExpectMagic) Then Begin Close(SrcF); Exit; End;
 If H.Version <> SIDECAR_VER Then Begin Close(SrcF); Exit; End;
 If (H.PayloadSize <= 0) Or
    (H.PayloadSize > FileSize(SrcF) - LongInt(SizeOf(H))) Then Begin
  Close(SrcF); Exit;
 End;

 Assign(DstF, DstOnePath);
 {$I-} Rewrite(DstF, 1); {$I+}
 If IOResult <> 0 Then Begin Close(SrcF); Exit; End;

 Remain := H.PayloadSize;
 While Remain > 0 Do Begin
  If Remain > PKG_BUF_SZ Then ToRead := PKG_BUF_SZ Else ToRead := Remain;
  BlockRead(SrcF, PkgBuf, ToRead);
  BlockWrite(DstF, PkgBuf, ToRead);
  Remain := Remain - ToRead;
 End;
 Close(SrcF);
 Close(DstF);
 SidecarUnwrap := True;
End;

{ ----- .MSONEBIN : enveloppe monolithique du bloc-notes ---------------- }

Function SaveMsoneBinFile(Const FN: String): Boolean;
Var TempOne: String;
    OK: Boolean;
Begin
 SaveMsoneBinFile := False;
 If Not PkgEnsureTempDir Then Exit;
 TempOne := PkgTempSubDir + 'PAYLOAD.ONE';
 OK := SaveOneFile(TempOne);
 If OK Then OK := SidecarWrap(FN, TempOne, MSB_MAGIC);
 {$I-} Assign(PkgF, TempOne); Erase(PkgF); {$I+} If IOResult <> 0 Then ;
 {$I-} RmDir(PkgTempSubDir); {$I+} If IOResult <> 0 Then ;
 SaveMsoneBinFile := OK;
End;

Function LoadMsoneBinFile(Const FN: String): Boolean;
Var TempOne: String;
    OK: Boolean;
Begin
 LoadMsoneBinFile := False;
 If Not PkgEnsureTempDir Then Exit;
 TempOne := PkgTempSubDir + 'PAYLOAD.ONE';
 OK := SidecarUnwrap(FN, TempOne, MSB_MAGIC);
 If OK Then OK := LoadOneFile(TempOne);
 If OK Then Book.FilePath := FN;
 {$I-} Assign(PkgF, TempOne); Erase(PkgF); {$I+} If IOResult <> 0 Then ;
 {$I-} RmDir(PkgTempSubDir); {$I+} If IOResult <> 0 Then ;
 LoadMsoneBinFile := OK;
End;

{ ----- .ONEPART : enveloppe de la section courante --------------------- }

Function SaveOnePartFile(Const FN: String): Boolean;
Var TempOne: String;
    OK: Boolean;
    SecIdx: Integer;
Begin
 SaveOnePartFile := False;
 SecIdx := Book.CurSection;
 If (SecIdx < 1) Or (SecIdx > Book.SectionCount) Then Exit;
 If Not PkgEnsureTempDir Then Exit;
 TempOne := PkgTempSubDir + 'PART.ONE';
 OK := SaveSectionAsOneFile(TempOne, SecIdx);
 If OK Then OK := SidecarWrap(FN, TempOne, PART_MAGIC);
 {$I-} Assign(PkgF, TempOne); Erase(PkgF); {$I+} If IOResult <> 0 Then ;
 {$I-} RmDir(PkgTempSubDir); {$I+} If IOResult <> 0 Then ;
 SaveOnePartFile := OK;
End;

Function LoadOnePartFile(Const FN: String): Boolean;
Var TempOne: String;
    OK: Boolean;
Begin
 LoadOnePartFile := False;
 If Not PkgEnsureTempDir Then Exit;
 TempOne := PkgTempSubDir + 'PART.ONE';
 OK := SidecarUnwrap(FN, TempOne, PART_MAGIC);
 If OK Then OK := LoadOneFile(TempOne);
 If OK Then Book.FilePath := FN;
 {$I-} Assign(PkgF, TempOne); Erase(PkgF); {$I+} If IOResult <> 0 Then ;
 {$I-} RmDir(PkgTempSubDir); {$I+} If IOResult <> 0 Then ;
 LoadOnePartFile := OK;
End;

{ ----- .ONECACHE : index allege (structure sans contenu) --------------- }

Function SaveOneCacheFile(Const FN: String): Boolean;
Var F: File;
    CH : TCacheHdr;
    CSH: TCacheSecHdr;
    CPH: TCachePageHdr;
    I, J: Integer;
    Sec: PSection;
    Pg : PPage;
Begin
 SaveOneCacheFile := False;
 Assign(F, FN);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;

 For I := 1 To 8 Do CH.Magic[I] := CACHE_MAGIC[I];
 CH.Version      := SIDECAR_VER;
 CH.Reserved     := 0;
 CH.SectionCount := Book.SectionCount;
 BlockWrite(F, CH, SizeOf(CH));

 SaveWrStr(F, Book.Name);

 For I := 1 To Book.SectionCount Do Begin
  Sec := @Book.Sections[I];
  SaveWrStr(F, Sec^.Name);
  CSH.Color     := Sec^.Color;
  CSH.PageCount := Sec^.PageCount;
  BlockWrite(F, CSH, SizeOf(CSH));
  For J := 1 To Sec^.PageCount Do Begin
   Pg := @Sec^.Pages[J];
   SaveWrStr(F, Pg^.Title);
   CPH.ParaCount  := Pg^.ParaCount;
   CPH.ExtraCount := Pg^.ExtraCount;
   BlockWrite(F, CPH, SizeOf(CPH));
  End;
 End;
 Close(F);
 SaveOneCacheFile := True;
End;

Function LoadOneCacheFile(Const FN: String): Boolean;
Var F: File;
    CH : TCacheHdr;
    CSH: TCacheSecHdr;
    CPH: TCachePageHdr;
    I, J, NS, NP: Integer;
    MagicArr: Array[0..7] Of Char;
    Name: String;
    Sec: PSection;
    Pg : PPage;
Begin
 LoadOneCacheFile := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockRead(F, CH, SizeOf(CH)); {$I+}
 If IOResult <> 0 Then Begin Close(F); Exit; End;
 For I := 0 To 7 Do MagicArr[I] := CH.Magic[I + 1];
 If Not MagicEqual(MagicArr, CACHE_MAGIC) Then Begin Close(F); Exit; End;
 If CH.Version <> SIDECAR_VER Then Begin Close(F); Exit; End;
 NS := CH.SectionCount;
 If NS > MAX_SECTIONS Then Begin Close(F); Exit; End;

 FreeBookImages;
 FillChar(Book, SizeOf(Book), 0);
 Book.FilePath := FN;
 Book.Modified := False;
 Book.Name     := LoadRdStr(F);
 Book.SectionCount := NS;
 Book.CurSection   := 1;

 For I := 1 To NS Do Begin
  Name := LoadRdStr(F);
  BlockRead(F, CSH, SizeOf(CSH));
  Sec := @Book.Sections[I];
  Sec^.Name      := Name;
  Sec^.Color     := CSH.Color;
  NP := CSH.PageCount;
  If NP > MAX_PAGES Then NP := MAX_PAGES;
  Sec^.PageCount := NP;
  Sec^.CurPage   := 1;
  For J := 1 To NP Do Begin
   Name := LoadRdStr(F);
   BlockRead(F, CPH, SizeOf(CPH));
   Pg := @Sec^.Pages[J];
   Pg^.Title      := Name;
   Pg^.CreatedTS  := 0;
   { Cache = squelette : pas de paras/extras restaures. }
   Pg^.ParaCount  := 0;
   Pg^.ExtraCount := 0;
  End;
 End;
 Close(F);
 LoadOneCacheFile := True;
End;

{ ============================================================ }
{ ===============  ACTIONS (stubs Phase 1)  =================== }
{ ============================================================ }

{ Phase 6 : forward decls necessaires a InsertImage. }
Function  CurPagePtr: PPage;            Forward;
Procedure DeleteExtra(Idx: Integer);    Forward;

Procedure FileNew;
Begin
 InitDefaultNotebook;
 SetStatus(L('Nouveau bloc-notes cree', 'New notebook created'));
End;

Procedure FileOpen;
Var FN, Ext: String;
Begin
 FN := '';
 If ShowFileDialog(False, '', 0, FN) Then Begin
  Ext := PathExtUp(FN);
  If Ext = '.ONETOC2' Then Begin
   If LoadTocFile(FN) Then
    SetStatus(L('Sommaire ouvert : ', 'TOC opened: ') + FN)
   Else
    SetStatus(L('Echec ouverture sommaire : ', 'TOC open failed: ') + FN);
  End
  Else If Ext = '.ONEPKG' Then Begin
   If LoadPkgFile(FN) Then
    SetStatus(L('Paquet ouvert : ', 'Package opened: ') + FN)
   Else
    SetStatus(L('Echec ouverture paquet : ', 'Package open failed: ') + FN);
  End
  Else If Ext = '.MSONEBIN' Then Begin
   If LoadMsoneBinFile(FN) Then
    SetStatus(L('Binaire ouvert : ', 'Binary opened: ') + FN)
   Else
    SetStatus(L('Echec binaire : ', 'Binary open failed: ') + FN);
  End
  Else If Ext = '.ONEPART' Then Begin
   If LoadOnePartFile(FN) Then
    SetStatus(L('Partage ouvert : ', 'Share opened: ') + FN)
   Else
    SetStatus(L('Echec partage : ', 'Share open failed: ') + FN);
  End
  Else If Ext = '.ONECACHE' Then Begin
   If LoadOneCacheFile(FN) Then
    SetStatus(L('Cache ouvert : ', 'Cache opened: ') + FN)
   Else
    SetStatus(L('Echec cache : ', 'Cache open failed: ') + FN);
  End
  Else Begin
   If LoadOneFile(FN) Then
    SetStatus(L('Ouvert : ', 'Opened: ') + FN)
   Else
    SetStatus(L('Echec ouverture : ', 'Open failed: ') + FN);
  End;
 End
 Else SetStatus(L('Ouverture annulee', 'Open cancelled'));
End;

Procedure FileClose;
Begin
 SetStatus(L('Fermer : a implementer', 'Close: TBD'));
End;

Procedure FileSave;
Var FN: String;
Begin
 If Book.FilePath = '' Then Begin
  FN := '';
  If ShowFileDialog(True, 'NOUVEAU.ONE', 0, FN) Then Begin
   If SaveOneFile(FN) Then Begin
    Book.FilePath := FN;
    Book.Modified := False;
    SetStatus(L('Enregistre : ', 'Saved: ') + FN);
   End
   Else SetStatus(L('Echec enregistrement : ', 'Save failed: ') + FN);
  End
  Else SetStatus(L('Enregistrement annule', 'Save cancelled'));
 End
 Else Begin
  If SaveOneFile(Book.FilePath) Then Begin
   Book.Modified := False;
   SetStatus(L('Enregistre : ', 'Saved: ') + Book.FilePath);
  End
  Else SetStatus(L('Echec enregistrement : ', 'Save failed: ') + Book.FilePath);
 End;
End;

Procedure FileSaveAs;
Var FN: String; DefName, Ext: String;
    OK: Boolean;
Begin
 If Book.FilePath <> '' Then DefName := Book.FilePath
                       Else DefName := 'NOUVEAU.ONE';
 FN := '';
 If ShowFileDialog(True, DefName, 0, FN) Then Begin
  Ext := PathExtUp(FN);
  If Ext = '.ONEPKG' Then OK := SavePkgFile(FN)
  Else If Ext = '.ONETOC2' Then OK := SaveTocFile(FN)
  Else If Ext = '.MSONEBIN' Then OK := SaveMsoneBinFile(FN)
  Else If Ext = '.ONEPART' Then OK := SaveOnePartFile(FN)
  Else If Ext = '.ONECACHE' Then OK := SaveOneCacheFile(FN)
  Else OK := SaveOneFile(FN);
  If OK Then Begin
   Book.FilePath := FN;
   Book.Modified := False;
   SetStatus(L('Enregistre sous : ', 'Saved as: ') + FN);
  End
  Else SetStatus(L('Echec enregistrement : ', 'Save failed: ') + FN);
 End
 Else SetStatus(L('Enregistrer sous : annule', 'Save As cancelled'));
End;

Procedure FileImportONE;
Begin
 SetStatus(L('Importer .ONE : Phase 8', 'Import .ONE: Phase 8'));
End;

Procedure FileExportPKG;
Var FN: String;
Begin
 FN := '';
 If ShowFileDialog(True, 'NOTEBOOK.ONEPKG', 1, FN) Then Begin
  If SavePkgFile(FN) Then
   SetStatus(L('Paquet exporte : ', 'Package exported: ') + FN)
  Else
   SetStatus(L('Echec export paquet : ', 'Package export failed: ') + FN);
 End
 Else SetStatus(L('Export paquet annule', 'Package export cancelled'));
End;

Procedure FileExportTOC;
Var FN: String;
Begin
 FN := '';
 If ShowFileDialog(True, 'NOTEBOOK.ONETOC2', 2, FN) Then Begin
  If SaveTocFile(FN) Then
   SetStatus(L('Sommaire exporte : ', 'TOC exported: ') + FN)
  Else
   SetStatus(L('Echec export sommaire : ', 'TOC export failed: ') + FN);
 End
 Else SetStatus(L('Export sommaire annule', 'TOC export cancelled'));
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
{ Phase 12 : petite boite de saisie modale (utilisee par la recherche). }
Function PromptText(Const Title: String; MaxLen: Integer; Var Out_: String): Boolean;
Var DlgX, DlgY, DlgW, DlgH, IX, IY: Integer;
    K, K2: Char; S: String;
    Btn, MX, MY: LongInt;
Begin
 PromptText := False;
 S := Out_;
 DlgW := 360; DlgH := 80;
 DlgX := (SCR_W - DlgW) Div 2;
 DlgY := (SCR_H - DlgH) Div 2;
 HideMouse;
 FillRect(DlgX, DlgY, DlgX + DlgW, DlgY + DlgH, LightGray);
 SetColor(Black);
 Rectangle(DlgX, DlgY, DlgX + DlgW, DlgY + DlgH);
 DrawTextAt(DlgX + 8, DlgY + 6, Black, Title);
 IX := DlgX + 8; IY := DlgY + 30;
 FillRect(IX, IY, IX + DlgW - 16, IY + 18, White);
 SetColor(DarkGray);
 Rectangle(IX, IY, IX + DlgW - 16, IY + 18);
 DrawTextAt(IX + 4, IY + 4, Black, S);
 DrawTextAt(DlgX + 8, DlgY + DlgH - 16, DarkGray,
            L('[Entree=OK  Esc=Annuler]', '[Enter=OK  Esc=Cancel]'));
 ShowMouse;
 Repeat
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #13 Then Begin Out_ := S; PromptText := True; Exit; End;
   If K = #27 Then Exit;
   If K = #0 Then Begin K2 := ReadKey; End
   Else If K = #8 Then Begin
    If Length(S) > 0 Then S[0] := Chr(Length(S) - 1);
    HideMouse;
    FillRect(IX + 1, IY + 1, IX + DlgW - 17, IY + 17, White);
    DrawTextAt(IX + 4, IY + 4, Black, S);
    ShowMouse;
   End
   Else If (K >= #32) And (Length(S) < MaxLen) Then Begin
    S := S + K;
    HideMouse;
    FillRect(IX + 1, IY + 1, IX + DlgW - 17, IY + 17, White);
    DrawTextAt(IX + 4, IY + 4, Black, S);
    ShowMouse;
   End;
  End;
  { Permet aussi clic souris pour annuler (en dehors de la boite). }
  GetMouseState(MX, MY, Btn);
  If ((Btn And MB_RIGHT) = MB_RIGHT) Then Exit;
  Delay(15);
 Until False;
End;

{ Phase 12 : recherche sequentielle dans tout le bloc-notes.
  SS/SP/ParaStart : point de depart (modifies au point de la prochaine occurrence). }
Function DoFindFrom(Var SS, SP, ParaStart: Integer; Const Pat: String): Boolean;
Var SI, PI, K: Integer; Found: Boolean; UP: String; Pg: PPage;
Begin
 UP := UpStr(Pat);
 Found := False;
 SI := SS; PI := SP; K := ParaStart;
 If SI < 1 Then SI := 1;
 If PI < 1 Then PI := 1;
 If K < 0 Then K := 0;
 While (SI <= Book.SectionCount) And (Not Found) Do Begin
  While (PI <= Book.Sections[SI].PageCount) And (Not Found) Do Begin
   Pg := @Book.Sections[SI].Pages[PI];
   If K <= 0 Then Begin
    If Pos(UP, UpStr(Pg^.Title)) > 0 Then Begin
     Found := True; SS := SI; SP := PI; ParaStart := 0;
    End;
    K := 1;
   End;
   While (Not Found) And (K <= Pg^.ParaCount) Do Begin
    If (Length(Pg^.Para[K].Txt) > 0) And
       (Pos(UP, UpStr(Pg^.Para[K].Txt)) > 0) Then Begin
     Found := True; SS := SI; SP := PI; ParaStart := K;
    End;
    Inc(K);
   End;
   If Not Found Then Begin Inc(PI); K := 0; End;
  End;
  If Not Found Then Begin Inc(SI); PI := 1; K := 0; End;
 End;
 DoFindFrom := Found;
End;

Procedure EditFindNext; Forward;

Procedure EditFind;
Var Q: String;
Begin
 Q := LastSearch;
 If Not PromptText(L('Rechercher : ', 'Find: '), 80, Q) Then Begin
  SetStatus(L('Recherche annulee', 'Search cancelled'));
  Exit;
 End;
 If Q = '' Then Exit;
 LastSearch  := Q;
 LastSecIdx  := 1; LastPgIdx := 1; LastParaIdx := -1;
 EditFindNext;
End;

Procedure EditFindNext;
Var SS, SP, K: Integer;
Begin
 If LastSearch = '' Then Begin EditFind; Exit; End;
 SS := LastSecIdx; SP := LastPgIdx; K := LastParaIdx + 1;
 If DoFindFrom(SS, SP, K, LastSearch) Then Begin
  Book.CurSection := SS;
  Book.Sections[SS].CurPage := SP;
  LastSecIdx  := SS;
  LastPgIdx   := SP;
  LastParaIdx := K;
  If K >= 1 Then Begin
   EditMode  := EM_BODY;
   EdParaIdx := K;
   EdCharPos := 0;
  End
  Else Begin
   EditMode  := EM_TITLE;
   EdCharPos := 0;
  End;
  SetStatus(L('Trouve : section ', 'Found: section ') + I2S(SS) +
            L(' page ', ' page ') + I2S(SP));
 End
 Else Begin
  LastSecIdx := 1; LastPgIdx := 1; LastParaIdx := -1;
  SetStatus(L('Aucune (autre) occurrence : ', 'No (more) matches: ') + LastSearch);
 End;
End;

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

{ Phase 4 : forward decls pour les containers libres }
Function  AddExtraAt(Cx, Cy: LongInt): Integer;        Forward;
Procedure SetEditExtra(ExIdx, CharPos: Integer);       Forward;

Procedure InsertContainer;
Var Idx: Integer;
Begin
 Idx := AddExtraAt((NOTE_X0 + NOTE_X1) Div 2,
                   (CONTENT_Y0 + CONTENT_Y1) Div 2);
 If Idx > 0 Then Begin
  SetEditExtra(Idx, Length(Book.Sections[Book.CurSection].Pages[
    Book.Sections[Book.CurSection].CurPage].Extras[Idx].Txt));
  SetStatus(L('Bloc insere', 'Container inserted'));
 End;
End;

Procedure InsertImage;
Var FN: String; Idx: Integer; Pg: PPage; Cx, Cy: Integer;
Begin
 Pg := CurPagePtr;
 If Pg = Nil Then Begin
  SetStatus(L('Aucune page active', 'No active page'));
  Exit;
 End;
 FN := '';
 If Not ShowFileDialog(False, '', 5, FN) Then Begin
  SetStatus(L('Insertion image annulee', 'Image insert cancelled'));
  Exit;
 End;
 Idx := AddExtraAt((NOTE_X0 + NOTE_X1) Div 2,
                   (CONTENT_Y0 + CONTENT_Y1) Div 2);
 If Idx = 0 Then Exit;
 If Not LoadBMPToExtra(FN, Pg^.Extras[Idx]) Then Begin
  DeleteExtra(Idx);
  SetStatus(L('Echec chargement BMP : ', 'BMP load failed: ') + FN);
  Exit;
 End;
 { Recentre le conteneur autour de l'image. }
 Cx := (NOTE_X0 + NOTE_X1) Div 2;
 Cy := (CONTENT_Y0 + CONTENT_Y1) Div 2;
 Pg^.Extras[Idx].X := Cx - Pg^.Extras[Idx].W Div 2;
 Pg^.Extras[Idx].Y := Cy - Pg^.Extras[Idx].H Div 2;
 If Pg^.Extras[Idx].X < NOTE_X0 + 2 Then Pg^.Extras[Idx].X := NOTE_X0 + 2;
 If Pg^.Extras[Idx].Y < CONTENT_Y0 + 30 Then Pg^.Extras[Idx].Y := CONTENT_Y0 + 30;
 If Pg^.Extras[Idx].X + Pg^.Extras[Idx].W > NOTE_X1 - 2 Then
  Pg^.Extras[Idx].X := NOTE_X1 - 2 - Pg^.Extras[Idx].W;
 If Pg^.Extras[Idx].Y + Pg^.Extras[Idx].H > CONTENT_Y1 - 2 Then
  Pg^.Extras[Idx].Y := CONTENT_Y1 - 2 - Pg^.Extras[Idx].H;
 Book.Modified := True;
 SetStatus(L('Image inseree : ', 'Image inserted: ') + FN);
End;

Procedure InsertTable;
Var Pg: PPage; Idx, R, C, Rows, Cols: Integer; S: String;
Begin
 Pg := CurPagePtr;
 If Pg = Nil Then Begin
  SetStatus(L('Aucune page active', 'No active page')); Exit;
 End;
 If Pg^.ExtraCount >= MAX_EXTRAS Then Begin
  SetStatus(L('Limite de blocs atteinte', 'Container limit reached')); Exit;
 End;
 Rows := 3; Cols := 3;
 Idx := AddExtraAt((NOTE_X0 + NOTE_X1) Div 2,
                   (CONTENT_Y0 + CONTENT_Y1) Div 2);
 If Idx < 1 Then Exit;
 S := TBL_MARKER_C1 + TBL_MARKER_C2 + Chr(Rows) + Chr(Cols);
 For R := 1 To Rows Do
  For C := 1 To Cols Do Begin
   If C < Cols Then S := S + #9
   Else If R < Rows Then S := S + #10;
  End;
 Pg^.Extras[Idx].Txt := S;
 Pg^.Extras[Idx].W   := 240;
 Pg^.Extras[Idx].H   := 90;
 Book.Modified := True;
 SetStatus(L('Tableau 3x3 insere', 'Table 3x3 inserted'));
End;

Procedure InsertDateTime;
Begin SetStatus(L('Date/Heure : a implementer', 'Date/Time: TBD')); End;

Procedure InsertTag;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Begin
  SetStatus(L('Tag : placer le caret dans un paragraphe',
              'Tag: place caret in paragraph first'));
  Exit;
 End;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (Sec^.CurPage > Sec^.PageCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do Begin
  Tag := Tag + 1;
  If Tag > TAG_COUNT Then Tag := TAG_NONE;
  SetStatus(L('Tag : ', 'Tag: ') + TagName(Tag));
 End;
 Book.Modified := True;
End;

Procedure FormatBold;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Begin
  SetStatus(L('Gras (placer le caret dans un paragraphe)',
              'Bold (place caret in paragraph first)')); Exit;
 End;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (EdParaIdx < 1) Or
    (EdParaIdx > Sec^.Pages[Sec^.CurPage].ParaCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do Bold := Not Bold;
 Book.Modified := True;
 SetStatus(L('Gras', 'Bold'));
End;

Procedure FormatItalic;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Begin
  SetStatus(L('Italique (placer le caret dans un paragraphe)',
              'Italic (place caret in paragraph first)')); Exit;
 End;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (EdParaIdx < 1) Or
    (EdParaIdx > Sec^.Pages[Sec^.CurPage].ParaCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do Italic := Not Italic;
 Book.Modified := True;
 SetStatus(L('Italique', 'Italic'));
End;

Procedure FormatUnder;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Begin
  SetStatus(L('Souligne (placer le caret dans un paragraphe)',
              'Underline (place caret in paragraph first)')); Exit;
 End;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (EdParaIdx < 1) Or
    (EdParaIdx > Sec^.Pages[Sec^.CurPage].ParaCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do Under := Not Under;
 Book.Modified := True;
 SetStatus(L('Souligne', 'Underline'));
End;

Procedure FormatBullet;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Begin
  SetStatus(L('Puce (placer le caret dans un paragraphe)',
              'Bullet (place caret in paragraph first)')); Exit;
 End;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (EdParaIdx < 1) Or
    (EdParaIdx > Sec^.Pages[Sec^.CurPage].ParaCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do Bullet := Not Bullet;
 Book.Modified := True;
 SetStatus(L('Puce', 'Bullet'));
End;

Procedure FormatNumber;   Begin SetStatus(L('Numerotation : Phase 12',
                                            'Numbering: Phase 12')); End;

Procedure FormatIndent;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (EdParaIdx < 1) Or
    (EdParaIdx > Sec^.Pages[Sec^.CurPage].ParaCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do
  If Indent < 8 Then Inc(Indent);
 Book.Modified := True;
 SetStatus(L('Indente', 'Indented'));
End;

Procedure FormatOutdent;
Var Sec: PSection;
Begin
 If (EditMode <> EM_BODY) Or (Book.CurSection < 1) Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (EdParaIdx < 1) Or
    (EdParaIdx > Sec^.Pages[Sec^.CurPage].ParaCount) Then Exit;
 With Sec^.Pages[Sec^.CurPage].Para[EdParaIdx] Do
  If Indent > 0 Then Dec(Indent);
 Book.Modified := True;
 SetStatus(L('Desindente', 'Outdented'));
End;

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
Procedure ToolsSearch;   Begin EditFind; End;
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

{ Phase 2 : forward decls pour casser les references croisees }
Procedure HandleNoteAreaClick(X, Y: LongInt); Forward;
Procedure OpenMenu(MI: Integer); Forward;
{ Phase 4 : forward decls pour le drag des containers libres }
Function  ExtraAt(X, Y: LongInt): Integer; Forward;
Function  ExtraBorderHit(Idx: Integer; X, Y: LongInt): Boolean; Forward;
Procedure DragExtra(Idx: Integer; StartX, StartY: LongInt); Forward;
{ Phase 12 : forward decl pour le pen tool (utilise par HandleLeftClick). }
Procedure PenStrokeAt(Sx, Sy: LongInt); Forward;

Procedure HandleLeftClick(X, Y: LongInt);
Var MI, II, IcIdx, SecIdx, PgIdx, EIdx: Integer; Exit_: Boolean;
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

 { 6) Clic dans la zone de notes : positionner le caret (Phase 2) }
 If (X >= NOTE_X0) And (X <= NOTE_X1) And
    (Y >= CONTENT_Y0) And (Y <= CONTENT_Y1) Then Begin
  { Phase 12 : outil stylo => trait libre. }
  If CurrentTool = TT_PEN Then Begin
   PenStrokeAt(X, Y); RefreshScreen; Exit;
  End;
  { Phase 4 : drag d'un container si on clique son bord }
  EIdx := ExtraAt(X, Y);
  If (EIdx > 0) And ExtraBorderHit(EIdx, X, Y) Then Begin
   DragExtra(EIdx, X, Y); RefreshScreen; Exit;
  End;
  HandleNoteAreaClick(X, Y); RefreshScreen; Exit;
 End;
End;

Procedure HandleRightClick(X, Y: LongInt);
Var NewIdx, ExIdx: Integer;
Begin
 { Phase 4 : clic droit dans la zone de notes => creer un container ici.
   Phase 6 : si l'on clique droit sur un extra existant => supprimer. }
 If (X >= NOTE_X0) And (X <= NOTE_X1) And
    (Y >= CONTENT_Y0 + 30) And (Y <= CONTENT_Y1) Then Begin
  ExIdx := ExtraAt(X, Y);
  If ExIdx > 0 Then Begin
   DeleteExtra(ExIdx);
   SetStatus(L('Bloc supprime', 'Block deleted'));
   RefreshScreen;
   Exit;
  End;
  NewIdx := AddExtraAt(X, Y);
  If NewIdx > 0 Then Begin
   SetEditExtra(NewIdx, Length(Book.Sections[Book.CurSection].Pages[
     Book.Sections[Book.CurSection].CurPage].Extras[NewIdx].Txt));
   SetStatus(L('Bloc cree (clic droit pour supprimer)',
               'Block created (right-click to delete)'));
   RefreshScreen;
  End;
  Exit;
 End;
 SetStatus(L('Clic droit : creez un bloc dans la zone de notes',
             'Right click: create a block in the notes area'));
 RefreshScreen;
End;

{ ============================================================ }
{ =============  PHASE 2 : EDITION DE TEXTE  ================== }
{ ============================================================ }

Function CurPagePtr: PPage;
Var Sec: PSection;
Begin
 CurPagePtr := Nil;
 If (Book.CurSection < 1) Or (Book.CurSection > Book.SectionCount) Then Exit;
 Sec := @Book.Sections[Book.CurSection];
 If (Sec^.CurPage < 1) Or (Sec^.CurPage > Sec^.PageCount) Then Exit;
 CurPagePtr := @Sec^.Pages[Sec^.CurPage];
End;

Procedure EnsureAtLeastOneParagraph;
Var Pg: PPage;
Begin
 Pg := CurPagePtr;
 If Pg = Nil Then Exit;
 If Pg^.ParaCount = 0 Then AddParagraph(Pg^, '', False, 0);
End;

Procedure ClampEditCursor;
Var Pg: PPage; LenS: Integer;
Begin
 Pg := CurPagePtr;
 If Pg = Nil Then Begin
  EditMode := EM_NONE; Exit;
 End;
 If EditMode = EM_TITLE Then Begin
  LenS := Length(Pg^.Title);
  If EdCharPos < 0       Then EdCharPos := 0;
  If EdCharPos > LenS    Then EdCharPos := LenS;
 End
 Else If EditMode = EM_BODY Then Begin
  EnsureAtLeastOneParagraph;
  If EdParaIdx < 1                 Then EdParaIdx := 1;
  If EdParaIdx > Pg^.ParaCount     Then EdParaIdx := Pg^.ParaCount;
  LenS := Length(Pg^.Para[EdParaIdx].Txt);
  If EdCharPos < 0       Then EdCharPos := 0;
  If EdCharPos > LenS    Then EdCharPos := LenS;
 End;
End;

Procedure SetEditBody(ParaIdx, CharPos: Integer);
Begin
 EditMode  := EM_BODY;
 EdParaIdx := ParaIdx;
 EdCharPos := CharPos;
 ClampEditCursor;
 CursorVisible := True;
 BlinkCounter  := 0;
End;

Procedure SetEditTitle(CharPos: Integer);
Begin
 EditMode  := EM_TITLE;
 EdCharPos := CharPos;
 ClampEditCursor;
 CursorVisible := True;
 BlinkCounter  := 0;
End;

{ ============================================================ }
{ ===============  PHASE 4 : CONTAINERS LIBRES  =============== }
{ ============================================================ }

{ Renvoie l'index du container sous (X,Y), 0 si aucun. Top-most en premier. }
Function ExtraAt(X, Y: LongInt): Integer;
Var Pg: PPage; I: Integer; EX, EY, EW, EH: Integer;
Begin
 ExtraAt := 0;
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 For I := Pg^.ExtraCount Downto 1 Do Begin
  EX := Pg^.Extras[I].X; EY := Pg^.Extras[I].Y;
  EW := Pg^.Extras[I].W; EH := Pg^.Extras[I].H;
  If (X >= EX) And (X < EX + EW) And
     (Y >= EY) And (Y < EY + EH) Then Begin
   ExtraAt := I; Exit;
  End;
 End;
End;

{ Click sur le bord (zone EXTRA_BORDER autour) mais pas interieur }
Function ExtraBorderHit(Idx: Integer; X, Y: LongInt): Boolean;
Var Pg: PPage; EX, EY, EW, EH: Integer;
Begin
 ExtraBorderHit := False;
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If (Idx < 1) Or (Idx > Pg^.ExtraCount) Then Exit;
 EX := Pg^.Extras[Idx].X; EY := Pg^.Extras[Idx].Y;
 EW := Pg^.Extras[Idx].W; EH := Pg^.Extras[Idx].H;
 If (X < EX - EXTRA_BORDER) Or (X >= EX + EW + EXTRA_BORDER) Or
    (Y < EY - EXTRA_BORDER) Or (Y >= EY + EH + EXTRA_BORDER) Then Exit;
 If (X > EX + EXTRA_BORDER) And (X < EX + EW - EXTRA_BORDER) And
    (Y > EY + EXTRA_BORDER) And (Y < EY + EH - EXTRA_BORDER) Then Exit;
 ExtraBorderHit := True;
End;

Procedure SetEditExtra(ExIdx, CharPos: Integer);
Var Pg: PPage; LenS: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If (ExIdx < 1) Or (ExIdx > Pg^.ExtraCount) Then Exit;
 EditMode    := EM_EXTRA;
 EdExtraIdx  := ExIdx;
 LenS := Length(Pg^.Extras[ExIdx].Txt);
 If CharPos < 0    Then CharPos := 0;
 If CharPos > LenS Then CharPos := LenS;
 EdCharPos   := CharPos;
 CursorVisible := True;
 BlinkCounter  := 0;
End;

{ Cree un container a la position centree autour de (Cx,Cy). Renvoie l'index. }
Function AddExtraAt(Cx, Cy: LongInt): Integer;
Var Pg: PPage; Idx, NewX, NewY: Integer;
Begin
 AddExtraAt := 0;
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If Pg^.ExtraCount >= MAX_EXTRAS Then Begin
  SetStatus(L('Limite de blocs atteinte', 'Container limit reached'));
  Exit;
 End;
 Inc(Pg^.ExtraCount);
 Idx := Pg^.ExtraCount;
 ClearExtra(Pg^.Extras[Idx]);
 NewX := Cx - EXTRA_DEFAULT_W Div 2;
 NewY := Cy - 12;
 If NewX < NOTE_X0 + 2 Then NewX := NOTE_X0 + 2;
 If NewY < CONTENT_Y0 + 30 Then NewY := CONTENT_Y0 + 30;
 If NewX + EXTRA_DEFAULT_W > NOTE_X1 - 2 Then NewX := NOTE_X1 - 2 - EXTRA_DEFAULT_W;
 If NewY + EXTRA_DEFAULT_H > CONTENT_Y1 - 2 Then NewY := CONTENT_Y1 - 2 - EXTRA_DEFAULT_H;
 Pg^.Extras[Idx].X := NewX;
 Pg^.Extras[Idx].Y := NewY;
 Pg^.Extras[Idx].W := EXTRA_DEFAULT_W;
 Pg^.Extras[Idx].H := EXTRA_DEFAULT_H;
 Pg^.Extras[Idx].Txt := L('Nouveau bloc', 'New block');
 Book.Modified := True;
 AddExtraAt := Idx;
End;

Procedure DeleteExtra(Idx: Integer);
Var Pg: PPage; I: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If (Idx < 1) Or (Idx > Pg^.ExtraCount) Then Exit;
 FreeExtraImage(Pg^.Extras[Idx]);
 For I := Idx To Pg^.ExtraCount - 1 Do
  Pg^.Extras[I] := Pg^.Extras[I + 1];
 { Le dernier slot est un doublon apres le shift : on l'efface sans freer. }
 Pg^.Extras[Pg^.ExtraCount].Pixels  := Nil;
 Pg^.Extras[Pg^.ExtraCount].IsImage := False;
 Pg^.Extras[Pg^.ExtraCount].ImgW   := 0;
 Pg^.Extras[Pg^.ExtraCount].ImgH   := 0;
 ClearExtra(Pg^.Extras[Pg^.ExtraCount]);
 Dec(Pg^.ExtraCount);
 Book.Modified := True;
 If EditMode = EM_EXTRA Then Begin
  EditMode := EM_NONE; CursorVisible := False;
 End;
End;

{ Deplace le container par drag tant que le bouton gauche reste enfonce }
Procedure DragExtra(Idx: Integer; StartX, StartY: LongInt);
Var Pg: PPage; Btn, MX, MY, NewX, NewY: LongInt; DX, DY: LongInt;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If (Idx < 1) Or (Idx > Pg^.ExtraCount) Then Exit;
 DX := StartX - Pg^.Extras[Idx].X;
 DY := StartY - Pg^.Extras[Idx].Y;
 Repeat
  GetMouseState(MX, MY, Btn);
  NewX := MX - DX; NewY := MY - DY;
  If NewX < NOTE_X0 + 2 Then NewX := NOTE_X0 + 2;
  If NewY < CONTENT_Y0 + 30 Then NewY := CONTENT_Y0 + 30;
  If NewX + Pg^.Extras[Idx].W > NOTE_X1 - 2 Then
   NewX := NOTE_X1 - 2 - Pg^.Extras[Idx].W;
  If NewY + Pg^.Extras[Idx].H > CONTENT_Y1 - 2 Then
   NewY := CONTENT_Y1 - 2 - Pg^.Extras[Idx].H;
  If (NewX <> Pg^.Extras[Idx].X) Or (NewY <> Pg^.Extras[Idx].Y) Then Begin
   Pg^.Extras[Idx].X := NewX;
   Pg^.Extras[Idx].Y := NewY;
   RefreshScreen;
  End;
 Until (Btn And MB_LEFT) = 0;
 Book.Modified := True;
End;

{ Phase 12 : trace un trait libre tant que le bouton gauche est maintenu.
  Ajoute un nouveau stroke a la page courante (jusqu'a MAX_STROKES) et y
  empile jusqu'a MAX_STROKE_PTS points (X,Y restreints a la zone notes). }
Procedure PenStrokeAt(Sx, Sy: LongInt);
Var Pg: PPage; Btn, MX, MY: LongInt; LX, LY: Integer; SK: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If Pg^.StrokeCount >= MAX_STROKES Then Begin
  SetStatus(L('Limite de traits atteinte', 'Stroke limit reached'));
  { drain bouton pour ne pas declencher un autre clic }
  Repeat GetMouseState(MX, MY, Btn) Until (Btn And MB_LEFT) = 0;
  Exit;
 End;
 Inc(Pg^.StrokeCount);
 SK := Pg^.StrokeCount;
 Pg^.Strokes[SK].Color := Black;
 Pg^.Strokes[SK].PtCount := 1;
 Pg^.Strokes[SK].Pts[1].X := Sx;
 Pg^.Strokes[SK].Pts[1].Y := Sy;
 LX := Sx; LY := Sy;
 HideMouse;
 PutPixel(LX, LY, Black);
 ShowMouse;
 Repeat
  GetMouseState(MX, MY, Btn);
  If (MX <> LX) Or (MY <> LY) Then Begin
   If (MX >= NOTE_X0) And (MX <= NOTE_X1) And
      (MY >= CONTENT_Y0) And (MY <= CONTENT_Y1) Then Begin
    If Pg^.Strokes[SK].PtCount < MAX_STROKE_PTS Then Begin
     Inc(Pg^.Strokes[SK].PtCount);
     Pg^.Strokes[SK].Pts[Pg^.Strokes[SK].PtCount].X := MX;
     Pg^.Strokes[SK].Pts[Pg^.Strokes[SK].PtCount].Y := MY;
    End;
    HideMouse;
    SetColor(Black);
    Line(LX, LY, MX, MY);
    ShowMouse;
    LX := MX; LY := MY;
   End;
  End;
 Until (Btn And MB_LEFT) = 0;
 Book.Modified := True;
End;

{ Insertion d'un caractere imprimable a la position courante }
Procedure EditInsertChar(C: Char);
Var Pg: PPage; S: String; MaxLen: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then Begin
  S := Pg^.Title; MaxLen := PAGE_TITLE_LEN;
  If Length(S) >= MaxLen Then Exit;
  Insert(C, S, EdCharPos + 1);
  Pg^.Title := S;
  Inc(EdCharPos);
 End
 Else If EditMode = EM_BODY Then Begin
  EnsureAtLeastOneParagraph;
  S := Pg^.Para[EdParaIdx].Txt; MaxLen := MAX_PARA_LEN;
  If Length(S) >= MaxLen Then Exit;
  Insert(C, S, EdCharPos + 1);
  Pg^.Para[EdParaIdx].Txt := S;
  Inc(EdCharPos);
 End
 Else If EditMode = EM_EXTRA Then Begin
  If (EdExtraIdx < 1) Or (EdExtraIdx > Pg^.ExtraCount) Then Exit;
  S := Pg^.Extras[EdExtraIdx].Txt; MaxLen := EXTRA_TXT_LEN;
  If Length(S) >= MaxLen Then Exit;
  Insert(C, S, EdCharPos + 1);
  Pg^.Extras[EdExtraIdx].Txt := S;
  Inc(EdCharPos);
 End;
 Book.Modified := True;
End;

{ Backspace : supprime caractere a gauche du caret }
Procedure EditBackspace;
Var Pg: PPage; S, Prev: String; I, PrevLen: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then Begin
  If EdCharPos = 0 Then Exit;
  S := Pg^.Title; Delete(S, EdCharPos, 1);
  Pg^.Title := S; Dec(EdCharPos);
  Book.Modified := True;
 End
 Else If EditMode = EM_BODY Then Begin
  If (EdCharPos = 0) And (EdParaIdx > 1) Then Begin
   { Fusion avec paragraphe precedent }
   Prev := Pg^.Para[EdParaIdx - 1].Txt;
   S    := Pg^.Para[EdParaIdx].Txt;
   PrevLen := Length(Prev);
   If Length(Prev) + Length(S) <= MAX_PARA_LEN Then Begin
    Pg^.Para[EdParaIdx - 1].Txt := Prev + S;
    { Decaler paragraphes vers le haut }
    For I := EdParaIdx To Pg^.ParaCount - 1 Do
     Pg^.Para[I] := Pg^.Para[I + 1];
    ClearParagraph(Pg^.Para[Pg^.ParaCount]);
    Dec(Pg^.ParaCount);
    Dec(EdParaIdx);
    EdCharPos := PrevLen;
    Book.Modified := True;
   End;
  End
  Else If EdCharPos > 0 Then Begin
   S := Pg^.Para[EdParaIdx].Txt;
   Delete(S, EdCharPos, 1);
   Pg^.Para[EdParaIdx].Txt := S;
   Dec(EdCharPos);
   Book.Modified := True;
  End;
 End
 Else If EditMode = EM_EXTRA Then Begin
  If (EdExtraIdx < 1) Or (EdExtraIdx > Pg^.ExtraCount) Then Exit;
  If EdCharPos = 0 Then Exit;
  S := Pg^.Extras[EdExtraIdx].Txt;
  Delete(S, EdCharPos, 1);
  Pg^.Extras[EdExtraIdx].Txt := S;
  Dec(EdCharPos);
  Book.Modified := True;
 End;
End;

{ Delete : supprime caractere a droite du caret }
Procedure EditDeleteChar;
Var Pg: PPage; S, Next: String; I: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then Begin
  S := Pg^.Title;
  If EdCharPos >= Length(S) Then Exit;
  Delete(S, EdCharPos + 1, 1);
  Pg^.Title := S; Book.Modified := True;
 End
 Else If EditMode = EM_BODY Then Begin
  S := Pg^.Para[EdParaIdx].Txt;
  If (EdCharPos >= Length(S)) And (EdParaIdx < Pg^.ParaCount) Then Begin
   { Fusion avec paragraphe suivant }
   Next := Pg^.Para[EdParaIdx + 1].Txt;
   If Length(S) + Length(Next) <= MAX_PARA_LEN Then Begin
    Pg^.Para[EdParaIdx].Txt := S + Next;
    For I := EdParaIdx + 1 To Pg^.ParaCount - 1 Do
     Pg^.Para[I] := Pg^.Para[I + 1];
    ClearParagraph(Pg^.Para[Pg^.ParaCount]);
    Dec(Pg^.ParaCount);
    Book.Modified := True;
   End;
  End
  Else If EdCharPos < Length(S) Then Begin
   Delete(S, EdCharPos + 1, 1);
   Pg^.Para[EdParaIdx].Txt := S;
   Book.Modified := True;
  End;
 End
 Else If EditMode = EM_EXTRA Then Begin
  If (EdExtraIdx < 1) Or (EdExtraIdx > Pg^.ExtraCount) Then Exit;
  S := Pg^.Extras[EdExtraIdx].Txt;
  If EdCharPos >= Length(S) Then Exit;
  Delete(S, EdCharPos + 1, 1);
  Pg^.Extras[EdExtraIdx].Txt := S;
  Book.Modified := True;
 End;
End;

{ Enter : decoupe le paragraphe au caret (corps) ou passe au corps (titre) }
Procedure EditEnter;
Var Pg: PPage; S, Left, Right: String; I: Integer;
    BulSrc: Boolean; IndSrc: Byte;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then Begin
  EnsureAtLeastOneParagraph;
  SetEditBody(1, 0);
  Exit;
 End;
 If EditMode = EM_EXTRA Then Begin
  EditMode := EM_NONE; CursorVisible := False; Exit;
 End;
 If EditMode <> EM_BODY Then Exit;
 If Pg^.ParaCount >= MAX_PARA Then Exit;
 EnsureAtLeastOneParagraph;
 S := Pg^.Para[EdParaIdx].Txt;
 BulSrc := Pg^.Para[EdParaIdx].Bullet;
 IndSrc := Pg^.Para[EdParaIdx].Indent;
 Left  := Copy(S, 1, EdCharPos);
 Right := Copy(S, EdCharPos + 1, Length(S) - EdCharPos);
 { Decaler paragraphes vers le bas pour faire place }
 For I := Pg^.ParaCount Downto EdParaIdx + 1 Do
  Pg^.Para[I + 1] := Pg^.Para[I];
 Inc(Pg^.ParaCount);
 Pg^.Para[EdParaIdx].Txt := Left;
 ClearParagraph(Pg^.Para[EdParaIdx + 1]);
 Pg^.Para[EdParaIdx + 1].Txt    := Right;
 Pg^.Para[EdParaIdx + 1].Bullet := BulSrc;
 Pg^.Para[EdParaIdx + 1].Indent := IndSrc;
 Inc(EdParaIdx);
 EdCharPos := 0;
 Book.Modified := True;
End;

Procedure EditMoveLeft;
Var Pg: PPage;
Begin
 If EdCharPos > 0 Then Begin Dec(EdCharPos); Exit; End;
 If EditMode = EM_BODY Then Begin
  Pg := CurPagePtr; If Pg = Nil Then Exit;
  If EdParaIdx > 1 Then Begin
   Dec(EdParaIdx);
   EdCharPos := Length(Pg^.Para[EdParaIdx].Txt);
  End;
 End;
End;

Procedure EditMoveRight;
Var Pg: PPage; LenS: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then Begin
  LenS := Length(Pg^.Title);
  If EdCharPos < LenS Then Inc(EdCharPos);
  Exit;
 End;
 If EditMode = EM_BODY Then Begin
  LenS := Length(Pg^.Para[EdParaIdx].Txt);
  If EdCharPos < LenS Then Inc(EdCharPos)
  Else If EdParaIdx < Pg^.ParaCount Then Begin
   Inc(EdParaIdx); EdCharPos := 0;
  End;
 End
 Else If EditMode = EM_EXTRA Then Begin
  If (EdExtraIdx < 1) Or (EdExtraIdx > Pg^.ExtraCount) Then Exit;
  LenS := Length(Pg^.Extras[EdExtraIdx].Txt);
  If EdCharPos < LenS Then Inc(EdCharPos);
 End;
End;

Procedure EditMoveUp;
Var Pg: PPage; LenS: Integer;
Begin
 If EditMode = EM_TITLE Then Exit;
 If EditMode <> EM_BODY Then Exit;
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EdParaIdx > 1 Then Begin
  Dec(EdParaIdx);
  LenS := Length(Pg^.Para[EdParaIdx].Txt);
  If EdCharPos > LenS Then EdCharPos := LenS;
 End
 Else Begin
  { Remonter au titre }
  SetEditTitle(EdCharPos);
 End;
End;

Procedure EditMoveDown;
Var Pg: PPage; LenS: Integer;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then Begin
  EnsureAtLeastOneParagraph;
  SetEditBody(1, EdCharPos);
  Exit;
 End;
 If EditMode = EM_BODY Then Begin
  If EdParaIdx < Pg^.ParaCount Then Begin
   Inc(EdParaIdx);
   LenS := Length(Pg^.Para[EdParaIdx].Txt);
   If EdCharPos > LenS Then EdCharPos := LenS;
  End;
 End;
End;

Procedure EditMoveHome;
Begin EdCharPos := 0; End;

Procedure EditMoveEnd;
Var Pg: PPage;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;
 If EditMode = EM_TITLE Then EdCharPos := Length(Pg^.Title)
 Else If EditMode = EM_BODY Then EdCharPos := Length(Pg^.Para[EdParaIdx].Txt)
 Else If EditMode = EM_EXTRA Then Begin
  If (EdExtraIdx >= 1) And (EdExtraIdx <= Pg^.ExtraCount) Then
   EdCharPos := Length(Pg^.Extras[EdExtraIdx].Txt);
 End;
End;

{ Renvoie True si la touche plain a ete consommee par l'editeur }
Function HandleEditKey(K: Char): Boolean;
Begin
 HandleEditKey := False;
 If EditMode = EM_NONE Then Exit;
 If K = #0 Then Exit;   { extended : geree par HandleEditExtKey }
 Case K Of
  #8  : Begin EditBackspace; HandleEditKey := True; End;
  #13 : Begin EditEnter;     HandleEditKey := True; End;
  #27 : Begin
         EditMode := EM_NONE; CursorVisible := False;
         HandleEditKey := True;
        End;
 Else
  If K >= #32 Then Begin
   EditInsertChar(K); HandleEditKey := True;
  End;
 End;
End;

{ Traite un scancode etendu #0+K2 deja lu, renvoie True si consomme }
Function HandleEditExtKey(K2: Char): Boolean;
Begin
 HandleEditExtKey := False;
 If EditMode = EM_NONE Then Exit;
 Case K2 Of
  #75: Begin EditMoveLeft;   HandleEditExtKey := True; End;
  #77: Begin EditMoveRight;  HandleEditExtKey := True; End;
  #72: Begin EditMoveUp;     HandleEditExtKey := True; End;
  #80: Begin EditMoveDown;   HandleEditExtKey := True; End;
  #71: Begin EditMoveHome;   HandleEditExtKey := True; End;
  #79: Begin EditMoveEnd;    HandleEditExtKey := True; End;
  #83: Begin EditDeleteChar; HandleEditExtKey := True; End;
  #147: Begin   { Ctrl+Suppr : supprime le container actif (Phase 4) }
         If EditMode = EM_EXTRA Then DeleteExtra(EdExtraIdx);
         HandleEditExtKey := True;
        End;
 End;
End;

{ Determine le mode/position d'edition par un clic dans la zone de notes }
Procedure HandleNoteAreaClick(X, Y: LongInt);
Var Pg: PPage; LeftMargin, RelY, ParaIdx, Xc, CharPos, EIdx, ExBaseX: Integer;
    P: TParagraph;
Begin
 Pg := CurPagePtr; If Pg = Nil Then Exit;

 { Phase 4 : clic dans un container libre ? }
 EIdx := ExtraAt(X, Y);
 If EIdx > 0 Then Begin
  If Pg^.Extras[EIdx].IsImage Then Begin
   { Image : pas d'edition de texte, juste un message. }
   SetStatus(L('Image selectionnee (bord pour deplacer, Ctrl+Del pour supprimer)',
              'Image selected (border to drag, Ctrl+Del to delete)'));
   Exit;
  End;
  ExBaseX := Pg^.Extras[EIdx].X + EXTRA_PAD;
  If Pg^.Extras[EIdx].Tag <> TAG_NONE Then ExBaseX := ExBaseX + NOTE_TAG_W;
  CharPos := (X - ExBaseX + NOTE_CHAR_W Div 2) Div NOTE_CHAR_W;
  If CharPos < 0 Then CharPos := 0;
  If CharPos > Length(Pg^.Extras[EIdx].Txt) Then CharPos := Length(Pg^.Extras[EIdx].Txt);
  SetEditExtra(EIdx, CharPos);
  Exit;
 End;

 LeftMargin := NOTE_X0 + NOTE_LEFT_MARGIN;
 If Y < CONTENT_Y0 + 28 Then Begin
  CharPos := (X - LeftMargin + NOTE_CHAR_W Div 2) Div NOTE_CHAR_W;
  If CharPos < 0 Then CharPos := 0;
  If CharPos > Length(Pg^.Title) Then CharPos := Length(Pg^.Title);
  SetEditTitle(CharPos);
  Exit;
 End;
 EnsureAtLeastOneParagraph;
 RelY := Y - NOTE_PARA_Y0;
 If RelY < 0 Then RelY := 0;
 ParaIdx := (RelY Div NOTE_LINE_H) + 1;
 If ParaIdx < 1 Then ParaIdx := 1;
 If ParaIdx > Pg^.ParaCount Then ParaIdx := Pg^.ParaCount;
 P := Pg^.Para[ParaIdx];
 Xc := ParaTextX(P);
 CharPos := (X - Xc + NOTE_CHAR_W Div 2) Div NOTE_CHAR_W;
 If CharPos < 0 Then CharPos := 0;
 If CharPos > Length(P.Txt) Then CharPos := Length(P.Txt);
 SetEditBody(ParaIdx, CharPos);
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

 { Aucun menu ouvert : prioritairement traiter l'edition de texte (Phase 2)
   pour les caracteres plain (non-#0). On dispatche AVANT les raccourcis
   globaux pour que les caracteres imprimables aillent dans le texte. }
 If (EditMode <> EM_NONE) And (K <> #0) Then Begin
  { #8 Backspace, #13 Enter, #27 Esc, #32+ imprimables -> edition.
    Pour les Ctrl+lettre (#1..#7,#9..#12,#14..#26) on laisse le dispatch global. }
  If (K = #8) Or (K = #13) Or (K = #27) Or (K >= #32) Then Begin
   If HandleEditKey(K) Then Begin
    CursorVisible := True; BlinkCounter := 0;
    RefreshScreen; Exit;
   End;
  End;
 End;

 { Aucun menu ouvert : raccourcis globaux }
 Case K Of
  #27: LoopDone := True;                 { Esc : quitter (hors edition) }
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
  #8 : Begin EditReplace; RefreshScreen; End; { Ctrl+H (hors edition) }
  #2 : Begin FormatBold; RefreshScreen; End; { Ctrl+B }
  #9 : Begin FormatItalic; RefreshScreen; End; { Ctrl+I/Tab }
  #21: Begin FormatUnder; RefreshScreen; End; { Ctrl+U }
  #13: Begin InsertPage; RefreshScreen; End; { Enter (hors edition) }
  #0 : Begin
        K2 := ReadKey;
        { Phase 2 : si en edition, les fleches/Home/End/Suppr controlent le caret }
        If (EditMode <> EM_NONE) And HandleEditExtKey(K2) Then Begin
         CursorVisible := True; BlinkCounter := 0;
         RefreshScreen; Exit;
        End;
        Case K2 Of
         #59:  Begin HelpContents; OpenMenu(7); End; { F1 }
         #61:  Begin EditFindNext; RefreshScreen; End; { F3 : occurrence suivante }
         #64:  Begin { F6 : bascule outil stylo / texte }
                If CurrentTool = TT_PEN Then Begin
                 CurrentTool := TT_TEXT;
                 SetStatus(L('Outil : texte', 'Tool: text'));
                End
                Else Begin
                 CurrentTool := TT_PEN;
                 SetStatus(L('Outil : stylo (clic gauche = trait)',
                             'Tool: pen (left click = stroke)'));
                End;
                RefreshScreen;
               End;
         #65:  Begin InsertTable; RefreshScreen; End; { F7 : tableau 3x3 }
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

 { Phase 12 : init recherche }
 LastSearch  := '';
 LastSecIdx  := 1;
 LastPgIdx   := 1;
 LastParaIdx := -1;

 { Phase 2 : initialiser l'edition sur le 1er paragraphe de la page courante }
 EditMode      := EM_BODY;
 EdParaIdx     := 1;
 EdCharPos     := 0;
 CursorVisible := True;
 BlinkCounter  := 0;
 PrevEdParaIdx := 0; PrevEdCharPos := -1; PrevEditMode := -1;

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
  End
  Else Begin
   { Clignotement du caret (Phase 2) ~ toutes les ~25 iterations idle }
   Inc(BlinkCounter);
   If (EditMode <> EM_NONE) And (BlinkCounter >= 25) And
      (MenuState <> MS_DROPDOWN) Then Begin
    BlinkCounter := 0;
    CursorVisible := Not CursorVisible;
    HideMouse; DrawNoteArea; ShowMouse;
   End;
   Delay(15);
  End;
 Until LoopDone;

 If MouseDriverFound Then HideMouse;
 CloseGraph;
END.