{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application PowerPoint
}

Program SR;

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
 Begin MouseDriverFound := True; End;
{$ENDIF}

{ ====================================================================== }
{                       CONSTANTES                                       }
{ ====================================================================== }

Const
 SCREEN_W      = 640;
 SCREEN_H      = 480;
 MENU_H        = 16;
 TOOL_H        = 22;
 STATUS_H      = 16;
 PANEL_W       = 100;    { panneau des miniatures a gauche }
 RULER_H       = 14;

 MAX_SLIDES        = 128;
 MAX_SHAPES        = 96;     { par diapositive }
 MAX_TEXT_LINES    = 16;     { lignes par forme texte }
 MAX_THEMES        = 8;
 MAX_IMAGES        = 16;     { images chargees globalement }
 MAX_IMG_W         = 320;
 MAX_IMG_H         = 240;
 BMP_SIGNATURE     = $4D42;

 SHAPE_NAME_LEN    = 24;
 TXT_LINE_LEN      = 96;
 TITLE_LEN         = 80;
 SLIDE_NAME_LEN    = 32;

 { Types de formes (compatibles AutoShape PowerPoint) }
 SHP_NONE        = 0;
 SHP_TITLE       = 1;     { placeholder de titre }
 SHP_CONTENT     = 2;     { placeholder de contenu / corps }
 SHP_SUBTITLE    = 3;     { sous-titre }
 SHP_TEXT        = 4;     { zone de texte libre }
 SHP_RECT        = 10;
 SHP_ROUNDRECT   = 11;
 SHP_ELLIPSE     = 12;
 SHP_LINE        = 13;
 SHP_ARROW       = 14;
 SHP_TRIANGLE    = 15;
 SHP_DIAMOND     = 16;
 SHP_PENTAGON    = 17;
 SHP_HEXAGON     = 18;
 SHP_STAR        = 19;
 SHP_HEART       = 20;
 SHP_CALLOUT     = 21;
 SHP_PARALLEL    = 22;    { parallelogramme }
 SHP_TRAPEZOID   = 23;
 SHP_CROSS       = 24;
 SHP_IMAGE       = 30;
 SHP_TABLE       = 31;
 SHP_CHART       = 32;

 { Layouts de diapositive }
 LAY_TITLE         = 0;   { titre + sous-titre centres }
 LAY_TITLE_CONTENT = 1;   { titre haut + corps }
 LAY_TWO_CONTENT   = 2;   { titre + 2 colonnes }
 LAY_COMPARISON    = 3;   { titre + 2 colonnes avec en-tetes }
 LAY_TITLE_ONLY    = 4;
 LAY_BLANK         = 5;
 LAY_CONTENT_CAPT  = 6;   { contenu + legende a gauche }
 LAY_SECTION       = 7;   { en-tete de section }

 { Vues actives }
 VIEW_NORMAL    = 0;     { editeur de slide }
 VIEW_OUTLINE   = 1;     { mode plan }
 VIEW_SORTER    = 2;     { trieuse de diapositives }
 VIEW_NOTES     = 3;     { page de commentaires }
 VIEW_SLIDESHOW = 4;     { diaporama plein ecran }

 { Outils de dessin actifs }
 TOOL_SELECT    = 0;
 TOOL_TEXT      = 1;
 TOOL_RECT      = 2;
 TOOL_ELLIPSE   = 3;
 TOOL_LINE      = 4;
 TOOL_ARROW     = 5;
 TOOL_TRIANGLE  = 6;
 TOOL_STAR      = 7;
 TOOL_CALLOUT   = 8;
 TOOL_HAND      = 9;

 { Transitions }
 TRANS_NONE     = 0;
 TRANS_FADE     = 1;
 TRANS_WIPE_L   = 2;
 TRANS_WIPE_R   = 3;
 TRANS_WIPE_U   = 4;
 TRANS_WIPE_D   = 5;
 TRANS_SPLIT    = 6;
 TRANS_CHECKER  = 7;
 TRANS_PUSH     = 8;
 TRANS_BLINDS   = 9;
 TRANS_DISSOLVE = 10;

 { Animations d'entree }
 ANIM_NONE      = 0;
 ANIM_APPEAR    = 1;
 ANIM_FADE      = 2;
 ANIM_SLIDE_L   = 3;
 ANIM_SLIDE_R   = 4;
 ANIM_SLIDE_U   = 5;
 ANIM_SLIDE_D   = 6;
 ANIM_ZOOM      = 7;
 ANIM_SPIN      = 8;

 { Alignement texte }
 ALIGN_LEFT   = 0;
 ALIGN_CENTER = 1;
 ALIGN_RIGHT  = 2;
 ALIGN_JUSTIFY = 3;

 { Couleurs VGA 16 }
 CLR_BLACK     = 0;  CLR_BLUE      = 1;  CLR_GREEN     = 2;  CLR_CYAN      = 3;
 CLR_RED       = 4;  CLR_MAGENTA   = 5;  CLR_BROWN     = 6;  CLR_LGRAY     = 7;
 CLR_DGRAY     = 8;  CLR_LBLUE     = 9;  CLR_LGREEN    = 10; CLR_LCYAN     = 11;
 CLR_LRED      = 12; CLR_LMAGENTA  = 13; CLR_YELLOW    = 14; CLR_WHITE     = 15;

 { Couleurs UI }
 CLR_WIN_BG       = 7;
 CLR_WIN_HI       = 15;
 CLR_WIN_LO       = 8;
 CLR_MENU_BG      = 7;
 CLR_MENU_FG      = 0;
 CLR_MENU_SEL_BG  = 1;
 CLR_MENU_SEL_FG  = 15;
 CLR_DLG_BG       = 7;
 CLR_DLG_TITLE_BG = 4;     { rouge/orange PowerPoint }
 CLR_DLG_TITLE_FG = 15;
 CLR_STATUS_BG    = 7;
 CLR_STATUS_FG    = 0;
 CLR_SLIDE_BG     = 15;    { fond de slide par defaut }
 CLR_SLIDE_BORD   = 8;
 CLR_PANEL_BG     = 8;     { fond panneau miniatures }
 CLR_PANEL_SEL    = 4;
 CLR_WORK_BG      = 8;     { zone de travail derriere la slide }

 { Identifiants d'actions }
 ACT_NONE         = 0;
 ACT_NEW          = 1;
 ACT_OPEN         = 2;
 ACT_SAVE         = 3;
 ACT_SAVEAS       = 4;
 ACT_CLOSE        = 5;
 ACT_PRINT        = 6;
 ACT_QUIT         = 7;
 ACT_UNDO         = 10;
 ACT_REDO         = 11;
 ACT_CUT          = 12;
 ACT_COPY         = 13;
 ACT_PASTE        = 14;
 ACT_DELETE       = 15;
 ACT_FIND         = 16;
 ACT_REPLACE      = 17;
 ACT_SELECTALL    = 18;
 ACT_DUP          = 19;
 ACT_VIEW_NORMAL  = 20;
 ACT_VIEW_OUTLINE = 21;
 ACT_VIEW_SORTER  = 22;
 ACT_VIEW_NOTES   = 23;
 ACT_VIEW_MASTER  = 24;
 ACT_NEW_SLIDE    = 30;
 ACT_DUP_SLIDE    = 31;
 ACT_DEL_SLIDE    = 32;
 ACT_MOVE_UP      = 33;
 ACT_MOVE_DOWN    = 34;
 ACT_LAYOUT       = 35;
 ACT_BACKGROUND   = 36;
 ACT_THEME        = 37;
 ACT_INS_TEXT     = 40;
 ACT_INS_RECT     = 41;
 ACT_INS_ELLIPSE  = 42;
 ACT_INS_LINE     = 43;
 ACT_INS_ARROW    = 44;
 ACT_INS_TRIANGLE = 45;
 ACT_INS_STAR     = 46;
 ACT_INS_CALLOUT  = 47;
 ACT_INS_IMAGE    = 48;
 ACT_INS_TABLE    = 49;
 ACT_INS_CHART    = 50;
 ACT_INS_HEADER   = 51;
 ACT_INS_DATE     = 52;
 ACT_INS_NUMBER   = 53;
 ACT_FONT_BOLD    = 60;
 ACT_FONT_ITAL    = 61;
 ACT_FONT_UND     = 62;
 ACT_ALIGN_LEFT   = 63;
 ACT_ALIGN_CENTER = 64;
 ACT_ALIGN_RIGHT  = 65;
 ACT_BULLET       = 66;
 ACT_NUMBERING    = 67;
 ACT_INDENT_INC   = 68;
 ACT_INDENT_DEC   = 69;
 ACT_FONT_SIZE_UP = 70;
 ACT_FONT_SIZE_DN = 71;
 ACT_COLOR_FILL   = 72;
 ACT_COLOR_LINE   = 73;
 ACT_COLOR_TEXT   = 74;
 ACT_TRANS        = 80;
 ACT_ANIM_ENTRY   = 81;
 ACT_ANIM_EXIT    = 82;
 ACT_TIMING       = 83;
 ACT_SLIDESHOW    = 90;
 ACT_SLIDESHOW_FROM = 91;
 ACT_RUN_FROM_BEG = 92;
 ACT_REHEARSE     = 93;
 ACT_GROUP        = 100;
 ACT_UNGROUP      = 101;
 ACT_BRING_FRONT  = 102;
 ACT_SEND_BACK    = 103;
 ACT_ALIGN_OBJ_L  = 104;
 ACT_ALIGN_OBJ_C  = 105;
 ACT_ALIGN_OBJ_R  = 106;
 ACT_HELP_TOPIC   = 110;
 ACT_HELP_ABOUT   = 111;
 ACT_NEXT_SLIDE   = 120;
 ACT_PREV_SLIDE   = 121;
 ACT_FIRST_SLIDE  = 122;
 ACT_LAST_SLIDE   = 123;
 ACT_ZOOM_IN      = 130;
 ACT_ZOOM_OUT     = 131;
 ACT_ZOOM_FIT     = 132;
 ACT_TOOL_SELECT  = 140;
 ACT_TOOL_TEXT    = 141;
 ACT_TOOL_RECT    = 142;
 ACT_TOOL_ELL     = 143;
 ACT_TOOL_LINE    = 144;
 ACT_TOOL_ARROW   = 145;

 { Icones (vectoriel 18x18) }
 ICO_NEW       = 1;
 ICO_OPEN      = 2;
 ICO_SAVE      = 3;
 ICO_PRINT     = 4;
 ICO_CUT       = 5;
 ICO_COPY      = 6;
 ICO_PASTE     = 7;
 ICO_UNDO      = 8;
 ICO_REDO      = 9;
 ICO_NEWSLIDE  = 10;
 ICO_DELSLIDE  = 11;
 ICO_TEXT      = 12;
 ICO_RECT      = 13;
 ICO_ELLIPSE   = 14;
 ICO_LINE      = 15;
 ICO_ARROW     = 16;
 ICO_TRIANGLE  = 17;
 ICO_STAR      = 18;
 ICO_IMAGE     = 19;
 ICO_TABLE     = 20;
 ICO_BOLD      = 21;
 ICO_ITAL      = 22;
 ICO_UND       = 23;
 ICO_ALIGN_L   = 24;
 ICO_ALIGN_C   = 25;
 ICO_ALIGN_R   = 26;
 ICO_BULLET    = 27;
 ICO_FILL      = 28;
 ICO_PEN       = 29;
 ICO_SLIDESHOW = 30;
 ICO_HELP      = 31;
 ICO_SELECT    = 32;
 ICO_FONT      = 33;
 ICO_TRANS     = 34;
 ICO_ANIM      = 35;

{ ====================================================================== }
{                       TYPES                                            }
{ ====================================================================== }

Type
 TShapeName = String[SHAPE_NAME_LEN];
 TTxtLine   = String[TXT_LINE_LEN];
 TTitleStr  = String[TITLE_LEN];
 TSlideName = String[SLIDE_NAME_LEN];

 PShape = ^TShape;
 TShape = Record
  Name        : TShapeName;
  ShType      : Byte;          { SHP_* }
  X, Y        : Integer;       { coordonnees logiques (slide 1000x750) }
  W, H        : Integer;
  FillColor   : Byte;
  LineColor   : Byte;
  LineWidth   : Byte;
  Filled      : Boolean;
  Rotation    : Integer;       { 0..359, simplifie }
  ZOrder      : Integer;
  Locked      : Boolean;
  Hidden      : Boolean;
  { Texte (utilise pour SHP_TITLE/CONTENT/TEXT/SUBTITLE) }
  TxtCount    : Integer;
  Text        : Array[1..MAX_TEXT_LINES] Of TTxtLine;
  Bullets     : Array[1..MAX_TEXT_LINES] Of Boolean;
  Indent      : Array[1..MAX_TEXT_LINES] Of Byte;
  Bold        : Boolean;
  Italic      : Boolean;
  Underline   : Boolean;
  FontSize    : Byte;          { 8..72 }
  TextColor   : Byte;
  Align       : Byte;
  { Image (index dans Pres.Images) }
  ImageIdx    : Integer;
  { Animations attachees }
  AnimEntry   : Byte;
  AnimExit    : Byte;
  AnimOrder   : Byte;
 End;

 PSlide = ^TSlide;
 TSlide = Record
  Name        : TSlideName;
  Title       : TTitleStr;
  Layout      : Byte;
  Background  : Byte;
  Theme       : Byte;
  Transition  : Byte;
  TransSpeed  : Byte;        { 0=lent 1=moyen 2=rapide }
  Notes       : String;
  Hidden      : Boolean;
  ShCount     : Integer;
  Shapes      : Array[1..MAX_SHAPES] Of PShape;
  Dirty       : Boolean;
 End;

 TTheme = Record
  Name        : String[32];
  BgColor     : Byte;
  TitleColor  : Byte;
  TextColor   : Byte;
  AccentColor : Byte;
  FontSize    : Byte;
 End;

 PImage = ^TImage;
 TImagePixels = Array[0..199999] Of Byte;
 PImagePixels = ^TImagePixels;
 TImage = Record
  Name   : String[40];
  FileName : String[80];
  W, H   : Integer;
  Loaded : Boolean;
  Pixels : PImagePixels;     { palette 0..15 indexee, W*H octets, Nil si vide }
 End;

 TPresentation = Record
  Name        : String[40];
  FileName    : String[80];
  Author      : String[40];
  Company     : String[60];
  Title       : String[80];
  Subject     : String[80];
  Comments    : String[120];
  SldCount    : Integer;
  Slides      : Array[1..MAX_SLIDES] Of PSlide;
  ThemeIdx    : Integer;
  Themes      : Array[1..MAX_THEMES] Of TTheme;
  ThemeCount  : Integer;
  ImgCount    : Integer;
  Images      : Array[1..MAX_IMAGES] Of PImage;
  Dirty       : Boolean;
  { Phase 6 : masque + en-tete/pied de page }
  HeaderText    : String[60];
  FooterText    : String[60];
  DateText      : String[20];
  ShowHeader    : Boolean;
  ShowFooter    : Boolean;
  ShowDate      : Boolean;
  ShowSlideNum  : Boolean;
  MasterBg      : Byte;        { fond par defaut applique aux nouvelles slides }
  MasterTitleC  : Byte;        { couleur titre par defaut }
  MasterTextC   : Byte;        { couleur texte par defaut }
  EditingMaster : Boolean;     { mode masque actif }
 End;

 TMouseState = Record
  X, Y, B : LongInt;
 End;

 TMenuItem = Record
  Caption  : String[32];
  Shortcut : String[12];
  IsSep    : Boolean;
  Action   : Integer;
  Enabled  : Boolean;
 End;

 TMenu = Record
  Caption : String[16];
  X1, X2  : Integer;
  Count   : Integer;
  Items   : Array[1..28] Of TMenuItem;
 End;

 TToolButton = Record
  Icon    : Integer;
  Hint    : String[40];
  Action  : Integer;
  IsSep   : Boolean;
  Enabled : Boolean;
  Toggle  : Boolean;     { bouton bistable (outils de dessin) }
  Down    : Boolean;
  X1,Y1,X2,Y2 : Integer;
 End;

{ ====================================================================== }
{                       VARIABLES GLOBALES                               }
{ ====================================================================== }

Const
 VGA_R : Array[0..15] Of Byte =
  (  0,   0,   0,   0, 168, 168, 168, 168,  84,  84,  84,  84, 252, 252, 252, 252);
 VGA_G : Array[0..15] Of Byte =
  (  0,   0, 168, 168,   0,   0,  84, 168,  84,  84, 252, 252,  84,  84, 252, 252);
 VGA_B : Array[0..15] Of Byte =
  (  0, 168,   0, 168,   0, 168,   0, 168,  84, 252,  84, 252,  84, 252,  84, 252);

Var
 Pres            : TPresentation;
 CurSlide        : Integer;          { 1..SldCount, 0 si vide }
 CurShape        : Integer;          { 0=aucune }
 CurView         : Integer;
 CurTool         : Integer;          { TOOL_* }
 PanelScroll     : Integer;          { defilement panneau miniatures }
 SorterScroll    : Integer;
 SorterSel       : Integer;
 OutlineScroll   : Integer;
 OutlineSel      : Integer;

 { Zone de travail (slide affichee) }
 SlideX1, SlideY1, SlideX2, SlideY2 : Integer;
 SlideScale     : Integer;       { % zoom }

 { Edition }
 EditMode       : Boolean;
 EditBuf        : String;
 EditCaret      : Integer;
 EditLine       : Integer;        { ligne en cours d'edition dans la forme }
 BlinkState     : Boolean;

 { Drag/drop / dessin }
 Dragging       : Boolean;
 DragShapeIdx   : Integer;
 DragStartX     : Integer;
 DragStartY     : Integer;
 DragOrigX      : Integer;
 DragOrigY      : Integer;
 DrawingNew     : Boolean;
 DrawStartX     : Integer;
 DrawStartY     : Integer;
 DrawCurX       : Integer;
 DrawCurY       : Integer;
 { Phase 2 - manipulation interactive }
 DragMode       : Byte;          { 0=none 1=move 2=resize 3=newshape 4=marquee }
 DragHandle     : Byte;          { 1..8 (NW,N,NE,E,SE,S,SW,W) }
 DragShapeKind  : Byte;          { SHP_* a creer en mode 3 }
 DragOrigW      : Integer;
 DragOrigH      : Integer;
 RubberValid    : Boolean;
 RubberX1, RubberY1, RubberX2, RubberY2: Integer;
 LastMouseX     : Integer;
 LastMouseY     : Integer;

 { Mouse }
 Mouse          : TMouseState;
 LastClickB     : LongInt;
 LastClickX     : LongInt;
 LastClickY     : LongInt;
 LastClickTime  : LongInt;
 DoubleClicked  : Boolean;

 { Menus }
 Menus          : Array[1..16] Of TMenu;
 MenuCount      : Integer;
 MenuOpen       : Integer;       { 0 = aucun }
 MenuHover      : Integer;
 MenuItemHover  : Integer;
 MenuY1, MenuY2 : Integer;

 { Toolbar }
 Tools          : Array[1..40] Of TToolButton;
 ToolCount      : Integer;
 ToolHover      : Integer;
 ToolY1, ToolY2 : Integer;

 { Etat global }
 TickCount      : LongInt;
 NeedFullRedraw : Boolean;
 NeedSlideRedraw: Boolean;
 NeedPanelRedraw: Boolean;
 NeedStatRedraw : Boolean;
 Quitting       : Boolean;
 StatusMsg      : String;

{ ====================================================================== }
{                       UTILITAIRES STRING                               }
{ ====================================================================== }

Function IntToStr(N: LongInt): String;
Var S: String;
Begin
 Str(N, S); IntToStr := S;
End;

Function StrToIntDef(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; Code: Integer;
Begin
 Val(S, V, Code);
 If Code = 0 Then StrToIntDef := V Else StrToIntDef := Def;
End;

Function UpperStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do R[I] := UpCase(R[I]);
 UpperStr := R;
End;

Function TrimStr(Const S: String): String;
Var A, B: Integer;
Begin
 A := 1; B := Length(S);
 While (A <= B) And (S[A] <= ' ') Do Inc(A);
 While (B >= A) And (S[B] <= ' ') Do Dec(B);
 TrimStr := Copy(S, A, B - A + 1);
End;

Function MinI(A, B: LongInt): LongInt;
Begin If A < B Then MinI := A Else MinI := B; End;

Function MaxI(A, B: LongInt): LongInt;
Begin If A > B Then MaxI := A Else MaxI := B; End;

Function LayoutName(L: Byte): String;
Begin
 Case L Of
  LAY_TITLE         : LayoutName := 'Diapositive de titre';
  LAY_TITLE_CONTENT : LayoutName := 'Titre et contenu';
  LAY_TWO_CONTENT   : LayoutName := 'Deux contenus';
  LAY_COMPARISON    : LayoutName := 'Comparaison';
  LAY_TITLE_ONLY    : LayoutName := 'Titre seul';
  LAY_BLANK         : LayoutName := 'Vide';
  LAY_CONTENT_CAPT  : LayoutName := 'Contenu avec legende';
  LAY_SECTION       : LayoutName := 'En-tete de section';
 Else LayoutName := 'Personnalise';
 End;
End;

Function TransName(T: Byte): String;
Begin
 Case T Of
  TRANS_NONE     : TransName := 'Aucune';
  TRANS_FADE     : TransName := 'Fondu';
  TRANS_WIPE_L   : TransName := 'Balayage gauche';
  TRANS_WIPE_R   : TransName := 'Balayage droite';
  TRANS_WIPE_U   : TransName := 'Balayage haut';
  TRANS_WIPE_D   : TransName := 'Balayage bas';
  TRANS_SPLIT    : TransName := 'Decoupage';
  TRANS_CHECKER  : TransName := 'Damier';
  TRANS_PUSH     : TransName := 'Pousser';
  TRANS_BLINDS   : TransName := 'Stores';
  TRANS_DISSOLVE : TransName := 'Dissolution';
 Else TransName := '?';
 End;
End;

Function ShapeKindName(T: Byte): String;
Begin
 Case T Of
  SHP_TITLE     : ShapeKindName := 'Titre';
  SHP_CONTENT   : ShapeKindName := 'Contenu';
  SHP_SUBTITLE  : ShapeKindName := 'Sous-titre';
  SHP_TEXT      : ShapeKindName := 'Texte';
  SHP_RECT      : ShapeKindName := 'Rectangle';
  SHP_ROUNDRECT : ShapeKindName := 'Rectangle arrondi';
  SHP_ELLIPSE   : ShapeKindName := 'Ellipse';
  SHP_LINE      : ShapeKindName := 'Ligne';
  SHP_ARROW     : ShapeKindName := 'Fleche';
  SHP_TRIANGLE  : ShapeKindName := 'Triangle';
  SHP_DIAMOND   : ShapeKindName := 'Losange';
  SHP_PENTAGON  : ShapeKindName := 'Pentagone';
  SHP_HEXAGON   : ShapeKindName := 'Hexagone';
  SHP_STAR      : ShapeKindName := 'Etoile';
  SHP_HEART     : ShapeKindName := 'Coeur';
  SHP_CALLOUT   : ShapeKindName := 'Bulle';
  SHP_PARALLEL  : ShapeKindName := 'Parallelogramme';
  SHP_TRAPEZOID : ShapeKindName := 'Trapeze';
  SHP_CROSS     : ShapeKindName := 'Croix';
  SHP_IMAGE     : ShapeKindName := 'Image';
  SHP_TABLE     : ShapeKindName := 'Tableau';
  SHP_CHART     : ShapeKindName := 'Graphique';
 Else ShapeKindName := 'Forme';
 End;
End;

{ ====================================================================== }
{                       PRIMITIVES SOURIS                                }
{ ====================================================================== }

Procedure UpdateMouse;
Var Dt: LongInt;
Begin
 LastClickB := Mouse.B;
 GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
 DoubleClicked := False;
 If ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0) Then Begin
  Dt := TickCount - LastClickTime;
  If (Dt > 0) And (Dt < 8) And (Abs(Mouse.X - LastClickX) < 4)
     And (Abs(Mouse.Y - LastClickY) < 4) Then DoubleClicked := True;
  LastClickTime := TickCount;
  LastClickX    := Mouse.X;
  LastClickY    := Mouse.Y;
 End;
End;

Function LeftPressed: Boolean;
Begin LeftPressed := ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0); End;

Function LeftDown: Boolean;
Begin LeftDown := (Mouse.B And 1) <> 0; End;

Function LeftReleased: Boolean;
Begin LeftReleased := ((Mouse.B And 1) = 0) And ((LastClickB And 1) <> 0); End;

Function RightPressed: Boolean;
Begin RightPressed := ((Mouse.B And 2) <> 0) And ((LastClickB And 2) = 0); End;

Function InRect(X, Y, X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 InRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2);
End;

{ ====================================================================== }
{                       PRIMITIVES DE DESSIN                             }
{ ====================================================================== }

Procedure FillBox(X1, Y1, X2, Y2, Col: Integer);
Begin
 SetFillStyle(1, Col);
 Bar(X1, Y1, X2, Y2);
End;

Procedure HLine(X1, X2, Y, Col: Integer);
Begin
 SetColor(Col); Line(X1, Y, X2, Y);
End;

Procedure VLine(X, Y1, Y2, Col: Integer);
Begin
 SetColor(Col); Line(X, Y1, X, Y2);
End;

Procedure DrawRaised(X1, Y1, X2, Y2, Bg, Hi, Lo: Integer);
Begin
 FillBox(X1, Y1, X2, Y2, Bg);
 HLine(X1, X2, Y1, Hi);
 VLine(X1, Y1, Y2, Hi);
 HLine(X1, X2, Y2, Lo);
 VLine(X2, Y1, Y2, Lo);
End;

Procedure DrawSunken(X1, Y1, X2, Y2, Bg, Hi, Lo: Integer);
Begin
 FillBox(X1, Y1, X2, Y2, Bg);
 HLine(X1, X2, Y1, Lo);
 VLine(X1, Y1, Y2, Lo);
 HLine(X1, X2, Y2, Hi);
 VLine(X2, Y1, Y2, Hi);
End;

Procedure DropShadow(X1, Y1, X2, Y2: Integer);
Begin
 FillBox(X1 + 4, Y2 + 1, X2 + 4, Y2 + 3, CLR_BLACK);
 FillBox(X2 + 1, Y1 + 4, X2 + 3, Y2 + 3, CLR_BLACK);
End;

Procedure DrawCheckBox(X, Y: Integer; Checked: Boolean);
Begin
 DrawSunken(X, Y, X + 11, Y + 11, CLR_WHITE, CLR_WIN_HI, CLR_WIN_LO);
 If Checked Then Begin
  SetColor(CLR_BLACK);
  Line(X + 2, Y + 5, X + 4, Y + 8);
  Line(X + 3, Y + 5, X + 5, Y + 8);
  Line(X + 4, Y + 8, X + 9, Y + 2);
  Line(X + 5, Y + 8, X + 9, Y + 3);
 End;
End;

{ ====================================================================== }
{                       PRIMITIVES DIALOGUES                             }
{ ====================================================================== }

Procedure DlgFrame(X1, Y1, X2, Y2: Integer; Const Title: String);
Begin
 HideMouse;
 DropShadow(X1, Y1, X2, Y2);
 DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 6, Y1 + 4, Title);
 DrawRaised(X2 - 16, Y1 + 3, X2 - 4, Y1 + 13, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 Line(X2 - 13, Y1 + 6, X2 - 7, Y1 + 10);
 Line(X2 - 13, Y1 + 10, X2 - 7, Y1 + 6);
 ShowMouse;
End;

Procedure DlgBtn(X1, Y1, X2, Y2: Integer; Const Caption: String;
                 Pressed, Focused: Boolean);
Var Tw: Integer;
Begin
 If Pressed Then
  DrawSunken(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO)
 Else
  DrawRaised(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 If Focused Then Begin
  SetColor(CLR_BLACK);
  Rectangle(X1 + 3, Y1 + 3, X2 - 3, Y2 - 3);
 End;
 SetColor(CLR_BLACK);
 Tw := TextWidth(Caption);
 OutTextXY(X1 + ((X2 - X1) - Tw) Div 2 + Ord(Pressed),
           Y1 + ((Y2 - Y1) - 8) Div 2 + Ord(Pressed), Caption);
End;

Procedure DlgEdit(X1, Y1, X2, Y2: Integer; Const Text: String;
                  Focused: Boolean; Caret: Integer);
Var S: String; Cx: Integer;
Begin
 FillBox(X1, Y1, X2, Y2, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(X1, Y1, X2, Y2);
 S := Text;
 While (Length(S) > 0) And (TextWidth(S) > X2 - X1 - 6) Do
  S := Copy(S, 2, Length(S) - 1);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 4, Y1 + ((Y2 - Y1) - 8) Div 2, S);
 If Focused And BlinkState Then Begin
  If Caret > Length(S) Then Caret := Length(S);
  Cx := X1 + 4 + TextWidth(Copy(S, 1, Caret));
  Line(Cx, Y1 + 3, Cx, Y2 - 3);
 End;
End;

Procedure DlgLabel(X, Y: Integer; Const S: String);
Begin SetColor(CLR_BLACK); OutTextXY(X, Y, S); End;

Procedure MessageBox(Const Title, Msg: String);
Var X1, Y1, X2, Y2, Bx1, By1, Bx2, By2: Integer; K, K2: Char;
Begin
 X1 := 170; Y1 := 180; X2 := 470; Y2 := 290;
 Bx1 := (X1 + X2) Div 2 - 35; By1 := Y2 - 32;
 Bx2 := Bx1 + 70;             By2 := Y2 - 12;
 DlgFrame(X1, Y1, X2, Y2, Title);
 HideMouse;
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 20, Y1 + 36, Msg);
 DlgBtn(Bx1, By1, Bx2, By2, 'OK', False, True);
 ShowMouse;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then K2 := ReadKey;
   If (K = #13) Or (K = #27) Or (K = ' ') Then Begin
    NeedFullRedraw := True; Exit;
   End;
  End;
  If LeftPressed Then
   If InRect(Mouse.X, Mouse.Y, Bx1, By1, Bx2, By2) Then Begin
    NeedFullRedraw := True; Exit;
   End;
 Until False;
End;

Function ConfirmYesNo(Const Title, Msg: String): Boolean;
Var X1, Y1, X2, Y2, Yx1, Yx2, Nx1, Nx2, By1, By2: Integer;
    K, K2: Char; Sel: Integer;
Begin
 ConfirmYesNo := False;
 X1 := 160; Y1 := 180; X2 := 480; Y2 := 290;
 By1 := Y2 - 32; By2 := Y2 - 12;
 Yx1 := X1 + 80;  Yx2 := Yx1 + 70;
 Nx1 := X2 - 150; Nx2 := Nx1 + 70;
 Sel := 1;
 DlgFrame(X1, Y1, X2, Y2, Title);
 HideMouse;
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 20, Y1 + 40, Msg);
 DlgBtn(Yx1, By1, Yx2, By2, 'Oui', False, Sel = 1);
 DlgBtn(Nx1, By1, Nx2, By2, 'Non', False, Sel = 2);
 ShowMouse;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    If K2 = #75 Then Sel := 1;
    If K2 = #77 Then Sel := 2;
    HideMouse;
    DlgBtn(Yx1, By1, Yx2, By2, 'Oui', False, Sel = 1);
    DlgBtn(Nx1, By1, Nx2, By2, 'Non', False, Sel = 2);
    ShowMouse;
    Continue;
   End;
   If K = #9 Then Begin
    If Sel = 1 Then Sel := 2 Else Sel := 1;
    HideMouse;
    DlgBtn(Yx1, By1, Yx2, By2, 'Oui', False, Sel = 1);
    DlgBtn(Nx1, By1, Nx2, By2, 'Non', False, Sel = 2);
    ShowMouse;
    Continue;
   End;
   If K = #13 Then Begin
    ConfirmYesNo := Sel = 1;
    NeedFullRedraw := True; Exit;
   End;
   If K = #27 Then Begin NeedFullRedraw := True; Exit; End;
   If UpCase(K) = 'O' Then Begin ConfirmYesNo := True;  NeedFullRedraw := True; Exit; End;
   If UpCase(K) = 'N' Then Begin ConfirmYesNo := False; NeedFullRedraw := True; Exit; End;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, Yx1, By1, Yx2, By2) Then Begin
    ConfirmYesNo := True;  NeedFullRedraw := True; Exit;
   End;
   If InRect(Mouse.X, Mouse.Y, Nx1, By1, Nx2, By2) Then Begin
    ConfirmYesNo := False; NeedFullRedraw := True; Exit;
   End;
  End;
 Until False;
End;

{ ====================================================================== }
{                       MENUS                                            }
{ ====================================================================== }

Procedure AddMenu(Const Caption: String);
Begin
 If MenuCount >= 16 Then Exit;
 Inc(MenuCount);
 Menus[MenuCount].Caption := Caption;
 Menus[MenuCount].Count   := 0;
End;

Procedure AddMenuItem(M: Integer; Const Caption, Shortcut: String;
                      IsSep: Boolean; Action: Integer);
Var C: Integer;
Begin
 If (M < 1) Or (M > MenuCount) Then Exit;
 If Menus[M].Count >= 28 Then Exit;
 Inc(Menus[M].Count);
 C := Menus[M].Count;
 Menus[M].Items[C].Caption  := Caption;
 Menus[M].Items[C].Shortcut := Shortcut;
 Menus[M].Items[C].IsSep    := IsSep;
 Menus[M].Items[C].Action   := Action;
 Menus[M].Items[C].Enabled  := True;
End;

Procedure InitMenus;
Var I, X: Integer;
Begin
 MenuCount := 0;
 AddMenu(' Fichier ');
 AddMenu(' Edition ');
 AddMenu(' Affichage ');
 AddMenu(' Insertion ');
 AddMenu(' Conception ');
 AddMenu(' Transitions ');
 AddMenu(' Animations ');
 AddMenu(' Diaporama ');
 AddMenu(' Revision ');
 AddMenu(' Aide ');

 AddMenuItem(1, 'Nouveau',                   'Ctrl+N',    False, ACT_NEW);
 AddMenuItem(1, 'Ouvrir...',                 'Ctrl+O',    False, ACT_OPEN);
 AddMenuItem(1, 'Fermer',                    'Ctrl+F4',   False, ACT_CLOSE);
 AddMenuItem(1, '',                          '',          True,  0);
 AddMenuItem(1, 'Enregistrer',               'Ctrl+S',    False, ACT_SAVE);
 AddMenuItem(1, 'Enregistrer sous...',       'F12',       False, ACT_SAVEAS);
 AddMenuItem(1, '',                          '',          True,  0);
 AddMenuItem(1, 'Imprimer...',               'Ctrl+P',    False, ACT_PRINT);
 AddMenuItem(1, '',                          '',          True,  0);
 AddMenuItem(1, 'Quitter',                   'Alt+F4',    False, ACT_QUIT);

 AddMenuItem(2, 'Annuler',                   'Ctrl+Z',    False, ACT_UNDO);
 AddMenuItem(2, 'Retablir',                  'Ctrl+Y',    False, ACT_REDO);
 AddMenuItem(2, '',                          '',          True,  0);
 AddMenuItem(2, 'Couper',                    'Ctrl+X',    False, ACT_CUT);
 AddMenuItem(2, 'Copier',                    'Ctrl+C',    False, ACT_COPY);
 AddMenuItem(2, 'Coller',                    'Ctrl+V',    False, ACT_PASTE);
 AddMenuItem(2, 'Dupliquer',                 'Ctrl+D',    False, ACT_DUP);
 AddMenuItem(2, 'Supprimer',                 'Suppr',     False, ACT_DELETE);
 AddMenuItem(2, '',                          '',          True,  0);
 AddMenuItem(2, 'Rechercher...',             'Ctrl+F',    False, ACT_FIND);
 AddMenuItem(2, 'Remplacer...',              'Ctrl+H',    False, ACT_REPLACE);
 AddMenuItem(2, 'Selectionner tout',         'Ctrl+A',    False, ACT_SELECTALL);

 AddMenuItem(3, 'Normal',                    '',          False, ACT_VIEW_NORMAL);
 AddMenuItem(3, 'Plan',                      '',          False, ACT_VIEW_OUTLINE);
 AddMenuItem(3, 'Trieuse de diapositives',   '',          False, ACT_VIEW_SORTER);
 AddMenuItem(3, 'Page de commentaires',      '',          False, ACT_VIEW_NOTES);
 AddMenuItem(3, '',                          '',          True,  0);
 AddMenuItem(3, 'Masque des diapositives',   '',          False, ACT_VIEW_MASTER);
 AddMenuItem(3, '',                          '',          True,  0);
 AddMenuItem(3, 'Zoom +',                    'Ctrl++',    False, ACT_ZOOM_IN);
 AddMenuItem(3, 'Zoom -',                    'Ctrl+-',    False, ACT_ZOOM_OUT);
 AddMenuItem(3, 'Ajuster a la fenetre',      '',          False, ACT_ZOOM_FIT);

 AddMenuItem(4, 'Nouvelle diapositive',      'Ctrl+M',    False, ACT_NEW_SLIDE);
 AddMenuItem(4, 'Dupliquer la diapositive',  '',          False, ACT_DUP_SLIDE);
 AddMenuItem(4, '',                          '',          True,  0);
 AddMenuItem(4, 'Zone de texte',             '',          False, ACT_INS_TEXT);
 AddMenuItem(4, 'Image...',                  '',          False, ACT_INS_IMAGE);
 AddMenuItem(4, 'Tableau...',                '',          False, ACT_INS_TABLE);
 AddMenuItem(4, 'Graphique...',              '',          False, ACT_INS_CHART);
 AddMenuItem(4, '',                          '',          True,  0);
 AddMenuItem(4, 'Forme - Rectangle',         '',          False, ACT_INS_RECT);
 AddMenuItem(4, 'Forme - Ellipse',           '',          False, ACT_INS_ELLIPSE);
 AddMenuItem(4, 'Forme - Triangle',          '',          False, ACT_INS_TRIANGLE);
 AddMenuItem(4, 'Forme - Etoile',            '',          False, ACT_INS_STAR);
 AddMenuItem(4, 'Forme - Bulle',             '',          False, ACT_INS_CALLOUT);
 AddMenuItem(4, 'Ligne',                     '',          False, ACT_INS_LINE);
 AddMenuItem(4, 'Fleche',                    '',          False, ACT_INS_ARROW);
 AddMenuItem(4, '',                          '',          True,  0);
 AddMenuItem(4, 'En-tete et pied',           '',          False, ACT_INS_HEADER);
 AddMenuItem(4, 'Date et heure',             '',          False, ACT_INS_DATE);
 AddMenuItem(4, 'Numero de diapositive',     '',          False, ACT_INS_NUMBER);

 AddMenuItem(5, 'Mise en page de slide...',  '',          False, ACT_LAYOUT);
 AddMenuItem(5, 'Theme...',                  '',          False, ACT_THEME);
 AddMenuItem(5, 'Arriere-plan...',           '',          False, ACT_BACKGROUND);
 AddMenuItem(5, '',                          '',          True,  0);
 AddMenuItem(5, 'Couleur de remplissage',    '',          False, ACT_COLOR_FILL);
 AddMenuItem(5, 'Couleur de contour',        '',          False, ACT_COLOR_LINE);
 AddMenuItem(5, 'Couleur du texte',          '',          False, ACT_COLOR_TEXT);

 AddMenuItem(6, 'Aucune',                    '',          False, ACT_TRANS);
 AddMenuItem(6, 'Fondu',                     '',          False, ACT_TRANS);
 AddMenuItem(6, 'Balayage',                  '',          False, ACT_TRANS);
 AddMenuItem(6, 'Decoupage',                 '',          False, ACT_TRANS);
 AddMenuItem(6, 'Pousser',                   '',          False, ACT_TRANS);
 AddMenuItem(6, 'Damier',                    '',          False, ACT_TRANS);
 AddMenuItem(6, 'Dissolution',               '',          False, ACT_TRANS);
 AddMenuItem(6, '',                          '',          True,  0);
 AddMenuItem(6, 'Minutage...',               '',          False, ACT_TIMING);

 AddMenuItem(7, 'Animation d''entree...',    '',          False, ACT_ANIM_ENTRY);
 AddMenuItem(7, 'Animation de sortie...',    '',          False, ACT_ANIM_EXIT);
 AddMenuItem(7, '',                          '',          True,  0);
 AddMenuItem(7, 'Volet d''animation',        '',          False, 0);

 AddMenuItem(8, 'Demarrer le diaporama',     'F5',        False, ACT_SLIDESHOW);
 AddMenuItem(8, 'A partir de cette slide',   'Maj+F5',    False, ACT_SLIDESHOW_FROM);
 AddMenuItem(8, 'Verifier le minutage',      '',          False, ACT_REHEARSE);
 AddMenuItem(8, '',                          '',          True,  0);
 AddMenuItem(8, 'Configurer le diaporama',   '',          False, 0);

 AddMenuItem(9, 'Orthographe...',            'F7',        False, 0);
 AddMenuItem(9, 'Recherche...',              '',          False, 0);
 AddMenuItem(9, 'Commentaires...',           '',          False, 0);

 AddMenuItem(10,'Rubriques d''aide',         'F1',        False, ACT_HELP_TOPIC);
 AddMenuItem(10,'',                          '',          True,  0);
 AddMenuItem(10,'A propos de PowerPnt...',   '',          False, ACT_HELP_ABOUT);

 X := 4;
 For I := 1 To MenuCount Do Begin
  Menus[I].X1 := X;
  Menus[I].X2 := X + TextWidth(Menus[I].Caption) + 6;
  X := Menus[I].X2 + 2;
 End;
 MenuY1 := 0;
 MenuY2 := MENU_H - 1;
End;

Procedure DrawMenuBar;
Var I, Bg, Fg: Integer;
Begin
 HideMouse;
 FillBox(0, MenuY1, SCREEN_W - 1, MenuY2, CLR_MENU_BG);
 HLine(0, SCREEN_W - 1, MenuY2, CLR_WIN_LO);
 For I := 1 To MenuCount Do Begin
  If (I = MenuOpen) Or ((I = MenuHover) And (MenuOpen = 0)) Then Begin
   Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG;
   FillBox(Menus[I].X1, MenuY1 + 1, Menus[I].X2, MenuY2 - 1, Bg);
  End
  Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
  SetColor(Fg);
  OutTextXY(Menus[I].X1 + 4, MenuY1 + 4, Menus[I].Caption);
 End;
 ShowMouse;
End;

Function MenuAtX(X: LongInt): Integer;
Var I: Integer;
Begin
 MenuAtX := 0;
 For I := 1 To MenuCount Do
  If (X >= Menus[I].X1) And (X <= Menus[I].X2) Then Begin
   MenuAtX := I; Exit;
  End;
End;

Var
 DropX, DropY, DropW, DropH: Integer;

Function DropItemH(M, I: Integer): Integer;
Begin
 If Menus[M].Items[I].IsSep Then DropItemH := 6 Else DropItemH := 14;
End;

Procedure ComputeDropLayout(M: Integer);
Var I, H, W, Tw: Integer; S: String;
Begin
 W := 130;
 For I := 1 To Menus[M].Count Do Begin
  S := Menus[M].Items[I].Caption + '   ' + Menus[M].Items[I].Shortcut;
  Tw := TextWidth(S) + 32;
  If Tw > W Then W := Tw;
 End;
 H := 4;
 For I := 1 To Menus[M].Count Do H := H + DropItemH(M, I);
 H := H + 2;
 DropX := Menus[M].X1;
 DropY := MENU_H;
 DropW := W;
 DropH := H;
 If DropX + DropW > SCREEN_W - 2 Then DropX := SCREEN_W - DropW - 2;
End;

Procedure DrawDropDown;
Var M, I, Y, Ih, Bg, Fg: Integer; S: String;
Begin
 If MenuOpen = 0 Then Exit;
 M := MenuOpen;
 ComputeDropLayout(M);
 HideMouse;
 DropShadow(DropX, DropY, DropX + DropW, DropY + DropH);
 DrawRaised(DropX, DropY, DropX + DropW, DropY + DropH,
            CLR_MENU_BG, CLR_WIN_HI, CLR_WIN_LO);
 Y := DropY + 2;
 For I := 1 To Menus[M].Count Do Begin
  Ih := DropItemH(M, I);
  If Menus[M].Items[I].IsSep Then Begin
   HLine(DropX + 4, DropX + DropW - 4, Y + 2, CLR_WIN_LO);
   HLine(DropX + 4, DropX + DropW - 4, Y + 3, CLR_WIN_HI);
  End
  Else Begin
   If I = MenuItemHover Then Begin Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG; End
   Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
   FillBox(DropX + 2, Y, DropX + DropW - 2, Y + Ih - 1, Bg);
   SetColor(Fg);
   OutTextXY(DropX + 8, Y + 2, Menus[M].Items[I].Caption);
   S := Menus[M].Items[I].Shortcut;
   If S <> '' Then
    OutTextXY(DropX + DropW - TextWidth(S) - 8, Y + 2, S);
  End;
  Y := Y + Ih;
 End;
 ShowMouse;
End;

Function DropItemAtY(M: Integer; Y: LongInt): Integer;
Var I, YY, Ih: Integer;
Begin
 DropItemAtY := 0;
 YY := DropY + 2;
 For I := 1 To Menus[M].Count Do Begin
  Ih := DropItemH(M, I);
  If (Y >= YY) And (Y < YY + Ih) And (Not Menus[M].Items[I].IsSep) Then Begin
   DropItemAtY := I; Exit;
  End;
  YY := YY + Ih;
 End;
End;

{ ====================================================================== }
{                       ICONES VECTORIELLES 18x18                        }
{ ====================================================================== }

Procedure IconNew(X, Y: Integer);
Begin
 FillBox(X + 3, Y + 1, X + 12, Y + 16, CLR_WHITE);
 SetColor(CLR_BLACK);
 Rectangle(X + 3, Y + 1, X + 12, Y + 16);
 Line(X + 9, Y + 1, X + 12, Y + 4);
 HLine(X + 5, X + 10, Y + 7, CLR_DGRAY);
 HLine(X + 5, X + 10, Y + 9, CLR_DGRAY);
 HLine(X + 5, X + 10, Y + 11, CLR_DGRAY);
End;

Procedure IconOpen(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 FillBox(X + 1, Y + 5, X + 15, Y + 14, CLR_YELLOW);
 Rectangle(X + 1, Y + 5, X + 15, Y + 14);
 Line(X + 1, Y + 5, X + 4, Y + 3);
 Line(X + 4, Y + 3, X + 8, Y + 3);
 Line(X + 8, Y + 3, X + 9, Y + 5);
 HLine(X + 2, X + 14, Y + 7, CLR_BROWN);
End;

Procedure IconSave(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 2, X + 15, Y + 15, CLR_BLUE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 15, Y + 15);
 FillBox(X + 5, Y + 2, X + 12, Y + 6, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 5, Y + 2, X + 12, Y + 6);
 FillBox(X + 9, Y + 3, X + 11, Y + 5, CLR_BLACK);
 FillBox(X + 4, Y + 9, X + 13, Y + 14, CLR_WHITE);
End;

Procedure IconPrint(X, Y: Integer);
Begin
 FillBox(X + 4, Y + 2, X + 13, Y + 6, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 4, Y + 2, X + 13, Y + 6);
 FillBox(X + 1, Y + 6, X + 16, Y + 12, CLR_LGRAY);
 SetColor(CLR_BLACK); Rectangle(X + 1, Y + 6, X + 16, Y + 12);
 FillBox(X + 4, Y + 12, X + 13, Y + 15, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 4, Y + 12, X + 13, Y + 15);
 PutPixel(X + 13, Y + 8, CLR_GREEN);
End;

Procedure IconCut(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 3, Y + 3, X + 13, Y + 13);
 Line(X + 13, Y + 3, X + 3, Y + 13);
 SetColor(CLR_RED);
 Circle(X + 4, Y + 14, 2);
 Circle(X + 12, Y + 14, 2);
End;

Procedure IconCopy(X, Y: Integer);
Begin
 FillBox(X + 5, Y + 3, X + 13, Y + 14, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 5, Y + 3, X + 13, Y + 14);
 FillBox(X + 2, Y + 6, X + 10, Y + 16, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 6, X + 10, Y + 16);
End;

Procedure IconPaste(X, Y: Integer);
Begin
 FillBox(X + 5, Y + 2, X + 12, Y + 4, CLR_BROWN);
 FillBox(X + 3, Y + 4, X + 14, Y + 15, CLR_YELLOW);
 SetColor(CLR_BLACK); Rectangle(X + 3, Y + 4, X + 14, Y + 15);
 FillBox(X + 5, Y + 7, X + 12, Y + 13, CLR_WHITE);
End;

Procedure IconUndo(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Arc(X + 9, Y + 11, 30, 200, 6);
 Line(X + 3, Y + 11, X + 3, Y + 5);
 Line(X + 3, Y + 5, X + 7, Y + 5);
 Line(X + 3, Y + 5, X + 5, Y + 3);
 Line(X + 3, Y + 5, X + 5, Y + 7);
End;

Procedure IconRedo(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Arc(X + 9, Y + 11, 0, 150, 6);
 Line(X + 15, Y + 11, X + 15, Y + 5);
 Line(X + 11, Y + 5, X + 15, Y + 5);
 Line(X + 15, Y + 5, X + 13, Y + 3);
 Line(X + 15, Y + 5, X + 13, Y + 7);
End;

Procedure IconNewSlide(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 2, X + 14, Y + 12, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 14, Y + 12);
 HLine(X + 4, X + 12, Y + 5, CLR_BLUE);
 HLine(X + 4, X + 12, Y + 8, CLR_DGRAY);
 SetColor(CLR_GREEN);
 Line(X + 14, Y + 14, X + 14, Y + 17);
 Line(X + 12, Y + 16, X + 16, Y + 16);
End;

Procedure IconDelSlide(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 2, X + 14, Y + 12, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 14, Y + 12);
 HLine(X + 4, X + 12, Y + 5, CLR_BLUE);
 SetColor(CLR_RED);
 Line(X + 12, Y + 13, X + 16, Y + 17);
 Line(X + 16, Y + 13, X + 12, Y + 17);
End;

Procedure IconText(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 4, X + 15, Y + 15);
 SetColor(CLR_DGRAY);
 Line(X + 5, Y + 6, X + 12, Y + 6);
 Line(X + 8, Y + 6, X + 8, Y + 13);
 Line(X + 7, Y + 13, X + 9, Y + 13);
End;

Procedure IconRect(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 4, X + 15, Y + 14, CLR_LCYAN);
 SetColor(CLR_BLUE); Rectangle(X + 2, Y + 4, X + 15, Y + 14);
End;

Procedure IconEllipse(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LRED);
 FillEllipse(X + 9, Y + 9, 6, 4);
 SetColor(CLR_RED); Ellipse(X + 9, Y + 9, 0, 360, 6, 4);
End;

Procedure IconLine(X, Y: Integer);
Begin
 SetColor(CLR_BLACK); Line(X + 2, Y + 14, X + 15, Y + 3);
 Line(X + 3, Y + 14, X + 15, Y + 4);
End;

Procedure IconArrow(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 9, X + 14, Y + 9);
 Line(X + 14, Y + 9, X + 11, Y + 6);
 Line(X + 14, Y + 9, X + 11, Y + 12);
End;

Procedure IconTriangle(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LGREEN);
 SetColor(CLR_GREEN);
 Line(X + 8, Y + 3, X + 2, Y + 14);
 Line(X + 8, Y + 3, X + 14, Y + 14);
 Line(X + 2, Y + 14, X + 14, Y + 14);
 FloodFill(X + 8, Y + 12, CLR_GREEN);
End;

Procedure IconStar(X, Y: Integer);
Var Cx, Cy: Integer;
Begin
 Cx := X + 9; Cy := Y + 9;
 SetColor(CLR_YELLOW);
 Line(Cx, Cy - 6, Cx - 5, Cy + 5);
 Line(Cx - 5, Cy + 5, Cx + 6, Cy - 2);
 Line(Cx + 6, Cy - 2, Cx - 6, Cy - 2);
 Line(Cx - 6, Cy - 2, Cx + 5, Cy + 5);
 Line(Cx + 5, Cy + 5, Cx, Cy - 6);
End;

Procedure IconImage(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 3, X + 15, Y + 14, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 3, X + 15, Y + 14);
 SetFillStyle(1, CLR_YELLOW); FillEllipse(X + 6, Y + 7, 2, 2);
 SetColor(CLR_GREEN);
 Line(X + 3, Y + 13, X + 8, Y + 8);
 Line(X + 8, Y + 8, X + 12, Y + 11);
 Line(X + 12, Y + 11, X + 14, Y + 9);
End;

Procedure IconTable(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 3, X + 15, Y + 15, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 3, X + 15, Y + 15);
 FillBox(X + 2, Y + 3, X + 15, Y + 6, CLR_LBLUE);
 HLine(X + 2, X + 15, Y + 9, CLR_DGRAY);
 HLine(X + 2, X + 15, Y + 12, CLR_DGRAY);
 VLine(X + 8, Y + 3, Y + 15, CLR_DGRAY);
End;

Procedure IconBold(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 OutTextXY(X + 6, Y + 4, 'B');
 OutTextXY(X + 7, Y + 4, 'B');
End;

Procedure IconItal(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 OutTextXY(X + 7, Y + 4, 'I');
 Line(X + 6, Y + 14, X + 9, Y + 14);
 Line(X + 5, Y + 4, X + 8, Y + 4);
End;

Procedure IconUnd(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 OutTextXY(X + 6, Y + 3, 'U');
 Line(X + 4, Y + 14, X + 14, Y + 14);
End;

Procedure IconAlignL(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 14, Y + 4);
 Line(X + 2, Y + 7, X + 10, Y + 7);
 Line(X + 2, Y + 10, X + 14, Y + 10);
 Line(X + 2, Y + 13, X + 9, Y + 13);
End;

Procedure IconAlignC(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 14, Y + 4);
 Line(X + 4, Y + 7, X + 12, Y + 7);
 Line(X + 2, Y + 10, X + 14, Y + 10);
 Line(X + 5, Y + 13, X + 11, Y + 13);
End;

Procedure IconAlignR(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 14, Y + 4);
 Line(X + 6, Y + 7, X + 14, Y + 7);
 Line(X + 2, Y + 10, X + 14, Y + 10);
 Line(X + 7, Y + 13, X + 14, Y + 13);
End;

Procedure IconBullet(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 PutPixel(X + 3, Y + 5, CLR_BLACK); PutPixel(X + 4, Y + 5, CLR_BLACK);
 PutPixel(X + 3, Y + 6, CLR_BLACK); PutPixel(X + 4, Y + 6, CLR_BLACK);
 Line(X + 6, Y + 5, X + 14, Y + 5);
 PutPixel(X + 3, Y + 9, CLR_BLACK); PutPixel(X + 4, Y + 9, CLR_BLACK);
 PutPixel(X + 3, Y + 10, CLR_BLACK); PutPixel(X + 4, Y + 10, CLR_BLACK);
 Line(X + 6, Y + 9, X + 14, Y + 9);
 PutPixel(X + 3, Y + 13, CLR_BLACK); PutPixel(X + 4, Y + 13, CLR_BLACK);
 PutPixel(X + 3, Y + 14, CLR_BLACK); PutPixel(X + 4, Y + 14, CLR_BLACK);
 Line(X + 6, Y + 13, X + 14, Y + 13);
End;

Procedure IconFill(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LRED);
 Bar(X + 3, Y + 4, X + 14, Y + 12);
 SetColor(CLR_BLACK); Rectangle(X + 3, Y + 4, X + 14, Y + 12);
 SetColor(CLR_RED);
 Line(X + 5, Y + 13, X + 12, Y + 13);
 Line(X + 6, Y + 14, X + 11, Y + 14);
End;

Procedure IconPen(X, Y: Integer);
Begin
 SetColor(CLR_BROWN);
 Line(X + 3, Y + 14, X + 14, Y + 3);
 Line(X + 4, Y + 14, X + 14, Y + 4);
 SetColor(CLR_BLACK);
 Line(X + 12, Y + 2, X + 15, Y + 5);
End;

Procedure IconSlideshow(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LGREEN);
 Bar(X + 4, Y + 3, X + 5, Y + 14);
 SetColor(CLR_GREEN);
 Line(X + 4, Y + 3, X + 15, Y + 9);
 Line(X + 4, Y + 14, X + 15, Y + 9);
 Line(X + 5, Y + 4, X + 14, Y + 9);
 Line(X + 5, Y + 13, X + 14, Y + 9);
End;

Procedure IconHelp(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_BLUE);
 FillEllipse(X + 8, Y + 9, 6, 6);
 SetColor(CLR_WHITE);
 OutTextXY(X + 5, Y + 5, '?');
End;

Procedure IconSelect(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 4, Y + 3, X + 4, Y + 14);
 Line(X + 4, Y + 3, X + 12, Y + 11);
 Line(X + 4, Y + 14, X + 8, Y + 11);
 Line(X + 12, Y + 11, X + 8, Y + 11);
 Line(X + 8, Y + 11, X + 11, Y + 16);
End;

Procedure IconFont(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 OutTextXY(X + 4, Y + 3, 'A');
 SetColor(CLR_RED);
 Line(X + 3, Y + 13, X + 14, Y + 13);
 Line(X + 3, Y + 14, X + 14, Y + 14);
End;

Procedure IconTrans(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LCYAN);
 Bar(X + 2, Y + 4, X + 7, Y + 13);
 SetColor(CLR_CYAN); Rectangle(X + 2, Y + 4, X + 7, Y + 13);
 SetFillStyle(1, CLR_LMAGENTA);
 Bar(X + 10, Y + 4, X + 15, Y + 13);
 SetColor(CLR_MAGENTA); Rectangle(X + 10, Y + 4, X + 15, Y + 13);
 SetColor(CLR_BLACK);
 Line(X + 7, Y + 9, X + 10, Y + 9);
 Line(X + 10, Y + 9, X + 8, Y + 7);
 Line(X + 10, Y + 9, X + 8, Y + 11);
End;

Procedure IconAnim(X, Y: Integer);
Begin
 SetColor(CLR_YELLOW);
 SetFillStyle(1, CLR_YELLOW);
 FillEllipse(X + 6, Y + 9, 3, 3);
 SetColor(CLR_BLACK);
 Line(X + 9, Y + 9, X + 15, Y + 5);
 Line(X + 9, Y + 9, X + 15, Y + 9);
 Line(X + 9, Y + 9, X + 15, Y + 13);
End;

Procedure DrawIcon(IconId, X, Y: Integer);
Begin
 Case IconId Of
  ICO_NEW:       IconNew(X, Y);
  ICO_OPEN:      IconOpen(X, Y);
  ICO_SAVE:      IconSave(X, Y);
  ICO_PRINT:     IconPrint(X, Y);
  ICO_CUT:       IconCut(X, Y);
  ICO_COPY:      IconCopy(X, Y);
  ICO_PASTE:     IconPaste(X, Y);
  ICO_UNDO:      IconUndo(X, Y);
  ICO_REDO:      IconRedo(X, Y);
  ICO_NEWSLIDE:  IconNewSlide(X, Y);
  ICO_DELSLIDE:  IconDelSlide(X, Y);
  ICO_TEXT:      IconText(X, Y);
  ICO_RECT:      IconRect(X, Y);
  ICO_ELLIPSE:   IconEllipse(X, Y);
  ICO_LINE:      IconLine(X, Y);
  ICO_ARROW:     IconArrow(X, Y);
  ICO_TRIANGLE:  IconTriangle(X, Y);
  ICO_STAR:      IconStar(X, Y);
  ICO_IMAGE:     IconImage(X, Y);
  ICO_TABLE:     IconTable(X, Y);
  ICO_BOLD:      IconBold(X, Y);
  ICO_ITAL:      IconItal(X, Y);
  ICO_UND:       IconUnd(X, Y);
  ICO_ALIGN_L:   IconAlignL(X, Y);
  ICO_ALIGN_C:   IconAlignC(X, Y);
  ICO_ALIGN_R:   IconAlignR(X, Y);
  ICO_BULLET:    IconBullet(X, Y);
  ICO_FILL:      IconFill(X, Y);
  ICO_PEN:       IconPen(X, Y);
  ICO_SLIDESHOW: IconSlideshow(X, Y);
  ICO_HELP:      IconHelp(X, Y);
  ICO_SELECT:    IconSelect(X, Y);
  ICO_FONT:      IconFont(X, Y);
  ICO_TRANS:     IconTrans(X, Y);
  ICO_ANIM:      IconAnim(X, Y);
 End;
End;

{ ====================================================================== }
{                       BARRE D'OUTILS                                   }
{ ====================================================================== }

Procedure AddTool(IconId: Integer; Const Hint: String; Action: Integer;
                  Toggle: Boolean);
Begin
 If ToolCount >= 40 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].Icon    := IconId;
 Tools[ToolCount].Hint    := Hint;
 Tools[ToolCount].Action  := Action;
 Tools[ToolCount].IsSep   := False;
 Tools[ToolCount].Enabled := True;
 Tools[ToolCount].Toggle  := Toggle;
 Tools[ToolCount].Down    := False;
End;

Procedure AddToolSep;
Begin
 If ToolCount >= 40 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].IsSep := True;
End;

Procedure InitTools;
Var I, X: Integer;
Begin
 ToolCount := 0;
 AddTool(ICO_NEW,       'Nouveau',                 ACT_NEW,         False);
 AddTool(ICO_OPEN,      'Ouvrir',                  ACT_OPEN,        False);
 AddTool(ICO_SAVE,      'Enregistrer',             ACT_SAVE,        False);
 AddTool(ICO_PRINT,     'Imprimer',                ACT_PRINT,       False);
 AddToolSep;
 AddTool(ICO_CUT,       'Couper',                  ACT_CUT,         False);
 AddTool(ICO_COPY,      'Copier',                  ACT_COPY,        False);
 AddTool(ICO_PASTE,     'Coller',                  ACT_PASTE,       False);
 AddTool(ICO_UNDO,      'Annuler',                 ACT_UNDO,        False);
 AddTool(ICO_REDO,      'Retablir',                ACT_REDO,        False);
 AddToolSep;
 AddTool(ICO_NEWSLIDE,  'Nouvelle diapositive',    ACT_NEW_SLIDE,   False);
 AddTool(ICO_DELSLIDE,  'Supprimer la diapositive',ACT_DEL_SLIDE,   False);
 AddToolSep;
 AddTool(ICO_SELECT,    'Selectionner',            ACT_TOOL_SELECT, True);
 AddTool(ICO_TEXT,      'Zone de texte',           ACT_TOOL_TEXT,   True);
 AddTool(ICO_RECT,      'Rectangle',               ACT_TOOL_RECT,   True);
 AddTool(ICO_ELLIPSE,   'Ellipse',                 ACT_TOOL_ELL,    True);
 AddTool(ICO_LINE,      'Ligne',                   ACT_TOOL_LINE,   True);
 AddTool(ICO_ARROW,     'Fleche',                  ACT_TOOL_ARROW,  True);
 AddTool(ICO_TRIANGLE,  'Triangle',                ACT_INS_TRIANGLE,False);
 AddTool(ICO_STAR,      'Etoile',                  ACT_INS_STAR,    False);
 AddToolSep;
 AddTool(ICO_IMAGE,     'Image',                   ACT_INS_IMAGE,   False);
 AddTool(ICO_TABLE,     'Tableau',                 ACT_INS_TABLE,   False);
 AddToolSep;
 AddTool(ICO_BOLD,      'Gras',                    ACT_FONT_BOLD,   True);
 AddTool(ICO_ITAL,      'Italique',                ACT_FONT_ITAL,   True);
 AddTool(ICO_UND,       'Souligne',                ACT_FONT_UND,    True);
 AddTool(ICO_ALIGN_L,   'Aligner a gauche',        ACT_ALIGN_LEFT,  True);
 AddTool(ICO_ALIGN_C,   'Centrer',                 ACT_ALIGN_CENTER,True);
 AddTool(ICO_ALIGN_R,   'Aligner a droite',        ACT_ALIGN_RIGHT, True);
 AddTool(ICO_BULLET,    'Puces',                   ACT_BULLET,      True);
 AddToolSep;
 AddTool(ICO_FILL,      'Remplissage',             ACT_COLOR_FILL,  False);
 AddTool(ICO_PEN,       'Contour',                 ACT_COLOR_LINE,  False);
 AddTool(ICO_FONT,      'Couleur du texte',        ACT_COLOR_TEXT,  False);
 AddToolSep;
 AddTool(ICO_TRANS,     'Transitions',             ACT_TRANS,       False);
 AddTool(ICO_ANIM,      'Animations',              ACT_ANIM_ENTRY,  False);
 AddTool(ICO_SLIDESHOW, 'Diaporama (F5)',          ACT_SLIDESHOW,   False);
 AddTool(ICO_HELP,      'Aide',                    ACT_HELP_TOPIC,  False);

 ToolY1 := MENU_H;
 ToolY2 := MENU_H + TOOL_H - 1;
 X := 2;
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   Tools[I].X1 := X; Tools[I].X2 := X + 3;
   Tools[I].Y1 := ToolY1 + 2; Tools[I].Y2 := ToolY2 - 2;
   X := X + 6;
  End
  Else Begin
   Tools[I].X1 := X; Tools[I].X2 := X + 19;
   Tools[I].Y1 := ToolY1 + 1; Tools[I].Y2 := ToolY2 - 1;
   X := X + 20;
  End;
 End;
End;

Procedure DrawToolBar;
Var I: Integer;
Begin
 HideMouse;
 FillBox(0, ToolY1, SCREEN_W - 1, ToolY2, CLR_WIN_BG);
 HLine(0, SCREEN_W - 1, ToolY2, CLR_WIN_LO);
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   VLine(Tools[I].X1 + 1, Tools[I].Y1, Tools[I].Y2, CLR_WIN_LO);
   VLine(Tools[I].X1 + 2, Tools[I].Y1, Tools[I].Y2, CLR_WIN_HI);
  End
  Else Begin
   If Tools[I].Down Then
    DrawSunken(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2,
               CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO)
   Else If I = ToolHover Then
    DrawRaised(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2,
               CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
   DrawIcon(Tools[I].Icon, Tools[I].X1, Tools[I].Y1 + 1);
  End;
 End;
 ShowMouse;
End;

Function ToolAt(X, Y: LongInt): Integer;
Var I: Integer;
Begin
 ToolAt := 0;
 For I := 1 To ToolCount Do
  If (Not Tools[I].IsSep) And
     InRect(X, Y, Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2) Then Begin
   ToolAt := I; Exit;
  End;
End;

Procedure UpdateToolToggles;
Var I: Integer;
Begin
 For I := 1 To ToolCount Do
  If (Not Tools[I].IsSep) And Tools[I].Toggle Then
   Case Tools[I].Action Of
    ACT_TOOL_SELECT: Tools[I].Down := CurTool = TOOL_SELECT;
    ACT_TOOL_TEXT:   Tools[I].Down := CurTool = TOOL_TEXT;
    ACT_TOOL_RECT:   Tools[I].Down := CurTool = TOOL_RECT;
    ACT_TOOL_ELL:    Tools[I].Down := CurTool = TOOL_ELLIPSE;
    ACT_TOOL_LINE:   Tools[I].Down := CurTool = TOOL_LINE;
    ACT_TOOL_ARROW:  Tools[I].Down := CurTool = TOOL_ARROW;
   End;
End;

{ ====================================================================== }
{                       MODELE PRESENTATION / SLIDES / SHAPES            }
{ ====================================================================== }

Function NewShape: PShape;
Var P: PShape; I: Integer;
Begin
 New(P);
 P^.Name      := '';
 P^.ShType    := SHP_RECT;
 P^.X := 100; P^.Y := 100; P^.W := 200; P^.H := 120;
 P^.FillColor := CLR_LCYAN;
 P^.LineColor := CLR_BLUE;
 P^.LineWidth := 1;
 P^.Filled    := True;
 P^.Rotation  := 0;
 P^.ZOrder    := 0;
 P^.Locked    := False;
 P^.Hidden    := False;
 P^.TxtCount  := 0;
 For I := 1 To MAX_TEXT_LINES Do Begin
  P^.Text[I] := '';
  P^.Bullets[I] := False;
  P^.Indent[I] := 0;
 End;
 P^.Bold := False; P^.Italic := False; P^.Underline := False;
 P^.FontSize := 14;
 P^.TextColor := CLR_BLACK;
 P^.Align := ALIGN_LEFT;
 P^.ImageIdx := 0;
 P^.AnimEntry := ANIM_NONE;
 P^.AnimExit  := ANIM_NONE;
 P^.AnimOrder := 0;
 NewShape := P;
End;

Procedure FreeShape(Var P: PShape);
Begin
 If P <> Nil Then Begin Dispose(P); P := Nil; End;
End;

Function NewSlide: PSlide;
Var S: PSlide; I: Integer;
Begin
 New(S);
 S^.Name       := '';
 S^.Title      := '';
 S^.Layout     := LAY_TITLE_CONTENT;
 S^.Background := CLR_WHITE;
 S^.Theme      := 0;
 S^.Transition := TRANS_NONE;
 S^.TransSpeed := 1;
 S^.Notes      := '';
 S^.Hidden     := False;
 S^.ShCount    := 0;
 For I := 1 To MAX_SHAPES Do S^.Shapes[I] := Nil;
 S^.Dirty      := False;
 NewSlide := S;
End;

Procedure FreeSlide(Var S: PSlide);
Var I: Integer;
Begin
 If S = Nil Then Exit;
 For I := 1 To S^.ShCount Do FreeShape(S^.Shapes[I]);
 Dispose(S); S := Nil;
End;

Procedure AddShapeToSlide(S: PSlide; P: PShape);
Begin
 If (S = Nil) Or (P = Nil) Then Exit;
 If S^.ShCount >= MAX_SHAPES Then Exit;
 Inc(S^.ShCount);
 S^.Shapes[S^.ShCount] := P;
 S^.Dirty := True;
End;

Function AddSlideAt(Pos: Integer): Integer;
Var I: Integer; NewS: PSlide;
Begin
 AddSlideAt := 0;
 If Pres.SldCount >= MAX_SLIDES Then Exit;
 NewS := NewSlide;
 If Pos < 1 Then Pos := 1;
 If Pos > Pres.SldCount + 1 Then Pos := Pres.SldCount + 1;
 For I := Pres.SldCount Downto Pos Do
  Pres.Slides[I + 1] := Pres.Slides[I];
 Pres.Slides[Pos] := NewS;
 Inc(Pres.SldCount);
 Pres.Dirty := True;
 AddSlideAt := Pos;
End;

Procedure RemoveSlide(Idx: Integer);
Var I: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 FreeSlide(Pres.Slides[Idx]);
 For I := Idx To Pres.SldCount - 1 Do
  Pres.Slides[I] := Pres.Slides[I + 1];
 Pres.Slides[Pres.SldCount] := Nil;
 Dec(Pres.SldCount);
 Pres.Dirty := True;
 If CurSlide > Pres.SldCount Then CurSlide := Pres.SldCount;
 If CurSlide < 1 Then CurSlide := 0;
End;

Procedure InitDefaultThemes;
Begin
 Pres.ThemeCount := 0;
 With Pres do begin
  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Office';
  Themes[ThemeCount].BgColor     := CLR_WHITE;
  Themes[ThemeCount].TitleColor  := CLR_BLUE;
  Themes[ThemeCount].TextColor   := CLR_BLACK;
  Themes[ThemeCount].AccentColor := CLR_LRED;
  Themes[ThemeCount].FontSize    := 14;

  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Ocean';
  Themes[ThemeCount].BgColor     := CLR_LBLUE;
  Themes[ThemeCount].TitleColor  := CLR_WHITE;
  Themes[ThemeCount].TextColor   := CLR_BLACK;
  Themes[ThemeCount].AccentColor := CLR_YELLOW;
  Themes[ThemeCount].FontSize    := 14;

  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Sombre';
  Themes[ThemeCount].BgColor     := CLR_BLACK;
  Themes[ThemeCount].TitleColor  := CLR_YELLOW;
  Themes[ThemeCount].TextColor   := CLR_WHITE;
  Themes[ThemeCount].AccentColor := CLR_LCYAN;
  Themes[ThemeCount].FontSize    := 14;

  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Vert';
  Themes[ThemeCount].BgColor     := CLR_LGREEN;
  Themes[ThemeCount].TitleColor  := CLR_GREEN;
  Themes[ThemeCount].TextColor   := CLR_BLACK;
  Themes[ThemeCount].AccentColor := CLR_BROWN;
  Themes[ThemeCount].FontSize    := 14;
 End;
 Pres.ThemeIdx := 1;
End;

Procedure InitPresentation;
Var I: Integer;
Begin
 Pres.Name     := 'Presentation1';
 Pres.FileName := '';
 Pres.Author   := 'Sylvain Maltais';
 Pres.Company  := 'gladir.com';
 Pres.Title    := '';
 Pres.Subject  := '';
 Pres.Comments := '';
 Pres.SldCount := 0;
 For I := 1 To MAX_SLIDES Do Pres.Slides[I] := Nil;
 Pres.ImgCount := 0;
 For I := 1 To MAX_IMAGES Do Pres.Images[I] := Nil;
 Pres.Dirty    := False;
 Pres.HeaderText   := '';
 Pres.FooterText   := 'gladir.com';
 Pres.DateText     := '2026';
 Pres.ShowHeader   := False;
 Pres.ShowFooter   := True;
 Pres.ShowDate     := True;
 Pres.ShowSlideNum := True;
 Pres.MasterBg     := CLR_WHITE;
 Pres.MasterTitleC := CLR_BLUE;
 Pres.MasterTextC  := CLR_BLACK;
 Pres.EditingMaster := False;
 InitDefaultThemes;
 CurSlide := 0;
 CurShape := 0;
End;

Procedure FreePresentation;
Var I: Integer;
Begin
 For I := 1 To Pres.SldCount Do FreeSlide(Pres.Slides[I]);
 Pres.SldCount := 0;
 For I := 1 To Pres.ImgCount Do
  If Pres.Images[I] <> Nil Then Begin
   If Pres.Images[I]^.Pixels <> Nil Then Begin
    FreeMem(Pres.Images[I]^.Pixels,
            LongInt(Pres.Images[I]^.W) * Pres.Images[I]^.H);
    Pres.Images[I]^.Pixels := Nil;
   End;
   Dispose(Pres.Images[I]); Pres.Images[I] := Nil;
  End;
 Pres.ImgCount := 0;
End;

{ Place les placeholders selon le layout sur une nouvelle slide.
  Coordonnees en pixels relatifs au cadre de la slide (1000 x 750 logique,
  re-echellonne au dessin). }
Procedure ApplyLayout(S: PSlide; Lay: Byte);
Var P: PShape;
Begin
 If S = Nil Then Exit;
 S^.Layout := Lay;
 Case Lay Of
  LAY_TITLE: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 80; P^.Y := 200; P^.W := 840; P^.H := 140;
   P^.Filled := False; P^.FillColor := CLR_WHITE;
   P^.LineColor := CLR_DGRAY; P^.LineWidth := 0;
   P^.FontSize := 36; P^.TextColor := CLR_BLUE; P^.Align := ALIGN_CENTER;
   P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Cliquez pour ajouter un titre';
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_SUBTITLE;
   P^.X := 160; P^.Y := 380; P^.W := 680; P^.H := 80;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 20; P^.TextColor := CLR_DGRAY; P^.Align := ALIGN_CENTER;
   P^.TxtCount := 1; P^.Text[1] := 'Cliquez pour ajouter un sous-titre';
   AddShapeToSlide(S, P);
  End;
  LAY_TITLE_CONTENT: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 40; P^.W := 880; P^.H := 90;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 28; P^.TextColor := CLR_BLUE; P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Cliquez pour ajouter un titre';
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_CONTENT;
   P^.X := 60; P^.Y := 150; P^.W := 880; P^.H := 540;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 18;
   P^.TxtCount := 3;
   P^.Text[1] := 'Cliquez pour ajouter du texte';
   P^.Text[2] := 'Deuxieme puce'; P^.Bullets[2] := True;
   P^.Text[3] := 'Troisieme puce'; P^.Bullets[3] := True;
   P^.Bullets[1] := True;
   AddShapeToSlide(S, P);
  End;
  LAY_TWO_CONTENT: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 40; P^.W := 880; P^.H := 90;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 28; P^.TextColor := CLR_BLUE; P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Titre';
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_CONTENT;
   P^.X := 60; P^.Y := 150; P^.W := 420; P^.H := 540;
   P^.Filled := False; P^.LineWidth := 0;
   P^.TxtCount := 1; P^.Text[1] := 'Contenu gauche'; P^.Bullets[1] := True;
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_CONTENT;
   P^.X := 520; P^.Y := 150; P^.W := 420; P^.H := 540;
   P^.Filled := False; P^.LineWidth := 0;
   P^.TxtCount := 1; P^.Text[1] := 'Contenu droit'; P^.Bullets[1] := True;
   AddShapeToSlide(S, P);
  End;
  LAY_TITLE_ONLY: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 40; P^.W := 880; P^.H := 90;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 28; P^.TextColor := CLR_BLUE; P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Titre seul';
   AddShapeToSlide(S, P);
  End;
  LAY_SECTION: Begin
   P := NewShape;
   P^.ShType := SHP_RECT;
   P^.X := 0; P^.Y := 300; P^.W := 1000; P^.H := 150;
   P^.Filled := True; P^.FillColor := CLR_BLUE; P^.LineWidth := 0;
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 320; P^.W := 880; P^.H := 110;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 36; P^.TextColor := CLR_WHITE; P^.Bold := True;
   P^.Align := ALIGN_CENTER;
   P^.TxtCount := 1; P^.Text[1] := 'Nouvelle section';
   AddShapeToSlide(S, P);
  End;
  LAY_BLANK: Begin
   { rien }
  End;
 Else
  ApplyLayout(S, LAY_TITLE_CONTENT);
 End;
End;

Procedure SeedSamplePresentation;
Var Pos: Integer; S: PSlide; P: PShape;
Begin
 { Slide 1 : titre }
 Pos := AddSlideAt(1);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TITLE);
 S^.Shapes[1]^.Text[1] := 'Office-0 PowerPnt';
 S^.Shapes[2]^.Text[1] := 'Clone Pascal de Microsoft PowerPoint';

 { Slide 2 : titre + contenu }
 Pos := AddSlideAt(2);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TITLE_CONTENT);
 S^.Shapes[1]^.Text[1] := 'Fonctionnalites';
 S^.Shapes[2]^.TxtCount := 5;
 S^.Shapes[2]^.Text[1] := 'Edition vectorielle de diapositives';
 S^.Shapes[2]^.Text[2] := 'Mises en page multiples';
 S^.Shapes[2]^.Text[3] := 'Themes et arriere-plans';
 S^.Shapes[2]^.Text[4] := 'Transitions et animations';
 S^.Shapes[2]^.Text[5] := 'Export .PPT et .PPTX';
 S^.Shapes[2]^.Bullets[1] := True;
 S^.Shapes[2]^.Bullets[2] := True;
 S^.Shapes[2]^.Bullets[3] := True;
 S^.Shapes[2]^.Bullets[4] := True;
 S^.Shapes[2]^.Bullets[5] := True;

 { Slide 3 : deux colonnes avec une forme }
 Pos := AddSlideAt(3);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TWO_CONTENT);
 S^.Shapes[1]^.Text[1] := 'Phases du projet';
 S^.Shapes[2]^.TxtCount := 4;
 S^.Shapes[2]^.Text[1] := 'Charpente UI';
 S^.Shapes[2]^.Text[2] := 'Outils de dessin';
 S^.Shapes[2]^.Text[3] := 'Edition de texte';
 S^.Shapes[2]^.Text[4] := 'Layouts de slide';
 S^.Shapes[2]^.Bullets[1] := True;
 S^.Shapes[2]^.Bullets[2] := True;
 S^.Shapes[2]^.Bullets[3] := True;
 S^.Shapes[2]^.Bullets[4] := True;
 S^.Shapes[3]^.TxtCount := 4;
 S^.Shapes[3]^.Text[1] := 'Themes et masques';
 S^.Shapes[3]^.Text[2] := 'Diaporama F5';
 S^.Shapes[3]^.Text[3] := 'Animations';
 S^.Shapes[3]^.Text[4] := 'Format .PPTX';
 S^.Shapes[3]^.Bullets[1] := True;
 S^.Shapes[3]^.Bullets[2] := True;
 S^.Shapes[3]^.Bullets[3] := True;
 S^.Shapes[3]^.Bullets[4] := True;

 { Slide 4 : section }
 Pos := AddSlideAt(4);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_SECTION);
 S^.Shapes[2]^.Text[1] := 'Demarrage rapide';

 { Slide 5 : titre + contenu + forme decorative }
 Pos := AddSlideAt(5);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TITLE_CONTENT);
 S^.Shapes[1]^.Text[1] := 'Formes vectorielles';
 S^.Shapes[2]^.TxtCount := 2;
 S^.Shapes[2]^.Text[1] := 'Rectangles, ellipses, lignes';
 S^.Shapes[2]^.Text[2] := 'Etoiles, triangles, bulles';
 S^.Shapes[2]^.Bullets[1] := True;
 S^.Shapes[2]^.Bullets[2] := True;
 P := NewShape;
 P^.ShType := SHP_STAR;
 P^.X := 720; P^.Y := 380; P^.W := 180; P^.H := 180;
 P^.FillColor := CLR_YELLOW; P^.LineColor := CLR_BROWN;
 AddShapeToSlide(S, P);

 Pres.Dirty := False;
 CurSlide := 1;
End;

{ ====================================================================== }
{                       LAYOUT DE LA FENETRE                             }
{ ====================================================================== }

Procedure ComputeLayout;
Var AvW, AvH, SW, SH: Integer;
Begin
 { Zone disponible pour la slide affichee : entre toolbar/ruler et statusbar,
   entre panneau gauche et bord droit. }
 AvW := SCREEN_W - PANEL_W - 12;
 AvH := SCREEN_H - (MENU_H + TOOL_H + RULER_H) - STATUS_H - 12;
 { Conserver ratio 4:3 (1000x750) }
 SW := AvW;
 SH := (SW * 3) Div 4;
 If SH > AvH Then Begin
  SH := AvH;
  SW := (SH * 4) Div 3;
 End;
 SlideX1 := PANEL_W + 6 + (AvW - SW) Div 2;
 SlideY1 := MENU_H + TOOL_H + RULER_H + 6 + (AvH - SH) Div 2;
 SlideX2 := SlideX1 + SW;
 SlideY2 := SlideY1 + SH;
 SlideScale := (SW * 100) Div 1000;   { logique 1000 -> SW pixels }
End;

Function LogX(L: Integer): Integer;
Begin LogX := SlideX1 + (L * (SlideX2 - SlideX1)) Div 1000; End;

Function LogY(L: Integer): Integer;
Begin LogY := SlideY1 + (L * (SlideY2 - SlideY1)) Div 750; End;

Function LogW(L: Integer): Integer;
Begin LogW := (L * (SlideX2 - SlideX1)) Div 1000; End;

Function LogH(L: Integer): Integer;
Begin LogH := (L * (SlideY2 - SlideY1)) Div 750; End;

{ ====================================================================== }
{                       RENDU D'UNE FORME                                }
{ ====================================================================== }

{ --- Phase 8 : images BMP/PCX --- }

{ Couleur VGA 16 la plus proche d'un triplet RGB. }
Function NearestVGA16(R, G, B: Integer): Byte;
Var I, BestI: Integer; D, BestD, DR, DG, DB: LongInt;
Begin
 BestI := 0; BestD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - VGA_R[I];
  DG := LongInt(G) - VGA_G[I];
  DB := LongInt(B) - VGA_B[I];
  D  := DR*DR + DG*DG + DB*DB;
  If D < BestD Then Begin BestD := D; BestI := I; End;
 End;
 NearestVGA16 := Byte(BestI);
End;

{ Libere la memoire pixels d'une image. }
Procedure FreeImagePixels(Img: PImage);
Begin
 If Img = Nil Then Exit;
 If Img^.Pixels <> Nil Then Begin
  FreeMem(Img^.Pixels, LongInt(Img^.W) * Img^.H);
  Img^.Pixels := Nil;
 End;
 Img^.W := 0; Img^.H := 0; Img^.Loaded := False;
End;

{ Trouve un slot d'image libre (1..MAX_IMAGES), ou 0 si plein. }
Function FindFreeImageSlot: Integer;
Var I: Integer;
Begin
 For I := 1 To MAX_IMAGES Do
  If Pres.Images[I] = Nil Then Begin
   FindFreeImageSlot := I; Exit;
  End;
 FindFreeImageSlot := 0;
End;

{ Alloue un slot image avec un buffer pixel W*H octets. }
Function AllocImageSlot(W, H: Integer; Const Nm: String): Integer;
Var Slot: Integer; Img: PImage; Sz: LongInt;
Begin
 AllocImageSlot := 0;
 Slot := FindFreeImageSlot;
 If Slot = 0 Then Exit;
 New(Img);
 If Img = Nil Then Exit;
 Img^.Name     := Nm;
 Img^.FileName := '';
 Img^.W        := W;
 Img^.H        := H;
 Img^.Loaded   := False;
 Img^.Pixels   := Nil;
 Sz := LongInt(W) * H;
 If Sz > 0 Then Begin
  GetMem(Img^.Pixels, Sz);
  If Img^.Pixels = Nil Then Begin Dispose(Img); Exit; End;
  FillChar(Img^.Pixels^, Sz, 0);
 End;
 Pres.Images[Slot] := Img;
 If Slot > Pres.ImgCount Then Pres.ImgCount := Slot;
 AllocImageSlot := Slot;
End;

{ --- LoadBMP : 1/4/8/24 bpp non compresse --- }

Function LoadImageBMP(Const FN: String; Var Slot: Integer): Boolean;
Type
 TBMPFile = Packed Record
  bfType: Word; bfSize: LongInt;
  bfRes1, bfRes2: Word; bfOffBits: LongInt;
 End;
 TBMPInfo = Packed Record
  biSize: LongInt; biWidth, biHeight: LongInt;
  biPlanes, biBitCount: Word;
  biCompression, biSizeImage: LongInt;
  biXPel, biYPel: LongInt;
  biClrUsed, biClrImp: LongInt;
 End;
 TRGBQ = Packed Record B, G, R, X: Byte; End;
Var F: File; FH: TBMPFile; IH: TBMPInfo; Got: Word;
    RowSize: LongInt; W, H, X, Y, SrcY, I, PalN: Integer;
    RowBuf: Array[0..4095] Of Byte;
    Pal: Array[0..255] Of TRGBQ;
    Remap: Array[0..255] Of Byte;
    Img: PImage; V, BV: Byte; BP: Integer;
    Rb, Gb, Bb: Byte;
Begin
 LoadImageBMP := False; Slot := 0;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, FH, SizeOf(FH), Got);
 If (Got <> SizeOf(FH)) Or (FH.bfType <> BMP_SIGNATURE) Then Begin Close(F); Exit; End;
 BlockRead(F, IH, SizeOf(IH), Got);
 If Got <> SizeOf(IH) Then Begin Close(F); Exit; End;
 W := IH.biWidth; H := Abs(IH.biHeight);
 If (W <= 0) Or (H <= 0) Then Begin Close(F); Exit; End;
 If W > MAX_IMG_W Then W := MAX_IMG_W;
 If H > MAX_IMG_H Then H := MAX_IMG_H;
 If IH.biCompression <> 0 Then Begin Close(F); Exit; End;
 RowSize := ((LongInt(IH.biWidth) * IH.biBitCount + 31) Div 32) * 4;
 If RowSize > 4096 Then Begin Close(F); Exit; End;
 If IH.biBitCount <= 8 Then Begin
  If IH.biClrUsed > 0 Then PalN := IH.biClrUsed
                      Else PalN := 1 Shl IH.biBitCount;
  BlockRead(F, Pal, PalN * 4, Got);
  For I := 0 To PalN - 1 Do
   Remap[I] := NearestVGA16(Pal[I].R, Pal[I].G, Pal[I].B);
  For I := PalN To 255 Do Remap[I] := 0;
 End;
 Slot := AllocImageSlot(W, H, FN);
 If Slot = 0 Then Begin Close(F); Exit; End;
 Img := Pres.Images[Slot];
 Seek(F, FH.bfOffBits);
 For Y := 0 To H - 1 Do Begin
  BlockRead(F, RowBuf, RowSize, Got);
  If IH.biHeight < 0 Then SrcY := Y Else SrcY := H - 1 - Y;
  For X := 0 To W - 1 Do Begin
   V := 0;
   Case IH.biBitCount Of
    1: Begin
     BV := RowBuf[X Shr 3]; BP := 7 - (X And 7);
     V := Remap[(BV Shr BP) And 1];
    End;
    4: Begin
     BV := RowBuf[X Shr 1];
     If (X And 1) = 0 Then V := Remap[(BV Shr 4) And 15]
                      Else V := Remap[BV And 15];
    End;
    8: V := Remap[RowBuf[X]];
    24: Begin
     Bb := RowBuf[X*3]; Gb := RowBuf[X*3+1]; Rb := RowBuf[X*3+2];
     V := NearestVGA16(Rb, Gb, Bb);
    End;
   End;
   Img^.Pixels^[LongInt(SrcY) * W + X] := V;
  End;
 End;
 Close(F);
 Img^.Loaded := True;
 LoadImageBMP := True;
End;

{ --- LoadPCX : 1/4/8 bpp, jusqu'a 4 plans --- }

Function LoadImagePCX(Const FN: String; Var Slot: Integer): Boolean;
Type
 TPCXHdr = Packed Record
  Manuf, Ver, Enc, BPP: Byte;
  Xmin, Ymin, Xmax, Ymax: Word;
  HDpi, VDpi: Word;
  EgaPal: Array[0..47] Of Byte;
  Reserved: Byte;
  NPlanes: Byte;
  BytesPerLine: Word;
  PalInfo: Word;
  HScr, VScr: Word;
  Filler: Array[0..53] Of Byte;
 End;
Var F: File; H: TPCXHdr; Got: Word; FSz: LongInt;
    Tail: Array[0..768] Of Byte;
    PalR, PalG, PalB: Array[0..255] Of Byte;
    Remap: Array[0..255] Of Byte;
    PalCount, I: Integer;
    HasPal8: Boolean;
    PcxW, PcxH, ScanBytes: LongInt;
    Scan: Array[0..16383] Of Byte;
    W, Hh, X, Y, ByteOff, BitIdx, Plane, BitC, Idx: Integer;
    Img: PImage;
    FBuf: Array[0..16383] Of Byte;
    FLen, FPos: Integer; FEof: Boolean;

 Function R1: Integer;
 Var G: Word;
 Begin
  If FPos >= FLen Then Begin
   If FEof Then Begin R1 := -1; Exit; End;
   BlockRead(F, FBuf, 16384, G); FLen := G; FPos := 0;
   If G = 0 Then Begin FEof := True; R1 := -1; Exit; End;
  End;
  R1 := FBuf[FPos]; Inc(FPos);
 End;

 Function ReadScan: Boolean;
 Var Cnt, Val, J: Integer; P: LongInt;
 Begin
  ReadScan := False; P := 0;
  While P < ScanBytes Do Begin
   Val := R1; If Val < 0 Then Exit;
   If (Val And $C0) = $C0 Then Begin
    Cnt := Val And $3F; Val := R1;
    If Val < 0 Then Exit;
    For J := 1 To Cnt Do Begin
     If P < ScanBytes Then Scan[P] := Byte(Val);
     Inc(P);
    End;
   End Else Begin
    Scan[P] := Byte(Val); Inc(P);
   End;
  End;
  ReadScan := True;
 End;

Begin
 LoadImagePCX := False; Slot := 0;
 FLen := 0; FPos := 0; FEof := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, H, SizeOf(H), Got);
 If Got <> SizeOf(H) Then Begin Close(F); Exit; End;
 If (H.Manuf <> $0A) Or (H.Enc <> 1) Then Begin Close(F); Exit; End;
 If (H.BPP <> 1) And (H.BPP <> 4) And (H.BPP <> 8) Then Begin Close(F); Exit; End;
 If (H.NPlanes < 1) Or (H.NPlanes > 4) Then Begin Close(F); Exit; End;
 PcxW := LongInt(H.Xmax) - H.Xmin + 1;
 PcxH := LongInt(H.Ymax) - H.Ymin + 1;
 If (PcxW <= 0) Or (PcxH <= 0) Then Begin Close(F); Exit; End;
 ScanBytes := LongInt(H.BytesPerLine) * H.NPlanes;
 If (ScanBytes <= 0) Or (ScanBytes > 16384) Then Begin Close(F); Exit; End;
 HasPal8 := False; PalCount := 0;
 If (H.BPP = 8) And (H.NPlanes = 1) Then Begin
  FSz := FileSize(F);
  If FSz >= 769 Then Begin
   Seek(F, FSz - 769);
   BlockRead(F, Tail, 769, Got);
   If (Got = 769) And (Tail[0] = $0C) Then Begin
    HasPal8 := True; PalCount := 256;
    For I := 0 To 255 Do Begin
     PalR[I] := Tail[1 + I*3];
     PalG[I] := Tail[1 + I*3 + 1];
     PalB[I] := Tail[1 + I*3 + 2];
    End;
   End;
  End;
  Seek(F, 128);
  FLen := 0; FPos := 0; FEof := False;
 End;
 If Not HasPal8 Then Begin
  PalCount := 16;
  For I := 0 To 15 Do Begin
   PalR[I] := H.EgaPal[I*3];
   PalG[I] := H.EgaPal[I*3 + 1];
   PalB[I] := H.EgaPal[I*3 + 2];
  End;
  If (H.NPlanes = 1) And (H.BPP = 1) Then Begin
   PalR[0]:=0;   PalG[0]:=0;   PalB[0]:=0;
   PalR[1]:=255; PalG[1]:=255; PalB[1]:=255;
  End;
 End;
 For I := 0 To PalCount - 1 Do
  Remap[I] := NearestVGA16(PalR[I], PalG[I], PalB[I]);
 For I := PalCount To 255 Do Remap[I] := 0;
 W := PcxW; Hh := PcxH;
 If W  > MAX_IMG_W Then W  := MAX_IMG_W;
 If Hh > MAX_IMG_H Then Hh := MAX_IMG_H;
 Slot := AllocImageSlot(W, Hh, FN);
 If Slot = 0 Then Begin Close(F); Exit; End;
 Img := Pres.Images[Slot];
 For Y := 0 To PcxH - 1 Do Begin
  If Not ReadScan Then Begin Close(F); Exit; End;
  If Y >= Hh Then Continue;
  For X := 0 To W - 1 Do Begin
   Idx := 0;
   If (H.NPlanes = 1) And (H.BPP = 8) Then Idx := Scan[X]
   Else If (H.NPlanes = 1) And (H.BPP = 1) Then Begin
    ByteOff := X Shr 3; BitIdx := 7 - (X And 7);
    Idx := (Scan[ByteOff] Shr BitIdx) And 1;
   End
   Else If (H.NPlanes = 1) And (H.BPP = 4) Then Begin
    ByteOff := X Shr 1;
    If (X And 1) = 0 Then Idx := (Scan[ByteOff] Shr 4) And 15
                     Else Idx := Scan[ByteOff] And 15;
   End
   Else If (H.BPP = 1) And (H.NPlanes >= 2) Then Begin
    ByteOff := X Shr 3; BitIdx := 7 - (X And 7);
    Idx := 0;
    For Plane := 0 To H.NPlanes - 1 Do
     If ((Scan[Plane * H.BytesPerLine + ByteOff] Shr BitIdx) And 1) <> 0 Then
      Idx := Idx Or (1 Shl Plane);
   End;
   Img^.Pixels^[LongInt(Y) * W + X] := Remap[Idx];
  End;
 End;
 Close(F);
 Img^.Loaded := True;
 LoadImagePCX := True;
End;

{ Charge une image en detectant le format via l'extension. }
Function LoadImageFile(Const FN: String; Var Slot: Integer): Boolean;
Var I: Integer; Ext: String;
Begin
 Ext := '';
 For I := Length(FN) DownTo 1 Do
  If FN[I] = '.' Then Begin Ext := Copy(FN, I + 1, 8); Break; End;
 For I := 1 To Length(Ext) Do
  If (Ext[I] >= 'a') And (Ext[I] <= 'z') Then
   Ext[I] := Chr(Ord(Ext[I]) - 32);
 If Ext = 'BMP' Then LoadImageFile := LoadImageBMP(FN, Slot)
 Else If Ext = 'PCX' Then LoadImageFile := LoadImagePCX(FN, Slot)
 Else LoadImageFile := False;
End;

{ Affiche une image (palette 16) mise a l'echelle dans [X1..X2]x[Y1..Y2]. }
Procedure DrawImageScaled(Img: PImage; X1, Y1, X2, Y2: Integer);
Var Sx, Sy, Ix, Iy, Dw, Dh: Integer;
Begin
 If Img = Nil Then Exit;
 If Not Img^.Loaded Then Exit;
 If Img^.Pixels = Nil Then Exit;
 Dw := X2 - X1 + 1; Dh := Y2 - Y1 + 1;
 If (Dw <= 0) Or (Dh <= 0) Then Exit;
 For Sy := 0 To Dh - 1 Do Begin
  Iy := LongInt(Sy) * Img^.H Div Dh;
  If Iy >= Img^.H Then Iy := Img^.H - 1;
  For Sx := 0 To Dw - 1 Do Begin
   Ix := LongInt(Sx) * Img^.W Div Dw;
   If Ix >= Img^.W Then Ix := Img^.W - 1;
   PutPixel(X1 + Sx, Y1 + Sy,
            Img^.Pixels^[LongInt(Iy) * Img^.W + Ix]);
  End;
 End;
End;

Procedure DrawShapeTextLines(P: PShape; X1, Y1, X2, Y2: Integer);
Var I, Ty, Tx, LineH, TitleSz, Ind, CaretX: Integer; S: String;
    IsEditing: Boolean;
Begin
 If P^.TxtCount <= 0 Then Exit;
 LineH := 12;
 If P^.FontSize >= 24 Then LineH := 22
 Else If P^.FontSize >= 18 Then LineH := 16
 Else LineH := 12;
 Ty := Y1 + 4;
 For I := 1 To P^.TxtCount Do Begin
  IsEditing := EditMode And (CurSlide >= 1) And
               (Pres.Slides[CurSlide]^.Shapes[CurShape] = P) And
               (EditLine = I);
  If IsEditing Then S := EditBuf Else S := P^.Text[I];
  Ind := P^.Indent[I] * 12;
  TitleSz := 1;
  If P^.FontSize >= 24 Then TitleSz := 2;
  If P^.FontSize >= 36 Then TitleSz := 3;
  SetTextStyle(DefaultFont, HorizDir, TitleSz);
  Case P^.Align Of
   ALIGN_CENTER: Tx := (X1 + X2) Div 2 - TextWidth(S) Div 2;
   ALIGN_RIGHT:  Tx := X2 - TextWidth(S) - 4;
  Else Tx := X1 + 4 + Ind;
  End;
  If P^.Bullets[I] Then Begin
   SetColor(P^.TextColor);
   FillBox(Tx - 8, Ty + 4, Tx - 5, Ty + 6, P^.TextColor);
   Tx := Tx + 4;
  End;
  SetColor(P^.TextColor);
  OutTextXY(Tx, Ty, S);
  If P^.Underline Then
   Line(Tx, Ty + LineH - 2, Tx + TextWidth(S), Ty + LineH - 2);
  { Texte en gras simule par re-trace decale d'un pixel }
  If P^.Bold Then OutTextXY(Tx + 1, Ty, S);
  { Caret clignotant en edition }
  If IsEditing And BlinkState Then Begin
   If (EditCaret >= 0) And (EditCaret <= Length(S)) Then
    CaretX := Tx + TextWidth(Copy(S, 1, EditCaret))
   Else
    CaretX := Tx + TextWidth(S);
   SetColor(CLR_BLACK);
   Line(CaretX, Ty, CaretX, Ty + LineH - 2);
  End;
  SetTextStyle(DefaultFont, HorizDir, 1);
  Ty := Ty + LineH;
  If Ty > Y2 - LineH Then Exit;
 End;
End;

Procedure DrawStarShape(X1, Y1, X2, Y2: Integer; Fill, LineCol: Integer);
Var Cx, Cy, Rx, Ry, I: Integer;
    Pts: Array[1..11] Of Record X, Y: Integer; End;
    Angle, R: Real;
Begin
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 Rx := (X2 - X1) Div 2; Ry := (Y2 - Y1) Div 2;
 For I := 1 To 10 Do Begin
  Angle := (I - 1) * 36.0 * Pi / 180.0 - Pi / 2.0;
  If (I Mod 2) = 1 Then R := 1.0 Else R := 0.45;
  Pts[I].X := Cx + Round(R * Rx * Cos(Angle));
  Pts[I].Y := Cy + Round(R * Ry * Sin(Angle));
 End;
 Pts[11] := Pts[1];
 SetFillStyle(1, Fill);
 SetColor(LineCol);
 For I := 1 To 10 Do
  Line(Pts[I].X, Pts[I].Y, Pts[I + 1].X, Pts[I + 1].Y);
 FloodFill(Cx, Cy, LineCol);
End;

Procedure DrawDiamondShape(X1, Y1, X2, Y2: Integer; Fill, LineCol: Integer);
Var Cx, Cy: Integer;
Begin
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 SetColor(LineCol);
 SetFillStyle(1, Fill);
 Line(Cx, Y1, X2, Cy);
 Line(X2, Cy, Cx, Y2);
 Line(Cx, Y2, X1, Cy);
 Line(X1, Cy, Cx, Y1);
 FloodFill(Cx, Cy, LineCol);
End;

Procedure DrawTriangleShape(X1, Y1, X2, Y2: Integer; Fill, LineCol: Integer);
Var Cx: Integer;
Begin
 Cx := (X1 + X2) Div 2;
 SetColor(LineCol);
 SetFillStyle(1, Fill);
 Line(Cx, Y1, X2, Y2);
 Line(X2, Y2, X1, Y2);
 Line(X1, Y2, Cx, Y1);
 FloodFill(Cx, (Y1 + Y2) Div 2 + (Y2 - Y1) Div 4, LineCol);
End;

Procedure DrawShape(P: PShape);
Var X1, Y1, X2, Y2, Cx, Cy: Integer;
Begin
 If P = Nil Then Exit;
 If P^.Hidden Then Exit;
 X1 := LogX(P^.X);
 Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W);
 Y2 := LogY(P^.Y + P^.H);
 Case P^.ShType Of
  SHP_RECT: Begin
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor); Bar(X1, Y1, X2, Y2);
   End;
   If P^.LineWidth > 0 Then Begin
    SetColor(P^.LineColor); Rectangle(X1, Y1, X2, Y2);
   End;
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
  End;
  SHP_ROUNDRECT: Begin
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor); Bar(X1 + 6, Y1 + 6, X2 - 6, Y2 - 6);
    Bar(X1, Y1 + 6, X2, Y2 - 6); Bar(X1 + 6, Y1, X2 - 6, Y2);
   End;
   SetColor(P^.LineColor);
   Line(X1 + 6, Y1, X2 - 6, Y1);
   Line(X1 + 6, Y2, X2 - 6, Y2);
   Line(X1, Y1 + 6, X1, Y2 - 6);
   Line(X2, Y1 + 6, X2, Y2 - 6);
   Arc(X1 + 6, Y1 + 6, 90, 180, 6);
   Arc(X2 - 6, Y1 + 6, 0,  90, 6);
   Arc(X1 + 6, Y2 - 6, 180,270, 6);
   Arc(X2 - 6, Y2 - 6, 270,360, 6);
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
  End;
  SHP_ELLIPSE: Begin
   Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor);
    FillEllipse(Cx, Cy, (X2 - X1) Div 2, (Y2 - Y1) Div 2);
   End;
   SetColor(P^.LineColor);
   Ellipse(Cx, Cy, 0, 360, (X2 - X1) Div 2, (Y2 - Y1) Div 2);
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
  End;
  SHP_LINE: Begin
   SetColor(P^.LineColor);
   Line(X1, Y1, X2, Y2);
  End;
  SHP_ARROW: Begin
   SetColor(P^.LineColor);
   Line(X1, Y1, X2, Y2);
   Line(X2, Y2, X2 - 8, Y2 - 4);
   Line(X2, Y2, X2 - 8, Y2 + 4);
  End;
  SHP_TRIANGLE:  DrawTriangleShape(X1, Y1, X2, Y2, P^.FillColor, P^.LineColor);
  SHP_DIAMOND:   DrawDiamondShape (X1, Y1, X2, Y2, P^.FillColor, P^.LineColor);
  SHP_STAR:      DrawStarShape    (X1, Y1, X2, Y2, P^.FillColor, P^.LineColor);
  SHP_TITLE,
  SHP_SUBTITLE,
  SHP_TEXT,
  SHP_CONTENT: Begin
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor); Bar(X1, Y1, X2, Y2);
   End;
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
   { Bord en pointille pour les placeholders sans contenu defini }
   If (P^.LineWidth = 0) And EditMode And (CurShape = 0) Then Begin
    SetColor(CLR_DGRAY);
    Rectangle(X1, Y1, X2, Y2);
   End;
  End;
  SHP_IMAGE: Begin
   If (P^.ImageIdx >= 1) And (P^.ImageIdx <= MAX_IMAGES) And
      (Pres.Images[P^.ImageIdx] <> Nil) And
      Pres.Images[P^.ImageIdx]^.Loaded Then Begin
    DrawImageScaled(Pres.Images[P^.ImageIdx], X1, Y1, X2, Y2);
    SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
   End Else Begin
    FillBox(X1, Y1, X2, Y2, CLR_LGRAY);
    SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
    Line(X1, Y1, X2, Y2); Line(X1, Y2, X2, Y1);
    SetColor(CLR_BLACK);
    OutTextXY(X1 + 4, Y1 + 4, '[Image]');
   End;
  End;
  SHP_TABLE: Begin
   FillBox(X1, Y1, X2, Y2, CLR_WHITE);
   SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
  End;
  SHP_CHART: Begin
   FillBox(X1, Y1, X2, Y2, CLR_WHITE);
   SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
   SetColor(CLR_BLUE);
   Bar(X1 + 10, Y2 - 30, X1 + 30, Y2 - 4);
   SetFillStyle(1, CLR_LGREEN); Bar(X1 + 35, Y2 - 60, X1 + 55, Y2 - 4);
   SetFillStyle(1, CLR_LRED);   Bar(X1 + 60, Y2 - 45, X1 + 80, Y2 - 4);
  End;
 Else
  { Forme inconnue : rectangle simple }
  SetColor(P^.LineColor); Rectangle(X1, Y1, X2, Y2);
 End;
End;

Procedure DrawSelectionHandles(P: PShape);
Var X1, Y1, X2, Y2, Cx, Cy: Integer;
Begin
 If P = Nil Then Exit;
 X1 := LogX(P^.X);
 Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W);
 Y2 := LogY(P^.Y + P^.H);
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 SetColor(CLR_BLUE);
 Rectangle(X1 - 1, Y1 - 1, X2 + 1, Y2 + 1);
 FillBox(X1 - 3, Y1 - 3, X1 + 1, Y1 + 1, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X1 - 3, Y1 - 3, X1 + 1, Y1 + 1);
 FillBox(X2 - 1, Y1 - 3, X2 + 3, Y1 + 1, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X2 - 1, Y1 - 3, X2 + 3, Y1 + 1);
 FillBox(X1 - 3, Y2 - 1, X1 + 1, Y2 + 3, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X1 - 3, Y2 - 1, X1 + 1, Y2 + 3);
 FillBox(X2 - 1, Y2 - 1, X2 + 3, Y2 + 3, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X2 - 1, Y2 - 1, X2 + 3, Y2 + 3);
 FillBox(Cx - 2, Y1 - 3, Cx + 2, Y1 + 1, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(Cx - 2, Y1 - 3, Cx + 2, Y1 + 1);
 FillBox(Cx - 2, Y2 - 1, Cx + 2, Y2 + 3, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(Cx - 2, Y2 - 1, Cx + 2, Y2 + 3);
 FillBox(X1 - 3, Cy - 2, X1 + 1, Cy + 2, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X1 - 3, Cy - 2, X1 + 1, Cy + 2);
 FillBox(X2 - 1, Cy - 2, X2 + 3, Cy + 2, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X2 - 1, Cy - 2, X2 + 3, Cy + 2);
End;

{ ====================================================================== }
{                       PANNEAU MINIATURES                               }
{ ====================================================================== }

Const
 THUMB_H_TOTAL = 60;     { hauteur d'une miniature + marge }
 THUMB_PAD     = 6;

Procedure DrawSlideThumb(Idx, Y: Integer);
Var X1, X2, Y1, Y2, Tw, I: Integer; S: PSlide; Sh: PShape;
    SX1, SY1, SX2, SY2: Integer; Title: String;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx];
 X1 := 8;          X2 := PANEL_W - 8;
 Y1 := Y;          Y2 := Y + THUMB_H_TOTAL - THUMB_PAD;
 { Numero }
 SetColor(CLR_WHITE);
 OutTextXY(2, Y1 + 14, IntToStr(Idx));
 { Cadre miniature }
 If Idx = CurSlide Then Begin
  FillBox(X1 - 2, Y1 - 2, X2 + 2, Y2 + 2, CLR_PANEL_SEL);
 End;
 FillBox(X1, Y1, X2, Y2, S^.Background);
 SetColor(CLR_BLACK); Rectangle(X1, Y1, X2, Y2);
 { Apercu simplifie : rectangles colores selon les formes }
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I];
  If Sh = Nil Then Continue;
  SX1 := X1 + ((Sh^.X) * (X2 - X1)) Div 1000;
  SY1 := Y1 + ((Sh^.Y) * (Y2 - Y1)) Div 750;
  SX2 := X1 + ((Sh^.X + Sh^.W) * (X2 - X1)) Div 1000;
  SY2 := Y1 + ((Sh^.Y + Sh^.H) * (Y2 - Y1)) Div 750;
  If SX2 > X2 Then SX2 := X2;
  If SY2 > Y2 Then SY2 := Y2;
  If SX1 < X1 Then SX1 := X1;
  If SY1 < Y1 Then SY1 := Y1;
  Case Sh^.ShType Of
   SHP_TITLE, SHP_SUBTITLE: Begin
    SetColor(CLR_BLUE);
    Line(SX1, (SY1 + SY2) Div 2, SX2, (SY1 + SY2) Div 2);
   End;
   SHP_CONTENT, SHP_TEXT: Begin
    SetColor(CLR_DGRAY);
    Line(SX1, SY1 + 2, SX2 - 4, SY1 + 2);
    Line(SX1, SY1 + 6, SX2 - 4, SY1 + 6);
    Line(SX1, SY1 + 10, SX2 - 8, SY1 + 10);
   End;
   SHP_ELLIPSE: Begin
    SetFillStyle(1, Sh^.FillColor);
    FillEllipse((SX1 + SX2) Div 2, (SY1 + SY2) Div 2,
                MaxI(2,(SX2 - SX1) Div 2), MaxI(2,(SY2 - SY1) Div 2));
   End;
   SHP_STAR, SHP_TRIANGLE, SHP_DIAMOND: Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  Else
   If Sh^.Filled Then Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  End;
 End;
 { Titre raccourci }
 Title := S^.Title;
 If Title = '' Then
  If (S^.ShCount > 0) And (S^.Shapes[1] <> Nil) And
     (S^.Shapes[1]^.ShType In [SHP_TITLE, SHP_SUBTITLE, SHP_TEXT]) Then
   Title := S^.Shapes[1]^.Text[1];
 If Length(Title) > 14 Then Title := Copy(Title, 1, 14);
 SetColor(CLR_WHITE);
 Tw := TextWidth(Title);
 If Tw > X2 - X1 - 4 Then Tw := X2 - X1 - 4;
 OutTextXY(X1 + ((X2 - X1) - Tw) Div 2, Y2 + 2, Title);
End;

Procedure DrawSlidePanel;
Var I, Y, Top, Bottom: Integer;
Begin
 HideMouse;
 Top    := MENU_H + TOOL_H;
 Bottom := SCREEN_H - STATUS_H;
 FillBox(0, Top, PANEL_W - 1, Bottom - 1, CLR_PANEL_BG);
 VLine(PANEL_W - 1, Top, Bottom - 1, CLR_WIN_LO);
 Y := Top + 10 - PanelScroll;
 For I := 1 To Pres.SldCount Do Begin
  If (Y + THUMB_H_TOTAL > Top) And (Y < Bottom) Then
   DrawSlideThumb(I, Y);
  Y := Y + THUMB_H_TOTAL;
 End;
 ShowMouse;
End;

Function SlideAtPanelY(Y: LongInt): Integer;
Var I, Yy, Top: Integer;
Begin
 SlideAtPanelY := 0;
 Top := MENU_H + TOOL_H;
 Yy  := Top + 10 - PanelScroll;
 For I := 1 To Pres.SldCount Do Begin
  If (Y >= Yy) And (Y < Yy + THUMB_H_TOTAL - THUMB_PAD) Then Begin
   SlideAtPanelY := I; Exit;
  End;
  Yy := Yy + THUMB_H_TOTAL;
 End;
End;

{ ====================================================================== }
{                       REGLE                                            }
{ ====================================================================== }

Procedure DrawRuler;
Var X, Y, Tk, X1, X2: Integer;
Begin
 Y  := MENU_H + TOOL_H;
 X1 := PANEL_W;
 X2 := SCREEN_W - 1;
 FillBox(X1, Y, X2, Y + RULER_H - 1, CLR_WIN_BG);
 HLine(X1, X2, Y + RULER_H - 1, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 For Tk := 0 To 20 Do Begin
  X := X1 + 4 + (Tk * (X2 - X1 - 8)) Div 20;
  If (Tk Mod 5) = 0 Then Line(X, Y + 4, X, Y + RULER_H - 3)
  Else Line(X, Y + 8, X, Y + RULER_H - 3);
 End;
End;

{ ====================================================================== }
{                       ZONE PRINCIPALE                                  }
{ ====================================================================== }

Procedure DrawMasterOverlay(SlideIdx: Integer; X1, Y1, X2, Y2: Integer); Forward;

{ Dessine une miniature de diapositive a une position et taille arbitraires.
  Utilise par la trieuse de diapositives (Phase 5). }
Procedure DrawSlideThumbAt(Idx, X1, Y1, X2, Y2: Integer; Selected: Boolean);
Var I, SX1, SY1, SX2, SY2: Integer; S: PSlide; Sh: PShape;
    Title: String; Tw: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx];
 If Selected Then Begin
  FillBox(X1 - 3, Y1 - 3, X2 + 3, Y2 + 3, CLR_PANEL_SEL);
 End;
 FillBox(X1, Y1, X2, Y2, S^.Background);
 SetColor(CLR_BLACK); Rectangle(X1, Y1, X2, Y2);
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I]; If Sh = Nil Then Continue;
  SX1 := X1 + ((Sh^.X) * (X2 - X1)) Div 1000;
  SY1 := Y1 + ((Sh^.Y) * (Y2 - Y1)) Div 750;
  SX2 := X1 + ((Sh^.X + Sh^.W) * (X2 - X1)) Div 1000;
  SY2 := Y1 + ((Sh^.Y + Sh^.H) * (Y2 - Y1)) Div 750;
  If SX2 > X2 Then SX2 := X2;  If SY2 > Y2 Then SY2 := Y2;
  If SX1 < X1 Then SX1 := X1;  If SY1 < Y1 Then SY1 := Y1;
  Case Sh^.ShType Of
   SHP_TITLE, SHP_SUBTITLE: Begin
    SetColor(CLR_BLUE);
    Line(SX1, (SY1 + SY2) Div 2, SX2, (SY1 + SY2) Div 2);
   End;
   SHP_CONTENT, SHP_TEXT: Begin
    SetColor(CLR_DGRAY);
    Line(SX1, SY1 + 3, SX2 - 4, SY1 + 3);
    Line(SX1, SY1 + 8, SX2 - 4, SY1 + 8);
    Line(SX1, SY1 + 13, SX2 - 8, SY1 + 13);
   End;
   SHP_ELLIPSE: Begin
    SetFillStyle(1, Sh^.FillColor);
    FillEllipse((SX1 + SX2) Div 2, (SY1 + SY2) Div 2,
                MaxI(2, (SX2 - SX1) Div 2), MaxI(2, (SY2 - SY1) Div 2));
   End;
   SHP_STAR, SHP_TRIANGLE, SHP_DIAMOND: Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  Else
   If Sh^.Filled Then Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  End;
 End;
 If S^.Hidden Then Begin
  SetColor(CLR_LRED);
  Line(X1, Y1, X2, Y2); Line(X1, Y2, X2, Y1);
 End;
 { Numero + titre au bas }
 SetColor(CLR_BLACK);
 OutTextXY(X1, Y2 + 2, IntToStr(Idx) + '.');
 Title := S^.Title;
 If Title = '' Then
  If (S^.ShCount > 0) And (S^.Shapes[1] <> Nil) And
     (S^.Shapes[1]^.ShType In [SHP_TITLE, SHP_SUBTITLE, SHP_TEXT]) Then
   Title := S^.Shapes[1]^.Text[1];
 If Length(Title) > 18 Then Title := Copy(Title, 1, 18);
 Tw := TextWidth(Title);
 If Tw > X2 - X1 - 20 Then Tw := X2 - X1 - 20;
 OutTextXY(X1 + 20, Y2 + 2, Title);
End;

{ ---------- TRIEUSE DE DIAPOSITIVES (VIEW_SORTER) ---------- }

Const
 SORT_COLS    = 4;
 SORT_THUMB_W = 130;
 SORT_THUMB_H = 90;
 SORT_GAP_X   = 16;
 SORT_GAP_Y   = 28;
 SORT_PAD_TOP = 16;

Function SorterCellRect(Idx: Integer; Var X1, Y1, X2, Y2: Integer): Boolean;
Var Col, Row, AreaTop, AreaLeft: Integer;
Begin
 SorterCellRect := False;
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 AreaTop  := MENU_H + TOOL_H + RULER_H;
 AreaLeft := PANEL_W;
 Col := (Idx - 1) Mod SORT_COLS;
 Row := (Idx - 1) Div SORT_COLS;
 X1 := AreaLeft + SORT_GAP_X + Col * (SORT_THUMB_W + SORT_GAP_X);
 Y1 := AreaTop  + SORT_PAD_TOP - SorterScroll + Row * (SORT_THUMB_H + SORT_GAP_Y);
 X2 := X1 + SORT_THUMB_W;
 Y2 := Y1 + SORT_THUMB_H;
 SorterCellRect := True;
End;

Function SorterAt(Mx, My: LongInt): Integer;
Var I, X1, Y1, X2, Y2: Integer;
Begin
 SorterAt := 0;
 For I := 1 To Pres.SldCount Do
  If SorterCellRect(I, X1, Y1, X2, Y2) Then
   If (Mx >= X1 - 3) And (Mx <= X2 + 3) And
      (My >= Y1 - 3) And (My <= Y2 + 3) Then Begin
    SorterAt := I; Exit;
   End;
End;

Procedure DrawSorterView;
Var I, X1, Y1, X2, Y2, Top, Bottom, Left, Right: Integer;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WORK_BG);
 If SorterSel < 1 Then SorterSel := CurSlide;
 If SorterSel > Pres.SldCount Then SorterSel := Pres.SldCount;
 If SorterSel < 1 Then SorterSel := 0;
 For I := 1 To Pres.SldCount Do Begin
  If Not SorterCellRect(I, X1, Y1, X2, Y2) Then Continue;
  If (Y2 < Top) Or (Y1 > Bottom) Then Continue;
  DrawSlideThumbAt(I, X1, Y1, X2, Y2, I = SorterSel);
 End;
 { En-tete titre }
 SetColor(CLR_BLACK);
 OutTextXY(Left + 8, Top + 2,
   'Trieuse de diapositives - ' + IntToStr(Pres.SldCount) + ' diapositive(s)');
End;

{ ---------- MODE PLAN (VIEW_OUTLINE) ---------- }

Const
 OUTLINE_LINE_H = 12;

Type
 TOutlineLines = Array[0..63] Of String;
 TOutlineLevs  = Array[0..63] Of Byte;
   { 255 = titre, 0..7 = niveau de puce/indentation }

Procedure CollectSlideOutline(S: PSlide; Var Lines: TOutlineLines;
                              Var Levels: TOutlineLevs; Var Count: Integer);
Var I, J: Integer; Sh: PShape;
Begin
 If S = Nil Then Exit;
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I];
  If (Sh <> Nil) And (Sh^.ShType = SHP_TITLE) Then Begin
   If Count >= 64 Then Exit;
   Lines[Count]  := Sh^.Text[1];
   Levels[Count] := 255;
   Inc(Count); Break;
  End;
 End;
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I];
  If Sh = Nil Then Continue;
  If Sh^.ShType In [SHP_CONTENT, SHP_SUBTITLE, SHP_TEXT] Then
   For J := 1 To Sh^.TxtCount Do Begin
    If Count >= 64 Then Exit;
    Lines[Count]  := Sh^.Text[J];
    Levels[Count] := Sh^.Indent[J];
    Inc(Count);
   End;
 End;
End;

Procedure DrawOutlineView;
Var Top, Bottom, Left, Right, Y, I, J, Cnt: Integer;
    Lines: TOutlineLines; Levels: TOutlineLevs;
    LineY, Indent: Integer;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WHITE);
 SetColor(CLR_DGRAY); Rectangle(Left + 4, Top + 4, Right - 4, Bottom - 4);
 Y := Top + 10 - OutlineScroll;
 For I := 1 To Pres.SldCount Do Begin
  LineY := Y;
  If (LineY >= Top) And (LineY < Bottom) Then Begin
   If I = OutlineSel Then Begin
    FillBox(Left + 6, LineY - 1, Right - 6, LineY + 12, CLR_PANEL_SEL);
    SetColor(CLR_WHITE);
   End Else
    SetColor(CLR_BLUE);
   OutTextXY(Left + 12, LineY + 1,
     IntToStr(I) + '. ' + Pres.Slides[I]^.Name);
  End;
  Y := Y + OUTLINE_LINE_H + 2;
  Cnt := 0;
  CollectSlideOutline(Pres.Slides[I], Lines, Levels, Cnt);
  For J := 0 To Cnt - 1 Do Begin
   LineY := Y;
   If (LineY + OUTLINE_LINE_H >= Top) And (LineY < Bottom) Then Begin
    If Levels[J] = 255 Then Begin
     SetColor(CLR_BLACK);
     OutTextXY(Left + 24, LineY, Lines[J]);
    End Else Begin
     Indent := Levels[J]; If Indent > 6 Then Indent := 6;
     SetColor(CLR_BLACK);
     OutTextXY(Left + 24 + (Indent + 1) * 12, LineY,
       #250 + ' ' + Lines[J]);
    End;
   End;
   Y := Y + OUTLINE_LINE_H;
   If Y > Bottom Then Break;
  End;
  Y := Y + 6;
  If Y > Bottom Then Break;
 End;
End;

Function OutlineSlideAtY(My: LongInt): Integer;
Var Top, Y, I, Cnt, Block: Integer;
    Lines: TOutlineLines; Levels: TOutlineLevs;
Begin
 OutlineSlideAtY := 0;
 Top := MENU_H + TOOL_H + RULER_H;
 Y := Top + 10 - OutlineScroll;
 For I := 1 To Pres.SldCount Do Begin
  Cnt := 0;
  CollectSlideOutline(Pres.Slides[I], Lines, Levels, Cnt);
  Block := OUTLINE_LINE_H + 2 + Cnt * OUTLINE_LINE_H + 6;
  If (My >= Y) And (My < Y + Block) Then Begin
   OutlineSlideAtY := I; Exit;
  End;
  Y := Y + Block;
 End;
End;

{ ---------- PAGE DE COMMENTAIRES (VIEW_NOTES) ---------- }

Procedure DrawNotesView;
Var Top, Bottom, Left, Right, MidY, I: Integer; S: PSlide;
    PrevX1, PrevY1, PrevX2, PrevY2: Integer;
    Notes: String; LineW, Pos, Cur: Integer; Word, Line: String;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WORK_BG);
 MidY := Top + (Bottom - Top) Div 2;
 { Apercu de slide en haut }
 PrevX1 := Left + 80; PrevX2 := Right - 80;
 PrevY1 := Top + 10;  PrevY2 := MidY - 10;
 If (CurSlide >= 1) And (CurSlide <= Pres.SldCount) Then Begin
  S := Pres.Slides[CurSlide];
  FillBox(PrevX1 + 3, PrevY1 + 3, PrevX2 + 3, PrevY2 + 3, CLR_BLACK);
  FillBox(PrevX1, PrevY1, PrevX2, PrevY2, S^.Background);
  SetColor(CLR_SLIDE_BORD); Rectangle(PrevX1, PrevY1, PrevX2, PrevY2);
  DrawSlideThumbAt(CurSlide, PrevX1, PrevY1, PrevX2, PrevY2, False);
 End Else Begin
  SetColor(CLR_DGRAY);
  OutTextXY(PrevX1 + 8, PrevY1 + 8, '(Aucune diapositive)');
 End;
 { Cadre notes en bas }
 FillBox(Left + 20, MidY + 4, Right - 20, Bottom - 8, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(Left + 20, MidY + 4, Right - 20, Bottom - 8);
 SetColor(CLR_BLACK);
 OutTextXY(Left + 24, MidY + 8, 'Notes du presentateur :');
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Notes := Pres.Slides[CurSlide]^.Notes;
 If Notes = '' Then Begin
  SetColor(CLR_DGRAY);
  OutTextXY(Left + 28, MidY + 28,
    '(Double-cliquez ou appuyez sur Entree pour modifier...)');
  Exit;
 End;
 { Wrap simple par mot }
 LineW := Right - 20 - (Left + 28);
 Cur   := MidY + 28;
 Line  := '';
 Pos   := 1;
 SetColor(CLR_BLACK);
 While Pos <= Length(Notes) Do Begin
  Word := '';
  While (Pos <= Length(Notes)) And (Notes[Pos] <> ' ') Do Begin
   Word := Word + Notes[Pos]; Inc(Pos);
  End;
  If TextWidth(Line + Word) > LineW Then Begin
   OutTextXY(Left + 28, Cur, Line);
   Cur := Cur + 11;
   If Cur > Bottom - 16 Then Exit;
   Line := Word;
  End Else
   If Line = '' Then Line := Word Else Line := Line + ' ' + Word;
  If Pos <= Length(Notes) Then Inc(Pos); { saute espace }
 End;
 If Line <> '' Then OutTextXY(Left + 28, Cur, Line);
 I := 0; { evite warning }
End;

Procedure DrawNormalView;
Var I, Top, Bottom, Left, Right: Integer; S: PSlide;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WORK_BG);
 ComputeLayout;
 FillBox(SlideX1 + 4, SlideY1 + 4, SlideX2 + 4, SlideY2 + 4, CLR_BLACK);
 If (CurSlide >= 1) And (CurSlide <= Pres.SldCount) Then
  S := Pres.Slides[CurSlide]
 Else S := Nil;
 If S <> Nil Then Begin
  FillBox(SlideX1, SlideY1, SlideX2, SlideY2, S^.Background);
  SetColor(CLR_SLIDE_BORD); Rectangle(SlideX1, SlideY1, SlideX2, SlideY2);
  For I := 1 To S^.ShCount Do DrawShape(S^.Shapes[I]);
  If (CurShape >= 1) And (CurShape <= S^.ShCount) Then
   DrawSelectionHandles(S^.Shapes[CurShape]);
  DrawMasterOverlay(CurSlide, SlideX1, SlideY1, SlideX2, SlideY2);
 End
 Else Begin
  FillBox(SlideX1, SlideY1, SlideX2, SlideY2, CLR_WHITE);
  SetColor(CLR_DGRAY); Rectangle(SlideX1, SlideY1, SlideX2, SlideY2);
  SetColor(CLR_DGRAY);
  OutTextXY(SlideX1 + 20, SlideY1 + 20, '(Aucune diapositive)');
 End;
