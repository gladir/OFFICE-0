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
 ACT_EXPORT_PPTX  = 115;
 ACT_IMPORT_PPTX  = 116;
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
 MenuKbdActive  : Boolean;       { selection clavier active : ignore souris stationnaire }
 MenuKbdMx      : Integer;
 MenuKbdMy      : Integer;

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

{ Phase 12 : repaint d'une seule rangee d'item dans le menu deroulant ouvert
  (pas de cadre, pas d'ombre) -- evite le scintillement plein dropdown lors
  d'un simple changement de surlignage. }
Procedure DrawDropDownItem(I: Integer);
Var M, J, Y, Ih, Bg, Fg: Integer; S: String;
Begin
 If MenuOpen = 0 Then Exit;
 M := MenuOpen;
 If (I < 1) Or (I > Menus[M].Count) Then Exit;
 If Menus[M].Items[I].IsSep Then Exit;
 Y := DropY + 2;
 For J := 1 To I - 1 Do Y := Y + DropItemH(M, J);
 Ih := DropItemH(M, I);
 If I = MenuItemHover Then Begin Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG; End
 Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
 HideMouse;
 FillBox(DropX + 2, Y, DropX + DropW - 2, Y + Ih - 1, Bg);
 SetColor(Fg);
 OutTextXY(DropX + 8, Y + 2, Menus[M].Items[I].Caption);
 S := Menus[M].Items[I].Shortcut;
 If S <> '' Then
  OutTextXY(DropX + DropW - TextWidth(S) - 8, Y + 2, S);
 ShowMouse;
End;

{ Phase 12 : change l'item survole sans repeindre tout le dropdown. }
Procedure SetMenuItemHover(NewSel: Integer);
Var Old: Integer;
Begin
 If MenuOpen = 0 Then Exit;
 If NewSel = MenuItemHover Then Exit;
 Old := MenuItemHover;
 MenuItemHover := NewSel;
 If Old <> 0 Then DrawDropDownItem(Old);
 If NewSel <> 0 Then DrawDropDownItem(NewSel);
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
Var Pos: Integer;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FreePresentation;
 InitPresentation;
 { Phase 12 fix : "Nouveau" doit creer une presentation VIDE (une seule
   diapo de titre blanche), pas re-injecter l'exemple de 4 pages. }
 Pos := AddSlideAt(1);
 If Pos > 0 Then ApplyLayout(Pres.Slides[Pos], LAY_TITLE_ONLY);
 CurSlide := 1;
 CurShape := 0;
 Pres.Dirty := False;
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
 OutTextXY(X1 + 20, Y1 + 80, 'Version 1.0 - 2026 (Phase 12 finale)');
 OutTextXY(X1 + 20, Y1 + 96, '(c) Sylvain Maltais  www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 20, Y1 + 120,'Clone complet : 12 phases livrees');
 OutTextXY(X1 + 20, Y1 + 136,'Formats : .PPT natif, .PPTX, .BMP, .PCX, .PRN');
 OutTextXY(X1 + 20, Y1 + 152,'Free Pascal 3.2 (-Mtp) - VGA 640 x 480 x 16');
 OutTextXY(X1 + 20, Y1 + 176,'F5 Diaporama  Ctrl+P Imprimer  Ctrl+E Exporter');
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

{ ====================================================================== }
{          PHASE 10 : FORMAT .PPT NATIF + DIALOGUES FICHIER              }
{ ====================================================================== }

Var
 PPTBuf : Array[0..511] Of Byte;

{ ----- I/O binaire little-endian sur File untyped (record size = 1) --- }

Procedure WrB(Var F:File; B:Byte);
Begin PPTBuf[0]:=B; BlockWrite(F,PPTBuf,1); End;

Procedure WrW(Var F:File; W:Word);
Begin
 PPTBuf[0] := Byte(W And $FF);
 PPTBuf[1] := Byte((W Shr 8) And $FF);
 BlockWrite(F, PPTBuf, 2);
End;

Procedure WrI(Var F:File; I:Integer);
Begin WrW(F, Word(I)); End;

Procedure WrS(Var F:File; Const S:String);
Var L:Integer;
Begin
 L := Length(S);
 If L > 255 Then L := 255;
 WrB(F, Byte(L));
 If L > 0 Then BlockWrite(F, S[1], L);
End;

Function RdB(Var F:File):Byte;
Begin
 BlockRead(F, PPTBuf, 1);
 RdB := PPTBuf[0];
End;

Function RdW(Var F:File):Word;
Begin
 BlockRead(F, PPTBuf, 2);
 RdW := Word(PPTBuf[0]) Or (Word(PPTBuf[1]) Shl 8);
End;

Function RdI(Var F:File):Integer;
Begin RdI := Integer(RdW(F)); End;

Procedure RdS(Var F:File; Var S:String);
Var L:Byte;
Begin
 BlockRead(F, L, 1);
 S[0] := Char(L);
 If L > 0 Then BlockRead(F, S[1], L);
End;

{ ----- Ecriture du fichier .PPT natif --------------------------------- }

Function SavePresentationFile(Const FN: String): Boolean;
Var F: File; I, J, K: Integer; S: PSlide; Sh: PShape; Img: PImage;
    Magic: Array[1..4] Of Char;
    PixSize: LongInt;
Begin
 SavePresentationFile := False;
 Assign(F, FN);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 Magic[1]:='P'; Magic[2]:='P'; Magic[3]:='N'; Magic[4]:='T';
 BlockWrite(F, Magic, 4);
 WrB(F, 1);                         { version }
 WrB(F, 0); WrB(F, 0); WrB(F, 0);   { reserve }

 WrS(F, Pres.Name);
 WrS(F, Pres.Author);
 WrS(F, Pres.Company);
 WrS(F, Pres.Title);
 WrS(F, Pres.Subject);
 WrS(F, Pres.Comments);
 WrS(F, Pres.HeaderText);
 WrS(F, Pres.FooterText);
 WrS(F, Pres.DateText);
 WrB(F, Byte(Pres.ShowHeader));
 WrB(F, Byte(Pres.ShowFooter));
 WrB(F, Byte(Pres.ShowDate));
 WrB(F, Byte(Pres.ShowSlideNum));
 WrB(F, Pres.MasterBg);
 WrB(F, Pres.MasterTitleC);
 WrB(F, Pres.MasterTextC);
 WrW(F, Word(Pres.ThemeIdx));

 { Images : 16 slots, marker 0/1 par slot }
 WrW(F, Word(Pres.ImgCount));
 For I := 1 To MAX_IMAGES Do Begin
  Img := Pres.Images[I];
  If Img = Nil Then WrB(F, 0)
  Else Begin
   WrB(F, 1);
   WrS(F, Img^.Name);
   WrS(F, Img^.FileName);
   WrW(F, Word(Img^.W));
   WrW(F, Word(Img^.H));
   WrB(F, Byte(Img^.Loaded));
   If Img^.Loaded And (Img^.Pixels <> Nil) And
      (Img^.W > 0) And (Img^.H > 0) Then Begin
    PixSize := LongInt(Img^.W) * Img^.H;
    BlockWrite(F, Img^.Pixels^, PixSize);
   End;
  End;
 End;

 { Slides }
 WrW(F, Word(Pres.SldCount));
 For I := 1 To Pres.SldCount Do Begin
  S := Pres.Slides[I];
  If S <> Nil Then Begin
   WrS(F, S^.Name);
   WrS(F, S^.Title);
   WrB(F, S^.Layout);
   WrB(F, S^.Background);
   WrB(F, S^.Theme);
   WrB(F, S^.Transition);
   WrB(F, S^.TransSpeed);
   WrS(F, S^.Notes);
   WrB(F, Byte(S^.Hidden));
   WrW(F, Word(S^.ShCount));
   For J := 1 To S^.ShCount Do Begin
    Sh := S^.Shapes[J];
    If Sh <> Nil Then Begin
     WrS(F, Sh^.Name);
     WrB(F, Sh^.ShType);
     WrI(F, Sh^.X);  WrI(F, Sh^.Y);
     WrI(F, Sh^.W);  WrI(F, Sh^.H);
     WrB(F, Sh^.FillColor);
     WrB(F, Sh^.LineColor);
     WrB(F, Sh^.LineWidth);
     WrB(F, Byte(Sh^.Filled));
     WrI(F, Sh^.Rotation);
     WrI(F, Sh^.ZOrder);
     WrB(F, Byte(Sh^.Locked));
     WrB(F, Byte(Sh^.Hidden));
     WrB(F, Byte(Sh^.TxtCount));
     For K := 1 To Sh^.TxtCount Do Begin
      WrS(F, Sh^.Text[K]);
      WrB(F, Byte(Sh^.Bullets[K]));
      WrB(F, Sh^.Indent[K]);
     End;
     WrB(F, Byte(Sh^.Bold));
     WrB(F, Byte(Sh^.Italic));
     WrB(F, Byte(Sh^.Underline));
     WrB(F, Sh^.FontSize);
     WrB(F, Sh^.TextColor);
     WrB(F, Sh^.Align);
     WrW(F, Word(Sh^.ImageIdx));
     WrB(F, Sh^.AnimEntry);
     WrB(F, Sh^.AnimExit);
     WrB(F, Sh^.AnimOrder);
    End;
   End;
  End;
 End;
 Close(F);
 SavePresentationFile := True;
End;

{ ----- Lecture du fichier .PPT natif ---------------------------------- }

Function LoadPresentationFile(Const FN: String): Boolean;
Var F: File;
    I, J, K: Integer;
    NImg, NSld, NSh, NTxt: Integer;
    S: PSlide; Sh: PShape; Img: PImage;
    Magic: Array[1..4] Of Char;
    Version, Marker: Byte;
    PixSize: LongInt;
    StrBuf: String;
Begin
 LoadPresentationFile := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockRead(F, Magic, 4); {$I+}
 If (IOResult <> 0) Or
    (Magic[1] <> 'P') Or (Magic[2] <> 'P') Or
    (Magic[3] <> 'N') Or (Magic[4] <> 'T') Then Begin
  Close(F); Exit;
 End;
 Version := RdB(F);
 If Version <> 1 Then Begin Close(F); Exit; End;
 RdB(F); RdB(F); RdB(F);

 FreePresentation;
 InitPresentation;

 RdS(F, StrBuf); Pres.Name        := StrBuf;
 RdS(F, StrBuf); Pres.Author      := StrBuf;
 RdS(F, StrBuf); Pres.Company     := StrBuf;
 RdS(F, StrBuf); Pres.Title       := StrBuf;
 RdS(F, StrBuf); Pres.Subject     := StrBuf;
 RdS(F, StrBuf); Pres.Comments    := StrBuf;
 RdS(F, StrBuf); Pres.HeaderText  := StrBuf;
 RdS(F, StrBuf); Pres.FooterText  := StrBuf;
 RdS(F, StrBuf); Pres.DateText    := StrBuf;
 Pres.ShowHeader   := RdB(F) <> 0;
 Pres.ShowFooter   := RdB(F) <> 0;
 Pres.ShowDate     := RdB(F) <> 0;
 Pres.ShowSlideNum := RdB(F) <> 0;
 Pres.MasterBg     := RdB(F);
 Pres.MasterTitleC := RdB(F);
 Pres.MasterTextC  := RdB(F);
 Pres.ThemeIdx     := Integer(RdW(F));

 { Images }
 NImg := Integer(RdW(F));
 Pres.ImgCount := NImg;
 For I := 1 To MAX_IMAGES Do Begin
  Marker := RdB(F);
  If Marker = 0 Then Pres.Images[I] := Nil
  Else Begin
   New(Img);
   RdS(F, StrBuf); Img^.Name     := StrBuf;
   RdS(F, StrBuf); Img^.FileName := StrBuf;
   Img^.W := Integer(RdW(F));
   Img^.H := Integer(RdW(F));
   Img^.Loaded := RdB(F) <> 0;
   Img^.Pixels := Nil;
   If Img^.Loaded And (Img^.W > 0) And (Img^.H > 0) Then Begin
    PixSize := LongInt(Img^.W) * Img^.H;
    GetMem(Img^.Pixels, PixSize);
    BlockRead(F, Img^.Pixels^, PixSize);
   End;
   Pres.Images[I] := Img;
  End;
 End;

 { Slides }
 NSld := Integer(RdW(F));
 If NSld > MAX_SLIDES Then NSld := MAX_SLIDES;
 For I := 1 To NSld Do Begin
  S := NewSlide;
  RdS(F, StrBuf); S^.Name  := StrBuf;
  RdS(F, StrBuf); S^.Title := StrBuf;
  S^.Layout     := RdB(F);
  S^.Background := RdB(F);
  S^.Theme      := RdB(F);
  S^.Transition := RdB(F);
  S^.TransSpeed := RdB(F);
  RdS(F, StrBuf); S^.Notes := StrBuf;
  S^.Hidden := RdB(F) <> 0;
  NSh := Integer(RdW(F));
  If NSh > MAX_SHAPES Then NSh := MAX_SHAPES;
  For J := 1 To NSh Do Begin
   Sh := NewShape;
   RdS(F, StrBuf); Sh^.Name := StrBuf;
   Sh^.ShType    := RdB(F);
   Sh^.X := Integer(RdW(F));  Sh^.Y := Integer(RdW(F));
   Sh^.W := Integer(RdW(F));  Sh^.H := Integer(RdW(F));
   Sh^.FillColor := RdB(F);
   Sh^.LineColor := RdB(F);
   Sh^.LineWidth := RdB(F);
   Sh^.Filled    := RdB(F) <> 0;
   Sh^.Rotation  := Integer(RdW(F));
   Sh^.ZOrder    := Integer(RdW(F));
   Sh^.Locked    := RdB(F) <> 0;
   Sh^.Hidden    := RdB(F) <> 0;
   NTxt := RdB(F);
   Sh^.TxtCount := NTxt;
   If NTxt > MAX_TEXT_LINES Then NTxt := MAX_TEXT_LINES;
   For K := 1 To NTxt Do Begin
    RdS(F, StrBuf); Sh^.Text[K] := StrBuf;
    Sh^.Bullets[K] := RdB(F) <> 0;
    Sh^.Indent[K]  := RdB(F);
   End;
   Sh^.Bold      := RdB(F) <> 0;
   Sh^.Italic    := RdB(F) <> 0;
   Sh^.Underline := RdB(F) <> 0;
   Sh^.FontSize  := RdB(F);
   Sh^.TextColor := RdB(F);
   Sh^.Align     := RdB(F);
   Sh^.ImageIdx  := Integer(RdW(F));
   Sh^.AnimEntry := RdB(F);
   Sh^.AnimExit  := RdB(F);
   Sh^.AnimOrder := RdB(F);
   AddShapeToSlide(S, Sh);
  End;
  Pres.Slides[I] := S;
 End;
 Pres.SldCount := NSld;
 Close(F);
 Pres.FileName := FN;
 Pres.Dirty    := False;
 If Pres.SldCount > 0 Then CurSlide := 1 Else CurSlide := 0;
 CurShape := 0;
 LoadPresentationFile := True;
End;

{ ====================================================================== }
{   DIALOGUE DE SELECTION DE FICHIER (Phase 12 - style Office classique)  }
{                                                                        }
{   - Champ "Nom du fichier" editable (avec caret clignotant)            }
{   - Combo "Type" cyclable : *.PPT / *.PPTX / *.PRN / *.*               }
{   - Affichage du repertoire courant ("Chercher dans :")                }
{   - Listbox "Fichiers" (filtree par le combo Type)                     }
{   - Listbox "Dossiers et lecteurs" : [..], [SOUS-DOSSIER], [-A-]..[-Z-]}
{   - Boutons "Aller dans le parent", "OK", "Annuler"                    }
{   - Navigation clavier : Tab/Shift+Tab pour le focus, fleches dans     }
{     les listes, Entree active, Esc annule, frappe edite le nom         }
{   - Navigation souris : simple clic = selection, double clic = activer }
{   - Mise a jour automatique de la liste apres chaque ChDir/changement  }
{     de filtre                                                          }
{ ====================================================================== }

Function FileSelectDlg(Const Title: String;
                       Var FN: String; ForSave: Boolean): Boolean;
Const
 FDM_FILES  = 256;             { capacite listbox fichiers }
 FDM_DIRS   = 96;              { capacite listbox dossiers+lecteurs }
 FDM_FILT   = 4;               { nombre de filtres }
 ROW_H      = 10;              { hauteur ligne listbox }
 DBL_TICKS  = 18;              { fenetre de double-clic (ticks ~20ms) }
Type
 TFileE = String[14];
 TDirE  = String[18];
Var
 { ----- Geometrie du dialogue ----- }
 X1, Y1, X2, Y2: Integer;
 NeX1, NeY1, NeX2, NeY2: Integer;        { name edit }
 FcX1, FcY1, FcX2, FcY2: Integer;        { filter combo }
 FlX1, FlY1, FlX2, FlY2: Integer;        { files listbox }
 DlX1, DlY1, DlX2, DlY2: Integer;        { dirs listbox }
 OkX1, OkY1, OkX2, OkY2: Integer;        { OK button }
 CnX1, CnY1, CnX2, CnY2: Integer;        { Cancel button }
 UpX1, UpY1, UpX2, UpY2: Integer;        { "parent dir" button }
 RefX1, RefY1, RefX2, RefY2: Integer;    { "refresh" button }

 { ----- Etat ----- }
 FiltMasks: Array[1..FDM_FILT] Of String[16];
 FiltNames: Array[1..FDM_FILT] Of String[44];
 FiltIdx  : Integer;

 CurDir   : String;

 Files    : Array[1..FDM_FILES] Of TFileE;
 FilesCnt : Integer;
 FilesSel : Integer;
 FilesScr : Integer;

 Dirs     : Array[1..FDM_DIRS] Of TDirE;
 DirsCnt  : Integer;
 DirsSel  : Integer;
 DirsScr  : Integer;

 NameBuf  : String;
 NameCaret: Integer;

 Focus    : Integer;        { 0=name 1=files 2=dirs 3=filter 4=ok 5=cancel }
 ResultOK : Boolean;
 Done     : Boolean;
 VisRows  : Integer;

 K, K2    : Char;
 SR       : SearchRec;
 I, J     : Integer;
 D        : Byte;
 Drv      : Char;
 TmpF     : TFileE;
 TmpD     : TDirE;
 TmpS     : String;
 ADir, AName, AExt: String;

 LastClickTick  : LongInt;
 LastClickField : Integer;
 LastClickIdx   : Integer;
 NowTick        : LongInt;
 IoR            : Integer;
 OldDir         : String;
 NewSel         : Integer;

 { -------------------------------------------------------------------- }
 {                          Helpers de scan                              }
 { -------------------------------------------------------------------- }

 Procedure ScanFiles;
 Var II, JJ: Integer; TF: TFileE;
 Begin
  FilesCnt := 0; FilesSel := 0; FilesScr := 0;
  FindFirst(FiltMasks[FiltIdx], $20, SR);
  While (DosError = 0) And (FilesCnt < FDM_FILES) Do Begin
   If ((SR.Attr And $18) = 0) Then Begin    { exclure dirs/volume }
    Inc(FilesCnt);
    Files[FilesCnt] := Copy(SR.Name, 1, 14);
   End;
   FindNext(SR);
  End;
  FindClose(SR);
  For II := 2 To FilesCnt Do Begin
   TF := Files[II]; JJ := II - 1;
   While (JJ >= 1) And (Files[JJ] > TF) Do Begin
    Files[JJ + 1] := Files[JJ]; Dec(JJ);
   End;
   Files[JJ + 1] := TF;
  End;
  If FilesCnt > 0 Then FilesSel := 1;
 End;

 Procedure ScanDirs;
 Var II, JJ, FirstSort: Integer; TD: TDirE;
     HasUp: Boolean; Drv2: Char; D2: Byte;
 Begin
  DirsCnt := 0; DirsSel := 0; DirsScr := 0;
  HasUp := False;
  FindFirst('*.*', $10, SR);
  While (DosError = 0) And (DirsCnt < FDM_DIRS - 28) Do Begin
   If ((SR.Attr And $10) <> 0) And (SR.Name <> '') And (SR.Name <> '.') Then
   Begin
    If SR.Name = '..' Then Begin
     If Not HasUp Then Begin
      Inc(DirsCnt); Dirs[DirsCnt] := '[..]'; HasUp := True;
     End;
    End Else Begin
     Inc(DirsCnt); Dirs[DirsCnt] := '[' + Copy(SR.Name, 1, 16) + ']';
    End;
   End;
   FindNext(SR);
  End;
  FindClose(SR);
  { Tri : on conserve [..] en tete s'il existe. }
  FirstSort := 1;
  If (DirsCnt > 0) And (Dirs[1] = '[..]') Then FirstSort := 2;
  For II := FirstSort + 1 To DirsCnt Do Begin
   TD := Dirs[II]; JJ := II - 1;
   While (JJ >= FirstSort) And (Dirs[JJ] > TD) Do Begin
    Dirs[JJ + 1] := Dirs[JJ]; Dec(JJ);
   End;
   Dirs[JJ + 1] := TD;
  End;
  { Lecteurs disponibles en queue de liste. }
  For Drv2 := 'A' To 'Z' Do Begin
   D2 := Ord(Drv2) - Ord('A') + 1;
   {$I-} II := 0; If DiskSize(D2) > 0 Then II := 1; {$I+}
   If IOResult <> 0 Then II := 0;
   If (II = 1) And (DirsCnt < FDM_DIRS) Then Begin
    Inc(DirsCnt);
    Dirs[DirsCnt] := '[-' + Drv2 + '-]';
   End;
  End;
  If DirsCnt > 0 Then DirsSel := 1;
 End;

 Procedure RefreshCurDir;
 Begin
  {$I-} GetDir(0, CurDir); {$I+}
  If IOResult <> 0 Then CurDir := '?:\';
 End;

 Procedure FullRefresh;
 Begin
  RefreshCurDir;
  ScanFiles;
  ScanDirs;
 End;

 { -------------------------------------------------------------------- }
 {                          Helpers de dessin                            }
 { -------------------------------------------------------------------- }

 Procedure DrawFocusRect(Lx1, Ly1, Lx2, Ly2: Integer);
 Var Xi: Integer;
 Begin
  SetColor(CLR_BLACK);
  Xi := Lx1;
  While Xi <= Lx2 Do Begin PutPixel(Xi, Ly1, CLR_BLACK); Inc(Xi, 2); End;
  Xi := Lx1;
  While Xi <= Lx2 Do Begin PutPixel(Xi, Ly2, CLR_BLACK); Inc(Xi, 2); End;
  Xi := Ly1;
  While Xi <= Ly2 Do Begin PutPixel(Lx1, Xi, CLR_BLACK); Inc(Xi, 2); End;
  Xi := Ly1;
  While Xi <= Ly2 Do Begin PutPixel(Lx2, Xi, CLR_BLACK); Inc(Xi, 2); End;
 End;

 Procedure DrawNameEdit;
 Begin
  HideMouse;
  DlgEdit(NeX1, NeY1, NeX2, NeY2, NameBuf, Focus = 0, NameCaret);
  If Focus = 0 Then DrawFocusRect(NeX1 - 2, NeY1 - 2, NeX2 + 2, NeY2 + 2)
  Else Begin
   FillBox(NeX1 - 2, NeY1 - 2, NeX2 + 2, NeY1 - 1, CLR_DLG_BG);
   FillBox(NeX1 - 2, NeY2 + 1, NeX2 + 2, NeY2 + 2, CLR_DLG_BG);
   FillBox(NeX1 - 2, NeY1 - 1, NeX1 - 1, NeY2 + 1, CLR_DLG_BG);
   FillBox(NeX2 + 1, NeY1 - 1, NeX2 + 2, NeY2 + 1, CLR_DLG_BG);
  End;
  ShowMouse;
 End;

 Procedure DrawFilterCombo;
 Var ArX1, ArY1, ArX2, ArY2: Integer;
 Begin
  HideMouse;
  FillBox(FcX1, FcY1, FcX2, FcY2, CLR_WHITE);
  SetColor(CLR_WIN_LO); Rectangle(FcX1, FcY1, FcX2, FcY2);
  SetColor(CLR_BLACK);
  OutTextXY(FcX1 + 4, FcY1 + ((FcY2 - FcY1) - 8) Div 2,
            FiltNames[FiltIdx]);
  { fleche bas a droite }
  ArX2 := FcX2 - 2; ArX1 := ArX2 - 14;
  ArY1 := FcY1 + 2; ArY2 := FcY2 - 2;
  DrawRaised(ArX1, ArY1, ArX2, ArY2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
  SetColor(CLR_BLACK);
  Line(ArX1 + 4, ArY1 + 5, ArX2 - 4, ArY1 + 5);
  Line(ArX1 + 5, ArY1 + 6, ArX2 - 5, ArY1 + 6);
  Line(ArX1 + 6, ArY1 + 7, ArX2 - 6, ArY1 + 7);
  Line(ArX1 + 7, ArY1 + 8, ArX1 + 7, ArY1 + 8);
  If Focus = 3 Then
   DrawFocusRect(FcX1 - 2, FcY1 - 2, FcX2 + 2, FcY2 + 2)
  Else Begin
   FillBox(FcX1 - 2, FcY1 - 2, FcX2 + 2, FcY1 - 1, CLR_DLG_BG);
   FillBox(FcX1 - 2, FcY2 + 1, FcX2 + 2, FcY2 + 2, CLR_DLG_BG);
   FillBox(FcX1 - 2, FcY1 - 1, FcX1 - 1, FcY2 + 1, CLR_DLG_BG);
   FillBox(FcX2 + 1, FcY1 - 1, FcX2 + 2, FcY2 + 1, CLR_DLG_BG);
  End;
  ShowMouse;
 End;

 Procedure DrawListBox(Lx1, Ly1, Lx2, Ly2: Integer;
                       Count, Sel, Scroll, IsFocus: Integer;
                       IsDirs: Boolean);
 Var II, Y, MaxR, Vis: Integer; S: String;
     Bg, Fg: Integer;
 Begin
  HideMouse;
  DrawSunken(Lx1, Ly1, Lx2, Ly2, CLR_WHITE, CLR_WIN_HI, CLR_WIN_LO);
  Vis := (Ly2 - Ly1 - 4) Div ROW_H;
  If Vis < 1 Then Vis := 1;
  MaxR := Count;
  If MaxR > Vis Then MaxR := Vis;
  For II := 1 To MaxR Do Begin
   Y := Ly1 + 2 + (II - 1) * ROW_H;
   If (II + Scroll) > Count Then Break;
   If IsDirs Then S := Dirs[II + Scroll]
   Else           S := Files[II + Scroll];
   If (II + Scroll) = Sel Then Begin
    Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG;
    FillBox(Lx1 + 2, Y, Lx2 - 2, Y + ROW_H - 1, Bg);
   End Else Begin
    Bg := CLR_WHITE; Fg := CLR_BLACK;
   End;
   SetColor(Fg);
   OutTextXY(Lx1 + 6, Y + 1, S);
  End;
  If IsFocus = 1 Then
   DrawFocusRect(Lx1 - 2, Ly1 - 2, Lx2 + 2, Ly2 + 2)
  Else Begin
   FillBox(Lx1 - 2, Ly1 - 2, Lx2 + 2, Ly1 - 1, CLR_DLG_BG);
   FillBox(Lx1 - 2, Ly2 + 1, Lx2 + 2, Ly2 + 2, CLR_DLG_BG);
   FillBox(Lx1 - 2, Ly1 - 1, Lx1 - 1, Ly2 + 1, CLR_DLG_BG);
   FillBox(Lx2 + 1, Ly1 - 1, Lx2 + 2, Ly2 + 1, CLR_DLG_BG);
  End;
  ShowMouse;
 End;

 Procedure DrawFilesBox;
 Var F: Integer;
 Begin
  F := 0; If Focus = 1 Then F := 1;
  DrawListBox(FlX1, FlY1, FlX2, FlY2, FilesCnt, FilesSel, FilesScr, F, False);
 End;

 Procedure DrawDirsBox;
 Var F: Integer;
 Begin
  F := 0; If Focus = 2 Then F := 1;
  DrawListBox(DlX1, DlY1, DlX2, DlY2, DirsCnt, DirsSel, DirsScr, F, True);
 End;

 Procedure DrawButtons;
 Var Ts: String;
 Begin
  HideMouse;
  DlgBtn(OkX1, OkY1, OkX2, OkY2, 'OK',      False, Focus = 4);
  DlgBtn(CnX1, CnY1, CnX2, CnY2, 'Annuler', False, Focus = 5);
  DlgBtn(UpX1, UpY1, UpX2, UpY2, 'Parent',  False, False);
  DlgBtn(RefX1, RefY1, RefX2, RefY2, 'Actualiser', False, False);
  { affichage du chemin courant }
  FillBox(X1 + 110, Y1 + 64, X2 - 14, Y1 + 76, CLR_DLG_BG);
  SetColor(CLR_BLACK);
  Ts := CurDir;
  While TextWidth(Ts) > (X2 - 14) - (X1 + 110) - 4 Do
   Ts := Copy(Ts, 1, Length(Ts) - 1);
  OutTextXY(X1 + 112, Y1 + 66, Ts);
  ShowMouse;
 End;

 Procedure DrawAll;
 Begin
  DlgFrame(X1, Y1, X2, Y2, Title);
  HideMouse;
  SetColor(CLR_BLACK);
  OutTextXY(X1 + 14, Y1 + 26, 'Nom du fichier :');
  OutTextXY(X1 + 14, Y1 + 46, 'Type de fichier :');
  OutTextXY(X1 + 14, Y1 + 66, 'Chercher dans :');
  OutTextXY(FlX1, FlY1 - 12, 'Fichiers :');
  OutTextXY(DlX1, DlY1 - 12, 'Dossiers et lecteurs :');
  ShowMouse;
  DrawNameEdit;
  DrawFilterCombo;
  DrawFilesBox;
  DrawDirsBox;
  DrawButtons;
 End;

 { -------------------------------------------------------------------- }
 {                       Helpers d'interaction                           }
 { -------------------------------------------------------------------- }

 Procedure CycleFilter(Dir: Integer);
 Begin
  FiltIdx := FiltIdx + Dir;
  If FiltIdx < 1 Then FiltIdx := FDM_FILT;
  If FiltIdx > FDM_FILT Then FiltIdx := 1;
  ScanFiles;
  DrawFilterCombo;
  DrawFilesBox;
 End;

 Procedure SetFocus(NewF: Integer);
 Var Old: Integer;
 Begin
  If NewF < 0 Then NewF := 5;
  If NewF > 5 Then NewF := 0;
  If NewF = Focus Then Exit;
  Old := Focus; Focus := NewF;
  { repeint les deux widgets concernes pour effacer/poser le focus }
  Case Old Of
   0: DrawNameEdit;
   1: DrawFilesBox;
   2: DrawDirsBox;
   3: DrawFilterCombo;
   4, 5: DrawButtons;
  End;
  Case Focus Of
   0: DrawNameEdit;
   1: DrawFilesBox;
   2: DrawDirsBox;
   3: DrawFilterCombo;
   4, 5: DrawButtons;
  End;
 End;

 Procedure ScrollFilesTo(NewS: Integer);
 Begin
  If NewS < 1 Then NewS := 1;
  If NewS > FilesCnt Then NewS := FilesCnt;
  If FilesCnt = 0 Then Exit;
  FilesSel := NewS;
  If FilesSel < FilesScr + 1 Then FilesScr := FilesSel - 1;
  If FilesSel > FilesScr + VisRows Then FilesScr := FilesSel - VisRows;
  If FilesScr < 0 Then FilesScr := 0;
  NameBuf := Files[FilesSel];
  NameCaret := Length(NameBuf);
  DrawFilesBox;
  DrawNameEdit;
 End;

 Procedure ScrollDirsTo(NewS: Integer);
 Begin
  If NewS < 1 Then NewS := 1;
  If NewS > DirsCnt Then NewS := DirsCnt;
  If DirsCnt = 0 Then Exit;
  DirsSel := NewS;
  If DirsSel < DirsScr + 1 Then DirsScr := DirsSel - 1;
  If DirsSel > DirsScr + VisRows Then DirsScr := DirsSel - VisRows;
  If DirsScr < 0 Then DirsScr := 0;
  DrawDirsBox;
 End;

 Procedure ActivateDir(Idx: Integer);
 Var S, Inner: String; OkChg: Boolean;
 Begin
  If (Idx < 1) Or (Idx > DirsCnt) Then Exit;
  S := Dirs[Idx];
  OkChg := False;
  If S = '[..]' Then Begin
   {$I-} ChDir('..'); {$I+}
   If IOResult = 0 Then OkChg := True;
  End
  Else If (Length(S) >= 5) And (S[1] = '[') And (S[2] = '-') And
          (S[Length(S)] = ']') And (S[Length(S) - 1] = '-') Then Begin
   { lecteur "[-X-]" }
   Inner := S[3] + ':\';
   {$I-} ChDir(Inner); {$I+}
   If IOResult = 0 Then OkChg := True;
  End
  Else If (Length(S) >= 2) And (S[1] = '[') And
          (S[Length(S)] = ']') Then Begin
   Inner := Copy(S, 2, Length(S) - 2);
   {$I-} ChDir(Inner); {$I+}
   If IOResult = 0 Then OkChg := True;
  End;
  If OkChg Then FullRefresh
  Else Begin
   MessageBox('Ouvrir', 'Acces refuse a ' + S);
   { la MessageBox a tout salit -> on redessine le dialogue. }
   DrawAll;
   Exit;
  End;
  DrawNameEdit; DrawFilterCombo;
  DrawFilesBox; DrawDirsBox; DrawButtons;
 End;

 Function TryAccept: Boolean;
 Var Eff, Dr, Nm, Ex: String;
 Begin
  TryAccept := False;
  Eff := NameBuf;
  While (Length(Eff) > 0) And (Eff[1] = ' ') Do Delete(Eff, 1, 1);
  While (Length(Eff) > 0) And (Eff[Length(Eff)] = ' ') Do
   Delete(Eff, Length(Eff), 1);
  If Eff = '' Then Exit;
  { contient un wildcard => trate comme un changement de filtre custom }
  If (Pos('*', Eff) > 0) Or (Pos('?', Eff) > 0) Then Begin
   FiltMasks[FiltIdx] := Copy(Eff, 1, 16);
   FiltNames[FiltIdx] := 'Personnalise (' + Eff + ')';
   NameBuf := ''; NameCaret := 0;
   ScanFiles;
   DrawFilterCombo; DrawNameEdit; DrawFilesBox;
   Exit;
  End;
  { chemin absolu ou relatif vers un dossier => CD }
  FSplit(Eff, Dr, Nm, Ex);
  If (Dr <> '') And (Nm = '') And (Ex = '') Then Begin
   {$I-} ChDir(Dr); {$I+}
   If IOResult = 0 Then Begin
    FullRefresh; NameBuf := ''; NameCaret := 0;
    DrawAll;
   End Else MessageBox('Ouvrir', 'Dossier introuvable : ' + Eff);
   Exit;
  End;
  { ajoute extension par defaut si absente }
  If Pos('.', Nm + Ex) = 0 Then Begin
   Case FiltIdx Of
    1: Eff := Eff + '.PPT';
    2: Eff := Eff + '.PPTX';
    3: Eff := Eff + '.PRN';
   End;
  End;
  FN := Eff;
  ResultOK := True; Done := True;
  TryAccept := True;
 End;

 Procedure ActivateFile(Idx: Integer);
 Begin
  If (Idx < 1) Or (Idx > FilesCnt) Then Exit;
  NameBuf := Files[Idx];
  NameCaret := Length(NameBuf);
  If TryAccept Then ;
 End;

 Function FileIdxAtY(Yy: Integer): Integer;
 Var R: Integer;
 Begin
  FileIdxAtY := 0;
  If (Yy < FlY1 + 2) Or (Yy > FlY2 - 2) Then Exit;
  R := (Yy - FlY1 - 2) Div ROW_H + 1 + FilesScr;
  If (R >= 1) And (R <= FilesCnt) Then FileIdxAtY := R;
 End;

 Function DirIdxAtY(Yy: Integer): Integer;
 Var R: Integer;
 Begin
  DirIdxAtY := 0;
  If (Yy < DlY1 + 2) Or (Yy > DlY2 - 2) Then Exit;
  R := (Yy - DlY1 - 2) Div ROW_H + 1 + DirsScr;
  If (R >= 1) And (R <= DirsCnt) Then DirIdxAtY := R;
 End;

 Procedure HandleClick;
 Var Idx, Field: Integer; IsDbl: Boolean;
 Begin
  Field := -1; Idx := 0;
  If InRect(Mouse.X, Mouse.Y, NeX1, NeY1, NeX2, NeY2) Then Begin
   SetFocus(0); Field := 0;
  End
  Else If InRect(Mouse.X, Mouse.Y, FcX1, FcY1, FcX2, FcY2) Then Begin
   SetFocus(3); CycleFilter(+1); Field := 3;
  End
  Else If InRect(Mouse.X, Mouse.Y, FlX1, FlY1, FlX2, FlY2) Then Begin
   Idx := FileIdxAtY(Mouse.Y);
   SetFocus(1);
   If Idx > 0 Then Begin
    FilesSel := Idx; DirsSel := 0;
    NameBuf := Files[Idx]; NameCaret := Length(NameBuf);
    DrawFilesBox; DrawNameEdit;
   End;
   Field := 1;
  End
  Else If InRect(Mouse.X, Mouse.Y, DlX1, DlY1, DlX2, DlY2) Then Begin
   Idx := DirIdxAtY(Mouse.Y);
   SetFocus(2);
   If Idx > 0 Then Begin
    DirsSel := Idx; DrawDirsBox;
   End;
   Field := 2;
  End
  Else If InRect(Mouse.X, Mouse.Y, OkX1, OkY1, OkX2, OkY2) Then Begin
   If TryAccept Then ;
   Exit;
  End
  Else If InRect(Mouse.X, Mouse.Y, CnX1, CnY1, CnX2, CnY2) Then Begin
   ResultOK := False; Done := True; Exit;
  End
  Else If InRect(Mouse.X, Mouse.Y, UpX1, UpY1, UpX2, UpY2) Then Begin
   {$I-} ChDir('..'); {$I+} IoR := IOResult;
   If IoR = 0 Then Begin FullRefresh; DrawAll; End;
   Exit;
  End
  Else If InRect(Mouse.X, Mouse.Y, RefX1, RefY1, RefX2, RefY2) Then Begin
   FullRefresh; DrawAll; Exit;
  End;
  { Detection double-clic sur listbox }
  NowTick := TickCount;
  IsDbl := (Field = LastClickField) And (Idx = LastClickIdx) And (Idx > 0) And
          ((NowTick - LastClickTick) < DBL_TICKS);
  LastClickField := Field; LastClickIdx := Idx; LastClickTick := NowTick;
  If IsDbl Then Begin
   If Field = 1 Then ActivateFile(Idx)
   Else If Field = 2 Then ActivateDir(Idx);
  End;
 End;

 Procedure HandleKeyChar(Kc: Char);
 Begin
  Case Focus Of
   0: Begin   { name edit }
    Case Kc Of
     #8 : Begin
      If (NameCaret > 0) And (Length(NameBuf) > 0) Then Begin
       Delete(NameBuf, NameCaret, 1); Dec(NameCaret); DrawNameEdit;
      End;
     End;
    Else
     If (Kc >= ' ') And (Kc <= #126) And (Length(NameBuf) < 79) Then Begin
      Insert(Kc, NameBuf, NameCaret + 1); Inc(NameCaret); DrawNameEdit;
     End;
    End;
   End;
   3: Begin   { filter : Space cycle }
    If Kc = ' ' Then CycleFilter(+1);
   End;
   1, 2, 4, 5: Begin
    { espace = clic sur bouton focuse / lance activation }
    If Kc = ' ' Then Begin
     If Focus = 4 Then Begin If TryAccept Then ; End
     Else If Focus = 5 Then Begin
      ResultOK := False; Done := True;
     End;
    End;
   End;
  End;
 End;

 Procedure HandleKeyExt(Kc: Char);
 Begin
  Case Kc Of
   #15: SetFocus(Focus - 1);              { Shift+Tab }
   #75: Begin                             { Left }
    If Focus = 0 Then Begin
     If NameCaret > 0 Then Begin Dec(NameCaret); DrawNameEdit; End;
    End
    Else If Focus = 3 Then CycleFilter(-1);
   End;
   #77: Begin                             { Right }
    If Focus = 0 Then Begin
     If NameCaret < Length(NameBuf) Then Begin Inc(NameCaret); DrawNameEdit; End;
    End
    Else If Focus = 3 Then CycleFilter(+1);
   End;
   #72: Begin                             { Up }
    If Focus = 1 Then ScrollFilesTo(FilesSel - 1)
    Else If Focus = 2 Then ScrollDirsTo(DirsSel - 1);
   End;
   #80: Begin                             { Down }
    If Focus = 1 Then ScrollFilesTo(FilesSel + 1)
    Else If Focus = 2 Then ScrollDirsTo(DirsSel + 1);
   End;
   #73: Begin                             { PgUp }
    If Focus = 1 Then ScrollFilesTo(FilesSel - VisRows)
    Else If Focus = 2 Then ScrollDirsTo(DirsSel - VisRows);
   End;
   #81: Begin                             { PgDn }
    If Focus = 1 Then ScrollFilesTo(FilesSel + VisRows)
    Else If Focus = 2 Then ScrollDirsTo(DirsSel + VisRows);
   End;
   #71: Begin                             { Home }
    If Focus = 0 Then Begin NameCaret := 0; DrawNameEdit; End
    Else If Focus = 1 Then ScrollFilesTo(1)
    Else If Focus = 2 Then ScrollDirsTo(1);
   End;
   #79: Begin                             { End }
    If Focus = 0 Then Begin NameCaret := Length(NameBuf); DrawNameEdit; End
    Else If Focus = 1 Then ScrollFilesTo(FilesCnt)
    Else If Focus = 2 Then ScrollDirsTo(DirsCnt);
   End;
   #83: Begin                             { Delete }
    If Focus = 0 Then Begin
     If (NameCaret < Length(NameBuf)) Then Begin
      Delete(NameBuf, NameCaret + 1, 1); DrawNameEdit;
     End;
    End;
   End;
  End;
 End;

Begin
 FileSelectDlg := False;
 { ----- Geometrie ----- }
 X1 := 40;  Y1 := 50;  X2 := 600; Y2 := 440;
 NeX1 := X1 + 130; NeY1 := Y1 + 22; NeX2 := X2 - 14; NeY2 := Y1 + 36;
 FcX1 := X1 + 130; FcY1 := Y1 + 42; FcX2 := X2 - 14; FcY2 := Y1 + 56;
 FlX1 := X1 + 14;  FlY1 := Y1 + 96;
 FlX2 := X1 + 292; FlY2 := Y1 + 340;
 DlX1 := X1 + 308; DlY1 := Y1 + 96;
 DlX2 := X2 - 14;  DlY2 := Y1 + 340;
 { Boutons alignes au bas du dialogue (droite) }
 OkX1 := X2 - 14 - 368; OkY1 := Y2 - 32;
 OkX2 := OkX1 + 86;     OkY2 := Y2 - 12;
 CnX1 := OkX2 + 8;      CnY1 := Y2 - 32;
 CnX2 := CnX1 + 86;     CnY2 := Y2 - 12;
 UpX1 := CnX2 + 8;      UpY1 := Y2 - 32;
 UpX2 := UpX1 + 86;     UpY2 := Y2 - 12;
 RefX1 := UpX2 + 8;     RefY1 := Y2 - 32;
 RefX2 := RefX1 + 86;   RefY2 := Y2 - 12;
 VisRows := (FlY2 - FlY1 - 4) Div ROW_H;
 If VisRows < 1 Then VisRows := 1;

 { ----- Filtres ----- }
 FiltMasks[1] := '*.PPT';   FiltNames[1] := 'Presentations PowerPoint (*.PPT)';
 FiltMasks[2] := '*.PPTX';  FiltNames[2] := 'Presentations OOXML (*.PPTX)';
 FiltMasks[3] := '*.PRN';   FiltNames[3] := 'Fichiers d''impression (*.PRN)';
 FiltMasks[4] := '*.*';     FiltNames[4] := 'Tous les fichiers (*.*)';
 FiltIdx := 1;

 { ----- Pre-remplissage depuis FN ----- }
 If FN <> '' Then Begin
  FSplit(FN, ADir, AName, AExt);
  If ADir <> '' Then Begin
   {$I-} ChDir(ADir); {$I+} IoR := IOResult;
  End;
  NameBuf := AName + AExt;
  TmpS := AExt; For I := 1 To Length(TmpS) Do TmpS[I] := UpCase(TmpS[I]);
  If TmpS = '.PPTX' Then FiltIdx := 2
  Else If TmpS = '.PRN' Then FiltIdx := 3
  Else If TmpS = '.PPT' Then FiltIdx := 1;
 End Else NameBuf := '';
 NameCaret := Length(NameBuf);

 { ----- Etat initial ----- }
 Focus := 0;
 ResultOK := False; Done := False;
 LastClickTick := -100; LastClickField := -1; LastClickIdx := -1;

 FullRefresh;
 DrawAll;
 ShowMouse;

 Repeat
  UpdateMouse;
  Inc(TickCount);
  If (TickCount Mod 8) = 0 Then Begin
   BlinkState := Not BlinkState;
   If Focus = 0 Then DrawNameEdit;
  End;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #59: ;                                { F1 : reserve aide }
     #107, #45: Begin                       { Alt+F4 / Alt+X : annule }
      ResultOK := False; Done := True;
     End;
    Else
     HandleKeyExt(K2);
    End;
   End Else Begin
    Case K Of
     #27: Begin ResultOK := False; Done := True; End;
     #13: Begin
      { Enter : depend du focus }
      Case Focus Of
       1: If FilesSel > 0 Then ActivateFile(FilesSel);
       2: If DirsSel > 0 Then ActivateDir(DirsSel);
       5: Begin ResultOK := False; Done := True; End;
      Else
       If TryAccept Then ;
      End;
     End;
     #9 : SetFocus(Focus + 1);             { Tab }
    Else
     HandleKeyChar(K);
    End;
   End;
  End;
  If LeftPressed Then HandleClick;
  Delay(20);
 Until Done;

 NeedFullRedraw := True;
 FileSelectDlg := ResultOK;
End;

{ ----- Actions Fichier (Open/Save/SaveAs/Close) ----------------------- }

Procedure ActionSaveAs;
Var FN: String;
Begin
 FN := Pres.FileName;
 If FN = '' Then FN := 'PRESENT.PPT';
 If Not InputTextDlg('Enregistrer sous',
                     'Nom du fichier (.PPT) :', FN, 79) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 If Pos('.', FN) = 0 Then FN := FN + '.PPT';
 If SavePresentationFile(FN) Then Begin
  Pres.FileName := FN;
  Pres.Dirty    := False;
  StatusMsg     := 'Enregistre : ' + FN;
 End Else
  MessageBox('Enregistrer', 'Impossible d''ecrire : ' + FN);
 NeedFullRedraw := True;
End;

Procedure ActionSave;
Begin
 If Pres.FileName = '' Then Begin ActionSaveAs; Exit; End;
 If SavePresentationFile(Pres.FileName) Then Begin
  Pres.Dirty := False;
  StatusMsg  := 'Enregistre : ' + Pres.FileName;
 End Else
  MessageBox('Enregistrer',
             'Impossible d''ecrire : ' + Pres.FileName);
 NeedStatRedraw := True;
End;

Procedure ActionOpen;
Var FN: String;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FN := '';
 If Not FileSelectDlg('Ouvrir une presentation .PPT', FN, False) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If LoadPresentationFile(FN) Then
  StatusMsg := 'Charge : ' + FN
 Else
  MessageBox('Ouvrir', 'Impossible de lire : ' + FN);
 NeedFullRedraw := True;
End;

Procedure ActionClose;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FreePresentation;
 InitPresentation;
 SeedSamplePresentation;
 StatusMsg := 'Presentation fermee.';
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{          PHASE 11 : .PPTX (OOXML) -- ECRITURE ET LECTURE                }
{ ====================================================================== }
{ Format ZIP : entrees STORED (methode 0) uniquement. Le fichier produit  }
{ s'ouvre dans PowerPoint, Impress, et nous-memes. La lecture est limitee }
{ aux entrees STORED ; pour les .pptx natifs PowerPoint (DEFLATE), il    }
{ faudrait integrer un decodeur deflate (UNZIP.PAS). On extrait les       }
{ chaines <a:t>...</a:t> des fichiers ppt/slides/slide*.xml.              }
{ ----------------------------------------------------------------------- }

Const
 MAX_ZIP_ENT       = 320;
 ZIP_LFH_SIG       : LongInt = $04034B50;
 ZIP_CDH_SIG       : LongInt = $02014B50;
 ZIP_EOCD_SIG      : LongInt = $06054B50;
 CRC32_POLY        : LongInt = -306674912; { = $EDB88320 en non-signe }

Var
 CRC32Tab     : Array[0..255] Of LongInt;
 CRC32Inited  : Boolean;
 ZOutF        : File;
 ZOutOk       : Boolean;
 ZCurStart    : LongInt;
 ZCurDataOff  : LongInt;
 ZCurName     : String[80];
 ZCurCRC      : LongInt;
 ZCurSize     : LongInt;
 ZCdNames     : Array[1..MAX_ZIP_ENT] Of String[80];
 ZCdOffsets   : Array[1..MAX_ZIP_ENT] Of LongInt;
 ZCdSizes     : Array[1..MAX_ZIP_ENT] Of LongInt;
 ZCdCRCs      : Array[1..MAX_ZIP_ENT] Of LongInt;
 ZCdCount     : Integer;

{ ----- 4 octets little-endian -------------------------------------------- }

Procedure WrL(Var F: File; L: LongInt);
Begin
 PPTBuf[0] := Byte(L And $FF);
 PPTBuf[1] := Byte((L Shr 8) And $FF);
 PPTBuf[2] := Byte((L Shr 16) And $FF);
 PPTBuf[3] := Byte((L Shr 24) And $FF);
 BlockWrite(F, PPTBuf, 4);
End;

Function RdL(Var F: File): LongInt;
Begin
 BlockRead(F, PPTBuf, 4);
 RdL := LongInt(PPTBuf[0]) Or (LongInt(PPTBuf[1]) Shl 8) Or
        (LongInt(PPTBuf[2]) Shl 16) Or (LongInt(PPTBuf[3]) Shl 24);
End;

{ ----- CRC32 ------------------------------------------------------------- }

Procedure InitCRC32;
Var I, J: Integer; C: LongInt;
Begin
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := LongInt(C Shr 1) Xor CRC32_POLY
   Else C := C Shr 1;
  CRC32Tab[I] := C;
 End;
 CRC32Inited := True;
End;

Procedure CRC32Update(Var CRC: LongInt; B: Byte);
Begin
 CRC := CRC32Tab[Byte((CRC Xor LongInt(B)) And $FF)] Xor LongInt(CRC Shr 8);
End;

{ ----- ZIP Writer (stored only) ------------------------------------------ }

Procedure ZipOpen(Const FN: String);
Begin
 ZOutOk := False;
 ZCdCount := 0;
 If Not CRC32Inited Then InitCRC32;
 Assign(ZOutF, FN);
 {$I-} Rewrite(ZOutF, 1); {$I+}
 If IOResult = 0 Then ZOutOk := True;
End;

Procedure ZipBeginEntry(Const Name: String);
Var L: Integer;
Begin
 If Not ZOutOk Then Exit;
 ZCurStart := FilePos(ZOutF);
 ZCurName  := Name;
 ZCurCRC   := LongInt($FFFFFFFF);
 ZCurSize  := 0;
 L := Length(Name);
 { Local file header : sig 4, ver 2, flags 2, method 2, time 2, date 2,
   crc 4, csize 4, usize 4, namelen 2, extralen 2, name }
 WrL(ZOutF, ZIP_LFH_SIG);
 WrW(ZOutF, 20);          { version }
 WrW(ZOutF, 0);           { flags }
 WrW(ZOutF, 0);           { method 0 = stored }
 WrW(ZOutF, 0);           { mod time }
 WrW(ZOutF, $4321);       { mod date (2013-01-01 environ) }
 WrL(ZOutF, 0);           { CRC placeholder }
 WrL(ZOutF, 0);           { csize placeholder }
 WrL(ZOutF, 0);           { usize placeholder }
 WrW(ZOutF, Word(L));     { name length }
 WrW(ZOutF, 0);           { extra length }
 If L > 0 Then BlockWrite(ZOutF, Name[1], L);
 ZCurDataOff := FilePos(ZOutF);
End;

Procedure ZipWriteByte(B: Byte);
Begin
 If Not ZOutOk Then Exit;
 PPTBuf[0] := B;
 BlockWrite(ZOutF, PPTBuf, 1);
 CRC32Update(ZCurCRC, B);
 Inc(ZCurSize);
End;

Procedure ZipWriteStr(Const S: String);
Var I, L: Integer;
Begin
 If Not ZOutOk Then Exit;
 L := Length(S);
 For I := 1 To L Do CRC32Update(ZCurCRC, Byte(S[I]));
 If L > 0 Then BlockWrite(ZOutF, S[1], L);
 ZCurSize := ZCurSize + L;
End;

Procedure ZipWriteLn(Const S: String);
Begin
 ZipWriteStr(S);
 ZipWriteByte(10);
End;

Procedure ZipWriteXml(Const S: String);
Var I: Integer; C: Char;
Begin
 For I := 1 To Length(S) Do Begin
  C := S[I];
  Case C Of
   '&': ZipWriteStr('&amp;');
   '<': ZipWriteStr('&lt;');
   '>': ZipWriteStr('&gt;');
   '"': ZipWriteStr('&quot;');
   '''': ZipWriteStr('&apos;');
  Else
   If (Byte(C) >= 32) And (Byte(C) < 127) Then ZipWriteByte(Byte(C))
   Else ZipWriteByte(63);
  End;
 End;
End;

Procedure ZipEndEntry;
Var CRC: LongInt; EndPos: LongInt;
Begin
 If Not ZOutOk Then Exit;
 CRC := ZCurCRC Xor LongInt($FFFFFFFF);
 EndPos := FilePos(ZOutF);
 { Repositionne dans le local header pour patcher CRC + sizes }
 Seek(ZOutF, ZCurStart + 14);
 WrL(ZOutF, CRC);
 WrL(ZOutF, ZCurSize);
 WrL(ZOutF, ZCurSize);
 Seek(ZOutF, EndPos);
 { Enregistre pour le central directory }
 If ZCdCount < MAX_ZIP_ENT Then Begin
  Inc(ZCdCount);
  ZCdNames[ZCdCount]   := ZCurName;
  ZCdOffsets[ZCdCount] := ZCurStart;
  ZCdSizes[ZCdCount]   := ZCurSize;
  ZCdCRCs[ZCdCount]    := CRC;
 End;
End;

Procedure ZipClose;
Var I, L: Integer;
    CdStart, CdSize: LongInt;
Begin
 If Not ZOutOk Then Exit;
 CdStart := FilePos(ZOutF);
 For I := 1 To ZCdCount Do Begin
  L := Length(ZCdNames[I]);
  WrL(ZOutF, ZIP_CDH_SIG);
  WrW(ZOutF, 20);                  { ver made by }
  WrW(ZOutF, 20);                  { ver needed }
  WrW(ZOutF, 0);                   { flags }
  WrW(ZOutF, 0);                   { method }
  WrW(ZOutF, 0);                   { time }
  WrW(ZOutF, $4321);               { date }
  WrL(ZOutF, ZCdCRCs[I]);
  WrL(ZOutF, ZCdSizes[I]);
  WrL(ZOutF, ZCdSizes[I]);
  WrW(ZOutF, Word(L));             { name len }
  WrW(ZOutF, 0);                   { extra len }
  WrW(ZOutF, 0);                   { comment len }
  WrW(ZOutF, 0);                   { disk number }
  WrW(ZOutF, 0);                   { internal attr }
  WrL(ZOutF, 0);                   { external attr }
  WrL(ZOutF, ZCdOffsets[I]);
  If L > 0 Then BlockWrite(ZOutF, ZCdNames[I][1], L);
 End;
 CdSize := FilePos(ZOutF) - CdStart;
 { End of central directory }
 WrL(ZOutF, ZIP_EOCD_SIG);
 WrW(ZOutF, 0);                    { disk }
 WrW(ZOutF, 0);                    { cd disk }
 WrW(ZOutF, Word(ZCdCount));
 WrW(ZOutF, Word(ZCdCount));
 WrL(ZOutF, CdSize);
 WrL(ZOutF, CdStart);
 WrW(ZOutF, 0);                    { comment len }
 Close(ZOutF);
 ZOutOk := False;
End;

{ ----- Emetteurs XML PPTX ------------------------------------------------ }

Procedure EmitContentTypes;
Var I: Integer; S: String;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<Types xmlns="http://schemas.openxmlformats.org/package/');
 ZipWriteLn('2006/content-types">');
 ZipWriteLn('<Default Extension="rels" ContentType="application/' +
            'vnd.openxmlformats-package.relationships+xml"/>');
 ZipWriteLn('<Default Extension="xml" ContentType="application/xml"/>');
 ZipWriteLn('<Override PartName="/ppt/presentation.xml" ContentType=' +
   '"application/vnd.openxmlformats-officedocument.' +
   'presentationml.presentation.main+xml"/>');
 ZipWriteLn('<Override PartName="/ppt/slideMasters/slideMaster1.xml" ' +
   'ContentType="application/vnd.openxmlformats-officedocument.' +
   'presentationml.slideMaster+xml"/>');
 ZipWriteLn('<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ' +
   'ContentType="application/vnd.openxmlformats-officedocument.' +
   'presentationml.slideLayout+xml"/>');
 ZipWriteLn('<Override PartName="/ppt/theme/theme1.xml" ContentType=' +
   '"application/vnd.openxmlformats-officedocument.theme+xml"/>');
 For I := 1 To Pres.SldCount Do Begin
  Str(I, S);
  ZipWriteLn('<Override PartName="/ppt/slides/slide' + S +
             '.xml" ContentType="application/vnd.openxmlformats-' +
             'officedocument.presentationml.slide+xml"/>');
 End;
 ZipWriteLn('</Types>');
End;

Procedure EmitRootRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxmlformats' +
   '.org/officeDocument/2006/relationships/officeDocument" ' +
   'Target="ppt/presentation.xml"/>');
 ZipWriteLn('</Relationships>');
End;

Procedure EmitPresentation;
Var I: Integer; S: String;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:presentation xmlns:a="http://schemas.openxmlformats.');
 ZipWriteStr('org/drawingml/2006/main" xmlns:r="http://schemas.');
 ZipWriteStr('openxmlformats.org/officeDocument/2006/relationships" ');
 ZipWriteLn('xmlns:p="http://schemas.openxmlformats.org/' +
            'presentationml/2006/main">');
 ZipWriteLn('<p:sldMasterIdLst><p:sldMasterId id="2147483648" ' +
            'r:id="rId1"/></p:sldMasterIdLst>');
 ZipWriteStr('<p:sldIdLst>');
 For I := 1 To Pres.SldCount Do Begin
  Str(255 + I, S);
  ZipWriteStr('<p:sldId id="' + S + '" r:id="rId' );
  Str(I + 1, S);
  ZipWriteStr(S + '"/>');
 End;
 ZipWriteLn('</p:sldIdLst>');
 ZipWriteLn('<p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>');
 ZipWriteLn('<p:notesSz cx="6858000" cy="9144000"/>');
 ZipWriteLn('</p:presentation>');
End;

Procedure EmitPresentationRels;
Var I: Integer; S: String;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxmlformats' +
            '.org/officeDocument/2006/relationships/slideMaster" ' +
            'Target="slideMasters/slideMaster1.xml"/>');
 For I := 1 To Pres.SldCount Do Begin
  Str(I + 1, S);
  ZipWriteStr('<Relationship Id="rId' + S + '" Type=');
  ZipWriteStr('"http://schemas.openxmlformats.org/officeDocument/');
  ZipWriteStr('2006/relationships/slide" Target="slides/slide');
  Str(I, S);
  ZipWriteLn(S + '.xml"/>');
 End;
 ZipWriteLn('</Relationships>');
End;

Procedure EmitTheme;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<a:theme xmlns:a="http://schemas.openxmlformats.org/' +
            'drawingml/2006/main" name="Office">');
 ZipWriteLn('<a:themeElements>');
 ZipWriteLn('<a:clrScheme name="Office">');
 ZipWriteLn('<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>');
 ZipWriteLn('<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>');
 ZipWriteLn('<a:dk2><a:srgbClr val="1F497D"/></a:dk2>');
 ZipWriteLn('<a:lt2><a:srgbClr val="EEECE1"/></a:lt2>');
 ZipWriteLn('<a:accent1><a:srgbClr val="4F81BD"/></a:accent1>');
 ZipWriteLn('<a:accent2><a:srgbClr val="C0504D"/></a:accent2>');
 ZipWriteLn('<a:accent3><a:srgbClr val="9BBB59"/></a:accent3>');
 ZipWriteLn('<a:accent4><a:srgbClr val="8064A2"/></a:accent4>');
 ZipWriteLn('<a:accent5><a:srgbClr val="4BACC6"/></a:accent5>');
 ZipWriteLn('<a:accent6><a:srgbClr val="F79646"/></a:accent6>');
 ZipWriteLn('<a:hlink><a:srgbClr val="0000FF"/></a:hlink>');
 ZipWriteLn('<a:folHlink><a:srgbClr val="800080"/></a:folHlink>');
 ZipWriteLn('</a:clrScheme>');
 ZipWriteLn('<a:fontScheme name="Office">');
 ZipWriteLn('<a:majorFont><a:latin typeface="Calibri"/>' +
            '<a:ea typeface=""/><a:cs typeface=""/></a:majorFont>');
 ZipWriteLn('<a:minorFont><a:latin typeface="Calibri"/>' +
            '<a:ea typeface=""/><a:cs typeface=""/></a:minorFont>');
 ZipWriteLn('</a:fontScheme>');
 ZipWriteLn('<a:fmtScheme name="Office">');
 ZipWriteLn('<a:fillStyleLst>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '</a:fillStyleLst>');
 ZipWriteLn('<a:lnStyleLst>' +
   '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/>' +
   '</a:solidFill></a:ln>' +
   '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/>' +
   '</a:solidFill></a:ln>' +
   '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/>' +
   '</a:solidFill></a:ln></a:lnStyleLst>');
 ZipWriteLn('<a:effectStyleLst>' +
   '<a:effectStyle><a:effectLst/></a:effectStyle>' +
   '<a:effectStyle><a:effectLst/></a:effectStyle>' +
   '<a:effectStyle><a:effectLst/></a:effectStyle>' +
   '</a:effectStyleLst>');
 ZipWriteLn('<a:bgFillStyleLst>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '</a:bgFillStyleLst>');
 ZipWriteLn('</a:fmtScheme>');
 ZipWriteLn('</a:themeElements>');
 ZipWriteLn('</a:theme>');
End;

Procedure EmitSlideMaster;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/');
 ZipWriteStr('drawingml/2006/main" xmlns:r="http://schemas.openxml');
 ZipWriteStr('formats.org/officeDocument/2006/relationships" xmlns:p=');
 ZipWriteLn('"http://schemas.openxmlformats.org/presentationml/2006/' +
            'main">');
 ZipWriteLn('<p:cSld><p:bg><p:bgRef idx="1001">' +
            '<a:schemeClr val="bg1"/></p:bgRef></p:bg>');
 ZipWriteLn('<p:spTree>');
 ZipWriteLn('<p:nvGrpSpPr><p:cNvPr id="1" name=""/>' +
            '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
 ZipWriteLn('<p:grpSpPr><a:xfrm><a:off x="0" y="0"/>' +
   '<a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/>' +
   '<a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>');
 ZipWriteLn('</p:spTree></p:cSld>');
 ZipWriteLn('<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" ' +
   'accent1="accent1" accent2="accent2" accent3="accent3" ' +
   'accent4="accent4" accent5="accent5" accent6="accent6" ' +
   'hlink="hlink" folHlink="folHlink"/>');
 ZipWriteLn('<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" ' +
            'r:id="rId1"/></p:sldLayoutIdLst>');
 ZipWriteLn('<p:txStyles>');
 ZipWriteLn('<p:titleStyle><a:lvl1pPr algn="ctr">' +
            '<a:defRPr sz="4400"/></a:lvl1pPr></p:titleStyle>');
 ZipWriteLn('<p:bodyStyle><a:lvl1pPr><a:defRPr sz="2400"/>' +
            '</a:lvl1pPr></p:bodyStyle>');
 ZipWriteLn('<p:otherStyle/>');
 ZipWriteLn('</p:txStyles>');
 ZipWriteLn('</p:sldMaster>');
End;

Procedure EmitSlideMasterRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/' +
            'slideLayout" Target="../slideLayouts/slideLayout1.xml"/>');
 ZipWriteLn('<Relationship Id="rId2" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/theme" ' +
            'Target="../theme/theme1.xml"/>');
 ZipWriteLn('</Relationships>');
End;

Procedure EmitSlideLayout;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/');
 ZipWriteStr('drawingml/2006/main" xmlns:r="http://schemas.openxml');
 ZipWriteStr('formats.org/officeDocument/2006/relationships" xmlns:p=');
 ZipWriteStr('"http://schemas.openxmlformats.org/presentationml/2006/');
 ZipWriteLn('main" type="blank" preserve="1">');
 ZipWriteLn('<p:cSld name="Blank">');
 ZipWriteLn('<p:spTree>');
 ZipWriteLn('<p:nvGrpSpPr><p:cNvPr id="1" name=""/>' +
            '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
 ZipWriteLn('<p:grpSpPr><a:xfrm><a:off x="0" y="0"/>' +
   '<a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/>' +
   '<a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>');
 ZipWriteLn('</p:spTree></p:cSld>');
 ZipWriteLn('</p:sldLayout>');
End;

Procedure EmitSlideLayoutRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/' +
            'slideMaster" Target="../slideMasters/slideMaster1.xml"/>');
 ZipWriteLn('</Relationships>');
End;

Procedure EmitSlide(SlIdx: Integer);
Var S: PSlide; Sh: PShape; I, J: Integer;
    Tmp: String;
Begin
 S := Pres.Slides[SlIdx];
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:sld xmlns:a="http://schemas.openxmlformats.org/');
 ZipWriteStr('drawingml/2006/main" xmlns:r="http://schemas.openxml');
 ZipWriteStr('formats.org/officeDocument/2006/relationships" xmlns:p=');
 ZipWriteLn('"http://schemas.openxmlformats.org/presentationml/2006/' +
            'main">');
 ZipWriteLn('<p:cSld><p:spTree>');
 ZipWriteLn('<p:nvGrpSpPr><p:cNvPr id="1" name=""/>' +
            '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
 ZipWriteLn('<p:grpSpPr/>');
 { Bloc titre }
 ZipWriteLn('<p:sp>');
 ZipWriteLn('<p:nvSpPr><p:cNvPr id="2" name="Title"/>' +
   '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>' +
   '<p:nvPr><p:ph type="ctrTitle"/></p:nvPr></p:nvSpPr>');
 ZipWriteLn('<p:spPr><a:xfrm><a:off x="838200" y="365125"/>' +
   '<a:ext cx="7467600" cy="1325563"/></a:xfrm></p:spPr>');
 ZipWriteLn('<p:txBody><a:bodyPr/><a:lstStyle/>');
 ZipWriteStr('<a:p><a:r><a:rPr lang="fr-FR"/><a:t>');
 If S <> Nil Then Tmp := S^.Title Else Tmp := '';
 If Tmp = '' Then Tmp := 'Diapositive';
 ZipWriteXml(Tmp);
 ZipWriteLn('</a:t></a:r></a:p></p:txBody></p:sp>');
 { Bloc contenu : concatene toutes les lignes de texte de toutes les formes }
 ZipWriteLn('<p:sp>');
 ZipWriteLn('<p:nvSpPr><p:cNvPr id="3" name="Content"/>' +
   '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>' +
   '<p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>');
 ZipWriteLn('<p:spPr><a:xfrm><a:off x="838200" y="1825625"/>' +
   '<a:ext cx="7467600" cy="4351338"/></a:xfrm></p:spPr>');
 ZipWriteLn('<p:txBody><a:bodyPr/><a:lstStyle/>');
 If S <> Nil Then
  For I := 1 To S^.ShCount Do Begin
   Sh := S^.Shapes[I];
   If Sh <> Nil Then
    For J := 1 To Sh^.TxtCount Do Begin
     ZipWriteStr('<a:p><a:r><a:rPr lang="fr-FR"/><a:t>');
     ZipWriteXml(Sh^.Text[J]);
     ZipWriteLn('</a:t></a:r></a:p>');
    End;
  End;
 ZipWriteLn('</p:txBody></p:sp>');
 ZipWriteLn('</p:spTree></p:cSld>');
 ZipWriteLn('</p:sld>');
End;

Procedure EmitSlideRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/' +
            'slideLayout" Target="../slideLayouts/slideLayout1.xml"/>');
 ZipWriteLn('</Relationships>');
End;

{ ----- Sauvegarde .PPTX complete ----------------------------------------- }

Function SavePPTX(Const FN: String): Boolean;
Var I: Integer; S: String;
Begin
 SavePPTX := False;
 ZipOpen(FN);
 If Not ZOutOk Then Exit;

 ZipBeginEntry('[Content_Types].xml');  EmitContentTypes;       ZipEndEntry;
 ZipBeginEntry('_rels/.rels');          EmitRootRels;           ZipEndEntry;
 ZipBeginEntry('ppt/presentation.xml'); EmitPresentation;       ZipEndEntry;
 ZipBeginEntry('ppt/_rels/presentation.xml.rels');
 EmitPresentationRels; ZipEndEntry;
 ZipBeginEntry('ppt/theme/theme1.xml'); EmitTheme;              ZipEndEntry;
 ZipBeginEntry('ppt/slideMasters/slideMaster1.xml');
 EmitSlideMaster;      ZipEndEntry;
 ZipBeginEntry('ppt/slideMasters/_rels/slideMaster1.xml.rels');
 EmitSlideMasterRels;  ZipEndEntry;
 ZipBeginEntry('ppt/slideLayouts/slideLayout1.xml');
 EmitSlideLayout;      ZipEndEntry;
 ZipBeginEntry('ppt/slideLayouts/_rels/slideLayout1.xml.rels');
 EmitSlideLayoutRels;  ZipEndEntry;

 For I := 1 To Pres.SldCount Do Begin
  Str(I, S);
  ZipBeginEntry('ppt/slides/slide' + S + '.xml');
  EmitSlide(I);
  ZipEndEntry;
  ZipBeginEntry('ppt/slides/_rels/slide' + S + '.xml.rels');
  EmitSlideRels;
  ZipEndEntry;
 End;
 ZipClose;
 SavePPTX := True;
End;

{ ====================================================================== }
{   Decodeur DEFLATE (RFC 1951) - pur Pascal, suffisant pour decompresser }
{   les entrees Method=8 d'un .PPTX produit par PowerPoint.               }
{ ====================================================================== }

Type
 TInfLenArr  = Array[0..287] Of Integer;
 TInfCntArr  = Array[0..15]  Of Integer;
 TInfDLenArr = Array[0..31]  Of Integer;

Const
 INF_LEN_BASE: Array[0..28] Of Integer = (
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,258);
 INF_LEN_EXTRA: Array[0..28] Of Integer = (
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0);
 INF_DIST_BASE: Array[0..29] Of LongInt = (
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,
  1025,1537,2049,3073,4097,6145,8193,12289,16385,24577);
 INF_DIST_EXTRA: Array[0..29] Of Integer = (
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
 INF_CLEN_ORDER: Array[0..18] Of Integer = (
  16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

Var
 InfBitBuf : LongInt;
 InfBitCnt : Integer;
 InfIn     : ^Byte;
 InfInPos  : LongInt;
 InfInLen  : LongInt;
 InfOut    : ^Byte;
 InfOutPos : LongInt;
 InfOutLen : LongInt;
 InfError  : Boolean;
 { Tables Huffman courantes }
 InfLL_Lens   : TInfLenArr;
 InfLL_Counts : TInfCntArr;
 InfLL_Sorted : TInfLenArr;
 InfD_Lens    : TInfDLenArr;
 InfD_Counts  : TInfCntArr;
 InfD_Sorted  : TInfDLenArr;
 InfCL_Lens   : Array[0..18] Of Integer;
 InfCL_Counts : TInfCntArr;
 InfCL_Sorted : Array[0..18] Of Integer;

Function InfReadByte: Byte;
Var P: ^Byte;
Begin
 If InfInPos >= InfInLen Then Begin
  InfError := True; InfReadByte := 0; Exit;
 End;
 P := InfIn; Inc(P, InfInPos); InfReadByte := P^;
 Inc(InfInPos);
End;

Function InfGetBits(N: Integer): LongInt;
Var R, B, Mask: LongInt;
Begin
 While InfBitCnt < N Do Begin
  B := InfReadByte;
  InfBitBuf := InfBitBuf Or (LongInt(B) Shl InfBitCnt);
  Inc(InfBitCnt, 8);
 End;
 If N = 0 Then Mask := 0 Else Mask := (LongInt(1) Shl N) - 1;
 R := InfBitBuf And Mask;
 InfBitBuf := InfBitBuf Shr N;
 Dec(InfBitCnt, N);
 InfGetBits := R;
End;

Procedure InfPutByte(B: Byte);
Var P: ^Byte;
Begin
 If InfOutPos >= InfOutLen Then Begin
  InfError := True; Exit;
 End;
 P := InfOut; Inc(P, InfOutPos); P^ := B;
 Inc(InfOutPos);
End;

Function InfOutByteAt(Off: LongInt): Byte;
Var P: ^Byte;
Begin
 P := InfOut; Inc(P, Off); InfOutByteAt := P^;
End;

{ Construit la table de decodage canonique. NumSym <= NumSymMax. }
Procedure InfBuildHuf(Var Lens: Array Of Integer; NumSym: Integer;
                      Var Counts: Array Of Integer;
                      Var Sorted: Array Of Integer);
Var I, L: Integer;
    NextOf: Array[0..16] Of Integer;
    Base  : Array[0..16] Of Integer;
Begin
 For I := 0 To 15 Do Counts[I] := 0;
 For I := 0 To NumSym - 1 Do
  If (Lens[I] >= 1) And (Lens[I] <= 15) Then Inc(Counts[Lens[I]]);
 Base[0] := 0; Base[1] := 0;
 For L := 2 To 16 Do Base[L] := Base[L - 1] + Counts[L - 1];
 For L := 0 To 16 Do NextOf[L] := Base[L];
 For I := 0 To NumSym - 1 Do Begin
  L := Lens[I];
  If (L >= 1) And (L <= 15) Then Begin
   Sorted[NextOf[L]] := I;
   Inc(NextOf[L]);
  End;
 End;
End;

Function InfDecodeSym(Var Counts: Array Of Integer;
                      Var Sorted: Array Of Integer): Integer;
Var Code, First, Index, Count, L: LongInt;
Begin
 Code := 0; First := 0; Index := 0;
 For L := 1 To 15 Do Begin
  Code := (Code Shl 1) Or InfGetBits(1);
  Count := Counts[L];
  If (Code - Count) < First Then Begin
   InfDecodeSym := Sorted[Index + (Code - First)];
   Exit;
  End;
  Index := Index + Count;
  First := (First + Count) Shl 1;
 End;
 InfError := True;
 InfDecodeSym := -1;
End;

Procedure InfDoStored;
Var Len, NLen, I: LongInt;
    B: Byte;
Begin
 { aligne sur octet }
 InfBitBuf := 0; InfBitCnt := 0;
 Len  := LongInt(InfReadByte);
 Len  := Len Or (LongInt(InfReadByte) Shl 8);
 NLen := LongInt(InfReadByte);
 NLen := NLen Or (LongInt(InfReadByte) Shl 8);
 If InfError Then Exit;
 If (Len Xor NLen) <> 65535 Then Begin
  InfError := True; Exit;
 End;
 For I := 1 To Len Do Begin
  B := InfReadByte;
  If InfError Then Exit;
  InfPutByte(B);
  If InfError Then Exit;
 End;
End;

Procedure InfInitFixed;
Var I: Integer;
Begin
 For I := 0 To 143 Do InfLL_Lens[I] := 8;
 For I := 144 To 255 Do InfLL_Lens[I] := 9;
 For I := 256 To 279 Do InfLL_Lens[I] := 7;
 For I := 280 To 287 Do InfLL_Lens[I] := 8;
 InfBuildHuf(InfLL_Lens, 288, InfLL_Counts, InfLL_Sorted);
 For I := 0 To 29 Do InfD_Lens[I] := 5;
 InfD_Lens[30] := 0; InfD_Lens[31] := 0;
 InfBuildHuf(InfD_Lens, 32, InfD_Counts, InfD_Sorted);
End;

Procedure InfReadDynamicTables;
Var HLit, HDist, HCLen, I, Idx, Sym, Rep: Integer;
    PrevLen: Integer;
    AllLens: Array[0..319] Of Integer;
Begin
 HLit  := InfGetBits(5) + 257;
 HDist := InfGetBits(5) + 1;
 HCLen := InfGetBits(4) + 4;
 If (HLit > 286) Or (HDist > 30) Or (HCLen > 19) Then Begin
  InfError := True; Exit;
 End;
 For I := 0 To 18 Do InfCL_Lens[I] := 0;
 For I := 0 To HCLen - 1 Do
  InfCL_Lens[INF_CLEN_ORDER[I]] := InfGetBits(3);
 InfBuildHuf(InfCL_Lens, 19, InfCL_Counts, InfCL_Sorted);
 If InfError Then Exit;
 Idx := 0;
 PrevLen := 0;
 While Idx < HLit + HDist Do Begin
  Sym := InfDecodeSym(InfCL_Counts, InfCL_Sorted);
  If InfError Then Exit;
  If Sym < 16 Then Begin
   AllLens[Idx] := Sym;
   PrevLen := Sym;
   Inc(Idx);
  End
  Else If Sym = 16 Then Begin
   Rep := InfGetBits(2) + 3;
   While (Rep > 0) And (Idx < HLit + HDist) Do Begin
    AllLens[Idx] := PrevLen; Inc(Idx); Dec(Rep);
   End;
  End
  Else If Sym = 17 Then Begin
   Rep := InfGetBits(3) + 3;
   PrevLen := 0;
   While (Rep > 0) And (Idx < HLit + HDist) Do Begin
    AllLens[Idx] := 0; Inc(Idx); Dec(Rep);
   End;
  End
  Else Begin   { 18 }
   Rep := InfGetBits(7) + 11;
   PrevLen := 0;
   While (Rep > 0) And (Idx < HLit + HDist) Do Begin
    AllLens[Idx] := 0; Inc(Idx); Dec(Rep);
   End;
  End;
 End;
 For I := 0 To HLit - 1 Do InfLL_Lens[I] := AllLens[I];
 For I := HLit To 287 Do InfLL_Lens[I] := 0;
 For I := 0 To HDist - 1 Do InfD_Lens[I] := AllLens[HLit + I];
 For I := HDist To 31 Do InfD_Lens[I] := 0;
 InfBuildHuf(InfLL_Lens, 288, InfLL_Counts, InfLL_Sorted);
 InfBuildHuf(InfD_Lens, 32, InfD_Counts, InfD_Sorted);
End;

Procedure InfDecodeBlock;
Var Sym, LenIdx, DistIdx, K: Integer;
    Length_, Distance, Src: LongInt;
Begin
 Repeat
  Sym := InfDecodeSym(InfLL_Counts, InfLL_Sorted);
  If InfError Then Exit;
  If Sym < 256 Then Begin
   InfPutByte(Byte(Sym));
   If InfError Then Exit;
  End
  Else If Sym = 256 Then Exit
  Else Begin
   LenIdx := Sym - 257;
   If LenIdx > 28 Then Begin InfError := True; Exit; End;
   Length_ := INF_LEN_BASE[LenIdx] + InfGetBits(INF_LEN_EXTRA[LenIdx]);
   DistIdx := InfDecodeSym(InfD_Counts, InfD_Sorted);
   If InfError Then Exit;
   If DistIdx > 29 Then Begin InfError := True; Exit; End;
   Distance := INF_DIST_BASE[DistIdx] + InfGetBits(INF_DIST_EXTRA[DistIdx]);
   If Distance > InfOutPos Then Begin InfError := True; Exit; End;
   Src := InfOutPos - Distance;
   For K := 1 To Length_ Do Begin
    InfPutByte(InfOutByteAt(Src));
    If InfError Then Exit;
    Inc(Src);
   End;
  End;
 Until False;
End;

Function Inflate(InBuf: Pointer; InLen: LongInt;
                 OutBuf: Pointer; OutLen: LongInt): Boolean;
Var BFinal, BType: Integer;
    BlockNo: Integer;

 Procedure InfLog(Const S: String);
 Var LF: Text;
 Begin
  Assign(LF, 'POWERPNT.LOG');
  {$I-} Append(LF); {$I+} If IOResult <> 0 Then Begin
   {$I-} Rewrite(LF); {$I+} If IOResult <> 0 Then Exit;
  End;
  WriteLn(LF, S); Close(LF);
 End;

 Function LS(L: LongInt): String;
 Var T: String; Begin Str(L, T); LS := T; End;

Begin
 InfIn := InBuf; InfInLen := InLen; InfInPos := 0;
 InfOut := OutBuf; InfOutLen := OutLen; InfOutPos := 0;
 InfBitBuf := 0; InfBitCnt := 0;
 InfError := False;
 BlockNo := 0;
 InfLog('  Inflate: InLen=' + LS(InLen) + ' OutLen=' + LS(OutLen));
 Repeat
  BFinal := InfGetBits(1);
  BType  := InfGetBits(2);
  Inc(BlockNo);
  InfLog('  Block ' + LS(BlockNo) + ': BFinal=' + LS(BFinal) + ' BType=' + LS(BType) + ' InPos=' + LS(InfInPos) + ' OutPos=' + LS(InfOutPos));
  Case BType Of
   0: InfDoStored;
   1: Begin InfInitFixed; InfDecodeBlock; End;
   2: Begin InfReadDynamicTables; If Not InfError Then InfDecodeBlock; End;
  Else
   InfError := True;
  End;
  If InfError Then Begin
   InfLog('  ERROR after block ' + LS(BlockNo) + ' InPos=' + LS(InfInPos) + ' OutPos=' + LS(InfOutPos));
   Break;
  End;
 Until BFinal = 1;
 InfLog('  Inflate done: err=' + LS(Ord(InfError)) + ' OutPos=' + LS(InfOutPos));
 Inflate := Not InfError;
End;

{ ----- Lecteur .PPTX (STORED + DEFLATE) ---------------------------------- }
{ On scrute les Local File Headers en sequence, on extrait <a:t>...</a:t>   }
{ depuis les fichiers ppt/slides/slide*.xml.                                }

Function LoadPPTX(Const FN: String): Boolean;
Const MAX_PPTX_SLIDES = 256;
      EOCD_SCAN_MAX   = 65557;
Type
 TSlideEnt = Record
  LfhOff   : LongInt;
  CSize    : LongInt;
  USize    : LongInt;
  Mth      : Word;
  SlideNum : Integer;
 End;
Var F: File;
    FSize, EocdPos, CdOff, CdSize: LongInt;
    TotalEnt, EI: Integer;
    Sig: LongInt;
    ScanBuf: ^Byte;
    ScanLen: LongInt;
    ScanByte: ^Byte;
    DiagStr: String;
    K, II, JJ: LongInt;
    SlideEnts: Array[1..MAX_PPTX_SLIDES] Of TSlideEnt;
    SlideCnt, SlideIdx: Integer;
    EntName: String;
    Mth, Flg, NameLen, ExtraLen, CommentLen: Word;
    CSize, USize: LongInt;
    LfhOff: LongInt;
    SlNum, ValErr: Integer;
    NumStr, NameTmp: String;
    XmlBuf, CompBuf: Pointer;
    BufSize, P, Q, ChI: LongInt;
    TmpEnt: TSlideEnt;
    NewSl: PSlide; NewSh, BodyShape: PShape;
    Line, StartTag, EndTag: String;
    InTitle: Boolean;
    LineCount: Integer;
    SkippedCompressed, FoundSlide: Integer;

 Function PtrToByteAt(Off: LongInt): Byte;
 Var Ptr: ^Byte;
 Begin
  Ptr := XmlBuf; Inc(Ptr, Off); PtrToByteAt := Ptr^;
 End;

 Function MatchAt(Off: LongInt; Const Tag: String): Boolean;
 Var L: Integer;
 Begin
  MatchAt := False;
  If Off + Length(Tag) > BufSize Then Exit;
  For L := 1 To Length(Tag) Do
   If Char(PtrToByteAt(Off + L - 1)) <> Tag[L] Then Exit;
  MatchAt := True;
 End;

 Procedure PptxLog(Const S: String);
 Var LF: Text;
 Begin
  Assign(LF, 'POWERPNT.LOG');
  {$I-} Append(LF); {$I+}
  If IOResult <> 0 Then Begin {$I-} Rewrite(LF); {$I+} If IOResult <> 0 Then Exit; End;
  WriteLn(LF, S);
  Close(LF);
 End;

 Function LStr(L: LongInt): String;
 Var T: String;
 Begin Str(L, T); LStr := T; End;

Begin
 PptxLog('--- LoadPPTX: ' + FN + ' ---');
 LoadPPTX := False;
 SkippedCompressed := 0;
 FoundSlide := 0;
 SlideCnt := 0;
 XmlBuf := Nil; BufSize := 0;
 ScanBuf := Nil;
 DiagStr := '';
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin
  PptxLog('FAIL: ouverture impossible');
  SeedSamplePresentation;
  StatusMsg := 'PPTX: ouverture impossible: ' + FN;
  Exit;
 End;
 FSize := FileSize(F);
 PptxLog('FSize=' + LStr(FSize));
 If FSize < 22 Then Begin
  Close(F); SeedSamplePresentation;
  StatusMsg := 'PPTX: fichier trop petit';
  Exit;
 End;

 { ---- Recherche EOCD en queue de fichier ---- }
 ScanLen := FSize;
 If ScanLen > EOCD_SCAN_MAX Then ScanLen := EOCD_SCAN_MAX;
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
 FreeMem(ScanBuf, ScanLen); ScanBuf := Nil;
 PptxLog('EocdPos=' + LStr(EocdPos));
 If EocdPos < 0 Then Begin
  Close(F); SeedSamplePresentation;
  Str(FSize, DiagStr);
  StatusMsg := 'PPTX: EOCD introuvable (taille=' + DiagStr + ')';
  Exit;
 End;

 { Lecture EOCD : on saute jusqu'a "total entries" (offset +10). }
 Seek(F, EocdPos + 10);
 TotalEnt := RdW(F);
 CdSize := RdL(F);
 CdOff := RdL(F);
 PptxLog('TotalEnt=' + LStr(TotalEnt) + ' CdSize=' + LStr(CdSize) + ' CdOff=' + LStr(CdOff));
 If (TotalEnt <= 0) Or (CdOff <= 0) Or (CdOff >= FSize) Then Begin
  Close(F); SeedSamplePresentation;
  Str(TotalEnt, DiagStr);
  StatusMsg := 'PPTX: CD invalide (ent=' + DiagStr + ')';
  Exit;
 End;

 { ---- Parcourt le Central Directory ---- }
 Seek(F, CdOff);
 For EI := 1 To TotalEnt Do Begin
  Sig := RdL(F);
  If Sig <> ZIP_CDH_SIG Then Begin
   PptxLog('CDH sig mismatch ent=' + LStr(EI));
   Break;
  End;
  RdW(F); RdW(F);                             { version made by / needed }
  Flg := RdW(F);
  Mth := RdW(F);
  RdW(F); RdW(F);                             { time, date }
  RdL(F);                                     { crc }
  CSize := RdL(F);
  USize := RdL(F);
  NameLen    := RdW(F);
  ExtraLen   := RdW(F);
  CommentLen := RdW(F);
  RdW(F); RdW(F); RdL(F);                     { disk, int, ext attrs }
  LfhOff := RdL(F);
  PptxLog('CDH ' + LStr(EI) + ' nameLen=' + LStr(NameLen) + ' extra=' + LStr(ExtraLen) + ' cmt=' + LStr(CommentLen) + ' off=' + LStr(LfhOff));
  If NameLen > 200 Then NameLen := 200;
  EntName[0] := Char(NameLen);
  If NameLen > 0 Then BlockRead(F, EntName[1], NameLen);
  If ExtraLen   > 0 Then Seek(F, FilePos(F) + ExtraLen);
  If CommentLen > 0 Then Seek(F, FilePos(F) + CommentLen);

  If (Pos('ppt/slides/slide', EntName) = 1) And
     (Pos('.xml', EntName) > 0) And
     (Pos('.rels', EntName) = 0) Then Begin
   PptxLog('SLIDE: ' + EntName + ' mth=' + LStr(Mth) + ' cs=' + LStr(CSize) + ' us=' + LStr(USize) + ' off=' + LStr(LfhOff));
   NameTmp := Copy(EntName, 17, Length(EntName));
   II := Pos('.xml', NameTmp);
   If II > 0 Then NameTmp := Copy(NameTmp, 1, II - 1);
   Val(NameTmp, SlNum, ValErr);
   If ValErr <> 0 Then SlNum := 9999;
   If SlideCnt < MAX_PPTX_SLIDES Then Begin
    Inc(SlideCnt);
    SlideEnts[SlideCnt].LfhOff   := LfhOff;
    SlideEnts[SlideCnt].CSize    := CSize;
    SlideEnts[SlideCnt].USize    := USize;
    SlideEnts[SlideCnt].Mth      := Mth;
    SlideEnts[SlideCnt].SlideNum := SlNum;
   End;
  End;
 End;

 { Trie par numero de slide croissant }
 For II := 2 To SlideCnt Do Begin
  TmpEnt := SlideEnts[II]; JJ := II - 1;
  While (JJ >= 1) And (SlideEnts[JJ].SlideNum > TmpEnt.SlideNum) Do Begin
   SlideEnts[JJ + 1] := SlideEnts[JJ]; Dec(JJ);
  End;
  SlideEnts[JJ + 1] := TmpEnt;
 End;

 FreePresentation;
 InitPresentation;

 { ---- Extraction effective ---- }
 For SlideIdx := 1 To SlideCnt Do Begin
  CSize  := SlideEnts[SlideIdx].CSize;
  USize  := SlideEnts[SlideIdx].USize;
  Mth    := SlideEnts[SlideIdx].Mth;
  LfhOff := SlideEnts[SlideIdx].LfhOff;

  If (Mth <> 0) And (Mth <> 8) Then Begin
   Inc(SkippedCompressed); Continue;
  End;
  If (USize <= 0) Or (USize > LongInt(4) * 1024 * 1024) Then Continue;
  If (CSize < 0) Or (LfhOff < 0) Or (LfhOff >= FSize) Then Continue;

  Seek(F, LfhOff);
  Sig := RdL(F);
  If Sig <> ZIP_LFH_SIG Then Begin
   PptxLog('LFH sig mismatch idx=' + LStr(SlideIdx));
   Continue;
  End;
  RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);     { ver,flg,mth,time,date }
  RdL(F); RdL(F); RdL(F);                     { crc,csize,usize (peu fiables si bit 3) }
  NameLen  := RdW(F);
  ExtraLen := RdW(F);
  Seek(F, FilePos(F) + NameLen + ExtraLen);

  GetMem(XmlBuf, USize); BufSize := USize;
  If Mth = 0 Then Begin
   If USize > 0 Then BlockRead(F, XmlBuf^, USize);
  End Else Begin
   GetMem(CompBuf, CSize);
   If CSize > 0 Then BlockRead(F, CompBuf^, CSize);
   If Not Inflate(CompBuf, CSize, XmlBuf, USize) Then Begin
    PptxLog('INFLATE FAIL idx=' + LStr(SlideIdx));
    FreeMem(CompBuf, CSize);
    FreeMem(XmlBuf, BufSize); XmlBuf := Nil;
    Inc(SkippedCompressed); Continue;
   End;
   FreeMem(CompBuf, CSize);
  End;

  Inc(FoundSlide);
  NewSl := NewSlide;
  Str(FoundSlide, NumStr);
  NewSl^.Name := 'Diapo ' + NumStr;
  NewSl^.Title := '';
  NewSh := NewShape;
  NewSh^.ShType := SHP_TEXT;
  NewSh^.X := 50; NewSh^.Y := 150;
  NewSh^.W := 900; NewSh^.H := 500;
  NewSh^.FillColor := 15;
  NewSh^.LineColor := 0;
  NewSh^.Filled := False;
  NewSh^.TxtCount := 0;
  BodyShape := NewSh;
  LineCount := 0;
  InTitle := True;

  StartTag := '<a:t>'; EndTag := '</a:t>';
  ChI := 0;
  While ChI < BufSize Do Begin
   If MatchAt(ChI, StartTag) Then Begin
    ChI := ChI + Length(StartTag);
    P := ChI; Q := P;
    While (Q < BufSize) And (Not MatchAt(Q, EndTag)) Do Inc(Q);
    Line := '';
    While P < Q Do Begin
     If Length(Line) < TXT_LINE_LEN Then
      Line := Line + Char(PtrToByteAt(P));
     Inc(P);
    End;
    If InTitle Then Begin
     NewSl^.Title := Copy(Line, 1, 79);
     InTitle := False;
    End Else If (Line <> '') And (LineCount < MAX_TEXT_LINES) Then Begin
     Inc(LineCount);
     BodyShape^.Text[LineCount]    := Line;
     BodyShape^.Bullets[LineCount] := True;
     BodyShape^.Indent[LineCount]  := 0;
     BodyShape^.TxtCount := LineCount;
    End;
    ChI := Q + Length(EndTag);
   End Else
    Inc(ChI);
  End;
  If BodyShape^.TxtCount > 0 Then
   AddShapeToSlide(NewSl, BodyShape)
  Else
   Dispose(BodyShape);
  SlNum := Pres.SldCount + 1;
  If SlNum <= MAX_SLIDES Then Begin
   Pres.Slides[SlNum] := NewSl;
   Pres.SldCount := SlNum;
  End Else Dispose(NewSl);

  FreeMem(XmlBuf, BufSize); XmlBuf := Nil;
 End;

 Close(F);
 If XmlBuf <> Nil Then FreeMem(XmlBuf, BufSize);
 PptxLog('SlideCnt=' + LStr(SlideCnt) + ' FoundSlide=' + LStr(FoundSlide) + ' Skipped=' + LStr(SkippedCompressed));

 If FoundSlide = 0 Then Begin
  SeedSamplePresentation;
  Str(SlideCnt, DiagStr);
  StatusMsg := 'PPTX: 0 slide extraite / ' + DiagStr + ' detectees';
  Exit;
 End;
 Pres.FileName := FN;
 Pres.Dirty := False;
 CurSlide := 1;
 CurShape := 0;
 { Le fichier PPTX importe ne contient pas notre pied de page par defaut.
   On le neutralise pour eviter d'afficher "gladir.com" / "2026" sur chaque
   diapo chargee. }
 Pres.FooterText   := '';
 Pres.DateText     := '';
 Pres.HeaderText   := '';
 Pres.ShowFooter   := False;
 Pres.ShowDate     := False;
 Pres.ShowHeader   := False;
 Pres.Company      := '';
 If SkippedCompressed > 0 Then
  StatusMsg := 'PPTX importe (slides ignorees)'
 Else
  StatusMsg := 'PPTX importe : ' + FN;
 PptxLog('OK: ' + LStr(FoundSlide) + ' slides chargees');
 LoadPPTX := True;
End;

{ ----- Actions Export/Import .PPTX -------------------------------------- }

Function PptxUpStr(Const S: String): String;
Var K: Integer; R: String;
Begin
 R := S;
 For K := 1 To Length(R) Do R[K] := UpCase(R[K]);
 PptxUpStr := R;
End;

Procedure ActionExportPPTX;
Var FN: String;
Begin
 FN := Pres.FileName;
 If FN = '' Then FN := 'EXPORT.PPTX'
 Else Begin
  { Remplace .PPT par .PPTX }
  If (Length(FN) >= 4) And
     (PptxUpStr(Copy(FN, Length(FN) - 3, 4)) = '.PPT') Then
   FN := Copy(FN, 1, Length(FN) - 4) + '.PPTX';
 End;
 If Not InputTextDlg('Exporter .PPTX',
                     'Nom du fichier (.PPTX) :', FN, 79) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 If Pos('.', FN) = 0 Then FN := FN + '.PPTX';
 If SavePPTX(FN) Then
  StatusMsg := 'Exporte : ' + FN
 Else
  MessageBox('Exporter .PPTX', 'Impossible d''ecrire : ' + FN);
 NeedFullRedraw := True;
End;

Procedure ActionImportPPTX;
Var FN: String;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FN := '';
 If Not InputTextDlg('Importer .PPTX',
                     'Nom du fichier (.PPTX) :', FN, 79) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 If Not LoadPPTX(FN) Then
  MessageBox('Importer .PPTX',
             'Impossible de lire ou aucune diapositive trouvee : ' + FN);
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{               PHASE 12 : IMPRESSION (vers fichier .PRN)                }
{ ====================================================================== }

Procedure ActionPrint;
Var F: Text; FN, Default: String;
    I, J, K: Integer; S: PSlide; Sh: PShape;
Begin
 Default := Pres.FileName;
 If Default = '' Then Default := 'PRINT.PRN'
 Else Begin
  If (Length(Default) >= 5) And
     (PptxUpStr(Copy(Default, Length(Default) - 4, 5)) = '.PPTX') Then
   Default := Copy(Default, 1, Length(Default) - 5) + '.PRN'
  Else If (Length(Default) >= 4) And
     (PptxUpStr(Copy(Default, Length(Default) - 3, 4)) = '.PPT') Then
   Default := Copy(Default, 1, Length(Default) - 4) + '.PRN'
  Else
   Default := Default + '.PRN';
 End;
 FN := Default;
 If Not InputTextDlg('Imprimer',
                     'Fichier d''impression (.PRN, texte) :', FN, 79) Then
 Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 Assign(F, FN);
 {$I-} Rewrite(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Imprimer', 'Impossible d''ecrire : ' + FN);
  NeedFullRedraw := True; Exit;
 End;
 WriteLn(F, '=================================================');
 WriteLn(F, '  ', Pres.Title);
 If Pres.Author  <> '' Then WriteLn(F, '  Auteur  : ', Pres.Author);
 If Pres.Company <> '' Then WriteLn(F, '  Societe : ', Pres.Company);
 WriteLn(F, '  Diapositives : ', Pres.SldCount);
 WriteLn(F, '=================================================');
 WriteLn(F);
 For I := 1 To Pres.SldCount Do Begin
  S := Pres.Slides[I];
  If S <> Nil Then Begin
   WriteLn(F, '--- Diapositive ', I, ' / ', Pres.SldCount,
              ' : ', S^.Title, ' ---');
   WriteLn(F);
   For J := 1 To S^.ShCount Do Begin
    Sh := S^.Shapes[J];
    If Sh <> Nil Then
     For K := 1 To Sh^.TxtCount Do Begin
      If Sh^.Bullets[K] Then Write(F, ' * ')
      Else Write(F, '   ');
      WriteLn(F, Sh^.Text[K]);
     End;
   End;
   If S^.Notes <> '' Then Begin
    WriteLn(F);
    WriteLn(F, 'Notes :');
    WriteLn(F, S^.Notes);
   End;
   WriteLn(F);
   { Saut de page ASCII (FF) entre diapos sauf la derniere }
   If I < Pres.SldCount Then Begin Write(F, #12); WriteLn(F); End;
  End;
 End;
 Close(F);
 StatusMsg := 'Imprime (texte) : ' + FN;
 NeedStatRedraw := True;
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
  ACT_OPEN:         ActionOpen;
  ACT_SAVE:         ActionSave;
  ACT_SAVEAS:       ActionSaveAs;
  ACT_CLOSE:        ActionClose;
  ACT_PRINT:        ActionPrint;
  ACT_EXPORT_PPTX:  ActionExportPPTX;
  ACT_IMPORT_PPTX:  ActionImportPPTX;
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
  MenuKbdActive := False;
  MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
 end;
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
Var T, M, NewItem: Integer;
Begin
 T := 0; M := 0;
 If InRect(Mouse.X, Mouse.Y, 0, MenuY1, SCREEN_W - 1, MenuY2) Then
  M := MenuAtX(Mouse.X);
 If MenuHover <> M Then Begin
  MenuHover := M;
  If MenuOpen = 0 Then DrawMenuBar;
 End;
 { Phase 12 fix : un menu deroulant est ouvert -- bascule automatique
   vers un autre menu si la souris survole un autre titre de la barre.
   MAIS si la selection clavier est active et que la souris n'a pas bouge,
   on ignore le survol-souris (sinon Gauche/Droite clavier est annule par
   la souris stationnaire sur l'ancien titre de menu). }
 If (MenuOpen <> 0) And (M <> 0) And (M <> MenuOpen) Then Begin
  If MenuKbdActive And
     (Mouse.X = MenuKbdMx) And (Mouse.Y = MenuKbdMy) Then Begin
   { ignorer : laisse le clavier piloter MenuOpen }
  End
  Else Begin
   MenuOpen := M;
   MenuItemHover := 0;
   MenuKbdActive := False;
   NeedFullRedraw := True;
   Exit;
  End;
 End;
 { Phase 12 fix : survol des items du menu deroulant ouvert.
   Si la selection a ete posee au clavier et que la souris n'a pas bouge,
   on ne touche PAS a MenuItemHover -- sinon la souris stationnaire ecrase
   la selection clavier a chaque tick. }
 If MenuOpen <> 0 Then Begin
  If MenuKbdActive And
     (Mouse.X = MenuKbdMx) And (Mouse.Y = MenuKbdMy) Then Begin
   { ne rien faire : laisse le clavier piloter MenuItemHover }
  End
  Else Begin
   MenuKbdActive := False;
   ComputeDropLayout(MenuOpen);
   If InRect(Mouse.X, Mouse.Y, DropX, DropY,
             DropX + DropW, DropY + DropH) Then
    NewItem := DropItemAtY(MenuOpen, Mouse.Y)
   Else
    NewItem := 0;
   SetMenuItemHover(NewItem);
  End;
 End;
 { Phase 12 fix : quand un menu deroulant est ouvert, on n'evalue PAS le
   survol des outils -- la souris sur le dropdown chevauche visuellement la
   barre d'outils en Y, ce qui declenche un repaint/flash de la toolbar a
   chaque pixel deplace. }
 If MenuOpen = 0 Then Begin
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
Var NewSel, Tries, Act: Integer;
Begin
 { ----- MENU DEROULANT OUVERT : priorite absolue clavier ----- }
 If MenuOpen <> 0 Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #80: Begin   { Down : item selectable suivant }
     If Menus[MenuOpen].Count = 0 Then Exit;
     NewSel := MenuItemHover; Tries := 0;
     Repeat
      Inc(NewSel);
      If NewSel > Menus[MenuOpen].Count Then NewSel := 1;
      Inc(Tries);
     Until (Not Menus[MenuOpen].Items[NewSel].IsSep) Or
           (Tries > Menus[MenuOpen].Count);
     SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
    #72: Begin   { Up : item selectable precedent }
     If Menus[MenuOpen].Count = 0 Then Exit;
     If MenuItemHover = 0 Then NewSel := 1 Else NewSel := MenuItemHover;
     Tries := 0;
     Repeat
      Dec(NewSel);
      If NewSel < 1 Then NewSel := Menus[MenuOpen].Count;
      Inc(Tries);
     Until (Not Menus[MenuOpen].Items[NewSel].IsSep) Or
           (Tries > Menus[MenuOpen].Count);
     SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
    #75: Begin   { Left : menu precedent }
     Dec(MenuOpen); If MenuOpen < 1 Then MenuOpen := MenuCount;
     MenuItemHover := 0;
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     NeedFullRedraw := True; Exit;
    End;
    #77: Begin   { Right : menu suivant }
     Inc(MenuOpen); If MenuOpen > MenuCount Then MenuOpen := 1;
     MenuItemHover := 0;
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     NeedFullRedraw := True; Exit;
    End;
    #71: Begin   { Home : premier selectable }
     NewSel := 1;
     While (NewSel <= Menus[MenuOpen].Count) And
           Menus[MenuOpen].Items[NewSel].IsSep Do Inc(NewSel);
     If NewSel <= Menus[MenuOpen].Count Then SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
    #79: Begin   { End : dernier selectable }
     NewSel := Menus[MenuOpen].Count;
     While (NewSel >= 1) And Menus[MenuOpen].Items[NewSel].IsSep Do Dec(NewSel);
     If NewSel >= 1 Then SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
   End;
   Exit;
  End;
  Case K Of
   #27: Begin   { Esc : ferme }
    MenuOpen := 0; MenuItemHover := 0; MenuKbdActive := False;
    NeedFullRedraw := True; Exit;
   End;
   #13: Begin   { Enter : active }
    If (MenuItemHover >= 1) And (MenuItemHover <= Menus[MenuOpen].Count) And
       (Not Menus[MenuOpen].Items[MenuItemHover].IsSep) Then Begin
     Act := Menus[MenuOpen].Items[MenuItemHover].Action;
     MenuOpen := 0; MenuItemHover := 0; MenuKbdActive := False;
     NeedFullRedraw := True;
     If Act <> 0 Then DoAction(Act);
    End;
    Exit;
   End;
  End;
  Exit;
 End;
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
  #5:   DoAction(ACT_EXPORT_PPTX);                  { Ctrl+E }
  #2:   If CurShape > 0 Then ShapeToggleBold;       { Ctrl+B }
  #21:  If CurShape > 0 Then ShapeToggleUnderline;  { Ctrl+U }
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
 OutTextXY(120, 180, 'Version 1.0 - Phase 12 (2026) - finale');
 OutTextXY(120, 200, '(c) Sylvain Maltais  -  www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(120, 240, 'Formats : .PPT natif, .PPTX (import/export), .PRN');
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
  { Phase 12 : vraie dispatche selon extension }
  If (Length(CmdFName) >= 5) And
     (PptxUpStr(Copy(CmdFName, Length(CmdFName) - 4, 5)) = '.PPTX') Then
  Begin
   If LoadPPTX(CmdFName) Then StatusMsg := 'Charge : ' + CmdFName
   Else Begin
    { LoadPPTX a deja seed + StatusMsg diagnostique }
    If Copy(StatusMsg, 1, 5) <> 'PPTX:' Then Begin
     SeedSamplePresentation;
     StatusMsg := 'Echec PPTX : ' + CmdFName;
    End;
   End;
  End
  Else If (Length(CmdFName) >= 4) And
          (PptxUpStr(Copy(CmdFName, Length(CmdFName) - 3, 4)) = '.PPT') Then
  Begin
   If LoadPresentationFile(CmdFName) Then
    StatusMsg := 'Charge : ' + CmdFName
   Else Begin SeedSamplePresentation;
              StatusMsg := 'Echec : ' + CmdFName; End;
  End
  Else Begin
   Pres.FileName := CmdFName;
   SeedSamplePresentation;
   StatusMsg := 'Charge (factice) : ' + CmdFName;
  End;
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