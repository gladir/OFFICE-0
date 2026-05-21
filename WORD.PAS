{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Word
}

Program WordApp;

Uses {$IFDEF FPC}
      Crt,Dos,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      Crt,Dos,Graph
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

{ ============================================================ }
{ ====================  CONSTANTES UI  ======================= }
{ ============================================================ }

Const
 SCREEN_W              = 640;
 SCREEN_H              = 480;

 { --- Barre de titre / menus --- }
 MENUBAR_TOP           = 0;
 MENUBAR_HEIGHT        = 18;
 MENUBAR_BG            = 7;          { Gris clair }
 MENUBAR_FG            = 0;          { Noir }
 MENUBAR_HL_BG         = 1;          { Bleu }
 MENUBAR_HL_FG         = 15;         { Blanc }

 { --- Toolbar standard (ic??nes) --- }
 STDBAR_TOP            = 19;
 STDBAR_HEIGHT         = 24;
 STDBAR_BG             = 7;
 STDBAR_BTN            = 22;         { largeur/hauteur bouton 22x22 }

 { --- Toolbar formatage --- }
 FMTBAR_TOP            = 44;
 FMTBAR_HEIGHT         = 22;
 FMTBAR_BG             = 7;
 FMTBAR_BTN            = 20;

 { --- R??gle horizontale --- }
 RULER_TOP             = 67;
 RULER_HEIGHT          = 14;
 RULER_BG              = 15;
 RULER_FG              = 0;

 { --- Zone document --- }
 DOCAREA_TOP           = 82;
 DOCAREA_BOTTOM        = 459;        { au-dessus de la status bar }
 DOCAREA_BG            = 8;          { gris fonc?? (autour de la page) }

 { --- Page virtuelle (Letter 8.5"x11" ?? ~50 dpi visuel) --- }
 PAGE_W                = 460;        { largeur page ?? l'??cran }
 PAGE_H                = 600;        { hauteur page ?? l'??cran }
 PAGE_MARGIN_L         = 60;         { marge gauche dans la page }
 PAGE_MARGIN_R         = 60;
 PAGE_MARGIN_T         = 60;
 PAGE_MARGIN_B         = 60;
 PAGE_BG               = 15;         { blanc }
 PAGE_SHADOW           = 8;
 PAGE_BORDER           = 0;

 { --- Status bar --- }
 STATUSBAR_TOP         = 460;
 STATUSBAR_HEIGHT      = 20;
 STATUSBAR_BG          = 7;
 STATUSBAR_FG          = 0;

 { --- Couleurs 3D --- }
 CLR_3D_FACE           = 7;          { Gris clair }
 CLR_3D_LIGHT          = 15;         { Blanc }
 CLR_3D_DARK           = 8;          { Gris fonc?? }
 CLR_3D_SHADOW         = 0;          { Noir }

 { --- Codes touches ??tendues --- }
 KEY_NONE              = 0;
 KEY_ESC               = 27;
 KEY_TAB               = 9;
 KEY_ENTER             = 13;
 KEY_BACKSPACE         = 8;
 { Touches ??tendues (pr??fix??es #0 dans ReadKey) - on les code en >256 }
 KEY_F1                = 315;
 KEY_F2                = 316;
 KEY_F3                = 317;
 KEY_F4                = 318;
 KEY_F10               = 324;
 KEY_HOME              = 327;
 KEY_UP                = 328;
 KEY_PGUP              = 329;
 KEY_LEFT              = 331;
 KEY_RIGHT             = 333;
 KEY_END               = 335;
 KEY_DOWN              = 336;
 KEY_PGDN              = 337;
 KEY_INS               = 338;
 KEY_DEL               = 339;
 KEY_ALT_F             = 289;        { Alt+F  - scancode 33 + 256 }
 KEY_ALT_E             = 274;
 KEY_ALT_V             = 303;
 KEY_ALT_I             = 279;
 KEY_ALT_O             = 280;        { Alt+O = Format }
 KEY_ALT_T             = 276;        { Alt+T = Tools }
 KEY_ALT_A             = 286;        { Alt+A = Table }
 KEY_ALT_W             = 273;
 KEY_ALT_H             = 291;        { Alt+H = Help }
 KEY_ALT_X             = 301;        { Alt+X = sortie rapide }

 { --- Boutons souris (bitmask) --- }
 MB_LEFT               = 1;
 MB_RIGHT              = 2;
 MB_MIDDLE             = 4;

 { --- Limites document (Phase 1: structures pr??par??es) --- }
 MAX_RUNS_PER_PARA     = 32;
 MAX_PARAS_PER_DOC     = 200;
 MAX_PAGES             = 50;
 MAX_TEXT_LEN          = 240;
 MAX_DOC_FILENAME      = 80;

 { --- Styles caract??res (bitmask) --- }
 STY_BOLD              = 1;
 STY_ITALIC            = 2;
 STY_UNDERLINE         = 4;

 { --- Alignement paragraphe --- }
 ALIGN_LEFT            = 0;
 ALIGN_CENTER          = 1;
 ALIGN_RIGHT           = 2;
 ALIGN_JUSTIFY         = 3;

{ ============================================================ }
{ ========================  TYPES  =========================== }
{ ============================================================ }

Type
 TStr80   = String[80];
 TStr240  = String[240];

 { --- Style d'un run de texte (Phase 3 utilisera) --- }
 TCharStyle = Record
  FontSize : Byte;       { 8, 10, 12, 14, 18, 24 }
  Style    : Byte;       { combinaison STY_* }
  Color    : Byte;       { 0..15 palette EGA/VGA }
 End;

 { --- Run = portion contigu?? de m??me style --- }
 TRun = Record
  Text  : TStr240;
  Style : TCharStyle;
 End;

 { --- Paragraphe = liste de runs + alignement (+ image en Phase 6) --- }
 TParagraph = Record
  Runs            : Array[1..MAX_RUNS_PER_PARA] Of TRun;
  RunCount        : Integer;
  Alignment       : Byte;
  PageBreakBefore : Boolean;
  IsImage         : Boolean;
  ImgW, ImgH      : Integer;
  ImgData         : Pointer;     { palette indices 0..15, W*H octets }
 End;

 { --- Document --- }
 TDocument = Record
  Paragraphs : Array[1..MAX_PARAS_PER_DOC] Of TParagraph;
  ParaCount  : Integer;
  PageCount  : Integer;
  FileName   : String[MAX_DOC_FILENAME];
  Modified   : Boolean;
 End;

 { --- Position curseur --- }
 TCursorPos = Record
  ParaIdx : Integer;     { 1..ParaCount }
  RunIdx  : Integer;     { 1..RunCount }
  CharIdx : Integer;     { 0..Length(Run.Text) }
 End;

 { --- D??finition d'un menu et de ses items --- }
 TMenuItem = Record
  Caption   : String[24];
  Shortcut  : String[10];   { ex. 'Ctrl+S' affich?? ?? droite }
  AltKey    : Char;         { lettre soulign??e, #0 si aucune }
  Separator : Boolean;
  ActionId  : Integer;      { identifiant d'action }
  Enabled   : Boolean;
 End;

 TMenu = Record
  Caption   : String[12];
  AltKey    : Char;
  X1, X2    : Integer;
  ItemCount : Integer;
  Items     : Array[1..16] Of TMenuItem;
  DropW     : Integer;      { largeur du dropdown calcul??e }
 End;

 { --- Toolbar : un bouton --- }
 TToolBtn = Record
  X, Y, W, H : Integer;
  IconId     : Integer;
  ActionId   : Integer;
  Tooltip    : String[24];
  Pressed    : Boolean;     { pour boutons toggle (gras/italique...) }
  Separator  : Boolean;
 End;

{ ============================================================ }
{ ====================  IDENTIFIANTS  ======================== }
{ ============================================================ }

Const
 { Actions menu/toolbar - une num??rotation unifi??e. }
 ACT_NONE        = 0;

 { File }
 ACT_FILE_NEW    = 101;
 ACT_FILE_OPEN   = 102;
 ACT_FILE_SAVE   = 103;
 ACT_FILE_SAVEAS = 104;
 ACT_FILE_PRINT  = 105;
 ACT_FILE_EXIT   = 109;

 { Edit }
 ACT_EDIT_UNDO   = 201;
 ACT_EDIT_REDO   = 202;
 ACT_EDIT_CUT    = 203;
 ACT_EDIT_COPY   = 204;
 ACT_EDIT_PASTE  = 205;
 ACT_EDIT_FIND   = 206;
 ACT_EDIT_REPL   = 207;
 ACT_EDIT_FIND_NEXT = 208;

 { View }
 ACT_VIEW_NORMAL = 301;
 ACT_VIEW_PAGE   = 302;
 ACT_VIEW_RULER  = 303;
 ACT_VIEW_ZOOM   = 304;

 { Insert }
 ACT_INS_PAGEBRK = 401;
 ACT_INS_IMAGE   = 402;
 ACT_INS_SYMBOL  = 403;
 ACT_INS_TABLE   = 404;

 { Format }
 ACT_FMT_FONT    = 501;
 ACT_FMT_PARA    = 502;
 ACT_FMT_BOLD    = 503;
 ACT_FMT_ITALIC  = 504;
 ACT_FMT_UNDER   = 505;
 ACT_FMT_LEFT    = 506;
 ACT_FMT_CENTER  = 507;
 ACT_FMT_RIGHT   = 508;
 ACT_FMT_JUSTIFY = 509;
 ACT_FMT_COLOR   = 510;

 { Tools }
 ACT_TLS_SPELL   = 601;
 ACT_TLS_OPTIONS = 602;
 ACT_TLS_WORDS   = 603;

 { Table }
 ACT_TBL_INSERT  = 701;
 ACT_TBL_DELETE  = 702;

 { Window }
 ACT_WIN_CASCADE = 801;

 { Help }
 ACT_HLP_ABOUT   = 901;
 ACT_HLP_CONTENT = 902;

 { Ic??nes toolbar (num??rotation des dessins vectoriels) }
 ICN_NEW         = 1;
 ICN_OPEN        = 2;
 ICN_SAVE        = 3;
 ICN_PRINT       = 4;
 ICN_CUT         = 5;
 ICN_COPY        = 6;
 ICN_PASTE       = 7;
 ICN_UNDO        = 8;
 ICN_REDO        = 9;
 ICN_BOLD        = 10;
 ICN_ITALIC      = 11;
 ICN_UNDER       = 12;
 ICN_ALIGN_L     = 13;
 ICN_ALIGN_C     = 14;
 ICN_ALIGN_R     = 15;
 ICN_ALIGN_J     = 16;
 ICN_IMAGE       = 17;
 ICN_TABLE       = 18;

{ ============================================================ }
{ ===================  VARIABLES GLOBALES  =================== }
{ ============================================================ }

Var
 { ??tat application }
 AppShouldExit  : Boolean;
 NeedsRedraw    : Boolean;
 StatusMsg      : String[80];

 { Document }
 Doc            : TDocument;
 Cursor         : TCursorPos;
 CurrentStyle   : TCharStyle;        { style actif (pour saisie future) }
 CurrentAlign   : Byte;
 CurrentPage    : Integer;           { page affich?e }
 ScrollY        : Integer;           { d?filement vertical (Phase 10) }

 { Selection de texte (ancre + extr?mit? = Cursor) }
 Sel            : Record
                   Active     : Boolean;
                   AnchorPara : Integer;
                   AnchorChar : Integer;
                  End;
 MouseSelecting : Boolean;          { drag souris en cours }

 { Souris (pr??fixe Ms* pour ??viter conflit avec PtcMouse.MsX/MsY) }
 MsAvailable : Boolean;
 MsX         : LongInt;
 MsY         : LongInt;
 MsBtn       : LongInt;
 LastMsX     : LongInt;
 LastMsY     : LongInt;
 LastMsBtn   : LongInt;
 MsSaved     : Boolean;            { curseur logiciel sauv?? ? (FPC) }
 MsSaveBuf   : Pointer;            { backing store sous le curseur }
 MsSaveX     : LongInt;
 MsSaveY     : LongInt;

 { Menus }
 Menus          : Array[1..9] Of TMenu;
 MenuCount      : Integer;
 ActiveMenu     : Integer;            { 0 = aucun, sinon 1..9 }
 MenuItemHover  : Integer;            { item survol?? dans dropdown }
 MenuKeyboardMode: Boolean;           { menu ouvert au clavier ? }

 { Toolbars }
 StdBar         : Array[1..24] Of TToolBtn;
 StdBarCount    : Integer;
 FmtBar         : Array[1..16] Of TToolBtn;
 FmtBarCount    : Integer;
 HoveredStdBtn  : Integer;
 HoveredFmtBtn  : Integer;

{ ============================================================ }
{ ==================  ROUTINES SOURIS X-PLAT  ================ }
{ ============================================================ }

{$IFNDEF FPC}
 Function MouseDriverFound: Boolean;
 Var Regs: Registers;
 Begin
  Regs.AX := 0;
  Intr($33, Regs);
  MouseDriverFound := Regs.AX = $FFFF;
 End;

 Procedure ShowMouse;
 Var Regs: Registers;
 Begin
  Regs.AX := $0001;
  Intr($33, Regs);
 End;

 Procedure HideMouse;
 Var Regs: Registers;
 Begin
  Regs.AX := $0002;
  Intr($33, Regs);
 End;

 Procedure GetMouseStateLI(Var X, Y, Button: LongInt);
 Var Regs: Registers;
 Begin
  Regs.AX := $0003;
  Intr($33, Regs);
  Button := Regs.BX;
  X := Regs.CX;
  Y := Regs.DX;
 End;
{$ELSE}
 { Sous FPC/PtcMouse, le pilote est toujours pr??sent.
   PtcMouse expose : ShowMouse, HideMouse,
                     GetMouseState(Var X, Y, Buttons: LongInt). }
 Function MouseDriverFound: Boolean;
 Begin
  MouseDriverFound := True;
 End;

 Procedure GetMouseStateLI(Var X, Y, Button: LongInt);
 Begin
  GetMouseState(X, Y, Button);
 End;
{$ENDIF}

{ ============================================================ }
{ =================  INITIALIZE GRAPHICS  ==================== }
{ ============================================================ }
{ NOTE : la proc??dure InitializeGraphics elle-m??me se trouve   }
{ plus haut dans le fichier (ne pas la modifier).              }

{ ============================================================ }
{ ================  UTILITAIRES GRAPHIQUES  ================== }
{ ============================================================ }

Procedure FillRectArea(X1, Y1, X2, Y2, Color: Integer);
Begin
 SetFillStyle(SolidFill, Color);
 Bar(X1, Y1, X2, Y2);
End;

Procedure DrawHLine(X1, X2, Y, Color: Integer);
Begin
 SetColor(Color);
 Line(X1, Y, X2, Y);
End;

Procedure DrawVLine(X, Y1, Y2, Color: Integer);
Begin
 SetColor(Color);
 Line(X, Y1, X, Y2);
End;

Procedure DrawFrameRect(X1, Y1, X2, Y2, Color: Integer);
Begin
 SetColor(Color);
 Rectangle(X1, Y1, X2, Y2);
End;

{ Bouton 3D style Win 3.x / Visio. Pressed=True ??? enfonc??. }
Procedure DrawButton3D(X1, Y1, X2, Y2: Integer; Pressed: Boolean);
Begin
 FillRectArea(X1+1, Y1+1, X2-1, Y2-1, CLR_3D_FACE);
 If Pressed Then Begin
  DrawHLine(X1, X2, Y1, CLR_3D_DARK);
  DrawVLine(X1, Y1, Y2, CLR_3D_DARK);
  DrawHLine(X1+1, X2-1, Y1+1, CLR_3D_SHADOW);
  DrawVLine(X1+1, Y1+1, Y2-1, CLR_3D_SHADOW);
  DrawHLine(X1, X2, Y2, CLR_3D_LIGHT);
  DrawVLine(X2, Y1, Y2, CLR_3D_LIGHT);
 End Else Begin
  DrawHLine(X1, X2, Y1, CLR_3D_LIGHT);
  DrawVLine(X1, Y1, Y2, CLR_3D_LIGHT);
  DrawHLine(X1, X2-1, Y2, CLR_3D_SHADOW);
  DrawVLine(X2, Y1, Y2, CLR_3D_SHADOW);
  DrawHLine(X1+1, X2-2, Y2-1, CLR_3D_DARK);
  DrawVLine(X2-1, Y1+1, Y2-1, CLR_3D_DARK);
 End;
End;

{ Cadre creux (ex. encadrement champ texte). }
Procedure DrawSunkenRect(X1, Y1, X2, Y2: Integer);
Begin
 DrawHLine(X1, X2, Y1, CLR_3D_DARK);
 DrawVLine(X1, Y1, Y2, CLR_3D_DARK);
 DrawHLine(X1, X2, Y2, CLR_3D_LIGHT);
 DrawVLine(X2, Y1, Y2, CLR_3D_LIGHT);
End;

Procedure DrawTextAt(X, Y: Integer; Const S: String; Color: Integer);
Begin
 SetColor(Color);
 OutTextXY(X, Y, S);
End;

{ Dessine une cha??ne avec un caract??re soulign?? (raccourci Alt). }
{ Retire les marqueurs '&' d'une chaine (utilise pour le calcul de largeur). }
Function StripAmp(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := '';
 I := 1;
 While I <= Length(S) Do Begin
  If (S[I] = '&') And (I < Length(S)) Then Begin
   R := R + S[I+1];
   Inc(I, 2);
  End Else Begin
   R := R + S[I];
   Inc(I);
  End;
 End;
 StripAmp := R;
End;

Procedure DrawTextWithAlt(X, Y: Integer; Const S: String;
                          AltCh: Char; Color: Integer);
Var
 I, Px, UX, UW : Integer;
 Disp          : String;
 HasAmp        : Boolean;
 Found         : Boolean;
 Up            : Char;
Begin
 SetColor(Color);
 { Analyse '&' : construit la chaine sans '&' et repere le caractere souligne. }
 Disp := '';
 HasAmp := False;
 UX := X; UW := 0;
 I := 1;
 While I <= Length(S) Do Begin
  If (S[I] = '&') And (I < Length(S)) Then Begin
   HasAmp := True;
   UX := X + TextWidth(Disp);
   UW := TextWidth(S[I+1]);
   Disp := Disp + S[I+1];
   Inc(I, 2);
  End Else Begin
   Disp := Disp + S[I];
   Inc(I);
  End;
 End;
 OutTextXY(X, Y, Disp);
 If HasAmp Then Begin
  Line(UX, Y+8, UX + UW - 1, Y+8);
  Exit;
 End;
 { Aucun '&' explicite : utiliser AltCh par recherche du premier caractere correspondant. }
 If AltCh = #0 Then Exit;
 Found := False;
 Px := X;
 Up := UpCase(AltCh);
 For I := 1 To Length(Disp) Do Begin
  If (Not Found) And (UpCase(Disp[I]) = Up) Then Begin
   Line(Px, Y+8, Px + TextWidth(Disp[I]) - 1, Y+8);
   Found := True;
  End;
  Inc(Px, TextWidth(Disp[I]));
 End;
End;

{ Conversion ReadKey #0+code ??? code ??tendu (>=256). }
Function ReadKeyEx: Word;
Var Ch: Char;
Begin
 Ch := ReadKey;
 If Ch = #0 Then Begin
  Ch := ReadKey;
  ReadKeyEx := 256 + Ord(Ch);
 End Else
  ReadKeyEx := Ord(Ch);
End;

{ ============================================================ }
{ =================  CURSEUR SOURIS LOGICIEL  ================ }
{ ============================================================ }
{ Sous Turbo Pascal + Int 33h, le curseur mat??riel est g??r??    }
{ par le pilote.  Sous PtcMouse il est invisible : on dessine  }
{ une fl??che logicielle avec backing store via GetImage.       }

{$IFDEF FPC}
Procedure DrawSoftCursor(X, Y: Integer);
Var
 X2, Y2 : Integer;
 Sz     : Word;
Begin
 X2 := X + 11;
 Y2 := Y + 17;
 If X2 > SCREEN_W-1 Then X2 := SCREEN_W-1;
 If Y2 > SCREEN_H-1 Then Y2 := SCREEN_H-1;
 Sz := ImageSize(X, Y, X2, Y2);
 If Sz = 0 Then Exit;
 GetMem(MsSaveBuf, Sz);
 GetImage(X, Y, X2, Y2, MsSaveBuf^);
 MsSaveX := X;
 MsSaveY := Y;
 MsSaved := True;
 { Fl??che : contour noir + int??rieur blanc }
 SetColor(Black);
 Line(X,   Y,   X,   Y+14);
 Line(X,   Y,   X+10, Y+10);
 Line(X+10, Y+10, X+6, Y+10);
 Line(X+6, Y+10, X+9, Y+15);
 Line(X+9, Y+15, X+7, Y+16);
 Line(X+7, Y+16, X+4, Y+11);
 Line(X+4, Y+11, X,   Y+14);
 SetFillStyle(SolidFill, White);
 FloodFill(X+2, Y+4, Black);
End;

Procedure EraseSoftCursor;
Begin
 If Not MsSaved Then Exit;
 PutImage(MsSaveX, MsSaveY, MsSaveBuf^, NormalPut);
 FreeMem(MsSaveBuf, ImageSize(MsSaveX, MsSaveY,
   MsSaveX+11, MsSaveY+17));
 MsSaved := False;
End;
{$ELSE}
{ Sous TP : le pilote DOS dessine le curseur via Int 33h. }
Procedure DrawSoftCursor(X, Y: Integer); Begin End;
Procedure EraseSoftCursor; Begin End;
{$ENDIF}

{ ============================================================ }
{ ===================  INIT MENUS / TOOLBARS  ================ }
{ ============================================================ }

Procedure SetMenuItem(M: Integer; Idx: Integer; Const Cap: String;
                     Const Sc: String; Alt: Char; Sep: Boolean;
                     Act: Integer);
Begin
 Menus[M].Items[Idx].Caption   := Cap;
 Menus[M].Items[Idx].Shortcut  := Sc;
 Menus[M].Items[Idx].AltKey    := Alt;
 Menus[M].Items[Idx].Separator := Sep;
 Menus[M].Items[Idx].ActionId  := Act;
 Menus[M].Items[Idx].Enabled   := True;
End;

Procedure InitMenus;
Var I, MaxW, W, J, X: Integer;
Begin
 MenuCount := 9;
 { --- D??finition des menus --- }
 Menus[1].Caption := '&Fichier';   Menus[1].AltKey := 'F';
 Menus[2].Caption := '&Edition';   Menus[2].AltKey := 'E';
 Menus[3].Caption := '&Affichage'; Menus[3].AltKey := 'A';
 Menus[4].Caption := '&Insertion'; Menus[4].AltKey := 'I';
 Menus[5].Caption := 'F&ormat';    Menus[5].AltKey := 'O';
 Menus[6].Caption := 'O&utils';    Menus[6].AltKey := 'U';
 Menus[7].Caption := '&Tableau';   Menus[7].AltKey := 'T';
 Menus[8].Caption := 'Fe&netre';   Menus[8].AltKey := 'N';
 Menus[9].Caption := 'Ai&de';      Menus[9].AltKey := 'D';

 { Fichier }
 Menus[1].ItemCount := 7;
 SetMenuItem(1,1,'&Nouveau',              'Ctrl+N','N',False, ACT_FILE_NEW);
 SetMenuItem(1,2,'&Ouvrir...',            'Ctrl+O','O',False, ACT_FILE_OPEN);
 SetMenuItem(1,3,'&Enregistrer',          'Ctrl+S','E',False, ACT_FILE_SAVE);
 SetMenuItem(1,4,'Enregistrer &sous...',  '',      'S',False, ACT_FILE_SAVEAS);
 SetMenuItem(1,5,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(1,6,'&Imprimer...',          'Ctrl+P','I',False, ACT_FILE_PRINT);
 SetMenuItem(1,7,'&Quitter',              'Alt+X', 'Q',False, ACT_FILE_EXIT);

 { Edition }
 Menus[2].ItemCount := 9;
 SetMenuItem(2,1,'&Annuler',              'Ctrl+Z','A',False, ACT_EDIT_UNDO);
 SetMenuItem(2,2,'&Retablir',             'Ctrl+Y','R',False, ACT_EDIT_REDO);
 SetMenuItem(2,3,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(2,4,'Co&uper',               'Ctrl+X','U',False, ACT_EDIT_CUT);
 SetMenuItem(2,5,'&Copier',               'Ctrl+C','C',False, ACT_EDIT_COPY);
 SetMenuItem(2,6,'Co&ller',               'Ctrl+V','L',False, ACT_EDIT_PASTE);
 SetMenuItem(2,7,'Rec&hercher...',        'Ctrl+F','H',False, ACT_EDIT_FIND);
 SetMenuItem(2,8,'Rechercher &suivant',   'F3',    'S',False, ACT_EDIT_FIND_NEXT);
 SetMenuItem(2,9,'Re&mplacer...',         'Ctrl+H','M',False, ACT_EDIT_REPL);

 { Affichage }
 Menus[3].ItemCount := 4;
 SetMenuItem(3,1,'&Normal',               '',      'N',False, ACT_VIEW_NORMAL);
 SetMenuItem(3,2,'&Mise en page',         '',      'M',False, ACT_VIEW_PAGE);
 SetMenuItem(3,3,'&Regle',                '',      'R',False, ACT_VIEW_RULER);
 SetMenuItem(3,4,'&Zoom...',              '',      'Z',False, ACT_VIEW_ZOOM);

 { Insertion }
 Menus[4].ItemCount := 4;
 SetMenuItem(4,1,'&Saut de page',         'Ctrl+Enter','S',False, ACT_INS_PAGEBRK);
 SetMenuItem(4,2,'&Image...',             '',      'I',False, ACT_INS_IMAGE);
 SetMenuItem(4,3,'Symbo&le...',           '',      'L',False, ACT_INS_SYMBOL);
 SetMenuItem(4,4,'&Tableau...',           '',      'T',False, ACT_INS_TABLE);

 { Format }
 Menus[5].ItemCount := 10;
 SetMenuItem(5,1,'&Police...',            '',      'P',False, ACT_FMT_FONT);
 SetMenuItem(5,2,'Para&graphe...',        '',      'G',False, ACT_FMT_PARA);
 SetMenuItem(5,3,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(5,4,'G&ras',                 'Ctrl+B','R',False, ACT_FMT_BOLD);
 SetMenuItem(5,5,'&Italique',             'Ctrl+I','I',False, ACT_FMT_ITALIC);
 SetMenuItem(5,6,'&Souligne',             'Ctrl+U','S',False, ACT_FMT_UNDER);
 SetMenuItem(5,7,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(5,8,'Aligner a g&auche',     'Ctrl+L','A',False, ACT_FMT_LEFT);
 SetMenuItem(5,9,'&Centrer',              'Ctrl+E','C',False, ACT_FMT_CENTER);
 SetMenuItem(5,10,'Aligner a &droite',    'Ctrl+R','D',False, ACT_FMT_RIGHT);

 { Outils }
 Menus[6].ItemCount := 3;
 SetMenuItem(6,1,'&Orthographe...',       'F7',    'O',False, ACT_TLS_SPELL);
 SetMenuItem(6,2,'Stat&istiques...',      '',      'I',False, ACT_TLS_WORDS);
 SetMenuItem(6,3,'O&ptions...',           '',      'P',False, ACT_TLS_OPTIONS);

 { Tableau }
 Menus[7].ItemCount := 2;
 SetMenuItem(7,1,'&Inserer un tableau...','',      'I',False, ACT_TBL_INSERT);
 SetMenuItem(7,2,'&Supprimer le tableau', '',      'S',False, ACT_TBL_DELETE);

 { Fenetre }
 Menus[8].ItemCount := 1;
 SetMenuItem(8,1,'&Cascade',              '',      'C',False, ACT_WIN_CASCADE);

 { Aide }
 Menus[9].ItemCount := 2;
 SetMenuItem(9,1,'&Sommaire...',          'F1',    'S',False, ACT_HLP_CONTENT);
 SetMenuItem(9,2,'A &propos...',          '',      'P',False, ACT_HLP_ABOUT);

 { --- Calcul positions X dans la barre de menus --- }
 X := 6;
 For I := 1 To MenuCount Do Begin
  Menus[I].X1 := X;
  W := TextWidth(StripAmp(Menus[I].Caption)) + 12;   { padding }
  Menus[I].X2 := X + W;
  X := X + W + 2;
 End;

 { --- Largeur dropdown = max largeur item + raccourci --- }
 For I := 1 To MenuCount Do Begin
  MaxW := 0;
  For J := 1 To Menus[I].ItemCount Do Begin
   W := TextWidth(StripAmp(Menus[I].Items[J].Caption));
   If Menus[I].Items[J].Shortcut <> '' Then
    W := W + 24 + TextWidth(Menus[I].Items[J].Shortcut);
   If W > MaxW Then MaxW := W;
  End;
  Menus[I].DropW := MaxW + 24;
 End;
End;

Procedure AddStdBtn(IconId, ActId: Integer; Const Tip: String;
                    Sep: Boolean);
Begin
 Inc(StdBarCount);
 StdBar[StdBarCount].IconId    := IconId;
 StdBar[StdBarCount].ActionId  := ActId;
 StdBar[StdBarCount].Tooltip   := Tip;
 StdBar[StdBarCount].Pressed   := False;
 StdBar[StdBarCount].Separator := Sep;
End;

Procedure AddFmtBtn(IconId, ActId: Integer; Const Tip: String;
                    Sep: Boolean);
Begin
 Inc(FmtBarCount);
 FmtBar[FmtBarCount].IconId    := IconId;
 FmtBar[FmtBarCount].ActionId  := ActId;
 FmtBar[FmtBarCount].Tooltip   := Tip;
 FmtBar[FmtBarCount].Pressed   := False;
 FmtBar[FmtBarCount].Separator := Sep;
End;

Procedure InitToolbars;
Var
 I, X, Y, BtnW : Integer;
Begin
 StdBarCount := 0;
 AddStdBtn(ICN_NEW,    ACT_FILE_NEW,   'New (Ctrl+N)',    False);
 AddStdBtn(ICN_OPEN,   ACT_FILE_OPEN,  'Open (Ctrl+O)',   False);
 AddStdBtn(ICN_SAVE,   ACT_FILE_SAVE,  'Save (Ctrl+S)',   False);
 AddStdBtn(ICN_PRINT,  ACT_FILE_PRINT, 'Print (Ctrl+P)',  True);
 AddStdBtn(ICN_CUT,    ACT_EDIT_CUT,   'Cut (Ctrl+X)',    False);
 AddStdBtn(ICN_COPY,   ACT_EDIT_COPY,  'Copy (Ctrl+C)',   False);
 AddStdBtn(ICN_PASTE,  ACT_EDIT_PASTE, 'Paste (Ctrl+V)',  True);
 AddStdBtn(ICN_UNDO,   ACT_EDIT_UNDO,  'Undo (Ctrl+Z)',   False);
 AddStdBtn(ICN_REDO,   ACT_EDIT_REDO,  'Redo (Ctrl+Y)',   True);
 AddStdBtn(ICN_IMAGE,  ACT_INS_IMAGE,  'Insert Picture',  False);
 AddStdBtn(ICN_TABLE,  ACT_INS_TABLE,  'Insert Table',    False);

 X := 6;
 Y := STDBAR_TOP + 1;
 BtnW := STDBAR_BTN;
 For I := 1 To StdBarCount Do Begin
  StdBar[I].X := X;
  StdBar[I].Y := Y;
  StdBar[I].W := BtnW;
  StdBar[I].H := BtnW;
  X := X + BtnW + 1;
  If StdBar[I].Separator Then X := X + 6;
 End;

 FmtBarCount := 0;
 AddFmtBtn(ICN_BOLD,    ACT_FMT_BOLD,    'Bold (Ctrl+B)',    False);
 AddFmtBtn(ICN_ITALIC,  ACT_FMT_ITALIC,  'Italic (Ctrl+I)',  False);
 AddFmtBtn(ICN_UNDER,   ACT_FMT_UNDER,   'Underline (Ctrl+U)',False);
 AddFmtBtn(ICN_ALIGN_L, ACT_FMT_LEFT,    'Align Left',       True);
 AddFmtBtn(ICN_ALIGN_C, ACT_FMT_CENTER,  'Align Center',     False);
 AddFmtBtn(ICN_ALIGN_R, ACT_FMT_RIGHT,   'Align Right',      False);
 AddFmtBtn(ICN_ALIGN_J, ACT_FMT_JUSTIFY, 'Justify',          False);

 { Police taille combo : on r??serve la place visuelle dans la barre }
 X := 6 + 100;     { apr??s le combo "Times New Roman" }
 X := X + 50;      { apr??s combo taille }
 Y := FMTBAR_TOP + 1;
 BtnW := FMTBAR_BTN;
 For I := 1 To FmtBarCount Do Begin
  FmtBar[I].X := X;
  FmtBar[I].Y := Y;
  FmtBar[I].W := BtnW;
  FmtBar[I].H := BtnW;
  X := X + BtnW + 1;
  If FmtBar[I].Separator Then X := X + 6;
 End;
End;

{ ============================================================ }
{ ====================  IC??NES VECTORIELLES  ================= }
{ ============================================================ }

Procedure DrawIcon(IconId, Cx, Cy: Integer);
Begin
 Case IconId Of
  ICN_NEW: Begin
   { Feuille blanche avec coin pli?? }
   FillRectArea(Cx-5, Cy-7, Cx+4, Cy+7, White);
   SetColor(Black);
   Rectangle(Cx-5, Cy-7, Cx+4, Cy+7);
   Line(Cx+1, Cy-7, Cx+4, Cy-4);
   Line(Cx+1, Cy-7, Cx+1, Cy-4);
   Line(Cx+1, Cy-4, Cx+4, Cy-4);
  End;
  ICN_OPEN: Begin
   { Dossier ouvert }
   SetFillStyle(SolidFill, Yellow);
   Bar(Cx-7, Cy-2, Cx+7, Cy+6);
   SetColor(DarkGray);
   Rectangle(Cx-7, Cy-2, Cx+7, Cy+6);
   Line(Cx-7, Cy-2, Cx-3, Cy-5);
   Line(Cx-3, Cy-5, Cx+1, Cy-5);
   Line(Cx+1, Cy-5, Cx+3, Cy-2);
  End;
  ICN_SAVE: Begin
   { Disquette 3.5" }
   SetFillStyle(SolidFill, Blue);
   Bar(Cx-7, Cy-7, Cx+7, Cy+7);
   SetColor(Black);
   Rectangle(Cx-7, Cy-7, Cx+7, Cy+7);
   FillRectArea(Cx-4, Cy-7, Cx+4, Cy-2, LightGray);
   FillRectArea(Cx-2, Cy-6, Cx-1, Cy-3, Black);
   FillRectArea(Cx-5, Cy+1, Cx+5, Cy+6, White);
  End;
  ICN_PRINT: Begin
   { Imprimante }
   FillRectArea(Cx-5, Cy-5, Cx+5, Cy-1, LightGray);
   SetColor(Black);
   Rectangle(Cx-7, Cy-1, Cx+7, Cy+4);
   FillRectArea(Cx-4, Cy+4, Cx+4, Cy+7, White);
   Rectangle(Cx-4, Cy+4, Cx+4, Cy+7);
  End;
  ICN_CUT: Begin
   { Ciseaux }
   SetColor(Black);
   Line(Cx-6, Cy-7, Cx+5, Cy+5);
   Line(Cx-6, Cy+5, Cx+5, Cy-7);
   Circle(Cx-5, Cy+5, 2);
   Circle(Cx+5, Cy+5, 2);
  End;
  ICN_COPY: Begin
   { Deux feuilles superpos??es }
   FillRectArea(Cx-6, Cy-6, Cx+2, Cy+4, White);
   SetColor(Black);
   Rectangle(Cx-6, Cy-6, Cx+2, Cy+4);
   FillRectArea(Cx-3, Cy-3, Cx+5, Cy+7, White);
   Rectangle(Cx-3, Cy-3, Cx+5, Cy+7);
  End;
  ICN_PASTE: Begin
   { Presse-papiers + feuille }
   SetFillStyle(SolidFill, LightGray);
   Bar(Cx-6, Cy-6, Cx+6, Cy+7);
   SetColor(Black);
   Rectangle(Cx-6, Cy-6, Cx+6, Cy+7);
   FillRectArea(Cx-2, Cy-7, Cx+2, Cy-5, DarkGray);
   FillRectArea(Cx-3, Cy-2, Cx+5, Cy+5, White);
   Rectangle(Cx-3, Cy-2, Cx+5, Cy+5);
  End;
  ICN_UNDO: Begin
   { Fl??che courb??e vers la gauche }
   SetColor(Blue);
   Arc(Cx, Cy, 30, 180, 6);
   Line(Cx-6, Cy, Cx-3, Cy-3);
   Line(Cx-6, Cy, Cx-3, Cy+3);
  End;
  ICN_REDO: Begin
   SetColor(Blue);
   Arc(Cx, Cy, 0, 150, 6);
   Line(Cx+6, Cy, Cx+3, Cy-3);
   Line(Cx+6, Cy, Cx+3, Cy+3);
  End;
  ICN_BOLD: Begin
   SetColor(Black);
   { Lettre "B" ??paisse }
   OutTextXY(Cx-3, Cy-4, 'B');
   OutTextXY(Cx-2, Cy-4, 'B');
  End;
  ICN_ITALIC: Begin
   SetColor(Black);
   { Lettre "I" inclin??e approxim??e }
   Line(Cx-2, Cy-5, Cx+2, Cy-5);
   Line(Cx, Cy-5, Cx-2, Cy+5);
   Line(Cx-4, Cy+5, Cx, Cy+5);
  End;
  ICN_UNDER: Begin
   SetColor(Black);
   OutTextXY(Cx-3, Cy-5, 'U');
   Line(Cx-4, Cy+5, Cx+4, Cy+5);
  End;
  ICN_ALIGN_L: Begin
   SetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-7, Cy-2, Cx+3, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-7, Cy+4, Cx+3, Cy+4);
  End;
  ICN_ALIGN_C: Begin
   SetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-5, Cy-2, Cx+5, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-5, Cy+4, Cx+5, Cy+4);
  End;
  ICN_ALIGN_R: Begin
   SetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-3, Cy-2, Cx+7, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-3, Cy+4, Cx+7, Cy+4);
  End;
  ICN_ALIGN_J: Begin
   SetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-7, Cy-2, Cx+7, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-7, Cy+4, Cx+7, Cy+4);
  End;
  ICN_IMAGE: Begin
   { Cadre photo avec montagne }
   FillRectArea(Cx-7, Cy-6, Cx+7, Cy+6, White);
   SetColor(Black);
   Rectangle(Cx-7, Cy-6, Cx+7, Cy+6);
   SetFillStyle(SolidFill, Yellow);
   FillEllipse(Cx-3, Cy-2, 2, 2);
   SetColor(Green);
   Line(Cx-7, Cy+5, Cx-2, Cy);
   Line(Cx-2, Cy, Cx+3, Cy+5);
   Line(Cx+1, Cy+2, Cx+7, Cy+5);
  End;
  ICN_TABLE: Begin
   SetColor(Black);
   Rectangle(Cx-7, Cy-6, Cx+7, Cy+6);
   Line(Cx-7, Cy-2, Cx+7, Cy-2);
   Line(Cx-7, Cy+2, Cx+7, Cy+2);
   Line(Cx-2, Cy-6, Cx-2, Cy+6);
   Line(Cx+3, Cy-6, Cx+3, Cy+6);
  End;
 End;
End;

{ ============================================================ }
{ =====================  DESSIN INTERFACE  =================== }
{ ============================================================ }

Procedure DrawMenuBar;
Var
 I  : Integer;
 Y0 : Integer;
Begin
 Y0 := MENUBAR_TOP;
 FillRectArea(0, Y0, SCREEN_W-1, Y0+MENUBAR_HEIGHT-1, MENUBAR_BG);
 DrawHLine(0, SCREEN_W-1, Y0+MENUBAR_HEIGHT-1, CLR_3D_DARK);
 For I := 1 To MenuCount Do Begin
  If ActiveMenu = I Then Begin
   FillRectArea(Menus[I].X1, Y0+1, Menus[I].X2, Y0+MENUBAR_HEIGHT-2,
                MENUBAR_HL_BG);
   DrawTextWithAlt(Menus[I].X1+5, Y0+5, Menus[I].Caption,
                   Menus[I].AltKey, MENUBAR_HL_FG);
  End Else
   DrawTextWithAlt(Menus[I].X1+5, Y0+5, Menus[I].Caption,
                   Menus[I].AltKey, MENUBAR_FG);
 End;
End;

Procedure DrawMenuDropdown;
Var
 M, I, X1, Y1, X2, Y2, ItY, IH : Integer;
 Item : TMenuItem;
Begin
 If ActiveMenu < 1 Then Exit;
 M := ActiveMenu;
 IH := 16;
 X1 := Menus[M].X1;
 Y1 := MENUBAR_HEIGHT;
 X2 := X1 + Menus[M].DropW;
 Y2 := Y1 + Menus[M].ItemCount * IH + 4;
 If X2 > SCREEN_W-1 Then Begin
  X1 := SCREEN_W-1 - Menus[M].DropW;
  X2 := SCREEN_W-1;
 End;
 { Ombre }
 FillRectArea(X1+3, Y2+1, X2+3, Y2+3, Black);
 FillRectArea(X2+1, Y1+3, X2+3, Y2+3, Black);
 { Cadre }
 FillRectArea(X1, Y1, X2, Y2, MENUBAR_BG);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 DrawHLine(X1+1, X2-1, Y1+1, CLR_3D_LIGHT);
 DrawVLine(X1+1, Y1+1, Y2-1, CLR_3D_LIGHT);

 For I := 1 To Menus[M].ItemCount Do Begin
  Item := Menus[M].Items[I];
  ItY := Y1 + 2 + (I-1)*IH;
  If Item.Separator Then Begin
   DrawHLine(X1+4, X2-4, ItY+IH Div 2, CLR_3D_DARK);
   DrawHLine(X1+4, X2-4, ItY+IH Div 2 + 1, CLR_3D_LIGHT);
  End Else Begin
   If MenuItemHover = I Then Begin
    FillRectArea(X1+2, ItY, X2-2, ItY+IH-1, MENUBAR_HL_BG);
    DrawTextWithAlt(X1+8, ItY+3, Item.Caption, Item.AltKey,
                    MENUBAR_HL_FG);
    If Item.Shortcut <> '' Then
     DrawTextAt(X2 - TextWidth(Item.Shortcut) - 8, ItY+3,
                Item.Shortcut, MENUBAR_HL_FG);
   End Else Begin
    DrawTextWithAlt(X1+8, ItY+3, Item.Caption, Item.AltKey,
                    MENUBAR_FG);
    If Item.Shortcut <> '' Then
     DrawTextAt(X2 - TextWidth(Item.Shortcut) - 8, ItY+3,
                Item.Shortcut, CLR_3D_DARK);
   End;
  End;
 End;
End;

Procedure DrawStdToolbar;
Var
 I, Cx, Cy : Integer;
Begin
 FillRectArea(0, STDBAR_TOP, SCREEN_W-1,
              STDBAR_TOP+STDBAR_HEIGHT-1, STDBAR_BG);
 DrawHLine(0, SCREEN_W-1, STDBAR_TOP+STDBAR_HEIGHT-1, CLR_3D_DARK);
 For I := 1 To StdBarCount Do Begin
  DrawButton3D(StdBar[I].X, StdBar[I].Y,
               StdBar[I].X+StdBar[I].W,
               StdBar[I].Y+StdBar[I].H,
               (HoveredStdBtn = I) And ((MsBtn And MB_LEFT) <> 0));
  Cx := StdBar[I].X + StdBar[I].W Div 2;
  Cy := StdBar[I].Y + StdBar[I].H Div 2;
  DrawIcon(StdBar[I].IconId, Cx, Cy);
  If StdBar[I].Separator Then
   DrawVLine(StdBar[I].X+StdBar[I].W+3,
             StdBar[I].Y, StdBar[I].Y+StdBar[I].H, CLR_3D_DARK);
 End;
End;

Procedure DrawFmtToolbar;
Var
 I, Cx, Cy : Integer;
 SizeStr   : String[8];
Begin
 FillRectArea(0, FMTBAR_TOP, SCREEN_W-1,
              FMTBAR_TOP+FMTBAR_HEIGHT-1, FMTBAR_BG);
 DrawHLine(0, SCREEN_W-1, FMTBAR_TOP+FMTBAR_HEIGHT-1, CLR_3D_DARK);

 { Combo "Police" - placeholder }
 FillRectArea(6, FMTBAR_TOP+2, 100, FMTBAR_TOP+FMTBAR_HEIGHT-3, White);
 DrawSunkenRect(6, FMTBAR_TOP+2, 100, FMTBAR_TOP+FMTBAR_HEIGHT-3);
 DrawTextAt(10, FMTBAR_TOP+5, 'Times New Roman', Black);
 SetColor(Black);
 { triangle dropdown }
 Line(92, FMTBAR_TOP+8,  98, FMTBAR_TOP+8);
 Line(93, FMTBAR_TOP+9,  97, FMTBAR_TOP+9);
 Line(94, FMTBAR_TOP+10, 96, FMTBAR_TOP+10);
 Line(95, FMTBAR_TOP+11, 95, FMTBAR_TOP+11);

 { Combo "Taille" }
 FillRectArea(106, FMTBAR_TOP+2, 150, FMTBAR_TOP+FMTBAR_HEIGHT-3, White);
 DrawSunkenRect(106, FMTBAR_TOP+2, 150, FMTBAR_TOP+FMTBAR_HEIGHT-3);
 Str(CurrentStyle.FontSize, SizeStr);
 DrawTextAt(112, FMTBAR_TOP+5, SizeStr, Black);
 Line(140, FMTBAR_TOP+8,  146, FMTBAR_TOP+8);
 Line(141, FMTBAR_TOP+9,  145, FMTBAR_TOP+9);
 Line(142, FMTBAR_TOP+10, 144, FMTBAR_TOP+10);
 Line(143, FMTBAR_TOP+11, 143, FMTBAR_TOP+11);

 For I := 1 To FmtBarCount Do Begin
  DrawButton3D(FmtBar[I].X, FmtBar[I].Y,
               FmtBar[I].X+FmtBar[I].W,
               FmtBar[I].Y+FmtBar[I].H, FmtBar[I].Pressed);
  Cx := FmtBar[I].X + FmtBar[I].W Div 2;
  Cy := FmtBar[I].Y + FmtBar[I].H Div 2;
  DrawIcon(FmtBar[I].IconId, Cx, Cy);
 End;
End;

Procedure DrawRuler;
Var
 I, X, PageX1, PageX2 : Integer;
 PMx                  : Integer;
Begin
 FillRectArea(0, RULER_TOP, SCREEN_W-1,
              RULER_TOP+RULER_HEIGHT-1, RULER_BG);
 DrawHLine(0, SCREEN_W-1, RULER_TOP+RULER_HEIGHT-1, CLR_3D_DARK);

 { Centre la "page" : graduations en pouces (1 pouce ~= 50 px) }
 PageX1 := (SCREEN_W - PAGE_W) Div 2;
 PageX2 := PageX1 + PAGE_W;
 PMx := 50;   { 1 pouce visuel = 50 pixels }
 SetColor(RULER_FG);
 For I := 0 To 9 Do Begin
  X := PageX1 + PAGE_MARGIN_L + I*PMx;
  If X < PageX2 Then Begin
   Line(X, RULER_TOP+9, X, RULER_TOP+12);
   { num??ros impairs / pairs }
   If I > 0 Then Begin
    SetColor(RULER_FG);
    Line(X-2, RULER_TOP+5, X+2, RULER_TOP+5);
   End;
  End;
 End;
 { Indication marges }
 SetColor(DarkGray);
 Line(PageX1+PAGE_MARGIN_L, RULER_TOP+1,
      PageX1+PAGE_MARGIN_L, RULER_TOP+RULER_HEIGHT-2);
 Line(PageX2-PAGE_MARGIN_R, RULER_TOP+1,
      PageX2-PAGE_MARGIN_R, RULER_TOP+RULER_HEIGHT-2);
End;

{ ============================================================ }
{ =================  PHASE 2 : LAYOUT / SAISIE  ============== }
{ ============================================================ }

Const
 MAX_VLINES        = 2000;
 LINE_HEIGHT       = 12;
 CURSOR_BLINK_TICKS= 25;     { ~500ms avec Delay(20) }
 MAX_IMG_W         = 340;    { largeur max image (= AvailW d'une page) }
 MAX_IMG_H         = 400;    { hauteur max image }

Type
 TVisualLine = Record
  ParaIdx   : Integer;       { 1..Doc.ParaCount }
  CharStart : Integer;       { 1-based offset dans paragraphe }
  CharLen   : Integer;       { nb caract??res de la ligne }
  PageIdx   : Integer;       { 1..Doc.PageCount }
  X, Y      : Integer;       { coords ??cran (sans ScrollY) }
  Width     : Integer;       { largeur pixel du texte }
  Height    : Integer;       { hauteur pixel (LINE_HEIGHT ou ImgH) }
  Alignment : Byte;
  IsImage   : Boolean;
 End;

Var
 VLines           : Array[1..MAX_VLINES] Of TVisualLine;
 VLineCount       : Integer;
 NeedsRelayout    : Boolean;
 CursorBlinkOn    : Boolean;
 CursorBlinkCnt   : Integer;

{ ----- Manipulation paragraphes (Phase 2: 1 run / paragraphe) ----- }

Function ParaText(P: Integer): String;
Var I: Integer; S: String;
Begin
 S := '';
 For I := 1 To Doc.Paragraphs[P].RunCount Do
  S := S + Doc.Paragraphs[P].Runs[I].Text;
 ParaText := S;
End;

Procedure ParaSetText(P: Integer; Const S: String);
Begin
 If Doc.Paragraphs[P].RunCount < 1 Then Begin
  Doc.Paragraphs[P].RunCount := 1;
  Doc.Paragraphs[P].Runs[1].Style := CurrentStyle;
 End;
 Doc.Paragraphs[P].Runs[1].Text := S;
 { Phase 2 : on consolide en un seul run }
 Doc.Paragraphs[P].RunCount := 1;
End;

{ ----- Phase 3 : helpers multi-run ----------------------------- }

Function StyleEq(Const A, B: TCharStyle): Boolean;
Begin
 StyleEq := (A.FontSize = B.FontSize) And
            (A.Style    = B.Style)    And
            (A.Color    = B.Color);
End;

{ Localise (RIdx, ROff) o? ins?rer un caract?re ? la position
  CharIdx (0-based, 0..Length(ParaText)). ROff est l'index 0-based
  dans Runs[RIdx].Text o? l'insertion aurait lieu (0..Length). }
Procedure LocateInsertion(P, CharIdx: Integer; Var RIdx, ROff: Integer);
Var Acc, K, L: Integer;
Begin
 Acc := 0;
 For K := 1 To Doc.Paragraphs[P].RunCount Do Begin
  L := Length(Doc.Paragraphs[P].Runs[K].Text);
  If CharIdx <= Acc + L Then Begin
   RIdx := K;
   ROff := CharIdx - Acc;
   Exit;
  End;
  Inc(Acc, L);
 End;
 RIdx := Doc.Paragraphs[P].RunCount;
 If RIdx < 1 Then RIdx := 1;
 ROff := Length(Doc.Paragraphs[P].Runs[RIdx].Text);
End;

{ Localise (RIdx, ROff) du caract?re ? la position CharIdx
  (0-based, 0..Length-1). ROff est l'index 0-based dans le run. }
Procedure LocateChar(P, CharIdx: Integer; Var RIdx, ROff: Integer);
Var Acc, K, L: Integer;
Begin
 Acc := 0;
 For K := 1 To Doc.Paragraphs[P].RunCount Do Begin
  L := Length(Doc.Paragraphs[P].Runs[K].Text);
  If CharIdx < Acc + L Then Begin
   RIdx := K;
   ROff := CharIdx - Acc;
   Exit;
  End;
  Inc(Acc, L);
 End;
 RIdx := Doc.Paragraphs[P].RunCount;
 If RIdx < 1 Then RIdx := 1;
 ROff := Length(Doc.Paragraphs[P].Runs[RIdx].Text) - 1;
 If ROff < 0 Then ROff := 0;
End;

{ Ins?re un run vide ? la position RIdx (les runs ?RIdx d?cal?s). }
Function InsertRunAt(P, RIdx: Integer): Boolean;
Var I: Integer;
Begin
 If Doc.Paragraphs[P].RunCount >= MAX_RUNS_PER_PARA Then Begin
  InsertRunAt := False; Exit;
 End;
 For I := Doc.Paragraphs[P].RunCount Downto RIdx Do
  Doc.Paragraphs[P].Runs[I + 1] := Doc.Paragraphs[P].Runs[I];
 Inc(Doc.Paragraphs[P].RunCount);
 Doc.Paragraphs[P].Runs[RIdx].Text := '';
 FillChar(Doc.Paragraphs[P].Runs[RIdx].Style, SizeOf(TCharStyle), 0);
 InsertRunAt := True;
End;

Procedure RemoveRunAt(P, RIdx: Integer);
Var I: Integer;
Begin
 If (RIdx < 1) Or (RIdx > Doc.Paragraphs[P].RunCount) Then Exit;
 For I := RIdx To Doc.Paragraphs[P].RunCount - 1 Do
  Doc.Paragraphs[P].Runs[I] := Doc.Paragraphs[P].Runs[I + 1];
 FillChar(Doc.Paragraphs[P].Runs[Doc.Paragraphs[P].RunCount],
          SizeOf(TRun), 0);
 Dec(Doc.Paragraphs[P].RunCount);
 If Doc.Paragraphs[P].RunCount = 0 Then Begin
  Doc.Paragraphs[P].RunCount := 1;
  Doc.Paragraphs[P].Runs[1].Style := CurrentStyle;
  Doc.Paragraphs[P].Runs[1].Text  := '';
 End;
End;

Procedure MergeAdjacentSameStyleRuns(P: Integer);
Var I: Integer;
Begin
 I := 1;
 While I < Doc.Paragraphs[P].RunCount Do Begin
  If StyleEq(Doc.Paragraphs[P].Runs[I].Style,
             Doc.Paragraphs[P].Runs[I+1].Style) Then Begin
   Doc.Paragraphs[P].Runs[I].Text :=
    Doc.Paragraphs[P].Runs[I].Text + Doc.Paragraphs[P].Runs[I+1].Text;
   RemoveRunAt(P, I+1);
  End Else
   Inc(I);
 End;
End;

{ Forward : helpers selection definis plus bas (apres CursorScreenX). }
Function  SelHasRange: Boolean; Forward;
Procedure SelGetRange(Var P1, C1, P2, C2: Integer); Forward;

{ Garantit une frontiere de run au caractere CharOff (0-based) du
  paragraphe P. Si CharOff tombe au milieu d'un run, le decoupe en
  deux runs adjacents de meme style. Retourne True en cas de succes
  (False uniquement si MAX_RUNS_PER_PARA atteint). }
Function SplitRunAtChar(P, CharOff: Integer): Boolean;
Var
 RIdx, ROff, ParaLen : Integer;
 Tail                : String;
Begin
 SplitRunAtChar := True;
 ParaLen := Length(ParaText(P));
 If CharOff <= 0 Then Exit;
 If CharOff >= ParaLen Then Exit;
 LocateChar(P, CharOff, RIdx, ROff);
 If ROff = 0 Then Exit;   { deja sur une frontiere }
 If Doc.Paragraphs[P].RunCount >= MAX_RUNS_PER_PARA Then Begin
  SplitRunAtChar := False; Exit;
 End;
 Tail := Copy(Doc.Paragraphs[P].Runs[RIdx].Text, ROff + 1,
              Length(Doc.Paragraphs[P].Runs[RIdx].Text) - ROff);
 Doc.Paragraphs[P].Runs[RIdx].Text :=
  Copy(Doc.Paragraphs[P].Runs[RIdx].Text, 1, ROff);
 If Not InsertRunAt(P, RIdx + 1) Then Begin
  { rollback }
  Doc.Paragraphs[P].Runs[RIdx].Text :=
   Doc.Paragraphs[P].Runs[RIdx].Text + Tail;
  SplitRunAtChar := False; Exit;
 End;
 Doc.Paragraphs[P].Runs[RIdx + 1].Style := Doc.Paragraphs[P].Runs[RIdx].Style;
 Doc.Paragraphs[P].Runs[RIdx + 1].Text  := Tail;
End;

{ True si tous les caracteres de [C1..C2) du paragraphe P portent
  le bit StyBit. Retourne True si l'intervalle est vide. }
Function ParaRangeAllHaveStyle(P, C1, C2: Integer; StyBit: Byte): Boolean;
Var
 K, Acc, RL, SegStart, SegEnd : Integer;
Begin
 ParaRangeAllHaveStyle := True;
 If C2 <= C1 Then Exit;
 Acc := 0;
 For K := 1 To Doc.Paragraphs[P].RunCount Do Begin
  RL := Length(Doc.Paragraphs[P].Runs[K].Text);
  SegStart := Acc;   If C1 > SegStart Then SegStart := C1;
  SegEnd   := Acc + RL; If C2 < SegEnd Then SegEnd := C2;
  If SegEnd > SegStart Then
   If (Doc.Paragraphs[P].Runs[K].Style.Style And StyBit) = 0 Then Begin
    ParaRangeAllHaveStyle := False; Exit;
   End;
  Inc(Acc, RL);
 End;
End;

{ Applique (Set=True) ou retire (Set=False) le bit StyBit sur tous les
  runs couvrant [C1..C2) du paragraphe P. Decoupe les runs aux bornes. }
Procedure ParaApplyStyleBit(P, C1, C2: Integer; StyBit: Byte; SetIt: Boolean);
Var
 K, Acc, RL, NewStyle : Integer;
Begin
 If C2 <= C1 Then Exit;
 { Decouper aux deux bornes (l'ordre importe : C2 d'abord pour ne pas
   invalider l'offset de C1 -- en fait c'est l'inverse, decouper C1
   peut decaler les runs apres C1 mais pas les chars; les offsets de
   caracteres sont absolus dans le paragraphe et ne bougent pas). }
 If Not SplitRunAtChar(P, C1) Then Exit;
 If Not SplitRunAtChar(P, C2) Then Exit;
 Acc := 0;
 For K := 1 To Doc.Paragraphs[P].RunCount Do Begin
  RL := Length(Doc.Paragraphs[P].Runs[K].Text);
  If (Acc >= C1) And (Acc + RL <= C2) And (RL > 0) Then Begin
   NewStyle := Doc.Paragraphs[P].Runs[K].Style.Style;
   If SetIt Then NewStyle := NewStyle Or StyBit
   Else NewStyle := NewStyle And (Not StyBit);
   Doc.Paragraphs[P].Runs[K].Style.Style := Byte(NewStyle);
  End;
  Inc(Acc, RL);
 End;
 MergeAdjacentSameStyleRuns(P);
End;

{ Applique le bit StyBit sur l'ensemble de la selection en cours, en
  basculant : si TOUS les caracteres l'ont deja, on le retire ; sinon
  on l'ajoute partout. Aucun effet si pas de selection active. }
Procedure SelApplyStyleBit(StyBit: Byte);
Var
 P1, C1, P2, C2, P, ParaLen, RangeL, RangeR : Integer;
 AllSet                                     : Boolean;
Begin
 If Not SelHasRange Then Exit;
 SelGetRange(P1, C1, P2, C2);
 AllSet := True;
 For P := P1 To P2 Do Begin
  ParaLen := Length(ParaText(P));
  If P = P1 Then RangeL := C1 Else RangeL := 0;
  If P = P2 Then RangeR := C2 Else RangeR := ParaLen;
  If RangeL < 0 Then RangeL := 0;
  If RangeR > ParaLen Then RangeR := ParaLen;
  If RangeR > RangeL Then
   If Not ParaRangeAllHaveStyle(P, RangeL, RangeR, StyBit) Then Begin
    AllSet := False; Break;
   End;
 End;
 For P := P1 To P2 Do Begin
  ParaLen := Length(ParaText(P));
  If P = P1 Then RangeL := C1 Else RangeL := 0;
  If P = P2 Then RangeR := C2 Else RangeR := ParaLen;
  If RangeL < 0 Then RangeL := 0;
  If RangeR > ParaLen Then RangeR := ParaLen;
  If RangeR > RangeL Then
   ParaApplyStyleBit(P, RangeL, RangeR, StyBit, Not AllSet);
 End;
 Doc.Modified  := True;
 NeedsRelayout := True;
End;

{ Applique la fonte/agrandissement n?cessaires ? un style donn?.
  Phase 3 : tailles toutes ? mag 1, gras simul? par overstrike. }
Procedure ApplyRunStyle(Const Sty: TCharStyle);
Begin
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(Sty.Color);
End;

{ Dessine S en (X,Y) avec gras (double-frappe +1px) et/ou italique
  (cisaillement : moitie haute decalee de +1 px) selon Sty.Style.
  La police 8x8 par defaut de BGI n'a pas de variante italique :
  on simule via deux SetViewPort qui clippent le haut et le bas du
  glyphe et redessinent avec un decalage horizontal. }
Procedure DrawStyledText(X, Y: Integer; Const S: String;
                         Const Sty: TCharStyle);
Var
 VP : ViewPortType;
 TW : Integer;
Begin
 If (Sty.Style And STY_ITALIC) <> 0 Then Begin
  TW := TextWidth(S);
  If (Sty.Style And STY_BOLD) <> 0 Then Inc(TW);
  GetViewSettings(VP);
  { Moitie haute (rangees 0..3) decalee de +1 px vers la droite }
  SetViewPort(X, Y, X + TW + 2, Y + 3, ClipOn);
  OutTextXY(1, 0, S);
  If (Sty.Style And STY_BOLD) <> 0 Then OutTextXY(2, 0, S);
  { Moitie basse (rangees 4..7) sans decalage }
  SetViewPort(X, Y + 4, X + TW + 2, Y + 7, ClipOn);
  OutTextXY(0, -4, S);
  If (Sty.Style And STY_BOLD) <> 0 Then OutTextXY(1, -4, S);
  SetViewPort(VP.X1, VP.Y1, VP.X2, VP.Y2, VP.Clip);
 End Else Begin
  OutTextXY(X, Y, S);
  If (Sty.Style And STY_BOLD) <> 0 Then OutTextXY(X + 1, Y, S);
 End;
End;

{ ----- Layout : word-wrap + pagination ------------------------- }

Procedure LayoutDocument;
Var
 P, Pos, LineStart, LineEnd, LastSpace : Integer;
 W, CharW, AvailW                      : Integer;
 ParaStr                               : String;
 Ch                                    : Char;
 PageIdx                               : Integer;
 PageX1, PageContentL, PageContentR    : Integer;
 PageContentBottom                     : Integer;
 CurY                                  : Integer;     { offset Y dans la page }
 LineW, LineX                          : Integer;
 LineYAbs                              : Integer;
 PageTopAbs                            : Integer;
 SettledLineEnd                        : Integer;
 PAlign                                : Byte;

 Function ComputeLineX(LW: Integer; AL: Byte): Integer;
 Begin
  Case AL Of
   ALIGN_CENTER : ComputeLineX := PageContentL + (AvailW - LW) Div 2;
   ALIGN_RIGHT  : ComputeLineX := PageContentR - LW;
  Else
   ComputeLineX := PageContentL;     { LEFT et JUSTIFY = bord gauche }
  End;
 End;

 Procedure EmitLine(PI, CSt, CLn, LX, LY, LW, LH: Integer; AL: Byte; IsImg: Boolean);
 Begin
  If VLineCount >= MAX_VLINES Then Exit;
  Inc(VLineCount);
  VLines[VLineCount].ParaIdx   := PI;
  VLines[VLineCount].CharStart := CSt;
  VLines[VLineCount].CharLen   := CLn;
  VLines[VLineCount].PageIdx   := PageIdx;
  VLines[VLineCount].X         := LX;
  VLines[VLineCount].Y         := LY;
  VLines[VLineCount].Width     := LW;
  VLines[VLineCount].Height    := LH;
  VLines[VLineCount].Alignment := AL;
  VLines[VLineCount].IsImage   := IsImg;
 End;

Begin
 VLineCount := 0;
 PageIdx := 1;
 PageX1 := (SCREEN_W - PAGE_W) Div 2;
 PageContentL := PageX1 + PAGE_MARGIN_L;
 PageContentR := PageX1 + PAGE_W - PAGE_MARGIN_R;
 AvailW := PageContentR - PageContentL;
 PageContentBottom := PAGE_H - PAGE_MARGIN_B;
 CurY := PAGE_MARGIN_T;

 SetTextStyle(DefaultFont, HorizDir, 1);

 For P := 1 To Doc.ParaCount Do Begin
  { Saut de page dur avant ce paragraphe }
  If Doc.Paragraphs[P].PageBreakBefore And (P > 1) Then Begin
   Inc(PageIdx);
   CurY := PAGE_MARGIN_T;
  End;

  PAlign  := Doc.Paragraphs[P].Alignment;

  { Paragraphe image : 1 VLine, hauteur = ImgH }
  If Doc.Paragraphs[P].IsImage Then Begin
   If CurY + Doc.Paragraphs[P].ImgH > PageContentBottom Then Begin
    Inc(PageIdx);
    CurY := PAGE_MARGIN_T;
   End;
   PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
   LineYAbs := PageTopAbs + CurY;
   LineX := ComputeLineX(Doc.Paragraphs[P].ImgW, PAlign);
   EmitLine(P, 1, 0, LineX, LineYAbs,
            Doc.Paragraphs[P].ImgW, Doc.Paragraphs[P].ImgH,
            PAlign, True);
   Inc(CurY, Doc.Paragraphs[P].ImgH + 4);
   Continue;
  End;

  ParaStr := ParaText(P);

  If Length(ParaStr) = 0 Then Begin
   { Paragraphe vide = 1 ligne vide }
   If CurY + LINE_HEIGHT > PageContentBottom Then Begin
    Inc(PageIdx);
    CurY := PAGE_MARGIN_T;
   End;
   PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
   LineYAbs := PageTopAbs + CurY;
   EmitLine(P, 1, 0, ComputeLineX(0, PAlign), LineYAbs, 0,
            LINE_HEIGHT, PAlign, False);
   Inc(CurY, LINE_HEIGHT);
   Continue;
  End;

  LineStart := 1;
  While LineStart <= Length(ParaStr) Do Begin
   { Greedy fit jusqu'au prochain wrap }
   Pos := LineStart;
   W := 0;
   LastSpace := 0;
   SettledLineEnd := 0;
   While Pos <= Length(ParaStr) Do Begin
    Ch := ParaStr[Pos];
    CharW := TextWidth(Ch);
    If W + CharW > AvailW Then Begin
     If LastSpace >= LineStart Then
      SettledLineEnd := LastSpace
     Else Begin
      SettledLineEnd := Pos - 1;
      If SettledLineEnd < LineStart Then SettledLineEnd := LineStart;
     End;
     Break;
    End;
    Inc(W, CharW);
    If Ch = ' ' Then LastSpace := Pos;
    Inc(Pos);
   End;
   If SettledLineEnd = 0 Then
    LineEnd := Length(ParaStr)
   Else
    LineEnd := SettledLineEnd;

   LineW := TextWidth(Copy(ParaStr, LineStart, LineEnd - LineStart + 1));
   LineX := ComputeLineX(LineW, PAlign);

   If CurY + LINE_HEIGHT > PageContentBottom Then Begin
    Inc(PageIdx);
    CurY := PAGE_MARGIN_T;
   End;
   PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
   LineYAbs := PageTopAbs + CurY;
   EmitLine(P, LineStart, LineEnd - LineStart + 1,
            LineX, LineYAbs, LineW, LINE_HEIGHT, PAlign, False);
   Inc(CurY, LINE_HEIGHT);
   LineStart := LineEnd + 1;
  End;
 End;

 If PageIdx > MAX_PAGES Then PageIdx := MAX_PAGES;
 Doc.PageCount := PageIdx;
 NeedsRelayout := False;
End;

{ ----- Recherche ligne du curseur + position ??cran ------------ }

Function FindCursorVLine: Integer;
Var I, R, LastInPara: Integer;
Begin
 R := 0; LastInPara := 0;
 For I := 1 To VLineCount Do
  If VLines[I].ParaIdx = Cursor.ParaIdx Then Begin
   LastInPara := I;
   If R = 0 Then
    If (Cursor.CharIdx >= VLines[I].CharStart - 1) And
       (Cursor.CharIdx <  VLines[I].CharStart + VLines[I].CharLen) Then
     R := I;
  End;
 If R = 0 Then R := LastInPara;
 FindCursorVLine := R;
End;

Function CursorScreenX(L: Integer): Integer;
Var
 Off, AvailW, SpaceCnt, Slack             : Integer;
 PerSpace, Remainder, Extra, SpacesSeen   : Integer;
 I, Limit, J, LastNonSpaceAbs, EffW, Idx  : Integer;
 ParaStr, Sub                             : String;
 IsLastInPara                             : Boolean;
Begin
 Off := Cursor.CharIdx - (VLines[L].CharStart - 1);
 If Off < 0 Then Off := 0;
 If Off > VLines[L].CharLen Then Off := VLines[L].CharLen;
 ParaStr := ParaText(VLines[L].ParaIdx);
 Sub := Copy(ParaStr, VLines[L].CharStart, Off);
 SetTextStyle(DefaultFont, HorizDir, 1);

 Extra := 0;
 If VLines[L].Alignment = ALIGN_JUSTIFY Then Begin
  If L >= VLineCount Then IsLastInPara := True
  Else IsLastInPara := VLines[L+1].ParaIdx <> VLines[L].ParaIdx;
  If Not IsLastInPara Then Begin
   AvailW := PAGE_W - PAGE_MARGIN_L - PAGE_MARGIN_R;
   { Determine la position 1-based dans le para du dernier non-espace. }
   LastNonSpaceAbs := 0;
   For J := 1 To VLines[L].CharLen Do Begin
    Idx := VLines[L].CharStart + J - 1;
    If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
     If ParaStr[Idx] <> ' ' Then LastNonSpaceAbs := Idx;
   End;
   SpaceCnt := 0;
   If LastNonSpaceAbs > 0 Then
    For I := VLines[L].CharStart To LastNonSpaceAbs - 1 Do
     If (I >= 1) And (I <= Length(ParaStr)) Then
      If ParaStr[I] = ' ' Then Inc(SpaceCnt);
   If LastNonSpaceAbs > 0 Then
    EffW := TextWidth(Copy(ParaStr, VLines[L].CharStart,
                            LastNonSpaceAbs - VLines[L].CharStart + 1))
   Else
    EffW := 0;
   Slack := AvailW - EffW;
   If (SpaceCnt > 0) And (Slack > 0) Then Begin
    PerSpace  := Slack Div SpaceCnt;
    Remainder := Slack Mod SpaceCnt;
    SpacesSeen := 0;
    Limit := VLines[L].CharStart + Off - 1;
    For I := VLines[L].CharStart To Limit Do
     If (I >= 1) And (I <= Length(ParaStr)) And (I < LastNonSpaceAbs) Then
      If ParaStr[I] = ' ' Then Begin
       Inc(SpacesSeen);
       Inc(Extra, PerSpace);
       If SpacesSeen <= Remainder Then Inc(Extra);
      End;
   End;
  End;
 End;
 CursorScreenX := VLines[L].X + TextWidth(Sub) + Extra;
End;

{ Position ecran X de la limite gauche du caractere a l'offset
  AbsCharIdx (0-based dans le paragraphe) sur la ligne visuelle L.
  Identique a CursorScreenX mais parametre par AbsCharIdx. }
Function LineCharScreenX(L, AbsCharIdx: Integer): Integer;
Var
 Off, AvailW, SpaceCnt, Slack             : Integer;
 PerSpace, Remainder, Extra, SpacesSeen   : Integer;
 I, Limit, J, LastNonSpaceAbs, EffW, Idx  : Integer;
 ParaStr, Sub                             : String;
 IsLastInPara                             : Boolean;
Begin
 Off := AbsCharIdx - (VLines[L].CharStart - 1);
 If Off < 0 Then Off := 0;
 If Off > VLines[L].CharLen Then Off := VLines[L].CharLen;
 ParaStr := ParaText(VLines[L].ParaIdx);
 Sub := Copy(ParaStr, VLines[L].CharStart, Off);
 SetTextStyle(DefaultFont, HorizDir, 1);
 Extra := 0;
 If VLines[L].Alignment = ALIGN_JUSTIFY Then Begin
  If L >= VLineCount Then IsLastInPara := True
  Else IsLastInPara := VLines[L+1].ParaIdx <> VLines[L].ParaIdx;
  If Not IsLastInPara Then Begin
   AvailW := PAGE_W - PAGE_MARGIN_L - PAGE_MARGIN_R;
   LastNonSpaceAbs := 0;
   For J := 1 To VLines[L].CharLen Do Begin
    Idx := VLines[L].CharStart + J - 1;
    If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
     If ParaStr[Idx] <> ' ' Then LastNonSpaceAbs := Idx;
   End;
   SpaceCnt := 0;
   If LastNonSpaceAbs > 0 Then
    For I := VLines[L].CharStart To LastNonSpaceAbs - 1 Do
     If (I >= 1) And (I <= Length(ParaStr)) Then
      If ParaStr[I] = ' ' Then Inc(SpaceCnt);
   If LastNonSpaceAbs > 0 Then
    EffW := TextWidth(Copy(ParaStr, VLines[L].CharStart,
                            LastNonSpaceAbs - VLines[L].CharStart + 1))
   Else
    EffW := 0;
   Slack := AvailW - EffW;
   If (SpaceCnt > 0) And (Slack > 0) Then Begin
    PerSpace  := Slack Div SpaceCnt;
    Remainder := Slack Mod SpaceCnt;
    SpacesSeen := 0;
    Limit := VLines[L].CharStart + Off - 1;
    For I := VLines[L].CharStart To Limit Do
     If (I >= 1) And (I <= Length(ParaStr)) And (I < LastNonSpaceAbs) Then
      If ParaStr[I] = ' ' Then Begin
       Inc(SpacesSeen);
       Inc(Extra, PerSpace);
       If SpacesSeen <= Remainder Then Inc(Extra);
      End;
   End;
  End;
 End;
 LineCharScreenX := VLines[L].X + TextWidth(Sub) + Extra;
End;

{ ----- Helpers selection -------------------------------------- }

Function SelHasRange: Boolean;
Begin
 SelHasRange := Sel.Active And
                ((Sel.AnchorPara <> Cursor.ParaIdx) Or
                 (Sel.AnchorChar <> Cursor.CharIdx));
End;

Procedure SelClear;
Begin
 Sel.Active := False;
End;

Procedure SelStartFromCursor;
Begin
 Sel.Active := True;
 Sel.AnchorPara := Cursor.ParaIdx;
 Sel.AnchorChar := Cursor.CharIdx;
End;

Procedure SelGetRange(Var P1, C1, P2, C2: Integer);
Var Swap: Boolean;
Begin
 P1 := Sel.AnchorPara; C1 := Sel.AnchorChar;
 P2 := Cursor.ParaIdx; C2 := Cursor.CharIdx;
 Swap := False;
 If P1 > P2 Then Swap := True
 Else If (P1 = P2) And (C1 > C2) Then Swap := True;
 If Swap Then Begin
  P1 := Cursor.ParaIdx; C1 := Cursor.CharIdx;
  P2 := Sel.AnchorPara; C2 := Sel.AnchorChar;
 End;
End;

{ ----- Helpers justification (Phase 4) ------------------------- }

Function VLineIsLastInPara(L: Integer): Boolean;
Begin
 If L >= VLineCount Then VLineIsLastInPara := True
 Else VLineIsLastInPara := VLines[L+1].ParaIdx <> VLines[L].ParaIdx;
End;

Function VLineSpaceCount(L: Integer): Integer;
Var I, N: Integer; ParaStr: String;
Begin
 N := 0;
 ParaStr := ParaText(VLines[L].ParaIdx);
 For I := VLines[L].CharStart To VLines[L].CharStart + VLines[L].CharLen - 1 Do
  If (I >= 1) And (I <= Length(ParaStr)) Then
   If ParaStr[I] = ' ' Then Inc(N);
 VLineSpaceCount := N;
End;

{ Statistiques pour la justification : exclut les espaces terminaux
  de la ligne (sinon, le slack se deverse sur l'espace de fin de ligne
  consomme par le wrap, ce qui rend l'expansion invisible).
  - InterSpaceCnt : nombre d'espaces ENTRE mots (non-terminaux).
  - EffWidth      : largeur pixel de la ligne sans les espaces terminaux.
  - LastVisOff    : offset 1-based dans la ligne du dernier caractere
                    non-espace (0 si la ligne ne contient que des espaces).
  Pre-condition : SetTextStyle(DefaultFont, ...) deja actif. }
Procedure VLineJustifyStats(L: Integer;
                            Var InterSpaceCnt, EffWidth,
                                LastVisOff: Integer);
Var
 I, Idx, LastNonSpace, Cnt : Integer;
 ParaStr                   : String;
Begin
 ParaStr := ParaText(VLines[L].ParaIdx);
 LastNonSpace := 0;
 For I := 1 To VLines[L].CharLen Do Begin
  Idx := VLines[L].CharStart + I - 1;
  If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
   If ParaStr[Idx] <> ' ' Then LastNonSpace := I;
 End;
 LastVisOff := LastNonSpace;
 Cnt := 0;
 If LastNonSpace > 1 Then
  For I := 1 To LastNonSpace - 1 Do Begin
   Idx := VLines[L].CharStart + I - 1;
   If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
    If ParaStr[Idx] = ' ' Then Inc(Cnt);
  End;
 InterSpaceCnt := Cnt;
 If LastNonSpace > 0 Then
  EffWidth := TextWidth(Copy(ParaStr, VLines[L].CharStart, LastNonSpace))
 Else
  EffWidth := 0;
End;

{ Retourne True si la ligne L doit ?tre justifi?e ; renseigne Slack et
  SpaceCnt. Slack = pixels ? r?partir entre les espaces inter-mots.
  SpaceCnt exclut les espaces terminaux. }
Function LineNeedsJustify(L: Integer; Var Slack, SpaceCnt: Integer): Boolean;
Var AvailW, EffW, LastVis: Integer;
Begin
 LineNeedsJustify := False;
 Slack := 0; SpaceCnt := 0;
 If VLines[L].Alignment <> ALIGN_JUSTIFY Then Exit;
 If VLineIsLastInPara(L) Then Exit;
 AvailW := PAGE_W - PAGE_MARGIN_L - PAGE_MARGIN_R;
 VLineJustifyStats(L, SpaceCnt, EffW, LastVis);
 If SpaceCnt = 0 Then Exit;
 Slack := AvailW - EffW;
 If Slack <= 0 Then Begin Slack := 0; Exit; End;
 LineNeedsJustify := True;
End;

{ Pixels extras ajout?s avant le caract?re ? l'offset OffInLine
  (0..CharLen). Pour usage par CursorScreenX en mode justify.
  Les espaces terminaux ne recoivent PAS d'extra. }
Function CursorJustifyExtra(L, OffInLine, Slack, SpaceCnt: Integer): Integer;
Var
 I, Limit, SpacesSeen, PerSpace, Remainder, Extra : Integer;
 LastVisAbs                                       : Integer;
 EffWDummy, InterDummy, LastVis                   : Integer;
 ParaStr                                          : String;
Begin
 If (Slack <= 0) Or (SpaceCnt <= 0) Then Begin
  CursorJustifyExtra := 0; Exit;
 End;
 PerSpace  := Slack Div SpaceCnt;
 Remainder := Slack Mod SpaceCnt;
 ParaStr := ParaText(VLines[L].ParaIdx);
 VLineJustifyStats(L, InterDummy, EffWDummy, LastVis);
 LastVisAbs := VLines[L].CharStart + LastVis - 1;  { 1-based dans Para }
 SpacesSeen := 0; Extra := 0;
 Limit := VLines[L].CharStart + OffInLine - 1;
 For I := VLines[L].CharStart To Limit Do Begin
  If (I >= 1) And (I <= Length(ParaStr)) And (I < LastVisAbs) Then
   If ParaStr[I] = ' ' Then Begin
    Inc(SpacesSeen);
    Inc(Extra, PerSpace);
    If SpacesSeen <= Remainder Then Inc(Extra);
   End;
 End;
 CursorJustifyExtra := Extra;
End;

{ ----- Rendu texte du document --------------------------------- }

Procedure RenderDocText;
Var
 I, ScreenY, ScreenX  : Integer;
 LineL, LineR         : Integer;
 Acc, K, RunStart, RunEnd : Integer;
 SegStart, SegEnd, SegLen : Integer;
 RunLen, SegW             : Integer;
 P, RC                    : Integer;
 Sub, OneCh               : String;
 Sty                      : TCharStyle;
 Slack, SpaceCnt          : Integer;
 PerSpace, Remainder      : Integer;
 Justify                  : Boolean;
 SegOff, J                : Integer;
 SpacesSeen, ExtraThis    : Integer;
 SegStartX, CharW         : Integer;
 IxImg, IyImg             : Integer;
 IW, IH                   : Integer;
 PB                       : ^Byte;
 LineLastNSAbs, LastVisOff : Integer;
Begin
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 1 To VLineCount Do Begin
  ScreenY := VLines[I].Y - ScrollY;
  If (ScreenY + VLines[I].Height < DOCAREA_TOP) Or
     (ScreenY > DOCAREA_BOTTOM) Then Continue;

  { Image line ? }
  If VLines[I].IsImage Then Begin
   P := VLines[I].ParaIdx;
   IW := Doc.Paragraphs[P].ImgW;
   IH := Doc.Paragraphs[P].ImgH;
   If (Doc.Paragraphs[P].ImgData = Nil) Or (IW <= 0) Or (IH <= 0) Then Continue;
   PB := Doc.Paragraphs[P].ImgData;
   For IyImg := 0 To IH-1 Do Begin
    If (ScreenY + IyImg < DOCAREA_TOP) Or
       (ScreenY + IyImg > DOCAREA_BOTTOM) Then Begin
     Inc(PB, IW);
     Continue;
    End;
    For IxImg := 0 To IW-1 Do Begin
     PutPixel(VLines[I].X + IxImg, ScreenY + IyImg, PB^ And 15);
     Inc(PB);
    End;
   End;
   Continue;
  End;

  If VLines[I].CharLen = 0 Then Continue;
  If (ScreenY < DOCAREA_TOP) Or
     (ScreenY + LINE_HEIGHT - 1 > DOCAREA_BOTTOM) Then Continue;

  P := VLines[I].ParaIdx;
  RC := Doc.Paragraphs[P].RunCount;
  LineL := VLines[I].CharStart - 1;
  LineR := LineL + VLines[I].CharLen;
  ScreenX := VLines[I].X;
  Acc := 0;

  Justify := LineNeedsJustify(I, Slack, SpaceCnt);
  If Justify Then Begin
   PerSpace  := Slack Div SpaceCnt;
   Remainder := Slack Mod SpaceCnt;
   { Position 1-based dans le paragraphe du dernier non-espace de la ligne :
     les espaces strictement au-dela ne recoivent PAS de pixels extras. }
   VLineJustifyStats(I, J, SegW, LastVisOff);
   LineLastNSAbs := VLines[I].CharStart + LastVisOff - 1;
  End Else Begin
   PerSpace := 0; Remainder := 0;
   LineLastNSAbs := MaxInt;
  End;
  SpacesSeen := 0;

  For K := 1 To RC Do Begin
   RunLen   := Length(Doc.Paragraphs[P].Runs[K].Text);
   RunStart := Acc;
   RunEnd   := Acc + RunLen;
   Inc(Acc, RunLen);
   SegStart := RunStart; If LineL > SegStart Then SegStart := LineL;
   SegEnd   := RunEnd;   If LineR < SegEnd   Then SegEnd   := LineR;
   If SegStart >= SegEnd Then Continue;
   SegLen := SegEnd - SegStart;
   Sub := Copy(Doc.Paragraphs[P].Runs[K].Text,
               SegStart - RunStart + 1, SegLen);
   Sty := Doc.Paragraphs[P].Runs[K].Style;
   ApplyRunStyle(Sty);

   If Not Justify Then Begin
    DrawStyledText(ScreenX, ScreenY, Sub, Sty);
    SegW := TextWidth(Sub);
    If (Sty.Style And STY_UNDERLINE) <> 0 Then Begin
     SetColor(Sty.Color);
     Line(ScreenX, ScreenY + LINE_HEIGHT - 2,
          ScreenX + SegW - 1, ScreenY + LINE_HEIGHT - 2);
    End;
    Inc(ScreenX, SegW);
    If (Sty.Style And STY_BOLD) <> 0 Then Inc(ScreenX);
   End Else Begin
    { Justifi? : rendu char par char avec extras sur espaces. }
    SegStartX := ScreenX;
    For SegOff := 1 To SegLen Do Begin
     OneCh := Copy(Sub, SegOff, 1);
     DrawStyledText(ScreenX, ScreenY, OneCh, Sty);
     CharW := TextWidth(OneCh);
     ExtraThis := 0;
     If OneCh[1] = ' ' Then Begin
      { (SegStart + SegOff) = position 1-based dans le para de ce char.
        Espaces terminaux : pas d'extra (sinon poussent rien et le slack
        est gaspille sur l'espace de fin de ligne). }
      If (SegStart + SegOff) < LineLastNSAbs Then Begin
       Inc(SpacesSeen);
       ExtraThis := PerSpace;
       If SpacesSeen <= Remainder Then Inc(ExtraThis);
      End;
     End;
     Inc(ScreenX, CharW + ExtraThis);
     If (Sty.Style And STY_BOLD) <> 0 Then Inc(ScreenX);
    End;
    If (Sty.Style And STY_UNDERLINE) <> 0 Then Begin
     SetColor(Sty.Color);
     Line(SegStartX, ScreenY + LINE_HEIGHT - 2,
          ScreenX - 1, ScreenY + LINE_HEIGHT - 2);
    End;
    { Pas d'incr?ment ScreenX r?siduel : d?j? mis ? jour char par char. }
    J := 0;     { dummy: silence "unused J" }
    If J <> 0 Then ;
   End;
  End;
 End;
 SetColor(Black);
End;

Procedure RenderTextCursor;
Var L, X, Y: Integer;
Begin
 If VLineCount = 0 Then Exit;
 If Not CursorBlinkOn Then Exit;
 If ActiveMenu > 0 Then Exit;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 X := CursorScreenX(L);
 Y := VLines[L].Y - ScrollY;
 If (Y < DOCAREA_TOP) Or (Y + LINE_HEIGHT > DOCAREA_BOTTOM) Then Exit;
 SetColor(Black);
 Line(X, Y, X, Y + LINE_HEIGHT - 2);
End;

{ Rendu de la selection : inversion video (XOR avec blanc) sur les
  portions de chaque ligne visuelle couvertes par [P1,C1]..[P2,C2]. }
Procedure RenderSelection;
Var
 P1, C1, P2, C2, I    : Integer;
 LineL, LineR         : Integer;
 SegL, SegR           : Integer;
 X1, X2, Y, YY        : Integer;
Begin
 If Not Sel.Active Then Exit;
 SelGetRange(P1, C1, P2, C2);
 If (P1 = P2) And (C1 = C2) Then Exit;
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 1 To VLineCount Do Begin
  If VLines[I].IsImage Then Continue;
  If (VLines[I].ParaIdx < P1) Or (VLines[I].ParaIdx > P2) Then Continue;
  LineL := VLines[I].CharStart - 1;
  LineR := LineL + VLines[I].CharLen;
  If VLines[I].ParaIdx = P1 Then Begin
   SegL := C1; If SegL < LineL Then SegL := LineL;
  End Else SegL := LineL;
  If VLines[I].ParaIdx = P2 Then Begin
   SegR := C2; If SegR > LineR Then SegR := LineR;
  End Else SegR := LineR;
  If SegR <= SegL Then Continue;
  X1 := LineCharScreenX(I, SegL);
  X2 := LineCharScreenX(I, SegR);
  If X2 <= X1 Then Continue;
  Y := VLines[I].Y - ScrollY;
  If (Y + LINE_HEIGHT - 1 < DOCAREA_TOP) Or (Y > DOCAREA_BOTTOM) Then Continue;
  SetWriteMode(XORPut);
  SetColor(White);
  For YY := Y To Y + LINE_HEIGHT - 1 Do
   Line(X1, YY, X2 - 1, YY);
  SetWriteMode(NormalPut);
 End;
 SetColor(Black);
End;

{ Bascule (XOR) le caret texte sans repeindre tout l'ecran. }
Procedure ToggleTextCursor;
Var L, X, Y: Integer;
Begin
 If VLineCount = 0 Then Exit;
 If ActiveMenu > 0 Then Exit;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 X := CursorScreenX(L);
 Y := VLines[L].Y - ScrollY;
 If (Y < DOCAREA_TOP) Or (Y + LINE_HEIGHT > DOCAREA_BOTTOM) Then Exit;
 {$IFDEF FPC} EraseSoftCursor; {$ENDIF}
 SetWriteMode(XORPut);
 SetColor(White);
 Line(X, Y, X, Y + LINE_HEIGHT - 2);
 SetWriteMode(NormalPut);
 {$IFDEF FPC} DrawSoftCursor(MsX, MsY); {$ENDIF}
End;

{ ----- Suivi curseur : auto-scroll + page courante ------------- }

Procedure EnsureCursorVisible;
Var L, ScreenY: Integer;
Begin
 If VLineCount = 0 Then Exit;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 CurrentPage := VLines[L].PageIdx;
 ScreenY := VLines[L].Y - ScrollY;
 If ScreenY < DOCAREA_TOP + 4 Then
  ScrollY := VLines[L].Y - DOCAREA_TOP - 4;
 If ScreenY + LINE_HEIGHT > DOCAREA_BOTTOM - 4 Then
  ScrollY := VLines[L].Y + LINE_HEIGHT - DOCAREA_BOTTOM + 4;
 If ScrollY < 0 Then ScrollY := 0;
End;

{ ----- Edition de texte (Phase 3 : multi-run) ----------------- }

Procedure InsertCharAtCursor(Ch: Char);
Var
 P, RIdx, ROff       : Integer;
 Tail                : String;
 ParaLen             : Integer;
 Sty                 : TCharStyle;
Begin
 P := Cursor.ParaIdx;
 ParaLen := Length(ParaText(P));
 If ParaLen >= MAX_TEXT_LEN Then Exit;
 Sty := CurrentStyle;

 { Cas paragraphe vide }
 If Doc.Paragraphs[P].RunCount = 0 Then Begin
  Doc.Paragraphs[P].RunCount := 1;
  Doc.Paragraphs[P].Runs[1].Style := Sty;
  Doc.Paragraphs[P].Runs[1].Text  := Ch;
  Inc(Cursor.CharIdx);
  Doc.Modified  := True;
  NeedsRelayout := True;
  Exit;
 End;

 LocateInsertion(P, Cursor.CharIdx, RIdx, ROff);

 { Run cible m?me style ? ins?rer dedans. }
 If StyleEq(Doc.Paragraphs[P].Runs[RIdx].Style, Sty) Then Begin
  Insert(Ch, Doc.Paragraphs[P].Runs[RIdx].Text, ROff + 1);
 End
 { Bord gauche d'un run, run pr?c?dent m?me style ? append. }
 Else If (ROff = 0) And (RIdx > 1) And
         StyleEq(Doc.Paragraphs[P].Runs[RIdx-1].Style, Sty) Then Begin
  Doc.Paragraphs[P].Runs[RIdx-1].Text :=
   Doc.Paragraphs[P].Runs[RIdx-1].Text + Ch;
 End
 { Bord droit d'un run, run suivant m?me style ? prepend. }
 Else If (ROff = Length(Doc.Paragraphs[P].Runs[RIdx].Text)) And
         (RIdx < Doc.Paragraphs[P].RunCount) And
         StyleEq(Doc.Paragraphs[P].Runs[RIdx+1].Style, Sty) Then Begin
  Insert(Ch, Doc.Paragraphs[P].Runs[RIdx+1].Text, 1);
 End
 { Insertion ? un bord : nouveau run. }
 Else If ROff = 0 Then Begin
  If Not InsertRunAt(P, RIdx) Then Exit;
  Doc.Paragraphs[P].Runs[RIdx].Style := Sty;
  Doc.Paragraphs[P].Runs[RIdx].Text  := Ch;
 End
 Else If ROff = Length(Doc.Paragraphs[P].Runs[RIdx].Text) Then Begin
  If Not InsertRunAt(P, RIdx + 1) Then Exit;
  Doc.Paragraphs[P].Runs[RIdx+1].Style := Sty;
  Doc.Paragraphs[P].Runs[RIdx+1].Text  := Ch;
 End
 { Splittage du run au milieu : tail puis nouveau run. }
 Else Begin
  If Doc.Paragraphs[P].RunCount + 2 > MAX_RUNS_PER_PARA Then Exit;
  Tail := Copy(Doc.Paragraphs[P].Runs[RIdx].Text,
               ROff + 1, Length(Doc.Paragraphs[P].Runs[RIdx].Text) - ROff);
  Doc.Paragraphs[P].Runs[RIdx].Text :=
   Copy(Doc.Paragraphs[P].Runs[RIdx].Text, 1, ROff);
  If Not InsertRunAt(P, RIdx + 1) Then Exit;
  Doc.Paragraphs[P].Runs[RIdx+1].Style := Sty;
  Doc.Paragraphs[P].Runs[RIdx+1].Text  := Ch;
  If Not InsertRunAt(P, RIdx + 2) Then Exit;
  Doc.Paragraphs[P].Runs[RIdx+2].Style := Doc.Paragraphs[P].Runs[RIdx].Style;
  Doc.Paragraphs[P].Runs[RIdx+2].Text  := Tail;
 End;

 Inc(Cursor.CharIdx);
 Doc.Modified  := True;
 NeedsRelayout := True;
End;

Procedure BackspaceAtCursor;
Var
 P, RIdx, ROff, I    : Integer;
 LastRun             : Integer;
 ParaLenPrev         : Integer;
Begin
 P := Cursor.ParaIdx;
 If Cursor.CharIdx > 0 Then Begin
  LocateChar(P, Cursor.CharIdx - 1, RIdx, ROff);
  Delete(Doc.Paragraphs[P].Runs[RIdx].Text, ROff + 1, 1);
  If Length(Doc.Paragraphs[P].Runs[RIdx].Text) = 0 Then
   RemoveRunAt(P, RIdx);
  MergeAdjacentSameStyleRuns(P);
  Dec(Cursor.CharIdx);
  Doc.Modified  := True;
  NeedsRelayout := True;
 End Else If Cursor.ParaIdx > 1 Then Begin
  ParaLenPrev := Length(ParaText(Cursor.ParaIdx - 1));
  If ParaLenPrev + Length(ParaText(Cursor.ParaIdx)) > MAX_TEXT_LEN Then Exit;
  { Append runs du paragraphe courant ? la fin du pr?c?dent }
  LastRun := Doc.Paragraphs[Cursor.ParaIdx - 1].RunCount;
  For I := 1 To Doc.Paragraphs[Cursor.ParaIdx].RunCount Do Begin
   If LastRun >= MAX_RUNS_PER_PARA Then Break;
   Inc(LastRun);
   Doc.Paragraphs[Cursor.ParaIdx - 1].Runs[LastRun] :=
    Doc.Paragraphs[Cursor.ParaIdx].Runs[I];
  End;
  Doc.Paragraphs[Cursor.ParaIdx - 1].RunCount := LastRun;
  MergeAdjacentSameStyleRuns(Cursor.ParaIdx - 1);
  For I := Cursor.ParaIdx To Doc.ParaCount - 1 Do
   Doc.Paragraphs[I] := Doc.Paragraphs[I + 1];
  FillChar(Doc.Paragraphs[Doc.ParaCount], SizeOf(TParagraph), 0);
  Dec(Doc.ParaCount);
  Dec(Cursor.ParaIdx);
  Cursor.RunIdx  := 1;
  Cursor.CharIdx := ParaLenPrev;
  Doc.Modified   := True;
  NeedsRelayout  := True;
 End;
End;

Procedure DeleteAtCursor;
Var
 P, RIdx, ROff, I   : Integer;
 ParaLen, LastRun   : Integer;
Begin
 P := Cursor.ParaIdx;
 ParaLen := Length(ParaText(P));
 If Cursor.CharIdx < ParaLen Then Begin
  LocateChar(P, Cursor.CharIdx, RIdx, ROff);
  Delete(Doc.Paragraphs[P].Runs[RIdx].Text, ROff + 1, 1);
  If Length(Doc.Paragraphs[P].Runs[RIdx].Text) = 0 Then
   RemoveRunAt(P, RIdx);
  MergeAdjacentSameStyleRuns(P);
  Doc.Modified  := True;
  NeedsRelayout := True;
 End Else If Cursor.ParaIdx < Doc.ParaCount Then Begin
  If ParaLen + Length(ParaText(Cursor.ParaIdx + 1)) > MAX_TEXT_LEN Then Exit;
  LastRun := Doc.Paragraphs[P].RunCount;
  For I := 1 To Doc.Paragraphs[Cursor.ParaIdx + 1].RunCount Do Begin
   If LastRun >= MAX_RUNS_PER_PARA Then Break;
   Inc(LastRun);
   Doc.Paragraphs[P].Runs[LastRun] :=
    Doc.Paragraphs[Cursor.ParaIdx + 1].Runs[I];
  End;
  Doc.Paragraphs[P].RunCount := LastRun;
  MergeAdjacentSameStyleRuns(P);
  For I := Cursor.ParaIdx + 1 To Doc.ParaCount - 1 Do
   Doc.Paragraphs[I] := Doc.Paragraphs[I + 1];
  FillChar(Doc.Paragraphs[Doc.ParaCount], SizeOf(TParagraph), 0);
  Dec(Doc.ParaCount);
  Doc.Modified  := True;
  NeedsRelayout := True;
 End;
End;

Procedure NewParagraphAtCursor;
Var
 P, RIdx, ROff, NewIdx, I, K : Integer;
 Tail                        : String;
 OldRunCount                 : Integer;
Begin
 If Doc.ParaCount >= MAX_PARAS_PER_DOC Then Exit;
 P := Cursor.ParaIdx;
 NewIdx := P + 1;
 For I := Doc.ParaCount Downto NewIdx Do
  Doc.Paragraphs[I + 1] := Doc.Paragraphs[I];
 Inc(Doc.ParaCount);
 FillChar(Doc.Paragraphs[NewIdx], SizeOf(TParagraph), 0);
 Doc.Paragraphs[NewIdx].Alignment := Doc.Paragraphs[P].Alignment;
 Doc.Paragraphs[NewIdx].RunCount  := 0;

 { Localise dans le paragraphe courant. }
 LocateInsertion(P, Cursor.CharIdx, RIdx, ROff);
 OldRunCount := Doc.Paragraphs[P].RunCount;

 { Cas tail = vide (curseur en fin de para) }
 If (RIdx = OldRunCount) And
    (ROff = Length(Doc.Paragraphs[P].Runs[OldRunCount].Text)) Then Begin
  { Nouveau paragraphe vide avec style courant. }
  Doc.Paragraphs[NewIdx].RunCount := 1;
  Doc.Paragraphs[NewIdx].Runs[1].Style := CurrentStyle;
  Doc.Paragraphs[NewIdx].Runs[1].Text  := '';
 End Else Begin
  { Split run RIdx en head/tail. Head reste dans P, tail va dans NewIdx. }
  Tail := Copy(Doc.Paragraphs[P].Runs[RIdx].Text,
               ROff + 1, Length(Doc.Paragraphs[P].Runs[RIdx].Text) - ROff);
  Doc.Paragraphs[P].Runs[RIdx].Text :=
   Copy(Doc.Paragraphs[P].Runs[RIdx].Text, 1, ROff);

  K := 0;
  If Length(Tail) > 0 Then Begin
   Inc(K);
   Doc.Paragraphs[NewIdx].Runs[K].Style := Doc.Paragraphs[P].Runs[RIdx].Style;
   Doc.Paragraphs[NewIdx].Runs[K].Text  := Tail;
  End;
  For I := RIdx + 1 To OldRunCount Do Begin
   Inc(K);
   Doc.Paragraphs[NewIdx].Runs[K] := Doc.Paragraphs[P].Runs[I];
  End;
  Doc.Paragraphs[NewIdx].RunCount := K;
  { Tronque P apr?s le run head. Si head vide et qu'il y a d'autres runs,
    enlever ce run vide. }
  Doc.Paragraphs[P].RunCount := RIdx;
  If (Length(Doc.Paragraphs[P].Runs[RIdx].Text) = 0) And (RIdx > 1) Then
   RemoveRunAt(P, RIdx);
  If Doc.Paragraphs[NewIdx].RunCount = 0 Then Begin
   Doc.Paragraphs[NewIdx].RunCount := 1;
   Doc.Paragraphs[NewIdx].Runs[1].Style := CurrentStyle;
   Doc.Paragraphs[NewIdx].Runs[1].Text  := '';
  End;
 End;

 { Nettoyage runs vides flottants dans P. }
 If Doc.Paragraphs[P].RunCount = 0 Then Begin
  Doc.Paragraphs[P].RunCount := 1;
  Doc.Paragraphs[P].Runs[1].Style := CurrentStyle;
  Doc.Paragraphs[P].Runs[1].Text  := '';
 End;

 Cursor.ParaIdx := NewIdx;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 Doc.Modified   := True;
 NeedsRelayout  := True;
End;

{ ----- Navigation curseur ------------------------------------- }

Procedure CursorMoveLeft;
Begin
 If Cursor.CharIdx > 0 Then Dec(Cursor.CharIdx)
 Else If Cursor.ParaIdx > 1 Then Begin
  Dec(Cursor.ParaIdx);
  Cursor.RunIdx := 1;
  Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
 End;
End;

Procedure CursorMoveRight;
Var L: Integer;
Begin
 L := Length(ParaText(Cursor.ParaIdx));
 If Cursor.CharIdx < L Then Inc(Cursor.CharIdx)
 Else If Cursor.ParaIdx < Doc.ParaCount Then Begin
  Inc(Cursor.ParaIdx);
  Cursor.RunIdx := 1;
  Cursor.CharIdx := 0;
 End;
End;

Procedure CursorMoveHome;
Var L: Integer;
Begin
 L := FindCursorVLine;
 If L > 0 Then
  Cursor.CharIdx := VLines[L].CharStart - 1
 Else
  Cursor.CharIdx := 0;
End;

Procedure CursorMoveEnd;
Var L: Integer;
Begin
 L := FindCursorVLine;
 If L > 0 Then
  Cursor.CharIdx := VLines[L].CharStart + VLines[L].CharLen - 1
 Else
  Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
End;

Procedure CursorVerticalMove(Delta: Integer);
Var
 L, NL, Off, BestOff, BestDist, D : Integer;
 TargetX, TestX                   : Integer;
 ParaStr, Pre                     : String;
Begin
 L := FindCursorVLine;
 If L = 0 Then Exit;
 NL := L + Delta;
 If (NL < 1) Or (NL > VLineCount) Then Exit;
 SetTextStyle(DefaultFont, HorizDir, 1);
 TargetX := CursorScreenX(L);
 ParaStr := ParaText(VLines[NL].ParaIdx);
 BestOff := 0;
 BestDist := 32767;
 For Off := 0 To VLines[NL].CharLen Do Begin
  Pre := Copy(ParaStr, VLines[NL].CharStart, Off);
  TestX := VLines[NL].X + TextWidth(Pre);
  D := TestX - TargetX;
  If D < 0 Then D := -D;
  If D < BestDist Then Begin
   BestDist := D;
   BestOff := Off;
  End;
 End;
 Cursor.ParaIdx := VLines[NL].ParaIdx;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := VLines[NL].CharStart - 1 + BestOff;
End;

Procedure CursorPageUp;
Var I: Integer;
Begin
 For I := 1 To 18 Do CursorVerticalMove(-1);
End;

Procedure CursorPageDown;
Var I: Integer;
Begin
 For I := 1 To 18 Do CursorVerticalMove(1);
End;

Procedure CursorDocStart;
Begin
 Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
End;

Procedure CursorDocEnd;
Begin
 Cursor.ParaIdx := Doc.ParaCount;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
End;

{ ============================================================ }
{ ===================  PHASE 6 - IMAGES  ===================== }
{ ============================================================ }

Const VGA_RGB : Array[0..15, 0..2] Of Byte =
 ((  0,  0,  0),(  0,  0,170),(  0,170,  0),(  0,170,170),
  (170,  0,  0),(170,  0,170),(170, 85,  0),(170,170,170),
  ( 85, 85, 85),( 85, 85,255),( 85,255, 85),( 85,255,255),
  (255, 85, 85),(255, 85,255),(255,255, 85),(255,255,255));

Function NearestVGA(R, G, B: Byte): Byte;
Var
 I, BestI    : Integer;
 D, BestD    : LongInt;
 DR, DG, DB  : LongInt;
Begin
 BestI := 0; BestD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - VGA_RGB[I,0];
  DG := LongInt(G) - VGA_RGB[I,1];
  DB := LongInt(B) - VGA_RGB[I,2];
  D  := DR*DR + DG*DG + DB*DB;
  If D < BestD Then Begin BestD := D; BestI := I; End;
 End;
 NearestVGA := BestI;
End;

Procedure FreeParaImage(Var Pp: TParagraph);
Begin
 If Pp.ImgData <> Nil Then Begin
  FreeMem(Pp.ImgData, Pp.ImgW * Pp.ImgH);
  Pp.ImgData := Nil;
 End;
 Pp.IsImage := False;
 Pp.ImgW := 0; Pp.ImgH := 0;
End;

Procedure FreeAllDocImages;
Var I: Integer;
Begin
 For I := 1 To Doc.ParaCount Do
  If Doc.Paragraphs[I].IsImage Then
   FreeParaImage(Doc.Paragraphs[I]);
End;

{ Nearest-neighbor downscale + copie. Source toujours liber? par appelant. }
Procedure ScaleImageNN(Src: Pointer; SW, SH: Integer;
                       Var Dst: Pointer; Var DW, DH: Integer);
Var
 Sx, Sy : Integer;
 PSrc, PDst, SrcRow : ^Byte;
 X, Y   : Integer;
Begin
 If (SW <= MAX_IMG_W) And (SH <= MAX_IMG_H) Then Begin
  GetMem(Dst, SW*SH);
  Move(Src^, Dst^, SW*SH);
  DW := SW; DH := SH; Exit;
 End;
 If LongInt(SW) * MAX_IMG_H > LongInt(SH) * MAX_IMG_W Then Begin
  DW := MAX_IMG_W;
  DH := (LongInt(SH) * MAX_IMG_W) Div SW;
  If DH < 1 Then DH := 1;
 End Else Begin
  DH := MAX_IMG_H;
  DW := (LongInt(SW) * MAX_IMG_H) Div SH;
  If DW < 1 Then DW := 1;
 End;
 GetMem(Dst, DW*DH);
 PDst := Dst;
 For Y := 0 To DH-1 Do Begin
  Sy := (LongInt(Y) * SH) Div DH;
  SrcRow := Src; Inc(SrcRow, LongInt(Sy) * SW);
  For X := 0 To DW-1 Do Begin
   Sx := (LongInt(X) * SW) Div DW;
   PSrc := SrcRow; Inc(PSrc, Sx);
   PDst^ := PSrc^;
   Inc(PDst);
  End;
 End;
End;

Function LoadBMP(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F                         : File;
 BFType                    : Array[1..2] Of Char;
 BFSize, BFRsv, BFOffBits  : LongInt;
 BISize, BIWidth, BIHeight : LongInt;
 BIPlanes, BIBitCount      : Word;
 BICompression, BISizeImg  : LongInt;
 BIXP, BIYP, BIClrUsed,
 BIClrImp                  : LongInt;
 PalCnt, PalI              : Integer;
 PalIdx                    : Array[0..255] Of Byte;
 RowBytes                  : LongInt;
 X, Y, IW, IH              : Integer;
 RowBuf                    : Array[0..2047] Of Byte;
 RowDst                    : ^Byte;
 R, G, BC, B0, B1          : Byte;
 PalEntry                  : Array[0..3] Of Byte;
Begin
 Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin LoadBMP := False; Exit; End;
 BlockRead(F, BFType, 2);
 If (BFType[1]<>'B') Or (BFType[2]<>'M') Then Begin
  Close(F); LoadBMP := False; Exit;
 End;
 BlockRead(F, BFSize, 4);
 BlockRead(F, BFRsv, 4);
 BlockRead(F, BFOffBits, 4);
 BlockRead(F, BISize, 4);
 If BISize < 40 Then Begin Close(F); LoadBMP := False; Exit; End;
 BlockRead(F, BIWidth, 4);
 BlockRead(F, BIHeight, 4);
 BlockRead(F, BIPlanes, 2);
 BlockRead(F, BIBitCount, 2);
 BlockRead(F, BICompression, 4);
 BlockRead(F, BISizeImg, 4);
 BlockRead(F, BIXP, 4);
 BlockRead(F, BIYP, 4);
 BlockRead(F, BIClrUsed, 4);
 BlockRead(F, BIClrImp, 4);
 If BISize > 40 Then Seek(F, 14 + BISize);
 If BICompression <> 0 Then Begin Close(F); LoadBMP := False; Exit; End;
 If (BIBitCount <> 4) And (BIBitCount <> 8) And (BIBitCount <> 24) Then Begin
  Close(F); LoadBMP := False; Exit;
 End;
 IW := BIWidth; IH := BIHeight;
 If IH < 0 Then IH := -IH;
 If (IW <= 0) Or (IH <= 0) Or (IW > 4096) Or (IH > 4096) Then Begin
  Close(F); LoadBMP := False; Exit;
 End;
 If BIBitCount <= 8 Then Begin
  PalCnt := BIClrUsed;
  If PalCnt = 0 Then PalCnt := 1 Shl BIBitCount;
  If PalCnt > 256 Then PalCnt := 256;
  For PalI := 0 To PalCnt-1 Do Begin
   BlockRead(F, PalEntry, 4);
   PalIdx[PalI] := NearestVGA(PalEntry[2], PalEntry[1], PalEntry[0]);
  End;
 End;
 Seek(F, BFOffBits);
 RowBytes := ((LongInt(IW) * BIBitCount + 31) Shr 3) And $FFFFFFFC;
 If RowBytes > 2048 Then Begin Close(F); LoadBMP := False; Exit; End;
 GetMem(Buf, IW * IH);
 For Y := 0 To IH-1 Do Begin
  BlockRead(F, RowBuf, RowBytes);
  RowDst := Buf;
  If BIHeight < 0 Then Inc(RowDst, LongInt(Y) * IW)
  Else                Inc(RowDst, LongInt(IH - 1 - Y) * IW);
  Case BIBitCount Of
   4: For X := 0 To IW-1 Do Begin
       B0 := RowBuf[X Shr 1];
       If (X And 1) = 0 Then B1 := B0 Shr 4 Else B1 := B0 And $0F;
       RowDst^ := PalIdx[B1]; Inc(RowDst);
      End;
   8: For X := 0 To IW-1 Do Begin
       RowDst^ := PalIdx[RowBuf[X]]; Inc(RowDst);
      End;
   24: For X := 0 To IW-1 Do Begin
        BC := RowBuf[X*3+0]; G := RowBuf[X*3+1]; R := RowBuf[X*3+2];
        RowDst^ := NearestVGA(R, G, BC); Inc(RowDst);
       End;
  End;
 End;
 Close(F);
 W := IW; H := IH;
 LoadBMP := True;
End;

Function LoadPCX(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F                  : File;
 Hdr                : Array[0..127] Of Byte;
 Encoding, BitsPerPx, NPlanes : Byte;
 BytesPerLine       : Word;
 Xmin,Ymin,Xmax,Ymax: Word;
 IW, IH             : Integer;
 Y, X, P            : Integer;
 ScanLine           : Array[0..4095] Of Byte;
 ScanIdx, TotalScan : Integer;
 RowDst             : ^Byte;
 ReadByte, Run      : Byte;
 Cnt, I             : Integer;
 PalIdx             : Array[0..255] Of Byte;
 BB                 : Byte;
 FSize              : LongInt;
 Pal256             : Array[0..767] Of Byte;
 Mask               : Byte;
Begin
 Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin LoadPCX := False; Exit; End;
 BlockRead(F, Hdr, 128);
 If Hdr[0] <> 10 Then Begin Close(F); LoadPCX := False; Exit; End;
 Encoding     := Hdr[2];
 BitsPerPx    := Hdr[3];
 Xmin := Hdr[4]  Or (Word(Hdr[5])  Shl 8);
 Ymin := Hdr[6]  Or (Word(Hdr[7])  Shl 8);
 Xmax := Hdr[8]  Or (Word(Hdr[9])  Shl 8);
 Ymax := Hdr[10] Or (Word(Hdr[11]) Shl 8);
 NPlanes      := Hdr[65];
 BytesPerLine := Hdr[66] Or (Word(Hdr[67]) Shl 8);
 IW := Xmax - Xmin + 1;
 IH := Ymax - Ymin + 1;
 If (Encoding <> 1) Or (IW <= 0) Or (IH <= 0) Or
    (IW > 4096) Or (IH > 4096) Or
    (LongInt(NPlanes) * BytesPerLine > 4096) Then Begin
  Close(F); LoadPCX := False; Exit;
 End;
 If (BitsPerPx = 8) And (NPlanes = 1) Then Begin
  FSize := FileSize(F);
  Seek(F, FSize - 769);
  BlockRead(F, BB, 1);
  If BB = 12 Then Begin
   BlockRead(F, Pal256, 768);
   For I := 0 To 255 Do
    PalIdx[I] := NearestVGA(Pal256[I*3], Pal256[I*3+1], Pal256[I*3+2]);
  End Else
   For I := 0 To 255 Do PalIdx[I] := I And 15;
 End Else Begin
  For I := 0 To 15 Do
   PalIdx[I] := NearestVGA(Hdr[16+I*3], Hdr[16+I*3+1], Hdr[16+I*3+2]);
 End;
 Seek(F, 128);
 GetMem(Buf, IW * IH);
 TotalScan := LongInt(NPlanes) * BytesPerLine;
 For Y := 0 To IH-1 Do Begin
  ScanIdx := 0;
  While ScanIdx < TotalScan Do Begin
   BlockRead(F, ReadByte, 1);
   If (ReadByte And $C0) = $C0 Then Begin
    Cnt := ReadByte And $3F;
    BlockRead(F, Run, 1);
    For I := 1 To Cnt Do Begin
     If ScanIdx < TotalScan Then ScanLine[ScanIdx] := Run;
     Inc(ScanIdx);
    End;
   End Else Begin
    ScanLine[ScanIdx] := ReadByte;
    Inc(ScanIdx);
   End;
  End;
  RowDst := Buf;
  Inc(RowDst, LongInt(Y) * IW);
  Case BitsPerPx Of
   1: If NPlanes = 1 Then Begin
       For X := 0 To IW-1 Do Begin
        Mask := 1 Shl (7 - (X And 7));
        If (ScanLine[X Shr 3] And Mask) <> 0 Then RowDst^ := 15 Else RowDst^ := 0;
        Inc(RowDst);
       End;
      End Else Begin
       For X := 0 To IW-1 Do Begin
        Mask := 1 Shl (7 - (X And 7));
        BB := 0;
        For P := 0 To NPlanes-1 Do
         If (ScanLine[P*BytesPerLine + (X Shr 3)] And Mask) <> 0 Then
          BB := BB Or (1 Shl P);
        RowDst^ := PalIdx[BB];
        Inc(RowDst);
       End;
      End;
   4: For X := 0 To IW-1 Do Begin
       BB := ScanLine[X Shr 1];
       If (X And 1) = 0 Then BB := BB Shr 4 Else BB := BB And $0F;
       RowDst^ := PalIdx[BB];
       Inc(RowDst);
      End;
   8: If NPlanes = 1 Then Begin
       For X := 0 To IW-1 Do Begin
        RowDst^ := PalIdx[ScanLine[X]]; Inc(RowDst);
       End;
      End Else Begin
       Close(F); FreeMem(Buf, IW*IH); Buf := Nil; LoadPCX := False; Exit;
      End;
  Else
   Close(F); FreeMem(Buf, IW*IH); Buf := Nil; LoadPCX := False; Exit;
  End;
 End;
 Close(F);
 W := IW; H := IH;
 LoadPCX := True;
End;


{ ============================================================ }
{ ====  PHASE 11: IMAGE LOADERS BGX/XBM/TIFF/GIF/JPEG  ======= }
{ ============================================================ }

{ ----- Helpers communs ----- }

Function ImgPByteAt(P: Pointer; Ofs: LongInt): Byte;
Var Q: ^Byte;
Begin
 Q := P; Inc(Q, Ofs);
 ImgPByteAt := Q^;
End;

Procedure ImgPByteSet(P: Pointer; Ofs: LongInt; B: Byte);
Var Q: ^Byte;
Begin
 Q := P; Inc(Q, Ofs);
 Q^ := B;
End;

Function ImgUpcaseChar(C: Char): Char;
Begin
 If (C>='a') And (C<='z') Then ImgUpcaseChar := Char(Byte(C)-32)
 Else ImgUpcaseChar := C;
End;

Function ImgUpperStr(Const S: String): String;
Var R: String; I: Integer;
Begin
 R := S;
 For I := 1 To Length(R) Do R[I] := ImgUpcaseChar(R[I]);
 ImgUpperStr := R;
End;

{ Palette VGA 256 par defaut (BIOS) reduite a 16 via NearestVGA.
  Pour BGX nous prenons une approximation simple : 0..15 EGA standard,
  16..31 niveaux de gris, 32..255 plage colorée pondérée. }
Function BGXIdxToVGA(Idx: Byte): Byte;
Var R, G, B: Byte; J: Integer;
Begin
 If Idx < 16 Then Begin BGXIdxToVGA := Idx; Exit; End;
 If Idx < 32 Then Begin
  J := (Idx - 16) * 17;     { 0..255 niveaux de gris }
  BGXIdxToVGA := NearestVGA(J, J, J); Exit;
 End;
 { Indices 32..255 : cube 6x6x6 approx }
 J := Idx - 32;             { 0..223 }
 R := Byte((J Div 36) * 51);
 G := Byte(((J Div 6) Mod 6) * 51);
 B := Byte((J Mod 6) * 51);
 BGXIdxToVGA := NearestVGA(R, G, B);
End;

{ ------------------------------------------------------------ }
{ -------- BGX (signature 'BGX1' + W16 + H16 + 8bpp) --------- }
{ ------------------------------------------------------------ }

Function LoadBGX(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F        : File;
 Sig      : Array[0..3] Of Char;
 W16, H16 : Word;
 Bpp      : Byte;
 N        : LongInt;
 P        : ^Byte;
 I        : LongInt;
 BR       : LongInt;
Begin
 LoadBGX := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, Sig, 4, BR);
 If (BR<>4) Or (Sig[0]<>'B') Or (Sig[1]<>'G') Or
    (Sig[2]<>'X') Or (Sig[3]<>'1') Then Begin
  Close(F); Exit;
 End;
 BlockRead(F, W16, 2);
 BlockRead(F, H16, 2);
 BlockRead(F, Bpp, 1);
 If (Bpp<>8) Or (W16=0) Or (H16=0) Or (W16>4096) Or (H16>4096) Then Begin
  Close(F); Exit;
 End;
 N := LongInt(W16) * LongInt(H16);
 GetMem(Buf, N);
 BlockRead(F, Buf^, N, BR);
 Close(F);
 If BR < N Then Begin
  FreeMem(Buf, N); Buf := Nil; Exit;
 End;
 P := Buf;
 For I := 0 To N-1 Do Begin
  P^ := BGXIdxToVGA(P^);
  Inc(P);
 End;
 W := W16; H := H16;
 LoadBGX := True;
End;

{ ------------------------------------------------------------ }
{ ---------- XBM (texte C, monochrome, LSB-first) ------------ }
{ ------------------------------------------------------------ }

Function XBMExtractInt(Const S: String): LongInt;
Var I, J: Integer; V: LongInt;
Begin
 J := Length(S);
 While (J>0) And ((S[J]=' ') Or (S[J]=#9) Or (S[J]=#13)) Do Dec(J);
 I := J;
 While (I>1) And (S[I-1]>='0') And (S[I-1]<='9') Do Dec(I);
 V := 0;
 While (I<=J) And (S[I]>='0') And (S[I]<='9') Do Begin
  V := V*10 + (Byte(S[I]) - Byte('0'));
  Inc(I);
 End;
 XBMExtractInt := V;
End;

{ Lit un nombre 0xXX ou décimal a partir de Pos dans S, avance Pos }
Function XBMNextHexByte(Const S: String; Var P: Integer; Var V: LongInt): Boolean;
Var Base: Integer; D: Char; Found: Boolean;
Begin
 XBMNextHexByte := False; V := 0; Base := 10; Found := False;
 While P <= Length(S) Do Begin
  D := S[P];
  If (D='0') And (P<Length(S)) And ((S[P+1]='x') Or (S[P+1]='X')) Then Begin
   Base := 16; Inc(P, 2); Found := True; Break;
  End;
  If (D>='0') And (D<='9') Then Begin
   Found := True; Break;
  End;
  Inc(P);
 End;
 If Not Found Then Exit;
 While P <= Length(S) Do Begin
  D := S[P];
  If (D>='0') And (D<='9') Then V := V*Base + (Byte(D)-Byte('0'))
  Else If (Base=16) And (D>='a') And (D<='f') Then V := V*Base + (Byte(D)-Byte('a')+10)
  Else If (Base=16) And (D>='A') And (D<='F') Then V := V*Base + (Byte(D)-Byte('A')+10)
  Else Break;
  Inc(P);
 End;
 XBMNextHexByte := True;
End;

Function LoadXBM(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 T          : Text;
 Line, US   : String;
 BW, BH     : Integer;
 RowBytes   : Integer;
 TotalBytes : LongInt;
 BitsBuf    : Pointer;
 K          : LongInt;
 InData     : Boolean;
 Pp         : Integer;
 V          : LongInt;
 X, Y       : Integer;
 ByteIdx    : Integer;
 PD         : ^Byte;
 BV         : Byte;
Begin
 LoadXBM := False; Buf := Nil; W := 0; H := 0;
 BW := 0; BH := 0; InData := False;
 {$I-} Assign(T, FName); Reset(T); {$I+}
 If IOResult <> 0 Then Exit;
 { Pass 1 : recuperer width, height et localiser accolade ouvrante }
 While (Not Eof(T)) And (Not InData) Do Begin
  ReadLn(T, Line);
  US := ImgUpperStr(Line);
  If Pos('_WIDTH', US) > 0 Then BW := XBMExtractInt(Line)
  Else If Pos('_HEIGHT', US) > 0 Then BH := XBMExtractInt(Line);
  If Pos('{', Line) > 0 Then InData := True;
 End;
 If (Not InData) Or (BW<=0) Or (BH<=0) Or (BW>4096) Or (BH>4096) Then Begin
  Close(T); Exit;
 End;
 RowBytes := (BW + 7) Div 8;
 TotalBytes := LongInt(RowBytes) * BH;
 GetMem(BitsBuf, TotalBytes);
 FillChar(BitsBuf^, TotalBytes, 0);
 K := 0;
 { Pass 2 : lire octets 0xXX }
 While (Not Eof(T)) And (K < TotalBytes) Do Begin
  ReadLn(T, Line);
  Pp := 1;
  While (Pp <= Length(Line)) And (K < TotalBytes) Do Begin
   If Not XBMNextHexByte(Line, Pp, V) Then Break;
   ImgPByteSet(BitsBuf, K, Byte(V And $FF));
   Inc(K);
  End;
 End;
 Close(T);
 If K < TotalBytes Then Begin
  FreeMem(BitsBuf, TotalBytes); Exit;
 End;
 GetMem(Buf, LongInt(BW) * BH);
 PD := Buf;
 For Y := 0 To BH-1 Do
  For X := 0 To BW-1 Do Begin
   ByteIdx := X Shr 3;
   BV := ImgPByteAt(BitsBuf, LongInt(Y)*RowBytes + ByteIdx);
   If ((BV Shr (X And 7)) And 1) <> 0 Then PD^ := 0   { foreground noir }
                                       Else PD^ := 15; { fond blanc }
   Inc(PD);
  End;
 FreeMem(BitsBuf, TotalBytes);
 W := BW; H := BH;
 LoadXBM := True;
End;

{ ------------------------------------------------------------ }
{ ---------- TIFF baseline (II/MM, compression=1) ------------ }
{ ------------------------------------------------------------ }

Var
 TifBE : Boolean;        { True = big-endian (MM), False = little-endian (II) }
 TifFh : File;

Function TifRdByte: Byte;
Var B: Byte;
Begin
 BlockRead(TifFh, B, 1); TifRdByte := B;
End;

Function TifRdWord: Word;
Var B0, B1: Byte;
Begin
 BlockRead(TifFh, B0, 1); BlockRead(TifFh, B1, 1);
 If TifBE Then TifRdWord := Word(B0) Shl 8 Or B1
          Else TifRdWord := Word(B1) Shl 8 Or B0;
End;

Function TifRdDWord: LongInt;
Var B: Array[0..3] Of Byte; I: Integer;
Begin
 For I := 0 To 3 Do BlockRead(TifFh, B[I], 1);
 If TifBE Then
  TifRdDWord := (LongInt(B[0]) Shl 24) Or (LongInt(B[1]) Shl 16) Or
                (LongInt(B[2]) Shl 8)  Or  LongInt(B[3])
 Else
  TifRdDWord := (LongInt(B[3]) Shl 24) Or (LongInt(B[2]) Shl 16) Or
                (LongInt(B[1]) Shl 8)  Or  LongInt(B[0]);
End;

Function TifReadValue(FType: Integer; Cnt: LongInt; Ofs: LongInt): LongInt;
Var
 V     : LongInt;
Begin
 V := 0;
 If (FType = 3) And (Cnt = 1) Then
  V := Ofs And $FFFF
 Else If (FType = 4) And (Cnt = 1) Then
  V := Ofs
 Else If (FType = 1) And (Cnt = 1) Then
  V := Ofs And $FF
 Else
  V := Ofs;
 TifReadValue := V;
End;

Function LoadTIFF(Const FName: String; Var Buf: Pointer;
                  Var W, H: Integer): Boolean;
Var
 ByteOrder       : Array[0..1] Of Char;
 Magic           : Word;
 IFDOff          : LongInt;
 EntryCount      : Word;
 IE              : Integer;
 Tag, FType      : Word;
 Cnt, Vof        : LongInt;
 IW, IH          : LongInt;
 BitsPerSample   : Integer;
 SamplesPerPixel : Integer;
 Compression     : Integer;
 Photometric     : Integer;
 StripOffsets    : Array[0..255] Of LongInt;
 StripByteCount  : Array[0..255] Of LongInt;
 NumStrips       : Integer;
 RowsPerStrip    : LongInt;
 ColorMapOfs     : LongInt;
 HasColorMap     : Boolean;
 PlanarConfig    : Integer;
 BPSOfs          : LongInt;
 HasMultiBPS     : Boolean;
 SaveP           : LongInt;
 SrcRow          : Array[0..16383] Of Byte;
 PalR, PalG, PalB: Array[0..255] Of Word;
 PalNumColors    : Integer;
 Y, X            : LongInt;
 Si              : Integer;
 RowsThisStrip   : LongInt;
 RowBytes        : LongInt;
 ToRead          : LongInt;
 Got             : LongInt;
 PD              : ^Byte;
 OutIdx          : LongInt;
 Pix             : Byte;
 Cr, Cg, Cb_     : Byte;
 RowsRemaining   : LongInt;
 Row             : LongInt;
 ColIdx          : LongInt;
Begin
 LoadTIFF := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(TifFh, FName); Reset(TifFh, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(TifFh, ByteOrder, 2);
 If (ByteOrder[0]='I') And (ByteOrder[1]='I') Then TifBE := False
 Else If (ByteOrder[0]='M') And (ByteOrder[1]='M') Then TifBE := True
 Else Begin Close(TifFh); Exit; End;
 Magic := TifRdWord;
 If Magic <> 42 Then Begin Close(TifFh); Exit; End;
 IFDOff := TifRdDWord;
 Seek(TifFh, IFDOff);
 EntryCount := TifRdWord;
 IW := 0; IH := 0; BitsPerSample := 1; SamplesPerPixel := 1;
 Compression := 1; Photometric := 1; NumStrips := 0;
 RowsPerStrip := 0; ColorMapOfs := 0; HasColorMap := False;
 PlanarConfig := 1; BPSOfs := 0; HasMultiBPS := False;
 For IE := 0 To Integer(EntryCount) - 1 Do Begin
  Tag := TifRdWord;
  FType := TifRdWord;
  Cnt := TifRdDWord;
  Vof := TifRdDWord;
  Case Tag Of
   256: IW := TifReadValue(FType, Cnt, Vof);
   257: IH := TifReadValue(FType, Cnt, Vof);
   258: Begin
    If Cnt = 1 Then BitsPerSample := Integer(Vof And $FFFF)
    Else Begin
     BPSOfs := Vof; HasMultiBPS := True; BitsPerSample := 8;
    End;
   End;
   259: Compression := Integer(Vof And $FFFF);
   262: Photometric := Integer(Vof And $FFFF);
   273: Begin
    NumStrips := Integer(Cnt);
    If NumStrips > 256 Then NumStrips := 256;
    If Cnt = 1 Then StripOffsets[0] := Vof
    Else Begin
     SaveP := FilePos(TifFh);
     Seek(TifFh, Vof);
     If FType = 3 Then
      For Si := 0 To NumStrips - 1 Do StripOffsets[Si] := TifRdWord
     Else
      For Si := 0 To NumStrips - 1 Do StripOffsets[Si] := TifRdDWord;
     Seek(TifFh, SaveP);
    End;
   End;
   277: SamplesPerPixel := Integer(Vof And $FFFF);
   278: RowsPerStrip := Vof;
   279: Begin
    If Cnt = 1 Then StripByteCount[0] := Vof
    Else Begin
     SaveP := FilePos(TifFh);
     Seek(TifFh, Vof);
     If FType = 3 Then
      For Si := 0 To NumStrips - 1 Do StripByteCount[Si] := TifRdWord
     Else
      For Si := 0 To NumStrips - 1 Do StripByteCount[Si] := TifRdDWord;
     Seek(TifFh, SaveP);
    End;
   End;
   284: PlanarConfig := Integer(Vof And $FFFF);
   320: Begin
    ColorMapOfs := Vof; HasColorMap := True;
   End;
  End;
 End;
 If (IW<=0) Or (IH<=0) Or (IW>4096) Or (IH>4096) Then Begin
  Close(TifFh); Exit;
 End;
 If Compression <> 1 Then Begin Close(TifFh); Exit; End;
 If (PlanarConfig <> 1) Then Begin Close(TifFh); Exit; End;
 If RowsPerStrip = 0 Then RowsPerStrip := IH;
 If NumStrips = 0 Then NumStrips := 1;
 { Charge BPS multi si presents }
 If HasMultiBPS Then Begin
  SaveP := FilePos(TifFh);
  Seek(TifFh, BPSOfs);
  BitsPerSample := TifRdWord;
  Seek(TifFh, SaveP);
 End;
 { Charge ColorMap si presente (Photometric=3) }
 If HasColorMap And (Photometric = 3) Then Begin
  PalNumColors := 1 Shl BitsPerSample;
  If PalNumColors > 256 Then PalNumColors := 256;
  SaveP := FilePos(TifFh);
  Seek(TifFh, ColorMapOfs);
  For Si := 0 To PalNumColors - 1 Do PalR[Si] := TifRdWord;
  For Si := 0 To PalNumColors - 1 Do PalG[Si] := TifRdWord;
  For Si := 0 To PalNumColors - 1 Do PalB[Si] := TifRdWord;
  Seek(TifFh, SaveP);
 End Else
  PalNumColors := 0;
 { Allocation buffer destination }
 GetMem(Buf, IW * IH);
 PD := Buf;
 RowsRemaining := IH;
 Row := 0;
 For Si := 0 To NumStrips - 1 Do Begin
  If RowsRemaining <= 0 Then Break;
  RowsThisStrip := RowsPerStrip;
  If RowsThisStrip > RowsRemaining Then RowsThisStrip := RowsRemaining;
  RowBytes := (LongInt(IW) * BitsPerSample * SamplesPerPixel + 7) Div 8;
  If RowBytes > 16384 Then Begin
   FreeMem(Buf, IW*IH); Buf := Nil; Close(TifFh); Exit;
  End;
  Seek(TifFh, StripOffsets[Si]);
  ToRead := RowsThisStrip * RowBytes;
  Got := 0;
  For Y := 0 To RowsThisStrip - 1 Do Begin
   BlockRead(TifFh, SrcRow, RowBytes);
   Inc(Got, RowBytes);
   OutIdx := LongInt(Row + Y) * IW;
   Case Photometric Of
    0: Begin { WhiteIsZero (gray) }
     For X := 0 To IW - 1 Do Begin
      Case BitsPerSample Of
       1: Begin
        Pix := SrcRow[X Shr 3];
        If ((Pix Shr (7 - (X And 7))) And 1) <> 0 Then Pix := 0 Else Pix := 255;
       End;
       4: Begin
        Pix := SrcRow[X Shr 1];
        If (X And 1) = 0 Then Pix := (Pix Shr 4) And $0F Else Pix := Pix And $0F;
        Pix := Byte(255 - Pix * 17);
       End;
       8: Pix := Byte(255 - SrcRow[X]);
      Else Pix := 0;
      End;
      ImgPByteSet(Buf, OutIdx + X, NearestVGA(Pix, Pix, Pix));
     End;
    End;
    1: Begin { BlackIsZero (gray) }
     For X := 0 To IW - 1 Do Begin
      Case BitsPerSample Of
       1: Begin
        Pix := SrcRow[X Shr 3];
        If ((Pix Shr (7 - (X And 7))) And 1) <> 0 Then Pix := 255 Else Pix := 0;
       End;
       4: Begin
        Pix := SrcRow[X Shr 1];
        If (X And 1) = 0 Then Pix := (Pix Shr 4) And $0F Else Pix := Pix And $0F;
        Pix := Byte(Pix * 17);
       End;
       8: Pix := SrcRow[X];
      Else Pix := 0;
      End;
      ImgPByteSet(Buf, OutIdx + X, NearestVGA(Pix, Pix, Pix));
     End;
    End;
    2: Begin { RGB }
     If (BitsPerSample = 8) And (SamplesPerPixel >= 3) Then
      For X := 0 To IW - 1 Do Begin
       ColIdx := LongInt(X) * SamplesPerPixel;
       Cr := SrcRow[ColIdx];
       Cg := SrcRow[ColIdx + 1];
       Cb_ := SrcRow[ColIdx + 2];
       ImgPByteSet(Buf, OutIdx + X, NearestVGA(Cr, Cg, Cb_));
      End;
    End;
    3: Begin { Palette }
     For X := 0 To IW - 1 Do Begin
      Case BitsPerSample Of
       4: Begin
        Pix := SrcRow[X Shr 1];
        If (X And 1) = 0 Then Pix := (Pix Shr 4) And $0F Else Pix := Pix And $0F;
       End;
       8: Pix := SrcRow[X];
      Else Pix := 0;
      End;
      ImgPByteSet(Buf, OutIdx + X,
       NearestVGA(Byte(PalR[Pix] Shr 8), Byte(PalG[Pix] Shr 8), Byte(PalB[Pix] Shr 8)));
     End;
    End;
   End;
  End;
  Inc(Row, RowsThisStrip);
  Dec(RowsRemaining, RowsThisStrip);
 End;
 Close(TifFh);
 W := IW; H := IH;
 LoadTIFF := True;
End;

{ ------------------------------------------------------------ }
{ ---------- GIF 87a/89a (LZW, image unique) ----------------- }
{ ------------------------------------------------------------ }

Const
 GIF_MAX_DICT = 4096;

Var
 GifFh         : File;
 GifBlkBuf     : Array[0..255] Of Byte;
 GifBlkLen     : Integer;
 GifBlkIdx     : Integer;
 GifBitBuf     : LongInt;
 GifBitCnt     : Integer;
 GifEof        : Boolean;

Function GifReadByte(Var B: Byte): Boolean;
Var BR: LongInt;
Begin
 BlockRead(GifFh, B, 1, BR);
 GifReadByte := BR = 1;
End;

{ Lit le prochain octet du flux de blocs LZW (sub-blocks) }
Function GifNextLzwByte(Var B: Byte): Boolean;
Var Sz: Byte;
Begin
 GifNextLzwByte := False;
 If GifBlkIdx >= GifBlkLen Then Begin
  If Not GifReadByte(Sz) Then Exit;
  If Sz = 0 Then Begin GifEof := True; Exit; End;
  BlockRead(GifFh, GifBlkBuf, Sz);
  GifBlkLen := Sz;
  GifBlkIdx := 0;
 End;
 B := GifBlkBuf[GifBlkIdx];
 Inc(GifBlkIdx);
 GifNextLzwByte := True;
End;

Function GifReadCode(NBits: Integer; Var Code: Word): Boolean;
Var B: Byte;
Begin
 GifReadCode := False;
 While GifBitCnt < NBits Do Begin
  If Not GifNextLzwByte(B) Then Exit;
  GifBitBuf := GifBitBuf Or (LongInt(B) Shl GifBitCnt);
  Inc(GifBitCnt, 8);
 End;
 Code := Word(GifBitBuf And ((LongInt(1) Shl NBits) - 1));
 GifBitBuf := GifBitBuf Shr NBits;
 Dec(GifBitCnt, NBits);
 GifReadCode := True;
End;

Procedure GifSkipSubBlocks;
Var Sz: Byte; Skip: Array[0..255] Of Byte;
Begin
 Repeat
  If Not GifReadByte(Sz) Then Exit;
  If Sz = 0 Then Exit;
  BlockRead(GifFh, Skip, Sz);
 Until False;
End;

Function LoadGIF(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 Sig          : Array[0..5] Of Char;
 LSW, LSH     : Word;
 Packed_      : Byte;
 BgIdx, AsR   : Byte;
 GctSize      : Integer;
 GctPresent   : Boolean;
 GctR, GctG, GctB : Array[0..255] Of Byte;
 RawByte      : Byte;
 LzwMinCode   : Byte;
 NPalIdx      : Array[0..255] Of Byte;   { palette -> VGA }
 PalI         : Integer;
 ImL, ImT, ImW, ImH: Word;
 ImPacked     : Byte;
 LctR, LctG, LctB : Array[0..255] Of Byte;
 LctPresent   : Boolean;
 LctSize      : Integer;
 Interlaced   : Boolean;
 ClearCode    : Word;
 EOICode      : Word;
 CodeSize     : Integer;
 NextCode     : Word;
 DictPrefix   : Array[0..GIF_MAX_DICT-1] Of Word;
 DictSuffix   : Array[0..GIF_MAX_DICT-1] Of Byte;
 PrevCode     : Word;
 Code         : Word;
 FirstByte    : Byte;
 OutStack     : Array[0..GIF_MAX_DICT-1] Of Byte;
 SP           : Integer;
 K            : Word;
 OutBuf       : Pointer;
 OutBufLn     : LongInt;
 OutPx        : LongInt;
 Done         : Boolean;
 IPass, ILine : Integer;
 InterStart   : Array[0..3] Of Integer;
 InterStep    : Array[0..3] Of Integer;
 PixelRow     : LongInt;
 PixelCol     : LongInt;
 LineW        : LongInt;
 Tmp          : Word;
 PD           : ^Byte;
Begin
 LoadGIF := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(GifFh, FName); Reset(GifFh, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(GifFh, Sig, 6);
 If (Sig[0]<>'G') Or (Sig[1]<>'I') Or (Sig[2]<>'F') Then Begin
  Close(GifFh); Exit;
 End;
 BlockRead(GifFh, LSW, 2);
 BlockRead(GifFh, LSH, 2);
 BlockRead(GifFh, Packed_, 1);
 BlockRead(GifFh, BgIdx, 1);
 BlockRead(GifFh, AsR, 1);
 GctPresent := (Packed_ And $80) <> 0;
 GctSize := 1 Shl ((Packed_ And 7) + 1);
 If GctPresent Then
  For PalI := 0 To GctSize - 1 Do Begin
   BlockRead(GifFh, GctR[PalI], 1);
   BlockRead(GifFh, GctG[PalI], 1);
   BlockRead(GifFh, GctB[PalI], 1);
  End;
 { Boucle blocs jusqu'à premier image descriptor }
 Done := False;
 ImW := 0; ImH := 0; ImL := 0; ImT := 0; ImPacked := 0;
 LctPresent := False; LctSize := 0; Interlaced := False;
 While Not Done Do Begin
  If Not GifReadByte(RawByte) Then Begin Close(GifFh); Exit; End;
  Case RawByte Of
   $21: Begin   { Extension }
    If Not GifReadByte(RawByte) Then Begin Close(GifFh); Exit; End;
    GifSkipSubBlocks;
   End;
   $2C: Begin   { Image descriptor }
    BlockRead(GifFh, ImL, 2);
    BlockRead(GifFh, ImT, 2);
    BlockRead(GifFh, ImW, 2);
    BlockRead(GifFh, ImH, 2);
    BlockRead(GifFh, ImPacked, 1);
    LctPresent := (ImPacked And $80) <> 0;
    Interlaced := (ImPacked And $40) <> 0;
    LctSize := 1 Shl ((ImPacked And 7) + 1);
    If LctPresent Then
     For PalI := 0 To LctSize - 1 Do Begin
      BlockRead(GifFh, LctR[PalI], 1);
      BlockRead(GifFh, LctG[PalI], 1);
      BlockRead(GifFh, LctB[PalI], 1);
     End;
    Done := True;
   End;
   $3B: Begin Close(GifFh); Exit; End;   { trailer sans image }
  Else
   Close(GifFh); Exit;
  End;
 End;
 If (ImW = 0) Or (ImH = 0) Or (ImW > 4096) Or (ImH > 4096) Then Begin
  Close(GifFh); Exit;
 End;
 { Construire mapping palette -> VGA }
 If LctPresent Then
  For PalI := 0 To LctSize - 1 Do
   NPalIdx[PalI] := NearestVGA(LctR[PalI], LctG[PalI], LctB[PalI])
 Else If GctPresent Then
  For PalI := 0 To GctSize - 1 Do
   NPalIdx[PalI] := NearestVGA(GctR[PalI], GctG[PalI], GctB[PalI])
 Else Begin Close(GifFh); Exit; End;
 { Init LZW }
 BlockRead(GifFh, LzwMinCode, 1);
 If (LzwMinCode < 2) Or (LzwMinCode > 8) Then Begin Close(GifFh); Exit; End;
 ClearCode := Word(1) Shl LzwMinCode;
 EOICode := ClearCode + 1;
 GifBlkLen := 0; GifBlkIdx := 0; GifEof := False;
 GifBitBuf := 0; GifBitCnt := 0;
 OutBufLn := LongInt(ImW) * ImH;
 GetMem(OutBuf, OutBufLn);
 OutPx := 0;
 { Interlacing }
 InterStart[0] := 0; InterStep[0] := 8;
 InterStart[1] := 4; InterStep[1] := 8;
 InterStart[2] := 2; InterStep[2] := 4;
 InterStart[3] := 1; InterStep[3] := 2;
 IPass := 0; ILine := InterStart[0];
 LineW := ImW;
 { Init dict }
 CodeSize := LzwMinCode + 1;
 NextCode := EOICode + 1;
 For K := 0 To ClearCode - 1 Do Begin
  DictPrefix[K] := 0;
  DictSuffix[K] := Byte(K);
 End;
 PrevCode := 0; FirstByte := 0;
 Done := False;
 PixelRow := 0; PixelCol := 0;
 While Not Done Do Begin
  If Not GifReadCode(CodeSize, Code) Then Begin Done := True; Break; End;
  If Code = ClearCode Then Begin
   CodeSize := LzwMinCode + 1;
   NextCode := EOICode + 1;
   If Not GifReadCode(CodeSize, Code) Then Begin Done := True; Break; End;
   If Code = EOICode Then Begin Done := True; Break; End;
   FirstByte := DictSuffix[Code];
   { Emit }
   If Interlaced Then Begin
    If (ILine < ImH) And (PixelCol < LineW) Then Begin
     ImgPByteSet(OutBuf, LongInt(ILine)*ImW + PixelCol, NPalIdx[FirstByte]);
     Inc(PixelCol);
     If PixelCol >= LineW Then Begin
      PixelCol := 0; Inc(ILine, InterStep[IPass]);
      While (ILine >= ImH) And (IPass < 3) Do Begin
       Inc(IPass); ILine := InterStart[IPass];
      End;
     End;
    End;
   End Else Begin
    If OutPx < OutBufLn Then ImgPByteSet(OutBuf, OutPx, NPalIdx[FirstByte]);
    Inc(OutPx);
   End;
   PrevCode := Code;
   Continue;
  End;
  If Code = EOICode Then Begin Done := True; Break; End;
  SP := 0;
  K := Code;
  If K >= NextCode Then Begin
   { KwKwK case }
   OutStack[SP] := FirstByte; Inc(SP);
   K := PrevCode;
  End;
  While K >= ClearCode Do Begin
   If SP >= GIF_MAX_DICT Then Begin Done := True; Break; End;
   OutStack[SP] := DictSuffix[K]; Inc(SP);
   K := DictPrefix[K];
  End;
  FirstByte := DictSuffix[K];
  OutStack[SP] := FirstByte; Inc(SP);
  { Emit stack in reverse }
  While SP > 0 Do Begin
   Dec(SP);
   If Interlaced Then Begin
    If (ILine < ImH) And (PixelCol < LineW) Then Begin
     ImgPByteSet(OutBuf, LongInt(ILine)*ImW + PixelCol, NPalIdx[OutStack[SP]]);
     Inc(PixelCol);
     If PixelCol >= LineW Then Begin
      PixelCol := 0; Inc(ILine, InterStep[IPass]);
      While (ILine >= ImH) And (IPass < 3) Do Begin
       Inc(IPass); ILine := InterStart[IPass];
      End;
     End;
    End;
   End Else Begin
    If OutPx < OutBufLn Then ImgPByteSet(OutBuf, OutPx, NPalIdx[OutStack[SP]]);
    Inc(OutPx);
   End;
  End;
  { Add to dict }
  If (NextCode < GIF_MAX_DICT) Then Begin
   DictPrefix[NextCode] := PrevCode;
   DictSuffix[NextCode] := FirstByte;
   Inc(NextCode);
   If (NextCode = (Word(1) Shl CodeSize)) And (CodeSize < 12) Then
    Inc(CodeSize);
  End;
  PrevCode := Code;
 End;
 { Consommer sub-blocks restants }
 If Not GifEof Then GifSkipSubBlocks;
 Close(GifFh);
 Buf := OutBuf; W := ImW; H := ImH;
 LoadGIF := True;
End;

{ ------------------------------------------------------------ }
{ -------- JPEG baseline DCT (Huffman + IDCT + YCbCr) -------- }
{ ------------------------------------------------------------ }

Const
 JPG_DCT_SIZE = 8;

Type
 TJpgQT     = Array[0..63] Of Integer;
 TJpgHuff   = Record
  Bits   : Array[0..16] Of Byte;       { count per length, [0] unused }
  HuffV  : Array[0..255] Of Byte;
  MinCode: Array[1..16] Of LongInt;
  MaxCode: Array[1..16] Of LongInt;
  ValPtr : Array[1..16] Of Integer;
  NumVals: Integer;
 End;
 TJpgComp   = Record
  Id     : Byte;
  HSamp  : Byte;
  VSamp  : Byte;
  QTId   : Byte;
  DCT    : Byte;
  ACT    : Byte;
  PrevDC : Integer;
 End;
 TJpgBlock  = Array[0..63] Of Integer;

Var
 JpgFh        : File;
 JpgBuf       : Array[0..4095] Of Byte;
 JpgBufLen    : Integer;
 JpgBufIdx    : Integer;
 JpgEofFlag   : Boolean;
 JpgBitBuf    : LongInt;
 JpgBitCnt    : Integer;
 JpgQT        : Array[0..3] Of TJpgQT;
 JpgDCHuff    : Array[0..3] Of TJpgHuff;
 JpgACHuff    : Array[0..3] Of TJpgHuff;
 JpgComp      : Array[0..2] Of TJpgComp;
 JpgNComp     : Integer;
 JpgWidth     : Integer;
 JpgHeight    : Integer;
 JpgHmax      : Integer;
 JpgVmax      : Integer;
 JpgMCUW      : Integer;
 JpgMCUH      : Integer;
 JpgRSTI      : Integer;
 JpgRSTCount  : Integer;
 JpgZigzag    : Array[0..63] Of Byte;
 JpgCosTab    : Array[0..7, 0..7] Of Real;
 JpgIDCTInit  : Boolean;

Function JpgFillBuf: Boolean;
Var BR: LongInt;
Begin
 BlockRead(JpgFh, JpgBuf, 4096, BR);
 JpgBufLen := Integer(BR);
 JpgBufIdx := 0;
 JpgFillBuf := BR > 0;
 If BR = 0 Then JpgEofFlag := True;
End;

Function JpgGetRawByte(Var B: Byte): Boolean;
Begin
 If JpgBufIdx >= JpgBufLen Then
  If Not JpgFillBuf Then Begin JpgGetRawByte := False; Exit; End;
 B := JpgBuf[JpgBufIdx]; Inc(JpgBufIdx);
 JpgGetRawByte := True;
End;

{ Lit un octet du flux entropie : FF00 -> FF, FFxx (xx<>0) = marker }
Function JpgGetEntropyByte(Var B: Byte; Var Marker: Byte): Boolean;
Var B2: Byte;
Begin
 JpgGetEntropyByte := False; Marker := 0;
 If Not JpgGetRawByte(B) Then Exit;
 If B = $FF Then Begin
  If Not JpgGetRawByte(B2) Then Exit;
  If B2 = 0 Then Begin
   B := $FF;
  End Else Begin
   Marker := B2;
   JpgGetEntropyByte := False; Exit;
  End;
 End;
 JpgGetEntropyByte := True;
End;

{ Charge NBits dans le bitbuf (depuis MSB) }
Function JpgFillBits(NBits: Integer): Boolean;
Var B, Mk: Byte;
Begin
 JpgFillBits := True;
 While JpgBitCnt < NBits Do Begin
  If Not JpgGetEntropyByte(B, Mk) Then Begin
   { Marker rencontre ou fin : bourre des zeros }
   JpgBitBuf := JpgBitBuf Shl 8;
   Inc(JpgBitCnt, 8);
   { Si c'est un marker non-restart, on s'arrete }
   If (Mk <> 0) And ((Mk < $D0) Or (Mk > $D7)) Then Begin
    { remettre le marker en buffer en stockant un sentinelle }
    JpgFillBits := False;
   End;
   Continue;
  End;
  JpgBitBuf := (JpgBitBuf Shl 8) Or B;
  Inc(JpgBitCnt, 8);
 End;
End;

Function JpgReadBits(NBits: Integer): LongInt;
Var V: LongInt;
Begin
 If NBits = 0 Then Begin JpgReadBits := 0; Exit; End;
 JpgFillBits(NBits);
 V := (JpgBitBuf Shr (JpgBitCnt - NBits)) And ((LongInt(1) Shl NBits) - 1);
 Dec(JpgBitCnt, NBits);
 JpgReadBits := V;
End;

Function JpgPeekBits(NBits: Integer): LongInt;
Begin
 JpgFillBits(NBits);
 JpgPeekBits := (JpgBitBuf Shr (JpgBitCnt - NBits)) And ((LongInt(1) Shl NBits) - 1);
End;

Procedure JpgDropBits(NBits: Integer);
Begin
 Dec(JpgBitCnt, NBits);
End;

{ Decode un code Huffman via mincode/maxcode/valptr }
Function JpgDecodeSymbol(Var T: TJpgHuff): Integer;
Var
 Code : LongInt;
 L    : Integer;
Begin
 Code := JpgReadBits(1);
 L := 1;
 While (L <= 16) And (Code > T.MaxCode[L]) Do Begin
  Code := (Code Shl 1) Or JpgReadBits(1);
  Inc(L);
 End;
 If L > 16 Then Begin JpgDecodeSymbol := 0; Exit; End;
 JpgDecodeSymbol := T.HuffV[T.ValPtr[L] + Integer(Code - T.MinCode[L])];
End;

{ Etend la valeur lue selon JPEG (signe via bit haut) }
Function JpgExtend(V: LongInt; T: Integer): Integer;
Begin
 If T = 0 Then Begin JpgExtend := 0; Exit; End;
 If V < (LongInt(1) Shl (T - 1)) Then
  JpgExtend := Integer(V - ((LongInt(1) Shl T) - 1))
 Else
  JpgExtend := Integer(V);
End;

Procedure JpgBuildHuffTables(Var T: TJpgHuff);
Var
 HuffCode : Array[0..255] Of LongInt;
 HuffSize : Array[0..255] Of Integer;
 I, J, K  : Integer;
 Code     : LongInt;
 SI       : Integer;
Begin
 { Construire huffsize }
 K := 0;
 For I := 1 To 16 Do
  For J := 1 To T.Bits[I] Do Begin
   HuffSize[K] := I; Inc(K);
  End;
 T.NumVals := K;
 { Construire huffcode }
 Code := 0; SI := HuffSize[0];
 For I := 0 To K - 1 Do Begin
  While HuffSize[I] <> SI Do Begin
   Code := Code Shl 1; Inc(SI);
  End;
  HuffCode[I] := Code;
  Inc(Code);
 End;
 { Construire mincode/maxcode/valptr par longueur }
 For I := 1 To 16 Do Begin
  T.MinCode[I] := -1;
  T.MaxCode[I] := -1;
  T.ValPtr[I]  := 0;
 End;
 J := 0;
 For I := 1 To 16 Do
  If T.Bits[I] > 0 Then Begin
   T.ValPtr[I]  := J;
   T.MinCode[I] := HuffCode[J];
   T.MaxCode[I] := HuffCode[J + T.Bits[I] - 1];
   Inc(J, T.Bits[I]);
  End;
End;

Procedure JpgInitTables;
Var
 ZZ : Array[0..63] Of Byte;
 I, J: Integer;
 PI : Real;
 Cu : Real;
Begin
 ZZ[0]:=0;  ZZ[1]:=1;  ZZ[2]:=8;  ZZ[3]:=16; ZZ[4]:=9;  ZZ[5]:=2;  ZZ[6]:=3;  ZZ[7]:=10;
 ZZ[8]:=17; ZZ[9]:=24; ZZ[10]:=32; ZZ[11]:=25; ZZ[12]:=18; ZZ[13]:=11; ZZ[14]:=4;  ZZ[15]:=5;
 ZZ[16]:=12; ZZ[17]:=19; ZZ[18]:=26; ZZ[19]:=33; ZZ[20]:=40; ZZ[21]:=48; ZZ[22]:=41; ZZ[23]:=34;
 ZZ[24]:=27; ZZ[25]:=20; ZZ[26]:=13; ZZ[27]:=6;  ZZ[28]:=7;  ZZ[29]:=14; ZZ[30]:=21; ZZ[31]:=28;
 ZZ[32]:=35; ZZ[33]:=42; ZZ[34]:=49; ZZ[35]:=56; ZZ[36]:=57; ZZ[37]:=50; ZZ[38]:=43; ZZ[39]:=36;
 ZZ[40]:=29; ZZ[41]:=22; ZZ[42]:=15; ZZ[43]:=23; ZZ[44]:=30; ZZ[45]:=37; ZZ[46]:=44; ZZ[47]:=51;
 ZZ[48]:=58; ZZ[49]:=59; ZZ[50]:=52; ZZ[51]:=45; ZZ[52]:=38; ZZ[53]:=31; ZZ[54]:=39; ZZ[55]:=46;
 ZZ[56]:=53; ZZ[57]:=60; ZZ[58]:=61; ZZ[59]:=54; ZZ[60]:=47; ZZ[61]:=55; ZZ[62]:=62; ZZ[63]:=63;
 For I := 0 To 63 Do JpgZigzag[I] := ZZ[I];
 PI := 3.14159265358979;
 For I := 0 To 7 Do Begin
  If I = 0 Then Cu := 1.0 / 1.41421356237
           Else Cu := 1.0;
  For J := 0 To 7 Do
   JpgCosTab[I, J] := Cu * Cos((2*J + 1) * I * PI / 16.0);
 End;
 JpgIDCTInit := True;
End;

{ IDCT 8x8 séparable. In = coefs de-quantifiés; Out = pixels (-128..127) }
Procedure JpgIDCT(Var Coef: TJpgBlock; Var Pix: Array Of Integer);
Var
 Tmp    : Array[0..63] Of Real;
 X, Y, U, V : Integer;
 S      : Real;
 V0     : Integer;
Begin
 { Row pass : Tmp[y][x] = sum_u F[y][u]*Cu*cos((2x+1)u pi/16) }
 For Y := 0 To 7 Do
  For X := 0 To 7 Do Begin
   S := 0;
   For U := 0 To 7 Do
    S := S + Coef[Y*8 + U] * JpgCosTab[U, X];
   Tmp[Y*8 + X] := S;
  End;
 { Col pass + scale 1/4 }
 For X := 0 To 7 Do
  For Y := 0 To 7 Do Begin
   S := 0;
   For V := 0 To 7 Do
    S := S + Tmp[V*8 + X] * JpgCosTab[V, Y];
   V0 := Round(S / 4.0);
   If V0 < -128 Then V0 := -128;
   If V0 > 127  Then V0 := 127;
   Pix[Y*8 + X] := V0;
  End;
End;

{ Decode un bloc 8x8 (DC+AC), dequant, IDCT. Pix sera -128..127. }
Function JpgDecodeBlock(Var Comp: TJpgComp; Var Pix: Array Of Integer): Boolean;
Var
 Coef        : TJpgBlock;
 ZZCoef      : TJpgBlock;
 I           : Integer;
 S, T        : Integer;
 Run         : Integer;
 RS          : Integer;
 K           : Integer;
 V           : LongInt;
 QT          : Integer;
Begin
 For I := 0 To 63 Do Coef[I] := 0;
 { DC }
 T := JpgDecodeSymbol(JpgDCHuff[Comp.DCT]);
 V := JpgReadBits(T);
 S := JpgExtend(V, T);
 Comp.PrevDC := Comp.PrevDC + S;
 Coef[0] := Comp.PrevDC;
 { AC }
 K := 1;
 While K < 64 Do Begin
  RS := JpgDecodeSymbol(JpgACHuff[Comp.ACT]);
  Run := RS Shr 4;
  T   := RS And $0F;
  If T = 0 Then Begin
   If Run = 15 Then Begin
    Inc(K, 16);
    Continue;
   End;
   Break;     { EOB }
  End;
  Inc(K, Run);
  If K >= 64 Then Break;
  V := JpgReadBits(T);
  Coef[K] := JpgExtend(V, T);
  Inc(K);
 End;
 { Dequantize + dezigzag }
 QT := Comp.QTId;
 For I := 0 To 63 Do
  ZZCoef[JpgZigzag[I]] := Coef[I] * JpgQT[QT, I];
 JpgIDCT(ZZCoef, Pix);
 JpgDecodeBlock := True;
End;

Procedure JpgReadDQT(Len: Integer);
Var
 PqTq, Pq, Tq: Byte;
 Bytes: Integer;
 I: Integer;
 W: Word;
Begin
 Bytes := Len - 2;
 While Bytes > 0 Do Begin
  BlockRead(JpgFh, PqTq, 1); Dec(Bytes);
  Pq := PqTq Shr 4;
  Tq := PqTq And $0F;
  If Tq > 3 Then Exit;
  For I := 0 To 63 Do
   If Pq = 0 Then Begin
    BlockRead(JpgFh, PqTq, 1); Dec(Bytes);
    JpgQT[Tq, I] := PqTq;
   End Else Begin
    BlockRead(JpgFh, W, 2); Dec(Bytes, 2);
    JpgQT[Tq, I] := Integer(Swap(W));
   End;
 End;
End;

Procedure JpgReadDHT(Len: Integer);
Var
 TcTh, Tc, Th : Byte;
 I, Total     : Integer;
 Bytes        : Integer;
Begin
 Bytes := Len - 2;
 While Bytes > 0 Do Begin
  BlockRead(JpgFh, TcTh, 1); Dec(Bytes);
  Tc := TcTh Shr 4;
  Th := TcTh And $0F;
  If Th > 3 Then Exit;
  Total := 0;
  If Tc = 0 Then Begin
   For I := 1 To 16 Do Begin
    BlockRead(JpgFh, JpgDCHuff[Th].Bits[I], 1);
    Inc(Total, JpgDCHuff[Th].Bits[I]);
   End;
   Dec(Bytes, 16);
   For I := 0 To Total - 1 Do BlockRead(JpgFh, JpgDCHuff[Th].HuffV[I], 1);
   Dec(Bytes, Total);
   JpgBuildHuffTables(JpgDCHuff[Th]);
  End Else Begin
   For I := 1 To 16 Do Begin
    BlockRead(JpgFh, JpgACHuff[Th].Bits[I], 1);
    Inc(Total, JpgACHuff[Th].Bits[I]);
   End;
   Dec(Bytes, 16);
   For I := 0 To Total - 1 Do BlockRead(JpgFh, JpgACHuff[Th].HuffV[I], 1);
   Dec(Bytes, Total);
   JpgBuildHuffTables(JpgACHuff[Th]);
  End;
 End;
End;

Function JpgReadSOF0(Len: Integer): Boolean;
Var
 Prec        : Byte;
 HH, WW      : Word;
 Nf          : Byte;
 I           : Integer;
 CompID, HV, Tq : Byte;
Begin
 JpgReadSOF0 := False;
 BlockRead(JpgFh, Prec, 1);
 If Prec <> 8 Then Exit;
 BlockRead(JpgFh, HH, 2);
 BlockRead(JpgFh, WW, 2);
 JpgHeight := Integer(Swap(HH));
 JpgWidth  := Integer(Swap(WW));
 BlockRead(JpgFh, Nf, 1);
 If (Nf <> 1) And (Nf <> 3) Then Exit;
 JpgNComp := Nf;
 JpgHmax := 0; JpgVmax := 0;
 For I := 0 To Nf - 1 Do Begin
  BlockRead(JpgFh, CompID, 1);
  BlockRead(JpgFh, HV, 1);
  BlockRead(JpgFh, Tq, 1);
  JpgComp[I].Id := CompID;
  JpgComp[I].HSamp := HV Shr 4;
  JpgComp[I].VSamp := HV And $0F;
  JpgComp[I].QTId := Tq;
  If JpgComp[I].HSamp > JpgHmax Then JpgHmax := JpgComp[I].HSamp;
  If JpgComp[I].VSamp > JpgVmax Then JpgVmax := JpgComp[I].VSamp;
 End;
 JpgMCUW := JpgHmax * 8;
 JpgMCUH := JpgVmax * 8;
 JpgReadSOF0 := True;
End;

Function JpgReadSOS(Len: Integer): Boolean;
Var
 Ns, CS, Td_Ta, Ss, Se, AhAl : Byte;
 I, J : Integer;
Begin
 JpgReadSOS := False;
 BlockRead(JpgFh, Ns, 1);
 If Ns <> JpgNComp Then Exit;
 For I := 0 To Ns - 1 Do Begin
  BlockRead(JpgFh, CS, 1);
  BlockRead(JpgFh, Td_Ta, 1);
  For J := 0 To JpgNComp - 1 Do
   If JpgComp[J].Id = CS Then Begin
    JpgComp[J].DCT := Td_Ta Shr 4;
    JpgComp[J].ACT := Td_Ta And $0F;
   End;
 End;
 BlockRead(JpgFh, Ss, 1);
 BlockRead(JpgFh, Se, 1);
 BlockRead(JpgFh, AhAl, 1);
 JpgReadSOS := True;
End;

Function JpgYCbCrToVGA(Y, Cb, Cr: Integer): Byte;
Var R, G, B, T: Integer;
Begin
 { Y, Cb, Cr déjà ajoutés +128 ; conversion JFIF }
 T := Cr - 128;
 R := Y + ((91881 * T) Shr 16);
 T := Cb - 128;
 B := Y + ((116130 * T) Shr 16);
 G := Y - ((22554 * (Cb - 128) + 46802 * (Cr - 128)) Shr 16);
 If R < 0 Then R := 0; If R > 255 Then R := 255;
 If G < 0 Then G := 0; If G > 255 Then G := 255;
 If B < 0 Then B := 0; If B > 255 Then B := 255;
 JpgYCbCrToVGA := NearestVGA(Byte(R), Byte(G), Byte(B));
End;

Function LoadJPEG(Const FName: String; Var Buf: Pointer;
                  Var W, H: Integer): Boolean;
Var
 Sig         : Word;
 Marker      : Byte;
 SegLen      : Word;
 B           : Byte;
 NumMCURows  : Integer;
 NumMCUCols  : Integer;
 MX, MY      : Integer;
 Ci, Bi, BIdx: Integer;
 Pix         : Array[0..63] Of Integer;
 CompPlanes  : Array[0..2, 0..255] Of Integer;   { max MCU 16x16 = 256 }
 PX, PY      : Integer;
 GX, GY      : Integer;
 YVal, CbVal, CrVal : Integer;
 LumaX, LumaY : Integer;
 ChrX, ChrY   : Integer;
 OutBuf      : Pointer;
 RstCnt      : Integer;
 I, J        : Integer;
 SOSDone     : Boolean;
 ScanByte    : Byte;
 ScanByte2   : Byte;
 BX, BY      : Integer;
Begin
 LoadJPEG := False; Buf := Nil; W := 0; H := 0;
 If Not JpgIDCTInit Then JpgInitTables;
 {$I-} Assign(JpgFh, FName); Reset(JpgFh, 1); {$I+}
 If IOResult <> 0 Then Exit;
 JpgBufLen := 0; JpgBufIdx := 0; JpgEofFlag := False;
 JpgBitBuf := 0; JpgBitCnt := 0;
 JpgRSTI := 0;
 { SOI }
 If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
 If B <> $FF Then Begin Close(JpgFh); Exit; End;
 If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
 If B <> $D8 Then Begin Close(JpgFh); Exit; End;
 { Parse markers jusqu'a SOS }
 SOSDone := False;
 While Not SOSDone Do Begin
  If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  If B <> $FF Then Continue;
  While B = $FF Do
   If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  Marker := B;
  If Marker = 0 Then Continue;
  If (Marker >= $D0) And (Marker <= $D9) Then Continue;
  { Lire longueur }
  If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  SegLen := Word(B) Shl 8;
  If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  SegLen := SegLen Or B;
  Case Marker Of
   $C0: Begin
    If Not JpgReadSOF0(SegLen) Then Begin Close(JpgFh); Exit; End;
   End;
   $C4: JpgReadDHT(SegLen);
   $DB: JpgReadDQT(SegLen);
   $DD: Begin
    BlockRead(JpgFh, B, 1);
    JpgRSTI := Integer(B) Shl 8;
    BlockRead(JpgFh, B, 1);
    JpgRSTI := JpgRSTI Or B;
   End;
   $DA: Begin
    If Not JpgReadSOS(SegLen) Then Begin Close(JpgFh); Exit; End;
    SOSDone := True;
   End;
  Else
   { Skip segment }
   For I := 0 To Integer(SegLen) - 3 Do BlockRead(JpgFh, B, 1);
  End;
 End;
 { Decode scan }
 If (JpgWidth <= 0) Or (JpgHeight <= 0) Or
    (JpgWidth > 4096) Or (JpgHeight > 4096) Then Begin Close(JpgFh); Exit; End;
 NumMCUCols := (JpgWidth  + JpgMCUW - 1) Div JpgMCUW;
 NumMCURows := (JpgHeight + JpgMCUH - 1) Div JpgMCUH;
 GetMem(OutBuf, LongInt(JpgWidth) * JpgHeight);
 For I := 0 To 2 Do JpgComp[I].PrevDC := 0;
 RstCnt := 0;
 For MY := 0 To NumMCURows - 1 Do
  For MX := 0 To NumMCUCols - 1 Do Begin
   { Decode chaque composante }
   For Ci := 0 To JpgNComp - 1 Do Begin
    For BY := 0 To JpgComp[Ci].VSamp - 1 Do
     For BX := 0 To JpgComp[Ci].HSamp - 1 Do Begin
      JpgDecodeBlock(JpgComp[Ci], Pix);
      { Niveau shift +128 et place dans CompPlanes }
      For PY := 0 To 7 Do
       For PX := 0 To 7 Do Begin
        I := (BY*8 + PY) * JpgMCUW + (BX*8 + PX);
        { Si composante a sampling < max, etirer }
        If JpgComp[Ci].HSamp = JpgHmax Then ChrX := 1 Else ChrX := JpgHmax Div JpgComp[Ci].HSamp;
        If JpgComp[Ci].VSamp = JpgVmax Then ChrY := 1 Else ChrY := JpgVmax Div JpgComp[Ci].VSamp;
        For LumaY := 0 To ChrY - 1 Do
         For LumaX := 0 To ChrX - 1 Do Begin
          J := ((BY*8 + PY)*ChrY + LumaY) * JpgMCUW + ((BX*8 + PX)*ChrX + LumaX);
          If (J >= 0) And (J < 256) Then
           CompPlanes[Ci, J] := Pix[PY*8 + PX] + 128;
         End;
       End;
     End;
   End;
   { Convertir et ecrire dans OutBuf }
   For PY := 0 To JpgMCUH - 1 Do
    For PX := 0 To JpgMCUW - 1 Do Begin
     GX := MX * JpgMCUW + PX;
     GY := MY * JpgMCUH + PY;
     If (GX < JpgWidth) And (GY < JpgHeight) Then Begin
      I := PY * JpgMCUW + PX;
      If JpgNComp = 1 Then Begin
       YVal := CompPlanes[0, I];
       If YVal < 0 Then YVal := 0;
       If YVal > 255 Then YVal := 255;
       ImgPByteSet(OutBuf, LongInt(GY)*JpgWidth + GX,
        NearestVGA(Byte(YVal), Byte(YVal), Byte(YVal)));
      End Else Begin
       YVal := CompPlanes[0, I];
       CbVal := CompPlanes[1, I];
       CrVal := CompPlanes[2, I];
       ImgPByteSet(OutBuf, LongInt(GY)*JpgWidth + GX,
        JpgYCbCrToVGA(YVal, CbVal, CrVal));
      End;
     End;
    End;
   { Restart interval }
   If JpgRSTI > 0 Then Begin
    Inc(RstCnt);
    If (RstCnt = JpgRSTI) And ((MY < NumMCURows - 1) Or (MX < NumMCUCols - 1)) Then Begin
     RstCnt := 0;
     { Vider bits, lire marker RSTm }
     JpgBitBuf := 0; JpgBitCnt := 0;
     If JpgGetRawByte(ScanByte) Then Begin
      While (ScanByte <> $FF) And JpgGetRawByte(ScanByte) Do ;
      JpgGetRawByte(ScanByte2);
     End;
     For I := 0 To 2 Do JpgComp[I].PrevDC := 0;
    End;
   End;
  End;
 Close(JpgFh);
 Buf := OutBuf; W := JpgWidth; H := JpgHeight;
 LoadJPEG := True;
End;

{ ------------------------------------------------------------ }
{ ------ Dispatcher unifie par extension --------------------- }
{ ------------------------------------------------------------ }

Function LoadAnyImage(Const FName: String; Var Buf: Pointer;
                      Var W, H: Integer): Boolean;
Var
 Ext : String;
 LF  : Integer;
 CC  : Char;
Begin
 LoadAnyImage := False;
 Ext := ''; LF := Length(FName);
 If LF >= 4 Then Begin
  If FName[LF-3] = '.' Then Begin
   CC := ImgUpcaseChar(FName[LF-2]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF-1]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF]);   Ext := Ext + CC;
  End Else If (LF >= 5) And (FName[LF-4] = '.') Then Begin
   CC := ImgUpcaseChar(FName[LF-3]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF-2]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF-1]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF]);   Ext := Ext + CC;
  End;
 End;
 If      Ext = 'BMP'  Then LoadAnyImage := LoadBMP(FName, Buf, W, H)
 Else If Ext = 'PCX'  Then LoadAnyImage := LoadPCX(FName, Buf, W, H)
 Else If Ext = 'BGX'  Then LoadAnyImage := LoadBGX(FName, Buf, W, H)
 Else If Ext = 'XBM'  Then LoadAnyImage := LoadXBM(FName, Buf, W, H)
 Else If Ext = 'TIF'  Then LoadAnyImage := LoadTIFF(FName, Buf, W, H)
 Else If Ext = 'TIFF' Then LoadAnyImage := LoadTIFF(FName, Buf, W, H)
 Else If Ext = 'GIF'  Then LoadAnyImage := LoadGIF(FName, Buf, W, H)
 Else If Ext = 'JPG'  Then LoadAnyImage := LoadJPEG(FName, Buf, W, H)
 Else If Ext = 'JPEG' Then LoadAnyImage := LoadJPEG(FName, Buf, W, H);
End;

Procedure InsertImageAtCursor(Buf: Pointer; W, H: Integer);
Var
 NewIdx, P, I       : Integer;
 ScaledBuf          : Pointer;
 SW, SH             : Integer;
Begin
 If Doc.ParaCount >= MAX_PARAS_PER_DOC - 1 Then Begin
  FreeMem(Buf, W*H);
  Exit;
 End;
 ScaleImageNN(Buf, W, H, ScaledBuf, SW, SH);
 FreeMem(Buf, W*H);
 If Cursor.CharIdx > 0 Then NewParagraphAtCursor;
 P := Cursor.ParaIdx;
 NewIdx := P + 1;
 For I := Doc.ParaCount Downto NewIdx Do
  Doc.Paragraphs[I+1] := Doc.Paragraphs[I];
 Inc(Doc.ParaCount);
 FillChar(Doc.Paragraphs[NewIdx], SizeOf(TParagraph), 0);
 Doc.Paragraphs[NewIdx].Alignment := ALIGN_CENTER;
 Doc.Paragraphs[NewIdx].IsImage   := True;
 Doc.Paragraphs[NewIdx].ImgW      := SW;
 Doc.Paragraphs[NewIdx].ImgH      := SH;
 Doc.Paragraphs[NewIdx].ImgData   := ScaledBuf;
 { Para vide ensuite pour permettre saisie sous l'image. }
 If (NewIdx = Doc.ParaCount) And (Doc.ParaCount < MAX_PARAS_PER_DOC) Then Begin
  Inc(Doc.ParaCount);
  FillChar(Doc.Paragraphs[NewIdx+1], SizeOf(TParagraph), 0);
  Doc.Paragraphs[NewIdx+1].RunCount := 1;
  Doc.Paragraphs[NewIdx+1].Runs[1].Style := CurrentStyle;
  Doc.Paragraphs[NewIdx+1].Runs[1].Text := '';
  Cursor.ParaIdx := NewIdx + 1;
 End Else
  Cursor.ParaIdx := NewIdx + 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 Doc.Modified   := True;
 NeedsRelayout  := True;
End;

{ ============================================================ }
{ =================  PHASE 7 - DEFLATE / ZIP  ================ }
{ ============================================================ }

{ ----------------------- CRC-32 (zlib) ---------------------- }

Var
 CRC32_Tbl_Init : Boolean;
 CRC32_Tbl      : Array[0..255] Of Cardinal;

Procedure InitCRC32Tbl;
Var I, J: Integer; C: Cardinal;
Begin
 If CRC32_Tbl_Init Then Exit;
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := Cardinal($EDB88320) Xor (C Shr 1)
   Else                   C := C Shr 1;
  CRC32_Tbl[I] := C;
 End;
 CRC32_Tbl_Init := True;
End;

Function CRC32Of(P: Pointer; N: LongInt): Cardinal;
Var PB: ^Byte; I: LongInt; CRC: Cardinal;
Begin
 InitCRC32Tbl;
 PB := P;
 CRC := Cardinal($FFFFFFFF);
 For I := 1 To N Do Begin
  CRC := CRC32_Tbl[(CRC Xor PB^) And $FF] Xor (CRC Shr 8);
  Inc(PB);
 End;
 CRC32Of := CRC Xor Cardinal($FFFFFFFF);
End;

{ ------------------- INFLATE (RFC 1951) -------------------- }

Const
 INF_LengthBase  : Array[0..28] Of Word =
  (3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
   35,43,51,59,67,83,99,115,131,163,195,227,258);
 INF_LengthExtra : Array[0..28] Of Byte =
  (0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
   3,3,3,3,4,4,4,4,5,5,5,5,0);
 INF_DistBase    : Array[0..29] Of Word =
  (1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
   257,385,513,769,1025,1537,2049,3073,4097,6145,
   8193,12289,16385,24577);
 INF_DistExtra   : Array[0..29] Of Byte =
  (0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,
   7,7,8,8,9,9,10,10,11,11,12,12,13,13);
 INF_ClenOrder   : Array[0..18] Of Byte =
  (16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

Type
 THuffTable = Record
  Counts  : Array[0..15] Of Integer;
  Symbols : Array[0..287] Of Integer;
 End;

Var
 InfSrc      : ^Byte;
 InfSrcLeft  : LongInt;
 InfBitBuf   : Cardinal;
 InfBitCnt   : Integer;
 InfOutBase  : ^Byte;
 InfOutPtr   : ^Byte;
 InfOutPos   : LongInt;
 InfOutSize  : LongInt;
 InfErr      : Boolean;

Procedure InfFillByte;
Begin
 If InfSrcLeft <= 0 Then Begin InfErr := True; Exit; End;
 InfBitBuf := InfBitBuf Or (Cardinal(InfSrc^) Shl InfBitCnt);
 Inc(InfBitCnt, 8);
 Inc(InfSrc); Dec(InfSrcLeft);
End;

Function InfGetBits(N: Integer): LongInt;
Var V, Mask: Cardinal;
Begin
 While InfBitCnt < N Do Begin
  InfFillByte;
  If InfErr Then Begin InfGetBits := 0; Exit; End;
 End;
 If N = 0 Then Begin InfGetBits := 0; Exit; End;
 Mask := (Cardinal(1) Shl N) - 1;
 V := InfBitBuf And Mask;
 InfBitBuf := InfBitBuf Shr N;
 Dec(InfBitCnt, N);
 InfGetBits := V;
End;

Procedure InfAlignByte;
Var Drop: Integer;
Begin
 Drop := InfBitCnt And 7;
 If Drop > 0 Then Begin
  InfBitBuf := InfBitBuf Shr Drop;
  Dec(InfBitCnt, Drop);
 End;
End;

Procedure InfOutByte(B: Byte);
Begin
 If InfOutPos >= InfOutSize Then Begin InfErr := True; Exit; End;
 InfOutPtr^ := B;
 Inc(InfOutPtr); Inc(InfOutPos);
End;

Procedure InfCopyMatch(Dist, Len: LongInt);
Var I, SrcPos: LongInt; SP: ^Byte;
Begin
 If (Dist <= 0) Or (Dist > InfOutPos) Then Begin InfErr := True; Exit; End;
 SrcPos := InfOutPos - Dist;
 For I := 1 To Len Do Begin
  If InfOutPos >= InfOutSize Then Begin InfErr := True; Exit; End;
  SP := InfOutBase; Inc(SP, SrcPos);
  InfOutPtr^ := SP^;
  Inc(InfOutPtr); Inc(InfOutPos); Inc(SrcPos);
 End;
End;

Procedure InfBuildHuff(Var Lens: Array Of Integer; N: Integer;
                       Var H: THuffTable);
Var I: Integer; Offs: Array[0..15] Of Integer;
Begin
 For I := 0 To 15 Do H.Counts[I] := 0;
 For I := 0 To N-1 Do
  If (Lens[I] >= 0) And (Lens[I] <= 15) Then Inc(H.Counts[Lens[I]]);
 H.Counts[0] := 0;
 Offs[0] := 0; Offs[1] := 0;
 For I := 1 To 14 Do Offs[I+1] := Offs[I] + H.Counts[I];
 For I := 0 To N-1 Do
  If (Lens[I] > 0) And (Lens[I] <= 15) Then Begin
   H.Symbols[Offs[Lens[I]]] := I;
   Inc(Offs[Lens[I]]);
  End;
End;

Function InfDecodeSym(Var H: THuffTable): Integer;
Var Code, First, Count, Idx, Len, Bit: Integer;
Begin
 Code := 0; First := 0; Idx := 0;
 For Len := 1 To 15 Do Begin
  Bit := InfGetBits(1);
  Code := (Code Shl 1) Or Bit;
  Count := H.Counts[Len];
  If (Code - Count) < First Then Begin
   InfDecodeSym := H.Symbols[Idx + (Code - First)];
   Exit;
  End;
  Idx := Idx + Count;
  First := (First + Count) Shl 1;
 End;
 InfErr := True;
 InfDecodeSym := -1;
End;

Procedure InfBuildFixed(Var HLit, HDist: THuffTable);
Var Lens: Array[0..287] Of Integer;
    DLens: Array[0..29] Of Integer;
    I: Integer;
Begin
 For I := 0 To 143 Do Lens[I] := 8;
 For I := 144 To 255 Do Lens[I] := 9;
 For I := 256 To 279 Do Lens[I] := 7;
 For I := 280 To 287 Do Lens[I] := 8;
 InfBuildHuff(Lens, 288, HLit);
 For I := 0 To 29 Do DLens[I] := 5;
 InfBuildHuff(DLens, 30, HDist);
End;

Procedure InfReadDynHuff(Var HLit, HDist: THuffTable);
Var
 HLitN, HDistN, HCLenN: Integer;
 ClenLens : Array[0..18] Of Integer;
 LitLens  : Array[0..287] Of Integer;
 DistLens : Array[0..29]  Of Integer;
 AllLens  : Array[0..317] Of Integer;
 HClen    : THuffTable;
 I, Sym, Rep, Total: Integer;
Begin
 HLitN  := InfGetBits(5) + 257;
 HDistN := InfGetBits(5) + 1;
 HCLenN := InfGetBits(4) + 4;
 If (HLitN > 286) Or (HDistN > 30) Or (HCLenN > 19) Then Begin
  InfErr := True; Exit;
 End;
 For I := 0 To 18 Do ClenLens[I] := 0;
 For I := 0 To HCLenN-1 Do ClenLens[INF_ClenOrder[I]] := InfGetBits(3);
 InfBuildHuff(ClenLens, 19, HClen);
 If InfErr Then Exit;
 Total := HLitN + HDistN; I := 0;
 While I < Total Do Begin
  Sym := InfDecodeSym(HClen);
  If InfErr Then Exit;
  If Sym < 16 Then Begin
   AllLens[I] := Sym; Inc(I);
  End Else If Sym = 16 Then Begin
   If I = 0 Then Begin InfErr := True; Exit; End;
   Rep := InfGetBits(2) + 3;
   While (Rep > 0) And (I < Total) Do Begin
    AllLens[I] := AllLens[I-1]; Inc(I); Dec(Rep);
   End;
  End Else If Sym = 17 Then Begin
   Rep := InfGetBits(3) + 3;
   While (Rep > 0) And (I < Total) Do Begin
    AllLens[I] := 0; Inc(I); Dec(Rep);
   End;
  End Else If Sym = 18 Then Begin
   Rep := InfGetBits(7) + 11;
   While (Rep > 0) And (I < Total) Do Begin
    AllLens[I] := 0; Inc(I); Dec(Rep);
   End;
  End Else Begin InfErr := True; Exit; End;
 End;
 For I := 0 To HLitN-1  Do LitLens[I]  := AllLens[I];
 For I := 0 To HDistN-1 Do DistLens[I] := AllLens[HLitN+I];
 InfBuildHuff(LitLens,  HLitN,  HLit);
 InfBuildHuff(DistLens, HDistN, HDist);
End;

Function InflateBuf(Src: Pointer; SrcSize: LongInt;
                    Dst: Pointer; DstSize: LongInt): Boolean;
Var
 BFinal, BType: Integer;
 Len, NLen: Word;
 I: LongInt;
 HLit, HDist: THuffTable;
 Sym, LenIdx, DistIdx: Integer;
 MLen, MDist: LongInt;
Begin
 InfSrc := Src; InfSrcLeft := SrcSize;
 InfBitBuf := 0; InfBitCnt := 0;
 InfOutBase := Dst; InfOutPtr := Dst;
 InfOutPos := 0; InfOutSize := DstSize;
 InfErr := False;
 BFinal := 0;
 While (Not InfErr) And (BFinal = 0) Do Begin
  BFinal := InfGetBits(1);
  BType  := InfGetBits(2);
  If InfErr Then Break;
  Case BType Of
   0: Begin
       InfAlignByte;
       Len  := Word(InfGetBits(16));
       NLen := Word(InfGetBits(16));
       If LongInt(Len) + LongInt(NLen) <> 65535 Then Begin
        InfErr := True; Break;
       End;
       For I := 1 To Len Do Begin
        InfOutByte(Byte(InfGetBits(8)));
        If InfErr Then Break;
       End;
      End;
   1: Begin
       InfBuildFixed(HLit, HDist);
       While Not InfErr Do Begin
        Sym := InfDecodeSym(HLit);
        If InfErr Then Break;
        If Sym < 256 Then InfOutByte(Sym)
        Else If Sym = 256 Then Break
        Else Begin
         LenIdx  := Sym - 257;
         If LenIdx > 28 Then Begin InfErr := True; Break; End;
         MLen    := INF_LengthBase[LenIdx] + InfGetBits(INF_LengthExtra[LenIdx]);
         DistIdx := InfDecodeSym(HDist);
         If (DistIdx < 0) Or (DistIdx > 29) Then Begin InfErr := True; Break; End;
         MDist   := INF_DistBase[DistIdx] + InfGetBits(INF_DistExtra[DistIdx]);
         InfCopyMatch(MDist, MLen);
        End;
       End;
      End;
   2: Begin
       InfReadDynHuff(HLit, HDist);
       If InfErr Then Break;
       While Not InfErr Do Begin
        Sym := InfDecodeSym(HLit);
        If InfErr Then Break;
        If Sym < 256 Then InfOutByte(Sym)
        Else If Sym = 256 Then Break
        Else Begin
         LenIdx  := Sym - 257;
         If LenIdx > 28 Then Begin InfErr := True; Break; End;
         MLen    := INF_LengthBase[LenIdx] + InfGetBits(INF_LengthExtra[LenIdx]);
         DistIdx := InfDecodeSym(HDist);
         If (DistIdx < 0) Or (DistIdx > 29) Then Begin InfErr := True; Break; End;
         MDist   := INF_DistBase[DistIdx] + InfGetBits(INF_DistExtra[DistIdx]);
         InfCopyMatch(MDist, MLen);
        End;
       End;
      End;
  Else
   InfErr := True;
  End;
 End;
 InflateBuf := Not InfErr;
End;

{ ----------------- DEFLATE encoder (stored) ---------------- }

Function DeflateStored(Src: Pointer; SrcSize: LongInt;
                       Var Dst: Pointer; Var DstSize: LongInt): Boolean;
Var
 BlocksNeeded, OutSize, Pos, ChunkLen: LongInt;
 PB, PS: ^Byte;
 LastBlock: Boolean;
 Hdr: Byte;
 W, NW: Word;
Begin
 If SrcSize < 0 Then Begin DeflateStored := False; Exit; End;
 BlocksNeeded := (SrcSize + 65534) Div 65535;
 If BlocksNeeded < 1 Then BlocksNeeded := 1;
 OutSize := SrcSize + 5 * BlocksNeeded;
 GetMem(Dst, OutSize);
 PB := Dst; PS := Src;
 Pos := 0;
 Repeat
  If SrcSize - Pos > 65535 Then ChunkLen := 65535
  Else                          ChunkLen := SrcSize - Pos;
  LastBlock := (Pos + ChunkLen >= SrcSize);
  If LastBlock Then Hdr := 1 Else Hdr := 0;
  PB^ := Hdr; Inc(PB);
  W  := Word(ChunkLen);
  NW := 65535 - W;
  PB^ := Byte(W And $FF);   Inc(PB);
  PB^ := Byte(W Shr 8);     Inc(PB);
  PB^ := Byte(NW And $FF);  Inc(PB);
  PB^ := Byte(NW Shr 8);    Inc(PB);
  If ChunkLen > 0 Then Begin
   Move(PS^, PB^, ChunkLen);
   Inc(PB, ChunkLen);
   Inc(PS, ChunkLen);
  End;
  Inc(Pos, ChunkLen);
 Until LastBlock;
 DstSize := OutSize;
 DeflateStored := True;
End;

{ -------------------- ZIP container ------------------------ }

Const
 MAX_ZIP_ENTRIES = 256;
 ZIP_SIG_LFH    = LongInt($04034B50);
 ZIP_SIG_CDH    = LongInt($02014B50);
 ZIP_SIG_EOCD   = LongInt($06054B50);

Type
 TZipEntry = Record
  Name       : String[80];
  Method     : Word;
  CRC32      : Cardinal;
  CompSize   : LongInt;
  UncompSize : LongInt;
  LFHOffset  : LongInt;
 End;

 TZipReader = Record
  F          : File;
  IsOpen     : Boolean;
  EntryCount : Integer;
  Entries    : Array[1..MAX_ZIP_ENTRIES] Of TZipEntry;
 End;

 TZipWriter = Record
  F          : File;
  IsOpen     : Boolean;
  EntryCount : Integer;
  Entries    : Array[1..MAX_ZIP_ENTRIES] Of TZipEntry;
 End;

Procedure ZipWriteWord(Var F: File; W: Word);
Begin BlockWrite(F, W, 2); End;

Procedure ZipWriteLong(Var F: File; L: LongInt);
Begin BlockWrite(F, L, 4); End;

Function ZipRead_Open(Var Z: TZipReader; Const FName: String): Boolean;
Var
 FileLen, ScanStart, ScanLen, EOCDPos: LongInt;
 Buf       : Array[0..4095] Of Byte;
 BufLen, I : LongInt;
 NEntries  : Word;
 CDOff, CDSize : LongInt;
 EntrySig, EntryCSize, EntryUSize, EntryLFHOff: LongInt;
 EntryCRC  : Cardinal;
 EntryMethod, EntryFlen, EntryExtra, EntryComment: Word;
 NameBuf   : Array[0..255] Of Byte;
 N, P      : Integer;
 Idx       : Integer;
Begin
 ZipRead_Open := False;
 Z.IsOpen := False; Z.EntryCount := 0;
 {$I-} Assign(Z.F, FName); Reset(Z.F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 FileLen := FileSize(Z.F);
 If FileLen < 22 Then Begin Close(Z.F); Exit; End;
 { Recherche EOCD dans les derniers 4096 octets (suffisant si pas de commentaire) }
 If FileLen > 4096 Then ScanStart := FileLen - 4096
 Else                   ScanStart := 0;
 ScanLen := FileLen - ScanStart;
 Seek(Z.F, ScanStart);
 BlockRead(Z.F, Buf, ScanLen, BufLen);
 If BufLen < 22 Then Begin Close(Z.F); Exit; End;
 EOCDPos := -1;
 For I := BufLen - 22 Downto 0 Do
  If (Buf[I]=$50) And (Buf[I+1]=$4B) And
     (Buf[I+2]=$05) And (Buf[I+3]=$06) Then Begin
   EOCDPos := ScanStart + I; Break;
  End;
 If EOCDPos < 0 Then Begin Close(Z.F); Exit; End;
 Seek(Z.F, EOCDPos + 10);
 BlockRead(Z.F, NEntries, 2);
 BlockRead(Z.F, CDSize, 4);
 BlockRead(Z.F, CDOff, 4);
 If NEntries > MAX_ZIP_ENTRIES Then Begin Close(Z.F); Exit; End;
 Z.EntryCount := NEntries;
 Seek(Z.F, CDOff);
 For Idx := 1 To NEntries Do Begin
  BlockRead(Z.F, EntrySig, 4);
  If EntrySig <> ZIP_SIG_CDH Then Begin Close(Z.F); Exit; End;
  Seek(Z.F, FilePos(Z.F) + 4); { version made + needed }
  Seek(Z.F, FilePos(Z.F) + 2); { flags }
  BlockRead(Z.F, EntryMethod, 2);
  Seek(Z.F, FilePos(Z.F) + 4); { time + date }
  BlockRead(Z.F, EntryCRC, 4);
  BlockRead(Z.F, EntryCSize, 4);
  BlockRead(Z.F, EntryUSize, 4);
  BlockRead(Z.F, EntryFlen, 2);
  BlockRead(Z.F, EntryExtra, 2);
  BlockRead(Z.F, EntryComment, 2);
  Seek(Z.F, FilePos(Z.F) + 8); { disk + internal + external attrs }
  BlockRead(Z.F, EntryLFHOff, 4);
  N := EntryFlen; If N > 255 Then N := 255;
  If N > 0 Then BlockRead(Z.F, NameBuf, N);
  If EntryFlen > N Then Seek(Z.F, FilePos(Z.F) + (EntryFlen - N));
  If N > 80 Then N := 80;
  Z.Entries[Idx].Name[0] := Char(N);
  For P := 1 To N Do Z.Entries[Idx].Name[P] := Char(NameBuf[P-1]);
  Z.Entries[Idx].Method := EntryMethod;
  Z.Entries[Idx].CRC32  := EntryCRC;
  Z.Entries[Idx].CompSize   := EntryCSize;
  Z.Entries[Idx].UncompSize := EntryUSize;
  Z.Entries[Idx].LFHOffset  := EntryLFHOff;
  Seek(Z.F, FilePos(Z.F) + EntryExtra + EntryComment);
 End;
 Z.IsOpen := True;
 ZipRead_Open := True;
End;

Function ZipRead_Find(Var Z: TZipReader; Const Name: String): Integer;
Var I: Integer;
Begin
 ZipRead_Find := -1;
 For I := 1 To Z.EntryCount Do
  If Z.Entries[I].Name = Name Then Begin
   ZipRead_Find := I; Exit;
  End;
End;

Function ZipRead_Extract(Var Z: TZipReader; Idx: Integer;
                          Var Buf: Pointer; Var Size: LongInt): Boolean;
Var
 FLen, ExtraLen, Method: Word;
 CompBuf: Pointer;
 CSize, USize: LongInt;
 OK: Boolean;
Begin
 ZipRead_Extract := False;
 Buf := Nil; Size := 0;
 If (Idx < 1) Or (Idx > Z.EntryCount) Or (Not Z.IsOpen) Then Exit;
 Method := Z.Entries[Idx].Method;
 CSize  := Z.Entries[Idx].CompSize;
 USize  := Z.Entries[Idx].UncompSize;
 Seek(Z.F, Z.Entries[Idx].LFHOffset + 26);
 BlockRead(Z.F, FLen, 2);
 BlockRead(Z.F, ExtraLen, 2);
 Seek(Z.F, Z.Entries[Idx].LFHOffset + 30 + FLen + ExtraLen);
 If Method = 0 Then Begin
  GetMem(Buf, USize);
  If USize > 0 Then BlockRead(Z.F, Buf^, USize);
  Size := USize;
  ZipRead_Extract := True;
 End
 Else If Method = 8 Then Begin
  If CSize <= 0 Then Begin
   GetMem(Buf, USize);
   Size := USize;
   ZipRead_Extract := True;
   Exit;
  End;
  GetMem(CompBuf, CSize);
  BlockRead(Z.F, CompBuf^, CSize);
  GetMem(Buf, USize);
  OK := InflateBuf(CompBuf, CSize, Buf, USize);
  FreeMem(CompBuf, CSize);
  If OK Then Begin
   Size := USize;
   ZipRead_Extract := True;
  End Else Begin
   FreeMem(Buf, USize);
   Buf := Nil;
  End;
 End;
End;

Procedure ZipRead_Close(Var Z: TZipReader);
Begin
 If Z.IsOpen Then Begin
  Close(Z.F);
  Z.IsOpen := False;
 End;
End;

Function ZipWrite_Create(Var Z: TZipWriter; Const FName: String): Boolean;
Begin
 Z.IsOpen := False; Z.EntryCount := 0;
 {$I-} Assign(Z.F, FName); Rewrite(Z.F, 1); {$I+}
 If IOResult <> 0 Then Begin ZipWrite_Create := False; Exit; End;
 Z.IsOpen := True;
 ZipWrite_Create := True;
End;

Function ZipWrite_AddStored(Var Z: TZipWriter; Const Name: String;
                              Buf: Pointer; Size: LongInt): Boolean;
Var
 LFHOff: LongInt;
 CRC: Cardinal;
 Idx: Integer;
Begin
 ZipWrite_AddStored := False;
 If (Not Z.IsOpen) Or (Z.EntryCount >= MAX_ZIP_ENTRIES) Then Exit;
 If Length(Name) > 80 Then Exit;
 LFHOff := FilePos(Z.F);
 CRC := CRC32Of(Buf, Size);
 ZipWriteLong(Z.F, ZIP_SIG_LFH);
 ZipWriteWord(Z.F, 20);    { version needed }
 ZipWriteWord(Z.F, 0);     { flags }
 ZipWriteWord(Z.F, 0);     { method = stored }
 ZipWriteWord(Z.F, 0);     { mod time }
 ZipWriteWord(Z.F, 33);    { mod date 1980-01-01 }
 ZipWriteLong(Z.F, LongInt(CRC));
 ZipWriteLong(Z.F, Size);
 ZipWriteLong(Z.F, Size);
 ZipWriteWord(Z.F, Length(Name));
 ZipWriteWord(Z.F, 0);     { extra len }
 If Length(Name) > 0 Then BlockWrite(Z.F, Name[1], Length(Name));
 If Size > 0 Then BlockWrite(Z.F, Buf^, Size);
 Inc(Z.EntryCount); Idx := Z.EntryCount;
 Z.Entries[Idx].Name       := Name;
 Z.Entries[Idx].Method     := 0;
 Z.Entries[Idx].CRC32      := CRC;
 Z.Entries[Idx].CompSize   := Size;
 Z.Entries[Idx].UncompSize := Size;
 Z.Entries[Idx].LFHOffset  := LFHOff;
 ZipWrite_AddStored := True;
End;

Function ZipWrite_AddDeflate(Var Z: TZipWriter; Const Name: String;
                               Buf: Pointer; Size: LongInt): Boolean;
Var
 LFHOff, CompSize: LongInt;
 Comp: Pointer;
 CRC: Cardinal;
 Idx: Integer;
Begin
 ZipWrite_AddDeflate := False;
 If (Not Z.IsOpen) Or (Z.EntryCount >= MAX_ZIP_ENTRIES) Then Exit;
 If Length(Name) > 80 Then Exit;
 If Not DeflateStored(Buf, Size, Comp, CompSize) Then Exit;
 LFHOff := FilePos(Z.F);
 CRC := CRC32Of(Buf, Size);
 ZipWriteLong(Z.F, ZIP_SIG_LFH);
 ZipWriteWord(Z.F, 20);
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, 8);     { method = deflate }
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, 33);
 ZipWriteLong(Z.F, LongInt(CRC));
 ZipWriteLong(Z.F, CompSize);
 ZipWriteLong(Z.F, Size);
 ZipWriteWord(Z.F, Length(Name));
 ZipWriteWord(Z.F, 0);
 If Length(Name) > 0 Then BlockWrite(Z.F, Name[1], Length(Name));
 If CompSize > 0 Then BlockWrite(Z.F, Comp^, CompSize);
 FreeMem(Comp, CompSize);
 Inc(Z.EntryCount); Idx := Z.EntryCount;
 Z.Entries[Idx].Name       := Name;
 Z.Entries[Idx].Method     := 8;
 Z.Entries[Idx].CRC32      := CRC;
 Z.Entries[Idx].CompSize   := CompSize;
 Z.Entries[Idx].UncompSize := Size;
 Z.Entries[Idx].LFHOffset  := LFHOff;
 ZipWrite_AddDeflate := True;
End;

Function ZipWrite_Finish(Var Z: TZipWriter): Boolean;
Var
 CDStart, CDEnd, CDSize: LongInt;
 I: Integer;
 NLen: Word;
Begin
 ZipWrite_Finish := False;
 If Not Z.IsOpen Then Exit;
 CDStart := FilePos(Z.F);
 For I := 1 To Z.EntryCount Do Begin
  ZipWriteLong(Z.F, ZIP_SIG_CDH);
  ZipWriteWord(Z.F, 20);                       { version made by }
  ZipWriteWord(Z.F, 20);                       { version needed }
  ZipWriteWord(Z.F, 0);                        { flags }
  ZipWriteWord(Z.F, Z.Entries[I].Method);
  ZipWriteWord(Z.F, 0);                        { mod time }
  ZipWriteWord(Z.F, 33);                       { mod date }
  ZipWriteLong(Z.F, LongInt(Z.Entries[I].CRC32));
  ZipWriteLong(Z.F, Z.Entries[I].CompSize);
  ZipWriteLong(Z.F, Z.Entries[I].UncompSize);
  NLen := Length(Z.Entries[I].Name);
  ZipWriteWord(Z.F, NLen);
  ZipWriteWord(Z.F, 0);                        { extra }
  ZipWriteWord(Z.F, 0);                        { comment }
  ZipWriteWord(Z.F, 0);                        { disk# }
  ZipWriteWord(Z.F, 0);                        { internal attrs }
  ZipWriteLong(Z.F, 0);                        { external attrs }
  ZipWriteLong(Z.F, Z.Entries[I].LFHOffset);
  If NLen > 0 Then BlockWrite(Z.F, Z.Entries[I].Name[1], NLen);
 End;
 CDEnd  := FilePos(Z.F);
 CDSize := CDEnd - CDStart;
 ZipWriteLong(Z.F, ZIP_SIG_EOCD);
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, Z.EntryCount);
 ZipWriteWord(Z.F, Z.EntryCount);
 ZipWriteLong(Z.F, CDSize);
 ZipWriteLong(Z.F, CDStart);
 ZipWriteWord(Z.F, 0);
 {$I-} Close(Z.F); {$I+}
 Z.IsOpen := False;
 If IOResult <> 0 Then Exit;
 ZipWrite_Finish := True;
End;

{ ============================================================ }
{ ====================  INIT DOCUMENT  ======================= }
{ ============================================================ }

Procedure InitDocument;
Begin
 FreeAllDocImages;
 FillChar(Doc, SizeOf(Doc), 0);
 Doc.ParaCount := 1;
 Doc.PageCount := 1;
 Doc.FileName  := 'Document1';
 Doc.Modified  := False;
 Doc.Paragraphs[1].RunCount := 1;
 Doc.Paragraphs[1].Alignment := ALIGN_LEFT;
 Doc.Paragraphs[1].Runs[1].Text := '';
 Doc.Paragraphs[1].Runs[1].Style.FontSize := 12;
 Doc.Paragraphs[1].Runs[1].Style.Style := 0;
 Doc.Paragraphs[1].Runs[1].Style.Color := Black;

 CurrentStyle.FontSize := 12;
 CurrentStyle.Style    := 0;
 CurrentStyle.Color    := Black;
 CurrentAlign          := ALIGN_LEFT;
 CurrentPage           := 1;
 ScrollY               := 0;

 Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;

 NeedsRelayout  := True;
 CursorBlinkOn  := True;
 CursorBlinkCnt := 0;
End;

Procedure DrawDocArea;
Var
 PX1, PY1, PX2, PY2 : Integer;
 P                  : Integer;
 YStart             : Integer;
Begin
 { Fond zone document }
 FillRectArea(0, DOCAREA_TOP, SCREEN_W-1, DOCAREA_BOTTOM, DOCAREA_BG);

 { Page centr??e horizontalement, position verticale d??pend de CurrentPage }
 PX1 := (SCREEN_W - PAGE_W) Div 2;
 YStart := DOCAREA_TOP + 8;

 For P := 1 To Doc.PageCount Do Begin
  PY1 := YStart + (P-1) * (PAGE_H + 12) - ScrollY;
  PY2 := PY1 + PAGE_H;
  PX2 := PX1 + PAGE_W;

  { Skip si enti??rement hors zone }
  If (PY2 < DOCAREA_TOP) Or (PY1 > DOCAREA_BOTTOM) Then Continue;

  { Ombre droite et bas }
  FillRectArea(PX2+1, PY1+3, PX2+3, PY2+3, PAGE_SHADOW);
  FillRectArea(PX1+3, PY2+1, PX2+3, PY2+3, PAGE_SHADOW);

  { Page blanche }
  FillRectArea(PX1, PY1, PX2, PY2, PAGE_BG);
  DrawFrameRect(PX1, PY1, PX2, PY2, PAGE_BORDER);

  { Marges en pointill??s discrets }
  SetColor(LightGray);
  Rectangle(PX1+PAGE_MARGIN_L, PY1+PAGE_MARGIN_T,
            PX2-PAGE_MARGIN_R, PY2-PAGE_MARGIN_B);

  { Num??ro de page en bas }
  SetColor(DarkGray);
  Str(P, StatusMsg);    { r??utilisation tampon }
  StatusMsg := 'Page ' + StatusMsg;
  OutTextXY(PX1 + PAGE_W Div 2 - TextWidth(StatusMsg) Div 2,
            PY2-12, StatusMsg);
 End;
 StatusMsg := '';

 { ----- Texte du document + curseur ----- }
 RenderDocText;
 RenderSelection;
 RenderTextCursor;
End;

Procedure DrawStatusBar;
Var
 PageStr  : String[40];
 LineColS : String[40];
 SP, SC   : String[12];
 SL, SCo  : String[12];
 L, Col   : Integer;
Begin
 FillRectArea(0, STATUSBAR_TOP, SCREEN_W-1,
              STATUSBAR_TOP+STATUSBAR_HEIGHT-1, STATUSBAR_BG);
 DrawHLine(0, SCREEN_W-1, STATUSBAR_TOP, CLR_3D_LIGHT);

 Str(CurrentPage, SP);
 Str(Doc.PageCount, SC);
 PageStr := 'Page ' + SP + ' of ' + SC;
 DrawTextAt(8, STATUSBAR_TOP+5, PageStr, STATUSBAR_FG);

 L := FindCursorVLine;
 If L > 0 Then Begin
  Col := Cursor.CharIdx - (VLines[L].CharStart - 1) + 1;
  Str(L, SL);
  Str(Col, SCo);
  LineColS := 'Ln ' + SL + '  Col ' + SCo;
  DrawTextAt(96, STATUSBAR_TOP+5, LineColS, STATUSBAR_FG);
 End;

 DrawTextAt(220, STATUSBAR_TOP+5, StatusMsg, STATUSBAR_FG);

 If Doc.Modified Then
  DrawTextAt(SCREEN_W-50, STATUSBAR_TOP+5, '[MOD]', Red);
End;

{ ============================================================ }
{ =====================  GESTION ACTIONS  ==================== }
{ ============================================================ }

Procedure ShowMessage(Const S: String); Forward;

{ ============================================================ }
{ ===================  PHASE 5 - I/O WPD  ==================== }
{ ============================================================ }
{ Format binaire .WPD :                                         }
{   Offset  Taille  Contenu                                     }
{   0       6       Magic 'WPDOC1'                              }
{   6       2       Version (Word LE) = 1                       }
{   8       2       ParaCount (Word LE)                         }
{   Pour chaque paragraphe :                                    }
{     1     Alignment (Byte)                                    }
{     1     PageBreakBefore (0/1)                               }
{     1     RunCount (Byte)                                     }
{     Pour chaque run :                                         }
{       1   FontSize / 1 Style / 1 Color / 1 TextLen (Byte)     }
{       N   Text (TextLen octets)                               }
{ ============================================================ }

Procedure EnsureWPDExt(Var FN: String);
Var I, DotPos : Integer;
Begin
 DotPos := 0;
 For I := Length(FN) Downto 1 Do
  If FN[I] = '.' Then Begin DotPos := I; Break; End;
 If DotPos = 0 Then FN := FN + '.WPD';
End;

Function SaveDocumentToFile(Const FName: String): Boolean;
Var
 F          : File;
 P, R       : Integer;
 B, RunCnt  : Byte;
 TextLen    : Byte;
 W          : Word;
 Magic      : Array[1..6] Of Char;
 OK         : Boolean;
 S          : String;
 ImgBytes   : LongInt;
Begin
 OK := True;
 Magic[1]:='W'; Magic[2]:='P'; Magic[3]:='D';
 Magic[4]:='O'; Magic[5]:='C'; Magic[6]:='1';
 {$I-} Assign(F, FName); Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin SaveDocumentToFile := False; Exit; End;
 BlockWrite(F, Magic, 6);
 W := 2;             BlockWrite(F, W, 2);     { version 2 = avec images }
 W := Doc.ParaCount; BlockWrite(F, W, 2);
 For P := 1 To Doc.ParaCount Do Begin
  B := Doc.Paragraphs[P].Alignment;                BlockWrite(F, B, 1);
  If Doc.Paragraphs[P].PageBreakBefore Then B:=1 Else B:=0;
  BlockWrite(F, B, 1);
  If Doc.Paragraphs[P].IsImage Then B:=1 Else B:=0;
  BlockWrite(F, B, 1);
  If Doc.Paragraphs[P].IsImage Then Begin
   W := Doc.Paragraphs[P].ImgW; BlockWrite(F, W, 2);
   W := Doc.Paragraphs[P].ImgH; BlockWrite(F, W, 2);
   ImgBytes := LongInt(Doc.Paragraphs[P].ImgW) * Doc.Paragraphs[P].ImgH;
   If (ImgBytes > 0) And (Doc.Paragraphs[P].ImgData <> Nil) Then
    BlockWrite(F, Doc.Paragraphs[P].ImgData^, ImgBytes);
   Continue;
  End;
  RunCnt := Doc.Paragraphs[P].RunCount;            BlockWrite(F, RunCnt, 1);
  For R := 1 To Doc.Paragraphs[P].RunCount Do Begin
   B := Doc.Paragraphs[P].Runs[R].Style.FontSize;  BlockWrite(F, B, 1);
   B := Doc.Paragraphs[P].Runs[R].Style.Style;     BlockWrite(F, B, 1);
   B := Doc.Paragraphs[P].Runs[R].Style.Color;     BlockWrite(F, B, 1);
   S := Doc.Paragraphs[P].Runs[R].Text;
   TextLen := Length(S);                           BlockWrite(F, TextLen, 1);
   If TextLen > 0 Then BlockWrite(F, S[1], TextLen);
  End;
 End;
 {$I-} Close(F); {$I+}
 If IOResult <> 0 Then OK := False;
 SaveDocumentToFile := OK;
End;

Function LoadDocumentFromFile(Const FName: String): Boolean;
Var
 F        : File;
 Magic    : Array[1..6] Of Char;
 V, PCnt  : Word;
 P, R, I  : Integer;
 B, RunCnt: Byte;
 TextLen  : Byte;
 Buf      : Array[0..255] Of Byte;
 S        : String;
 IsImg    : Byte;
 IW, IH   : Word;
 ImgBytes : LongInt;
 ImgPtr   : Pointer;
Begin
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin LoadDocumentFromFile := False; Exit; End;
 BlockRead(F, Magic, 6);
 If (Magic[1]<>'W') Or (Magic[2]<>'P') Or (Magic[3]<>'D') Or
    (Magic[4]<>'O') Or (Magic[5]<>'C') Or (Magic[6]<>'1') Then Begin
  Close(F); LoadDocumentFromFile := False; Exit;
 End;
 BlockRead(F, V, 2);
 BlockRead(F, PCnt, 2);
 If (PCnt < 1) Or (PCnt > MAX_PARAS_PER_DOC) Then Begin
  Close(F); LoadDocumentFromFile := False; Exit;
 End;
 FreeAllDocImages;
 FillChar(Doc, SizeOf(Doc), 0);
 Doc.ParaCount := PCnt;
 Doc.PageCount := 1;
 For P := 1 To PCnt Do Begin
  BlockRead(F, B, 1); Doc.Paragraphs[P].Alignment      := B;
  BlockRead(F, B, 1); Doc.Paragraphs[P].PageBreakBefore:= B <> 0;
  IsImg := 0;
  If V >= 2 Then BlockRead(F, IsImg, 1);
  If IsImg <> 0 Then Begin
   BlockRead(F, IW, 2); BlockRead(F, IH, 2);
   If (IW = 0) Or (IH = 0) Or (IW > MAX_IMG_W) Or (IH > MAX_IMG_H) Then Begin
    Close(F); LoadDocumentFromFile := False; Exit;
   End;
   ImgBytes := LongInt(IW) * IH;
   GetMem(ImgPtr, ImgBytes);
   BlockRead(F, ImgPtr^, ImgBytes);
   Doc.Paragraphs[P].IsImage := True;
   Doc.Paragraphs[P].ImgW    := IW;
   Doc.Paragraphs[P].ImgH    := IH;
   Doc.Paragraphs[P].ImgData := ImgPtr;
   Doc.Paragraphs[P].RunCount := 0;
   Continue;
  End;
  BlockRead(F, RunCnt, 1);
  If RunCnt > MAX_RUNS_PER_PARA Then RunCnt := MAX_RUNS_PER_PARA;
  Doc.Paragraphs[P].RunCount := RunCnt;
  For R := 1 To RunCnt Do Begin
   BlockRead(F, B, 1); Doc.Paragraphs[P].Runs[R].Style.FontSize := B;
   BlockRead(F, B, 1); Doc.Paragraphs[P].Runs[R].Style.Style    := B;
   BlockRead(F, B, 1); Doc.Paragraphs[P].Runs[R].Style.Color    := B;
   BlockRead(F, TextLen, 1);
   S := '';
   If TextLen > 0 Then Begin
    BlockRead(F, Buf, TextLen);
    If TextLen > MAX_TEXT_LEN Then TextLen := MAX_TEXT_LEN;
    S[0] := Char(TextLen);
    For I := 1 To TextLen Do S[I] := Char(Buf[I-1]);
   End;
   Doc.Paragraphs[P].Runs[R].Text := S;
  End;
 End;
 Close(F);
 Doc.FileName   := FName;
 Doc.Modified   := False;
 Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 ScrollY        := 0;
 CurrentPage    := 1;
 NeedsRelayout  := True;
 LoadDocumentFromFile := True;
End;

{ ============================================================ }
{ ===================  PHASE 8 - DOCX I/O  =================== }
{ ============================================================ }
{ DOCX = ZIP contenant au minimum :                             }
{   [Content_Types].xml                                         }
{   _rels/.rels                                                 }
{   word/document.xml  (le seul reellement parse)               }
{                                                               }
{ Mapping :                                                     }
{  <w:p><w:pPr><w:jc w:val="left|center|right|both"/>           }
{    <w:pageBreakBefore/></w:pPr>                               }
{   <w:r><w:rPr><w:b/><w:i/><w:u w:val="single"/>               }
{       <w:sz w:val="N"/></w:rPr>                               }
{    <w:t xml:space="preserve">texte</w:t></w:r>                }
{   <w:r><w:br w:type="page"/></w:r>  --> PageBreakBefore       }
{                       sur le paragraphe suivant.              }
{  </w:p>                                                       }
{ Les images ne sont pas exportees (paragraphes images = vides).}
{ ============================================================ }

Type
 TByteBuf = Record
  Data : Pointer;
  Size : LongInt;
  Cap  : LongInt;
 End;

Procedure BufInit(Var B: TByteBuf);
Begin
 B.Data := Nil; B.Size := 0; B.Cap := 0;
End;

Procedure BufFree(Var B: TByteBuf);
Begin
 If B.Data <> Nil Then FreeMem(B.Data, B.Cap);
 B.Data := Nil; B.Size := 0; B.Cap := 0;
End;

Procedure BufEnsure(Var B: TByteBuf; Need: LongInt);
Var
 NewCap : LongInt;
 NewPtr : Pointer;
 Dst    : ^Byte;
Begin
 If Need <= B.Cap Then Exit;
 NewCap := B.Cap;
 If NewCap < 512 Then NewCap := 512;
 While NewCap < Need Do NewCap := NewCap * 2;
 GetMem(NewPtr, NewCap);
 If (B.Data <> Nil) And (B.Size > 0) Then Begin
  Dst := NewPtr;
  Move(B.Data^, Dst^, B.Size);
 End;
 If B.Data <> Nil Then FreeMem(B.Data, B.Cap);
 B.Data := NewPtr; B.Cap := NewCap;
End;

Procedure BufAppendBytes(Var B: TByteBuf; P: Pointer; N: LongInt);
Var Dst: ^Byte;
Begin
 If N <= 0 Then Exit;
 BufEnsure(B, B.Size + N);
 Dst := B.Data; Inc(Dst, B.Size);
 Move(P^, Dst^, N);
 Inc(B.Size, N);
End;

Procedure BufAppendStr(Var B: TByteBuf; Const S: String);
Begin
 If Length(S) > 0 Then BufAppendBytes(B, @S[1], Length(S));
End;

Procedure BufAppendXmlText(Var B: TByteBuf; Const S: String);
Var I: Integer; C: Char; Tmp: Byte;
Begin
 For I := 1 To Length(S) Do Begin
  C := S[I];
  Case C Of
   '&': BufAppendStr(B, '&amp;');
   '<': BufAppendStr(B, '&lt;');
   '>': BufAppendStr(B, '&gt;');
   '"': BufAppendStr(B, '&quot;');
   #39: BufAppendStr(B, '&apos;');
  Else
   Tmp := Byte(C);
   BufAppendBytes(B, @Tmp, 1);
  End;
 End;
End;

{ ---------- Lexer XML minimal (sur buffer) ---------- }

Const
 DTK_EOF   = 0;
 DTK_TEXT  = 1;
 DTK_START = 2;
 DTK_END   = 3;
 DTK_EMPTY = 4;

Var
 DocxBuf  : Pointer;
 DocxPos  : LongInt;
 DocxSize : LongInt;
 TokKind  : Integer;
 TokName  : String;
 TokAttrs : String;
 TokText  : String;

Function DocxByte(Pos: LongInt): Byte;
Var P: ^Byte;
Begin
 P := DocxBuf; Inc(P, Pos); DocxByte := P^;
End;

Function DocxDecodeEntity(Const E: String): String;
Begin
 If      E = 'amp'  Then DocxDecodeEntity := '&'
 Else If E = 'lt'   Then DocxDecodeEntity := '<'
 Else If E = 'gt'   Then DocxDecodeEntity := '>'
 Else If E = 'quot' Then DocxDecodeEntity := '"'
 Else If E = 'apos' Then DocxDecodeEntity := #39
 Else DocxDecodeEntity := '';
End;

Function DocxDecodeText(Const S: String): String;
Var I, J: Integer; R, E, Dec1: String;
Begin
 R := ''; I := 1;
 While I <= Length(S) Do Begin
  If S[I] = '&' Then Begin
   J := I + 1; E := '';
   While (J <= Length(S)) And (S[J] <> ';') And (Length(E) < 8) Do Begin
    E := E + S[J]; Inc(J);
   End;
   If (J <= Length(S)) And (S[J] = ';') Then Begin
    Dec1 := DocxDecodeEntity(E);
    If (Length(R) + Length(Dec1)) <= 255 Then R := R + Dec1;
    I := J + 1;
   End Else Begin
    If Length(R) < 255 Then R := R + '&';
    Inc(I);
   End;
  End Else Begin
   If Length(R) < 255 Then R := R + S[I];
   Inc(I);
  End;
 End;
 DocxDecodeText := R;
End;

Procedure DocxNextToken;
Var
 Ch      : Char;
 First, I: LongInt;
 Tag     : String;
 HasSlash: Boolean;
 K       : Integer;
Begin
 TokKind := DTK_EOF; TokName := ''; TokAttrs := ''; TokText := '';
 If DocxPos >= DocxSize Then Exit;
 Ch := Char(DocxByte(DocxPos));
 If Ch = '<' Then Begin
  Inc(DocxPos);
  If DocxPos >= DocxSize Then Exit;
  Ch := Char(DocxByte(DocxPos));
  { <?xml ... ?> : skip jusqu'a ?> }
  If Ch = '?' Then Begin
   While DocxPos + 1 < DocxSize Do Begin
    If (DocxByte(DocxPos) = Byte('?')) And (DocxByte(DocxPos+1) = Byte('>')) Then Begin
     Inc(DocxPos, 2); Break;
    End;
    Inc(DocxPos);
   End;
   DocxNextToken; Exit;
  End;
  { <!-- --> ou <![CDATA[ ]]> ou <!DOCTYPE ...> }
  If Ch = '!' Then Begin
   If (DocxPos+2 < DocxSize) And
      (DocxByte(DocxPos+1) = Byte('-')) And
      (DocxByte(DocxPos+2) = Byte('-')) Then Begin
    Inc(DocxPos, 3);
    While DocxPos + 2 < DocxSize Do Begin
     If (DocxByte(DocxPos) = Byte('-')) And
        (DocxByte(DocxPos+1) = Byte('-')) And
        (DocxByte(DocxPos+2) = Byte('>')) Then Begin
      Inc(DocxPos, 3); Break;
     End;
     Inc(DocxPos);
    End;
   End Else If (DocxPos+7 < DocxSize) And (DocxByte(DocxPos+1) = Byte('[')) Then Begin
    Inc(DocxPos, 8);  { sauter ![CDATA[ }
    First := DocxPos;
    While DocxPos + 2 < DocxSize Do Begin
     If (DocxByte(DocxPos) = Byte(']')) And
        (DocxByte(DocxPos+1) = Byte(']')) And
        (DocxByte(DocxPos+2) = Byte('>')) Then Begin
      Tag := '';
      For I := First To DocxPos - 1 Do
       If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(I));
      Inc(DocxPos, 3);
      TokKind := DTK_TEXT; TokText := Tag;
      Exit;
     End;
     Inc(DocxPos);
    End;
   End Else Begin
    While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('>')) Do Inc(DocxPos);
    If DocxPos < DocxSize Then Inc(DocxPos);
   End;
   DocxNextToken; Exit;
  End;
  { </name> }
  If Ch = '/' Then Begin
   Inc(DocxPos);
   Tag := '';
   While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('>')) Do Begin
    If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(DocxPos));
    Inc(DocxPos);
   End;
   If DocxPos < DocxSize Then Inc(DocxPos);
   While (Length(Tag) > 0) And
         ((Tag[Length(Tag)] = ' ') Or (Tag[Length(Tag)] = #9) Or
          (Tag[Length(Tag)] = #10) Or (Tag[Length(Tag)] = #13)) Do
    Dec(Tag[0]);
   TokKind := DTK_END; TokName := Tag; Exit;
  End;
  { Start ou empty }
  Tag := '';
  While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('>')) Do Begin
   If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(DocxPos));
   Inc(DocxPos);
  End;
  If DocxPos < DocxSize Then Inc(DocxPos);
  HasSlash := False;
  If (Length(Tag) > 0) And (Tag[Length(Tag)] = '/') Then Begin
   HasSlash := True; Dec(Tag[0]);
   While (Length(Tag) > 0) And
         ((Tag[Length(Tag)] = ' ') Or (Tag[Length(Tag)] = #9)) Do
    Dec(Tag[0]);
  End;
  K := 1;
  While (K <= Length(Tag)) And (Tag[K] <> ' ') And (Tag[K] <> #9) And
        (Tag[K] <> #10) And (Tag[K] <> #13) Do Inc(K);
  TokName := Copy(Tag, 1, K - 1);
  If K <= Length(Tag) Then TokAttrs := Copy(Tag, K + 1, 255) Else TokAttrs := '';
  If HasSlash Then TokKind := DTK_EMPTY Else TokKind := DTK_START;
  Exit;
 End Else Begin
  { Texte jusqu'au prochain < }
  First := DocxPos;
  While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('<')) Do Inc(DocxPos);
  Tag := '';
  For I := First To DocxPos - 1 Do
   If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(I));
  TokKind := DTK_TEXT;
  TokText := DocxDecodeText(Tag);
 End;
End;

Function DocxGetAttr(Const Attrs, Name: String): String;
Var I, J, K, NLen: Integer; OK: Boolean; Q: Char;
Begin
 DocxGetAttr := ''; NLen := Length(Name);
 If NLen = 0 Then Exit;
 I := 1;
 While I + NLen <= Length(Attrs) + 1 Do Begin
  OK := True;
  If I > 1 Then Begin
   Q := Attrs[I-1];
   If (Q <> ' ') And (Q <> #9) And (Q <> #10) And (Q <> #13) Then OK := False;
  End;
  If OK Then
   For K := 1 To NLen Do
    If Attrs[I+K-1] <> Name[K] Then Begin OK := False; Break; End;
  If OK Then Begin
   J := I + NLen;
   If (J <= Length(Attrs)) And (Attrs[J] = '=') Then Begin
    Inc(J);
    If (J <= Length(Attrs)) And ((Attrs[J] = '"') Or (Attrs[J] = #39)) Then Begin
     Q := Attrs[J]; Inc(J); K := J;
     While (K <= Length(Attrs)) And (Attrs[K] <> Q) Do Inc(K);
     DocxGetAttr := DocxDecodeText(Copy(Attrs, J, K - J));
     Exit;
    End;
   End;
  End;
  Inc(I);
 End;
End;

{ ---------- DOCX writer ---------- }

Procedure DocxBuildContentTypes(Var B: TByteBuf);
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B, '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
 BufAppendStr(B, '<Default Extension="rels" ContentType=');
 BufAppendStr(B, '"application/vnd.openxmlformats-package.relationships+xml"/>');
 BufAppendStr(B, '<Default Extension="xml" ContentType="application/xml"/>');
 BufAppendStr(B, '<Override PartName="/word/document.xml" ContentType=');
 BufAppendStr(B, '"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>');
 BufAppendStr(B, '</Types>');
End;

Procedure DocxBuildRels(Var B: TByteBuf);
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B, '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
 BufAppendStr(B, '<Relationship Id="rId1" Type=');
 BufAppendStr(B, '"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"');
 BufAppendStr(B, ' Target="word/document.xml"/>');
 BufAppendStr(B, '</Relationships>');
End;

Procedure DocxBuildDocument(Var B: TByteBuf);
Var
 P, R     : Integer;
 AlignStr : String;
 Sty      : Byte;
 SzHP     : Integer;
 NumStr   : String;
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B, '<w:document xmlns:w=');
 BufAppendStr(B, '"http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
 BufAppendStr(B, '<w:body>');
 For P := 1 To Doc.ParaCount Do Begin
  If Doc.Paragraphs[P].IsImage Then Begin
   BufAppendStr(B, '<w:p/>');
   Continue;
  End;
  BufAppendStr(B, '<w:p><w:pPr>');
  Case Doc.Paragraphs[P].Alignment Of
   ALIGN_CENTER : AlignStr := 'center';
   ALIGN_RIGHT  : AlignStr := 'right';
   ALIGN_JUSTIFY: AlignStr := 'both';
  Else AlignStr := '';
  End;
  If AlignStr <> '' Then Begin
   BufAppendStr(B, '<w:jc w:val="');
   BufAppendStr(B, AlignStr);
   BufAppendStr(B, '"/>');
  End;
  If Doc.Paragraphs[P].PageBreakBefore Then
   BufAppendStr(B, '<w:pageBreakBefore/>');
  BufAppendStr(B, '</w:pPr>');
  For R := 1 To Doc.Paragraphs[P].RunCount Do Begin
   BufAppendStr(B, '<w:r><w:rPr>');
   Sty := Doc.Paragraphs[P].Runs[R].Style.Style;
   If (Sty And STY_BOLD)      <> 0 Then BufAppendStr(B, '<w:b/>');
   If (Sty And STY_ITALIC)    <> 0 Then BufAppendStr(B, '<w:i/>');
   If (Sty And STY_UNDERLINE) <> 0 Then BufAppendStr(B, '<w:u w:val="single"/>');
   SzHP := Doc.Paragraphs[P].Runs[R].Style.FontSize * 2;
   If SzHP < 4 Then SzHP := 24;
   Str(SzHP, NumStr);
   BufAppendStr(B, '<w:sz w:val="');
   BufAppendStr(B, NumStr);
   BufAppendStr(B, '"/></w:rPr>');
   BufAppendStr(B, '<w:t xml:space="preserve">');
   BufAppendXmlText(B, Doc.Paragraphs[P].Runs[R].Text);
   BufAppendStr(B, '</w:t></w:r>');
  End;
  BufAppendStr(B, '</w:p>');
 End;
 BufAppendStr(B, '</w:body></w:document>');
End;

Function SaveDocxToFile(Const FName: String): Boolean;
Var
 Z              : TZipWriter;
 BCT, BRels, BD : TByteBuf;
 OK             : Boolean;
Begin
 SaveDocxToFile := False;
 DocxBuildContentTypes(BCT);
 DocxBuildRels(BRels);
 DocxBuildDocument(BD);
 OK := ZipWrite_Create(Z, FName);
 If OK Then OK := ZipWrite_AddDeflate(Z, '[Content_Types].xml', BCT.Data,  BCT.Size);
 If OK Then OK := ZipWrite_AddDeflate(Z, '_rels/.rels',         BRels.Data, BRels.Size);
 If OK Then OK := ZipWrite_AddDeflate(Z, 'word/document.xml',   BD.Data,   BD.Size);
 If OK Then OK := ZipWrite_Finish(Z);
 BufFree(BCT); BufFree(BRels); BufFree(BD);
 SaveDocxToFile := OK;
End;

{ ---------- DOCX reader ---------- }

Function LoadDocxFromFile(Const FName: String): Boolean;
Var
 Z          : TZipReader;
 Idx, Code  : Integer;
 Buf        : Pointer;
 Size       : LongInt;
 ParaIdx    : Integer;
 RunIdx     : Integer;
 InP, InR   : Boolean;
 InRPr, InPPr, InT : Boolean;
 PendingPB  : Boolean;
 CurAlign   : Byte;
 RunSty     : Byte;
 RunSize    : Byte;
 RunStyleSet: Boolean;
 AttrVal    : String;
 Tn         : String;
 SzHP       : Integer;
 OK         : Boolean;
 TLen, AvailLen : Integer;
 TxtPiece   : String;
Begin
 LoadDocxFromFile := False;
 If Not ZipRead_Open(Z, FName) Then Exit;
 Idx := ZipRead_Find(Z, 'word/document.xml');
 If Idx < 0 Then Begin ZipRead_Close(Z); Exit; End;
 If Not ZipRead_Extract(Z, Idx, Buf, Size) Then Begin ZipRead_Close(Z); Exit; End;
 ZipRead_Close(Z);

 DocxBuf := Buf; DocxPos := 0; DocxSize := Size;

 FreeAllDocImages;
 FillChar(Doc, SizeOf(Doc), 0);
 Doc.PageCount := 1;
 ParaIdx := 0; RunIdx := 0;
 InP := False; InR := False; InRPr := False; InPPr := False; InT := False;
 PendingPB := False;
 CurAlign := ALIGN_LEFT;
 RunSty := 0; RunSize := 12; RunStyleSet := False;
 OK := True;

 Repeat
  DocxNextToken;
  Case TokKind Of

   DTK_START : Begin
    Tn := TokName;
    If Tn = 'w:p' Then Begin
     If ParaIdx >= MAX_PARAS_PER_DOC Then Begin
      { On stoppe la lecture mais on garde ce qu'on a. }
      OK := True; Break;
     End;
     Inc(ParaIdx);
     Doc.Paragraphs[ParaIdx].Alignment := ALIGN_LEFT;
     Doc.Paragraphs[ParaIdx].PageBreakBefore := PendingPB;
     PendingPB := False;
     Doc.Paragraphs[ParaIdx].RunCount := 0;
     Doc.Paragraphs[ParaIdx].IsImage := False;
     InP := True;
     CurAlign := ALIGN_LEFT;
    End
    Else If Tn = 'w:pPr' Then InPPr := True
    Else If (Tn = 'w:r') And InP Then Begin
     If Doc.Paragraphs[ParaIdx].RunCount < MAX_RUNS_PER_PARA Then Begin
      Inc(Doc.Paragraphs[ParaIdx].RunCount);
      RunIdx := Doc.Paragraphs[ParaIdx].RunCount;
      RunSty := 0; RunSize := 12; RunStyleSet := False;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text := '';
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.Style    := 0;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.FontSize := 12;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.Color    := Black;
      InR := True;
     End;
    End
    Else If Tn = 'w:rPr' Then InRPr := True
    Else If (Tn = 'w:t') And InR Then InT := True;
   End;

   DTK_EMPTY : Begin
    Tn := TokName;
    If InPPr Then Begin
     If Tn = 'w:jc' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If      AttrVal = 'center'  Then CurAlign := ALIGN_CENTER
      Else If AttrVal = 'right'   Then CurAlign := ALIGN_RIGHT
      Else If AttrVal = 'both'    Then CurAlign := ALIGN_JUSTIFY
      Else If AttrVal = 'justify' Then CurAlign := ALIGN_JUSTIFY
      Else                             CurAlign := ALIGN_LEFT;
     End
     Else If Tn = 'w:pageBreakBefore' Then Begin
      If InP Then Doc.Paragraphs[ParaIdx].PageBreakBefore := True;
     End;
    End
    Else If InRPr Then Begin
     If      Tn = 'w:b' Then RunSty := RunSty Or STY_BOLD
     Else If Tn = 'w:i' Then RunSty := RunSty Or STY_ITALIC
     Else If Tn = 'w:u' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If AttrVal <> 'none' Then RunSty := RunSty Or STY_UNDERLINE;
     End
     Else If Tn = 'w:sz' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      Val(AttrVal, SzHP, Code);
      If Code = 0 Then Begin
       SzHP := SzHP Div 2;
       If SzHP < 6  Then SzHP := 6;
       If SzHP > 72 Then SzHP := 72;
       RunSize := SzHP;
      End;
     End;
     RunStyleSet := True;
    End
    Else If InR Then Begin
     If Tn = 'w:br' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:type');
      If AttrVal = 'page' Then PendingPB := True;
     End
     Else If Tn = 'w:tab' Then Begin
      If Length(Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text) < MAX_TEXT_LEN Then
       Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
        Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text + ' ';
     End;
    End;
   End;

   DTK_END : Begin
    Tn := TokName;
    If Tn = 'w:t' Then InT := False
    Else If Tn = 'w:rPr' Then Begin
     InRPr := False;
     If InR Then Begin
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.Style    := RunSty;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.FontSize := RunSize;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.Color    := Black;
     End;
    End
    Else If Tn = 'w:r' Then Begin
     If InR And (Not RunStyleSet) Then Begin
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.Style    := RunSty;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.FontSize := RunSize;
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Style.Color    := Black;
     End;
     InR := False;
    End
    Else If Tn = 'w:pPr' Then Begin
     InPPr := False;
     If InP Then Doc.Paragraphs[ParaIdx].Alignment := CurAlign;
    End
    Else If Tn = 'w:p' Then Begin
     If (ParaIdx > 0) And (Doc.Paragraphs[ParaIdx].RunCount = 0) Then Begin
      Doc.Paragraphs[ParaIdx].RunCount := 1;
      Doc.Paragraphs[ParaIdx].Runs[1].Text := '';
      Doc.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
      Doc.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
      Doc.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
     End;
     InP := False;
    End;
   End;

   DTK_TEXT : Begin
    If InT And InR And (ParaIdx > 0) And (RunIdx > 0) Then Begin
     TLen := Length(Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text);
     AvailLen := MAX_TEXT_LEN - TLen;
     If AvailLen > 0 Then Begin
      TxtPiece := TokText;
      If Length(TxtPiece) > AvailLen Then TxtPiece := Copy(TxtPiece, 1, AvailLen);
      Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
       Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text + TxtPiece;
     End;
    End;
   End;

  End;
 Until TokKind = DTK_EOF;

 FreeMem(Buf, Size);

 If ParaIdx = 0 Then Begin
  ParaIdx := 1;
  Doc.Paragraphs[1].Alignment := ALIGN_LEFT;
  Doc.Paragraphs[1].RunCount := 1;
  Doc.Paragraphs[1].Runs[1].Text := '';
  Doc.Paragraphs[1].Runs[1].Style.Style    := 0;
  Doc.Paragraphs[1].Runs[1].Style.FontSize := 12;
  Doc.Paragraphs[1].Runs[1].Style.Color    := Black;
 End;
 Doc.ParaCount  := ParaIdx;
 Doc.FileName   := FName;
 Doc.Modified   := False;
 Cursor.ParaIdx := 1; Cursor.RunIdx := 1; Cursor.CharIdx := 0;
 ScrollY := 0; CurrentPage := 1; NeedsRelayout := True;
 LoadDocxFromFile := OK;
End;

{ ---------- Dispatch par extension ---------- }

Function ExtIsDocx(Const FN: String): Boolean;
Var L: Integer; E: String;
Begin
 ExtIsDocx := False;
 L := Length(FN);
 If L < 5 Then Exit;
 E := Copy(FN, L - 4, 5);
 If (UpCase(E[1]) = '.') And (UpCase(E[2]) = 'D') And
    (UpCase(E[3]) = 'O') And (UpCase(E[4]) = 'C') And
    (UpCase(E[5]) = 'X') Then ExtIsDocx := True;
End;

Procedure EnsureDocExt(Var FN: String; WantDocx: Boolean);
Var I, DotPos : Integer;
Begin
 DotPos := 0;
 For I := Length(FN) Downto 1 Do
  If FN[I] = '.' Then Begin DotPos := I; Break; End;
 If DotPos = 0 Then Begin
  If WantDocx Then FN := FN + '.DOCX' Else FN := FN + '.WPD';
 End;
End;

{ ============================================================ }
{ ===================  PHASE 9 - DOC CFBF  =================== }
{ ============================================================ }
{ Lecture seule de fichiers .DOC Word 97-2003 :                 }
{   - Parseur Compound File Binary Format (CFBF / OLE2)         }
{   - Extraction du texte via la table de pieces (CLX) du FIB   }
{   - Pieces compressees (CP1252, 1 octet/char) ou UTF-16       }
{   - Conversion en paragraphes (separateur #13)                }
{   - #12 = saut de page, #11 = saut de ligne -> espace         }
{   - Formatage (gras/italique/taille) NON preserve             }
{ ============================================================ }

Const
 CFB_DIFSECT    = LongInt($FFFFFFFC);
 CFB_FATSECT    = LongInt($FFFFFFFD);
 CFB_ENDOFCHAIN = LongInt($FFFFFFFE);
 CFB_FREESECT   = LongInt($FFFFFFFF);
 CFB_MAX_DIRS   = 256;

Type
 TCfbDir = Record
  Name    : String[32];
  ObjType : Byte;
  StartSec: LongInt;
  SizeLo  : LongInt;
 End;

Var
 CfbF       : File;
 CfbFOpen   : Boolean;
 CfbSecSize : LongInt;
 CfbMiniSz  : LongInt;
 CfbDirFirst: LongInt;
 CfbMiniCut : LongInt;
 CfbMFATFst : LongInt;
 CfbMFATCnt : LongInt;
 CfbDIFFst  : LongInt;
 CfbDIFCnt  : LongInt;
 CfbFATNum  : LongInt;
 CfbFAT     : Pointer;
 CfbFATLen  : LongInt;
 CfbMFAT    : Pointer;
 CfbMFATLen : LongInt;
 CfbMini    : Pointer;
 CfbMiniLen : LongInt;
 CfbDirs    : Array[0..CFB_MAX_DIRS-1] Of TCfbDir;
 CfbDirCnt  : LongInt;

Function PByteAt(P: Pointer; Ofs: LongInt): Byte;
Var Pp: ^Byte;
Begin
 Pp := P; Inc(Pp, Ofs); PByteAt := Pp^;
End;

Function CfbBufU16(P: Pointer; Ofs: LongInt): Word;
Var Pp: ^Byte; A, B: Word;
Begin
 Pp := P; Inc(Pp, Ofs);
 A := Word(Pp^); Inc(Pp); B := Word(Pp^);
 CfbBufU16 := A Or (B Shl 8);
End;

Function CfbBufU32(P: Pointer; Ofs: LongInt): Cardinal;
Var Pp: ^Byte; A, B, C, D: Cardinal;
Begin
 Pp := P; Inc(Pp, Ofs);
 A := Cardinal(Pp^); Inc(Pp);
 B := Cardinal(Pp^); Inc(Pp);
 C := Cardinal(Pp^); Inc(Pp);
 D := Cardinal(Pp^);
 CfbBufU32 := A Or (B Shl 8) Or (C Shl 16) Or (D Shl 24);
End;

Function CfbFATEntry(Idx: LongInt): Cardinal;
Var Pp: ^Byte;
Begin
 If (Idx < 0) Or (Idx >= CfbFATLen) Then Begin
  CfbFATEntry := Cardinal(CFB_FREESECT); Exit;
 End;
 Pp := CfbFAT; Inc(Pp, Idx * 4);
 CfbFATEntry := CfbBufU32(Pp, 0);
End;

Function CfbMFATEntry(Idx: LongInt): Cardinal;
Var Pp: ^Byte;
Begin
 If (Idx < 0) Or (Idx >= CfbMFATLen) Then Begin
  CfbMFATEntry := Cardinal(CFB_FREESECT); Exit;
 End;
 Pp := CfbMFAT; Inc(Pp, Idx * 4);
 CfbMFATEntry := CfbBufU32(Pp, 0);
End;

Procedure CfbReadSector(SecNum: LongInt; Buf: Pointer);
Var Offs: LongInt;
Begin
 Offs := (SecNum + 1) * CfbSecSize;
 {$I-} Seek(CfbF, Offs); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockRead(CfbF, Buf^, CfbSecSize); {$I+}
 If IOResult <> 0 Then ;
End;

Function CfbReadFATChain(StartSec: LongInt; TotalSize: LongInt;
                         Var Buf: Pointer): Boolean;
Var
 Cur     : Cardinal;
 Pos     : LongInt;
 Chunk   : LongInt;
 SecBuf  : Pointer;
 OutP    : ^Byte;
 Safety  : LongInt;
Begin
 CfbReadFATChain := False;
 If TotalSize <= 0 Then Begin Buf := Nil; CfbReadFATChain := True; Exit; End;
 GetMem(Buf, TotalSize);
 GetMem(SecBuf, CfbSecSize);
 Cur := Cardinal(StartSec);
 Pos := 0; Safety := 0;
 OutP := Buf;
 While (Pos < TotalSize) And
       (Cur <> Cardinal(CFB_ENDOFCHAIN)) And
       (Cur <> Cardinal(CFB_FREESECT)) Do Begin
  CfbReadSector(LongInt(Cur), SecBuf);
  Chunk := CfbSecSize;
  If Pos + Chunk > TotalSize Then Chunk := TotalSize - Pos;
  Move(SecBuf^, OutP^, Chunk);
  Inc(OutP, Chunk);
  Inc(Pos, Chunk);
  Cur := CfbFATEntry(LongInt(Cur));
  Inc(Safety);
  If Safety > 1048576 Then Begin
   FreeMem(SecBuf, CfbSecSize); FreeMem(Buf, TotalSize); Buf := Nil; Exit;
  End;
 End;
 FreeMem(SecBuf, CfbSecSize);
 If Pos < TotalSize Then Begin
  FreeMem(Buf, TotalSize); Buf := Nil; Exit;
 End;
 CfbReadFATChain := True;
End;

Function CfbReadMiniChain(StartSec: LongInt; TotalSize: LongInt;
                          Var Buf: Pointer): Boolean;
Var
 Cur     : Cardinal;
 Pos     : LongInt;
 Chunk   : LongInt;
 SrcP    : ^Byte;
 OutP    : ^Byte;
 Safety  : LongInt;
Begin
 CfbReadMiniChain := False;
 If TotalSize <= 0 Then Begin Buf := Nil; CfbReadMiniChain := True; Exit; End;
 If CfbMini = Nil Then Exit;
 GetMem(Buf, TotalSize);
 Cur := Cardinal(StartSec);
 Pos := 0; Safety := 0;
 OutP := Buf;
 While (Pos < TotalSize) And
       (Cur <> Cardinal(CFB_ENDOFCHAIN)) And
       (Cur <> Cardinal(CFB_FREESECT)) Do Begin
  If LongInt(Cur) * CfbMiniSz + CfbMiniSz > CfbMiniLen Then Begin
   FreeMem(Buf, TotalSize); Buf := Nil; Exit;
  End;
  SrcP := CfbMini; Inc(SrcP, LongInt(Cur) * CfbMiniSz);
  Chunk := CfbMiniSz;
  If Pos + Chunk > TotalSize Then Chunk := TotalSize - Pos;
  Move(SrcP^, OutP^, Chunk);
  Inc(OutP, Chunk);
  Inc(Pos, Chunk);
  Cur := CfbMFATEntry(LongInt(Cur));
  Inc(Safety);
  If Safety > 1048576 Then Begin
   FreeMem(Buf, TotalSize); Buf := Nil; Exit;
  End;
 End;
 If Pos < TotalSize Then Begin
  FreeMem(Buf, TotalSize); Buf := Nil; Exit;
 End;
 CfbReadMiniChain := True;
End;

Procedure CfbCleanup;
Begin
 If CfbFAT  <> Nil Then Begin FreeMem(CfbFAT,  CfbFATLen * 4);  CfbFAT  := Nil; End;
 If CfbMFAT <> Nil Then Begin FreeMem(CfbMFAT, CfbMFATLen * 4); CfbMFAT := Nil; End;
 If CfbMini <> Nil Then Begin FreeMem(CfbMini, CfbMiniLen);     CfbMini := Nil; End;
 CfbFATLen := 0; CfbMFATLen := 0; CfbMiniLen := 0;
 CfbDirCnt := 0;
 If CfbFOpen Then Begin
  {$I-} Close(CfbF); {$I+}
  If IOResult <> 0 Then ;
  CfbFOpen := False;
 End;
End;

Function CfbOpenFile(Const FName: String): Boolean;
Var
 Hdr        : Array[0..511] Of Byte;
 I, J       : LongInt;
 DifSectors : Array[0..1023] Of LongInt;
 DifSectCnt : LongInt;
 DIFCount   : LongInt;
 Buf        : Pointer;
 DirBuf     : Pointer;
 DirEntries : LongInt;
 EntryP     : ^Byte;
 NameLen    : Word;
 K          : LongInt;
 M          : Byte;
 RootStart  : LongInt;
 RootSize   : LongInt;
 NextDifSec : Cardinal;
 PFat       : ^Byte;
Begin
 CfbOpenFile := False;
 CfbFAT := Nil; CfbMFAT := Nil; CfbMini := Nil; CfbFOpen := False;
 CfbFATLen := 0; CfbMFATLen := 0; CfbMiniLen := 0; CfbDirCnt := 0;

 {$I-} Assign(CfbF, FName); Reset(CfbF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 CfbFOpen := True;
 {$I-} BlockRead(CfbF, Hdr, 512); {$I+}
 If IOResult <> 0 Then Begin CfbCleanup; Exit; End;

 If (Hdr[0] <> $D0) Or (Hdr[1] <> $CF) Or (Hdr[2] <> $11) Or (Hdr[3] <> $E0) Or
    (Hdr[4] <> $A1) Or (Hdr[5] <> $B1) Or (Hdr[6] <> $1A) Or (Hdr[7] <> $E1) Then Begin
  CfbCleanup; Exit;
 End;

 CfbSecSize  := LongInt(1) Shl CfbBufU16(@Hdr, 30);
 CfbMiniSz   := LongInt(1) Shl CfbBufU16(@Hdr, 32);
 CfbFATNum   := LongInt(CfbBufU32(@Hdr, 44));
 CfbDirFirst := LongInt(CfbBufU32(@Hdr, 48));
 CfbMiniCut  := LongInt(CfbBufU32(@Hdr, 56));
 CfbMFATFst  := LongInt(CfbBufU32(@Hdr, 60));
 CfbMFATCnt  := LongInt(CfbBufU32(@Hdr, 64));
 CfbDIFFst   := LongInt(CfbBufU32(@Hdr, 68));
 CfbDIFCnt   := LongInt(CfbBufU32(@Hdr, 72));

 If (CfbSecSize <> 512) And (CfbSecSize <> 4096) Then Begin CfbCleanup; Exit; End;
 If CfbMiniSz <> 64 Then Begin CfbCleanup; Exit; End;
 If (CfbFATNum <= 0) Or (CfbFATNum > 100000) Then Begin CfbCleanup; Exit; End;

 DifSectCnt := 0;
 For I := 0 To 108 Do Begin
  J := LongInt(CfbBufU32(@Hdr, 76 + I * 4));
  If (Cardinal(J) <> Cardinal(CFB_FREESECT)) And (DifSectCnt < 1024) Then Begin
   DifSectors[DifSectCnt] := J; Inc(DifSectCnt);
  End;
 End;

 NextDifSec := Cardinal(CfbDIFFst);
 GetMem(Buf, CfbSecSize);
 While (NextDifSec <> Cardinal(CFB_ENDOFCHAIN)) And
       (NextDifSec <> Cardinal(CFB_FREESECT)) And
       (DifSectCnt < 1024) Do Begin
  CfbReadSector(LongInt(NextDifSec), Buf);
  DIFCount := (CfbSecSize Div 4) - 1;
  For I := 0 To DIFCount - 1 Do Begin
   J := LongInt(CfbBufU32(Buf, I * 4));
   If (Cardinal(J) <> Cardinal(CFB_FREESECT)) And (DifSectCnt < 1024) Then Begin
    DifSectors[DifSectCnt] := J; Inc(DifSectCnt);
   End;
  End;
  NextDifSec := CfbBufU32(Buf, DIFCount * 4);
 End;
 FreeMem(Buf, CfbSecSize);

 CfbFATLen := DifSectCnt * (CfbSecSize Div 4);
 If CfbFATLen <= 0 Then Begin CfbCleanup; Exit; End;
 GetMem(CfbFAT, CfbFATLen * 4);
 GetMem(Buf, CfbSecSize);
 PFat := CfbFAT;
 For I := 0 To DifSectCnt - 1 Do Begin
  CfbReadSector(DifSectors[I], Buf);
  Move(Buf^, PFat^, CfbSecSize);
  Inc(PFat, CfbSecSize);
 End;
 FreeMem(Buf, CfbSecSize);

 If (CfbMFATCnt > 0) And (CfbMFATFst >= 0) Then Begin
  CfbMFATLen := CfbMFATCnt * (CfbSecSize Div 4);
  GetMem(CfbMFAT, CfbMFATLen * 4);
  GetMem(Buf, CfbSecSize);
  PFat := CfbMFAT;
  J := CfbMFATFst;
  I := 0;
  While (I < CfbMFATCnt) And (Cardinal(J) <> Cardinal(CFB_ENDOFCHAIN)) And
        (Cardinal(J) <> Cardinal(CFB_FREESECT)) Do Begin
   CfbReadSector(J, Buf);
   Move(Buf^, PFat^, CfbSecSize);
   Inc(PFat, CfbSecSize);
   J := LongInt(CfbFATEntry(J));
   Inc(I);
  End;
  FreeMem(Buf, CfbSecSize);
 End Else Begin
  CfbMFAT := Nil; CfbMFATLen := 0;
 End;

 { Lecture du repertoire (limite a CFB_MAX_DIRS entrees) }
 If Not CfbReadFATChain(CfbDirFirst, 128 * CFB_MAX_DIRS, DirBuf) Then Begin
  If Not CfbReadFATChain(CfbDirFirst, 4 * CfbSecSize, DirBuf) Then Begin
   CfbCleanup; Exit;
  End;
  DirEntries := (4 * CfbSecSize) Div 128;
 End Else
  DirEntries := CFB_MAX_DIRS;

 If DirEntries > CFB_MAX_DIRS Then DirEntries := CFB_MAX_DIRS;
 CfbDirCnt := 0;
 EntryP := DirBuf;
 RootStart := -1; RootSize := 0;
 For I := 0 To DirEntries - 1 Do Begin
  NameLen := CfbBufU16(EntryP, 64);
  CfbDirs[I].ObjType := PByteAt(EntryP, 66);
  CfbDirs[I].StartSec := LongInt(CfbBufU32(EntryP, 116));
  CfbDirs[I].SizeLo   := LongInt(CfbBufU32(EntryP, 120));
  CfbDirs[I].Name := '';
  If NameLen > 64 Then NameLen := 64;
  If NameLen >= 2 Then Dec(NameLen, 2);
  K := 0;
  While K < (NameLen Div 2) Do Begin
   M := PByteAt(EntryP, K * 2);
   If (M >= 32) And (M < 128) And (Length(CfbDirs[I].Name) < 32) Then
    CfbDirs[I].Name := CfbDirs[I].Name + Char(M)
   Else If (Length(CfbDirs[I].Name) < 32) Then
    CfbDirs[I].Name := CfbDirs[I].Name + '?';
   Inc(K);
  End;
  If CfbDirs[I].ObjType = 5 Then Begin
   RootStart := CfbDirs[I].StartSec;
   RootSize  := CfbDirs[I].SizeLo;
  End;
  Inc(CfbDirCnt);
  Inc(EntryP, 128);
 End;
 FreeMem(DirBuf, 128 * DirEntries);

 If (RootStart >= 0) And (RootSize > 0) Then Begin
  If Not CfbReadFATChain(RootStart, RootSize, CfbMini) Then Begin
   CfbMini := Nil; CfbMiniLen := 0;
  End Else
   CfbMiniLen := RootSize;
 End Else Begin
  CfbMini := Nil; CfbMiniLen := 0;
 End;

 CfbOpenFile := True;
End;

Function CfbFindStream(Const Name: String): LongInt;
Var I, K: LongInt; Match: Boolean;
Begin
 CfbFindStream := -1;
 For I := 0 To CfbDirCnt - 1 Do Begin
  If CfbDirs[I].ObjType <> 2 Then Continue;
  If Length(CfbDirs[I].Name) <> Length(Name) Then Continue;
  Match := True;
  For K := 1 To Length(Name) Do
   If CfbDirs[I].Name[K] <> Name[K] Then Begin Match := False; Break; End;
  If Match Then Begin CfbFindStream := I; Exit; End;
 End;
End;

Function CfbReadStreamByDir(Idx: LongInt; Var Buf: Pointer): LongInt;
Var Size: LongInt;
Begin
 CfbReadStreamByDir := 0; Buf := Nil;
 If (Idx < 0) Or (Idx >= CfbDirCnt) Then Exit;
 Size := CfbDirs[Idx].SizeLo;
 If Size <= 0 Then Exit;
 If Size < CfbMiniCut Then Begin
  If Not CfbReadMiniChain(CfbDirs[Idx].StartSec, Size, Buf) Then Exit;
 End Else Begin
  If Not CfbReadFATChain(CfbDirs[Idx].StartSec, Size, Buf) Then Exit;
 End;
 CfbReadStreamByDir := Size;
End;

{ ---------- DOC : extraction du texte via la piece table ---------- }

Procedure DocStartFirstPara(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean);
Begin
 ParaIdx := 1;
 Doc.Paragraphs[1].Alignment := ALIGN_LEFT;
 Doc.Paragraphs[1].PageBreakBefore := PendingPB; PendingPB := False;
 Doc.Paragraphs[1].RunCount := 1;
 Doc.Paragraphs[1].Runs[1].Text := '';
 Doc.Paragraphs[1].Runs[1].Style.Style    := 0;
 Doc.Paragraphs[1].Runs[1].Style.FontSize := 12;
 Doc.Paragraphs[1].Runs[1].Style.Color    := Black;
 RunIdx := 1;
End;

Procedure DocAppendCh(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean; C: Char);
Var L: Integer;
Begin
 If ParaIdx = 0 Then DocStartFirstPara(ParaIdx, RunIdx, PendingPB);
 L := Length(Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text);
 If L < MAX_TEXT_LEN Then
  Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
   Doc.Paragraphs[ParaIdx].Runs[RunIdx].Text + C
 Else Begin
  If ParaIdx >= MAX_PARAS_PER_DOC Then Exit;
  Inc(ParaIdx);
  Doc.Paragraphs[ParaIdx].Alignment := ALIGN_LEFT;
  Doc.Paragraphs[ParaIdx].PageBreakBefore := False;
  Doc.Paragraphs[ParaIdx].RunCount := 1;
  Doc.Paragraphs[ParaIdx].Runs[1].Text := C;
  Doc.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
  Doc.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
  Doc.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
  RunIdx := 1;
 End;
End;

Procedure DocFinishParaP(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean);
Begin
 If ParaIdx = 0 Then DocStartFirstPara(ParaIdx, RunIdx, PendingPB);
 If ParaIdx >= MAX_PARAS_PER_DOC Then Exit;
 Inc(ParaIdx);
 Doc.Paragraphs[ParaIdx].Alignment := ALIGN_LEFT;
 Doc.Paragraphs[ParaIdx].PageBreakBefore := PendingPB; PendingPB := False;
 Doc.Paragraphs[ParaIdx].RunCount := 1;
 Doc.Paragraphs[ParaIdx].Runs[1].Text := '';
 Doc.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
 Doc.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
 Doc.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
 RunIdx := 1;
End;

Procedure DocProcessW(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean; W: Word);
Begin
 Case W Of
  13 : DocFinishParaP(ParaIdx, RunIdx, PendingPB);
  12 : Begin PendingPB := True;
        DocFinishParaP(ParaIdx, RunIdx, PendingPB);
       End;
  9  : DocAppendCh(ParaIdx, RunIdx, PendingPB, ' ');
  11 : DocAppendCh(ParaIdx, RunIdx, PendingPB, ' ');
  7, 14, 19, 20, 21 : ;   { marqueurs cellule/champ ignores }
  $2013, $2014 : DocAppendCh(ParaIdx, RunIdx, PendingPB, '-');
  $2018, $2019 : DocAppendCh(ParaIdx, RunIdx, PendingPB, #39);
  $201C, $201D : DocAppendCh(ParaIdx, RunIdx, PendingPB, '"');
  $00A0       : DocAppendCh(ParaIdx, RunIdx, PendingPB, ' ');
 Else
  If (W >= 32) And (W < 256) Then
   DocAppendCh(ParaIdx, RunIdx, PendingPB, Char(W))
  Else If W >= 256 Then
   DocAppendCh(ParaIdx, RunIdx, PendingPB, '?');
 End;
End;

Function LoadDocFromFile(Const FName: String): Boolean;
Var
 WDIdx, TBIdx : LongInt;
 WDBuf, TBBuf : Pointer;
 WDSize, TBSize : LongInt;
 TableName    : String;
 WIdent       : Word;
 FibFlags     : Word;
 FWhichTbl    : Boolean;
 CbRgFcLcb    : Word;
 FCLcbOffset  : LongInt;
 FcClx, LcbClx: LongInt;
 ClxP         : ^Byte;
 ClxOff       : LongInt;
 PcdtOff      : LongInt;
 LcbPlcfPcd   : LongInt;
 NPieces      : LongInt;
 CPs          : Array[0..512] Of LongInt;
 I            : LongInt;
 PcdP         : ^Byte;
 FcRaw        : Cardinal;
 Compressed   : Boolean;
 FcReal       : LongInt;
 CPStart, CPEnd : LongInt;
 PieceLen     : LongInt;
 ByteLen      : LongInt;
 SrcP         : ^Byte;
 ParaIdx, RunIdx : Integer;
 PendingPB    : Boolean;
 K            : LongInt;
 W            : Word;
 PcdEntryOff  : LongInt;
Begin
 LoadDocFromFile := False;
 If Not CfbOpenFile(FName) Then Exit;

 WDIdx := CfbFindStream('WordDocument');
 If WDIdx < 0 Then Begin CfbCleanup; Exit; End;
 WDSize := CfbReadStreamByDir(WDIdx, WDBuf);
 If (WDSize < 158) Or (WDBuf = Nil) Then Begin
  If WDBuf <> Nil Then FreeMem(WDBuf, WDSize);
  CfbCleanup; Exit;
 End;

 WIdent := CfbBufU16(WDBuf, 0);
 If (WIdent <> $A5EC) And (WIdent <> $A5DC) And (WIdent <> $A699) Then Begin
  FreeMem(WDBuf, WDSize); CfbCleanup; Exit;
 End;

 FibFlags := CfbBufU16(WDBuf, 10);
 FWhichTbl := (FibFlags And $0200) <> 0;
 If FWhichTbl Then TableName := '1Table' Else TableName := '0Table';

 TBIdx := CfbFindStream(TableName);
 If TBIdx < 0 Then Begin
  If FWhichTbl Then TableName := '0Table' Else TableName := '1Table';
  TBIdx := CfbFindStream(TableName);
 End;
 If TBIdx < 0 Then Begin FreeMem(WDBuf, WDSize); CfbCleanup; Exit; End;
 TBSize := CfbReadStreamByDir(TBIdx, TBBuf);
 If (TBSize <= 0) Or (TBBuf = Nil) Then Begin
  If TBBuf <> Nil Then FreeMem(TBBuf, TBSize);
  FreeMem(WDBuf, WDSize); CfbCleanup; Exit;
 End;

 { FibRgFcLcb a l'offset 154 pour Word 97-2003 standard }
 CbRgFcLcb := CfbBufU16(WDBuf, 152);
 FCLcbOffset := 154;
 If (CbRgFcLcb <= 33) Or (FCLcbOffset + 33 * 8 + 8 > WDSize) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;
 FcClx  := LongInt(CfbBufU32(WDBuf, FCLcbOffset + 33 * 8));
 LcbClx := LongInt(CfbBufU32(WDBuf, FCLcbOffset + 33 * 8 + 4));

 If (FcClx < 0) Or (LcbClx <= 0) Or (FcClx + LcbClx > TBSize) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;

 ClxP := TBBuf; Inc(ClxP, FcClx);
 ClxOff := 0;
 PcdtOff := -1;
 While ClxOff < LcbClx Do Begin
  If PByteAt(ClxP, ClxOff) = $01 Then Begin
   If ClxOff + 3 > LcbClx Then Break;
   ByteLen := LongInt(CfbBufU16(ClxP, ClxOff + 1));
   Inc(ClxOff, 3 + ByteLen);
  End Else If PByteAt(ClxP, ClxOff) = $02 Then Begin
   PcdtOff := ClxOff;
   Break;
  End Else
   Break;
 End;

 If (PcdtOff < 0) Or (PcdtOff + 5 > LcbClx) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;
 LcbPlcfPcd := LongInt(CfbBufU32(ClxP, PcdtOff + 1));
 If (LcbPlcfPcd <= 4) Or (PcdtOff + 5 + LcbPlcfPcd > LcbClx) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;

 NPieces := (LcbPlcfPcd - 4) Div 12;
 If (NPieces <= 0) Or (NPieces > 512) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;

 PcdP := ClxP; Inc(PcdP, PcdtOff + 5);
 For I := 0 To NPieces Do
  CPs[I] := LongInt(CfbBufU32(PcdP, I * 4));

 FreeAllDocImages;
 FillChar(Doc, SizeOf(Doc), 0);
 Doc.PageCount := 1;
 ParaIdx := 0; RunIdx := 0; PendingPB := False;

 For I := 0 To NPieces - 1 Do Begin
  CPStart := CPs[I];
  CPEnd   := CPs[I + 1];
  PieceLen := CPEnd - CPStart;
  If PieceLen <= 0 Then Continue;
  PcdEntryOff := (NPieces + 1) * 4 + I * 8;
  FcRaw := CfbBufU32(PcdP, PcdEntryOff + 2);
  Compressed := (FcRaw And Cardinal($40000000)) <> 0;
  If Compressed Then
   FcReal := LongInt((FcRaw And Cardinal($BFFFFFFF)) Shr 1)
  Else
   FcReal := LongInt(FcRaw And Cardinal($BFFFFFFF));
  If Compressed Then ByteLen := PieceLen Else ByteLen := PieceLen * 2;
  If (FcReal < 0) Or (FcReal + ByteLen > WDSize) Then Break;
  SrcP := WDBuf; Inc(SrcP, FcReal);
  If Compressed Then Begin
   For K := 0 To PieceLen - 1 Do Begin
    W := Word(SrcP^);
    DocProcessW(ParaIdx, RunIdx, PendingPB, W);
    Inc(SrcP);
   End;
  End Else Begin
   For K := 0 To PieceLen - 1 Do Begin
    W := Word(SrcP^) Or (Word(PByteAt(SrcP, 1)) Shl 8);
    DocProcessW(ParaIdx, RunIdx, PendingPB, W);
    Inc(SrcP, 2);
   End;
  End;
  If ParaIdx >= MAX_PARAS_PER_DOC Then Break;
 End;

 FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup;

 If ParaIdx = 0 Then DocStartFirstPara(ParaIdx, RunIdx, PendingPB);
 Doc.ParaCount  := ParaIdx;
 Doc.FileName   := FName;
 Doc.Modified   := False;
 Cursor.ParaIdx := 1; Cursor.RunIdx := 1; Cursor.CharIdx := 0;
 ScrollY := 0; CurrentPage := 1; NeedsRelayout := True;
 LoadDocFromFile := True;
End;

Function ExtIsDoc(Const FN: String): Boolean;
Var L: Integer; E: String;
Begin
 ExtIsDoc := False;
 If ExtIsDocx(FN) Then Exit;
 L := Length(FN);
 If L < 4 Then Exit;
 E := Copy(FN, L - 3, 4);
 If (E[1] = '.') And (UpCase(E[2]) = 'D') And
    (UpCase(E[3]) = 'O') And (UpCase(E[4]) = 'C') Then ExtIsDoc := True;
End;

Function LoadAnyDocument(Const FName: String): Boolean;
Begin
 If      ExtIsDocx(FName) Then LoadAnyDocument := LoadDocxFromFile(FName)
 Else If ExtIsDoc (FName) Then LoadAnyDocument := LoadDocFromFile(FName)
 Else                          LoadAnyDocument := LoadDocumentFromFile(FName);
End;

Function SaveAnyDocument(Const FName: String): Boolean;
Begin
 If      ExtIsDocx(FName) Then SaveAnyDocument := SaveDocxToFile(FName)
 Else If ExtIsDoc (FName) Then SaveAnyDocument := False
 Else                          SaveAnyDocument := SaveDocumentToFile(FName);
End;

{ ============================================================ }
{ ===================  PHASE 5 - DIALOGUES  ================== }
{ ============================================================ }

Function ShowConfirmYN(Const Msg: String): Boolean;
Var
 X1, Y1, X2, Y2 : Integer;
 K              : Word;
 Done, OK       : Boolean;
Begin
 OK := False;
 X1 := 120; X2 := 520; Y1 := 180; Y2 := 280;
 EraseSoftCursor;
 FillRectArea(X1+5, Y2+1, X2+5, Y2+5, Black);
 FillRectArea(X2+1, Y1+5, X2+5, Y2+5, Black);
 FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
 DrawButton3D(X1, Y1, X2, Y2, False);
 FillRectArea(X1+3, Y1+3, X2-3, Y1+18, Blue);
 DrawTextAt(X1+8, Y1+6, 'Word Clone', White);
 DrawTextAt(X1+16, Y1+40, Msg, Black);
 DrawButton3D(X1+100, Y2-30, X1+180, Y2-10, False);
 DrawTextAt(X1+128, Y2-26, 'Yes', Black);
 DrawButton3D(X1+220, Y2-30, X1+300, Y2-10, False);
 DrawTextAt(X1+250, Y2-26, 'No', Black);
 {$IFDEF FPC} DrawSoftCursor(MsX, MsY); {$ENDIF}
 Done := False;
 Repeat
  If KeyPressed Then Begin
   K := ReadKeyEx;
   Case K Of
    Ord('Y'),Ord('y'),Ord('O'),Ord('o'),KEY_ENTER : Begin OK:=True;  Done:=True; End;
    Ord('N'),Ord('n'),KEY_ESC                     : Begin OK:=False; Done:=True; End;
   End;
  End;
  GetMouseStateLI(MsX, MsY, MsBtn);
  If (MsBtn And MB_LEFT) <> 0 Then Begin
   If (MsX>=X1+100) And (MsX<=X1+180) And (MsY>=Y2-30) And (MsY<=Y2-10) Then
    Begin OK:=True; Done:=True; End
   Else If (MsX>=X1+220) And (MsX<=X1+300) And (MsY>=Y2-30) And (MsY<=Y2-10) Then
    Begin OK:=False; Done:=True; End;
  End;
 Until Done;
 Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_LEFT) = 0;
 NeedsRedraw := True;
 ShowConfirmYN := OK;
End;

Function ShowFileDialog(Const Title: String; SaveMode: Boolean;
                        Const Filter: String;
                        Var FName: String): Boolean;
Const
 MAX_LIST = 64;
 LIST_ROWS = 10;
 ROW_H = 16;
Var
 X1, Y1, X2, Y2  : Integer;
 LX1, LY1, LX2, LY2 : Integer;
 IX1, IY1, IX2, IY2 : Integer;
 OkX1, CnX1, BY1, BY2 : Integer;
 K               : Word;
 OK, Done        : Boolean;
 Files           : Array[1..MAX_LIST] Of String[16];
 FileCount       : Integer;
 Sel, Top        : Integer;
 SR              : SearchRec;
 Inp             : String;
 I, Idx          : Integer;
 FStart, FEnd, FLen : Integer;
 Mask            : String;

 Procedure RedrawList;
 Var L, Y : Integer;
 Begin
  FillRectArea(LX1+1, LY1+1, LX2-1, LY2-1, White);
  DrawFrameRect(LX1, LY1, LX2, LY2, Black);
  For L := 0 To LIST_ROWS-1 Do Begin
   If Top + L > FileCount Then Break;
   Y := LY1 + 1 + L*ROW_H;
   If Top + L = Sel Then Begin
    FillRectArea(LX1+1, Y, LX2-1, Y+ROW_H-1, Blue);
    DrawTextAt(LX1+6, Y+4, Files[Top+L], White);
   End Else
    DrawTextAt(LX1+6, Y+4, Files[Top+L], Black);
  End;
 End;

 Procedure RedrawInput;
 Var TW : Integer;
 Begin
  FillRectArea(IX1+1, IY1+1, IX2-1, IY2-1, White);
  DrawFrameRect(IX1, IY1, IX2, IY2, Black);
  DrawTextAt(IX1+4, IY1+4, Inp, Black);
  TW := TextWidth(Inp);
  FillRectArea(IX1+4+TW, IY1+3, IX1+4+TW+1, IY2-3, Black);
 End;

Begin
 OK := False;
 X1 := 140; X2 := 500; Y1 := 100; Y2 := 380;
 LX1 := X1+15;  LY1 := Y1+90;
 LX2 := X2-15;  LY2 := LY1 + LIST_ROWS*ROW_H + 1;
 IX1 := X1+60;  IY1 := Y1+58;
 IX2 := X2-15;  IY2 := Y1+74;
 BY1 := Y2-30;  BY2 := Y2-10;
 OkX1 := X2-180;
 CnX1 := X2-90;
 Inp := FName;
 { Strip leading dir part from default if present }
 For I := Length(Inp) Downto 1 Do
  If (Inp[I]='\') Or (Inp[I]='/') Or (Inp[I]=':') Then Begin
   Inp := Copy(Inp, I+1, Length(Inp)-I); Break;
  End;
 Sel := 0; Top := 1;
 FileCount := 0;
 FStart := 1; FLen := Length(Filter);
 While FStart <= FLen Do Begin
  FEnd := FStart;
  While (FEnd <= FLen) And (Filter[FEnd] <> ';') Do Inc(FEnd);
  Mask := Copy(Filter, FStart, FEnd - FStart);
  If Length(Mask) > 0 Then Begin
   FindFirst(Mask, AnyFile, SR);
   While (DosError = 0) And (FileCount < MAX_LIST) Do Begin
    Inc(FileCount);
    Files[FileCount] := SR.Name;
    FindNext(SR);
   End;
   {$IFDEF FPC} FindClose(SR); {$ENDIF}
  End;
  FStart := FEnd + 1;
 End;

 EraseSoftCursor;
 FillRectArea(X1+5, Y2+1, X2+5, Y2+5, Black);
 FillRectArea(X2+1, Y1+5, X2+5, Y2+5, Black);
 FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
 DrawButton3D(X1, Y1, X2, Y2, False);
 FillRectArea(X1+3, Y1+3, X2-3, Y1+18, Blue);
 DrawTextAt(X1+8, Y1+6, Title, White);
 DrawTextAt(X1+15, Y1+30, 'Files (' + Filter + '):', Black);
 DrawTextAt(X1+15, Y1+62, 'Name:', Black);
 RedrawInput;
 RedrawList;
 DrawButton3D(OkX1, BY1, OkX1+80, BY2, False);
 If SaveMode Then DrawTextAt(OkX1+25, BY1+4, 'Save', Black)
             Else DrawTextAt(OkX1+30, BY1+4, 'Open', Black);
 DrawButton3D(CnX1, BY1, CnX1+80, BY2, False);
 DrawTextAt(CnX1+22, BY1+4, 'Cancel', Black);
 {$IFDEF FPC} DrawSoftCursor(MsX, MsY); {$ENDIF}

 Done := False;
 Repeat
  If KeyPressed Then Begin
   K := ReadKeyEx;
   Case K Of
    KEY_ESC   : Begin OK:=False; Done:=True; End;
    KEY_ENTER : If Length(Inp) > 0 Then Begin OK:=True; Done:=True; End;
    KEY_UP    : If FileCount > 0 Then Begin
                 If Sel <= 1 Then Sel := 1 Else Dec(Sel);
                 If Sel < Top Then Top := Sel;
                 Inp := Files[Sel]; RedrawInput; RedrawList;
                End;
    KEY_DOWN  : If Sel < FileCount Then Begin
                 If Sel = 0 Then Sel := 1 Else Inc(Sel);
                 If Sel > Top + LIST_ROWS - 1 Then Top := Sel - LIST_ROWS + 1;
                 Inp := Files[Sel]; RedrawInput; RedrawList;
                End;
    KEY_BACKSPACE : If Length(Inp) > 0 Then Begin
                     Inp[0] := Char(Length(Inp)-1);
                     RedrawInput;
                    End;
   Else
    If (K >= 32) And (K <= 126) And (Length(Inp) < 50) Then Begin
     Inp := Inp + Char(K);
     RedrawInput;
    End;
   End;
  End;
  GetMouseStateLI(MsX, MsY, MsBtn);
  If (MsBtn And MB_LEFT) <> 0 Then Begin
   If (MsX>=OkX1) And (MsX<=OkX1+80) And (MsY>=BY1) And (MsY<=BY2) Then Begin
    If Length(Inp)>0 Then Begin OK:=True; Done:=True; End;
   End Else If (MsX>=CnX1) And (MsX<=CnX1+80) And (MsY>=BY1) And (MsY<=BY2) Then Begin
    OK:=False; Done:=True;
   End Else If (MsX>=LX1) And (MsX<=LX2) And (MsY>=LY1) And (MsY<=LY2) Then Begin
    Idx := Top + (MsY - LY1 - 1) Div ROW_H;
    If (Idx >= 1) And (Idx <= FileCount) Then Begin
     Sel := Idx; Inp := Files[Sel]; RedrawInput; RedrawList;
    End;
   End;
   Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_LEFT) = 0;
  End;
 Until Done;
 If OK Then FName := Inp;
 NeedsRedraw := True;
 ShowFileDialog := OK;
End;

{ ============================================================ }
{ ===================  PHASE 10 - POLISSAGE  ================= }
{ ============================================================ }
{ Boite de saisie de texte, recherche/remplacement, undo/redo  }
{ (snapshot du document, profondeur 5), comptage de mots.      }
{ ============================================================ }

Const
 ACT_EDIT_FIND_NEXT_X = 208;  { kept for back-compat with Phase 10 placeholder }
 ACT_TLS_WORDS_X      = 603;
 MAX_UNDO           = 5;
 MAX_FIND_LEN       = 60;

Type
 TDocPtr = ^TDocument;

Var
 UndoStack    : Array[1..MAX_UNDO] Of TDocPtr;
 UndoCursors  : Array[1..MAX_UNDO] Of TCursorPos;
 UndoCount    : Integer;
 RedoStack    : Array[1..MAX_UNDO] Of TDocPtr;
 RedoCursors  : Array[1..MAX_UNDO] Of TCursorPos;
 RedoCount    : Integer;
 LastMutate   : Integer;     { 0=none, 1=typing, 2=other }
 LastFindStr  : String[MAX_FIND_LEN];
 LastReplStr  : String[MAX_FIND_LEN];

{ ---- Boite de saisie texte simple ---- }

Function InputBoxDlg(Const Title, Prompt: String;
                     Var S: String; MaxLen: Integer): Boolean;
Var
 X1, Y1, X2, Y2  : Integer;
 IX1, IY1, IX2, IY2 : Integer;
 OkX1, CnX1, BY1, BY2 : Integer;
 K               : Word;
 OK, Done        : Boolean;
 Inp             : String;
 TW              : Integer;

 Procedure RedrawInput;
 Var TWi : Integer;
 Begin
  FillRectArea(IX1+1, IY1+1, IX2-1, IY2-1, White);
  DrawFrameRect(IX1, IY1, IX2, IY2, Black);
  DrawTextAt(IX1+4, IY1+4, Inp, Black);
  TWi := TextWidth(Inp);
  FillRectArea(IX1+4+TWi, IY1+3, IX1+4+TWi+1, IY2-3, Black);
 End;

Begin
 OK := False;
 X1 := 160; X2 := 480; Y1 := 160; Y2 := 280;
 IX1 := X1+15; IX2 := X2-15; IY1 := Y1+60; IY2 := Y1+78;
 BY1 := Y2-30; BY2 := Y2-10;
 OkX1 := X2-180; CnX1 := X2-90;
 Inp := S;
 If MaxLen <= 0 Then MaxLen := 80;
 If MaxLen > 250 Then MaxLen := 250;

 EraseSoftCursor;
 FillRectArea(X1+5, Y2+1, X2+5, Y2+5, Black);
 FillRectArea(X2+1, Y1+5, X2+5, Y2+5, Black);
 FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
 DrawButton3D(X1, Y1, X2, Y2, False);
 FillRectArea(X1+3, Y1+3, X2-3, Y1+18, Blue);
 DrawTextAt(X1+8, Y1+6, Title, White);
 DrawTextAt(X1+15, Y1+34, Prompt, Black);
 RedrawInput;
 DrawButton3D(OkX1, BY1, OkX1+80, BY2, False);
 TW := TextWidth('OK');
 DrawTextAt(OkX1 + 40 - TW Div 2, BY1+4, 'OK', Black);
 DrawButton3D(CnX1, BY1, CnX1+80, BY2, False);
 DrawTextAt(CnX1+22, BY1+4, 'Cancel', Black);
 {$IFDEF FPC} DrawSoftCursor(MsX, MsY); {$ENDIF}

 Done := False;
 Repeat
  If KeyPressed Then Begin
   K := ReadKeyEx;
   Case K Of
    KEY_ESC   : Begin OK := False; Done := True; End;
    KEY_ENTER : Begin OK := True; Done := True; End;
    KEY_BACKSPACE : If Length(Inp) > 0 Then Begin
                     Inp[0] := Char(Length(Inp)-1);
                     RedrawInput;
                    End;
   Else
    If (K >= 32) And (K <= 126) And (Length(Inp) < MaxLen) Then Begin
     Inp := Inp + Char(K);
     RedrawInput;
    End;
   End;
  End;
  GetMouseStateLI(MsX, MsY, MsBtn);
  If (MsBtn And MB_LEFT) <> 0 Then Begin
   If (MsX>=OkX1) And (MsX<=OkX1+80) And (MsY>=BY1) And (MsY<=BY2) Then Begin
    OK := True; Done := True;
   End Else If (MsX>=CnX1) And (MsX<=CnX1+80) And (MsY>=BY1) And (MsY<=BY2) Then Begin
    OK := False; Done := True;
   End;
   Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_LEFT) = 0;
  End;
 Until Done;
 If OK Then S := Inp;
 NeedsRedraw := True;
 InputBoxDlg := OK;
End;

{ ---- Comptage mots / caracteres ---- }

Function CountWordsInStr(Const S: String): LongInt;
Var I, L: Integer; InWord: Boolean; N: LongInt;
Begin
 N := 0; InWord := False; L := Length(S);
 For I := 1 To L Do Begin
  If (S[I] = ' ') Or (S[I] = #9) Or (S[I] = #13) Then Begin
   InWord := False;
  End Else Begin
   If Not InWord Then Inc(N);
   InWord := True;
  End;
 End;
 CountWordsInStr := N;
End;

Procedure CountDocStats(Var Words, Chars, ParaCnt, PageCnt: LongInt);
Var I: Integer; T: String;
Begin
 Words := 0; Chars := 0;
 ParaCnt := Doc.ParaCount;
 PageCnt := Doc.PageCount;
 For I := 1 To Doc.ParaCount Do Begin
  If Doc.Paragraphs[I].IsImage Then Continue;
  T := ParaText(I);
  Inc(Words, CountWordsInStr(T));
  Inc(Chars, Length(T));
 End;
End;

Procedure ShowWordCountDialog;
Var
 W, C, P, Pg : LongInt;
 SW, SC, SP, SPg : String[16];
 Msg : String;
Begin
 CountDocStats(W, C, P, Pg);
 Str(W, SW); Str(C, SC); Str(P, SP); Str(Pg, SPg);
 Msg := 'Words: ' + SW + '  Chars: ' + SC +
        '  Paras: ' + SP + '  Pages: ' + SPg;
 ShowMessage(Msg);
End;

{ ---- Recherche dans le document ---- }

Function UpperStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do
  If (R[I] >= 'a') And (R[I] <= 'z') Then
   R[I] := Char(Byte(R[I]) - 32);
 UpperStr := R;
End;

{ Cherche Needle a partir de (StartP, StartCh) inclus, sans wrap. Si trouve,
  pose Cursor au debut du match et retourne True. }
Function FindNextFromCursor(Const Needle: String): Boolean;
Var
 P            : Integer;
 T, UT, UN    : String;
 StartCh, Idx : Integer;
 RIdx, ROff   : Integer;
Begin
 FindNextFromCursor := False;
 If Length(Needle) = 0 Then Exit;
 UN := UpperStr(Needle);
 StartCh := Cursor.CharIdx + 1;
 For P := Cursor.ParaIdx To Doc.ParaCount Do Begin
  If Doc.Paragraphs[P].IsImage Then Begin
   StartCh := 1; Continue;
  End;
  T := ParaText(P);
  UT := UpperStr(T);
  If StartCh < 1 Then StartCh := 1;
  If StartCh > Length(UT) Then Begin StartCh := 1; Continue; End;
  Idx := Pos(UN, Copy(UT, StartCh, Length(UT) - StartCh + 1));
  If Idx > 0 Then Begin
   Idx := Idx + StartCh - 1;
   Cursor.ParaIdx := P;
   Cursor.CharIdx := Idx - 1;
   LocateChar(P, Cursor.CharIdx, RIdx, ROff);
   Cursor.RunIdx := RIdx;
   FindNextFromCursor := True;
   Exit;
  End;
  StartCh := 1;
 End;
End;

{ ---- Undo/Redo : snapshots avec clonage des images ---- }

Procedure DocSnapshotClone(Src: TDocPtr; Dst: TDocPtr);
Var
 I, Sz : Integer;
 NewP  : Pointer;
Begin
 Dst^ := Src^;
 For I := 1 To Dst^.ParaCount Do
  If Dst^.Paragraphs[I].IsImage And (Dst^.Paragraphs[I].ImgData <> Nil) Then Begin
   Sz := Dst^.Paragraphs[I].ImgW * Dst^.Paragraphs[I].ImgH;
   If Sz > 0 Then Begin
    GetMem(NewP, Sz);
    Move(Src^.Paragraphs[I].ImgData^, NewP^, Sz);
    Dst^.Paragraphs[I].ImgData := NewP;
   End Else
    Dst^.Paragraphs[I].ImgData := Nil;
  End;
End;

Procedure DocSnapshotFreeImages(Snap: TDocPtr);
Var I, Sz: Integer;
Begin
 For I := 1 To Snap^.ParaCount Do
  If Snap^.Paragraphs[I].IsImage And (Snap^.Paragraphs[I].ImgData <> Nil) Then Begin
   Sz := Snap^.Paragraphs[I].ImgW * Snap^.Paragraphs[I].ImgH;
   FreeMem(Snap^.Paragraphs[I].ImgData, Sz);
   Snap^.Paragraphs[I].ImgData := Nil;
  End;
End;

Procedure DisposeSnapshot(Var Snap: TDocPtr);
Begin
 If Snap = Nil Then Exit;
 DocSnapshotFreeImages(Snap);
 Dispose(Snap);
 Snap := Nil;
End;

Procedure ClearRedoStack;
Var I: Integer;
Begin
 For I := 1 To RedoCount Do DisposeSnapshot(RedoStack[I]);
 RedoCount := 0;
End;

Procedure ClearAllUndo;
Var I: Integer;
Begin
 For I := 1 To UndoCount Do DisposeSnapshot(UndoStack[I]);
 UndoCount := 0;
 ClearRedoStack;
 LastMutate := 0;
End;

Procedure PushUndoSnapshot;
Var
 NewSnap : TDocPtr;
 I       : Integer;
Begin
 New(NewSnap);
 DocSnapshotClone(@Doc, NewSnap);
 If UndoCount >= MAX_UNDO Then Begin
  DisposeSnapshot(UndoStack[1]);
  For I := 1 To MAX_UNDO - 1 Do Begin
   UndoStack[I]   := UndoStack[I+1];
   UndoCursors[I] := UndoCursors[I+1];
  End;
  Dec(UndoCount);
 End;
 Inc(UndoCount);
 UndoStack[UndoCount]   := NewSnap;
 UndoCursors[UndoCount] := Cursor;
 ClearRedoStack;
End;

Procedure PushRedoSnapshot;
Var
 NewSnap : TDocPtr;
 I       : Integer;
Begin
 New(NewSnap);
 DocSnapshotClone(@Doc, NewSnap);
 If RedoCount >= MAX_UNDO Then Begin
  DisposeSnapshot(RedoStack[1]);
  For I := 1 To MAX_UNDO - 1 Do Begin
   RedoStack[I]   := RedoStack[I+1];
   RedoCursors[I] := RedoCursors[I+1];
  End;
  Dec(RedoCount);
 End;
 Inc(RedoCount);
 RedoStack[RedoCount]   := NewSnap;
 RedoCursors[RedoCount] := Cursor;
End;

{ Restaure depuis Snap, transfere ownership des images du snap vers Doc. }
Procedure RestoreFromSnapshot(Snap: TDocPtr; Const Cur: TCursorPos);
Begin
 FreeAllDocImages;
 Doc := Snap^;
 { Pointeurs images sont maintenant dans Doc ; on les efface du snap pour
   ne pas double-free a la disposition. }
 FillChar(Snap^, 0, 0);  { no-op, juste pour clarte }
 { On ne peut pas effacer les pointeurs du snap proprement avec un memset
   sur tout le record (ca casserait d'autres champs au reread). On parcourt. }
End;

Procedure StealImagesFromSnap(Snap: TDocPtr);
Var I: Integer;
Begin
 For I := 1 To Snap^.ParaCount Do
  If Snap^.Paragraphs[I].IsImage Then
   Snap^.Paragraphs[I].ImgData := Nil;
End;

Procedure DoUndo;
Var Snap: TDocPtr; Cur: TCursorPos;
Begin
 If UndoCount = 0 Then Begin
  StatusMsg := 'Nothing to undo'; Exit;
 End;
 PushRedoSnapshot;
 Snap := UndoStack[UndoCount];
 Cur  := UndoCursors[UndoCount];
 Dec(UndoCount);
 FreeAllDocImages;
 Doc := Snap^;
 StealImagesFromSnap(Snap);  { Doc possede maintenant les images }
 Dispose(Snap);              { libere juste le record }
 Cursor := Cur;
 NeedsRelayout := True;
 StatusMsg := 'Undo';
 LastMutate := 0;
End;

Procedure DoRedo;
Var Snap: TDocPtr; Cur: TCursorPos; NewSnap: TDocPtr;
Begin
 If RedoCount = 0 Then Begin
  StatusMsg := 'Nothing to redo'; Exit;
 End;
 { Re-push undo (sans clear du redo) }
 New(NewSnap);
 DocSnapshotClone(@Doc, NewSnap);
 If UndoCount >= MAX_UNDO Then Begin
  DisposeSnapshot(UndoStack[1]);
  Move(UndoStack[2], UndoStack[1], (MAX_UNDO-1) * SizeOf(TDocPtr));
  Move(UndoCursors[2], UndoCursors[1], (MAX_UNDO-1) * SizeOf(TCursorPos));
  Dec(UndoCount);
 End;
 Inc(UndoCount);
 UndoStack[UndoCount]   := NewSnap;
 UndoCursors[UndoCount] := Cursor;

 Snap := RedoStack[RedoCount];
 Cur  := RedoCursors[RedoCount];
 Dec(RedoCount);
 FreeAllDocImages;
 Doc := Snap^;
 StealImagesFromSnap(Snap);
 Dispose(Snap);
 Cursor := Cur;
 NeedsRelayout := True;
 StatusMsg := 'Redo';
 LastMutate := 0;
End;

{ Helper : a appeler avant toute mutation. Coalesce le typing en un seul
  snapshot par burst. }
Procedure MarkMutation(Kind: Integer);
Begin
 If (Kind = 1) And (LastMutate = 1) Then Exit;
 PushUndoSnapshot;
 LastMutate := Kind;
End;

Procedure ResetMutation;
Begin
 LastMutate := 0;
End;

{ ---- Dialogues Find / Replace haut niveau ---- }

Procedure DoFindDialog;
Var S: String;
Begin
 S := LastFindStr;
 If Not InputBoxDlg('Find', 'Find what:', S, MAX_FIND_LEN) Then Begin
  NeedsRedraw := True; Exit;
 End;
 If Length(S) = 0 Then Exit;
 LastFindStr := S;
 If FindNextFromCursor(S) Then Begin
  NeedsRelayout := True;
  StatusMsg := 'Found: ' + S;
 End Else
  ShowMessage('Not found: ' + S);
End;

Procedure DoFindNext;
Begin
 If Length(LastFindStr) = 0 Then Begin
  DoFindDialog; Exit;
 End;
 { Avance d'un cran pour ne pas re-trouver le meme }
 If Cursor.CharIdx < Length(ParaText(Cursor.ParaIdx)) Then
  Inc(Cursor.CharIdx)
 Else If Cursor.ParaIdx < Doc.ParaCount Then Begin
  Inc(Cursor.ParaIdx); Cursor.CharIdx := 0;
 End;
 If FindNextFromCursor(LastFindStr) Then Begin
  NeedsRelayout := True;
  StatusMsg := 'Found: ' + LastFindStr;
 End Else
  ShowMessage('No more matches');
End;

Procedure DoReplaceDialog;
Var
 SFind, SRepl, Ans : String;
 NReplaced         : Integer;
 K                 : Integer;
Begin
 SFind := LastFindStr;
 If Not InputBoxDlg('Replace', 'Find what:', SFind, MAX_FIND_LEN) Then Begin
  NeedsRedraw := True; Exit;
 End;
 If Length(SFind) = 0 Then Exit;
 SRepl := LastReplStr;
 If Not InputBoxDlg('Replace', 'Replace with:', SRepl, MAX_FIND_LEN) Then Begin
  NeedsRedraw := True; Exit;
 End;
 LastFindStr := SFind;
 LastReplStr := SRepl;
 Ans := 'A';
 If Not InputBoxDlg('Replace', 'Replace All? (Y/N)', Ans, 2) Then Begin
  NeedsRedraw := True; Exit;
 End;
 NReplaced := 0;
 If (Length(Ans) > 0) And ((Ans[1] = 'Y') Or (Ans[1] = 'y')) Then Begin
  { Replace All : repart du debut. }
  MarkMutation(2);
  Cursor.ParaIdx := 1; Cursor.CharIdx := 0; Cursor.RunIdx := 1;
  While FindNextFromCursor(SFind) Do Begin
   { Supprime Length(SFind) chars }
   For K := 1 To Length(SFind) Do DeleteAtCursor;
   { Insere SRepl }
   For K := 1 To Length(SRepl) Do InsertCharAtCursor(SRepl[K]);
   Inc(NReplaced);
   If NReplaced > 10000 Then Break;
  End;
  Str(NReplaced, Ans);
  StatusMsg := Ans + ' replacement(s)';
  NeedsRelayout := True;
 End Else Begin
  { Une seule occurrence depuis cursor }
  If FindNextFromCursor(SFind) Then Begin
   MarkMutation(2);
   For K := 1 To Length(SFind) Do DeleteAtCursor;
   For K := 1 To Length(SRepl) Do InsertCharAtCursor(SRepl[K]);
   StatusMsg := 'Replaced';
   NeedsRelayout := True;
  End Else
   ShowMessage('Not found: ' + SFind);
 End;
End;

Procedure ExecAction(Act: Integer);
Var
 FNameTmp : String;
 ImgBuf   : Pointer;
 IW, IH   : Integer;
 Ext      : String;
 LF       : Integer;
 CC       : Char;
 LoadOK   : Boolean;
Begin
 Case Act Of
  ACT_FILE_NEW    : Begin
                     If Doc.Modified Then
                      If Not ShowConfirmYN('Discard unsaved changes?') Then Exit;
                     InitDocument; LayoutDocument;
                     ClearAllUndo;
                     StatusMsg := 'New document'; NeedsRedraw := True;
                    End;
  ACT_FILE_OPEN   : Begin
                     If Doc.Modified Then
                      If Not ShowConfirmYN('Discard unsaved changes?') Then Exit;
                     FNameTmp := '';
                     If ShowFileDialog('Open Document', False, '*.WPD;*.DOCX;*.DOC', FNameTmp) Then Begin
                      EnsureDocExt(FNameTmp, ExtIsDocx(FNameTmp));
                      If LoadAnyDocument(FNameTmp) Then Begin
                       LayoutDocument;
                       ClearAllUndo;
                       StatusMsg := 'Opened ' + FNameTmp;
                      End Else
                       ShowMessage('Cannot open file: ' + FNameTmp);
                     End;
                     NeedsRedraw := True;
                    End;
  ACT_FILE_SAVE   : Begin
                     FNameTmp := Doc.FileName;
                     If (FNameTmp = '') Or (FNameTmp = 'Document1') Then Begin
                      If Not ShowFileDialog('Save Document', True, '*.WPD;*.DOCX', FNameTmp) Then Begin
                      { .DOC en sortie n'est pas supporte (Phase 9 lecture seule) }
                       NeedsRedraw := True; Exit;
                      End;
                     End;
                     EnsureDocExt(FNameTmp, ExtIsDocx(FNameTmp));
                     If SaveAnyDocument(FNameTmp) Then Begin
                      Doc.FileName := FNameTmp;
                      Doc.Modified := False;
                      StatusMsg := 'Saved ' + FNameTmp;
                     End Else
                      ShowMessage('Cannot save file: ' + FNameTmp);
                     NeedsRedraw := True;
                    End;
  ACT_FILE_SAVEAS : Begin
                     FNameTmp := Doc.FileName;
                     If FNameTmp = 'Document1' Then FNameTmp := '';
                     If ShowFileDialog('Save As', True, '*.WPD;*.DOCX', FNameTmp) Then Begin
                      EnsureDocExt(FNameTmp, ExtIsDocx(FNameTmp));
                      If ExtIsDoc(FNameTmp) And (Not ExtIsDocx(FNameTmp)) Then Begin
                       ShowMessage('Cannot save as .DOC (read-only format)');
                       NeedsRedraw := True; Exit;
                      End;
                      If SaveAnyDocument(FNameTmp) Then Begin
                       Doc.FileName := FNameTmp;
                       Doc.Modified := False;
                       StatusMsg := 'Saved ' + FNameTmp;
                      End Else
                       ShowMessage('Cannot save file: ' + FNameTmp);
                     End;
                     NeedsRedraw := True;
                    End;
  ACT_FILE_PRINT  : ShowMessage('Print: a venir');
  ACT_FILE_EXIT   : AppShouldExit := True;

  ACT_EDIT_UNDO   : DoUndo;
  ACT_EDIT_REDO   : DoRedo;
  ACT_EDIT_CUT    : StatusMsg := 'Cut (Phase 2+)';
  ACT_EDIT_COPY   : StatusMsg := 'Copy (Phase 2+)';
  ACT_EDIT_PASTE  : StatusMsg := 'Paste (Phase 2+)';
  ACT_EDIT_FIND   : DoFindDialog;
  ACT_EDIT_REPL   : DoReplaceDialog;
  ACT_EDIT_FIND_NEXT : DoFindNext;

  ACT_VIEW_NORMAL : StatusMsg := 'View: Normal';
  ACT_VIEW_PAGE   : StatusMsg := 'View: Page Layout';
  ACT_VIEW_RULER  : StatusMsg := 'Toggle Ruler';
  ACT_VIEW_ZOOM   : ShowMessage('Zoom: a venir');

  ACT_INS_PAGEBRK : Begin
                     If Doc.ParaCount < MAX_PARAS_PER_DOC Then Begin
                      MarkMutation(2);
                      { Si curseur n'est pas en t?te de paragraphe, splitte
                        d'abord pour que le saut de page s'applique au
                        nouveau paragraphe. }
                      If Cursor.CharIdx > 0 Then NewParagraphAtCursor
                      Else If Cursor.ParaIdx > 1 Then ;
                      Doc.Paragraphs[Cursor.ParaIdx].PageBreakBefore := True;
                      Doc.Modified  := True;
                      NeedsRelayout := True;
                      StatusMsg := 'Page break inserted';
                     End;
                    End;
  ACT_INS_IMAGE   : Begin
                     FNameTmp := '';
                     If ShowFileDialog('Insert Picture', False,
                      '*.BMP;*.PCX;*.BGX;*.XBM;*.TIF;*.TIFF;*.GIF;*.JPG;*.JPEG', FNameTmp) Then Begin
                      LoadOK := False; ImgBuf := Nil; IW := 0; IH := 0;
                      LoadOK := LoadAnyImage(FNameTmp, ImgBuf, IW, IH);
                      If LoadOK Then Begin
                       MarkMutation(2);
                       InsertImageAtCursor(ImgBuf, IW, IH);
                       LayoutDocument;
                       StatusMsg := 'Picture inserted: ' + FNameTmp;
                      End Else
                       ShowMessage('Cannot load image: ' + FNameTmp);
                     End;
                     NeedsRedraw := True;
                    End;
  ACT_INS_SYMBOL  : ShowMessage('Insert Symbol: a venir');
  ACT_INS_TABLE   : ShowMessage('Insert Table: a venir');

  ACT_FMT_FONT    : ShowMessage('Font dialog: Phase 3');
  ACT_FMT_PARA    : ShowMessage('Paragraph dialog: Phase 4');
  ACT_FMT_BOLD    : Begin
                     If SelHasRange Then Begin
                      MarkMutation(2);
                      SelApplyStyleBit(STY_BOLD);
                     End;
                     CurrentStyle.Style := CurrentStyle.Style Xor STY_BOLD;
                     FmtBar[1].Pressed := (CurrentStyle.Style And STY_BOLD) <> 0;
                     StatusMsg := 'Toggle Bold';
                    End;
  ACT_FMT_ITALIC  : Begin
                     If SelHasRange Then Begin
                      MarkMutation(2);
                      SelApplyStyleBit(STY_ITALIC);
                     End;
                     CurrentStyle.Style := CurrentStyle.Style Xor STY_ITALIC;
                     FmtBar[2].Pressed := (CurrentStyle.Style And STY_ITALIC) <> 0;
                     StatusMsg := 'Toggle Italic';
                    End;
  ACT_FMT_UNDER   : Begin
                     If SelHasRange Then Begin
                      MarkMutation(2);
                      SelApplyStyleBit(STY_UNDERLINE);
                     End;
                     CurrentStyle.Style := CurrentStyle.Style Xor STY_UNDERLINE;
                     FmtBar[3].Pressed := (CurrentStyle.Style And STY_UNDERLINE) <> 0;
                     StatusMsg := 'Toggle Underline';
                    End;
  ACT_FMT_LEFT    : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_LEFT;
                     Doc.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_LEFT;
                     FmtBar[4].Pressed := True;  FmtBar[5].Pressed := False;
                     FmtBar[6].Pressed := False; FmtBar[7].Pressed := False;
                     Doc.Modified := True; NeedsRelayout := True;
                     StatusMsg := 'Align Left';
                    End;
  ACT_FMT_CENTER  : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_CENTER;
                     Doc.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_CENTER;
                     FmtBar[4].Pressed := False; FmtBar[5].Pressed := True;
                     FmtBar[6].Pressed := False; FmtBar[7].Pressed := False;
                     Doc.Modified := True; NeedsRelayout := True;
                     StatusMsg := 'Align Center';
                    End;
  ACT_FMT_RIGHT   : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_RIGHT;
                     Doc.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_RIGHT;
                     FmtBar[4].Pressed := False; FmtBar[5].Pressed := False;
                     FmtBar[6].Pressed := True;  FmtBar[7].Pressed := False;
                     Doc.Modified := True; NeedsRelayout := True;
                     StatusMsg := 'Align Right';
                    End;
  ACT_FMT_JUSTIFY : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_JUSTIFY;
                     Doc.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_JUSTIFY;
                     FmtBar[4].Pressed := False; FmtBar[5].Pressed := False;
                     FmtBar[6].Pressed := False; FmtBar[7].Pressed := True;
                     Doc.Modified := True; NeedsRelayout := True;
                     StatusMsg := 'Justify';
                    End;
  ACT_FMT_COLOR   : Begin
                     CurrentStyle.Color := (CurrentStyle.Color + 1) And 15;
                     If CurrentStyle.Color = 0 Then
                      StatusMsg := 'Color: Black'
                     Else Begin
                      Str(CurrentStyle.Color, StatusMsg);
                      StatusMsg := 'Color #' + StatusMsg;
                     End;
                    End;

  ACT_TLS_SPELL   : ShowMessage('Spelling: a venir');
  ACT_TLS_WORDS   : ShowWordCountDialog;
  ACT_TLS_OPTIONS : ShowMessage('Options: a venir');

  ACT_TBL_INSERT  : ShowMessage('Insert Table: a venir');
  ACT_TBL_DELETE  : ShowMessage('Delete Table: a venir');

  ACT_WIN_CASCADE : StatusMsg := 'Cascade (single-doc)';

  ACT_HLP_CONTENT : ShowMessage('Help Contents (a venir)');
  ACT_HLP_ABOUT   : ShowMessage('Word Clone v1.0 - Pascal/Graph');
 Else
  StatusMsg := 'Action non implementee';
 End;
End;

{ ============================================================ }
{ =====================  BO??TE MESSAGE  ====================== }
{ ============================================================ }

Procedure ShowMessage(Const S: String);
Var
 X1, Y1, X2, Y2 : Integer;
 K              : Word;
 Done           : Boolean;
Begin
 X1 := 120; X2 := 520;
 Y1 := 180; Y2 := 280;
 EraseSoftCursor;
 { Ombre }
 FillRectArea(X1+5, Y2+1, X2+5, Y2+5, Black);
 FillRectArea(X2+1, Y1+5, X2+5, Y2+5, Black);
 { Cadre }
 FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
 DrawButton3D(X1, Y1, X2, Y2, False);
 { Titre }
 FillRectArea(X1+3, Y1+3, X2-3, Y1+18, Blue);
 DrawTextAt(X1+8, Y1+6, 'Word Clone', White);
 { Message }
 DrawTextAt(X1+16, Y1+40, S, Black);
 { Bouton OK }
 DrawButton3D(X1+160, Y2-30, X1+240, Y2-10, False);
 DrawTextAt(X1+190, Y2-26, 'OK', Black);

 {$IFDEF FPC} DrawSoftCursor(MsX, MsY); {$ENDIF}

 Done := False;
 Repeat
  If KeyPressed Then Begin
   K := ReadKeyEx;
   If (K = KEY_ENTER) Or (K = KEY_ESC) Or (K = Ord(' ')) Then
    Done := True;
  End;
  GetMouseStateLI(MsX, MsY, MsBtn);
  If ((MsBtn And MB_LEFT) <> 0) And
     (MsX >= X1+160) And (MsX <= X1+240) And
     (MsY >= Y2-30) And (MsY <= Y2-10) Then
   Done := True;
 Until Done;

 { Attendre rel??chement souris pour ??viter clic transmis }
 Repeat
  GetMouseStateLI(MsX, MsY, MsBtn);
 Until (MsBtn And MB_LEFT) = 0;

 NeedsRedraw := True;
End;

{ ============================================================ }
{ =====================  GESTION CLAVIER  ==================== }
{ ============================================================ }

{ Trouve un menu par sa lettre Alt (insensible ?? la casse) }
Function FindMenuByAlt(Alt: Char): Integer;
Var I, R: Integer;
Begin
 R := 0;
 For I := 1 To MenuCount Do
  If UpCase(Menus[I].AltKey) = UpCase(Alt) Then R := I;
 FindMenuByAlt := R;
End;

{ Trouve un item de menu par sa lettre Alt }
Function FindItemByAlt(M: Integer; Alt: Char): Integer;
Var I, R: Integer;
Begin
 R := 0;
 For I := 1 To Menus[M].ItemCount Do
  If (Not Menus[M].Items[I].Separator) And
     (UpCase(Menus[M].Items[I].AltKey) = UpCase(Alt)) Then R := I;
 FindItemByAlt := R;
End;

Procedure HandleMenuKey(K: Word);
Var Idx, SavedM: Integer;
Begin
 Case K Of
  KEY_ESC: Begin ActiveMenu := 0; MenuItemHover := 0;
                 MenuKeyboardMode := False; End;
  KEY_LEFT: Begin
   Dec(ActiveMenu); If ActiveMenu < 1 Then ActiveMenu := MenuCount;
   MenuItemHover := 1;
  End;
  KEY_RIGHT: Begin
   Inc(ActiveMenu); If ActiveMenu > MenuCount Then ActiveMenu := 1;
   MenuItemHover := 1;
  End;
  KEY_UP: Begin
   Repeat
    Dec(MenuItemHover);
    If MenuItemHover < 1 Then MenuItemHover := Menus[ActiveMenu].ItemCount;
   Until Not Menus[ActiveMenu].Items[MenuItemHover].Separator;
  End;
  KEY_DOWN: Begin
   Repeat
    Inc(MenuItemHover);
    If MenuItemHover > Menus[ActiveMenu].ItemCount Then MenuItemHover := 1;
   Until Not Menus[ActiveMenu].Items[MenuItemHover].Separator;
  End;
  KEY_ENTER: Begin
   If (MenuItemHover >= 1) And
      (Not Menus[ActiveMenu].Items[MenuItemHover].Separator) Then Begin
    SavedM := ActiveMenu;
    Idx := Menus[SavedM].Items[MenuItemHover].ActionId;
    ActiveMenu := 0; MenuItemHover := 0;
    MenuKeyboardMode := False;
    ExecAction(Idx);
   End;
  End;
 Else
  { Lettre Alt ??? item du menu actif }
  If (K >= Ord('A')) And (K <= Ord('z')) Then Begin
   SavedM := ActiveMenu;
   Idx := FindItemByAlt(SavedM, Chr(K));
   If Idx > 0 Then Begin
    ActiveMenu := 0; MenuItemHover := 0;
    MenuKeyboardMode := False;
    ExecAction(Menus[SavedM].Items[Idx].ActionId);
   End;
  End;
 End;
End;

{ Raccourcis Ctrl+X au niveau application. ReadKey retourne #1..#26. }
Procedure HandleCtrlKey(C: Char);
Begin
 Case C Of
  #14: ExecAction(ACT_FILE_NEW);    { Ctrl+N }
  #15: ExecAction(ACT_FILE_OPEN);   { Ctrl+O }
  #19: ExecAction(ACT_FILE_SAVE);   { Ctrl+S }
  #16: ExecAction(ACT_FILE_PRINT);  { Ctrl+P }
  #26: ExecAction(ACT_EDIT_UNDO);   { Ctrl+Z }
  #25: ExecAction(ACT_EDIT_REDO);   { Ctrl+Y }
  #24: ExecAction(ACT_EDIT_CUT);    { Ctrl+X }
  #03: ExecAction(ACT_EDIT_COPY);   { Ctrl+C }
  #22: ExecAction(ACT_EDIT_PASTE);  { Ctrl+V }
  #06: ExecAction(ACT_EDIT_FIND);   { Ctrl+F }
  #08: ExecAction(ACT_EDIT_REPL);   { Ctrl+H }
  #02: ExecAction(ACT_FMT_BOLD);    { Ctrl+B }
  #09: ExecAction(ACT_FMT_ITALIC);  { Ctrl+I (Tab=#9 aussi) }
  #21: ExecAction(ACT_FMT_UNDER);   { Ctrl+U }
  #12: ExecAction(ACT_FMT_LEFT);    { Ctrl+L }
  #05: ExecAction(ACT_FMT_CENTER);  { Ctrl+E }
  #18: ExecAction(ACT_FMT_RIGHT);   { Ctrl+R }
 End;
End;

Procedure HandleKey(K: Word);
Begin
 If ActiveMenu > 0 Then Begin
  HandleMenuKey(K);
  Exit;
 End;

 { Toute action de navigation / edition annule la selection en cours. }
 If Sel.Active Then
  If (K = KEY_LEFT) Or (K = KEY_RIGHT) Or (K = KEY_UP) Or (K = KEY_DOWN) Or
     (K = KEY_HOME) Or (K = KEY_END) Or (K = KEY_PGUP) Or (K = KEY_PGDN) Or
     (K = KEY_BACKSPACE) Or (K = KEY_DEL) Or (K = KEY_ENTER) Or
     (K = KEY_TAB) Or ((K >= 32) And (K <= 126)) Then SelClear;

 Case K Of
  KEY_F10: Begin
   ActiveMenu := 1; MenuItemHover := 1; MenuKeyboardMode := True;
  End;
  KEY_ESC: ;
  KEY_ALT_F: Begin ActiveMenu := 1; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_E: Begin ActiveMenu := 2; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_V: Begin ActiveMenu := 3; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_I: Begin ActiveMenu := 4; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_O: Begin ActiveMenu := 5; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_T: Begin ActiveMenu := 6; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_A: Begin ActiveMenu := 7; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_W: Begin ActiveMenu := 8; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_H: Begin ActiveMenu := 9; MenuItemHover := 1; MenuKeyboardMode := True; End;
  KEY_ALT_X: ExecAction(ACT_FILE_EXIT);
  KEY_F1   : ExecAction(ACT_HLP_CONTENT);
  KEY_F3   : ExecAction(ACT_EDIT_FIND_NEXT);

  { ----- Navigation ----- }
  KEY_LEFT : Begin CursorMoveLeft;  ResetMutation; End;
  KEY_RIGHT: Begin CursorMoveRight; ResetMutation; End;
  KEY_UP   : Begin CursorVerticalMove(-1); ResetMutation; End;
  KEY_DOWN : Begin CursorVerticalMove(1);  ResetMutation; End;
  KEY_HOME : Begin CursorMoveHome; ResetMutation; End;
  KEY_END  : Begin CursorMoveEnd;  ResetMutation; End;
  KEY_PGUP : Begin CursorPageUp;   ResetMutation; End;
  KEY_PGDN : Begin CursorPageDown; ResetMutation; End;

  { ----- Edition ----- }
  KEY_BACKSPACE: Begin MarkMutation(2); BackspaceAtCursor; End;
  KEY_DEL      : Begin MarkMutation(2); DeleteAtCursor; End;
  KEY_ENTER    : Begin MarkMutation(2); NewParagraphAtCursor; End;
  KEY_TAB      : Begin MarkMutation(1); InsertCharAtCursor(' '); End;
 Else
  If (K >= 32) And (K <= 126) Then Begin
   MarkMutation(1);
   InsertCharAtCursor(Chr(K));
  End Else If (K >= 1) And (K <= 26) Then
   HandleCtrlKey(Chr(K));
 End;

 { Toute frappe relance le clignotement }
 CursorBlinkOn  := True;
 CursorBlinkCnt := 0;
End;

{ ============================================================ }
{ =====================  GESTION SOURIS  ===================== }
{ ============================================================ }

Function PointInRect(Px, Py, X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 PointInRect := (Px >= X1) And (Px <= X2) And
                (Py >= Y1) And (Py <= Y2);
End;

{ Identifie le menu sous (X,Y) dans la barre de menus ; 0 sinon. }
Function MenuAtPoint(X, Y: LongInt): Integer;
Var I, R: Integer;
Begin
 R := 0;
 If (Y >= MENUBAR_TOP) And (Y < MENUBAR_TOP+MENUBAR_HEIGHT) Then
  For I := 1 To MenuCount Do
   If (X >= Menus[I].X1) And (X <= Menus[I].X2) Then R := I;
 MenuAtPoint := R;
End;

{ Item du dropdown sous (X,Y) ; 0 sinon. }
Function DropItemAtPoint(X, Y: LongInt): Integer;
Var
 X1, Y1, X2, Y2, IH, I, R : Integer;
Begin
 R := 0;
 If ActiveMenu < 1 Then Begin DropItemAtPoint := 0; Exit; End;
 IH := 16;
 X1 := Menus[ActiveMenu].X1;
 Y1 := MENUBAR_HEIGHT;
 X2 := X1 + Menus[ActiveMenu].DropW;
 Y2 := Y1 + Menus[ActiveMenu].ItemCount * IH + 4;
 If X2 > SCREEN_W-1 Then Begin
  X1 := SCREEN_W-1 - Menus[ActiveMenu].DropW;
  X2 := SCREEN_W-1;
 End;
 If (X >= X1) And (X <= X2) And (Y >= Y1+2) And (Y <= Y2) Then Begin
  I := ((Y - (Y1+2)) Div IH) + 1;
  If (I >= 1) And (I <= Menus[ActiveMenu].ItemCount) Then R := I;
 End;
 DropItemAtPoint := R;
End;

Function StdBtnAtPoint(X, Y: LongInt): Integer;
Var I, R: Integer;
Begin
 R := 0;
 For I := 1 To StdBarCount Do
  If PointInRect(X, Y, StdBar[I].X, StdBar[I].Y,
                 StdBar[I].X+StdBar[I].W, StdBar[I].Y+StdBar[I].H) Then R := I;
 StdBtnAtPoint := R;
End;

Function FmtBtnAtPoint(X, Y: LongInt): Integer;
Var I, R: Integer;
Begin
 R := 0;
 For I := 1 To FmtBarCount Do
  If PointInRect(X, Y, FmtBar[I].X, FmtBar[I].Y,
                 FmtBar[I].X+FmtBar[I].W, FmtBar[I].Y+FmtBar[I].H) Then R := I;
 FmtBtnAtPoint := R;
End;

{ Convertit (Mx,My) en position document la plus proche.
  Renvoie False si aucune ligne visuelle disponible. }
Function MouseToDocPos(Mx, My: LongInt; Var P, C: Integer): Boolean;
Var
 I, Best, Off, BestOff, BestDist, D : Integer;
 TestX, LineY                       : Integer;
 ParaStr, Pre                       : String;
Begin
 P := 0; C := 0;
 If VLineCount = 0 Then Begin MouseToDocPos := False; Exit; End;
 Best := 0;
 BestDist := 32767;
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 1 To VLineCount Do Begin
  If VLines[I].IsImage Then Continue;
  LineY := VLines[I].Y - ScrollY;
  If My < LineY Then D := LineY - My
  Else If My > LineY + LINE_HEIGHT - 1 Then D := My - (LineY + LINE_HEIGHT - 1)
  Else D := 0;
  If D < BestDist Then Begin BestDist := D; Best := I; End;
 End;
 If Best = 0 Then Begin MouseToDocPos := False; Exit; End;
 ParaStr := ParaText(VLines[Best].ParaIdx);
 BestOff := 0;
 BestDist := 32767;
 For Off := 0 To VLines[Best].CharLen Do Begin
  Pre := Copy(ParaStr, VLines[Best].CharStart, Off);
  TestX := VLines[Best].X + TextWidth(Pre);
  D := TestX - Mx;
  If D < 0 Then D := -D;
  If D < BestDist Then Begin BestDist := D; BestOff := Off; End;
 End;
 P := VLines[Best].ParaIdx;
 C := VLines[Best].CharStart - 1 + BestOff;
 MouseToDocPos := True;
End;

Function PointInDocArea(X, Y: LongInt): Boolean;
Begin
 PointInDocArea := (Y >= DOCAREA_TOP) And (Y <= DOCAREA_BOTTOM);
End;

Procedure HandleMouse;
Var
 LeftDown, LeftPressed, LeftReleased: Boolean;
 RightDown                          : Boolean;
 M, Itm, B                          : Integer;
 NewP, NewC                         : Integer;
Begin
 LastMsBtn := MsBtn;
 GetMouseStateLI(MsX, MsY, MsBtn);
 LeftDown     := (MsBtn And MB_LEFT) <> 0;
 LeftPressed  := LeftDown And ((LastMsBtn And MB_LEFT) = 0);
 LeftReleased := (Not LeftDown) And ((LastMsBtn And MB_LEFT) <> 0);
 RightDown    := (MsBtn And MB_RIGHT) <> 0;

 { Survol toolbars }
 HoveredStdBtn := StdBtnAtPoint(MsX, MsY);
 HoveredFmtBtn := FmtBtnAtPoint(MsX, MsY);

 { Survol barre de menus : si un menu est deja ouvert et la souris
   passe au-dessus d'un AUTRE menu de la barre, on bascule. }
 If ActiveMenu > 0 Then Begin
  M := MenuAtPoint(MsX, MsY);
  If (M > 0) And (M <> ActiveMenu) Then Begin
   ActiveMenu := M;
   MenuItemHover := 1;
   MenuKeyboardMode := False;
  End;
 End;

 { Survol dropdown menu actif : la souris choisit l'item courant. }
 If ActiveMenu > 0 Then Begin
  Itm := DropItemAtPoint(MsX, MsY);
  If (Itm > 0) And (Not Menus[ActiveMenu].Items[Itm].Separator) Then Begin
   MenuItemHover := Itm;
   MenuKeyboardMode := False;
  End;
 End;

 { ----- Click gauche ----- }
 If LeftPressed Then Begin
  M := MenuAtPoint(MsX, MsY);
  If M > 0 Then Begin
   If ActiveMenu = M Then ActiveMenu := 0
   Else Begin
    ActiveMenu := M; MenuItemHover := 1;
    MenuKeyboardMode := False;
   End;
  End Else If ActiveMenu > 0 Then Begin
   { Clic dans dropdown ou ailleurs }
   Itm := DropItemAtPoint(MsX, MsY);
   If (Itm > 0) And
      (Not Menus[ActiveMenu].Items[Itm].Separator) Then Begin
    B := Menus[ActiveMenu].Items[Itm].ActionId;
    ActiveMenu := 0; MenuItemHover := 0;
    ExecAction(B);
   End Else
    ActiveMenu := 0;
  End Else If HoveredStdBtn > 0 Then Begin
   { rien : on agit au release pour effet bouton enfonc?? visuel }
  End Else If HoveredFmtBtn > 0 Then Begin
   { idem }
  End Else If PointInDocArea(MsX, MsY) Then Begin
   { Clic dans la zone document : positionne le curseur et amorce
     une selection. Drag etend la selection. }
   If MouseToDocPos(MsX, MsY, NewP, NewC) Then Begin
    Cursor.ParaIdx := NewP;
    Cursor.RunIdx  := 1;
    Cursor.CharIdx := NewC;
    SelStartFromCursor;
    MouseSelecting := True;
    CursorBlinkOn  := True;
    CursorBlinkCnt := 0;
    NeedsRedraw    := True;
   End;
  End;
 End;

 { ----- Drag gauche : extension de la selection ----- }
 If LeftDown And MouseSelecting And (Not LeftPressed) Then Begin
  If MouseToDocPos(MsX, MsY, NewP, NewC) Then Begin
   If (NewP <> Cursor.ParaIdx) Or (NewC <> Cursor.CharIdx) Then Begin
    Cursor.ParaIdx := NewP;
    Cursor.RunIdx  := 1;
    Cursor.CharIdx := NewC;
    CursorBlinkOn  := True;
    CursorBlinkCnt := 0;
    NeedsRedraw    := True;
   End;
  End;
 End;

 { ----- Release gauche ----- }
 If LeftReleased Then Begin
  If MouseSelecting Then Begin
   MouseSelecting := False;
   { Selection vide => on efface l'etat selection (juste un clic). }
   If Not SelHasRange Then SelClear;
  End;
  If (ActiveMenu = 0) And (HoveredStdBtn > 0) Then
   ExecAction(StdBar[HoveredStdBtn].ActionId);
  If (ActiveMenu = 0) And (HoveredFmtBtn > 0) Then
   ExecAction(FmtBar[HoveredFmtBtn].ActionId);
 End;

 { ----- Click droit ----- }
 If RightDown And ((LastMsBtn And MB_RIGHT) = 0) Then Begin
  If ActiveMenu > 0 Then ActiveMenu := 0;
  StatusMsg := 'Menu contextuel (a venir)';
 End;
End;

{ ============================================================ }
{ =====================  RENDU COMPLET  ====================== }
{ ============================================================ }

Procedure RenderAll;
Begin
 EraseSoftCursor;
 SetViewPort(0, 0, SCREEN_W-1, SCREEN_H-1, ClipOn);

 DrawDocArea;
 DrawRuler;
 DrawStdToolbar;
 DrawFmtToolbar;
 DrawMenuBar;
 If ActiveMenu > 0 Then DrawMenuDropdown;
 DrawStatusBar;

 {$IFDEF FPC} DrawSoftCursor(MsX, MsY); {$ENDIF}
End;

{ ============================================================ }
{ =====================  BOUCLE PRINCIPALE  ================== }
{ ============================================================ }

Procedure MainLoop;
Var
 K              : Word;
 RedrawAfter    : Boolean;
 MouseOnly      : Boolean;
 CursorOnly     : Boolean;
 PrevMx,PrevMy  : LongInt;
 PrevActiveMenu : Integer;
 PrevMenuHover  : Integer;
 PrevHovStd     : Integer;
 PrevHovFmt     : Integer;
Begin
 AppShouldExit := False;
 ActiveMenu    := 0;
 MenuItemHover := 0;
 HoveredStdBtn := 0;
 HoveredFmtBtn := 0;
 MsBtn      := 0;
 LastMsBtn  := 0;
 MsX        := SCREEN_W Div 2;
 MsY        := SCREEN_H Div 2;
 PrevMx        := -1;
 PrevMy        := -1;
 PrevActiveMenu := 0;
 PrevMenuHover  := 0;
 PrevHovStd     := 0;
 PrevHovFmt     := 0;
 CursorBlinkOn := True;
 CursorBlinkCnt:= 0;
 Sel.Active     := False;
 MouseSelecting := False;
 StatusMsg     := 'Pret. F10=menu, fleches=naviguer, Alt+X=quitter.';

 LayoutDocument;
 RenderAll;

 While Not AppShouldExit Do Begin
  RedrawAfter := False;
  MouseOnly   := False;
  CursorOnly  := False;

  If KeyPressed Then Begin
   K := ReadKeyEx;
   HandleKey(K);
   If NeedsRelayout Then Begin
    LayoutDocument;
   End;
   { Toujours s'assurer que le curseur reste visible (defile la page si besoin). }
   EnsureCursorVisible;
   { Reset blink ON pendant la frappe : caret toujours visible }
   CursorBlinkOn := True;
   CursorBlinkCnt := 0;
   RedrawAfter := True;
  End;

  HandleMouse;
  If MsBtn <> LastMsBtn Then RedrawAfter := True
  Else If (MsX <> PrevMx) Or (MsY <> PrevMy) Then MouseOnly := True;

  { Tout changement d'etat de menu/toolbar du au survol force un RenderAll. }
  If (ActiveMenu <> PrevActiveMenu) Or (MenuItemHover <> PrevMenuHover) Or
     (HoveredStdBtn <> PrevHovStd) Or (HoveredFmtBtn <> PrevHovFmt) Then Begin
   RedrawAfter := True;
   MouseOnly   := False;
  End;

  If NeedsRedraw Then Begin RedrawAfter := True; NeedsRedraw := False; End;
  If NeedsRelayout Then Begin
   LayoutDocument;
   EnsureCursorVisible;
   RedrawAfter := True;
  End;

  { Clignotement curseur texte : XOR-toggle si rien d'autre a redessiner }
  Inc(CursorBlinkCnt);
  If CursorBlinkCnt >= CURSOR_BLINK_TICKS Then Begin
   CursorBlinkCnt := 0;
   CursorBlinkOn := Not CursorBlinkOn;
   If Not RedrawAfter Then CursorOnly := True;
  End;

  If RedrawAfter Then Begin
   RenderAll;
   PrevMx := MsX;
   PrevMy := MsY;
   PrevActiveMenu := ActiveMenu;
   PrevMenuHover  := MenuItemHover;
   PrevHovStd     := HoveredStdBtn;
   PrevHovFmt     := HoveredFmtBtn;
  End Else If MouseOnly Then Begin
   {$IFDEF FPC}
   EraseSoftCursor;
   DrawSoftCursor(MsX, MsY);
   {$ENDIF}
   PrevMx := MsX;
   PrevMy := MsY;
  End Else If CursorOnly Then Begin
   ToggleTextCursor;
  End;

  Delay(20);
 End;
End;

{ ============================================================ }
{ =====================  PROGRAMME PRINCIPAL  ================ }
{ ============================================================ }

BEGIN
 InitializeGraphics;
 InitMenus;
 InitToolbars;
 InitDocument;
 UndoCount := 0; RedoCount := 0; LastMutate := 0;
 LastFindStr := ''; LastReplStr := '';
 { Argument ligne de commande : nom de fichier a ouvrir au demarrage. }
 If ParamCount >= 1 Then Begin
  If LoadAnyDocument(ParamStr(1)) Then
   Doc.FileName := ParamStr(1)
  Else
   ShowMessage('Cannot open file: ' + ParamStr(1));
 End;
 MsAvailable := MouseDriverFound;
 If MsAvailable Then ShowMouse;
 MainLoop;
 If MsAvailable Then HideMouse;
 CloseGraph;
END.