End;

Procedure DrawMainArea;
Begin
 HideMouse;
 Case CurView Of
  VIEW_OUTLINE: DrawOutlineView;
  VIEW_SORTER:  DrawSorterView;
  VIEW_NOTES:   DrawNotesView;
 Else
  DrawNormalView;
 End;
 ShowMouse;
End;

{ ====================================================================== }
{                       BARRE D'ETAT                                     }
{ ====================================================================== }

Procedure DrawStatusBar;
Var Y, X: Integer; S: String;
Begin
 HideMouse;
 Y := SCREEN_H - STATUS_H;
 FillBox(0, Y, SCREEN_W - 1, SCREEN_H - 1, CLR_STATUS_BG);
 HLine(0, SCREEN_W - 1, Y, CLR_WIN_HI);
 SetColor(CLR_STATUS_FG);
 OutTextXY(4, Y + 4, StatusMsg);
 { Bloc droit : "Diapositive X sur Y" et nom du theme/zoom }
 X := SCREEN_W - 320;
 SetColor(CLR_DGRAY); VLine(X - 2, Y + 2, SCREEN_H - 3, CLR_DGRAY);
 SetColor(CLR_BLACK);
 If Pres.SldCount > 0 Then
  S := 'Diapositive ' + IntToStr(CurSlide) + ' sur ' + IntToStr(Pres.SldCount)
 Else
  S := 'Aucune diapositive';
 OutTextXY(X + 4, Y + 4, S);
 X := SCREEN_W - 160;
 VLine(X - 2, Y + 2, SCREEN_H - 3, CLR_DGRAY);
 OutTextXY(X + 4, Y + 4, 'Theme : ' + Pres.Themes[Pres.ThemeIdx].Name);
 X := SCREEN_W - 60;
 VLine(X - 2, Y + 2, SCREEN_H - 3, CLR_DGRAY);
 OutTextXY(X + 4, Y + 4, IntToStr(SlideScale) + '%');
 ShowMouse;
End;

{ ====================================================================== }
{                       REDRAW                                           }
{ ====================================================================== }

Procedure Redraw;
Begin
 If NeedFullRedraw Then Begin
  HideMouse;
  FillBox(0, 0, SCREEN_W - 1, SCREEN_H - 1, CLR_WORK_BG);
  ShowMouse;
  DrawMenuBar;
  UpdateToolToggles;
  DrawToolBar;
  DrawRuler;
  DrawSlidePanel;
  DrawMainArea;
  DrawStatusBar;
  If MenuOpen <> 0 Then DrawDropDown;
  NeedFullRedraw  := False;
  NeedSlideRedraw := False;
  NeedPanelRedraw := False;
  NeedStatRedraw  := False;
  Exit;
 End;
 If NeedSlideRedraw Then Begin DrawMainArea; NeedSlideRedraw := False; End;
 If NeedPanelRedraw Then Begin DrawSlidePanel; NeedPanelRedraw := False; End;
 If NeedStatRedraw  Then Begin DrawStatusBar;  NeedStatRedraw  := False; End;
End;

{ ====================================================================== }
{                       ACTIONS                                          }
{ ====================================================================== }

Function ConfirmDiscardChanges: Boolean;
Begin
 If Pres.Dirty Then
  ConfirmDiscardChanges := ConfirmYesNo('PowerPnt',
   'Modifications non enregistrees. Continuer ?')
 Else ConfirmDiscardChanges := True;
End;

Procedure ActionQuit;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 Quitting := True;
End;

Procedure ActionNew;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FreePresentation;
 InitPresentation;
 SeedSamplePresentation;
 StatusMsg := 'Nouvelle presentation.';
 NeedFullRedraw := True;
End;

Procedure ActionNewSlide;
Var Pos: Integer;
Begin
 If CurSlide < 1 Then Pos := AddSlideAt(1)
 Else Pos := AddSlideAt(CurSlide + 1);
 If Pos > 0 Then Begin
  ApplyLayout(Pres.Slides[Pos], LAY_TITLE_CONTENT);
  CurSlide := Pos;
  CurShape := 0;
  StatusMsg := 'Diapositive ' + IntToStr(Pos) + ' ajoutee.';
  NeedFullRedraw := True;
 End
 Else MessageBox('PowerPnt', 'Nombre maximum de diapositives atteint.');
End;

Procedure ActionDupSlide;
Var Pos, I: Integer; Src, Dst: PSlide; SH: PShape;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Pos := AddSlideAt(CurSlide + 1);
 If Pos = 0 Then Begin
  MessageBox('PowerPnt', 'Nombre maximum de diapositives atteint.'); Exit;
 End;
 Src := Pres.Slides[CurSlide];
 Dst := Pres.Slides[Pos];
 Dst^.Title      := Src^.Title;
 Dst^.Layout     := Src^.Layout;
 Dst^.Background := Src^.Background;
 Dst^.Theme      := Src^.Theme;
 Dst^.Transition := Src^.Transition;
 For I := 1 To Src^.ShCount Do Begin
  SH := NewShape;
  SH^ := Src^.Shapes[I]^;
  AddShapeToSlide(Dst, SH);
 End;
 CurSlide := Pos;
 CurShape := 0;
 StatusMsg := 'Diapositive dupliquee.';
 NeedFullRedraw := True;
End;

Procedure ActionDelSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 If Not ConfirmYesNo('PowerPnt',
  'Supprimer la diapositive ' + IntToStr(CurSlide) + ' ?') Then Exit;
 RemoveSlide(CurSlide);
 CurShape := 0;
 StatusMsg := 'Diapositive supprimee.';
 NeedFullRedraw := True;
End;

Procedure ActionNextSlide;
Begin
 If CurSlide < Pres.SldCount Then Begin
  Inc(CurSlide); CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionPrevSlide;
Begin
 If CurSlide > 1 Then Begin
  Dec(CurSlide); CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionFirstSlide;
Begin
 If Pres.SldCount > 0 Then Begin
  CurSlide := 1; CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionLastSlide;
Begin
 If Pres.SldCount > 0 Then Begin
  CurSlide := Pres.SldCount; CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionAbout;
Var X1, Y1, X2, Y2: Integer; K: Char;
Begin
 X1 := 130; Y1 := 110; X2 := 510; Y2 := 370;
 DlgFrame(X1, Y1, X2, Y2, 'A propos de Office-0 PowerPnt');
 HideMouse;
 SetColor(CLR_BLACK);
 SetTextStyle(DefaultFont, HorizDir, 2);
 OutTextXY(X1 + 20, Y1 + 30, 'Office-0  PowerPnt');
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(CLR_BLUE);
 OutTextXY(X1 + 20, Y1 + 60, 'Clone de Microsoft PowerPoint');
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 20, Y1 + 80, 'Version 0.10 - 2026 (Phase 1)');
 OutTextXY(X1 + 20, Y1 + 96, '(c) Sylvain Maltais  www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 20, Y1 + 120,'Phase 1 : charpente UI + modele presentation');
 OutTextXY(X1 + 20, Y1 + 136,'Formats : .PPT, .PPTX (a venir)');
 OutTextXY(X1 + 20, Y1 + 152,'Free Pascal 3.2 (-Mtp) - VGA 640 x 480 x 16');
 OutTextXY(X1 + 20, Y1 + 176,'F5 Diaporama  F11 Plein ecran');
 OutTextXY(X1 + 20, Y1 + 192,'Ctrl+M Nouvelle slide  Ctrl+S Enregistrer');
 DlgBtn(X1 + 160, Y2 - 32, X1 + 220, Y2 - 12, 'OK', False, True);
 ShowMouse;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then ReadKey;
   If (K = #13) Or (K = #27) Or (K = ' ') Then Begin
    NeedFullRedraw := True; Exit;
   End;
  End;
  If LeftPressed Then
   If InRect(Mouse.X, Mouse.Y, X1 + 160, Y2 - 32, X1 + 220, Y2 - 12) Then Begin
    NeedFullRedraw := True; Exit;
   End;
 Until False;
End;

Procedure SetTool(T: Integer);
Begin
 CurTool := T;
 Case T Of
  TOOL_SELECT:   StatusMsg := 'Outil : Selection';
  TOOL_TEXT:     StatusMsg := 'Outil : Zone de texte';
  TOOL_RECT:     StatusMsg := 'Outil : Rectangle';
  TOOL_ELLIPSE:  StatusMsg := 'Outil : Ellipse';
  TOOL_LINE:     StatusMsg := 'Outil : Ligne';
  TOOL_ARROW:    StatusMsg := 'Outil : Fleche';
 Else StatusMsg := 'Outil change.';
 End;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{           PHASE 4 - DIALOGUES REUTILISABLES + GESTION SLIDES           }
{ ====================================================================== }

{ Saisie de texte modal. Retourne True si OK valide, False si Annuler. }
Function InputTextDlg(Const Title, Prompt: String;
                      Var Value: String; MaxLen: Integer): Boolean;
Var X1, Y1, X2, Y2, Ex1, Ey1, Ex2, Ey2: Integer;
    Bx1, By1, Bx2, By2, Cx1, Cy1, Cx2, Cy2: Integer;
    K, K2: Char; Caret: Integer; S: String;
Begin
 InputTextDlg := False;
 X1 := 130; Y1 := 170; X2 := 510; Y2 := 290;
 Ex1 := X1 + 20; Ey1 := Y1 + 56; Ex2 := X2 - 20; Ey2 := Ey1 + 22;
 Bx1 := X1 + 80;  By1 := Y2 - 32; Bx2 := Bx1 + 80; By2 := Y2 - 12;
 Cx1 := X2 - 160; Cy1 := By1;     Cx2 := Cx1 + 80; Cy2 := By2;
 DlgFrame(X1, Y1, X2, Y2, Title);
 HideMouse;
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 20, Y1 + 36, Prompt);
 S := Value;
 Caret := Length(S);
 DlgEdit(Ex1, Ey1, Ex2, Ey2, S, True, Caret);
 DlgBtn(Bx1, By1, Bx2, By2, 'OK',      False, True);
 DlgBtn(Cx1, Cy1, Cx2, Cy2, 'Annuler', False, False);
 ShowMouse;
 Repeat
  UpdateMouse;
  HideMouse;
  DlgEdit(Ex1, Ey1, Ex2, Ey2, S, True, Caret);
  ShowMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #75: If Caret > 0 Then Dec(Caret);
     #77: If Caret < Length(S) Then Inc(Caret);
     #71: Caret := 0;
     #79: Caret := Length(S);
     #83: If Caret < Length(S) Then Delete(S, Caret + 1, 1);
    End;
    Continue;
   End;
   Case K Of
    #13: Begin
     Value := S; InputTextDlg := True;
     NeedFullRedraw := True; Exit;
    End;
    #27: Begin NeedFullRedraw := True; Exit; End;
    #8 : If Caret > 0 Then Begin Delete(S, Caret, 1); Dec(Caret); End;
   Else
    If (K >= ' ') And (K <= #126) And (Length(S) < MaxLen) Then Begin
     Insert(K, S, Caret + 1); Inc(Caret);
    End
    Else If (K >= #128) And (Length(S) < MaxLen) Then Begin
     Insert(K, S, Caret + 1); Inc(Caret);
    End;
   End;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, Bx1, By1, Bx2, By2) Then Begin
    Value := S; InputTextDlg := True;
    NeedFullRedraw := True; Exit;
   End;
   If InRect(Mouse.X, Mouse.Y, Cx1, Cy1, Cx2, Cy2) Then Begin
    NeedFullRedraw := True; Exit;
   End;
  End;
  Delay(20);
 Until False;
End;

{ Selection dans une liste deroulante. Items separes par #10. Retourne
  l'index 1..N choisi, ou 0 si annule. }
Function SelectListDlg(Const Title: String; Const Items: String;
                       InitialIdx: Integer): Integer;
Var X1, Y1, X2, Y2, Lx1, Ly1, Lx2, Ly2: Integer;
    Bx1, By1, Bx2, By2, Cx1, Cy1, Cx2, Cy2: Integer;
    K, K2: Char; Sel, Count, I, Top, ItemH, MaxView: Integer;
    Lines: Array[1..32] Of String; S: String;
Begin
 SelectListDlg := 0;
 { Parse }
 Count := 0; S := '';
 For I := 1 To Length(Items) Do Begin
  If Items[I] = #10 Then Begin
   Inc(Count); If Count <= 32 Then Lines[Count] := S; S := '';
  End Else
   S := S + Items[I];
 End;
 If Length(S) > 0 Then Begin Inc(Count); If Count <= 32 Then Lines[Count] := S; End;
 If Count = 0 Then Exit;
 Sel := InitialIdx; If Sel < 1 Then Sel := 1; If Sel > Count Then Sel := Count;
 X1 := 180; Y1 := 130; X2 := 460; Y2 := 360;
 Lx1 := X1 + 12; Ly1 := Y1 + 32; Lx2 := X2 - 12; Ly2 := Y2 - 44;
 Bx1 := X1 + 50;  By1 := Y2 - 32; Bx2 := Bx1 + 70; By2 := Y2 - 12;
 Cx1 := X2 - 120; Cy1 := By1;     Cx2 := Cx1 + 70; Cy2 := By2;
 ItemH := 12;
 MaxView := (Ly2 - Ly1) Div ItemH;
 Top := 1;
 If Sel > Top + MaxView - 1 Then Top := Sel - MaxView + 1;
 DlgFrame(X1, Y1, X2, Y2, Title);
 HideMouse;
 DlgBtn(Bx1, By1, Bx2, By2, 'OK',      False, True);
 DlgBtn(Cx1, Cy1, Cx2, Cy2, 'Annuler', False, False);
 ShowMouse;
 Repeat
  HideMouse;
  FillBox(Lx1, Ly1, Lx2, Ly2, CLR_WHITE);
  SetColor(CLR_WIN_LO); Rectangle(Lx1, Ly1, Lx2, Ly2);
  For I := 0 To MaxView - 1 Do Begin
   If Top + I > Count Then Break;
   If Top + I = Sel Then Begin
    FillBox(Lx1 + 1, Ly1 + 1 + I * ItemH, Lx2 - 1, Ly1 + ItemH + I * ItemH, CLR_BLUE);
    SetColor(CLR_WHITE);
   End Else
    SetColor(CLR_BLACK);
   OutTextXY(Lx1 + 4, Ly1 + 2 + I * ItemH, Lines[Top + I]);
  End;
  ShowMouse;
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #72: If Sel > 1 Then Dec(Sel);
     #80: If Sel < Count Then Inc(Sel);
     #73: Begin Dec(Sel, MaxView); If Sel < 1 Then Sel := 1; End;
     #81: Begin Inc(Sel, MaxView); If Sel > Count Then Sel := Count; End;
     #71: Sel := 1;
     #79: Sel := Count;
    End;
    If Sel < Top Then Top := Sel;
    If Sel > Top + MaxView - 1 Then Top := Sel - MaxView + 1;
    Continue;
   End;
   If K = #13 Then Begin
    SelectListDlg := Sel; NeedFullRedraw := True; Exit;
   End;
   If K = #27 Then Begin NeedFullRedraw := True; Exit; End;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, Bx1, By1, Bx2, By2) Then Begin
    SelectListDlg := Sel; NeedFullRedraw := True; Exit;
   End;
   If InRect(Mouse.X, Mouse.Y, Cx1, Cy1, Cx2, Cy2) Then Begin
    NeedFullRedraw := True; Exit;
   End;
   If InRect(Mouse.X, Mouse.Y, Lx1, Ly1, Lx2, Ly2) Then Begin
    I := (Mouse.Y - Ly1) Div ItemH;
    If (I >= 0) And (Top + I <= Count) Then Begin
     If (Top + I = Sel) And DoubleClicked Then Begin
      SelectListDlg := Sel; NeedFullRedraw := True; Exit;
     End;
     Sel := Top + I;
    End;
   End;
  End;
  Delay(15);
 Until False;
End;

{ ====================================================================== }
{           PHASE 4 - OPERATIONS SUR LES DIAPOSITIVES                    }
{ ====================================================================== }

Procedure ClearSlideShapes(S: PSlide);
Var I: Integer;
Begin
 If S = Nil Then Exit;
 For I := 1 To S^.ShCount Do
  If S^.Shapes[I] <> Nil Then FreeShape(S^.Shapes[I]);
 For I := 1 To MAX_SHAPES Do S^.Shapes[I] := Nil;
 S^.ShCount := 0;
End;

Procedure ActionMoveSlideUp;
Var Tmp: PSlide;
Begin
 If (CurSlide <= 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Tmp := Pres.Slides[CurSlide - 1];
 Pres.Slides[CurSlide - 1] := Pres.Slides[CurSlide];
 Pres.Slides[CurSlide] := Tmp;
 Dec(CurSlide);
 Pres.Dirty := True;
 StatusMsg := 'Diapositive remontee.';
 NeedFullRedraw := True;
End;

Procedure ActionMoveSlideDown;
Var Tmp: PSlide;
Begin
 If (CurSlide < 1) Or (CurSlide >= Pres.SldCount) Then Exit;
 Tmp := Pres.Slides[CurSlide + 1];
 Pres.Slides[CurSlide + 1] := Pres.Slides[CurSlide];
 Pres.Slides[CurSlide] := Tmp;
 Inc(CurSlide);
 Pres.Dirty := True;
 StatusMsg := 'Diapositive descendue.';
 NeedFullRedraw := True;
End;

Procedure ActionApplyLayoutToCurrent(Lay: Byte);
Var S: PSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If Not ConfirmYesNo('Mise en page',
   'Remplacer les elements par les placeholders de la mise en page ?')
 Then Exit;
 ClearSlideShapes(S);
 ApplyLayout(S, Lay);
 CurShape := 0;
 S^.Dirty := True; Pres.Dirty := True;
 StatusMsg := 'Mise en page appliquee : ' + LayoutName(Lay);
 NeedFullRedraw := True;
End;

Procedure ActionChangeLayoutDlg;
Var Idx: Integer; Items: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Items := 'Titre'                + #10 +
          'Titre + contenu'      + #10 +
          'Deux contenus'        + #10 +
          'Comparaison'          + #10 +
          'Titre seul'           + #10 +
          'Vide'                 + #10 +
          'Contenu et legende'   + #10 +
          'En-tete de section';
 Idx := SelectListDlg('Mise en page de la diapositive', Items,
                      Pres.Slides[CurSlide]^.Layout + 1);
 If Idx > 0 Then ActionApplyLayoutToCurrent(Idx - 1);
End;

Procedure ActionChangeBackgroundDlg;
Var Idx: Integer; Items: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
          'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
          'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
          'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
          'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
          'Blanc';
 Idx := SelectListDlg('Arriere-plan de diapositive', Items,
                      Pres.Slides[CurSlide]^.Background + 1);
 If Idx > 0 Then Begin
  Pres.Slides[CurSlide]^.Background := Idx - 1;
  Pres.Slides[CurSlide]^.Dirty := True;
  Pres.Dirty := True;
  StatusMsg := 'Arriere-plan modifie.';
  NeedFullRedraw := True;
 End;
End;

Procedure ApplyThemeToSlide(S: PSlide; T: Integer);
Var I: Integer; Sh: PShape;
Begin
 If (S = Nil) Or (T < 1) Or (T > Pres.ThemeCount) Then Exit;
 S^.Background := Pres.Themes[T].BgColor;
 S^.Theme := T;
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I]; If Sh = Nil Then Continue;
  Case Sh^.ShType Of
   SHP_TITLE:    Sh^.TextColor := Pres.Themes[T].TitleColor;
   SHP_SUBTITLE: Sh^.TextColor := Pres.Themes[T].TitleColor;
   SHP_CONTENT,
   SHP_TEXT:     Sh^.TextColor := Pres.Themes[T].TextColor;
  End;
 End;
 S^.Dirty := True;
End;

Procedure ApplyThemeToAll(T: Integer);
Var I: Integer;
Begin
 If (T < 1) Or (T > Pres.ThemeCount) Then Exit;
 Pres.MasterBg     := Pres.Themes[T].BgColor;
 Pres.MasterTitleC := Pres.Themes[T].TitleColor;
 Pres.MasterTextC  := Pres.Themes[T].TextColor;
 For I := 1 To Pres.SldCount Do ApplyThemeToSlide(Pres.Slides[I], T);
 Pres.Dirty := True;
End;

Procedure ActionChangeThemeDlg;
Var Idx, I: Integer; Items: String;
Begin
 Items := '';
 For I := 1 To Pres.ThemeCount Do Begin
  If I > 1 Then Items := Items + #10;
  Items := Items + Pres.Themes[I].Name;
 End;
 Idx := SelectListDlg('Theme de la presentation', Items, Pres.ThemeIdx);
 If Idx > 0 Then Begin
  Pres.ThemeIdx := Idx;
  If ConfirmYesNo('Appliquer le theme',
                  'Appliquer le theme a toutes les diapositives ?') Then
   ApplyThemeToAll(Idx);
  Pres.Dirty := True;
  StatusMsg := 'Theme : ' + Pres.Themes[Idx].Name;
  NeedFullRedraw := True;
 End;
End;

Procedure ActionRenameSlide;
Var S: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide]^.Name;
 If InputTextDlg('Nom de la diapositive',
                 'Nom interne de la diapositive :', S, 30) Then Begin
  Pres.Slides[CurSlide]^.Name := S;
  Pres.Slides[CurSlide]^.Dirty := True;
  Pres.Dirty := True;
  StatusMsg := 'Diapositive renommee.';
  NeedFullRedraw := True;
 End;
End;

Procedure ActionEditNotes;
Var S: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide]^.Notes;
 If InputTextDlg('Notes du presentateur',
                 'Notes pour cette diapositive :', S, 200) Then Begin
  Pres.Slides[CurSlide]^.Notes := S;
  Pres.Slides[CurSlide]^.Dirty := True;
  Pres.Dirty := True;
  StatusMsg := 'Notes enregistrees.';
  NeedFullRedraw := True;
 End;
End;

Procedure ActionToggleHideSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Pres.Slides[CurSlide]^.Hidden := Not Pres.Slides[CurSlide]^.Hidden;
 If Pres.Slides[CurSlide]^.Hidden Then
  StatusMsg := 'Diapositive masquee.'
 Else
  StatusMsg := 'Diapositive visible.';
 Pres.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure ActionInsertFromLayout;
Var Idx, Pos: Integer; Items: String;
Begin
 Items := 'Titre'                + #10 +
          'Titre + contenu'      + #10 +
          'Deux contenus'        + #10 +
          'Comparaison'          + #10 +
          'Titre seul'           + #10 +
          'Vide'                 + #10 +
          'Contenu et legende'   + #10 +
          'En-tete de section';
 Idx := SelectListDlg('Nouvelle diapositive : mise en page', Items, 2);
 If Idx <= 0 Then Exit;
 If CurSlide < 1 Then Pos := AddSlideAt(1)
 Else Pos := AddSlideAt(CurSlide + 1);
 If Pos > 0 Then Begin
  ApplyLayout(Pres.Slides[Pos], Idx - 1);
  CurSlide := Pos; CurShape := 0;
  StatusMsg := 'Diapositive inseree.';
  NeedFullRedraw := True;
 End;
End;

{ ====================================================================== }
{           PHASE 6 - EN-TETE / PIED / MASQUE / THEMES                   }
{ ====================================================================== }

Procedure ActionHeaderFooter;
Var S: String;
Begin
 Pres.ShowHeader := ConfirmYesNo('En-tete et pied de page',
                                 'Afficher un en-tete ?');
 If Pres.ShowHeader Then Begin
  S := Pres.HeaderText;
  If InputTextDlg('En-tete', 'Texte de l''en-tete :', S, 60) Then
   Pres.HeaderText := S;
 End;
 Pres.ShowFooter := ConfirmYesNo('En-tete et pied de page',
                                 'Afficher un pied de page ?');
 If Pres.ShowFooter Then Begin
  S := Pres.FooterText;
  If InputTextDlg('Pied de page', 'Texte du pied de page :', S, 60) Then
   Pres.FooterText := S;
 End;
 Pres.ShowDate := ConfirmYesNo('En-tete et pied de page',
                               'Afficher la date ?');
 If Pres.ShowDate Then Begin
  S := Pres.DateText;
  If InputTextDlg('Date', 'Texte de la date :', S, 20) Then
   Pres.DateText := S;
 End;
 Pres.ShowSlideNum := ConfirmYesNo('En-tete et pied de page',
                                   'Afficher le numero de diapositive ?');
 Pres.Dirty := True;
 StatusMsg := 'En-tete / pied / date / numero : mis a jour.';
 NeedFullRedraw := True;
End;

Procedure ActionMasterEdit;
Var Idx: Integer; Items: String;
Begin
 Items := 'Modifier la couleur de fond par defaut'    + #10 +
          'Modifier la couleur de titre par defaut'   + #10 +
          'Modifier la couleur de texte par defaut'   + #10 +
          'Appliquer le masque aux nouvelles slides'  + #10 +
          'Reappliquer le masque a toutes les slides';
 Idx := SelectListDlg('Masque des diapositives', Items, 1);
 If Idx <= 0 Then Exit;
 Case Idx Of
  1: Begin
   Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
            'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
            'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
            'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
            'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
            'Blanc';
   Idx := SelectListDlg('Couleur de fond du masque', Items, Pres.MasterBg + 1);
   If Idx > 0 Then Pres.MasterBg := Idx - 1;
  End;
  2: Begin
   Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
            'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
            'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
            'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
            'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
            'Blanc';
   Idx := SelectListDlg('Couleur de titre du masque', Items, Pres.MasterTitleC + 1);
   If Idx > 0 Then Pres.MasterTitleC := Idx - 1;
  End;
  3: Begin
   Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
            'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
            'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
            'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
            'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
            'Blanc';
   Idx := SelectListDlg('Couleur de texte du masque', Items, Pres.MasterTextC + 1);
   If Idx > 0 Then Pres.MasterTextC := Idx - 1;
  End;
  4: Begin
   StatusMsg := 'Le masque sera applique aux prochaines slides creees.';
  End;
  5: ApplyThemeToAll(Pres.ThemeIdx);
 End;
 Pres.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure ActionBackgroundAll;
Var Idx, I: Integer; Items: String;
Begin
 Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
          'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
          'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
          'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
          'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
          'Blanc';
 Idx := SelectListDlg('Arriere-plan global', Items, Pres.MasterBg + 1);
 If Idx <= 0 Then Exit;
 Pres.MasterBg := Idx - 1;
 For I := 1 To Pres.SldCount Do
  If Pres.Slides[I] <> Nil Then Pres.Slides[I]^.Background := Idx - 1;
 Pres.Dirty := True;
 StatusMsg := 'Arriere-plan applique a toutes les diapositives.';
 NeedFullRedraw := True;
End;

{ Trace l'en-tete/pied/date/numero a l'interieur d'une slide rendue. }
Procedure DrawMasterOverlay(SlideIdx: Integer; X1, Y1, X2, Y2: Integer);
Var FgC, BgC: Byte; W: Integer; S: String;
Begin
 BgC := Pres.MasterBg;
 If (SlideIdx >= 1) And (SlideIdx <= Pres.SldCount) Then
  BgC := Pres.Slides[SlideIdx]^.Background;
 { Choix de la couleur du texte selon le fond }
 If (BgC = CLR_BLACK) Or (BgC = CLR_BLUE) Or
    (BgC = CLR_DGRAY) Or (BgC = CLR_BROWN) Then
  FgC := CLR_WHITE
 Else
  FgC := CLR_BLACK;
 SetColor(FgC);
 If Pres.ShowHeader And (Pres.HeaderText <> '') Then Begin
  S := Pres.HeaderText;
  W := TextWidth(S);
  OutTextXY(X1 + ((X2 - X1) - W) Div 2, Y1 + 4, S);
 End;
 If Pres.ShowDate And (Pres.DateText <> '') Then
  OutTextXY(X1 + 8, Y2 - 12, Pres.DateText);
 If Pres.ShowFooter And (Pres.FooterText <> '') Then Begin
  S := Pres.FooterText;
  W := TextWidth(S);
  OutTextXY(X1 + ((X2 - X1) - W) Div 2, Y2 - 12, S);
 End;
 If Pres.ShowSlideNum And (SlideIdx > 0) Then Begin
  S := IntToStr(SlideIdx);
  W := TextWidth(S);
  OutTextXY(X2 - 8 - W, Y2 - 12, S);
 End;
End;

{ ====================================================================== }
{                  PHASE 7 : DIAPORAMA + TRANSITIONS                     }
{ ====================================================================== }

{ ----- Phase 9 : helpers d'animations ------------------------------- }

{ Plus grande valeur AnimOrder utilisee par les formes ayant une entree
  animee. Retourne 0 si aucune animation : il y a alors une seule etape
  (tout visible). }
Function MaxAnimOrder(S: PSlide): Integer;
Var I, M: Integer;
Begin
 M := 0;
 If S <> Nil Then
  For I := 1 To S^.ShCount Do
   If (S^.Shapes[I] <> Nil) And
      (S^.Shapes[I]^.AnimEntry <> ANIM_NONE) And
      (S^.Shapes[I]^.AnimOrder > M) Then
    M := S^.Shapes[I]^.AnimOrder;
 MaxAnimOrder := M;
End;

{ Une forme est-elle visible a l'etape d'animation Step ?
  - AnimEntry = ANIM_NONE : toujours visible (sauf Hidden).
  - sinon : visible quand AnimOrder <= Step. }
Function ShapeVisibleAt(P: PShape; Step: Integer): Boolean;
Begin
 If P = Nil Then Begin ShapeVisibleAt := False; Exit; End;
 If P^.Hidden Then Begin ShapeVisibleAt := False; Exit; End;
 If P^.AnimEntry = ANIM_NONE Then ShapeVisibleAt := True
 Else ShapeVisibleAt := P^.AnimOrder <= Step;
End;

{ Rend la diapositive Idx en plein ecran en montrant les formes visibles
  a l'etape d'animation Step (0 = etat initial). }
Procedure RenderSlideAtStep(Idx, Step: Integer);
Var S: PSlide; I, MaxX, MaxY: Integer;
    SX1, SY1, SX2, SY2: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx];
 If S = Nil Then Exit;
 MaxX := GetMaxX; MaxY := GetMaxY;
 SX1 := SlideX1; SY1 := SlideY1; SX2 := SlideX2; SY2 := SlideY2;
 SlideX1 := 0; SlideY1 := 0; SlideX2 := MaxX; SlideY2 := MaxY;
 SetFillStyle(1, S^.Background);
 Bar(0, 0, MaxX, MaxY);
 For I := 1 To S^.ShCount Do
  If ShapeVisibleAt(S^.Shapes[I], Step) Then DrawShape(S^.Shapes[I]);
 DrawMasterOverlay(Idx, 0, 0, MaxX, MaxY);
 SlideX1 := SX1; SlideY1 := SY1; SlideX2 := SX2; SlideY2 := SY2;
End;

{ Rendu complet (toutes animations terminees) : utilise pour transitions
  et navigation arriere. }
Procedure RenderSlideFullscreen(Idx: Integer);
Begin
 If (Idx >= 1) And (Idx <= Pres.SldCount) Then
  RenderSlideAtStep(Idx, MaxAnimOrder(Pres.Slides[Idx]));
End;

Procedure TransDelay(Speed: Byte);
Begin
 Case Speed Of
  0: Delay(70);
  1: Delay(35);
  2: Delay(15);
 Else Delay(35);
 End;
End;

{ Recouvre en CLR_BLACK la region NON ENCORE revelee a l'etape K (0..STEPS).
  K=0 : tout est cache. K=STEPS : rien n'est cache. }
Procedure DrawTransitionCover(Trans: Byte; K, Steps: Integer);
Var MaxX, MaxY, Cx, Cy, Half, I, J, Bh, H, Cw, Ch, Gap: Integer;
Begin
 MaxX := GetMaxX; MaxY := GetMaxY;
 Cx := MaxX Div 2; Cy := MaxY Div 2;
 SetFillStyle(1, CLR_BLACK);
 SetColor(CLR_BLACK);
 Case Trans Of
  TRANS_WIPE_R, TRANS_PUSH:
   Bar(K * MaxX Div Steps, 0, MaxX, MaxY);
  TRANS_WIPE_L:
   Bar(0, 0, MaxX - K * MaxX Div Steps, MaxY);
  TRANS_WIPE_D:
   Bar(0, K * MaxY Div Steps, MaxX, MaxY);
  TRANS_WIPE_U:
   Bar(0, 0, MaxX, MaxY - K * MaxY Div Steps);
  TRANS_SPLIT: Begin
   Half := (Steps - K) * MaxX Div (2 * Steps);
   If Half > 0 Then Bar(Cx - Half, 0, Cx + Half, MaxY);
  End;
  TRANS_BLINDS: Begin
   Bh := MaxY Div 8;
   H  := (Steps - K) * Bh Div Steps;
   If H > 0 Then
    For I := 0 To 7 Do Bar(0, I * Bh, MaxX, I * Bh + H);
  End;
  TRANS_CHECKER: Begin
   Cw := 32; Ch := 24;
   For I := 0 To (MaxX Div Cw) Do
    For J := 0 To (MaxY Div Ch) Do
     If ((I + J) Mod 2) = 0 Then Begin
      If I + J + 1 > K Then
       Bar(I * Cw, J * Ch, I * Cw + Cw - 1, J * Ch + Ch - 1);
     End Else Begin
      If I + J + 2 > K Then
       Bar(I * Cw, J * Ch, I * Cw + Cw - 1, J * Ch + Ch - 1);
     End;
  End;
  TRANS_DISSOLVE: Begin
   { Pavage 16x16, ordre pseudo-aleatoire base sur Steps }
   For I := 0 To (MaxX Div 16) Do
    For J := 0 To (MaxY Div 16) Do
     If (((I * 7 + J * 13 + I*J) Mod (Steps + 1)) >= K) Then
      Bar(I * 16, J * 16, I * 16 + 15, J * 16 + 15);
  End;
  TRANS_FADE: Begin
   { Pattern de pixels noirs qui se rarefie a chaque etape }
   Gap := K + 1;
   If Gap > 0 Then
    For I := 0 To MaxX Div Gap Do
     For J := 0 To MaxY Div Gap Do
      PutPixel(I * Gap, J * Gap, CLR_BLACK);
  End;
 End;
End;

{ Anime la transition vers la diapositive NewIdx. Le contenu actuel de
  l'ecran est considere comme l'ancienne diapositive. }
Procedure RunTransition(NewIdx: Integer; Trans, Speed: Byte);
Const STEPS = 10;
Var K, MaxX, MaxY: Integer;
Begin
 MaxX := GetMaxX; MaxY := GetMaxY;
 If Trans = TRANS_NONE Then Begin
  RenderSlideFullscreen(NewIdx);
  Exit;
 End;
 For K := 0 To STEPS Do Begin
  RenderSlideFullscreen(NewIdx);
  DrawTransitionCover(Trans, K, STEPS);
  TransDelay(Speed);
  If KeyPressed Then Exit;
 End;
 RenderSlideFullscreen(NewIdx);
End;

{ Couvre la forme P avec un patron de pixels noirs decroissant.
  K = Steps : couverture maximale ; K = 0 : aucune couverture. }
Procedure DrawShapeDitherCover(P: PShape; K, Steps: Integer);
Var X1, Y1, X2, Y2, IX, IY, Gap: Integer;
Begin
 If (P = Nil) Or (K <= 0) Or (Steps <= 0) Then Exit;
 X1 := LogX(P^.X);
 Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W);
 Y2 := LogY(P^.Y + P^.H);
 Gap := Steps - K + 1;
 If Gap < 1 Then Gap := 1;
 IY := Y1;
 While IY <= Y2 Do Begin
  IX := X1;
  While IX <= X2 Do Begin
   PutPixel(IX, IY, CLR_BLACK);
   Inc(IX, Gap);
  End;
  Inc(IY, Gap);
 End;
End;

{ Joue l'animation d'entree d'une forme. Le rendu de la slide a l'etape
  AtStep (forme finale visible) est utilise pour chaque image
  intermediaire. Modifie temporairement les coordonnees de la forme. }
Procedure PlayShapeEntry(Idx, AtStep, ShapeIdx: Integer);
Const STEPS = 8;
Var S: PSlide; P: PShape; K: Integer;
    SaveX, SaveY, SaveW, SaveH: Integer;
    Dx, Dy: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx]; If S = Nil Then Exit;
 If (ShapeIdx < 1) Or (ShapeIdx > S^.ShCount) Then Exit;
 P := S^.Shapes[ShapeIdx];
 If (P = Nil) Or (P^.AnimEntry = ANIM_NONE) Then Exit;
 SaveX := P^.X; SaveY := P^.Y; SaveW := P^.W; SaveH := P^.H;
 Dx := 0; Dy := 0;
 Case P^.AnimEntry Of
  ANIM_APPEAR:
   RenderSlideAtStep(Idx, AtStep);
  ANIM_FADE: Begin
   For K := STEPS Downto 0 Do Begin
    RenderSlideAtStep(Idx, AtStep);
    DrawShapeDitherCover(P, K, STEPS);
    Delay(35);
    If KeyPressed Then Break;
   End;
   RenderSlideAtStep(Idx, AtStep);
  End;
  ANIM_SLIDE_L, ANIM_SLIDE_R, ANIM_SLIDE_U, ANIM_SLIDE_D: Begin
   Case P^.AnimEntry Of
    ANIM_SLIDE_L: Begin Dx := -1100; Dy := 0; End;
    ANIM_SLIDE_R: Begin Dx :=  1100; Dy := 0; End;
    ANIM_SLIDE_U: Begin Dx := 0; Dy := -850; End;
    ANIM_SLIDE_D: Begin Dx := 0; Dy :=  850; End;
   End;
   For K := STEPS Downto 0 Do Begin
    P^.X := SaveX + (LongInt(Dx) * K) Div STEPS;
    P^.Y := SaveY + (LongInt(Dy) * K) Div STEPS;
    RenderSlideAtStep(Idx, AtStep);
    Delay(30);
    If KeyPressed Then Break;
   End;
   P^.X := SaveX; P^.Y := SaveY;
   RenderSlideAtStep(Idx, AtStep);
  End;
  ANIM_ZOOM: Begin
   For K := 1 To STEPS Do Begin
    P^.W := (LongInt(SaveW) * K) Div STEPS;
    P^.H := (LongInt(SaveH) * K) Div STEPS;
    If P^.W < 2 Then P^.W := 2;
    If P^.H < 2 Then P^.H := 2;
    P^.X := SaveX + (SaveW - P^.W) Div 2;
    P^.Y := SaveY + (SaveH - P^.H) Div 2;
    RenderSlideAtStep(Idx, AtStep);
    Delay(35);
    If KeyPressed Then Break;
   End;
   P^.X := SaveX; P^.Y := SaveY; P^.W := SaveW; P^.H := SaveH;
   RenderSlideAtStep(Idx, AtStep);
  End;
  ANIM_SPIN: Begin
   { Rotation non supportee : clignotement avant apparition. }
   For K := 1 To 4 Do Begin
    If AtStep > 0 Then RenderSlideAtStep(Idx, AtStep - 1)
                  Else RenderSlideAtStep(Idx, 0);
    Delay(50);
    RenderSlideAtStep(Idx, AtStep);
    Delay(50);
    If KeyPressed Then Break;
   End;
   RenderSlideAtStep(Idx, AtStep);
  End;
 Else
  RenderSlideAtStep(Idx, AtStep);
 End;
End;

{ Revele toutes les formes ayant AnimOrder = TargetStep, l'une apres
  l'autre dans leur ordre de declaration. Masque temporairement les
  formes non encore animees de cette etape pour qu'elles n'apparaissent
  pas avant leur tour. }
Procedure RevealAnimStep(Idx, TargetStep: Integer);
Var S: PSlide; I, J: Integer; P: PShape;
    OrigOrder: Array[1..MAX_SHAPES] Of Byte;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx]; If S = Nil Then Exit;
 For J := 1 To S^.ShCount Do
  If S^.Shapes[J] <> Nil Then OrigOrder[J] := S^.Shapes[J]^.AnimOrder
                         Else OrigOrder[J] := 0;
 For I := 1 To S^.ShCount Do Begin
  P := S^.Shapes[I];
  If (P <> Nil) And (P^.AnimEntry <> ANIM_NONE) And
     (OrigOrder[I] = TargetStep) And (Not P^.Hidden) Then Begin
   { Masque les formes suivantes de la meme etape non encore animees. }
   For J := I + 1 To S^.ShCount Do
    If (S^.Shapes[J] <> Nil) And
       (S^.Shapes[J]^.AnimEntry <> ANIM_NONE) And
       (OrigOrder[J] = TargetStep) Then
     S^.Shapes[J]^.AnimOrder := TargetStep + 1;
   PlayShapeEntry(Idx, TargetStep, I);
   For J := I + 1 To S^.ShCount Do
    If S^.Shapes[J] <> Nil Then
     S^.Shapes[J]^.AnimOrder := OrigOrder[J];
  End;
 End;
 RenderSlideAtStep(Idx, TargetStep);
End;

{ Boucle principale du diaporama plein ecran. }
Procedure SlideShowLoop(StartIdx: Integer);
Var Idx, K, ExtCode: Integer; Done, GoNext, GoPrev: Boolean; C: Char;
    Sl: PSlide; SaveView: Byte;
    CurStep, MaxStep: Integer;
Begin
 If Pres.SldCount = 0 Then Begin
  MessageBox('Diaporama', 'Aucune diapositive a presenter.');
  Exit;
 End;
 Idx := StartIdx;
 If Idx < 1 Then Idx := 1;
 If Idx > Pres.SldCount Then Idx := Pres.SldCount;
 { Saute les slides masquees au debut }
 While (Idx <= Pres.SldCount) And (Pres.Slides[Idx] <> Nil) And
       Pres.Slides[Idx]^.Hidden Do Inc(Idx);
 If Idx > Pres.SldCount Then Begin
  MessageBox('Diaporama', 'Toutes les diapositives sont masquees.');
  Exit;
 End;
 SaveView := CurView;
 CurView  := VIEW_SLIDESHOW;
 SetFillStyle(1, CLR_BLACK);
 Bar(0, 0, GetMaxX, GetMaxY);
 CurStep := 0;
 MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
 RenderSlideAtStep(Idx, CurStep);
 Done := False;
 Repeat
  GoNext := False; GoPrev := False;
  GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
  If KeyPressed Then Begin
   C := ReadKey;
   If C = #0 Then Begin
    ExtCode := Ord(ReadKey);
    Case ExtCode Of
     75, 72: GoPrev := True;             { fleche gauche / haut }
     77, 80, 81: GoNext := True;         { fleche droite / bas / PgDn }
     71: Begin                           { Home }
      Idx := 1;
      While (Idx <= Pres.SldCount) And (Pres.Slides[Idx] <> Nil) And
            Pres.Slides[Idx]^.Hidden Do Inc(Idx);
      If Idx <= Pres.SldCount Then Begin
       CurStep := 0;
       MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
       RenderSlideAtStep(Idx, CurStep);
      End;
     End;
     79: Begin                           { End }
      Idx := Pres.SldCount;
      While (Idx >= 1) And (Pres.Slides[Idx] <> Nil) And
            Pres.Slides[Idx]^.Hidden Do Dec(Idx);
      If Idx >= 1 Then Begin
       MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
       CurStep := MaxStep;
       RenderSlideAtStep(Idx, CurStep);
      End;
     End;
    End;
   End Else Begin
    Case C Of
     #27: Done := True;                  { Echap }
     #13, ' ', 'n', 'N': GoNext := True; { Entree / Espace / N }
     'p', 'P', #8: GoPrev := True;       { P / Backspace }
     'b', 'B': Begin
      SetFillStyle(1, CLR_BLACK);
      Bar(0, 0, GetMaxX, GetMaxY);
     End;
     'w', 'W': Begin
      SetFillStyle(1, CLR_WHITE);
      Bar(0, 0, GetMaxX, GetMaxY);
     End;
     'r', 'R': RenderSlideAtStep(Idx, CurStep);
    End;
   End;
  End Else If ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0) Then Begin
   GoNext := True;
   LastClickB := Mouse.B;
  End Else If ((Mouse.B And 2) <> 0) And ((LastClickB And 2) = 0) Then Begin
   GoPrev := True;
   LastClickB := Mouse.B;
  End Else
   LastClickB := Mouse.B;
  { Avance : etape suivante d'animation, sinon slide suivante }
  If GoNext Then Begin
   If CurStep < MaxStep Then Begin
    Inc(CurStep);
    RevealAnimStep(Idx, CurStep);
   End Else Begin
    K := Idx + 1;
    While (K <= Pres.SldCount) And (Pres.Slides[K] <> Nil) And
          Pres.Slides[K]^.Hidden Do Inc(K);
    If K <= Pres.SldCount Then Begin
     Sl  := Pres.Slides[Idx];
     Idx := K;
     CurStep := 0;
     MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
     If Sl <> Nil Then
      RunTransition(Idx, Sl^.Transition, Sl^.TransSpeed);
     RenderSlideAtStep(Idx, CurStep);
    End Else Done := True;
   End;
  End;
  { Recul : etape precedente, sinon slide precedente }
  If GoPrev Then Begin
   If CurStep > 0 Then Begin
    Dec(CurStep);
    RenderSlideAtStep(Idx, CurStep);
   End Else Begin
    K := Idx - 1;
    While (K >= 1) And (Pres.Slides[K] <> Nil) And
          Pres.Slides[K]^.Hidden Do Dec(K);
    If K >= 1 Then Begin
     Idx := K;
     MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
     CurStep := MaxStep;
     RenderSlideAtStep(Idx, CurStep);
    End;
   End;
  End;
  Delay(20);
 Until Done;
 CurView := SaveView;
 NeedFullRedraw := True;
End;

Procedure ActionInsertImage;
Var FN: String; Slot: Integer; P: PShape; S: PSlide;
    ImW, ImH, LogIW, LogIH: Integer;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If S = Nil Then Exit;
 If S^.ShCount >= MAX_SHAPES Then Begin
  MessageBox('Image', 'Nombre maximum de formes atteint sur cette slide.');
  Exit;
 End;
 FN := '';
 If Not InputTextDlg('Inserer une image',
                     'Fichier BMP ou PCX :', FN, 79) Then Exit;
 If FN = '' Then Exit;
 If Not LoadImageFile(FN, Slot) Then Begin
  MessageBox('Image', 'Impossible de charger : ' + FN);
  Exit;
 End;
 ImW := Pres.Images[Slot]^.W;
 ImH := Pres.Images[Slot]^.H;
 LogIW := 400;
 If ImW > 0 Then LogIH := (LongInt(ImH) * LogIW) Div ImW
            Else LogIH := 300;
 If LogIH > 500 Then Begin
  LogIH := 500;
  If ImH > 0 Then LogIW := (LongInt(ImW) * LogIH) Div ImH;
 End;
 P := NewShape;
 If P = Nil Then Begin
  MessageBox('Image', 'Memoire insuffisante.'); Exit;
 End;
 P^.ShType    := SHP_IMAGE;
 P^.X         := (1000 - LogIW) Div 2;
 P^.Y         := (750  - LogIH) Div 2;
 P^.W         := LogIW;
 P^.H         := LogIH;
 P^.ImageIdx  := Slot;
 P^.Filled    := False;
 P^.LineWidth := 0;
 P^.TxtCount  := 0;
 AddShapeToSlide(S, P);
 CurShape := S^.ShCount;
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Image chargee : ' + FN +
              ' (' + IntToStr(ImW) + 'x' + IntToStr(ImH) + ')';
 NeedStatRedraw := True;
 NeedSlideRedraw := True;
 NeedPanelRedraw := True;
End;

Procedure ActionAnimEntryDlg;
Const ANIM_LIST = 'Aucune'#10'Apparaitre'#10'Fondu'#10 +
                  'Glisser depuis la gauche'#10 +
                  'Glisser depuis la droite'#10 +
                  'Glisser depuis le haut'#10 +
                  'Glisser depuis le bas'#10 +
                  'Zoom'#10'Rotation';
Var S: PSlide; P: PShape; Sel: Integer; OrdStr: String;
    NewOrder: LongInt;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If (S = Nil) Or (CurShape < 1) Or (CurShape > S^.ShCount) Then Begin
  MessageBox('Animation', 'Selectionnez d''abord une forme.');
  Exit;
 End;
 P := S^.Shapes[CurShape]; If P = Nil Then Exit;
 Sel := SelectListDlg('Animation d''entree', ANIM_LIST, P^.AnimEntry + 1);
 If Sel = 0 Then Exit;
 P^.AnimEntry := Byte(Sel - 1);
 If P^.AnimEntry <> ANIM_NONE Then Begin
  OrdStr := IntToStr(P^.AnimOrder);
  If P^.AnimOrder = 0 Then OrdStr := '1';
  If InputTextDlg('Ordre d''animation',
                  'Ordre (1 = premier, max 250) :', OrdStr, 4) Then Begin
   NewOrder := StrToIntDef(OrdStr, 1);
   If NewOrder < 1 Then NewOrder := 1;
   If NewOrder > 250 Then NewOrder := 250;
   P^.AnimOrder := Byte(NewOrder);
  End Else If P^.AnimOrder = 0 Then
   P^.AnimOrder := 1;
 End Else
  P^.AnimOrder := 0;
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Animation d''entree mise a jour.';
 NeedStatRedraw := True;
End;

Procedure ActionAnimExitDlg;
Const ANIM_LIST = 'Aucune'#10'Disparaitre'#10'Fondu'#10 +
                  'Glisser vers la gauche'#10 +
                  'Glisser vers la droite'#10 +
                  'Glisser vers le haut'#10 +
                  'Glisser vers le bas'#10 +
                  'Zoom'#10'Rotation';
Var S: PSlide; P: PShape; Sel: Integer;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If (S = Nil) Or (CurShape < 1) Or (CurShape > S^.ShCount) Then Begin
  MessageBox('Animation', 'Selectionnez d''abord une forme.');
  Exit;
 End;
 P := S^.Shapes[CurShape]; If P = Nil Then Exit;
 Sel := SelectListDlg('Animation de sortie', ANIM_LIST, P^.AnimExit + 1);
 If Sel = 0 Then Exit;
 P^.AnimExit := Byte(Sel - 1);
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Animation de sortie mise a jour.';
 NeedStatRedraw := True;
End;

Procedure ActionTimingDlg;
Const SPD_LIST = 'Lente'#10'Moyenne'#10'Rapide';
Var S: PSlide; Sel: Integer;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If S = Nil Then Exit;
 Sel := SelectListDlg('Vitesse des transitions/animations',
                      SPD_LIST, S^.TransSpeed + 1);
 If Sel = 0 Then Exit;
 S^.TransSpeed := Byte(Sel - 1);
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Vitesse mise a jour.';
 NeedStatRedraw := True;
End;

Procedure ActionSlideShow;
Begin SlideShowLoop(1); End;

Procedure ActionSlideShowFrom;
Begin SlideShowLoop(CurSlide); End;

Procedure ActionChangeTransitionDlg;
Var Idx, I: Integer; Items: String; S: PSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If S = Nil Then Exit;
 Items := '';
 For I := 0 To 10 Do Begin
  If I > 0 Then Items := Items + #10;
  Items := Items + TransName(Byte(I));
 End;
 Idx := SelectListDlg('Transition de diapositive', Items, S^.Transition + 1);
 If Idx > 0 Then Begin
  S^.Transition := Byte(Idx - 1);
  S^.Dirty := True;
  If ConfirmYesNo('Transition',
                  'Appliquer a toutes les diapositives ?') Then Begin
   For I := 1 To Pres.SldCount Do
    If Pres.Slides[I] <> Nil Then Begin
     Pres.Slides[I]^.Transition := Byte(Idx - 1);
     Pres.Slides[I]^.Dirty      := True;
    End;
  End;
  StatusMsg := 'Transition : ' + TransName(Byte(Idx - 1));
  NeedStatRedraw := True;
 End;
 NeedFullRedraw := True;
End;

Procedure DoAction(A: Integer); Forward;
Procedure RemoveShapeAt(SlIdx, ShIdx: Integer); Forward;
Procedure ShapeDuplicate; Forward;
Procedure ShapeBringFront; Forward;
Procedure ShapeSendBack; Forward;
Procedure ShapeToggleBold; Forward;
Procedure ShapeToggleItalic; Forward;
Procedure ShapeToggleUnderline; Forward;
Procedure ShapeSetAlign(A: Byte); Forward;
Procedure ShapeApplyFontDelta(Delta: Integer); Forward;
Procedure ShapeCycleColor(Which: Byte); Forward;
Procedure EditToggleBullet; Forward;
Procedure EditIndent(Delta: Integer); Forward;

Procedure ActionViewChange(V: Integer);
Begin
 CurView := V;
 Case V Of
  VIEW_NORMAL:  StatusMsg := 'Mode Normal';
  VIEW_OUTLINE: StatusMsg := 'Mode Plan';
  VIEW_SORTER:  StatusMsg := 'Trieuse de diapositives';
  VIEW_NOTES:   StatusMsg := 'Commentaires';
 End;
 NeedFullRedraw := True;
End;

Procedure DoAction(A: Integer);
Begin
 Case A Of
  ACT_QUIT:         ActionQuit;
  ACT_NEW:          ActionNew;
  ACT_HELP_ABOUT:   ActionAbout;
  ACT_NEW_SLIDE:    ActionNewSlide;
  ACT_DUP_SLIDE:    ActionDupSlide;
  ACT_DEL_SLIDE:    ActionDelSlide;
  ACT_NEXT_SLIDE:   ActionNextSlide;
  ACT_PREV_SLIDE:   ActionPrevSlide;
  ACT_FIRST_SLIDE:  ActionFirstSlide;
  ACT_LAST_SLIDE:   ActionLastSlide;
  ACT_VIEW_NORMAL:  ActionViewChange(VIEW_NORMAL);
  ACT_VIEW_OUTLINE: ActionViewChange(VIEW_OUTLINE);
  ACT_VIEW_SORTER:  ActionViewChange(VIEW_SORTER);
  ACT_VIEW_NOTES:   ActionViewChange(VIEW_NOTES);
  ACT_TOOL_SELECT:  SetTool(TOOL_SELECT);
  ACT_TOOL_TEXT:    SetTool(TOOL_TEXT);
  ACT_TOOL_RECT:    SetTool(TOOL_RECT);
  ACT_TOOL_ELL:     SetTool(TOOL_ELLIPSE);
  ACT_TOOL_LINE:    SetTool(TOOL_LINE);
  ACT_TOOL_ARROW:   SetTool(TOOL_ARROW);
  ACT_INS_RECT:     SetTool(TOOL_RECT);
  ACT_INS_ELLIPSE:  SetTool(TOOL_ELLIPSE);
  ACT_INS_LINE:     SetTool(TOOL_LINE);
  ACT_INS_ARROW:    SetTool(TOOL_ARROW);
  ACT_INS_TRIANGLE: SetTool(TOOL_TRIANGLE);
  ACT_INS_STAR:     SetTool(TOOL_STAR);
  ACT_INS_CALLOUT:  SetTool(TOOL_CALLOUT);
  ACT_INS_TEXT:     SetTool(TOOL_TEXT);
  ACT_FONT_BOLD:    ShapeToggleBold;
  ACT_FONT_ITAL:    ShapeToggleItalic;
  ACT_FONT_UND:     ShapeToggleUnderline;
  ACT_ALIGN_LEFT:   ShapeSetAlign(ALIGN_LEFT);
  ACT_ALIGN_CENTER: ShapeSetAlign(ALIGN_CENTER);
  ACT_ALIGN_RIGHT:  ShapeSetAlign(ALIGN_RIGHT);
  ACT_BULLET:       EditToggleBullet;
  ACT_INDENT_INC:   EditIndent(+1);
  ACT_INDENT_DEC:   EditIndent(-1);
  ACT_FONT_SIZE_UP: ShapeApplyFontDelta(+2);
  ACT_FONT_SIZE_DN: ShapeApplyFontDelta(-2);
  ACT_COLOR_FILL:   ShapeCycleColor(0);
  ACT_COLOR_LINE:   ShapeCycleColor(1);
  ACT_COLOR_TEXT:   ShapeCycleColor(2);
  ACT_MOVE_UP:      ActionMoveSlideUp;
  ACT_MOVE_DOWN:    ActionMoveSlideDown;
  ACT_LAYOUT:       ActionChangeLayoutDlg;
  ACT_BACKGROUND:   ActionChangeBackgroundDlg;
  ACT_THEME:        ActionChangeThemeDlg;
  ACT_VIEW_MASTER:  ActionMasterEdit;
  ACT_INS_HEADER:   ActionHeaderFooter;
  ACT_SLIDESHOW:      ActionSlideShow;
  ACT_SLIDESHOW_FROM: ActionSlideShowFrom;
  ACT_RUN_FROM_BEG:   ActionSlideShow;
  ACT_TRANS:          ActionChangeTransitionDlg;
  ACT_INS_IMAGE:      ActionInsertImage;
  ACT_ANIM_ENTRY:     ActionAnimEntryDlg;
  ACT_ANIM_EXIT:      ActionAnimExitDlg;
  ACT_TIMING:         ActionTimingDlg;
  ACT_DELETE: Begin
   If CurShape > 0 Then Begin
    RemoveShapeAt(CurSlide, CurShape);
    CurShape := 0;
    NeedSlideRedraw := True; NeedPanelRedraw := True;
    StatusMsg := 'Forme supprimee.'; NeedStatRedraw := True;
   End;
  End;
  ACT_DUP: Begin
   If CurShape > 0 Then Begin
    ShapeDuplicate;
    NeedSlideRedraw := True; NeedPanelRedraw := True;
    StatusMsg := 'Forme dupliquee.'; NeedStatRedraw := True;
   End Else ActionDupSlide;
  End;
  ACT_BRING_FRONT: Begin
   ShapeBringFront;
   NeedSlideRedraw := True; NeedPanelRedraw := True;
   StatusMsg := 'Premier plan.'; NeedStatRedraw := True;
  End;
  ACT_SEND_BACK: Begin
   ShapeSendBack;
   NeedSlideRedraw := True; NeedPanelRedraw := True;
   StatusMsg := 'Arriere-plan.'; NeedStatRedraw := True;
  End;
 Else Begin
  StatusMsg := 'Action ' + IntToStr(A) + ' : a implementer (phase ulterieure).';
  NeedStatRedraw := True;
 End;
 End;
End;

{ ====================================================================== }
{                       GESTION SOURIS                                   }
{ ====================================================================== }

Procedure HandleMenuBarClick;
Var M: Integer;
Begin
 M := MenuAtX(Mouse.X);
 If M = 0 Then Begin
  MenuOpen := 0; NeedFullRedraw := True; Exit;
 End;
 If M = MenuOpen Then MenuOpen := 0
 Else Begin
  MenuOpen := M;
  MenuItemHover := 0;
 End;
 NeedFullRedraw := True;
End;

Procedure HandleDropDownClick;
Var Idx, Act: Integer;
Begin
 If MenuOpen = 0 Then Exit;
 If InRect(Mouse.X, Mouse.Y, DropX, DropY, DropX + DropW, DropY + DropH) Then Begin
  Idx := DropItemAtY(MenuOpen, Mouse.Y);
  If Idx > 0 Then Begin
   Act := Menus[MenuOpen].Items[Idx].Action;
   MenuOpen := 0;
   NeedFullRedraw := True;
   If Act <> 0 Then DoAction(Act);
  End;
 End
 Else Begin
  MenuOpen := 0;
  NeedFullRedraw := True;
 End;
End;

Function ShapeAt(SX, SY: Integer): Integer;
Var I, X1, Y1, X2, Y2: Integer; S: PSlide; Sh: PShape;
Begin
 ShapeAt := 0;
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 For I := S^.ShCount Downto 1 Do Begin
  Sh := S^.Shapes[I];
  If (Sh = Nil) Or Sh^.Hidden Then Continue;
  X1 := LogX(Sh^.X);
  Y1 := LogY(Sh^.Y);
  X2 := LogX(Sh^.X + Sh^.W);
  Y2 := LogY(Sh^.Y + Sh^.H);
  If InRect(SX, SY, X1, Y1, X2, Y2) Then Begin
   ShapeAt := I; Exit;
  End;
 End;
End;

{ ====================================================================== }
{        PHASE 2 - INVERSE COORDS, POIGNEES, MANIPULATION                }
{ ====================================================================== }

Function ScreenToLogX(SX: Integer): Integer;
Var W: LongInt;
Begin
 W := SlideX2 - SlideX1; If W <= 0 Then W := 1;
 ScreenToLogX := (LongInt(SX - SlideX1) * 1000) Div W;
End;

Function ScreenToLogY(SY: Integer): Integer;
Var H: LongInt;
Begin
 H := SlideY2 - SlideY1; If H <= 0 Then H := 1;
 ScreenToLogY := (LongInt(SY - SlideY1) * 750) Div H;
End;

Function ScreenToLogW(SW: Integer): Integer;
Var W: LongInt;
Begin
 W := SlideX2 - SlideX1; If W <= 0 Then W := 1;
 ScreenToLogW := (LongInt(SW) * 1000) Div W;
End;

Function ScreenToLogH(SH: Integer): Integer;
Var H: LongInt;
Begin
 H := SlideY2 - SlideY1; If H <= 0 Then H := 1;
 ScreenToLogH := (LongInt(SH) * 750) Div H;
End;

{ Retourne 1..8 si (X,Y) est sur une poignee de la forme P, 0 sinon.
  Ordre : 1=NO 2=N 3=NE 4=E 5=SE 6=S 7=SO 8=O }
Function HitHandle(P: PShape; X, Y: Integer): Byte;
Var X1, Y1, X2, Y2, Cx, Cy: Integer;
Begin
 HitHandle := 0;
 If P = Nil Then Exit;
 X1 := LogX(P^.X); Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W); Y2 := LogY(P^.Y + P^.H);
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 If InRect(X, Y, X1 - 3, Y1 - 3, X1 + 1, Y1 + 1) Then Begin HitHandle := 1; Exit; End;
 If InRect(X, Y, Cx - 2, Y1 - 3, Cx + 2, Y1 + 1) Then Begin HitHandle := 2; Exit; End;
 If InRect(X, Y, X2 - 1, Y1 - 3, X2 + 3, Y1 + 1) Then Begin HitHandle := 3; Exit; End;
 If InRect(X, Y, X2 - 1, Cy - 2, X2 + 3, Cy + 2) Then Begin HitHandle := 4; Exit; End;
 If InRect(X, Y, X2 - 1, Y2 - 1, X2 + 3, Y2 + 3) Then Begin HitHandle := 5; Exit; End;
 If InRect(X, Y, Cx - 2, Y2 - 1, Cx + 2, Y2 + 3) Then Begin HitHandle := 6; Exit; End;
 If InRect(X, Y, X1 - 3, Y2 - 1, X1 + 1, Y2 + 3) Then Begin HitHandle := 7; Exit; End;
 If InRect(X, Y, X1 - 3, Cy - 2, X1 + 1, Cy + 2) Then Begin HitHandle := 8; Exit; End;
End;

{ Trace rectangle XOR pour bande elastique - efface si redessine }
Procedure XorRect(X1, Y1, X2, Y2: Integer);
Var T: Integer;
Begin
 If X2 < X1 Then Begin T := X1; X1 := X2; X2 := T; End;
 If Y2 < Y1 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;
 SetWriteMode(XORPut);
 SetColor(CLR_WHITE);
 Rectangle(X1, Y1, X2, Y2);
 SetWriteMode(NormalPut);
End;

Procedure XorLine(X1, Y1, X2, Y2: Integer);
Begin
 SetWriteMode(XORPut);
 SetColor(CLR_WHITE);
 Line(X1, Y1, X2, Y2);
 SetWriteMode(NormalPut);
End;

Procedure EraseRubberBand;
Begin
 If Not RubberValid Then Exit;
 If DragMode = 3 Then Begin
  Case DragShapeKind Of
   SHP_LINE, SHP_ARROW: XorLine(RubberX1, RubberY1, RubberX2, RubberY2);
  Else XorRect(RubberX1, RubberY1, RubberX2, RubberY2);
  End;
 End Else
  XorRect(RubberX1, RubberY1, RubberX2, RubberY2);
 RubberValid := False;
End;

Procedure DrawRubberBand(X1, Y1, X2, Y2: Integer);
Begin
 EraseRubberBand;
 If DragMode = 3 Then Begin
  Case DragShapeKind Of
   SHP_LINE, SHP_ARROW: XorLine(X1, Y1, X2, Y2);
  Else XorRect(X1, Y1, X2, Y2);
  End;
 End Else
  XorRect(X1, Y1, X2, Y2);
 RubberX1 := X1; RubberY1 := Y1;
 RubberX2 := X2; RubberY2 := Y2;
 RubberValid := True;
End;

Function ToolToShapeKind(T: Integer): Byte;
Begin
 ToolToShapeKind := 0;
 Case T Of
  TOOL_TEXT:     ToolToShapeKind := SHP_TEXT;
  TOOL_RECT:     ToolToShapeKind := SHP_RECT;
  TOOL_ELLIPSE:  ToolToShapeKind := SHP_ELLIPSE;
  TOOL_LINE:     ToolToShapeKind := SHP_LINE;
  TOOL_ARROW:    ToolToShapeKind := SHP_ARROW;
  TOOL_TRIANGLE: ToolToShapeKind := SHP_TRIANGLE;
  TOOL_STAR:     ToolToShapeKind := SHP_STAR;
  TOOL_CALLOUT:  ToolToShapeKind := SHP_CALLOUT;
 End;
End;

{ Insere une forme dans la slide courante a partir d'un rect logique }
Function CreateShapeRect(Kind: Byte; LX1, LY1, LX2, LY2: Integer): Integer;
Var Sh: PShape; T: Integer;
Begin
 CreateShapeRect := 0;
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 If LX2 < LX1 Then Begin T := LX1; LX1 := LX2; LX2 := T; End;
 If LY2 < LY1 Then Begin T := LY1; LY1 := LY2; LY2 := T; End;
 { Taille minimum sauf pour lignes }
 If (Kind <> SHP_LINE) And (Kind <> SHP_ARROW) Then Begin
  If LX2 - LX1 < 20 Then LX2 := LX1 + 20;
  If LY2 - LY1 < 20 Then LY2 := LY1 + 20;
 End Else Begin
  If LX2 - LX1 < 4 Then LX2 := LX1 + 4;
  If LY2 - LY1 < 4 Then LY2 := LY1 + 4;
 End;
 If LX1 < 0 Then LX1 := 0; If LY1 < 0 Then LY1 := 0;
 If LX2 > 1000 Then LX2 := 1000; If LY2 > 750 Then LY2 := 750;
 Sh := NewShape;
 If Sh = Nil Then Exit;
 Sh^.ShType := Kind;
 Sh^.X := LX1; Sh^.Y := LY1;
 Sh^.W := LX2 - LX1; Sh^.H := LY2 - LY1;
 Case Kind Of
  SHP_LINE, SHP_ARROW: Begin
   Sh^.FillColor := 0; Sh^.LineColor := CLR_BLACK;
   Sh^.Filled := False; Sh^.LineWidth := 2;
  End;
  SHP_TEXT: Begin
   Sh^.FillColor := CLR_WHITE; Sh^.LineColor := CLR_LGRAY;
   Sh^.Filled := False; Sh^.LineWidth := 1;
   Sh^.TxtCount := 1; Sh^.Text[1] := 'Zone de texte';
   Sh^.FontSize := 14;
  End;
  SHP_STAR: Begin
   Sh^.FillColor := CLR_YELLOW; Sh^.LineColor := CLR_BROWN;
   Sh^.Filled := True; Sh^.LineWidth := 1;
  End;
  SHP_TRIANGLE, SHP_DIAMOND: Begin
   Sh^.FillColor := CLR_LCYAN; Sh^.LineColor := CLR_BLUE;
   Sh^.Filled := True; Sh^.LineWidth := 1;
  End;
  SHP_CALLOUT: Begin
   Sh^.FillColor := CLR_YELLOW; Sh^.LineColor := CLR_BLACK;
   Sh^.Filled := True; Sh^.LineWidth := 1;
   Sh^.TxtCount := 1; Sh^.Text[1] := 'Bulle';
  End;
 Else Begin
  Sh^.FillColor := CLR_LBLUE; Sh^.LineColor := CLR_BLUE;
  Sh^.Filled := True; Sh^.LineWidth := 1;
 End;
 End;
 AddShapeToSlide(Pres.Slides[CurSlide], Sh);
 CreateShapeRect := Pres.Slides[CurSlide]^.ShCount;
 Pres.Slides[CurSlide]^.Dirty := True;
 Pres.Dirty := True;
End;

Procedure RemoveShapeAt(SlIdx, ShIdx: Integer);
Var I: Integer; S: PSlide;
Begin
 If (SlIdx < 1) Or (SlIdx > Pres.SldCount) Then Exit;
 S := Pres.Slides[SlIdx];
 If (ShIdx < 1) Or (ShIdx > S^.ShCount) Then Exit;
 FreeShape(S^.Shapes[ShIdx]);
 For I := ShIdx To S^.ShCount - 1 Do
  S^.Shapes[I] := S^.Shapes[I + 1];
 S^.Shapes[S^.ShCount] := Nil;
 Dec(S^.ShCount);
 S^.Dirty := True;
 Pres.Dirty := True;
End;

Procedure ShapeBringFront;
Var S: PSlide; P: PShape; I: Integer;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 S := Pres.Slides[CurSlide];
 If CurShape >= S^.ShCount Then Exit;
 P := S^.Shapes[CurShape];
 For I := CurShape To S^.ShCount - 1 Do
  S^.Shapes[I] := S^.Shapes[I + 1];
 S^.Shapes[S^.ShCount] := P;
 CurShape := S^.ShCount;
 S^.Dirty := True; Pres.Dirty := True;
End;

Procedure ShapeSendBack;
Var S: PSlide; P: PShape; I: Integer;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 S := Pres.Slides[CurSlide];
 If CurShape <= 1 Then Exit;
 P := S^.Shapes[CurShape];
 For I := CurShape Downto 2 Do
  S^.Shapes[I] := S^.Shapes[I - 1];
 S^.Shapes[1] := P;
 CurShape := 1;
 S^.Dirty := True; Pres.Dirty := True;
End;

Procedure ShapeDuplicate;
Var S: PSlide; Src, Dst: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 S := Pres.Slides[CurSlide];
 If S^.ShCount >= MAX_SHAPES Then Exit;
 Src := S^.Shapes[CurShape];
 Dst := NewShape; If Dst = Nil Then Exit;
 Dst^ := Src^;
 Dst^.X := Src^.X + 20; Dst^.Y := Src^.Y + 20;
 If Dst^.X + Dst^.W > 1000 Then Dst^.X := 1000 - Dst^.W;
 If Dst^.Y + Dst^.H > 750  Then Dst^.Y := 750  - Dst^.H;
 AddShapeToSlide(S, Dst);
 CurShape := S^.ShCount;
 S^.Dirty := True; Pres.Dirty := True;
End;

Procedure NudgeShape(Dx, Dy: Integer);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.X := P^.X + Dx; P^.Y := P^.Y + Dy;
 If P^.X < 0 Then P^.X := 0;
 If P^.Y < 0 Then P^.Y := 0;
 If P^.X + P^.W > 1000 Then P^.X := 1000 - P^.W;
 If P^.Y + P^.H > 750  Then P^.Y := 750  - P^.H;
 Pres.Slides[CurSlide]^.Dirty := True; Pres.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ResizeShapeKey(Dw, Dh: Integer);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.W := P^.W + Dw; P^.H := P^.H + Dh;
 If P^.W < 20 Then P^.W := 20;
 If P^.H < 20 Then P^.H := 20;
 If P^.X + P^.W > 1000 Then P^.W := 1000 - P^.X;
 If P^.Y + P^.H > 750  Then P^.H := 750  - P^.Y;
 Pres.Slides[CurSlide]^.Dirty := True; Pres.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure CycleShapeSelection(Reverse: Boolean);
Var N: Integer;
Begin
 If CurSlide < 1 Then Exit;
 N := Pres.Slides[CurSlide]^.ShCount;
 If N = 0 Then Begin CurShape := 0; Exit; End;
 If Reverse Then Begin
  Dec(CurShape);
  If CurShape < 1 Then CurShape := N;
 End Else Begin
  Inc(CurShape);
  If CurShape > N Then CurShape := 1;
 End;
 NeedSlideRedraw := True;
End;

Procedure UpdateDrag;
Var P: PShape; Lx, Ly, Ldx, Ldy: Integer;
    NX, NY, NW, NH: Integer;
    SX1, SY1, SX2, SY2: Integer;
Begin
 If DragMode = 0 Then Exit;
 If (Mouse.X = LastMouseX) And (Mouse.Y = LastMouseY) Then Exit;
 LastMouseX := Mouse.X; LastMouseY := Mouse.Y;
 Case DragMode Of
  1: Begin   { deplacement }
   P := Pres.Slides[CurSlide]^.Shapes[DragShapeIdx];
   If P = Nil Then Exit;
   Ldx := ScreenToLogW(Mouse.X - DragStartX);
   Ldy := ScreenToLogH(Mouse.Y - DragStartY);
   NX := DragOrigX + Ldx; NY := DragOrigY + Ldy;
   If NX < 0 Then NX := 0; If NY < 0 Then NY := 0;
   If NX + P^.W > 1000 Then NX := 1000 - P^.W;
   If NY + P^.H > 750  Then NY := 750  - P^.H;
   P^.X := NX; P^.Y := NY;
   NeedSlideRedraw := True;
  End;
  2: Begin   { resize par poignee }
   P := Pres.Slides[CurSlide]^.Shapes[DragShapeIdx];
   If P = Nil Then Exit;
   Ldx := ScreenToLogW(Mouse.X - DragStartX);
   Ldy := ScreenToLogH(Mouse.Y - DragStartY);
   NX := DragOrigX; NY := DragOrigY;
   NW := DragOrigW; NH := DragOrigH;
   Case DragHandle Of
    1: Begin NX := DragOrigX + Ldx; NY := DragOrigY + Ldy;
             NW := DragOrigW - Ldx; NH := DragOrigH - Ldy; End;
    2: Begin NY := DragOrigY + Ldy; NH := DragOrigH - Ldy; End;
    3: Begin NY := DragOrigY + Ldy;
             NW := DragOrigW + Ldx; NH := DragOrigH - Ldy; End;
    4: Begin NW := DragOrigW + Ldx; End;
    5: Begin NW := DragOrigW + Ldx; NH := DragOrigH + Ldy; End;
    6: Begin NH := DragOrigH + Ldy; End;
    7: Begin NX := DragOrigX + Ldx;
             NW := DragOrigW - Ldx; NH := DragOrigH + Ldy; End;
    8: Begin NX := DragOrigX + Ldx; NW := DragOrigW - Ldx; End;
   End;
   If NW < 20 Then Begin NW := 20; If DragHandle In [1,7,8] Then NX := DragOrigX + DragOrigW - 20; End;
   If NH < 20 Then Begin NH := 20; If DragHandle In [1,2,3] Then NY := DragOrigY + DragOrigH - 20; End;
   If NX < 0 Then Begin NW := NW + NX; NX := 0; End;
   If NY < 0 Then Begin NH := NH + NY; NY := 0; End;
   If NX + NW > 1000 Then NW := 1000 - NX;
   If NY + NH > 750  Then NH := 750  - NY;
   P^.X := NX; P^.Y := NY; P^.W := NW; P^.H := NH;
   NeedSlideRedraw := True;
  End;
  3, 4: Begin   { rubber-band : nouvelle forme ou marquee }
   SX1 := DragStartX; SY1 := DragStartY;
   SX2 := Mouse.X;    SY2 := Mouse.Y;
   If SX2 < SlideX1 Then SX2 := SlideX1;
   If SY2 < SlideY1 Then SY2 := SlideY1;
   If SX2 > SlideX2 Then SX2 := SlideX2;
   If SY2 > SlideY2 Then SY2 := SlideY2;
   HideMouse;
   DrawRubberBand(SX1, SY1, SX2, SY2);
   ShowMouse;
  End;
 End;
End;

Procedure EndDrag;
Var Lx1, Ly1, Lx2, Ly2, Idx, T: Integer;
    S: PSlide; Sh: PShape; X1, Y1, X2, Y2: Integer;
Begin
 If DragMode = 0 Then Exit;
 Case DragMode Of
  1, 2: Begin
   Pres.Slides[CurSlide]^.Dirty := True;
   Pres.Dirty := True;
   NeedSlideRedraw := True;
   NeedPanelRedraw := True;
  End;
  3: Begin   { creation d'une forme par drag }
   HideMouse;
   EraseRubberBand;
   ShowMouse;
   Lx1 := ScreenToLogX(DragStartX);
   Ly1 := ScreenToLogY(DragStartY);
   Lx2 := ScreenToLogX(Mouse.X);
   Ly2 := ScreenToLogY(Mouse.Y);
   Idx := CreateShapeRect(DragShapeKind, Lx1, Ly1, Lx2, Ly2);
   If Idx > 0 Then Begin
    CurShape := Idx;
    StatusMsg := 'Forme ajoutee.';
   End;
   { Retour outil selection apres dessin (comportement Visio/PowerPoint) }
   CurTool := TOOL_SELECT;
   NeedFullRedraw := True;
  End;
  4: Begin   { marquee selection - selectionne premiere forme dans le cadre }
   HideMouse;
   EraseRubberBand;
   ShowMouse;
   If CurSlide >= 1 Then Begin
    S := Pres.Slides[CurSlide];
    X1 := DragStartX; Y1 := DragStartY;
    X2 := Mouse.X;    Y2 := Mouse.Y;
    If X2 < X1 Then Begin T := X1; X1 := X2; X2 := T; End;
    If Y2 < Y1 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;
    For T := S^.ShCount Downto 1 Do Begin
     Sh := S^.Shapes[T];
     If Sh = Nil Then Continue;
     If (LogX(Sh^.X) >= X1) And (LogY(Sh^.Y) >= Y1) And
        (LogX(Sh^.X + Sh^.W) <= X2) And (LogY(Sh^.Y + Sh^.H) <= Y2) Then Begin
      CurShape := T; Break;
     End;
    End;
   End;
   NeedSlideRedraw := True;
  End;
 End;
 DragMode := 0;
 DragHandle := 0;
 RubberValid := False;
End;

{ ====================================================================== }
{          PHASE 3 - EDITION DE TEXTE RICHE DANS LES FORMES              }
{ ====================================================================== }

Function ShapeAcceptsText(P: PShape): Boolean;
Begin
 ShapeAcceptsText := False;
 If P = Nil Then Exit;
 Case P^.ShType Of
  SHP_TITLE, SHP_SUBTITLE, SHP_CONTENT, SHP_TEXT,
  SHP_CALLOUT, SHP_RECT, SHP_ROUNDRECT, SHP_ELLIPSE,
  SHP_TRIANGLE, SHP_DIAMOND, SHP_STAR:
   ShapeAcceptsText := True;
 End;
End;

Function IsPlaceholderText(Const S: String): Boolean;
Begin
 IsPlaceholderText := (Pos('Cliquez pour ajouter', S) = 1);
End;

Procedure CommitEditBuf;
Var P: PShape;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If (EditLine < 1) Or (EditLine > MAX_TEXT_LINES) Then Exit;
 If Length(EditBuf) > TXT_LINE_LEN Then EditBuf[0] := Chr(TXT_LINE_LEN);
 P^.Text[EditLine] := EditBuf;
 If EditLine > P^.TxtCount Then P^.TxtCount := EditLine;
 Pres.Slides[CurSlide]^.Dirty := True;
 Pres.Dirty := True;
End;

Procedure ExitEditMode;
Begin
 If Not EditMode Then Exit;
 CommitEditBuf;
 EditMode := False;
 EditBuf := '';
 EditCaret := 0;
 EditLine := 0;
 StatusMsg := 'Edition terminee.';
 NeedSlideRedraw := True;
 NeedStatRedraw := True;
End;

Procedure LoadEditLine(P: PShape; LineIdx: Integer);
Begin
 EditLine := LineIdx;
 If (LineIdx >= 1) And (LineIdx <= P^.TxtCount) Then Begin
  EditBuf := P^.Text[LineIdx];
  If IsPlaceholderText(EditBuf) Then EditBuf := '';
 End Else Begin
  EditBuf := '';
 End;
 EditCaret := Length(EditBuf);
End;

Procedure EnterEditMode(ShIdx, LineIdx: Integer);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (ShIdx < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[ShIdx];
 If Not ShapeAcceptsText(P) Then Exit;
 If P^.TxtCount = 0 Then Begin
  P^.TxtCount := 1; P^.Text[1] := ''; P^.Bullets[1] := False; P^.Indent[1] := 0;
 End;
 If LineIdx < 1 Then LineIdx := 1;
 If LineIdx > P^.TxtCount Then LineIdx := P^.TxtCount;
 CurShape := ShIdx;
 EditMode := True;
 LoadEditLine(P, LineIdx);
 StatusMsg := 'Edition de texte (Esc pour terminer).';
 NeedSlideRedraw := True;
 NeedStatRedraw := True;
End;

Procedure EditInsertChar(C: Char);
Begin
 If Not EditMode Then Exit;
 If Length(EditBuf) >= TXT_LINE_LEN Then Exit;
 If (EditCaret < 0) Then EditCaret := 0;
 If (EditCaret > Length(EditBuf)) Then EditCaret := Length(EditBuf);
 Insert(C, EditBuf, EditCaret + 1);
 Inc(EditCaret);
 NeedSlideRedraw := True;
End;

Procedure EditBackspace;
Begin
 If Not EditMode Then Exit;
 If EditCaret <= 0 Then Exit;
 Delete(EditBuf, EditCaret, 1);
 Dec(EditCaret);
 NeedSlideRedraw := True;
End;

Procedure EditDeleteChar;
Begin
 If Not EditMode Then Exit;
 If EditCaret >= Length(EditBuf) Then Exit;
 Delete(EditBuf, EditCaret + 1, 1);
 NeedSlideRedraw := True;
End;

Procedure EditMoveCaret(Dx: Integer);
Begin
 If Not EditMode Then Exit;
 Inc(EditCaret, Dx);
 If EditCaret < 0 Then EditCaret := 0;
 If EditCaret > Length(EditBuf) Then EditCaret := Length(EditBuf);
 NeedSlideRedraw := True;
End;

Procedure EditMoveLine(Dy: Integer);
Var P: PShape; N, NewLine: Integer;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 CommitEditBuf;
 N := P^.TxtCount;
 NewLine := EditLine + Dy;
 If NewLine < 1 Then NewLine := 1;
 If NewLine > N Then NewLine := N;
 LoadEditLine(P, NewLine);
 NeedSlideRedraw := True;
End;

Procedure EditHomeEnd(ToEnd: Boolean);
Begin
 If Not EditMode Then Exit;
 If ToEnd Then EditCaret := Length(EditBuf) Else EditCaret := 0;
 NeedSlideRedraw := True;
End;

Procedure EditNewLine;
Var P: PShape; I: Integer;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If P^.TxtCount >= MAX_TEXT_LINES Then Exit;
 CommitEditBuf;
 { Decale les lignes apres EditLine vers le bas }
 For I := P^.TxtCount Downto EditLine + 1 Do Begin
  P^.Text[I + 1]    := P^.Text[I];
  P^.Bullets[I + 1] := P^.Bullets[I];
  P^.Indent[I + 1]  := P^.Indent[I];
 End;
 Inc(P^.TxtCount);
 P^.Text[EditLine + 1]    := '';
 P^.Bullets[EditLine + 1] := P^.Bullets[EditLine];
 P^.Indent[EditLine + 1]  := P^.Indent[EditLine];
 Inc(EditLine);
 EditBuf := '';
 EditCaret := 0;
 NeedSlideRedraw := True;
End;

Procedure EditBackLine;
Var P: PShape; I, PrevLen: Integer;
Begin
 { Backspace en debut de ligne : fusionne avec la precedente }
 If Not EditMode Then Exit;
 If EditLine <= 1 Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 CommitEditBuf;
 PrevLen := Length(P^.Text[EditLine - 1]);
 If PrevLen + Length(P^.Text[EditLine]) <= TXT_LINE_LEN Then
  P^.Text[EditLine - 1] := P^.Text[EditLine - 1] + P^.Text[EditLine];
 For I := EditLine To P^.TxtCount - 1 Do Begin
  P^.Text[I]    := P^.Text[I + 1];
  P^.Bullets[I] := P^.Bullets[I + 1];
  P^.Indent[I]  := P^.Indent[I + 1];
 End;
 P^.Text[P^.TxtCount] := '';
 P^.Bullets[P^.TxtCount] := False;
 P^.Indent[P^.TxtCount] := 0;
 Dec(P^.TxtCount);
 Dec(EditLine);
 LoadEditLine(P, EditLine);
 EditCaret := PrevLen;
 NeedSlideRedraw := True;
End;

Procedure EditIndent(Delta: Integer);
Var P: PShape;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If (EditLine < 1) Or (EditLine > MAX_TEXT_LINES) Then Exit;
 If Delta > 0 Then Begin
  If P^.Indent[EditLine] < 5 Then Inc(P^.Indent[EditLine]);
 End Else Begin
  If P^.Indent[EditLine] > 0 Then Dec(P^.Indent[EditLine]);
 End;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure EditToggleBullet;
Var P: PShape; I: Integer; NewVal: Boolean;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If EditMode Then Begin
  P^.Bullets[EditLine] := Not P^.Bullets[EditLine];
 End Else Begin
  If P^.TxtCount > 0 Then NewVal := Not P^.Bullets[1] Else NewVal := True;
  For I := 1 To P^.TxtCount Do P^.Bullets[I] := NewVal;
 End;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

{ Detection ligne ciblee par un clic dans la forme }
Function LineAtY(P: PShape; SY: Integer): Integer;
Var Ty, LineH, I, Y1: Integer;
Begin
 LineAtY := 1;
 If P^.TxtCount <= 0 Then Exit;
 LineH := 12;
 If P^.FontSize >= 24 Then LineH := 22
 Else If P^.FontSize >= 18 Then LineH := 16;
 Y1 := LogY(P^.Y);
 Ty := Y1 + 4;
 For I := 1 To P^.TxtCount Do Begin
  If (SY >= Ty) And (SY < Ty + LineH) Then Begin LineAtY := I; Exit; End;
  Ty := Ty + LineH;
 End;
 LineAtY := P^.TxtCount;
End;

Procedure ShapeApplyFontDelta(Delta: Integer);
Var P: PShape; F: Integer;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 F := P^.FontSize + Delta;
 If F < 8 Then F := 8;
 If F > 72 Then F := 72;
 P^.FontSize := F;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
 StatusMsg := 'Taille de police: ' + IntToStr(F);
 NeedStatRedraw := True;
End;

Procedure ShapeToggleBold;
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Bold := Not P^.Bold;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeToggleItalic;
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Italic := Not P^.Italic;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeToggleUnderline;
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Underline := Not P^.Underline;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeSetAlign(A: Byte);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Align := A;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeCycleColor(Which: Byte);
{ Which : 0=fill 1=line 2=text. Cycle parmi 16 couleurs VGA }
Var P: PShape; C: Byte;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 Case Which Of
  0: Begin C := (P^.FillColor + 1) And 15; P^.FillColor := C;
           StatusMsg := 'Remplissage : couleur ' + IntToStr(C); End;
  1: Begin C := (P^.LineColor + 1) And 15; P^.LineColor := C;
           StatusMsg := 'Contour : couleur ' + IntToStr(C); End;
  2: Begin C := (P^.TextColor + 1) And 15; P^.TextColor := C;
           StatusMsg := 'Texte : couleur ' + IntToStr(C); End;
 End;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
 NeedStatRedraw := True;
End;

Procedure HandleSlideAreaClick;
Var Idx: Integer; H: Byte; P: PShape; Kind: Byte;
Begin
 If Not InRect(Mouse.X, Mouse.Y, SlideX1, SlideY1, SlideX2, SlideY2) Then Begin
  If EditMode Then ExitEditMode;
  CurShape := 0; NeedSlideRedraw := True; Exit;
  End;
 { Si on est en edition, clic dans la meme forme = repositionne ligne, ailleurs = sort }
 If EditMode And (CurShape > 0) Then Begin
  Idx := ShapeAt(Mouse.X, Mouse.Y);
  P := Pres.Slides[CurSlide]^.Shapes[CurShape];
  If Idx = CurShape Then Begin
   CommitEditBuf;
   LoadEditLine(P, LineAtY(P, Mouse.Y));
   NeedSlideRedraw := True;
   Exit;
  End Else Begin
   ExitEditMode;
   { ne pas exit - continuer pour traiter le clic comme normal }
  End;
 End;
 { Double-clic sur une forme texte : entre en edition }
 If DoubleClicked Then Begin
  Idx := ShapeAt(Mouse.X, Mouse.Y);
  If Idx > 0 Then Begin
   P := Pres.Slides[CurSlide]^.Shapes[Idx];
   If ShapeAcceptsText(P) Then Begin
    EnterEditMode(Idx, LineAtY(P, Mouse.Y));
    Exit;
   End;
  End;
 End;
 { Outil de dessin actif : on amorce un drag rubber-band pour creer une forme }
 Kind := ToolToShapeKind(CurTool);
 If Kind <> 0 Then Begin
  DragMode      := 3;
  DragShapeKind := Kind;
  DragStartX    := Mouse.X; DragStartY := Mouse.Y;
  LastMouseX    := Mouse.X; LastMouseY := Mouse.Y;
  RubberValid   := False;
  CurShape      := 0;
  StatusMsg     := 'Glissez pour dimensionner la forme...';
  NeedStatRedraw := True;
  Exit;
 End;
 { Outil selection : tester poignee si forme deja selectionnee }
 If CurShape > 0 Then Begin
  P := Pres.Slides[CurSlide]^.Shapes[CurShape];
  H := HitHandle(P, Mouse.X, Mouse.Y);
  If H <> 0 Then Begin
   DragMode    := 2;
   DragHandle  := H;
   DragShapeIdx := CurShape;
   DragStartX  := Mouse.X; DragStartY := Mouse.Y;
   DragOrigX   := P^.X; DragOrigY := P^.Y;
   DragOrigW   := P^.W; DragOrigH := P^.H;
   LastMouseX  := Mouse.X; LastMouseY := Mouse.Y;
   StatusMsg   := 'Redimensionnement...';
   NeedStatRedraw := True;
   Exit;
  End;
 End;
 Idx := ShapeAt(Mouse.X, Mouse.Y);
 If Idx > 0 Then Begin
  CurShape := Idx;
  P := Pres.Slides[CurSlide]^.Shapes[Idx];
  DragMode     := 1;
  DragShapeIdx := Idx;
  DragStartX   := Mouse.X; DragStartY := Mouse.Y;
  DragOrigX    := P^.X; DragOrigY := P^.Y;
  LastMouseX   := Mouse.X; LastMouseY := Mouse.Y;
  StatusMsg    := 'Deplacement...';
  NeedSlideRedraw := True;
  NeedStatRedraw  := True;
 End Else Begin
  { Aucune forme : marquee }
  CurShape := 0;
  DragMode    := 4;
  DragStartX  := Mouse.X; DragStartY := Mouse.Y;
  LastMouseX  := Mouse.X; LastMouseY := Mouse.Y;
  RubberValid := False;
  NeedSlideRedraw := True;
 End;
End;

Procedure HandleMouseClick;
Var T, M: Integer; Idx: Integer;
Begin
 { Barre de menu }
 If InRect(Mouse.X, Mouse.Y, 0, MenuY1, SCREEN_W - 1, MenuY2) Then Begin
  HandleMenuBarClick; Exit;
 End;
 { Menu deroulant ouvert }
 If MenuOpen <> 0 Then Begin
  HandleDropDownClick; Exit;
 End;
 { Barre d'outils }
 If InRect(Mouse.X, Mouse.Y, 0, ToolY1, SCREEN_W - 1, ToolY2) Then Begin
  T := ToolAt(Mouse.X, Mouse.Y);
  If T > 0 Then Begin
   If Tools[T].Action <> 0 Then DoAction(Tools[T].Action);
  End;
  Exit;
 End;
 { Panneau miniatures }
 If InRect(Mouse.X, Mouse.Y, 0, MENU_H + TOOL_H, PANEL_W - 1,
           SCREEN_H - STATUS_H - 1) Then Begin
  Idx := SlideAtPanelY(Mouse.Y);
  If Idx > 0 Then Begin
   CurSlide := Idx; CurShape := 0; NeedFullRedraw := True;
  End;
  Exit;
 End;
 { Zone de slide }
 If InRect(Mouse.X, Mouse.Y, PANEL_W, MENU_H + TOOL_H + RULER_H,
           SCREEN_W - 1, SCREEN_H - STATUS_H - 1) Then Begin
  Case CurView Of
   VIEW_SORTER: Begin
    Idx := SorterAt(Mouse.X, Mouse.Y);
    If Idx > 0 Then Begin
     SorterSel := Idx; CurSlide := Idx; CurShape := 0;
     If DoubleClicked Then ActionViewChange(VIEW_NORMAL)
     Else NeedFullRedraw := True;
    End;
    Exit;
   End;
   VIEW_OUTLINE: Begin
    Idx := OutlineSlideAtY(Mouse.Y);
    If Idx > 0 Then Begin
     OutlineSel := Idx; CurSlide := Idx; CurShape := 0;
     If DoubleClicked Then ActionViewChange(VIEW_NORMAL)
     Else NeedFullRedraw := True;
    End;
    Exit;
   End;
   VIEW_NOTES: Begin
    If DoubleClicked Then ActionEditNotes;
    Exit;
   End;
  End;
  HandleSlideAreaClick; Exit;
 End;
 { Clic ailleurs : referme menu si actif }
 If MenuOpen <> 0 Then Begin
  MenuOpen := 0; NeedFullRedraw := True;
 End;
 M := 0; { evite avertissement variable inutilisee }
End;

Procedure UpdateHovers;
Var T, M: Integer;
Begin
 T := 0; M := 0;
 If InRect(Mouse.X, Mouse.Y, 0, MenuY1, SCREEN_W - 1, MenuY2) Then
  M := MenuAtX(Mouse.X);
 If MenuHover <> M Then Begin
  MenuHover := M;
  If MenuOpen = 0 Then DrawMenuBar;
 End;
 If InRect(Mouse.X, Mouse.Y, 0, ToolY1, SCREEN_W - 1, ToolY2) Then
  T := ToolAt(Mouse.X, Mouse.Y);
 If ToolHover <> T Then Begin
  ToolHover := T;
  DrawToolBar;
  If T > 0 Then Begin
   StatusMsg := Tools[T].Hint;
   NeedStatRedraw := True;
  End;
 End;
 { Met a jour la position dans la status bar quand on est sur la slide }
 If InRect(Mouse.X, Mouse.Y, SlideX1, SlideY1, SlideX2, SlideY2) Then Begin
  { rien pour Phase 1 }
 End;
End;

{ ====================================================================== }
{                       GESTION CLAVIER                                  }
{ ====================================================================== }

Procedure HandleKey(K, K2: Char);
Begin
 { ----- MODE EDITION TEXTE : priorite absolue ----- }
 If EditMode Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #75: EditMoveCaret(-1);            { Left }
    #77: EditMoveCaret(+1);            { Right }
    #72: EditMoveLine(-1);             { Up }
    #80: EditMoveLine(+1);             { Down }
    #71: EditHomeEnd(False);           { Home }
    #79: EditHomeEnd(True);            { End }
    #83: EditDeleteChar;               { Delete }
    #15: EditIndent(+1);               { Shift+Tab in some maps - here Tab key }
    #59: DoAction(ACT_HELP_TOPIC);     { F1 }
    #107,#45: Begin ExitEditMode; DoAction(ACT_QUIT); End;
   End;
   Exit;
  End;
  Case K Of
   #27: ExitEditMode;
   #13: EditNewLine;
   #8 : Begin
    If EditCaret > 0 Then EditBackspace Else EditBackLine;
   End;
   #9 : EditIndent(+1);
  Else Begin
   If (K >= ' ') And (K <= #126) Then EditInsertChar(K)
   Else If K >= #128 Then EditInsertChar(K);  { caracteres etendus 8 bits }
  End;
  End;
  Exit;
 End;
 { ----- MODES TRIEUSE / PLAN / NOTES ----- }
 If CurView = VIEW_SORTER Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #75: If SorterSel > 1 Then Begin Dec(SorterSel); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #77: If SorterSel < Pres.SldCount Then Begin Inc(SorterSel); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #72: If SorterSel > SORT_COLS Then Begin Dec(SorterSel, SORT_COLS); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #80: If SorterSel + SORT_COLS <= Pres.SldCount Then Begin Inc(SorterSel, SORT_COLS); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #71: Begin SorterSel := 1; CurSlide := 1; NeedFullRedraw := True; End;
    #79: Begin SorterSel := Pres.SldCount; CurSlide := SorterSel; NeedFullRedraw := True; End;
    #83: Begin DoAction(ACT_DEL_SLIDE); Exit; End;
    #107,#45: Begin DoAction(ACT_QUIT); Exit; End;
   End;
   Exit;
  End;
  Case K Of
   #13: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
   #27: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
  End;
  { Tombe en raccourcis globaux pour Ctrl+* }
 End;
 If CurView = VIEW_OUTLINE Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #72: If OutlineSel > 1 Then Begin Dec(OutlineSel); CurSlide := OutlineSel; NeedFullRedraw := True; End;
    #80: If OutlineSel < Pres.SldCount Then Begin Inc(OutlineSel); CurSlide := OutlineSel; NeedFullRedraw := True; End;
    #71: Begin OutlineSel := 1; CurSlide := 1; NeedFullRedraw := True; End;
    #79: Begin OutlineSel := Pres.SldCount; CurSlide := OutlineSel; NeedFullRedraw := True; End;
    #73: Begin Dec(OutlineScroll, 80); If OutlineScroll < 0 Then OutlineScroll := 0; NeedFullRedraw := True; End;
    #81: Begin Inc(OutlineScroll, 80); NeedFullRedraw := True; End;
    #107,#45: Begin DoAction(ACT_QUIT); Exit; End;
   End;
   Exit;
  End;
  Case K Of
   #13: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
   #27: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
  End;
 End;
 If CurView = VIEW_NOTES Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #73,#75: ActionPrevSlide;
    #81,#77: ActionNextSlide;
    #71: ActionFirstSlide;
    #79: ActionLastSlide;
    #107,#45: DoAction(ACT_QUIT);
   End;
   Exit;
  End;
  Case K Of
   #13: Begin ActionEditNotes; Exit; End;
   #27: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
  End;
 End;
 { Raccourcis globaux }
 If K = #0 Then Begin
  Case K2 Of
   #107: Begin DoAction(ACT_QUIT);        Exit; End;   { Alt+F4 }
   #45 : Begin DoAction(ACT_QUIT);        Exit; End;   { Alt+X  }
   #59 : Begin DoAction(ACT_HELP_TOPIC);  Exit; End;   { F1 }
   #63 : Begin DoAction(ACT_SLIDESHOW);   Exit; End;   { F5 }
   #50 : Begin DoAction(ACT_NEW_SLIDE);   Exit; End;   { Ctrl+M : scan 50 = M }
   #15 : Begin                                          { Tab : cycle forme }
    CycleShapeSelection(False); Exit;
   End;
   #83 : Begin                                          { Delete }
    If CurShape > 0 Then DoAction(ACT_DELETE);
    Exit;
   End;
   #80 : Begin
    If CurShape > 0 Then NudgeShape(0,  10) Else ActionNextSlide; Exit;
   End;
   #72 : Begin
    If CurShape > 0 Then NudgeShape(0, -10) Else ActionPrevSlide; Exit;
   End;
   #77 : Begin
    If CurShape > 0 Then NudgeShape( 10, 0) Else ActionNextSlide; Exit;
   End;
   #75 : Begin
    If CurShape > 0 Then NudgeShape(-10, 0) Else ActionPrevSlide; Exit;
   End;
   #81 : Begin ActionNextSlide;           Exit; End;   { PgDn }
   #73 : Begin ActionPrevSlide;           Exit; End;   { PgUp }
   #71 : Begin ActionFirstSlide;          Exit; End;   { Home }
   #79 : Begin ActionLastSlide;           Exit; End;   { End }
  End;
  Exit;
 End;
 Case K Of
  #27: Begin
   If MenuOpen <> 0 Then Begin MenuOpen := 0; NeedFullRedraw := True; End
   Else If DragMode <> 0 Then Begin
    HideMouse; EraseRubberBand; ShowMouse;
    DragMode := 0; DragHandle := 0; NeedSlideRedraw := True;
    StatusMsg := 'Annule.'; NeedStatRedraw := True;
   End
   Else If CurTool <> TOOL_SELECT Then Begin
    SetTool(TOOL_SELECT);
   End
   Else If CurShape > 0 Then Begin CurShape := 0; NeedSlideRedraw := True; End;
  End;
  #14:  DoAction(ACT_NEW);                          { Ctrl+N }
  #15:  DoAction(ACT_OPEN);                         { Ctrl+O }
  #19:  DoAction(ACT_SAVE);                         { Ctrl+S }
  #16:  DoAction(ACT_PRINT);                        { Ctrl+P }
  #26:  DoAction(ACT_UNDO);                         { Ctrl+Z }
  #25:  DoAction(ACT_REDO);                         { Ctrl+Y }
  #24:  DoAction(ACT_CUT);                          { Ctrl+X }
  #3:   DoAction(ACT_COPY);                         { Ctrl+C }
  #22:  DoAction(ACT_PASTE);                        { Ctrl+V }
  #6:   DoAction(ACT_FIND);                         { Ctrl+F }
  #4:   DoAction(ACT_DUP);                          { Ctrl+D }
  #1:   DoAction(ACT_SELECTALL);                    { Ctrl+A }
 End;
End;

{ ====================================================================== }
{                       BOUCLE PRINCIPALE                                }
{ ====================================================================== }

Procedure MainLoop;
Var K, K2: Char;
Begin
 NeedFullRedraw := True;
 Redraw;
 ShowMouse;
 Repeat
  Inc(TickCount);
  If (TickCount Mod 8) = 0 Then Begin
   BlinkState := Not BlinkState;
   If EditMode Then NeedSlideRedraw := True;
  End;
  UpdateMouse;
  UpdateHovers;
  If LeftPressed Then HandleMouseClick;
  If LeftDown And (DragMode <> 0) Then UpdateDrag;
  If LeftReleased And (DragMode <> 0) Then EndDrag;
  K := #0; K2 := #0;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then K2 := ReadKey;
   HandleKey(K, K2);
  End;
  Redraw;
  Delay(20);
 Until Quitting;
End;

{ ====================================================================== }
{                       SPLASH                                           }
{ ====================================================================== }

Procedure ShowSplash;
Var T0: LongInt; Done: Boolean; K: Char;
Begin
 HideMouse;
 FillBox(0, 0, SCREEN_W - 1, SCREEN_H - 1, CLR_RED);
 FillBox(80, 80, 559, 399, CLR_LGRAY);
 SetColor(CLR_BLACK); Rectangle(80, 80, 559, 399);
 FillBox(84, 84, 555, 130, CLR_RED);
 SetColor(CLR_WHITE);
 SetTextStyle(DefaultFont, HorizDir, 3);
 OutTextXY(110, 95, 'Office-0 PowerPnt');
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(CLR_BLACK);
 OutTextXY(120, 160, 'Clone Pascal de Microsoft PowerPoint');
 OutTextXY(120, 180, 'Version 0.10 - Phase 1 (2026)');
 OutTextXY(120, 200, '(c) Sylvain Maltais  -  www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(120, 240, 'Formats supportes : .PPT, .PPTX (a venir)');
 OutTextXY(120, 256, 'Compilateur : Free Pascal 3.2 (-Mtp)');
 OutTextXY(120, 272, 'Affichage : VGA 640 x 480 x 16');
 SetColor(CLR_BLACK);
 OutTextXY(120, 360, 'Appuyez sur une touche ou cliquez pour continuer...');
 ShowMouse;
 T0 := TickCount;
 Done := False;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey; If K = #0 Then ReadKey; Done := True;
  End;
  If LeftPressed Then Done := True;
  If (TickCount - T0) > 60 Then Done := True;
  Delay(20);
 Until Done;
End;

{ ====================================================================== }
{                       PROGRAMME PRINCIPAL                              }
{ ====================================================================== }

Var
 CmdFName: String;

Begin
 InitializeGraphics;
 If Not MouseDriverFound Then Begin
  CloseGraph;
  WriteLn('Aucun pilote de souris detecte.');
  Halt(1);
 End;
 SetTextStyle(DefaultFont, HorizDir, 1);
 ShowSplash;
 InitMenus;
 InitTools;
 InitPresentation;
 If ParamCount >= 1 Then Begin
  CmdFName := ParamStr(1);
  { Phase 1 : on charge juste le nom dans la presentation, vrai loader en
    phases 10/11 (.PPT / .PPTX). }
  Pres.FileName := CmdFName;
  SeedSamplePresentation;
  StatusMsg := 'Charge (factice) : ' + CmdFName;
 End
 Else Begin
  SeedSamplePresentation;
  StatusMsg := 'Pret';
 End;
 CurView    := VIEW_NORMAL;
 CurTool    := TOOL_SELECT;
 MenuOpen   := 0;
 MenuHover  := 0;
 ToolHover  := 0;
 EditMode   := False;
 BlinkState := True;
 Quitting   := False;
 TickCount  := 0;
 PanelScroll   := 0;
 SorterScroll  := 0;
 SorterSel     := 0;
 OutlineScroll := 0;
 OutlineSel    := 0;
 MainLoop;
 HideMouse;
 FreePresentation;
 CloseGraph;
End.