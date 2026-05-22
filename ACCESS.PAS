{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Microsoft Access
}

Program ACCESS;

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

 Procedure GetMouseState(Var X, Y, Button: LongInt);
 Var Regs: Registers;
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

 Procedure ShowMouse;
 Begin End;

 Procedure HideMouse;
 Begin End;
{$ENDIF}

{ ====================================================================== }
{                       CONSTANTES                                       }
{ ====================================================================== }

Const
 SCREEN_W      = 640;
 SCREEN_H      = 480;
 MENU_H        = 16;
 TOOL_H        = 24;
 STAT_H        = 14;
 TS_H          = 24;       { Tab strip / object bar }
 ROW_H         = 14;
 GRID_HDR_H    = 18;
 NAV_H         = 18;
 SPLIT_W       = 3;

 MAX_TABLES    = 32;
 MAX_FIELDS    = 32;
 MAX_RECORDS   = 2000;
 MAX_INDEXES   = 16;
 MAX_RELATIONS = 32;
 MAX_QUERIES   = 32;
 MAX_FORMS     = 16;
 MAX_REPORTS   = 16;
 MAX_PICTURES  = 8;
 MAX_QRES_COLS = 16;
 MAX_QRES_ROWS = 200;

 FLD_NAME_LEN  = 32;
 TBL_NAME_LEN  = 32;
 VAL_LEN       = 80;       { longueur max valeur texte d'une cellule }

 { Types de champs (compatibles Access) }
 FT_TEXT       = 1;
 FT_MEMO       = 2;
 FT_INTEGER    = 3;
 FT_LONG       = 4;
 FT_SINGLE     = 5;
 FT_DOUBLE     = 6;
 FT_CURRENCY   = 7;
 FT_DATE       = 8;
 FT_TIME       = 9;
 FT_DATETIME   = 10;
 FT_BOOL       = 11;
 FT_AUTONUM    = 12;
 FT_OLE        = 13;
 FT_HYPERLINK  = 14;
 FT_BINARY     = 15;

 { Objets de la base }
 OBJ_TABLE     = 1;
 OBJ_QUERY     = 2;
 OBJ_FORM      = 3;
 OBJ_REPORT    = 4;
 OBJ_MACRO     = 5;
 OBJ_MODULE    = 6;

 { Vues actives }
 VIEW_NAV      = 0;        { fenetre base de donnees (liste objets) }
 VIEW_DSHEET   = 1;        { feuille de donnees }
 VIEW_DESIGN   = 2;        { mode creation table }
 VIEW_QUERY    = 3;        { requete (concepteur ou SQL) }
 VIEW_FORM     = 4;
 VIEW_REPORT   = 5;
 VIEW_RELATIONS = 6;

 { Couleurs VGA 16 (palette par defaut) }
 CLR_BLACK     = 0;  CLR_BLUE      = 1;  CLR_GREEN     = 2;  CLR_CYAN      = 3;
 CLR_RED       = 4;  CLR_MAGENTA   = 5;  CLR_BROWN     = 6;  CLR_LGRAY     = 7;
 CLR_DGRAY     = 8;  CLR_LBLUE     = 9;  CLR_LGREEN    = 10; CLR_LCYAN     = 11;
 CLR_LRED      = 12; CLR_LMAGENTA  = 13; CLR_YELLOW    = 14; CLR_WHITE     = 15;

 { Couleurs UI (style Access 97/2000) }
 CLR_WIN_BG       = 7;     { LGRAY }
 CLR_WIN_TEXT     = 0;
 CLR_WIN_HI       = 15;    { white border raised }
 CLR_WIN_LO       = 8;     { dgray border sunken }
 CLR_MENU_BG      = 7;
 CLR_MENU_FG      = 0;
 CLR_MENU_SEL_BG  = 1;     { bleu Office }
 CLR_MENU_SEL_FG  = 15;
 CLR_DLG_BG       = 7;
 CLR_DLG_TITLE_BG = 1;
 CLR_DLG_TITLE_FG = 15;
 CLR_GRID_BG      = 15;    { blanc }
 CLR_GRID_TEXT    = 0;
 CLR_GRID_LINE    = 7;
 CLR_GRID_HDR_BG  = 7;
 CLR_GRID_HDR_FG  = 0;
 CLR_GRID_SEL_BG  = 1;
 CLR_GRID_SEL_FG  = 15;
 CLR_STATUS_BG    = 7;
 CLR_STATUS_FG    = 0;
 CLR_NAV_BG       = 15;
 CLR_NAV_SIDE     = 9;     { panneau lateral bleu }

 { Identifiants d'actions }
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
 ACT_GOTO_REC     = 18;
 ACT_SELECTALL    = 19;
 ACT_VIEW_NAV     = 20;
 ACT_VIEW_DSHEET  = 21;
 ACT_VIEW_DESIGN  = 22;
 ACT_VIEW_QUERY   = 23;
 ACT_VIEW_FORM    = 24;
 ACT_VIEW_REPORT  = 25;
 ACT_NEW_TABLE    = 30;
 ACT_NEW_QUERY    = 31;
 ACT_NEW_FORM     = 32;
 ACT_NEW_REPORT   = 33;
 ACT_OPEN_OBJ     = 34;
 ACT_DESIGN_OBJ   = 35;
 ACT_DELETE_OBJ   = 36;
 ACT_RENAME_OBJ   = 37;
 ACT_RUN_QUERY    = 40;
 ACT_SQL_VIEW     = 41;
 ACT_TABLE_ADDF   = 42;
 ACT_TABLE_DELF   = 43;
 ACT_TABLE_KEY    = 44;
 ACT_REL_EDIT     = 50;
 ACT_NEW_RELATION = 51;
 ACT_DEL_RELATION = 52;
 ACT_INS_REC      = 60;
 ACT_DEL_REC      = 61;
 ACT_SAVE_REC     = 62;
 ACT_FIRST_REC    = 63;
 ACT_PREV_REC     = 64;
 ACT_NEXT_REC     = 65;
 ACT_LAST_REC     = 66;
 ACT_NEW_REC      = 67;
 ACT_SORT_ASC     = 70;
 ACT_SORT_DESC    = 71;
 ACT_FILTER       = 72;
 ACT_INS_PIC      = 75;
 ACT_IMPORT_CSV   = 76;
 ACT_EXPORT_CSV   = 77;
 ACT_RUN_SQL      = 78;
 ACT_REPORTS      = 80;
 ACT_HELP_TOPIC   = 90;
 ACT_HELP_ABOUT   = 91;
 ACT_ZOOM_IN      = 92;
 ACT_ZOOM_OUT     = 93;

 { Icones de la barre d'outils (vectoriel 18x18) }
 ICO_NEW       = 1;
 ICO_OPEN      = 2;
 ICO_SAVE      = 3;
 ICO_PRINT     = 4;
 ICO_CUT       = 5;
 ICO_COPY      = 6;
 ICO_PASTE     = 7;
 ICO_UNDO      = 8;
 ICO_REDO      = 9;
 ICO_FIND      = 10;
 ICO_TABLE     = 11;
 ICO_QUERY     = 12;
 ICO_FORM      = 13;
 ICO_REPORT    = 14;
 ICO_DESIGN    = 15;
 ICO_DSHEET    = 16;
 ICO_RUN       = 17;
 ICO_REL       = 18;
 ICO_KEY       = 19;
 ICO_INSREC    = 20;
 ICO_DELREC    = 21;
 ICO_FIRST     = 22;
 ICO_PREV      = 23;
 ICO_NEXT      = 24;
 ICO_LAST      = 25;
 ICO_SORTA     = 26;
 ICO_SORTD     = 27;
 ICO_FILTER    = 28;
 ICO_HELP      = 29;
 ICO_PIC       = 30;

{ ====================================================================== }
{                       TYPES                                            }
{ ====================================================================== }

Type
 TFieldName = String[FLD_NAME_LEN];
 TTableName = String[TBL_NAME_LEN];
 TCellStr   = String[VAL_LEN];

 TField = Record
  Name        : TFieldName;
  FType       : Byte;
  Size        : Word;       { taille en octets/caracteres }
  Decimals    : Byte;
  Required    : Boolean;
  Indexed     : Byte;       { 0=non 1=oui 2=oui sans doublons }
  PrimaryKey  : Boolean;
  AllowNull   : Boolean;
  DefaultVal  : String[40];
  Caption     : String[40];
  Description : String[64];
  Format      : String[24];
  InputMask   : String[24];
  ValidRule   : String[60];
  ValidText   : String[60];
 End;
 PField = ^TField;

 PRecord = ^TRecordData;
 TRecordData = Record
  Deleted : Boolean;
  Values  : Array[1..MAX_FIELDS] Of TCellStr;
 End;

 PTable = ^TTable;
 TTable = Record
  Name       : TTableName;
  Description: String[64];
  FldCount   : Integer;
  Fields     : Array[1..MAX_FIELDS] Of TField;
  RecCount   : Integer;
  Records    : Array[1..MAX_RECORDS] Of PRecord;
  NextAutoNum: LongInt;
  Dirty      : Boolean;
 End;

 PIndex = ^TIndex;
 TIndex = Record
  Name      : String[32];
  TblIdx    : Integer;
  FldIdx    : Integer;
  Unique    : Boolean;
  Ascending : Boolean;
 End;

 PRelation = ^TRelation;
 TRelation = Record
  Name        : String[32];
  TblFromIdx  : Integer;
  FldFromIdx  : Integer;
  TblToIdx    : Integer;
  FldToIdx    : Integer;
  Enforce     : Boolean;   { integrite referentielle }
  CascadeUpd  : Boolean;
  CascadeDel  : Boolean;
 End;

 PQuery = ^TQuery;
 TQuery = Record
  Name : String[32];
  SQL  : String[255];      { texte SQL }
  SQL2 : String[255];      { suite eventuelle }
 End;

 PForm = ^TForm;
 TForm = Record
  Name       : String[32];
  SrcTable   : Integer;
  CtrlCount  : Integer;
 End;

 PReport = ^TReport;
 TReport = Record
  Name       : String[32];
  SrcTable   : Integer;
 End;

 TDatabase = Record
  Name       : String[40];
  FileName   : String[80];
  Title      : String[60];
  Author     : String[40];
  Company    : String[60];
  Comments   : String[120];
  TblCount   : Integer;
  Tables     : Array[1..MAX_TABLES] Of PTable;
  IdxCount   : Integer;
  Indexes    : Array[1..MAX_INDEXES] Of PIndex;
  RelCount   : Integer;
  Relations  : Array[1..MAX_RELATIONS] Of PRelation;
  QryCount   : Integer;
  Queries    : Array[1..MAX_QUERIES] Of PQuery;
  FrmCount   : Integer;
  Forms      : Array[1..MAX_FORMS] Of PForm;
  RptCount   : Integer;
  Reports    : Array[1..MAX_REPORTS] Of PReport;
  Dirty      : Boolean;
 End;

 TMouseState = Record
  X, Y, B : LongInt;
 End;

 TMenuItem = Record
  Caption  : String[28];
  Shortcut : String[12];
  IsSep    : Boolean;
  Action   : Integer;
  Enabled  : Boolean;
 End;

 TMenu = Record
  Caption : String[14];
  X1, X2  : Integer;
  Count   : Integer;
  Items   : Array[1..24] Of TMenuItem;
 End;

 TToolButton = Record
  Icon    : Integer;
  Hint    : String[40];
  Action  : Integer;
  IsSep   : Boolean;
  Enabled : Boolean;
  X1,Y1,X2,Y2 : Integer;
 End;

{ ====================================================================== }
{                       VARIABLES GLOBALES                               }
{ ====================================================================== }

Var
 DB              : TDatabase;
 CurView         : Integer;
 CurObjType      : Integer;       { OBJ_TABLE..OBJ_REPORT }
 CurTblIdx       : Integer;       { table active }
 CurRecIdx       : Integer;
 CurFldIdx       : Integer;
 CurQryIdx       : Integer;
 CurFrmIdx       : Integer;
 CurRptIdx       : Integer;
 NavSelObj       : Integer;       { selection dans la fenetre Database }
 NavScroll       : Integer;
 DSheetColX      : Array[1..MAX_FIELDS] Of Integer;
 DSheetColW      : Array[1..MAX_FIELDS] Of Integer;
 DSheetRowTop    : Integer;
 DSheetScroll    : Integer;
 EditMode        : Boolean;
 EditBuf         : String;
 EditCaret       : Integer;
 BlinkState      : Boolean;

 { Mode Creation }
 DesignSelRow    : Integer;
 DesignSelCol    : Integer;
 DesignTopRow    : Integer;
 DesignVis       : Integer;
 DesignPropSel   : Integer;
 DesignFocus     : Integer;   { 0=grille, 1=proprietes }
 DesignTypeDrop  : Boolean;
 DesignTypeDropSel : Integer;
 DesignTypeDropX : Integer;
 DesignTypeDropY : Integer;
 DesignSplitY    : Integer;
 DesignPropY     : Integer;
 DesignGridY     : Integer;
 DesignBodyY     : Integer;
 DesignGridY2    : Integer;

 { Mode Requete }
 QSqlBuf         : String;
 QCaret          : Integer;
 QFocus          : Integer;       { 0=editeur, 1=resultats }
 QSplitY         : Integer;
 QResColCount    : Integer;
 QResRowCount    : Integer;
 QResColName     : Array[1..MAX_QRES_COLS] Of String;
 QResColW        : Array[1..MAX_QRES_COLS] Of Integer;
 QResRows        : Array[1..MAX_QRES_ROWS,1..MAX_QRES_COLS] Of String;
 QResSelRow      : Integer;
 QResSelCol      : Integer;
 QResScroll      : Integer;
 QResColScroll   : Integer;
 QStatusMsg      : String;
 QStatusErr      : Boolean;
 QDirty          : Boolean;        { SQL modifie non sauvegarde }

 { Mode Formulaire }
 FormScroll      : Integer;        { 1er champ visible }
 FormVisFlds     : Integer;        { nombre de champs visibles }
 FormLabelX      : Integer;
 FormEditX       : Integer;
 FormEditX2      : Integer;
 FormFldY0       : Integer;
 FormFldH        : Integer;
 FormBtnY        : Integer;
 FormBtnH        : Integer;

 { Mode Etat }
 RptPage         : Integer;
 RptPageCount    : Integer;
 RptRowsPerPage  : Integer;
 RptColX         : Array[1..MAX_FIELDS] Of Integer;
 RptColW         : Array[1..MAX_FIELDS] Of Integer;
 RptBodyY1       : Integer;
 RptBodyY2       : Integer;
 RptBtnY         : Integer;
 RptBtnH         : Integer;

 { Mode Relations }
 RelLayoutDone   : Boolean;
 RelBoxX         : Array[1..MAX_TABLES] Of Integer;
 RelBoxY         : Array[1..MAX_TABLES] Of Integer;
 RelBoxW         : Array[1..MAX_TABLES] Of Integer;
 RelBoxH         : Array[1..MAX_TABLES] Of Integer;
 RelSelIdx       : Integer;
 RelDragTbl      : Integer;
 RelDragDX       : Integer;
 RelDragDY       : Integer;
 RelArea1        : Integer;
 RelArea2        : Integer;
 RelBtnY         : Integer;
 RelBtnH         : Integer;

 Mouse           : TMouseState;
 LastClickB      : LongInt;
 LastClickTime   : LongInt;
 LastClickX      : LongInt;
 LastClickY      : LongInt;
 DoubleClicked   : Boolean;

 MenuCount       : Integer;
 Menus           : Array[1..16] Of TMenu;
 MenuY1, MenuY2  : Integer;
 MenuHover       : Integer;
 MenuOpen        : Integer;
 MenuItemHover   : Integer;

 ToolCount       : Integer;
 Tools           : Array[1..40] Of TToolButton;
 ToolY1, ToolY2  : Integer;
 ToolHover       : Integer;

 StatusMsg       : String;
 TickCount       : LongInt;

 NeedFullRedraw  : Boolean;
 NeedGridRedraw  : Boolean;
 NeedMenuRedraw  : Boolean;
 NeedStatRedraw  : Boolean;
 NeedDropRedraw  : Boolean;
 NeedNavRedraw   : Boolean;

 Quitting        : Boolean;

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

Function ExtractExt(Const F: String): String;
Var I: Integer;
Begin
 For I := Length(F) Downto 1 Do
  If F[I] = '.' Then Begin
   ExtractExt := UpperStr(Copy(F, I, Length(F) - I + 1)); Exit;
  End;
 ExtractExt := '';
End;

Function FieldTypeName(T: Byte): String;
Begin
 Case T Of
  FT_TEXT     : FieldTypeName := 'Texte';
  FT_MEMO     : FieldTypeName := 'Memo';
  FT_INTEGER  : FieldTypeName := 'Entier';
  FT_LONG     : FieldTypeName := 'Entier long';
  FT_SINGLE   : FieldTypeName := 'Reel';
  FT_DOUBLE   : FieldTypeName := 'Reel double';
  FT_CURRENCY : FieldTypeName := 'Monetaire';
  FT_DATE     : FieldTypeName := 'Date';
  FT_TIME     : FieldTypeName := 'Heure';
  FT_DATETIME : FieldTypeName := 'Date/Heure';
  FT_BOOL     : FieldTypeName := 'Oui/Non';
  FT_AUTONUM  : FieldTypeName := 'NumeroAuto';
  FT_OLE      : FieldTypeName := 'Objet OLE';
  FT_HYPERLINK: FieldTypeName := 'Lien hypertexte';
  FT_BINARY   : FieldTypeName := 'Binaire';
 Else FieldTypeName := '?';
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
  LastClickX := Mouse.X;
  LastClickY := Mouse.Y;
 End;
End;

Function LeftPressed: Boolean;
Begin LeftPressed := ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0); End;

Function LeftDown: Boolean;
Begin LeftDown := (Mouse.B And 1) <> 0; End;

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
 SetColor(Col);
 Line(X1, Y, X2, Y);
End;

Procedure VLine(X, Y1, Y2, Col: Integer);
Begin
 SetColor(Col);
 Line(X, Y1, X, Y2);
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

Procedure DrawRadioBtn(X, Y: Integer; Checked: Boolean);
Begin
 SetColor(CLR_WIN_LO);
 Circle(X + 5, Y + 5, 5);
 SetColor(CLR_WIN_HI);
 Arc(X + 5, Y + 5, 45, 225, 5);
 If Checked Then Begin
  SetFillStyle(1, CLR_BLACK);
  FillEllipse(X + 5, Y + 5, 2, 2);
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
 { Close box stylise [x] }
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
Begin
 SetColor(CLR_BLACK);
 OutTextXY(X, Y, S);
End;

Procedure DlgCheck(X, Y: Integer; Const Caption: String; Checked: Boolean);
Begin
 DrawCheckBox(X, Y, Checked);
 SetColor(CLR_BLACK);
 OutTextXY(X + 16, Y + 2, Caption);
End;

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
 If Menus[M].Count >= 24 Then Exit;
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
 AddMenu(' Inserer ');
 AddMenu(' Format ');
 AddMenu(' Enregistrements ');
 AddMenu(' Outils ');
 AddMenu(' Fenetre ');
 AddMenu(' Aide ');

 AddMenuItem(1, 'Nouvelle base...',          'Ctrl+N',   False, ACT_NEW);
 AddMenuItem(1, 'Ouvrir...',                 'Ctrl+O',   False, ACT_OPEN);
 AddMenuItem(1, 'Fermer',                    '',         False, ACT_CLOSE);
 AddMenuItem(1, '',                          '',         True,  0);
 AddMenuItem(1, 'Enregistrer',               'Ctrl+S',   False, ACT_SAVE);
 AddMenuItem(1, 'Enregistrer sous...',       '',         False, ACT_SAVEAS);
 AddMenuItem(1, '',                          '',         True,  0);
 AddMenuItem(1, 'Importer CSV...',           '',         False, ACT_IMPORT_CSV);
 AddMenuItem(1, 'Exporter CSV...',           '',         False, ACT_EXPORT_CSV);
 AddMenuItem(1, '',                          '',         True,  0);
 AddMenuItem(1, 'Imprimer...',               'Ctrl+P',   False, ACT_PRINT);
 AddMenuItem(1, '',                          '',         True,  0);
 AddMenuItem(1, 'Quitter',                   'Alt+F4',   False, ACT_QUIT);

 AddMenuItem(2, 'Annuler',                   'Ctrl+Z',   False, ACT_UNDO);
 AddMenuItem(2, 'Retablir',                  'Ctrl+Y',   False, ACT_REDO);
 AddMenuItem(2, '',                          '',         True,  0);
 AddMenuItem(2, 'Couper',                    'Ctrl+X',   False, ACT_CUT);
 AddMenuItem(2, 'Copier',                    'Ctrl+C',   False, ACT_COPY);
 AddMenuItem(2, 'Coller',                    'Ctrl+V',   False, ACT_PASTE);
 AddMenuItem(2, 'Supprimer',                 'Del',      False, ACT_DELETE);
 AddMenuItem(2, '',                          '',         True,  0);
 AddMenuItem(2, 'Rechercher...',             'Ctrl+F',   False, ACT_FIND);
 AddMenuItem(2, 'Remplacer...',              'Ctrl+H',   False, ACT_REPLACE);
 AddMenuItem(2, 'Atteindre...',              'F5',       False, ACT_GOTO_REC);
 AddMenuItem(2, 'Selectionner tout',         'Ctrl+A',   False, ACT_SELECTALL);

 AddMenuItem(3, 'Fenetre Base de donnees',   'F11',      False, ACT_VIEW_NAV);
 AddMenuItem(3, '',                          '',         True,  0);
 AddMenuItem(3, 'Feuille de donnees',        '',         False, ACT_VIEW_DSHEET);
 AddMenuItem(3, 'Mode Creation',             '',         False, ACT_VIEW_DESIGN);
 AddMenuItem(3, 'Mode Requete',              '',         False, ACT_VIEW_QUERY);
 AddMenuItem(3, 'Mode SQL',                  '',         False, ACT_SQL_VIEW);
 AddMenuItem(3, 'Mode Formulaire',           '',         False, ACT_VIEW_FORM);
 AddMenuItem(3, 'Mode Etat',                 '',         False, ACT_VIEW_REPORT);

 AddMenuItem(4, 'Nouvelle table',            '',         False, ACT_NEW_TABLE);
 AddMenuItem(4, 'Nouvelle requete',          '',         False, ACT_NEW_QUERY);
 AddMenuItem(4, 'Nouveau formulaire',        '',         False, ACT_NEW_FORM);
 AddMenuItem(4, 'Nouvel etat',               '',         False, ACT_NEW_REPORT);
 AddMenuItem(4, '',                          '',         True,  0);
 AddMenuItem(4, 'Nouvel enregistrement',     'Ctrl++',   False, ACT_NEW_REC);
 AddMenuItem(4, 'Image...',                  '',         False, ACT_INS_PIC);

 AddMenuItem(5, 'Police...',                 '',         False, 0);
 AddMenuItem(5, 'Cellules...',               '',         False, 0);
 AddMenuItem(5, 'Hauteur de ligne...',       '',         False, 0);
 AddMenuItem(5, 'Largeur de colonne...',     '',         False, 0);

 AddMenuItem(6, 'Premier',                   'Ctrl+Home',False, ACT_FIRST_REC);
 AddMenuItem(6, 'Precedent',                 'PgUp',     False, ACT_PREV_REC);
 AddMenuItem(6, 'Suivant',                   'PgDn',     False, ACT_NEXT_REC);
 AddMenuItem(6, 'Dernier',                   'Ctrl+End', False, ACT_LAST_REC);
 AddMenuItem(6, '',                          '',         True,  0);
 AddMenuItem(6, 'Nouveau',                   'Ctrl++',   False, ACT_INS_REC);
 AddMenuItem(6, 'Supprimer',                 'Ctrl+-',   False, ACT_DEL_REC);
 AddMenuItem(6, 'Enregistrer',               'Maj+Entree',False, ACT_SAVE_REC);
 AddMenuItem(6, '',                          '',         True,  0);
 AddMenuItem(6, 'Tri croissant',             '',         False, ACT_SORT_ASC);
 AddMenuItem(6, 'Tri decroissant',           '',         False, ACT_SORT_DESC);
 AddMenuItem(6, 'Filtre / Tri...',           '',         False, ACT_FILTER);

 AddMenuItem(7, 'Relations...',              '',         False, ACT_REL_EDIT);
 AddMenuItem(7, 'Executer requete',          '',         False, ACT_RUN_QUERY);
 AddMenuItem(7, 'Executer SQL...',           '',         False, ACT_RUN_SQL);
 AddMenuItem(7, '',                          '',         True,  0);
 AddMenuItem(7, 'Rapports...',               '',         False, ACT_REPORTS);

 AddMenuItem(8, 'Fenetre Base de donnees',   'F11',      False, ACT_VIEW_NAV);

 AddMenuItem(9, 'Rubriques d''aide',         'F1',       False, ACT_HELP_TOPIC);
 AddMenuItem(9, '',                          '',         True,  0);
 AddMenuItem(9, 'A propos de Access...',     '',         False, ACT_HELP_ABOUT);

 { Positionnement horizontal des titres }
 X := 4;
 For I := 1 To MenuCount Do Begin
  Menus[I].X1 := X;
  Menus[I].X2 := X + TextWidth(Menus[I].Caption) + 6;
  X := Menus[I].X2 + 2;
 End;
 MenuY1 := 0;
 MenuY2 := MENU_H - 1;
End;

Procedure DrawMenuCaption(X, Y: Integer; Const S: String; Fg: Integer);
Begin
 SetColor(Fg);
 OutTextXY(X, Y, S);
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
  Else Begin
   Bg := CLR_MENU_BG; Fg := CLR_MENU_FG;
  End;
  DrawMenuCaption(Menus[I].X1 + 4, MenuY1 + 4, Menus[I].Caption, Fg);
 End;
 ShowMouse;
End;

Function MenuAtX(X: LongInt): Integer;
Var I: Integer;
Begin
 MenuAtX := 0;
 For I := 1 To MenuCount Do
  If (X >= Menus[I].X1) And (X <= Menus[I].X2) Then Begin
   MenuAtX := I; Exit; End;
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
 W := 120;
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
   DrawMenuCaption(DropX + 8, Y + 2, Menus[M].Items[I].Caption, Fg);
   S := Menus[M].Items[I].Shortcut;
   If S <> '' Then Begin
    SetColor(Fg);
    OutTextXY(DropX + DropW - TextWidth(S) - 8, Y + 2, S);
   End;
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
 { Page blanche avec coin replie }
 FillBox(X + 3, Y + 1, X + 12, Y + 16, CLR_WHITE);
 SetColor(CLR_BLACK);
 Rectangle(X + 3, Y + 1, X + 12, Y + 16);
 Line(X + 9, Y + 1, X + 12, Y + 4);
 Line(X + 9, Y + 1, X + 9, Y + 4);
 Line(X + 9, Y + 4, X + 12, Y + 4);
 HLine(X + 5, X + 10, Y + 7, CLR_DGRAY);
 HLine(X + 5, X + 10, Y + 9, CLR_DGRAY);
 HLine(X + 5, X + 10, Y + 11, CLR_DGRAY);
End;

Procedure IconOpen(X, Y: Integer);
Begin
 { Dossier ouvert jaune }
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
 { Disquette }
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
 { Ciseaux }
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

Procedure IconFind(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Circle(X + 7, Y + 7, 5);
 Line(X + 11, Y + 11, X + 15, Y + 15);
 Line(X + 12, Y + 11, X + 15, Y + 14);
End;

Procedure IconTable(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 2, X + 15, Y + 15, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 15, Y + 15);
 FillBox(X + 2, Y + 2, X + 15, Y + 5, CLR_LBLUE);
 SetColor(CLR_BLACK);
 HLine(X + 2, X + 15, Y + 8, CLR_DGRAY);
 HLine(X + 2, X + 15, Y + 11, CLR_DGRAY);
 VLine(X + 8, Y + 2, Y + 15, CLR_DGRAY);
End;

Procedure IconQuery(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 2, X + 15, Y + 15, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 15, Y + 15);
 FillBox(X + 2, Y + 2, X + 15, Y + 5, CLR_LBLUE);
 SetColor(CLR_RED);
 Line(X + 4, Y + 14, X + 10, Y + 8);
 Line(X + 5, Y + 14, X + 11, Y + 8);
End;

Procedure IconForm(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 2, X + 15, Y + 15, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 15, Y + 15);
 FillBox(X + 2, Y + 2, X + 15, Y + 5, CLR_LBLUE);
 SetColor(CLR_DGRAY);
 Rectangle(X + 4, Y + 7, X + 13, Y + 9);
 Rectangle(X + 4, Y + 11, X + 13, Y + 13);
End;

Procedure IconReport(X, Y: Integer);
Begin
 FillBox(X + 3, Y + 2, X + 14, Y + 16, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 3, Y + 2, X + 14, Y + 16);
 SetColor(CLR_DGRAY);
 HLine(X + 5, X + 12, Y + 5, CLR_DGRAY);
 HLine(X + 5, X + 12, Y + 7, CLR_DGRAY);
 HLine(X + 5, X + 12, Y + 9, CLR_DGRAY);
 HLine(X + 5, X + 12, Y + 11, CLR_DGRAY);
 HLine(X + 5, X + 12, Y + 13, CLR_DGRAY);
End;

Procedure IconDesign(X, Y: Integer);
Begin
 { Regle + crayon }
 SetColor(CLR_BLUE);
 Line(X + 2, Y + 14, X + 15, Y + 14);
 Line(X + 2, Y + 15, X + 15, Y + 15);
 SetColor(CLR_BROWN);
 Line(X + 4, Y + 2, X + 14, Y + 12);
 Line(X + 5, Y + 2, X + 15, Y + 12);
 PutPixel(X + 3, Y + 3, CLR_BLACK);
 PutPixel(X + 4, Y + 3, CLR_BLACK);
End;

Procedure IconDSheet(X, Y: Integer);
Begin
 IconTable(X, Y);
 SetColor(CLR_RED);
 Rectangle(X + 9, Y + 6, X + 14, Y + 10);
End;

Procedure IconRun(X, Y: Integer);
Begin
 { Triangle play vert }
 SetFillStyle(1, CLR_LGREEN);
 Bar(X + 4, Y + 3, X + 5, Y + 14);
 SetColor(CLR_GREEN);
 Line(X + 4, Y + 3, X + 14, Y + 9);
 Line(X + 4, Y + 14, X + 14, Y + 9);
 Line(X + 5, Y + 4, X + 13, Y + 9);
 Line(X + 5, Y + 13, X + 13, Y + 9);
End;

Procedure IconRel(X, Y: Integer);
Begin
 IconTable(X, Y);
 FillBox(X + 10, Y + 9, X + 16, Y + 16, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 10, Y + 9, X + 16, Y + 16);
 Line(X + 8, Y + 13, X + 10, Y + 13);
End;

Procedure IconKey(X, Y: Integer);
Begin
 { Cle jaune }
 SetColor(CLR_YELLOW);
 Circle(X + 5, Y + 9, 3);
 Line(X + 8, Y + 9, X + 15, Y + 9);
 Line(X + 13, Y + 9, X + 13, Y + 12);
 Line(X + 15, Y + 9, X + 15, Y + 12);
End;

Procedure IconInsRec(X, Y: Integer);
Begin
 IconTable(X, Y);
 SetColor(CLR_LGREEN);
 Line(X + 13, Y + 4, X + 13, Y + 10);
 Line(X + 10, Y + 7, X + 16, Y + 7);
End;

Procedure IconDelRec(X, Y: Integer);
Begin
 IconTable(X, Y);
 SetColor(CLR_RED);
 Line(X + 10, Y + 4, X + 16, Y + 10);
 Line(X + 16, Y + 4, X + 10, Y + 10);
End;

Procedure IconArrow(X, Y, Dir: Integer);
{ Dir: 0=first, 1=prev, 2=next, 3=last }
Begin
 SetColor(CLR_BLACK);
 Case Dir Of
  0: Begin
      Line(X + 4, Y + 4, X + 4, Y + 14);
      Line(X + 5, Y + 4, X + 5, Y + 14);
      Line(X + 6, Y + 9, X + 12, Y + 4);
      Line(X + 6, Y + 9, X + 12, Y + 14);
      Line(X + 6, Y + 9, X + 12, Y + 9);
     End;
  1: Begin
      Line(X + 4, Y + 9, X + 10, Y + 4);
      Line(X + 4, Y + 9, X + 10, Y + 14);
      Line(X + 4, Y + 9, X + 14, Y + 9);
     End;
  2: Begin
      Line(X + 4, Y + 9, X + 14, Y + 9);
      Line(X + 14, Y + 9, X + 8, Y + 4);
      Line(X + 14, Y + 9, X + 8, Y + 14);
     End;
  3: Begin
      Line(X + 13, Y + 4, X + 13, Y + 14);
      Line(X + 14, Y + 4, X + 14, Y + 14);
      Line(X + 6, Y + 4, X + 12, Y + 9);
      Line(X + 6, Y + 14, X + 12, Y + 9);
      Line(X + 6, Y + 9, X + 12, Y + 9);
     End;
 End;
End;

Procedure IconSort(X, Y: Integer; Asc: Boolean);
Begin
 SetColor(CLR_BLACK);
 If Asc Then Begin
  OutTextXY(X + 3, Y + 2, 'A');
  OutTextXY(X + 3, Y + 9, 'Z');
  Line(X + 11, Y + 3, X + 11, Y + 14);
  Line(X + 9, Y + 12, X + 11, Y + 14);
  Line(X + 13, Y + 12, X + 11, Y + 14);
 End
 Else Begin
  OutTextXY(X + 3, Y + 2, 'Z');
  OutTextXY(X + 3, Y + 9, 'A');
  Line(X + 11, Y + 14, X + 11, Y + 3);
  Line(X + 9, Y + 5, X + 11, Y + 3);
  Line(X + 13, Y + 5, X + 11, Y + 3);
 End;
End;

Procedure IconFilter(X, Y: Integer);
Begin
 SetColor(CLR_DGRAY);
 Line(X + 2, Y + 3, X + 14, Y + 3);
 Line(X + 4, Y + 6, X + 12, Y + 6);
 Line(X + 6, Y + 9, X + 10, Y + 9);
 Line(X + 7, Y + 12, X + 9, Y + 12);
 PutPixel(X + 8, Y + 15, CLR_DGRAY);
End;

Procedure IconHelp(X, Y: Integer);
Begin
 SetColor(CLR_YELLOW);
 SetFillStyle(1, CLR_BLUE);
 FillEllipse(X + 8, Y + 9, 6, 6);
 SetColor(CLR_WHITE);
 OutTextXY(X + 5, Y + 5, '?');
End;

Procedure IconPic(X, Y: Integer);
Begin
 FillBox(X + 2, Y + 3, X + 15, Y + 14, CLR_WHITE);
 SetColor(CLR_BLACK); Rectangle(X + 2, Y + 3, X + 15, Y + 14);
 SetFillStyle(1, CLR_YELLOW); FillEllipse(X + 6, Y + 7, 2, 2);
 SetColor(CLR_GREEN);
 Line(X + 3, Y + 13, X + 8, Y + 8);
 Line(X + 8, Y + 8, X + 12, Y + 11);
 Line(X + 12, Y + 11, X + 14, Y + 9);
End;

Procedure DrawIcon(IconId, X, Y: Integer);
Begin
 Case IconId Of
  ICO_NEW:    IconNew(X, Y);
  ICO_OPEN:   IconOpen(X, Y);
  ICO_SAVE:   IconSave(X, Y);
  ICO_PRINT:  IconPrint(X, Y);
  ICO_CUT:    IconCut(X, Y);
  ICO_COPY:   IconCopy(X, Y);
  ICO_PASTE:  IconPaste(X, Y);
  ICO_UNDO:   IconUndo(X, Y);
  ICO_REDO:   IconRedo(X, Y);
  ICO_FIND:   IconFind(X, Y);
  ICO_TABLE:  IconTable(X, Y);
  ICO_QUERY:  IconQuery(X, Y);
  ICO_FORM:   IconForm(X, Y);
  ICO_REPORT: IconReport(X, Y);
  ICO_DESIGN: IconDesign(X, Y);
  ICO_DSHEET: IconDSheet(X, Y);
  ICO_RUN:    IconRun(X, Y);
  ICO_REL:    IconRel(X, Y);
  ICO_KEY:    IconKey(X, Y);
  ICO_INSREC: IconInsRec(X, Y);
  ICO_DELREC: IconDelRec(X, Y);
  ICO_FIRST:  IconArrow(X, Y, 0);
  ICO_PREV:   IconArrow(X, Y, 1);
  ICO_NEXT:   IconArrow(X, Y, 2);
  ICO_LAST:   IconArrow(X, Y, 3);
  ICO_SORTA:  IconSort(X, Y, True);
  ICO_SORTD:  IconSort(X, Y, False);
  ICO_FILTER: IconFilter(X, Y);
  ICO_HELP:   IconHelp(X, Y);
  ICO_PIC:    IconPic(X, Y);
 End;
End;

{ ====================================================================== }
{                       BARRE D'OUTILS                                   }
{ ====================================================================== }

Procedure AddTool(Icon: Integer; Const Hint: String; Action: Integer);
Begin
 If ToolCount >= 40 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].Icon    := Icon;
 Tools[ToolCount].Hint    := Hint;
 Tools[ToolCount].Action  := Action;
 Tools[ToolCount].IsSep   := False;
 Tools[ToolCount].Enabled := True;
End;

Procedure AddToolSep;
Begin
 If ToolCount >= 40 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].IsSep   := True;
 Tools[ToolCount].Enabled := False;
End;

Procedure InitTools;
Var I, X, Y: Integer;
Begin
 ToolCount := 0;
 AddTool(ICO_NEW,    'Nouvelle base',           ACT_NEW);
 AddTool(ICO_OPEN,   'Ouvrir...',               ACT_OPEN);
 AddTool(ICO_SAVE,   'Enregistrer',             ACT_SAVE);
 AddTool(ICO_PRINT,  'Imprimer',                ACT_PRINT);
 AddToolSep;
 AddTool(ICO_CUT,    'Couper',                  ACT_CUT);
 AddTool(ICO_COPY,   'Copier',                  ACT_COPY);
 AddTool(ICO_PASTE,  'Coller',                  ACT_PASTE);
 AddToolSep;
 AddTool(ICO_UNDO,   'Annuler',                 ACT_UNDO);
 AddTool(ICO_REDO,   'Retablir',                ACT_REDO);
 AddTool(ICO_FIND,   'Rechercher',              ACT_FIND);
 AddToolSep;
 AddTool(ICO_DSHEET, 'Feuille de donnees',      ACT_VIEW_DSHEET);
 AddTool(ICO_DESIGN, 'Mode Creation',           ACT_VIEW_DESIGN);
 AddTool(ICO_RUN,    'Executer requete',        ACT_RUN_QUERY);
 AddTool(ICO_KEY,    'Cle primaire',            ACT_TABLE_KEY);
 AddTool(ICO_REL,    'Relations',               ACT_REL_EDIT);
 AddToolSep;
 AddTool(ICO_INSREC, 'Nouvel enregistrement',   ACT_INS_REC);
 AddTool(ICO_DELREC, 'Supprimer enregistrement',ACT_DEL_REC);
 AddTool(ICO_FIRST,  'Premier',                 ACT_FIRST_REC);
 AddTool(ICO_PREV,   'Precedent',               ACT_PREV_REC);
 AddTool(ICO_NEXT,   'Suivant',                 ACT_NEXT_REC);
 AddTool(ICO_LAST,   'Dernier',                 ACT_LAST_REC);
 AddToolSep;
 AddTool(ICO_SORTA,  'Tri croissant',           ACT_SORT_ASC);
 AddTool(ICO_SORTD,  'Tri decroissant',         ACT_SORT_DESC);
 AddTool(ICO_FILTER, 'Filtre',                  ACT_FILTER);
 AddToolSep;
 AddTool(ICO_PIC,    'Inserer une image',       ACT_INS_PIC);
 AddToolSep;
 AddTool(ICO_HELP,   'Aide',                    ACT_HELP_TOPIC);

 ToolY1 := MENU_H;
 ToolY2 := MENU_H + TOOL_H - 1;
 X := 4;
 Y := ToolY1 + 2;
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   Tools[I].X1 := X; Tools[I].Y1 := Y;
   Tools[I].X2 := X + 4; Tools[I].Y2 := Y + 19;
   X := X + 6;
  End
  Else Begin
   Tools[I].X1 := X; Tools[I].Y1 := Y;
   Tools[I].X2 := X + 19; Tools[I].Y2 := Y + 19;
   X := X + 21;
  End;
 End;
End;

Procedure DrawToolbar;
Var I: Integer;
Begin
 HideMouse;
 FillBox(0, ToolY1, SCREEN_W - 1, ToolY2, CLR_WIN_BG);
 HLine(0, SCREEN_W - 1, ToolY2, CLR_WIN_LO);
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   VLine(Tools[I].X1 + 1, Tools[I].Y1 + 2, Tools[I].Y2 - 2, CLR_WIN_LO);
   VLine(Tools[I].X1 + 2, Tools[I].Y1 + 2, Tools[I].Y2 - 2, CLR_WIN_HI);
  End
  Else Begin
   If I = ToolHover Then
    DrawRaised(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2,
               CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO)
   Else
    FillBox(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2, CLR_WIN_BG);
   DrawIcon(Tools[I].Icon, Tools[I].X1, Tools[I].Y1);
  End;
 End;
 ShowMouse;
End;

Function ToolAtXY(X, Y: LongInt): Integer;
Var I: Integer;
Begin
 ToolAtXY := 0;
 For I := 1 To ToolCount Do
  If Not Tools[I].IsSep Then
   If InRect(X, Y, Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2) Then Begin
    ToolAtXY := I; Exit;
   End;
End;

{ ====================================================================== }
{                       BARRE D'ETAT                                     }
{ ====================================================================== }

Procedure DrawStatusBar;
Var Y1, Y2: Integer; S: String;
Begin
 HideMouse;
 Y1 := SCREEN_H - STAT_H;
 Y2 := SCREEN_H - 1;
 FillBox(0, Y1, SCREEN_W - 1, Y2, CLR_STATUS_BG);
 HLine(0, SCREEN_W - 1, Y1, CLR_WIN_HI);
 SetColor(CLR_STATUS_FG);
 OutTextXY(6, Y1 + 3, StatusMsg);
 { Indicateur enregistrement courant a droite }
 S := '';
 If (CurView = VIEW_DSHEET) And (CurTblIdx > 0) And
    (CurTblIdx <= DB.TblCount) And (DB.Tables[CurTblIdx] <> Nil) Then
  S := 'Enr ' + IntToStr(CurRecIdx) + ' / ' +
       IntToStr(DB.Tables[CurTblIdx]^.RecCount);
 If S <> '' Then OutTextXY(SCREEN_W - TextWidth(S) - 8, Y1 + 3, S);
 ShowMouse;
End;

{ ====================================================================== }
{                       GESTION DE LA BASE                               }
{ ====================================================================== }

Procedure InitDatabase;
Begin
 FillChar(DB, SizeOf(DB), 0);
 DB.Name      := 'Base1';
 DB.Title     := 'Nouvelle base de donnees';
 DB.Author    := 'Sylvain Maltais';
 DB.Company   := 'Gladir.com';
 DB.FileName  := '';
 DB.TblCount  := 0;
 DB.QryCount  := 0;
 DB.FrmCount  := 0;
 DB.RptCount  := 0;
 DB.IdxCount  := 0;
 DB.RelCount  := 0;
 DB.Dirty     := False;
End;

Function NewTable(Const Name: String): Integer;
Var T: PTable;
Begin
 NewTable := 0;
 If DB.TblCount >= MAX_TABLES Then Exit;
 GetMem(T, SizeOf(TTable));
 FillChar(T^, SizeOf(TTable), 0);
 T^.Name        := Name;
 T^.FldCount    := 0;
 T^.RecCount    := 0;
 T^.NextAutoNum := 1;
 Inc(DB.TblCount);
 DB.Tables[DB.TblCount] := T;
 NewTable := DB.TblCount;
End;

Procedure AddField(TIdx: Integer; Const FName: String; FT: Byte; Size: Word);
Var T: PTable; F: Integer;
Begin
 If (TIdx < 1) Or (TIdx > DB.TblCount) Then Exit;
 T := DB.Tables[TIdx];
 If T = Nil Then Exit;
 If T^.FldCount >= MAX_FIELDS Then Exit;
 Inc(T^.FldCount);
 F := T^.FldCount;
 FillChar(T^.Fields[F], SizeOf(TField), 0);
 T^.Fields[F].Name      := FName;
 T^.Fields[F].FType     := FT;
 T^.Fields[F].Size      := Size;
 T^.Fields[F].AllowNull := True;
End;

Function NewRecord(TIdx: Integer): Integer;
Var T: PTable; R: PRecord;
Begin
 NewRecord := 0;
 If (TIdx < 1) Or (TIdx > DB.TblCount) Then Exit;
 T := DB.Tables[TIdx];
 If T = Nil Then Exit;
 If T^.RecCount >= MAX_RECORDS Then Exit;
 GetMem(R, SizeOf(TRecordData));
 FillChar(R^, SizeOf(TRecordData), 0);
 Inc(T^.RecCount);
 T^.Records[T^.RecCount] := R;
 NewRecord := T^.RecCount;
End;

Procedure FreeDatabase;
Var I, J: Integer; T: PTable;
Begin
 For I := 1 To DB.TblCount Do Begin
  T := DB.Tables[I];
  If T <> Nil Then Begin
   For J := 1 To T^.RecCount Do
    If T^.Records[J] <> Nil Then FreeMem(T^.Records[J], SizeOf(TRecordData));
   FreeMem(T, SizeOf(TTable));
   DB.Tables[I] := Nil;
  End;
 End;
 DB.TblCount := 0;
 For I := 1 To DB.QryCount Do
  If DB.Queries[I] <> Nil Then FreeMem(DB.Queries[I], SizeOf(TQuery));
 DB.QryCount := 0;
 For I := 1 To DB.FrmCount Do
  If DB.Forms[I] <> Nil Then FreeMem(DB.Forms[I], SizeOf(TForm));
 DB.FrmCount := 0;
 For I := 1 To DB.RptCount Do
  If DB.Reports[I] <> Nil Then FreeMem(DB.Reports[I], SizeOf(TReport));
 DB.RptCount := 0;
 For I := 1 To DB.IdxCount Do
  If DB.Indexes[I] <> Nil Then FreeMem(DB.Indexes[I], SizeOf(TIndex));
 DB.IdxCount := 0;
 For I := 1 To DB.RelCount Do
  If DB.Relations[I] <> Nil Then FreeMem(DB.Relations[I], SizeOf(TRelation));
 DB.RelCount := 0;
End;

Procedure SeedSampleDatabase;
Var T, I: Integer;
Begin
 T := NewTable('Clients');
 AddField(T, 'NoClient',  FT_AUTONUM, 4);
 AddField(T, 'Nom',       FT_TEXT,    40);
 AddField(T, 'Prenom',    FT_TEXT,    30);
 AddField(T, 'Ville',     FT_TEXT,    30);
 AddField(T, 'Telephone', FT_TEXT,    20);
 DB.Tables[T]^.Fields[1].PrimaryKey := True;
 DB.Tables[T]^.Fields[1].Indexed    := 2;
 I := NewRecord(T);
 DB.Tables[T]^.Records[I]^.Values[1] := '1';
 DB.Tables[T]^.Records[I]^.Values[2] := 'Tremblay';
 DB.Tables[T]^.Records[I]^.Values[3] := 'Marie';
 DB.Tables[T]^.Records[I]^.Values[4] := 'Quebec';
 DB.Tables[T]^.Records[I]^.Values[5] := '418-555-0001';
 I := NewRecord(T);
 DB.Tables[T]^.Records[I]^.Values[1] := '2';
 DB.Tables[T]^.Records[I]^.Values[2] := 'Lavoie';
 DB.Tables[T]^.Records[I]^.Values[3] := 'Jean';
 DB.Tables[T]^.Records[I]^.Values[4] := 'Montreal';
 DB.Tables[T]^.Records[I]^.Values[5] := '514-555-0002';
 I := NewRecord(T);
 DB.Tables[T]^.Records[I]^.Values[1] := '3';
 DB.Tables[T]^.Records[I]^.Values[2] := 'Bouchard';
 DB.Tables[T]^.Records[I]^.Values[3] := 'Sophie';
 DB.Tables[T]^.Records[I]^.Values[4] := 'Gatineau';
 DB.Tables[T]^.Records[I]^.Values[5] := '819-555-0003';
 DB.Tables[T]^.NextAutoNum := 4;

 T := NewTable('Produits');
 AddField(T, 'NoProduit',   FT_AUTONUM, 4);
 AddField(T, 'Description', FT_TEXT,    50);
 AddField(T, 'PrixUnitaire',FT_CURRENCY,8);
 AddField(T, 'EnStock',     FT_LONG,    4);
 DB.Tables[T]^.Fields[1].PrimaryKey := True;
 DB.Tables[T]^.NextAutoNum := 1;

 T := NewTable('Commandes');
 AddField(T, 'NoCommande', FT_AUTONUM, 4);
 AddField(T, 'NoClient',   FT_LONG,    4);
 AddField(T, 'Date',       FT_DATE,    8);
 AddField(T, 'Montant',    FT_CURRENCY,8);
 DB.Tables[T]^.Fields[1].PrimaryKey := True;
 DB.Tables[T]^.NextAutoNum := 1;

 CurTblIdx  := 1;
 CurRecIdx  := 1;
 CurFldIdx  := 1;
 NavSelObj  := 1;
 CurObjType := OBJ_TABLE;
End;

{ ====================================================================== }
{                       VUE NAVIGATEUR (Fenetre Base de donnees)         }
{ ====================================================================== }

Var
 NavTabY      : Integer;       { y de la rangee d'onglets objets }
 NavListY1    : Integer;
 NavListY2    : Integer;
 NavTabBoxes  : Array[1..6] Of Record X1,Y1,X2,Y2:Integer; End;

Procedure ComputeNavLayout;
Var I, X, W: Integer;
Begin
 NavTabY   := ToolY2 + 6;
 NavListY1 := NavTabY + 22;
 NavListY2 := SCREEN_H - STAT_H - 4;
 X := 110;
 W := 78;
 For I := 1 To 6 Do Begin
  NavTabBoxes[I].X1 := X;
  NavTabBoxes[I].Y1 := NavTabY;
  NavTabBoxes[I].X2 := X + W;
  NavTabBoxes[I].Y2 := NavTabY + 18;
  X := X + W + 2;
 End;
End;

Function NavObjCount(OT: Integer): Integer;
Begin
 Case OT Of
  OBJ_TABLE  : NavObjCount := DB.TblCount;
  OBJ_QUERY  : NavObjCount := DB.QryCount;
  OBJ_FORM   : NavObjCount := DB.FrmCount;
  OBJ_REPORT : NavObjCount := DB.RptCount;
 Else NavObjCount := 0;
 End;
End;

Function NavObjName(OT, Idx: Integer): String;
Begin
 NavObjName := '';
 Case OT Of
  OBJ_TABLE :
   If (Idx >= 1) And (Idx <= DB.TblCount) And (DB.Tables[Idx] <> Nil) Then
    NavObjName := DB.Tables[Idx]^.Name;
  OBJ_QUERY :
   If (Idx >= 1) And (Idx <= DB.QryCount) And (DB.Queries[Idx] <> Nil) Then
    NavObjName := DB.Queries[Idx]^.Name;
  OBJ_FORM  :
   If (Idx >= 1) And (Idx <= DB.FrmCount) And (DB.Forms[Idx] <> Nil) Then
    NavObjName := DB.Forms[Idx]^.Name;
  OBJ_REPORT:
   If (Idx >= 1) And (Idx <= DB.RptCount) And (DB.Reports[Idx] <> Nil) Then
    NavObjName := DB.Reports[Idx]^.Name;
 End;
End;

Function NavObjIcon(OT: Integer): Integer;
Begin
 Case OT Of
  OBJ_TABLE : NavObjIcon := ICO_TABLE;
  OBJ_QUERY : NavObjIcon := ICO_QUERY;
  OBJ_FORM  : NavObjIcon := ICO_FORM;
  OBJ_REPORT: NavObjIcon := ICO_REPORT;
 Else NavObjIcon := ICO_TABLE;
 End;
End;

Procedure DrawNavTab(Idx: Integer; Const Caption: String; Active: Boolean);
Var X1, Y1, X2, Y2: Integer;
Begin
 X1 := NavTabBoxes[Idx].X1; Y1 := NavTabBoxes[Idx].Y1;
 X2 := NavTabBoxes[Idx].X2; Y2 := NavTabBoxes[Idx].Y2;
 If Active Then Begin
  DrawRaised(X1, Y1, X2, Y2 + 2, CLR_WIN_BG, CLR_WIN_HI, CLR_WIN_LO);
  FillBox(X1 + 1, Y2 + 1, X2 - 1, Y2 + 2, CLR_WIN_BG);
 End
 Else
  DrawRaised(X1, Y1 + 2, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 6, Y1 + 6, Caption);
End;

Procedure DrawNavSidePanel;
Var X1, Y1, X2, Y2: Integer;
Begin
 X1 := 0; Y1 := NavTabY;
 X2 := 100; Y2 := NavListY2;
 FillBox(X1, Y1, X2, Y2, CLR_NAV_SIDE);
 SetColor(CLR_WHITE);
 OutTextXY(X1 + 8, Y1 + 10, 'Objets');
 SetColor(CLR_LGRAY);
 Line(X1 + 6, Y1 + 24, X2 - 6, Y1 + 24);
 SetColor(CLR_WHITE);
 If CurObjType = OBJ_TABLE  Then OutTextXY(X1 + 14, Y1 + 32, '> Tables')
 Else                            OutTextXY(X1 + 14, Y1 + 32, '  Tables');
 If CurObjType = OBJ_QUERY  Then OutTextXY(X1 + 14, Y1 + 50, '> Requetes')
 Else                            OutTextXY(X1 + 14, Y1 + 50, '  Requetes');
 If CurObjType = OBJ_FORM   Then OutTextXY(X1 + 14, Y1 + 68, '> Formulaires')
 Else                            OutTextXY(X1 + 14, Y1 + 68, '  Formulaires');
 If CurObjType = OBJ_REPORT Then OutTextXY(X1 + 14, Y1 + 86, '> Etats')
 Else                            OutTextXY(X1 + 14, Y1 + 86, '  Etats');
End;

Procedure DrawNavList;
Var X1, X2, Y, Yy, I, RowH, N, Vis: Integer;
    Name: String;
Begin
 X1 := 102; X2 := SCREEN_W - 4;
 Y  := NavListY1;
 FillBox(X1, Y, X2, NavListY2, CLR_NAV_BG);
 DrawSunken(X1, Y, X2, NavListY2, CLR_NAV_BG, CLR_WIN_HI, CLR_WIN_LO);

 N := NavObjCount(CurObjType);
 RowH := 22;
 Vis  := (NavListY2 - Y - 4) Div RowH;
 If NavScroll > N - Vis Then NavScroll := N - Vis;
 If NavScroll < 0 Then NavScroll := 0;

 { Boutons d'action en haut a droite }
 DlgBtn(X2 - 220, Y + 4, X2 - 158, Y + 22, 'Ouvrir',     False, False);
 DlgBtn(X2 - 156, Y + 4, X2 -  94, Y + 22, 'Creer',      False, False);
 DlgBtn(X2 -  92, Y + 4, X2 -  30, Y + 22, 'Supprimer',  False, False);

 Yy := Y + 32;
 For I := 1 To Vis Do Begin
  If NavScroll + I > N Then Break;
  If NavScroll + I = NavSelObj Then Begin
   FillBox(X1 + 4, Yy - 2, X2 - 4, Yy + RowH - 4, CLR_GRID_SEL_BG);
   SetColor(CLR_GRID_SEL_FG);
  End
  Else SetColor(CLR_BLACK);
  DrawIcon(NavObjIcon(CurObjType), X1 + 8, Yy - 2);
  Name := NavObjName(CurObjType, NavScroll + I);
  OutTextXY(X1 + 30, Yy + 4, Name);
  Yy := Yy + RowH;
 End;
End;

Procedure DrawNavView;
Var X1, Y1, X2, Y2: Integer;
Begin
 HideMouse;
 ComputeNavLayout;
 { Fond global espace travail }
 FillBox(0, ToolY2 + 1, SCREEN_W - 1, SCREEN_H - STAT_H - 1, CLR_WIN_BG);
 { Cadre de la fenetre "Base de donnees" }
 X1 := 0; Y1 := ToolY2 + 1;
 X2 := SCREEN_W - 1; Y2 := SCREEN_H - STAT_H - 1;
 DrawRaised(X1, Y1, X2, Y2, CLR_WIN_BG, CLR_WIN_HI, CLR_WIN_LO);
 { Titre de la fenetre interne }
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 16, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 6, Y1 + 4, 'Base de donnees : ' + DB.Name);
 DrawNavSidePanel;
 { Onglets d'objets }
 DrawNavTab(1, 'Tables',       CurObjType = OBJ_TABLE);
 DrawNavTab(2, 'Requetes',     CurObjType = OBJ_QUERY);
 DrawNavTab(3, 'Formulaires',  CurObjType = OBJ_FORM);
 DrawNavTab(4, 'Etats',        CurObjType = OBJ_REPORT);
 DrawNavTab(5, 'Macros',       False);
 DrawNavTab(6, 'Modules',      False);
 DrawNavList;
 ShowMouse;
End;

{ ====================================================================== }
{                       UNDO / REDO                                      }
{ ====================================================================== }

Const
 UNDO_STACK = 64;
 UND_EDIT   = 1;
 UND_INSREC = 2;
 UND_DELREC = 3;

Type
 PUndoOp = ^TUndoOp;
 TUndoOp = Record
  Kind   : Byte;
  TblIdx : Integer;
  RecIdx : Integer;
  FldIdx : Integer;
  OldVal : TCellStr;
  NewVal : TCellStr;
  RecBak : TRecordData;
 End;

Var
 UndoStack : Array[1..UNDO_STACK] Of PUndoOp;
 UndoTop   : Integer;        { dernier valide }
 RedoStack : Array[1..UNDO_STACK] Of PUndoOp;
 RedoTop   : Integer;

Procedure UndoClear;
Var I: Integer;
Begin
 For I := 1 To UNDO_STACK Do Begin
  If UndoStack[I] <> Nil Then Begin FreeMem(UndoStack[I], SizeOf(TUndoOp)); UndoStack[I] := Nil; End;
  If RedoStack[I] <> Nil Then Begin FreeMem(RedoStack[I], SizeOf(TUndoOp)); RedoStack[I] := Nil; End;
 End;
 UndoTop := 0; RedoTop := 0;
End;

Procedure RedoClear;
Var I: Integer;
Begin
 For I := 1 To UNDO_STACK Do
  If RedoStack[I] <> Nil Then Begin FreeMem(RedoStack[I], SizeOf(TUndoOp)); RedoStack[I] := Nil; End;
 RedoTop := 0;
End;

Procedure UndoPush(Op: PUndoOp);
Var I: Integer; Old: PUndoOp;
Begin
 RedoClear;
 If UndoTop >= UNDO_STACK Then Begin
  { Drop bottom }
  Old := UndoStack[1];
  If Old <> Nil Then FreeMem(Old, SizeOf(TUndoOp));
  For I := 1 To UNDO_STACK - 1 Do UndoStack[I] := UndoStack[I + 1];
  UndoStack[UNDO_STACK] := Nil;
  Dec(UndoTop);
 End;
 Inc(UndoTop);
 UndoStack[UndoTop] := Op;
End;

Procedure DoUndo; Forward;
Procedure DoRedo; Forward;

{ ====================================================================== }
{                       EDITION CELLULE + COLONNE                        }
{ ====================================================================== }

Var
 DragCol      : Integer;       { colonne en cours de redimensionnement, 0=aucun }
 DragStartX   : LongInt;
 DragStartW   : Integer;
 DSheetY1     : Integer;       { y debut zone titre }
 DSheetHdrY   : Integer;       { y debut en-tete colonnes }
 DSheetBodyY  : Integer;       { y debut premiere ligne }
 DSheetBodyY2 : Integer;       { y fin zone donnees }
 DSheetVis    : Integer;       { lignes visibles }

Function CurTable: PTable;
Begin
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) Then
  CurTable := DB.Tables[CurTblIdx]
 Else CurTable := Nil;
End;

Procedure EnsureDSheetVisible;
Var T: PTable;
Begin
 T := CurTable;
 If T = Nil Then Exit;
 If CurRecIdx < 1 Then CurRecIdx := 1;
 If CurRecIdx > T^.RecCount Then CurRecIdx := T^.RecCount;
 If CurFldIdx < 1 Then CurFldIdx := 1;
 If CurFldIdx > T^.FldCount Then CurFldIdx := T^.FldCount;
 If DSheetVis < 1 Then DSheetVis := 1;
 If CurRecIdx <= DSheetScroll Then DSheetScroll := CurRecIdx - 1;
 If CurRecIdx > DSheetScroll + DSheetVis Then
  DSheetScroll := CurRecIdx - DSheetVis;
 If DSheetScroll < 0 Then DSheetScroll := 0;
End;

Procedure BeginEdit;
Var T: PTable;
Begin
 T := CurTable;
 If T = Nil Then Exit;
 If (CurRecIdx < 1) Or (CurRecIdx > T^.RecCount) Then Exit;
 If (CurFldIdx < 1) Or (CurFldIdx > T^.FldCount) Then Exit;
 If T^.Fields[CurFldIdx].FType = FT_AUTONUM Then Exit;
 EditBuf   := T^.Records[CurRecIdx]^.Values[CurFldIdx];
 EditCaret := Length(EditBuf);
 EditMode  := True;
 NeedGridRedraw := True;
End;

Procedure CommitEdit;
Var T: PTable; Op: PUndoOp; OldS: TCellStr;
Begin
 If Not EditMode Then Exit;
 T := CurTable;
 If T = Nil Then Begin EditMode := False; Exit; End;
 OldS := T^.Records[CurRecIdx]^.Values[CurFldIdx];
 If OldS <> EditBuf Then Begin
  GetMem(Op, SizeOf(TUndoOp));
  FillChar(Op^, SizeOf(TUndoOp), 0);
  Op^.Kind   := UND_EDIT;
  Op^.TblIdx := CurTblIdx;
  Op^.RecIdx := CurRecIdx;
  Op^.FldIdx := CurFldIdx;
  Op^.OldVal := OldS;
  Op^.NewVal := EditBuf;
  UndoPush(Op);
  T^.Records[CurRecIdx]^.Values[CurFldIdx] := EditBuf;
  T^.Dirty := True;
  DB.Dirty := True;
 End;
 EditMode := False;
 NeedGridRedraw := True;
End;

Procedure CancelEdit;
Begin
 If Not EditMode Then Exit;
 EditMode := False;
 NeedGridRedraw := True;
End;

Procedure EditInsertChar(C: Char);
Begin
 If Length(EditBuf) >= VAL_LEN Then Exit;
 If EditCaret < 0 Then EditCaret := 0;
 If EditCaret > Length(EditBuf) Then EditCaret := Length(EditBuf);
 EditBuf := Copy(EditBuf, 1, EditCaret) + C + Copy(EditBuf, EditCaret + 1, 255);
 Inc(EditCaret);
 NeedGridRedraw := True;
End;

Procedure EditBackspace;
Begin
 If EditCaret = 0 Then Exit;
 EditBuf := Copy(EditBuf, 1, EditCaret - 1) + Copy(EditBuf, EditCaret + 1, 255);
 Dec(EditCaret);
 NeedGridRedraw := True;
End;

Procedure EditDeleteChar;
Begin
 If EditCaret >= Length(EditBuf) Then Exit;
 EditBuf := Copy(EditBuf, 1, EditCaret) + Copy(EditBuf, EditCaret + 2, 255);
 NeedGridRedraw := True;
End;

{ ====================================================================== }
{                       VUE FEUILLE DE DONNEES                           }
{ ====================================================================== }

Procedure ComputeDSheetColumns;
Var T: PTable; I, X: Integer;
Begin
 T := CurTable;
 If T = Nil Then Exit;
 X := 30;                       { marge gauche pour selecteur ligne }
 For I := 1 To T^.FldCount Do Begin
  DSheetColX[I] := X;
  If DSheetColW[I] = 0 Then DSheetColW[I] := 96;
  X := X + DSheetColW[I];
 End;
End;

Function FieldAtX(X: LongInt; Var OverSep: Boolean): Integer;
Var T: PTable; I, Lx: Integer;
Begin
 OverSep := False;
 FieldAtX := 0;
 T := CurTable;
 If T = Nil Then Exit;
 For I := 1 To T^.FldCount Do Begin
  Lx := DSheetColX[I] + DSheetColW[I];
  If (X >= Lx - 3) And (X <= Lx + 3) Then Begin
   OverSep := True; FieldAtX := I; Exit;
  End;
  If (X >= DSheetColX[I]) And (X < Lx) Then Begin
   FieldAtX := I; Exit;
  End;
 End;
End;

Function RowAtY(Y: LongInt): Integer;
Begin
 RowAtY := 0;
 If Y < DSheetBodyY Then Exit;
 If Y >= DSheetBodyY2 Then Exit;
 RowAtY := DSheetScroll + (Y - DSheetBodyY) Div ROW_H + 1;
End;

Procedure DrawDSheetView;
Var T: PTable; X1, X2, Cx, I, J, RowY, R: Integer;
    S: TCellStr; Sel: Boolean; Cwidth: Integer;
    EditX1, EditY1, EditX2, EditY2, CxCaret: Integer; EditS: String;
Begin
 HideMouse;
 FillBox(0, ToolY2 + 1, SCREEN_W - 1, SCREEN_H - STAT_H - 1, CLR_GRID_BG);
 T := CurTable;
 If T = Nil Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(20, ToolY2 + 20, 'Aucune table selectionnee.');
  ShowMouse; Exit;
 End;
 ComputeDSheetColumns;
 DSheetY1     := ToolY2 + 2;
 DSheetHdrY   := DSheetY1 + 16;
 DSheetBodyY  := DSheetHdrY + GRID_HDR_H;
 DSheetBodyY2 := SCREEN_H - STAT_H - NAV_H - 2;
 DSheetVis    := (DSheetBodyY2 - DSheetBodyY) Div ROW_H;
 EnsureDSheetVisible;

 { Titre }
 FillBox(0, DSheetY1, SCREEN_W - 1, DSheetY1 + 14, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(6, DSheetY1 + 3, 'Table : ' + T^.Name);

 { En-tetes }
 FillBox(0, DSheetHdrY, SCREEN_W - 1, DSheetHdrY + GRID_HDR_H - 1, CLR_GRID_HDR_BG);
 HLine(0, SCREEN_W - 1, DSheetHdrY + GRID_HDR_H - 1, CLR_WIN_LO);
 SetColor(CLR_GRID_HDR_FG);
 For I := 1 To T^.FldCount Do Begin
  Cx := DSheetColX[I];
  Cwidth := DSheetColW[I];
  VLine(Cx, DSheetHdrY, DSheetHdrY + GRID_HDR_H - 1, CLR_WIN_LO);
  If I = CurFldIdx Then Begin
   FillBox(Cx + 1, DSheetHdrY + 1, Cx + Cwidth - 1, DSheetHdrY + GRID_HDR_H - 2,
           CLR_LGRAY);
   SetColor(CLR_BLACK);
  End
  Else SetColor(CLR_GRID_HDR_FG);
  OutTextXY(Cx + 4, DSheetHdrY + 4, T^.Fields[I].Name);
  If T^.Fields[I].PrimaryKey Then Begin
   SetColor(CLR_YELLOW);
   OutTextXY(Cx + Cwidth - 14, DSheetHdrY + 4, #20);
  End;
 End;

 { Lignes }
 RowY := DSheetBodyY;
 For J := 1 To DSheetVis Do Begin
  R := DSheetScroll + J;
  If R > T^.RecCount Then Break;
  Sel := (R = CurRecIdx);

  { Selecteur ligne }
  FillBox(0, RowY, 28, RowY + ROW_H - 1, CLR_GRID_HDR_BG);
  HLine(0, 28, RowY + ROW_H - 1, CLR_GRID_LINE);
  VLine(28, RowY, RowY + ROW_H - 1, CLR_WIN_LO);
  If Sel Then Begin
   SetColor(CLR_BLACK);
   If EditMode Then OutTextXY(8, RowY + 3, #18)   { crayon edition }
   Else             OutTextXY(8, RowY + 3, #16);  { fleche enr courant }
  End;

  For I := 1 To T^.FldCount Do Begin
   X1 := DSheetColX[I]; X2 := X1 + DSheetColW[I] - 1;
   If Sel And (I = CurFldIdx) Then Begin
    If EditMode Then
     FillBox(X1 + 1, RowY, X2, RowY + ROW_H - 1, CLR_WHITE)
    Else
     FillBox(X1 + 1, RowY, X2, RowY + ROW_H - 1, CLR_GRID_SEL_BG);
   End
   Else
    FillBox(X1 + 1, RowY, X2, RowY + ROW_H - 1, CLR_GRID_BG);
   VLine(X1, RowY, RowY + ROW_H - 1, CLR_GRID_LINE);
   If T^.Records[R]^.Deleted Then S := '(supprime)'
   Else                            S := T^.Records[R]^.Values[I];
   If Sel And (I = CurFldIdx) And EditMode Then Begin
    EditS := EditBuf;
    SetColor(CLR_BLACK);
    OutTextXY(X1 + 4, RowY + 3, EditS);
    If BlinkState Then Begin
     CxCaret := X1 + 4 + TextWidth(Copy(EditS, 1, EditCaret));
     Line(CxCaret, RowY + 1, CxCaret, RowY + ROW_H - 3);
    End;
   End
   Else Begin
    If Sel And (I = CurFldIdx) Then SetColor(CLR_GRID_SEL_FG)
    Else If Sel Then SetColor(CLR_BLACK)
    Else SetColor(CLR_GRID_TEXT);
    OutTextXY(X1 + 4, RowY + 3, S);
   End;
  End;
  { Bord droit dernier separateur }
  Cx := DSheetColX[T^.FldCount] + DSheetColW[T^.FldCount];
  VLine(Cx, RowY, RowY + ROW_H - 1, CLR_GRID_LINE);
  HLine(0, SCREEN_W - 1, RowY + ROW_H - 1, CLR_GRID_LINE);

  { Bordure cellule active }
  If Sel And (Not EditMode) Then Begin
   X1 := DSheetColX[CurFldIdx]; X2 := X1 + DSheetColW[CurFldIdx] - 1;
   SetColor(CLR_BLACK);
   Rectangle(X1, RowY, X2, RowY + ROW_H - 1);
  End;

  { Bordure cellule en edition }
  If Sel And EditMode Then Begin
   EditX1 := DSheetColX[CurFldIdx]; EditX2 := EditX1 + DSheetColW[CurFldIdx] - 1;
   EditY1 := RowY; EditY2 := RowY + ROW_H - 1;
   SetColor(CLR_BLACK);
   Rectangle(EditX1, EditY1, EditX2, EditY2);
  End;

  RowY := RowY + ROW_H;
 End;

 { Ligne "nouvel enregistrement" si place }
 If (T^.RecCount < MAX_RECORDS) And (RowY + ROW_H <= DSheetBodyY2) Then Begin
  FillBox(0, RowY, SCREEN_W - 1, RowY + ROW_H - 1, CLR_GRID_BG);
  SetColor(CLR_DGRAY);
  OutTextXY(36, RowY + 3, '*  (Nouvel enregistrement)');
  HLine(0, SCREEN_W - 1, RowY + ROW_H - 1, CLR_GRID_LINE);
 End;

 { Barre de navigation en bas }
 RowY := DSheetBodyY2 + 2;
 FillBox(0, RowY, SCREEN_W - 1, RowY + NAV_H, CLR_WIN_BG);
 HLine(0, SCREEN_W - 1, RowY, CLR_WIN_HI);
 SetColor(CLR_BLACK);
 OutTextXY(8, RowY + 5, 'Enregistrement :');
 DrawIcon(ICO_FIRST,  120, RowY);
 DrawIcon(ICO_PREV,   140, RowY);
 OutTextXY(168, RowY + 5,
   IntToStr(CurRecIdx) + ' sur ' + IntToStr(T^.RecCount));
 DrawIcon(ICO_NEXT,   250, RowY);
 DrawIcon(ICO_LAST,   270, RowY);
 DrawIcon(ICO_INSREC, 296, RowY);
 DrawIcon(ICO_DELREC, 320, RowY);
 ShowMouse;
End;

{ ====================================================================== }
{                       MODE CREATION DE TABLE (Phase 3)                 }
{ ====================================================================== }

Function TypeName(T: Byte): String;
Begin
 Case T Of
  FT_TEXT      : TypeName := 'Texte';
  FT_MEMO      : TypeName := 'Memo';
  FT_INTEGER   : TypeName := 'Entier';
  FT_LONG      : TypeName := 'Entier long';
  FT_SINGLE    : TypeName := 'Reel simple';
  FT_DOUBLE    : TypeName := 'Reel double';
  FT_CURRENCY  : TypeName := 'Monetaire';
  FT_DATE      : TypeName := 'Date';
  FT_TIME      : TypeName := 'Heure';
  FT_DATETIME  : TypeName := 'Date/Heure';
  FT_BOOL      : TypeName := 'Oui/Non';
  FT_AUTONUM   : TypeName := 'NumeroAuto';
  FT_OLE       : TypeName := 'Objet OLE';
  FT_HYPERLINK : TypeName := 'Lien hypertexte';
  FT_BINARY    : TypeName := 'Binaire';
 Else
  TypeName := '?';
 End;
End;

Function TypeDefaultSize(T: Byte): Integer;
Begin
 Case T Of
  FT_TEXT     : TypeDefaultSize := 50;
  FT_INTEGER  : TypeDefaultSize := 2;
  FT_LONG     : TypeDefaultSize := 4;
  FT_SINGLE   : TypeDefaultSize := 4;
  FT_DOUBLE   : TypeDefaultSize := 8;
  FT_CURRENCY : TypeDefaultSize := 8;
  FT_AUTONUM  : TypeDefaultSize := 4;
  FT_BOOL     : TypeDefaultSize := 1;
  FT_DATE     : TypeDefaultSize := 8;
  FT_TIME     : TypeDefaultSize := 8;
  FT_DATETIME : TypeDefaultSize := 8;
 Else
  TypeDefaultSize := 0;
 End;
End;

Const
 PROP_COUNT = 9;
 PROP_SIZE     = 1;
 PROP_FORMAT   = 2;
 PROP_INPMASK  = 3;
 PROP_CAPTION  = 4;
 PROP_DEFAULT  = 5;
 PROP_VRULE    = 6;
 PROP_VTEXT    = 7;
 PROP_REQUIRED = 8;
 PROP_INDEXED  = 9;

Function PropName(P: Integer): String;
Begin
 Case P Of
  PROP_SIZE     : PropName := 'Taille du champ';
  PROP_FORMAT   : PropName := 'Format';
  PROP_INPMASK  : PropName := 'Masque de saisie';
  PROP_CAPTION  : PropName := 'Legende';
  PROP_DEFAULT  : PropName := 'Valeur par defaut';
  PROP_VRULE    : PropName := 'Regle de validation';
  PROP_VTEXT    : PropName := 'Texte de validation';
  PROP_REQUIRED : PropName := 'Null interdit';
  PROP_INDEXED  : PropName := 'Indexe';
 Else
  PropName := '';
 End;
End;

Function PropValue(F: PField; P: Integer): String;
Begin
 PropValue := '';
 If F = Nil Then Exit;
 Case P Of
  PROP_SIZE     : PropValue := IntToStr(F^.Size);
  PROP_FORMAT   : PropValue := F^.Format;
  PROP_INPMASK  : PropValue := F^.InputMask;
  PROP_CAPTION  : PropValue := F^.Caption;
  PROP_DEFAULT  : PropValue := F^.DefaultVal;
  PROP_VRULE    : PropValue := F^.ValidRule;
  PROP_VTEXT    : PropValue := F^.ValidText;
  PROP_REQUIRED : If F^.Required   Then PropValue := 'Oui' Else PropValue := 'Non';
  PROP_INDEXED  : If F^.Indexed > 0 Then PropValue := 'Oui' Else PropValue := 'Non';
 End;
End;

Procedure PropSet(F: PField; P: Integer; Const V: String);
Var Code, N: Integer;
Begin
 If F = Nil Then Exit;
 Case P Of
  PROP_SIZE     : Begin Val(V, N, Code); If Code = 0 Then F^.Size := N; End;
  PROP_FORMAT   : F^.Format     := V;
  PROP_INPMASK  : F^.InputMask  := V;
  PROP_CAPTION  : F^.Caption    := V;
  PROP_DEFAULT  : F^.DefaultVal := V;
  PROP_VRULE    : F^.ValidRule  := V;
  PROP_VTEXT    : F^.ValidText  := V;
  PROP_REQUIRED : F^.Required   := (V = 'Oui') Or (V = 'oui') Or (V = 'O') Or (V = '1');
  PROP_INDEXED  : If (V = 'Oui') Or (V = 'oui') Or (V = 'O') Or (V = '1') Then F^.Indexed := 1 Else F^.Indexed := 0;
 End;
End;

Function DesignColumnX(C: Integer): Integer;
Begin
 Case C Of
  1: DesignColumnX := 0;
  2: DesignColumnX := 28;
  3: DesignColumnX := 228;
  4: DesignColumnX := 378;
 Else
  DesignColumnX := 0;
 End;
End;

Function DesignColumnW(C: Integer): Integer;
Begin
 Case C Of
  1: DesignColumnW := 28;
  2: DesignColumnW := 200;
  3: DesignColumnW := 150;
  4: DesignColumnW := SCREEN_W - 378;
 Else
  DesignColumnW := 0;
 End;
End;

Procedure EnsureDesignVisible;
Var T: PTable;
Begin
 T := CurTable;
 If T = Nil Then Exit;
 If DesignSelRow < 1 Then DesignSelRow := 1;
 If DesignSelRow > T^.FldCount + 1 Then DesignSelRow := T^.FldCount + 1;
 If DesignSelRow > MAX_FIELDS Then DesignSelRow := MAX_FIELDS;
 If DesignVis < 1 Then DesignVis := 1;
 If DesignSelRow <= DesignTopRow Then DesignTopRow := DesignSelRow - 1;
 If DesignSelRow > DesignTopRow + DesignVis Then
  DesignTopRow := DesignSelRow - DesignVis;
 If DesignTopRow < 0 Then DesignTopRow := 0;
End;

Procedure BeginDesignEdit;
Var T: PTable; F: PField;
Begin
 T := CurTable; If T = Nil Then Exit;
 If DesignFocus = 0 Then Begin
  If DesignSelCol = 1 Then Exit;
  If DesignSelCol = 3 Then Begin
   DesignTypeDrop := True;
   If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then
    DesignTypeDropSel := T^.Fields[DesignSelRow].FType
   Else DesignTypeDropSel := FT_TEXT;
   NeedFullRedraw := True;
   Exit;
  End;
  If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then Begin
   F := @T^.Fields[DesignSelRow];
   Case DesignSelCol Of
    2: EditBuf := F^.Name;
    4: EditBuf := F^.Description;
   End;
  End
  Else EditBuf := '';
 End
 Else Begin
  If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then Begin
   F := @T^.Fields[DesignSelRow];
   EditBuf := PropValue(F, DesignPropSel);
  End
  Else Exit;
 End;
 EditCaret := Length(EditBuf);
 EditMode  := True;
 NeedFullRedraw := True;
End;

Procedure CommitDesignEdit;
Var T: PTable; F: PField; I: Integer;
Begin
 If Not EditMode Then Exit;
 T := CurTable; If T = Nil Then Begin EditMode := False; Exit; End;
 If DesignFocus = 0 Then Begin
  If DesignSelCol = 2 Then Begin
   { Nom : si ligne au-dela de FldCount, on ajoute un champ }
   If (DesignSelRow = T^.FldCount + 1) And (EditBuf <> '') Then Begin
    If T^.FldCount < MAX_FIELDS Then Begin
     Inc(T^.FldCount);
     F := @T^.Fields[T^.FldCount];
     FillChar(F^, SizeOf(TField), 0);
     F^.Name  := EditBuf;
     F^.FType := FT_TEXT;
     F^.Size := TypeDefaultSize(FT_TEXT);
     F^.AllowNull := True;
     T^.Dirty := True; DB.Dirty := True;
     { Etendre les enregistrements existants avec valeur vide }
     For I := 1 To T^.RecCount Do
      If T^.Records[I] <> Nil Then T^.Records[I]^.Values[T^.FldCount] := '';
    End;
   End
   Else If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then Begin
    T^.Fields[DesignSelRow].Name := EditBuf;
    T^.Dirty := True; DB.Dirty := True;
   End;
  End
  Else If DesignSelCol = 4 Then Begin
   If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then Begin
    T^.Fields[DesignSelRow].Description := EditBuf;
    T^.Dirty := True; DB.Dirty := True;
   End;
  End;
 End
 Else Begin
  If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then Begin
   F := @T^.Fields[DesignSelRow];
   PropSet(F, DesignPropSel, EditBuf);
   T^.Dirty := True; DB.Dirty := True;
  End;
 End;
 EditMode := False;
 NeedFullRedraw := True;
End;

Procedure CancelDesignEdit;
Begin
 If Not EditMode Then Exit;
 EditMode := False;
 NeedFullRedraw := True;
End;

Procedure DesignAddField;
Var T: PTable; F: PField; I: Integer;
Begin
 T := CurTable; If T = Nil Then Exit;
 If T^.FldCount >= MAX_FIELDS Then Begin
  StatusMsg := 'Limite de champs atteinte.'; NeedStatRedraw := True; Exit;
 End;
 Inc(T^.FldCount);
 F := @T^.Fields[T^.FldCount];
 FillChar(F^, SizeOf(TField), 0);
 F^.Name  := 'Champ' + IntToStr(T^.FldCount);
 F^.FType := FT_TEXT;
 F^.Size := TypeDefaultSize(FT_TEXT);
 F^.AllowNull := True;
 For I := 1 To T^.RecCount Do
  If T^.Records[I] <> Nil Then T^.Records[I]^.Values[T^.FldCount] := '';
 DesignSelRow := T^.FldCount;
 DesignSelCol := 2;
 T^.Dirty := True; DB.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure DesignDelField;
Var T: PTable; I, J: Integer;
Begin
 T := CurTable; If T = Nil Then Exit;
 If (DesignSelRow < 1) Or (DesignSelRow > T^.FldCount) Then Exit;
 If T^.FldCount <= 1 Then Begin
  StatusMsg := 'Une table doit avoir au moins un champ.';
  NeedStatRedraw := True; Exit;
 End;
 { Decaler champs }
 For I := DesignSelRow To T^.FldCount - 1 Do
  T^.Fields[I] := T^.Fields[I + 1];
 FillChar(T^.Fields[T^.FldCount], SizeOf(TField), 0);
 { Decaler valeurs des enregistrements }
 For J := 1 To T^.RecCount Do
  If T^.Records[J] <> Nil Then Begin
   For I := DesignSelRow To T^.FldCount - 1 Do
    T^.Records[J]^.Values[I] := T^.Records[J]^.Values[I + 1];
   T^.Records[J]^.Values[T^.FldCount] := '';
  End;
 Dec(T^.FldCount);
 If DesignSelRow > T^.FldCount Then DesignSelRow := T^.FldCount;
 If DesignSelRow < 1 Then DesignSelRow := 1;
 T^.Dirty := True; DB.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure DesignTogglePK;
Var T: PTable; I: Integer;
Begin
 T := CurTable; If T = Nil Then Exit;
 If (DesignSelRow < 1) Or (DesignSelRow > T^.FldCount) Then Exit;
 If T^.Fields[DesignSelRow].PrimaryKey Then
  T^.Fields[DesignSelRow].PrimaryKey := False
 Else Begin
  For I := 1 To T^.FldCount Do T^.Fields[I].PrimaryKey := False;
  T^.Fields[DesignSelRow].PrimaryKey := True;
  T^.Fields[DesignSelRow].Required   := True;
  T^.Fields[DesignSelRow].Indexed    := 2;
 End;
 T^.Dirty := True; DB.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure DesignSetType(NewType: Byte);
Var T: PTable; F: PField;
Begin
 T := CurTable; If T = Nil Then Exit;
 If (DesignSelRow < 1) Or (DesignSelRow > T^.FldCount) Then Exit;
 F := @T^.Fields[DesignSelRow];
 F^.FType := NewType;
 F^.Size := TypeDefaultSize(NewType);
 T^.Dirty := True; DB.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure DrawDesignView;
Var T: PTable; F: PField; X, Y, X1, X2, I, J, R, RowY, NumRows: Integer;
    S: String; Sel: Boolean; CellX, CellW, CxCaret: Integer;
    Y0, PropX1, PropX2, PropY1, PropY2, PropRowH: Integer;
Begin
 HideMouse;
 FillBox(0, ToolY2 + 1, SCREEN_W - 1, SCREEN_H - STAT_H - 1, CLR_WIN_BG);
 T := CurTable;
 If T = Nil Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(20, ToolY2 + 20, 'Aucune table selectionnee. Creer une nouvelle table.');
  ShowMouse; Exit;
 End;
 Y0 := ToolY2 + 2;
 DesignSplitY := Y0 + 14 + 18 + 16 * 10 + 4;
 If DesignSplitY > SCREEN_H - STAT_H - 130 Then
  DesignSplitY := SCREEN_H - STAT_H - 130;
 DesignGridY  := Y0 + 16;
 DesignBodyY  := DesignGridY + 18;
 DesignGridY2 := DesignSplitY - 4;
 DesignVis    := (DesignGridY2 - DesignBodyY) Div 16;
 DesignPropY  := DesignSplitY + 2;
 EnsureDesignVisible;

 { Titre }
 FillBox(0, Y0, SCREEN_W - 1, Y0 + 14, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(6, Y0 + 3, 'Table : ' + T^.Name + '   (Mode Creation)');

 { En-tete grille }
 FillBox(0, DesignGridY, SCREEN_W - 1, DesignGridY + 17, CLR_GRID_HDR_BG);
 SetColor(CLR_GRID_HDR_FG);
 OutTextXY(DesignColumnX(2) + 4, DesignGridY + 4, 'Nom du champ');
 OutTextXY(DesignColumnX(3) + 4, DesignGridY + 4, 'Type de donnees');
 OutTextXY(DesignColumnX(4) + 4, DesignGridY + 4, 'Description');
 For I := 1 To 4 Do Begin
  X := DesignColumnX(I);
  VLine(X, DesignGridY, DesignGridY + 17, CLR_WIN_LO);
 End;
 HLine(0, SCREEN_W - 1, DesignGridY + 17, CLR_WIN_LO);

 { Lignes grille }
 NumRows := T^.FldCount + 1;     { ligne supplementaire pour nouveau }
 If NumRows > MAX_FIELDS Then NumRows := MAX_FIELDS;
 RowY := DesignBodyY;
 For J := 1 To DesignVis Do Begin
  R := DesignTopRow + J;
  If R > NumRows Then Break;
  Sel := (DesignFocus = 0) And (R = DesignSelRow);
  FillBox(0, RowY, SCREEN_W - 1, RowY + 15, CLR_GRID_BG);
  { Selecteur ligne }
  If Sel Then Begin
   FillBox(0, RowY, 27, RowY + 15, CLR_GRID_HDR_BG);
   SetColor(CLR_BLACK);
   OutTextXY(10, RowY + 3, #16);
  End;
  { PK : icone cle si primaire }
  If (R <= T^.FldCount) And T^.Fields[R].PrimaryKey Then Begin
   SetColor(CLR_YELLOW); FillBox(8, RowY + 4, 16, RowY + 9, CLR_YELLOW);
   SetColor(CLR_BLACK); Rectangle(8, RowY + 4, 16, RowY + 9);
   Line(16, RowY + 6, 22, RowY + 6);
   Line(20, RowY + 5, 20, RowY + 8);
  End;
  { Nom du champ }
  CellX := DesignColumnX(2); CellW := DesignColumnW(2);
  If R <= T^.FldCount Then S := T^.Fields[R].Name Else S := '';
  If Sel And (DesignSelCol = 2) Then Begin
   If EditMode Then FillBox(CellX + 1, RowY, CellX + CellW - 1, RowY + 15, CLR_WHITE)
   Else             FillBox(CellX + 1, RowY, CellX + CellW - 1, RowY + 15, CLR_GRID_SEL_BG);
   If EditMode Then Begin
    SetColor(CLR_BLACK);
    OutTextXY(CellX + 4, RowY + 3, EditBuf);
    If BlinkState Then Begin
     CxCaret := CellX + 4 + TextWidth(Copy(EditBuf, 1, EditCaret));
     Line(CxCaret, RowY + 1, CxCaret, RowY + 13);
    End;
   End
   Else Begin SetColor(CLR_GRID_SEL_FG); OutTextXY(CellX + 4, RowY + 3, S); End;
  End
  Else Begin
   SetColor(CLR_GRID_TEXT);
   OutTextXY(CellX + 4, RowY + 3, S);
  End;
  { Type }
  CellX := DesignColumnX(3); CellW := DesignColumnW(3);
  If R <= T^.FldCount Then S := TypeName(T^.Fields[R].FType) Else S := '';
  If Sel And (DesignSelCol = 3) Then Begin
   FillBox(CellX + 1, RowY, CellX + CellW - 1, RowY + 15, CLR_GRID_SEL_BG);
   SetColor(CLR_GRID_SEL_FG);
  End
  Else SetColor(CLR_GRID_TEXT);
  OutTextXY(CellX + 4, RowY + 3, S);
  { Fleche combo }
  If R <= T^.FldCount Then Begin
   SetColor(CLR_BLACK);
   OutTextXY(CellX + CellW - 10, RowY + 3, #25);
  End;
  { Description }
  CellX := DesignColumnX(4); CellW := DesignColumnW(4);
  If R <= T^.FldCount Then S := T^.Fields[R].Description Else S := '';
  If Sel And (DesignSelCol = 4) Then Begin
   If EditMode Then FillBox(CellX + 1, RowY, CellX + CellW - 1, RowY + 15, CLR_WHITE)
   Else             FillBox(CellX + 1, RowY, CellX + CellW - 1, RowY + 15, CLR_GRID_SEL_BG);
   If EditMode Then Begin
    SetColor(CLR_BLACK);
    OutTextXY(CellX + 4, RowY + 3, EditBuf);
    If BlinkState Then Begin
     CxCaret := CellX + 4 + TextWidth(Copy(EditBuf, 1, EditCaret));
     Line(CxCaret, RowY + 1, CxCaret, RowY + 13);
    End;
   End
   Else Begin SetColor(CLR_GRID_SEL_FG); OutTextXY(CellX + 4, RowY + 3, S); End;
  End
  Else Begin
   SetColor(CLR_GRID_TEXT);
   OutTextXY(CellX + 4, RowY + 3, S);
  End;
  { Separateurs verticaux }
  For I := 1 To 4 Do Begin
   X := DesignColumnX(I);
   SetColor(CLR_WIN_LO); VLine(X, RowY, RowY + 15, CLR_WIN_LO);
  End;
  HLine(0, SCREEN_W - 1, RowY + 15, CLR_GRID_LINE);
  { Bordure cellule active }
  If Sel And (Not EditMode) Then Begin
   X1 := DesignColumnX(DesignSelCol);
   X2 := X1 + DesignColumnW(DesignSelCol) - 1;
   SetColor(CLR_BLACK);
   Rectangle(X1, RowY, X2, RowY + 15);
  End;
  RowY := RowY + 16;
 End;

 { Splitter }
 FillBox(0, DesignSplitY - 4, SCREEN_W - 1, DesignSplitY, CLR_WIN_BG);
 DrawRaised(0, DesignSplitY - 3, SCREEN_W - 1, DesignSplitY - 1, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);

 { Panneau proprietes }
 PropY1 := DesignPropY;
 PropY2 := SCREEN_H - STAT_H - 1;
 FillBox(0, PropY1, SCREEN_W - 1, PropY2, CLR_WIN_BG);
 SetColor(CLR_DLG_TITLE_BG);
 FillBox(0, PropY1, SCREEN_W - 1, PropY1 + 14, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then
  OutTextXY(6, PropY1 + 3, 'Proprietes du champ : ' + T^.Fields[DesignSelRow].Name)
 Else
  OutTextXY(6, PropY1 + 3, 'Proprietes du champ');
 PropX1 := 0; PropX2 := 220;
 PropRowH := 12;
 Y := PropY1 + 18;
 If (DesignSelRow >= 1) And (DesignSelRow <= T^.FldCount) Then
  F := @T^.Fields[DesignSelRow]
 Else F := Nil;
 For I := 1 To PROP_COUNT Do Begin
  Sel := (DesignFocus = 1) And (I = DesignPropSel);
  If Sel Then Begin
   FillBox(0, Y, SCREEN_W - 1, Y + PropRowH - 1, CLR_GRID_SEL_BG);
   SetColor(CLR_GRID_SEL_FG);
  End
  Else SetColor(CLR_BLACK);
  OutTextXY(8, Y + 2, PropName(I));
  If Sel And EditMode Then Begin
   FillBox(PropX2, Y, SCREEN_W - 4, Y + PropRowH - 1, CLR_WHITE);
   SetColor(CLR_BLACK);
   OutTextXY(PropX2 + 4, Y + 2, EditBuf);
   If BlinkState Then Begin
    CxCaret := PropX2 + 4 + TextWidth(Copy(EditBuf, 1, EditCaret));
    Line(CxCaret, Y + 1, CxCaret, Y + PropRowH - 2);
   End;
  End
  Else Begin
   OutTextXY(PropX2 + 4, Y + 2, PropValue(F, I));
  End;
  VLine(PropX2 - 2, Y, Y + PropRowH - 1, CLR_WIN_LO);
  Y := Y + PropRowH;
 End;
 { Aide en bas }
 SetColor(CLR_DGRAY);
 OutTextXY(8, PropY2 - 16,
  'F6=Basculer  F2/Entree=Editer  Ins=Nouv. champ  Suppr=Eff. champ  F4=Type');

 { Liste deroulante des types }
 If DesignTypeDrop Then Begin
  X1 := DesignColumnX(3); X2 := X1 + DesignColumnW(3);
  Y := DesignBodyY + ((DesignSelRow - DesignTopRow) * 16);
  If Y > DesignGridY2 - 16 * 15 Then Y := DesignBodyY;
  Y0 := Y + 16;
  X := Y0 + 15 * 14;
  If X > SCREEN_H - STAT_H - 4 Then Begin Y0 := Y - 15 * 14; End;
  FillBox(X1, Y0, X2 + 2, Y0 + 15 * 14, CLR_WHITE);
  SetColor(CLR_BLACK); Rectangle(X1, Y0, X2 + 2, Y0 + 15 * 14);
  For I := 1 To 15 Do Begin
   If I = DesignTypeDropSel Then Begin
    FillBox(X1 + 1, Y0 + (I - 1) * 14 + 1, X2 + 1, Y0 + I * 14, CLR_GRID_SEL_BG);
    SetColor(CLR_GRID_SEL_FG);
   End
   Else SetColor(CLR_BLACK);
   OutTextXY(X1 + 6, Y0 + (I - 1) * 14 + 3, TypeName(I));
  End;
  DesignTypeDropX := X1;
  DesignTypeDropY := Y0;
 End;
 ShowMouse;
End;

{ ====================================================================== }
{                       MOTEUR SQL (Phase 4)                             }
{ ====================================================================== }

Const
 TK_EOF=0; TK_IDENT=1; TK_KW=2; TK_NUMBER=3; TK_STRING=4;
 TK_OP=5; TK_COMMA=6; TK_LPAREN=7; TK_RPAREN=8; TK_STAR=9; TK_SEMI=10;
 TK_DOT=11;

 KW_SELECT=1; KW_FROM=2; KW_WHERE=3; KW_ORDER=4; KW_BY=5; KW_ASC=6;
 KW_DESC=7; KW_INSERT=8; KW_INTO=9; KW_VALUES=10; KW_UPDATE=11;
 KW_SET=12; KW_DELETE=13; KW_CREATE=14; KW_TABLE=15; KW_DROP=16;
 KW_AND=17; KW_OR=18; KW_NOT=19; KW_LIKE=20; KW_NULL=21;
 KW_TRUE=22; KW_FALSE=23; KW_AS=24; KW_DISTINCT=25;

 OP_EQ=1; OP_NE=2; OP_LT=3; OP_LE=4; OP_GT=5; OP_GE=6;
 OP_ADD=7; OP_SUB=8; OP_MUL=9; OP_DIV=10; OP_LIKE=11;

Var
 SqlSrc    : String;
 SqlPos    : Integer;
 TokKind   : Integer;
 TokKw     : Integer;
 TokOp     : Integer;
 TokStr    : String;
 TokNum    : LongInt;
 SqlErr    : Boolean;
 SqlErrMsg : String;

Function SqlIsAlpha(C: Char): Boolean;
Begin
 SqlIsAlpha := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or (C = '_');
End;

Function SqlIsDigit(C: Char): Boolean;
Begin
 SqlIsDigit := (C >= '0') And (C <= '9');
End;

Function SqlIsAlnum(C: Char): Boolean;
Begin
 SqlIsAlnum := SqlIsAlpha(C) Or SqlIsDigit(C);
End;

Function SqlKwId(Const S: String): Integer;
Var U: String;
Begin
 U := UpperStr(S);
 SqlKwId := 0;
 If U = 'SELECT'   Then SqlKwId := KW_SELECT
 Else If U = 'FROM'     Then SqlKwId := KW_FROM
 Else If U = 'WHERE'    Then SqlKwId := KW_WHERE
 Else If U = 'ORDER'    Then SqlKwId := KW_ORDER
 Else If U = 'BY'       Then SqlKwId := KW_BY
 Else If U = 'ASC'      Then SqlKwId := KW_ASC
 Else If U = 'DESC'     Then SqlKwId := KW_DESC
 Else If U = 'INSERT'   Then SqlKwId := KW_INSERT
 Else If U = 'INTO'     Then SqlKwId := KW_INTO
 Else If U = 'VALUES'   Then SqlKwId := KW_VALUES
 Else If U = 'UPDATE'   Then SqlKwId := KW_UPDATE
 Else If U = 'SET'      Then SqlKwId := KW_SET
 Else If U = 'DELETE'   Then SqlKwId := KW_DELETE
 Else If U = 'CREATE'   Then SqlKwId := KW_CREATE
 Else If U = 'TABLE'    Then SqlKwId := KW_TABLE
 Else If U = 'DROP'     Then SqlKwId := KW_DROP
 Else If U = 'AND'      Then SqlKwId := KW_AND
 Else If U = 'OR'       Then SqlKwId := KW_OR
 Else If U = 'NOT'      Then SqlKwId := KW_NOT
 Else If U = 'LIKE'     Then SqlKwId := KW_LIKE
 Else If U = 'NULL'     Then SqlKwId := KW_NULL
 Else If U = 'TRUE'     Then SqlKwId := KW_TRUE
 Else If U = 'FALSE'    Then SqlKwId := KW_FALSE
 Else If U = 'AS'       Then SqlKwId := KW_AS
 Else If U = 'DISTINCT' Then SqlKwId := KW_DISTINCT;
End;

Procedure SqlSetError(Const Msg: String);
Begin
 If Not SqlErr Then Begin
  SqlErr    := True;
  SqlErrMsg := Msg;
 End;
End;

Procedure NextToken;
Var C: Char; Start: Integer; S: String; KwId, Code: Integer; N: LongInt;
Begin
 TokKind := TK_EOF;
 TokStr  := '';
 TokKw   := 0;
 TokOp   := 0;
 TokNum  := 0;
 While (SqlPos <= Length(SqlSrc)) And (SqlSrc[SqlPos] In [' ', #9, #10, #13]) Do Inc(SqlPos);
 If SqlPos > Length(SqlSrc) Then Exit;
 C := SqlSrc[SqlPos];
 { Identificateur ou mot-cle }
 If SqlIsAlpha(C) Then Begin
  Start := SqlPos;
  While (SqlPos <= Length(SqlSrc)) And SqlIsAlnum(SqlSrc[SqlPos]) Do Inc(SqlPos);
  S := Copy(SqlSrc, Start, SqlPos - Start);
  KwId := SqlKwId(S);
  If KwId = KW_LIKE Then Begin
   TokKind := TK_OP; TokOp := OP_LIKE; TokStr := S; Exit;
  End;
  If KwId > 0 Then Begin
   TokKind := TK_KW; TokKw := KwId; TokStr := S; Exit;
  End;
  TokKind := TK_IDENT; TokStr := S; Exit;
 End;
 { Nombre }
 If SqlIsDigit(C) Then Begin
  Start := SqlPos;
  While (SqlPos <= Length(SqlSrc)) And SqlIsDigit(SqlSrc[SqlPos]) Do Inc(SqlPos);
  If (SqlPos <= Length(SqlSrc)) And (SqlSrc[SqlPos] = '.') Then Begin
   Inc(SqlPos);
   While (SqlPos <= Length(SqlSrc)) And SqlIsDigit(SqlSrc[SqlPos]) Do Inc(SqlPos);
  End;
  TokKind := TK_NUMBER;
  TokStr  := Copy(SqlSrc, Start, SqlPos - Start);
  Val(TokStr, N, Code);
  If Code = 0 Then TokNum := N Else TokNum := 0;
  Exit;
 End;
 { Chaine 'litterale' }
 If C = '''' Then Begin
  Inc(SqlPos);
  Start := SqlPos;
  While SqlPos <= Length(SqlSrc) Do Begin
   If SqlSrc[SqlPos] = '''' Then Begin
    If (SqlPos < Length(SqlSrc)) And (SqlSrc[SqlPos + 1] = '''') Then Begin
     TokStr := TokStr + Copy(SqlSrc, Start, SqlPos - Start) + '''';
     Inc(SqlPos, 2);
     Start := SqlPos;
    End
    Else Begin
     TokStr := TokStr + Copy(SqlSrc, Start, SqlPos - Start);
     Inc(SqlPos);
     TokKind := TK_STRING; Exit;
    End;
   End
   Else Inc(SqlPos);
  End;
  SqlSetError('Chaine non terminee');
  TokKind := TK_STRING; Exit;
 End;
 { Operateurs et ponctuation }
 Case C Of
  ',': Begin TokKind := TK_COMMA;  Inc(SqlPos); End;
  '(': Begin TokKind := TK_LPAREN; Inc(SqlPos); End;
  ')': Begin TokKind := TK_RPAREN; Inc(SqlPos); End;
  '*': Begin TokKind := TK_STAR;   Inc(SqlPos); End;
  ';': Begin TokKind := TK_SEMI;   Inc(SqlPos); End;
  '.': Begin TokKind := TK_DOT;    Inc(SqlPos); End;
  '+': Begin TokKind := TK_OP; TokOp := OP_ADD; Inc(SqlPos); End;
  '-': Begin TokKind := TK_OP; TokOp := OP_SUB; Inc(SqlPos); End;
  '/': Begin TokKind := TK_OP; TokOp := OP_DIV; Inc(SqlPos); End;
  '=': Begin TokKind := TK_OP; TokOp := OP_EQ; Inc(SqlPos); End;
  '<': Begin
   Inc(SqlPos);
   If (SqlPos <= Length(SqlSrc)) And (SqlSrc[SqlPos] = '=') Then Begin
    TokKind := TK_OP; TokOp := OP_LE; Inc(SqlPos);
   End
   Else If (SqlPos <= Length(SqlSrc)) And (SqlSrc[SqlPos] = '>') Then Begin
    TokKind := TK_OP; TokOp := OP_NE; Inc(SqlPos);
   End
   Else Begin TokKind := TK_OP; TokOp := OP_LT; End;
  End;
  '>': Begin
   Inc(SqlPos);
   If (SqlPos <= Length(SqlSrc)) And (SqlSrc[SqlPos] = '=') Then Begin
    TokKind := TK_OP; TokOp := OP_GE; Inc(SqlPos);
   End
   Else Begin TokKind := TK_OP; TokOp := OP_GT; End;
  End;
  '!': Begin
   Inc(SqlPos);
   If (SqlPos <= Length(SqlSrc)) And (SqlSrc[SqlPos] = '=') Then Begin
    TokKind := TK_OP; TokOp := OP_NE; Inc(SqlPos);
   End
   Else SqlSetError('Caractere ! inattendu');
  End;
  Else Begin
   SqlSetError('Caractere inattendu : ' + C);
   Inc(SqlPos);
  End;
 End;
End;

Function FindTableByName(Const N: String): Integer;
Var I: Integer; U: String;
Begin
 U := UpperStr(N);
 FindTableByName := 0;
 For I := 1 To DB.TblCount Do
  If (DB.Tables[I] <> Nil) And (UpperStr(DB.Tables[I]^.Name) = U) Then Begin
   FindTableByName := I; Exit;
  End;
End;

Function FindField(TblIdx: Integer; Const N: String): Integer;
Var I: Integer; T: PTable; U: String;
Begin
 FindField := 0;
 If (TblIdx < 1) Or (TblIdx > DB.TblCount) Then Exit;
 T := DB.Tables[TblIdx]; If T = Nil Then Exit;
 U := UpperStr(N);
 For I := 1 To T^.FldCount Do
  If UpperStr(T^.Fields[I].Name) = U Then Begin
   FindField := I; Exit;
  End;
End;

Function SqlIsNumeric(Const S: String): Boolean;
Var I: Integer; HasDigit: Boolean;
Begin
 SqlIsNumeric := False;
 If S = '' Then Exit;
 I := 1;
 If (S[1] = '+') Or (S[1] = '-') Then Inc(I);
 HasDigit := False;
 While I <= Length(S) Do Begin
  If SqlIsDigit(S[I]) Then HasDigit := True
  Else If S[I] = '.' Then { ok }
  Else Exit;
  Inc(I);
 End;
 SqlIsNumeric := HasDigit;
End;

Function SqlNum(Const S: String): Real;
Var R: Real; Code: Integer;
Begin
 Val(S, R, Code);
 If Code <> 0 Then SqlNum := 0 Else SqlNum := R;
End;

Function SqlCompare(Const A, B: String): Integer;
Var X, Y: Real; UA, UB: String;
Begin
 If SqlIsNumeric(A) And SqlIsNumeric(B) Then Begin
  X := SqlNum(A); Y := SqlNum(B);
  If X < Y Then SqlCompare := -1
  Else If X > Y Then SqlCompare := 1
  Else SqlCompare := 0;
  Exit;
 End;
 UA := UpperStr(A); UB := UpperStr(B);
 If UA < UB Then SqlCompare := -1
 Else If UA > UB Then SqlCompare := 1
 Else SqlCompare := 0;
End;

Function SqlLikeMatch(Const S, Pat: String): Boolean;
Var Si, Pi: Integer; US, UP: String;
 Function MatchAt(Si, Pi: Integer): Boolean;
 Begin
  While Pi <= Length(UP) Do Begin
   If UP[Pi] = '%' Then Begin
    Inc(Pi);
    If Pi > Length(UP) Then Begin MatchAt := True; Exit; End;
    While Si <= Length(US) + 1 Do Begin
     If MatchAt(Si, Pi) Then Begin MatchAt := True; Exit; End;
     Inc(Si);
    End;
    MatchAt := False; Exit;
   End
   Else If UP[Pi] = '_' Then Begin
    If Si > Length(US) Then Begin MatchAt := False; Exit; End;
    Inc(Si); Inc(Pi);
   End
   Else Begin
    If (Si > Length(US)) Or (US[Si] <> UP[Pi]) Then Begin MatchAt := False; Exit; End;
    Inc(Si); Inc(Pi);
   End;
  End;
  MatchAt := Si > Length(US);
 End;
Begin
 US := UpperStr(S); UP := UpperStr(Pat);
 SqlLikeMatch := MatchAt(1, 1);
End;

{ Evaluation d'expression : forward decls }
Function EvalExpr(TblIdx, RecIdx: Integer): String; Forward;

Function EvalFactor(TblIdx, RecIdx: Integer): String;
Var V, FldName: String; FIdx: Integer; T: PTable;
Begin
 EvalFactor := '';
 If SqlErr Then Exit;
 Case TokKind Of
  TK_NUMBER: Begin EvalFactor := TokStr; NextToken; End;
  TK_STRING: Begin EvalFactor := TokStr; NextToken; End;
  TK_LPAREN: Begin
   NextToken;
   V := EvalExpr(TblIdx, RecIdx);
   If TokKind <> TK_RPAREN Then SqlSetError(') attendue')
   Else NextToken;
   EvalFactor := V;
  End;
  TK_OP: Begin
   If TokOp = OP_SUB Then Begin
    NextToken;
    V := EvalFactor(TblIdx, RecIdx);
    If SqlIsNumeric(V) Then EvalFactor := IntToStr(-Trunc(SqlNum(V)))
    Else EvalFactor := V;
   End
   Else SqlSetError('Operateur inattendu');
  End;
  TK_IDENT: Begin
   FldName := TokStr;
   NextToken;
   { tbl.col ignore tbl prefix }
   If TokKind = TK_DOT Then Begin
    NextToken;
    If TokKind = TK_IDENT Then Begin FldName := TokStr; NextToken; End
    Else SqlSetError('Nom de colonne attendu');
   End;
   If (TblIdx > 0) And (RecIdx > 0) Then Begin
    T := DB.Tables[TblIdx];
    FIdx := FindField(TblIdx, FldName);
    If FIdx = 0 Then SqlSetError('Colonne inconnue : ' + FldName)
    Else If (RecIdx <= T^.RecCount) And (T^.Records[RecIdx] <> Nil) Then
     EvalFactor := T^.Records[RecIdx]^.Values[FIdx];
   End
   Else EvalFactor := FldName;
  End;
  TK_KW: Begin
   Case TokKw Of
    KW_NULL : Begin EvalFactor := ''; NextToken; End;
    KW_TRUE : Begin EvalFactor := 'T'; NextToken; End;
    KW_FALSE: Begin EvalFactor := 'F'; NextToken; End;
    Else SqlSetError('Expression attendue');
   End;
  End;
  Else SqlSetError('Expression attendue');
 End;
End;

Function EvalMul(TblIdx, RecIdx: Integer): String;
Var L, R: String; Op: Integer;
Begin
 L := EvalFactor(TblIdx, RecIdx);
 While (Not SqlErr) And (TokKind = TK_OP) And ((TokOp = OP_MUL) Or (TokOp = OP_DIV)) Do Begin
  Op := TokOp; NextToken;
  R := EvalFactor(TblIdx, RecIdx);
  If SqlIsNumeric(L) And SqlIsNumeric(R) Then Begin
   If Op = OP_MUL Then L := IntToStr(Trunc(SqlNum(L) * SqlNum(R)))
   Else If SqlNum(R) <> 0 Then L := IntToStr(Trunc(SqlNum(L) / SqlNum(R)))
   Else L := '0';
  End
  Else L := '';
 End;
 { TK_STAR seul peut apparaitre apres un identificateur en multiplication }
 While (Not SqlErr) And (TokKind = TK_STAR) Do Begin
  NextToken;
  R := EvalFactor(TblIdx, RecIdx);
  If SqlIsNumeric(L) And SqlIsNumeric(R) Then
   L := IntToStr(Trunc(SqlNum(L) * SqlNum(R)))
  Else L := '';
 End;
 EvalMul := L;
End;

Function EvalAdd(TblIdx, RecIdx: Integer): String;
Var L, R: String; Op: Integer;
Begin
 L := EvalMul(TblIdx, RecIdx);
 While (Not SqlErr) And (TokKind = TK_OP) And ((TokOp = OP_ADD) Or (TokOp = OP_SUB)) Do Begin
  Op := TokOp; NextToken;
  R := EvalMul(TblIdx, RecIdx);
  If SqlIsNumeric(L) And SqlIsNumeric(R) Then Begin
   If Op = OP_ADD Then L := IntToStr(Trunc(SqlNum(L) + SqlNum(R)))
   Else                L := IntToStr(Trunc(SqlNum(L) - SqlNum(R)));
  End
  Else If Op = OP_ADD Then L := L + R
  Else L := '';
 End;
 EvalAdd := L;
End;

Function EvalCmp(TblIdx, RecIdx: Integer): String;
Var L, R: String; Op, Cmp: Integer;
Begin
 L := EvalAdd(TblIdx, RecIdx);
 If (Not SqlErr) And (TokKind = TK_OP) And (TokOp >= OP_EQ) And (TokOp <= OP_GE) Then Begin
  Op := TokOp; NextToken;
  R := EvalAdd(TblIdx, RecIdx);
  Cmp := SqlCompare(L, R);
  Case Op Of
   OP_EQ: If Cmp = 0  Then L := 'T' Else L := 'F';
   OP_NE: If Cmp <> 0 Then L := 'T' Else L := 'F';
   OP_LT: If Cmp < 0  Then L := 'T' Else L := 'F';
   OP_LE: If Cmp <= 0 Then L := 'T' Else L := 'F';
   OP_GT: If Cmp > 0  Then L := 'T' Else L := 'F';
   OP_GE: If Cmp >= 0 Then L := 'T' Else L := 'F';
  End;
 End
 Else If (Not SqlErr) And (TokKind = TK_OP) And (TokOp = OP_LIKE) Then Begin
  NextToken;
  R := EvalAdd(TblIdx, RecIdx);
  If SqlLikeMatch(L, R) Then L := 'T' Else L := 'F';
 End;
 EvalCmp := L;
End;

Function EvalNot(TblIdx, RecIdx: Integer): String;
Var V: String;
Begin
 If (TokKind = TK_KW) And (TokKw = KW_NOT) Then Begin
  NextToken;
  V := EvalNot(TblIdx, RecIdx);
  If V = 'T' Then EvalNot := 'F' Else EvalNot := 'T';
 End
 Else EvalNot := EvalCmp(TblIdx, RecIdx);
End;

Function EvalAndE(TblIdx, RecIdx: Integer): String;
Var L, R: String;
Begin
 L := EvalNot(TblIdx, RecIdx);
 While (Not SqlErr) And (TokKind = TK_KW) And (TokKw = KW_AND) Do Begin
  NextToken;
  R := EvalNot(TblIdx, RecIdx);
  If (L = 'T') And (R = 'T') Then L := 'T' Else L := 'F';
 End;
 EvalAndE := L;
End;

Function EvalOrE(TblIdx, RecIdx: Integer): String;
Var L, R: String;
Begin
 L := EvalAndE(TblIdx, RecIdx);
 While (Not SqlErr) And (TokKind = TK_KW) And (TokKw = KW_OR) Do Begin
  NextToken;
  R := EvalAndE(TblIdx, RecIdx);
  If (L = 'T') Or (R = 'T') Then L := 'T' Else L := 'F';
 End;
 EvalOrE := L;
End;

Function EvalExpr(TblIdx, RecIdx: Integer): String;
Begin
 EvalExpr := EvalOrE(TblIdx, RecIdx);
End;

Function EvalBoolExpr(TblIdx, RecIdx: Integer): Boolean;
Var V: String;
Begin
 V := EvalExpr(TblIdx, RecIdx);
 EvalBoolExpr := (V = 'T') Or ((V <> '') And (V <> 'F') And (V <> '0'));
End;

Procedure SqlSkipExpr;
Var Depth: Integer;
Begin
 Depth := 0;
 While Not SqlErr Do Begin
  If TokKind = TK_EOF Then Exit;
  If TokKind = TK_SEMI Then Exit;
  If TokKind = TK_LPAREN Then Inc(Depth)
  Else If TokKind = TK_RPAREN Then Begin
   If Depth = 0 Then Exit;
   Dec(Depth);
  End
  Else If Depth = 0 Then Begin
   If TokKind = TK_COMMA Then Exit;
   If (TokKind = TK_KW) And ((TokKw = KW_ORDER) Or (TokKw = KW_FROM)) Then Exit;
  End;
  NextToken;
 End;
End;

{ ----- Type SQL pour CREATE TABLE ----- }
Function SqlMapType(Const N: String): Byte;
Var U: String;
Begin
 U := UpperStr(N);
 SqlMapType := FT_TEXT;
 If (U = 'TEXT') Or (U = 'VARCHAR') Or (U = 'CHAR') Or (U = 'STRING') Then SqlMapType := FT_TEXT
 Else If U = 'MEMO' Then SqlMapType := FT_MEMO
 Else If (U = 'INT') Or (U = 'INTEGER') Or (U = 'SMALLINT') Then SqlMapType := FT_INTEGER
 Else If (U = 'LONG') Or (U = 'BIGINT') Then SqlMapType := FT_LONG
 Else If (U = 'SINGLE') Or (U = 'REAL') Or (U = 'FLOAT') Then SqlMapType := FT_SINGLE
 Else If (U = 'DOUBLE') Or (U = 'NUMERIC') Or (U = 'DECIMAL') Then SqlMapType := FT_DOUBLE
 Else If (U = 'MONEY') Or (U = 'CURRENCY') Then SqlMapType := FT_CURRENCY
 Else If U = 'DATE' Then SqlMapType := FT_DATE
 Else If U = 'TIME' Then SqlMapType := FT_TIME
 Else If (U = 'DATETIME') Or (U = 'TIMESTAMP') Then SqlMapType := FT_DATETIME
 Else If (U = 'BOOL') Or (U = 'BOOLEAN') Or (U = 'YESNO') Or (U = 'BIT') Then SqlMapType := FT_BOOL
 Else If (U = 'AUTONUM') Or (U = 'AUTONUMBER') Or (U = 'COUNTER') Or (U = 'IDENTITY') Or (U = 'SERIAL') Then SqlMapType := FT_AUTONUM
 Else If U = 'OLE' Then SqlMapType := FT_OLE
 Else If U = 'HYPERLINK' Then SqlMapType := FT_HYPERLINK
 Else If (U = 'BINARY') Or (U = 'BLOB') Then SqlMapType := FT_BINARY;
End;

{ ----- Executeurs ----- }
Procedure ExecSelect(Var RowsAffected: Integer); Forward;
Procedure ExecInsert(Var RowsAffected: Integer); Forward;
Procedure ExecUpdate(Var RowsAffected: Integer); Forward;
Procedure ExecDelete(Var RowsAffected: Integer); Forward;
Procedure ExecCreate(Var RowsAffected: Integer); Forward;
Procedure ExecDrop(Var RowsAffected: Integer); Forward;

Procedure ExecSelect(Var RowsAffected: Integer);
Var
 ColCount, I, K, TblIdx, FIdx: Integer;
 ColField: Array[1..MAX_QRES_COLS] Of Integer; { 0=*, sinon field idx }
 ColName : Array[1..MAX_QRES_COLS] Of String;
 StarMode: Boolean;
 WherePos: Integer;
 OrderField: Integer;
 OrderDesc: Boolean;
 T: PTable;
 Rec: PRecord;
 Keep: Boolean;
 OutCount: Integer;
 SwapTmp: Array[1..MAX_QRES_COLS] Of String;
 A, B: Integer; Better: Boolean; Cmp: Integer;
Begin
 NextToken;
 If (TokKind = TK_KW) And (TokKw = KW_DISTINCT) Then NextToken;
 ColCount := 0;
 StarMode := False;
 If TokKind = TK_STAR Then Begin
  StarMode := True;
  NextToken;
 End
 Else Begin
  Repeat
   If ColCount >= MAX_QRES_COLS Then Begin SqlSetError('Trop de colonnes'); Exit; End;
   Inc(ColCount);
   If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de colonne attendu'); Exit; End;
   ColName[ColCount] := TokStr;
   ColField[ColCount] := -1; { sera resolu apres FROM }
   NextToken;
   { Optionnel tbl.col }
   If TokKind = TK_DOT Then Begin
    NextToken;
    If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de colonne attendu apres .'); Exit; End;
    ColName[ColCount] := TokStr;
    NextToken;
   End;
   If (TokKind = TK_KW) And (TokKw = KW_AS) Then Begin
    NextToken;
    If TokKind <> TK_IDENT Then Begin SqlSetError('Alias attendu apres AS'); Exit; End;
    NextToken;
   End;
   If TokKind = TK_COMMA Then NextToken Else Break;
  Until False;
 End;
 If (TokKind <> TK_KW) Or (TokKw <> KW_FROM) Then Begin SqlSetError('FROM attendu'); Exit; End;
 NextToken;
 If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de table attendu'); Exit; End;
 TblIdx := FindTableByName(TokStr);
 If TblIdx = 0 Then Begin SqlSetError('Table inconnue : ' + TokStr); Exit; End;
 NextToken;
 T := DB.Tables[TblIdx];
 { Resolution des colonnes }
 If StarMode Then Begin
  ColCount := T^.FldCount;
  If ColCount > MAX_QRES_COLS Then ColCount := MAX_QRES_COLS;
  For I := 1 To ColCount Do Begin
   ColField[I] := I;
   ColName[I]  := T^.Fields[I].Name;
  End;
 End
 Else
  For I := 1 To ColCount Do Begin
   FIdx := FindField(TblIdx, ColName[I]);
   If FIdx = 0 Then Begin SqlSetError('Colonne inconnue : ' + ColName[I]); Exit; End;
   ColField[I] := FIdx;
  End;
 { WHERE }
 WherePos := 0;
 If (TokKind = TK_KW) And (TokKw = KW_WHERE) Then Begin
  NextToken;
  WherePos := SqlPos;
  { On va re-tokeniser per ligne ; il faut un point de reprise = position
    SqlPos est positionnee APRES le token courant. On veut une position
    qui, quand on Set + NextToken, donne le premier token de WHERE. }
  { Astuce : on sauve TokStr et SqlPos courants. Pour reprendre on memorise
    egalement le debut du token. Simplification : on retokenise en
    reinitialisant SqlPos juste avant l'expression. On retro-cherche en
    soustrayant Length(TokStr) du SqlPos courant si IDENT/NUMBER. Plus
    simple : memoriser SqlPos AVANT NextToken au moment ou on entre dans
    WHERE. Faisons-le via WherePos memorise AVANT le NextToken sortant
    de l'evaluation : on remplace donc par un saut au caractere du token
    courant. }
  WherePos := SqlPos - Length(TokStr);
  If (TokKind = TK_STRING) Then WherePos := WherePos - 2; { quotes }
  If WherePos < 1 Then WherePos := 1;
  SqlSkipExpr;
 End;
 { ORDER BY }
 OrderField := 0; OrderDesc := False;
 If (TokKind = TK_KW) And (TokKw = KW_ORDER) Then Begin
  NextToken;
  If (TokKind <> TK_KW) Or (TokKw <> KW_BY) Then Begin SqlSetError('BY attendu'); Exit; End;
  NextToken;
  If TokKind <> TK_IDENT Then Begin SqlSetError('Colonne ORDER BY attendue'); Exit; End;
  OrderField := FindField(TblIdx, TokStr);
  If OrderField = 0 Then Begin SqlSetError('Colonne ORDER BY inconnue'); Exit; End;
  NextToken;
  If TokKind = TK_KW Then Begin
   If TokKw = KW_DESC Then Begin OrderDesc := True; NextToken; End
   Else If TokKw = KW_ASC Then NextToken;
  End;
 End;
 { Setup result }
 QResColCount := ColCount;
 For I := 1 To ColCount Do QResColName[I] := ColName[I];
 OutCount := 0;
 { Iteration }
 For I := 1 To T^.RecCount Do Begin
  Rec := T^.Records[I];
  If (Rec = Nil) Or Rec^.Deleted Then Continue;
  Keep := True;
  If WherePos > 0 Then Begin
   SqlPos := WherePos;
   NextToken;
   Keep := EvalBoolExpr(TblIdx, I);
   If SqlErr Then Exit;
  End;
  If Keep Then Begin
   If OutCount >= MAX_QRES_ROWS Then Continue;
   Inc(OutCount);
   For K := 1 To ColCount Do Begin
    If ColField[K] > 0 Then QResRows[OutCount, K] := Rec^.Values[ColField[K]]
    Else QResRows[OutCount, K] := '';
   End;
  End;
 End;
 QResRowCount := OutCount;
 { Tri }
 If (OrderField > 0) And (OutCount > 1) Then Begin
  FIdx := 0;
  For K := 1 To ColCount Do If ColField[K] = OrderField Then FIdx := K;
  If FIdx > 0 Then
   For A := 2 To OutCount Do
    For B := OutCount DownTo A Do Begin
     Cmp := SqlCompare(QResRows[B-1, FIdx], QResRows[B, FIdx]);
     If OrderDesc Then Better := Cmp < 0 Else Better := Cmp > 0;
     If Better Then Begin
      For K := 1 To ColCount Do SwapTmp[K] := QResRows[B-1, K];
      For K := 1 To ColCount Do QResRows[B-1, K] := QResRows[B, K];
      For K := 1 To ColCount Do QResRows[B, K] := SwapTmp[K];
     End;
    End;
 End;
 RowsAffected := OutCount;
End;

Procedure ExecInsert(Var RowsAffected: Integer);
Var
 TblIdx, I, FIdx: Integer;
 ColList: Array[1..MAX_FIELDS] Of Integer;
 ColCount: Integer;
 HasCols: Boolean;
 T: PTable;
 Rec: PRecord;
 RIdx: Integer;
 V: String;
Begin
 NextToken;
 If (TokKind <> TK_KW) Or (TokKw <> KW_INTO) Then Begin SqlSetError('INTO attendu'); Exit; End;
 NextToken;
 If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de table attendu'); Exit; End;
 TblIdx := FindTableByName(TokStr);
 If TblIdx = 0 Then Begin SqlSetError('Table inconnue'); Exit; End;
 T := DB.Tables[TblIdx];
 NextToken;
 HasCols := False; ColCount := 0;
 If TokKind = TK_LPAREN Then Begin
  HasCols := True;
  NextToken;
  Repeat
   If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de colonne attendu'); Exit; End;
   FIdx := FindField(TblIdx, TokStr);
   If FIdx = 0 Then Begin SqlSetError('Colonne inconnue : ' + TokStr); Exit; End;
   Inc(ColCount); ColList[ColCount] := FIdx;
   NextToken;
   If TokKind = TK_COMMA Then NextToken Else Break;
  Until False;
  If TokKind <> TK_RPAREN Then Begin SqlSetError(') attendue'); Exit; End;
  NextToken;
 End;
 If (TokKind <> TK_KW) Or (TokKw <> KW_VALUES) Then Begin SqlSetError('VALUES attendu'); Exit; End;
 NextToken;
 If TokKind <> TK_LPAREN Then Begin SqlSetError('( attendue'); Exit; End;
 NextToken;
 RIdx := NewRecord(TblIdx);
 If RIdx = 0 Then Begin SqlSetError('Capacite max atteinte'); Exit; End;
 Rec := T^.Records[RIdx];
 I := 0;
 Repeat
  Inc(I);
  V := EvalExpr(TblIdx, 0);
  If SqlErr Then Exit;
  If HasCols Then Begin
   If I > ColCount Then Begin SqlSetError('Trop de valeurs'); Exit; End;
   Rec^.Values[ColList[I]] := V;
  End
  Else Begin
   If I <= T^.FldCount Then Rec^.Values[I] := V;
  End;
  If TokKind = TK_COMMA Then NextToken Else Break;
 Until False;
 If TokKind <> TK_RPAREN Then Begin SqlSetError(') attendue'); Exit; End;
 NextToken;
 { Auto-incremente NumeroAuto si non specifie }
 For I := 1 To T^.FldCount Do
  If (T^.Fields[I].FType = FT_AUTONUM) And (Rec^.Values[I] = '') Then Begin
   Rec^.Values[I] := IntToStr(T^.NextAutoNum);
   Inc(T^.NextAutoNum);
  End;
 T^.Dirty := True; DB.Dirty := True;
 RowsAffected := 1;
End;

Procedure ExecUpdate(Var RowsAffected: Integer);
Var
 TblIdx, FIdx, I, NSet: Integer;
 SetField: Array[1..MAX_FIELDS] Of Integer;
 SetExprPos: Array[1..MAX_FIELDS] Of Integer;
 T: PTable;
 WherePos: Integer;
 Rec: PRecord;
 V: String;
Begin
 NextToken;
 If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de table attendu'); Exit; End;
 TblIdx := FindTableByName(TokStr);
 If TblIdx = 0 Then Begin SqlSetError('Table inconnue'); Exit; End;
 T := DB.Tables[TblIdx];
 NextToken;
 If (TokKind <> TK_KW) Or (TokKw <> KW_SET) Then Begin SqlSetError('SET attendu'); Exit; End;
 NextToken;
 NSet := 0;
 Repeat
  If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de colonne attendu'); Exit; End;
  FIdx := FindField(TblIdx, TokStr);
  If FIdx = 0 Then Begin SqlSetError('Colonne inconnue : ' + TokStr); Exit; End;
  Inc(NSet); SetField[NSet] := FIdx;
  NextToken;
  If (TokKind <> TK_OP) Or (TokOp <> OP_EQ) Then Begin SqlSetError('= attendu'); Exit; End;
  NextToken;
  SetExprPos[NSet] := SqlPos - Length(TokStr);
  If TokKind = TK_STRING Then SetExprPos[NSet] := SetExprPos[NSet] - 2;
  If SetExprPos[NSet] < 1 Then SetExprPos[NSet] := 1;
  SqlSkipExpr;
  If TokKind = TK_COMMA Then NextToken Else Break;
 Until False;
 WherePos := 0;
 If (TokKind = TK_KW) And (TokKw = KW_WHERE) Then Begin
  NextToken;
  WherePos := SqlPos - Length(TokStr);
  If TokKind = TK_STRING Then WherePos := WherePos - 2;
  If WherePos < 1 Then WherePos := 1;
  SqlSkipExpr;
 End;
 RowsAffected := 0;
 For I := 1 To T^.RecCount Do Begin
  Rec := T^.Records[I];
  If (Rec = Nil) Or Rec^.Deleted Then Continue;
  If WherePos > 0 Then Begin
   SqlPos := WherePos; NextToken;
   If Not EvalBoolExpr(TblIdx, I) Then Continue;
   If SqlErr Then Exit;
  End;
  For FIdx := 1 To NSet Do Begin
   SqlPos := SetExprPos[FIdx]; NextToken;
   V := EvalExpr(TblIdx, I);
   If SqlErr Then Exit;
   Rec^.Values[SetField[FIdx]] := V;
  End;
  Inc(RowsAffected);
 End;
 T^.Dirty := True; DB.Dirty := True;
End;

Procedure ExecDelete(Var RowsAffected: Integer);
Var TblIdx, I: Integer; T: PTable; Rec: PRecord; WherePos: Integer;
Begin
 NextToken;
 If (TokKind <> TK_KW) Or (TokKw <> KW_FROM) Then Begin SqlSetError('FROM attendu'); Exit; End;
 NextToken;
 If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de table attendu'); Exit; End;
 TblIdx := FindTableByName(TokStr);
 If TblIdx = 0 Then Begin SqlSetError('Table inconnue'); Exit; End;
 T := DB.Tables[TblIdx];
 NextToken;
 WherePos := 0;
 If (TokKind = TK_KW) And (TokKw = KW_WHERE) Then Begin
  NextToken;
  WherePos := SqlPos - Length(TokStr);
  If TokKind = TK_STRING Then WherePos := WherePos - 2;
  If WherePos < 1 Then WherePos := 1;
  SqlSkipExpr;
 End;
 RowsAffected := 0;
 For I := 1 To T^.RecCount Do Begin
  Rec := T^.Records[I];
  If (Rec = Nil) Or Rec^.Deleted Then Continue;
  If WherePos > 0 Then Begin
   SqlPos := WherePos; NextToken;
   If Not EvalBoolExpr(TblIdx, I) Then Continue;
   If SqlErr Then Exit;
  End;
  Rec^.Deleted := True;
  Inc(RowsAffected);
 End;
 T^.Dirty := True; DB.Dirty := True;
End;

Procedure ExecCreate(Var RowsAffected: Integer);
Var TName, FName, TType: String; T: PTable; F: PField;
 SzN: LongInt; SzCode: Integer; TIdx: Integer;
Begin
 NextToken;
 If (TokKind <> TK_KW) Or (TokKw <> KW_TABLE) Then Begin SqlSetError('TABLE attendu'); Exit; End;
 NextToken;
 If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de table attendu'); Exit; End;
 TName := TokStr;
 If FindTableByName(TName) <> 0 Then Begin SqlSetError('Table existe deja'); Exit; End;
 NextToken;
 If TokKind <> TK_LPAREN Then Begin SqlSetError('( attendue'); Exit; End;
 NextToken;
 TIdx := NewTable(TName);
 If TIdx = 0 Then Begin SqlSetError('Capacite max atteinte'); Exit; End;
 T := DB.Tables[TIdx];
 Repeat
  If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de colonne attendu'); Exit; End;
  FName := TokStr;
  NextToken;
  If TokKind <> TK_IDENT Then Begin SqlSetError('Type attendu pour ' + FName); Exit; End;
  TType := TokStr;
  NextToken;
  If TokKind = TK_LPAREN Then Begin
   NextToken;
   If TokKind <> TK_NUMBER Then Begin SqlSetError('Taille attendue'); Exit; End;
   Val(TokStr, SzN, SzCode);
   NextToken;
   If TokKind = TK_COMMA Then Begin NextToken;
    If TokKind = TK_NUMBER Then NextToken;
   End;
   If TokKind <> TK_RPAREN Then Begin SqlSetError(') attendue'); Exit; End;
   NextToken;
  End
  Else SzN := 0;
  If T^.FldCount < MAX_FIELDS Then Begin
   Inc(T^.FldCount);
   F := @T^.Fields[T^.FldCount];
   FillChar(F^, SizeOf(TField), 0);
   F^.Name  := FName;
   F^.FType := SqlMapType(TType);
   If SzN > 0 Then F^.Size := SzN Else F^.Size := TypeDefaultSize(F^.FType);
   F^.AllowNull := True;
  End;
  { Tolere les contraintes inline : NOT NULL, PRIMARY KEY, UNIQUE,
    DEFAULT <val>, etc. On lit jusqu'au prochain , ou ) }
  While (TokKind <> TK_COMMA) And (TokKind <> TK_RPAREN) And
        (TokKind <> TK_EOF) Do Begin
   If TokKind = TK_IDENT Then Begin
    If UpperStr(TokStr) = 'PRIMARY' Then Begin
     F^.PrimaryKey := True; F^.AllowNull := False;
    End;
   End;
   If TokKind = TK_KW Then Begin
    If TokKw = KW_NOT Then F^.AllowNull := False;
   End;
   NextToken;
  End;
  If TokKind = TK_COMMA Then NextToken Else Break;
 Until False;
 If TokKind <> TK_RPAREN Then Begin SqlSetError(') attendue'); Exit; End;
 NextToken;
 T^.Dirty := True; DB.Dirty := True;
 RowsAffected := 0;
 ComputeNavLayout;
End;

Procedure ExecDrop(Var RowsAffected: Integer);
Var TblIdx, J: Integer; T: PTable;
Begin
 NextToken;
 If (TokKind <> TK_KW) Or (TokKw <> KW_TABLE) Then Begin SqlSetError('TABLE attendu'); Exit; End;
 NextToken;
 If TokKind <> TK_IDENT Then Begin SqlSetError('Nom de table attendu'); Exit; End;
 TblIdx := FindTableByName(TokStr);
 If TblIdx = 0 Then Begin SqlSetError('Table inconnue'); Exit; End;
 T := DB.Tables[TblIdx];
 For J := 1 To T^.RecCount Do If T^.Records[J] <> Nil Then Dispose(T^.Records[J]);
 Dispose(T);
 For J := TblIdx To DB.TblCount - 1 Do DB.Tables[J] := DB.Tables[J + 1];
 DB.Tables[DB.TblCount] := Nil;
 Dec(DB.TblCount);
 If CurTblIdx > DB.TblCount Then CurTblIdx := DB.TblCount;
 DB.Dirty := True;
 RowsAffected := 0;
 NextToken;
 ComputeNavLayout;
End;

Procedure ExecSql(Const Src: String);
Var Affected: Integer;
Begin
 SqlSrc    := Src;
 SqlPos    := 1;
 SqlErr    := False;
 SqlErrMsg := '';
 QResColCount := 0;
 QResRowCount := 0;
 Affected := 0;
 NextToken;
 If TokKind <> TK_KW Then Begin
  If TokKind = TK_EOF Then Begin QStatusMsg := 'SQL vide'; QStatusErr := True; Exit; End;
  SqlSetError('Mot-cle SQL attendu');
 End
 Else
  Case TokKw Of
   KW_SELECT: ExecSelect(Affected);
   KW_INSERT: ExecInsert(Affected);
   KW_UPDATE: ExecUpdate(Affected);
   KW_DELETE: ExecDelete(Affected);
   KW_CREATE: ExecCreate(Affected);
   KW_DROP  : ExecDrop(Affected);
   Else SqlSetError('Instruction non supportee');
  End;
 If SqlErr Then Begin
  QStatusMsg := 'Erreur : ' + SqlErrMsg;
  QStatusErr := True;
 End
 Else Begin
  QStatusErr := False;
  If TokKw = KW_SELECT Then
   QStatusMsg := IntToStr(Affected) + ' ligne(s) retournee(s)'
  Else
   QStatusMsg := IntToStr(Affected) + ' ligne(s) traitee(s)';
 End;
End;

{ ====================================================================== }
{                       VUE REQUETE (Phase 4)                            }
{ ====================================================================== }

Procedure QueryComputeColW;
Var I, J, L, M: Integer;
Begin
 For I := 1 To QResColCount Do Begin
  M := Length(QResColName[I]) * 6 + 12;
  For J := 1 To QResRowCount Do Begin
   L := Length(QResRows[J, I]) * 6 + 12;
   If L > M Then M := L;
  End;
  If M < 50 Then M := 50;
  If M > 240 Then M := 240;
  QResColW[I] := M;
 End;
End;

Function CurQuery: PQuery;
Begin
 If (CurQryIdx >= 1) And (CurQryIdx <= DB.QryCount) Then CurQuery := DB.Queries[CurQryIdx]
 Else CurQuery := Nil;
End;

Procedure DrawQueryEditor(X1, Y1, X2, Y2: Integer);
Var
 PaneX1, PaneY1, PaneX2, PaneY2, CurX, CurY, I, LineH, MaxCharsPerLine, LineCount: Integer;
 Ch: Char; CaretPxX, CaretPxY: Integer;
Begin
 DrawSunken(X1, Y1, X2, Y2, CLR_GRID_BG, CLR_WIN_LO, CLR_WIN_HI);
 PaneX1 := X1 + 4; PaneY1 := Y1 + 4;
 PaneX2 := X2 - 4; PaneY2 := Y2 - 4;
 SetColor(CLR_BLACK);
 LineH := 12;
 MaxCharsPerLine := (PaneX2 - PaneX1) Div 6;
 If MaxCharsPerLine < 10 Then MaxCharsPerLine := 10;
 CurX := PaneX1; CurY := PaneY1; LineCount := 0;
 CaretPxX := CurX; CaretPxY := CurY;
 For I := 1 To Length(QSqlBuf) Do Begin
  If I = QCaret + 1 Then Begin CaretPxX := CurX; CaretPxY := CurY; End;
  Ch := QSqlBuf[I];
  If (Ch = #10) Or (Ch = #13) Then Begin
   CurX := PaneX1; CurY := CurY + LineH; Inc(LineCount);
   If CurY + LineH > PaneY2 Then Break;
   Continue;
  End;
  If (CurX - PaneX1) Div 6 >= MaxCharsPerLine Then Begin
   CurX := PaneX1; CurY := CurY + LineH;
   If CurY + LineH > PaneY2 Then Break;
  End;
  If Ch >= ' ' Then Begin
   OutTextXY(CurX, CurY, Ch);
   CurX := CurX + 6;
  End;
 End;
 If QCaret >= Length(QSqlBuf) Then Begin CaretPxX := CurX; CaretPxY := CurY; End;
 If (QFocus = 0) And BlinkState Then Begin
  SetColor(CLR_BLACK);
  Line(CaretPxX, CaretPxY, CaretPxX, CaretPxY + LineH - 2);
 End;
End;

Procedure DrawQueryResults(X1, Y1, X2, Y2: Integer);
Var
 I, J, Cx, RowH, HdrH, VisRows, VisCols, MaxRow, Y, ColX, ColW, TextLen: Integer;
 S: String;
 Sel: Boolean;
Begin
 DrawSunken(X1, Y1, X2, Y2, CLR_GRID_BG, CLR_WIN_LO, CLR_WIN_HI);
 If QResColCount = 0 Then Begin
  SetColor(CLR_DGRAY);
  OutTextXY(X1 + 8, Y1 + 8, 'Pas de resultats. Tapez SQL et F5 pour executer.');
  Exit;
 End;
 HdrH := GRID_HDR_H; RowH := ROW_H;
 { Entete }
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 2 + HdrH, CLR_GRID_HDR_BG);
 SetColor(CLR_GRID_HDR_FG);
 Cx := X1 + 4;
 For I := QResColScroll + 1 To QResColCount Do Begin
  If Cx >= X2 - 4 Then Break;
  ColW := QResColW[I];
  If Cx + ColW > X2 - 2 Then ColW := X2 - 2 - Cx;
  S := QResColName[I];
  TextLen := Length(S) * 6;
  If TextLen > ColW - 6 Then S := Copy(S, 1, (ColW - 6) Div 6);
  OutTextXY(Cx + 3, Y1 + 6, S);
  SetColor(CLR_WIN_LO);
  Line(Cx + ColW - 1, Y1 + 2, Cx + ColW - 1, Y1 + 2 + HdrH);
  SetColor(CLR_GRID_HDR_FG);
  Cx := Cx + ColW;
 End;
 SetColor(CLR_WIN_LO);
 Line(X1 + 2, Y1 + 2 + HdrH, X2 - 2, Y1 + 2 + HdrH);
 { Lignes }
 Y := Y1 + 3 + HdrH;
 VisRows := (Y2 - Y - 2) Div RowH;
 If VisRows < 1 Then VisRows := 1;
 MaxRow := QResScroll + VisRows;
 If MaxRow > QResRowCount Then MaxRow := QResRowCount;
 VisCols := QResColCount;
 For J := QResScroll + 1 To MaxRow Do Begin
  Sel := (QFocus = 1) And (J = QResSelRow);
  If Sel Then FillBox(X1 + 2, Y, X2 - 2, Y + RowH - 1, CLR_GRID_SEL_BG);
  Cx := X1 + 4;
  For I := QResColScroll + 1 To VisCols Do Begin
   If Cx >= X2 - 4 Then Break;
   ColW := QResColW[I];
   If Cx + ColW > X2 - 2 Then ColW := X2 - 2 - Cx;
   S := QResRows[J, I];
   If Length(S) > (ColW - 6) Div 6 Then S := Copy(S, 1, (ColW - 6) Div 6);
   If Sel Then SetColor(CLR_GRID_SEL_FG) Else SetColor(CLR_GRID_TEXT);
   OutTextXY(Cx + 3, Y + 2, S);
   SetColor(CLR_GRID_LINE);
   Line(Cx + ColW - 1, Y, Cx + ColW - 1, Y + RowH);
   Cx := Cx + ColW;
  End;
  SetColor(CLR_GRID_LINE);
  Line(X1 + 2, Y + RowH - 1, X2 - 2, Y + RowH - 1);
  Y := Y + RowH;
 End;
End;

Procedure DrawQueryView;
Var
 Y0, X1, X2, EditY1, EditY2, ResY1, ResY2: Integer;
 Q: PQuery; Title: String;
Begin
 HideMouse;
 Y0 := ToolY2 + 1;
 FillBox(0, Y0, SCREEN_W - 1, SCREEN_H - STAT_H - 1, CLR_WIN_BG);
 { Titre }
 X1 := 4; X2 := SCREEN_W - 4;
 FillBox(X1, Y0 + 2, X2, Y0 + 16, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 Q := CurQuery;
 If Q <> Nil Then Title := 'Requete : ' + Q^.Name
 Else Title := 'Requete : (nouvelle)';
 OutTextXY(X1 + 6, Y0 + 5, Title);
 SetColor(CLR_WIN_TEXT);
 OutTextXY(X2 - 200, Y0 + 5, 'F5=Executer F6=Focus Esc=Retour');
 { Editeur SQL (haut) }
 EditY1 := Y0 + 22;
 QSplitY := Y0 + 22 + 130;
 EditY2 := QSplitY - 2;
 OutTextXY(X1 + 4, EditY1 - 12, 'SQL :');
 DrawQueryEditor(X1, EditY1, X2, EditY2);
 { Splitter }
 DrawRaised(X1, QSplitY, X2, QSplitY + 3, CLR_WIN_BG, CLR_WIN_HI, CLR_WIN_LO);
 { Resultats (bas) }
 ResY1 := QSplitY + 5;
 ResY2 := SCREEN_H - STAT_H - 18;
 OutTextXY(X1 + 4, ResY1 - 12, 'Resultats :');
 QueryComputeColW;
 DrawQueryResults(X1, ResY1, X2, ResY2);
 { Status }
 SetColor(CLR_WIN_TEXT);
 If QStatusErr Then SetColor(CLR_RED);
 If QStatusMsg <> '' Then OutTextXY(X1 + 4, ResY2 + 4, QStatusMsg);
 ShowMouse;
End;

{ ====================================================================== }
{                       VUE GENERIQUE (placeholders)                     }
{ ====================================================================== }

Function CurForm: PForm;
Begin
 If (CurFrmIdx >= 1) And (CurFrmIdx <= DB.FrmCount) Then
  CurForm := DB.Forms[CurFrmIdx]
 Else
  CurForm := Nil;
End;

Procedure FormBindTable;
Var Frm: PForm;
Begin
 Frm := CurForm;
 If Frm = Nil Then Exit;
 If (Frm^.SrcTable >= 1) And (Frm^.SrcTable <= DB.TblCount) Then Begin
  CurTblIdx := Frm^.SrcTable;
  If CurFldIdx < 1 Then CurFldIdx := 1;
  If CurFldIdx > DB.Tables[CurTblIdx]^.FldCount Then CurFldIdx := DB.Tables[CurTblIdx]^.FldCount;
  If CurRecIdx < 1 Then CurRecIdx := 1;
  If CurRecIdx > DB.Tables[CurTblIdx]^.RecCount Then
   CurRecIdx := DB.Tables[CurTblIdx]^.RecCount;
  If CurRecIdx < 1 Then CurRecIdx := 1;
 End;
End;

Procedure FormComputeLayout(T: PTable);
Var Avail: Integer;
Begin
 FormLabelX := 20;
 FormEditX  := 180;
 FormEditX2 := SCREEN_W - 24;
 FormFldY0  := ToolY2 + 26;
 FormFldH   := 22;
 FormBtnH   := 24;
 FormBtnY   := SCREEN_H - STAT_H - 6 - FormBtnH;
 Avail := FormBtnY - 8 - FormFldY0;
 If Avail < FormFldH Then FormVisFlds := 1
 Else FormVisFlds := Avail Div FormFldH;
 If T <> Nil Then
  If FormVisFlds > T^.FldCount Then FormVisFlds := T^.FldCount;
 If FormVisFlds < 1 Then FormVisFlds := 1;
End;

Function FormFieldRowY(Idx: Integer): Integer;
Begin
 FormFieldRowY := FormFldY0 + (Idx - FormScroll) * FormFldH;
End;

Procedure DrawFormNavBtn(X1, Y1, X2, Y2: Integer; Const Cap: String);
Begin
 DrawRaised(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + ((X2 - X1) - TextWidth(Cap)) Div 2,
           Y1 + ((Y2 - Y1) - 8) Div 2, Cap);
End;

Procedure FormGetNavBtnRect(Idx: Integer; Var X1, Y1, X2, Y2: Integer);
Var W, Gap, X0: Integer;
Begin
 W := 56; Gap := 4;
 X0 := 12 + (Idx - 1) * (W + Gap);
 X1 := X0; Y1 := FormBtnY;
 X2 := X0 + W - 1; Y2 := FormBtnY + FormBtnH - 1;
End;

Procedure DrawFormFieldRow(T: PTable; FldIdx, Y: Integer);
Var F: PField; V, S: String;
    EX1, EY1, EX2, EY2, Cx: Integer;
    IsBool, Checked, Sel: Boolean;
Begin
 F := @T^.Fields[FldIdx];
 IsBool := F^.FType = FT_BOOL;
 Sel := FldIdx = CurFldIdx;
 SetColor(CLR_BLACK);
 OutTextXY(FormLabelX, Y + (FormFldH - 8) Div 2, F^.Name + ' :');
 EX1 := FormEditX;
 EY1 := Y + 2;
 EX2 := FormEditX2;
 EY2 := Y + FormFldH - 4;
 If (CurRecIdx < 1) Or (CurRecIdx > T^.RecCount) Then V := ''
 Else V := T^.Records[CurRecIdx]^.Values[FldIdx];
 If IsBool Then Begin
  Checked := (V = 'T') Or (V = '1') Or (V = 'Oui') Or (V = 'Yes') Or (V = 'True');
  DrawCheckBox(EX1, Y + (FormFldH - 12) Div 2, Checked);
  If Sel Then Begin
   SetColor(CLR_BLACK);
   Rectangle(EX1 - 2, Y + (FormFldH - 12) Div 2 - 2,
             EX1 + 13, Y + (FormFldH - 12) Div 2 + 13);
  End;
  Exit;
 End;
 DrawSunken(EX1, EY1, EX2, EY2, CLR_WHITE, CLR_WIN_HI, CLR_WIN_LO);
 If Sel And EditMode Then Begin
  S := EditBuf;
  While (Length(S) > 0) And (TextWidth(S) > EX2 - EX1 - 6) Do
   S := Copy(S, 2, Length(S) - 1);
  SetColor(CLR_BLACK);
  OutTextXY(EX1 + 4, EY1 + ((EY2 - EY1) - 8) Div 2, S);
  If BlinkState Then Begin
   Cx := EditCaret; If Cx > Length(S) Then Cx := Length(S);
   Cx := EX1 + 4 + TextWidth(Copy(S, 1, Cx));
   SetColor(CLR_BLACK);
   Line(Cx, EY1 + 3, Cx, EY2 - 3);
  End;
 End
 Else Begin
  If F^.FType = FT_AUTONUM Then SetColor(CLR_DGRAY) Else SetColor(CLR_BLACK);
  S := V;
  While (Length(S) > 0) And (TextWidth(S) > EX2 - EX1 - 6) Do
   S := Copy(S, 1, Length(S) - 1);
  OutTextXY(EX1 + 4, EY1 + ((EY2 - EY1) - 8) Div 2, S);
  If Sel Then Begin
   SetColor(CLR_BLUE);
   Rectangle(EX1 - 1, EY1 - 1, EX2 + 1, EY2 + 1);
  End;
 End;
End;

Procedure DrawFormView;
Var Frm: PForm; T: PTable;
    I, Y, X1, Y1, X2, Y2: Integer;
    Title, Pos: String;
Begin
 HideMouse;
 FillBox(0, ToolY2 + 1, SCREEN_W - 1, SCREEN_H - STAT_H - 1, CLR_WIN_BG);
 Frm := CurForm;
 If Frm = Nil Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(20, ToolY2 + 20, 'Aucun formulaire ouvert.');
  ShowMouse; Exit;
 End;
 FormBindTable;
 If (Frm^.SrcTable < 1) Or (Frm^.SrcTable > DB.TblCount) Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(20, ToolY2 + 20, 'Formulaire ' + Frm^.Name + ' : table source absente.');
  ShowMouse; Exit;
 End;
 T := DB.Tables[Frm^.SrcTable];
 FormComputeLayout(T);
 FillBox(0, ToolY2 + 1, SCREEN_W - 1, ToolY2 + 22, CLR_DLG_TITLE_BG);
 SetColor(CLR_WHITE);
 Title := 'Formulaire : ' + Frm^.Name + '  -  Table : ' + T^.Name;
 OutTextXY(8, ToolY2 + 7, Title);
 SetColor(CLR_LGRAY);
 OutTextXY(SCREEN_W - 240, ToolY2 + 7,
           'Tab=Suiv Shift+Tab=Prec Esc=Retour');
 If FormScroll < 1 Then FormScroll := 1;
 If FormScroll > CurFldIdx Then FormScroll := CurFldIdx;
 If CurFldIdx >= FormScroll + FormVisFlds Then
  FormScroll := CurFldIdx - FormVisFlds + 1;
 If FormScroll < 1 Then FormScroll := 1;
 If (T^.FldCount > 0) And (FormScroll + FormVisFlds - 1 > T^.FldCount) Then
  FormScroll := T^.FldCount - FormVisFlds + 1;
 If FormScroll < 1 Then FormScroll := 1;
 If T^.FldCount = 0 Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(FormLabelX, FormFldY0 + 4, '(Aucun champ dans la table)');
 End
 Else For I := FormScroll To FormScroll + FormVisFlds - 1 Do Begin
  If I > T^.FldCount Then Break;
  Y := FormFieldRowY(I);
  DrawFormFieldRow(T, I, Y);
 End;
 If T^.FldCount > FormVisFlds Then Begin
  SetColor(CLR_DGRAY);
  OutTextXY(SCREEN_W - 70, FormFldY0,
            IntToStr(FormScroll) + '-' +
            IntToStr(FormScroll + FormVisFlds - 1) + '/' +
            IntToStr(T^.FldCount));
 End;
 FormGetNavBtnRect(1, X1, Y1, X2, Y2); DrawFormNavBtn(X1, Y1, X2, Y2, '|<');
 FormGetNavBtnRect(2, X1, Y1, X2, Y2); DrawFormNavBtn(X1, Y1, X2, Y2, '<');
 FormGetNavBtnRect(3, X1, Y1, X2, Y2); DrawFormNavBtn(X1, Y1, X2, Y2, '>');
 FormGetNavBtnRect(4, X1, Y1, X2, Y2); DrawFormNavBtn(X1, Y1, X2, Y2, '>|');
 FormGetNavBtnRect(5, X1, Y1, X2, Y2); DrawFormNavBtn(X1, Y1, X2, Y2, 'Nouv.');
 FormGetNavBtnRect(6, X1, Y1, X2, Y2); DrawFormNavBtn(X1, Y1, X2, Y2, 'Suppr.');
 If T^.RecCount = 0 Then Pos := 'Aucun enregistrement'
 Else Pos := 'Enr. ' + IntToStr(CurRecIdx) + ' / ' + IntToStr(T^.RecCount);
 SetColor(CLR_BLACK);
 OutTextXY(SCREEN_W - 8 - TextWidth(Pos),
           FormBtnY + (FormBtnH - 8) Div 2, Pos);
 ShowMouse;
End;

Function CurReport: PReport;
Begin
 If (CurRptIdx >= 1) And (CurRptIdx <= DB.RptCount) Then
  CurReport := DB.Reports[CurRptIdx]
 Else
  CurReport := Nil;
End;

Procedure RptComputeLayout(T: PTable);
Var I, X, FldW, Avail: Integer;
    F: PField;
Begin
 RptBodyY1 := ToolY2 + 60;
 RptBtnH   := 22;
 RptBtnY   := SCREEN_H - STAT_H - 6 - RptBtnH;
 RptBodyY2 := RptBtnY - 8;
 If RptBodyY2 < RptBodyY1 + ROW_H Then RptBodyY2 := RptBodyY1 + ROW_H;
 RptRowsPerPage := (RptBodyY2 - RptBodyY1 - GRID_HDR_H) Div ROW_H;
 If RptRowsPerPage < 1 Then RptRowsPerPage := 1;
 If T = Nil Then Exit;
 X := 12;
 Avail := SCREEN_W - 24;
 For I := 1 To T^.FldCount Do Begin
  F := @T^.Fields[I];
  Case F^.FType Of
   FT_INTEGER, FT_LONG, FT_AUTONUM         : FldW := 60;
   FT_SINGLE, FT_DOUBLE, FT_CURRENCY       : FldW := 80;
   FT_DATE, FT_TIME                        : FldW := 70;
   FT_DATETIME                             : FldW := 110;
   FT_BOOL                                 : FldW := 36;
   FT_MEMO                                 : FldW := 120;
  Else
   If F^.Size > 0 Then FldW := F^.Size * 7 + 12 Else FldW := 80;
  End;
  If FldW < TextWidth(F^.Name) + 12 Then FldW := TextWidth(F^.Name) + 12;
  If FldW > 200 Then FldW := 200;
  If FldW < 36  Then FldW := 36;
  RptColX[I] := X;
  RptColW[I] := FldW;
  X := X + FldW;
  If X > Avail Then RptColW[I] := Avail - RptColX[I];
  If X > Avail Then Break;
 End;
End;

Procedure RptDrawBtn(X1, Y1, X2, Y2: Integer; Const Cap: String);
Begin
 DrawRaised(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + ((X2 - X1) - TextWidth(Cap)) Div 2,
           Y1 + ((Y2 - Y1) - 8) Div 2, Cap);
End;

Procedure RptGetBtnRect(Idx: Integer; Var X1, Y1, X2, Y2: Integer);
Var W, Gap, X0: Integer;
Begin
 W := 56; Gap := 4;
 X0 := 12 + (Idx - 1) * (W + Gap);
 X1 := X0; Y1 := RptBtnY;
 X2 := X0 + W - 1; Y2 := RptBtnY + RptBtnH - 1;
End;

Procedure DrawReportView;
Var Rpt: PReport; T: PTable;
    I, J, RowIdx, BaseY, ClipX2: Integer;
    X1, Y1, X2, Y2, RecsTotal, FirstRec, LastRec: Integer;
    Title, Pos, S: String;
    R: PRecord;
Begin
 HideMouse;
 FillBox(0, ToolY2 + 1, SCREEN_W - 1, SCREEN_H - STAT_H - 1, CLR_WHITE);
 Rpt := CurReport;
 If Rpt = Nil Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(20, ToolY2 + 20, 'Aucun etat ouvert.');
  ShowMouse; Exit;
 End;
 If (Rpt^.SrcTable < 1) Or (Rpt^.SrcTable > DB.TblCount) Then Begin
  SetColor(CLR_BLACK);
  OutTextXY(20, ToolY2 + 20, 'Etat ' + Rpt^.Name + ' : table source absente.');
  ShowMouse; Exit;
 End;
 T := DB.Tables[Rpt^.SrcTable];
 RptComputeLayout(T);
 { Compte les enregistrements non supprimes }
 RecsTotal := 0;
 For I := 1 To T^.RecCount Do
  If (T^.Records[I] <> Nil) And (Not T^.Records[I]^.Deleted) Then Inc(RecsTotal);
 If RecsTotal = 0 Then RptPageCount := 1
 Else RptPageCount := (RecsTotal + RptRowsPerPage - 1) Div RptRowsPerPage;
 If RptPage < 1 Then RptPage := 1;
 If RptPage > RptPageCount Then RptPage := RptPageCount;
 { Page simulee : bordure et titre }
 FillBox(8, ToolY2 + 6, SCREEN_W - 9, SCREEN_H - STAT_H - 4, CLR_WHITE);
 SetColor(CLR_WIN_LO);
 Rectangle(8, ToolY2 + 6, SCREEN_W - 9, SCREEN_H - STAT_H - 4);
 SetColor(CLR_BLACK);
 SetTextStyle(0, 0, 2);
 Title := Rpt^.Name;
 OutTextXY((SCREEN_W - TextWidth(Title)) Div 2, ToolY2 + 16, Title);
 SetTextStyle(0, 0, 1);
 OutTextXY(16, ToolY2 + 42, 'Table source : ' + T^.Name);
 OutTextXY(SCREEN_W - 200, ToolY2 + 42,
           'Page ' + IntToStr(RptPage) + ' / ' + IntToStr(RptPageCount));
 { En-tete grille }
 ClipX2 := SCREEN_W - 12;
 FillBox(12, RptBodyY1, ClipX2, RptBodyY1 + GRID_HDR_H, CLR_LGRAY);
 SetColor(CLR_WIN_HI);
 HLine(12, ClipX2, RptBodyY1, CLR_WIN_HI);
 SetColor(CLR_WIN_LO);
 HLine(12, ClipX2, RptBodyY1 + GRID_HDR_H, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 For I := 1 To T^.FldCount Do Begin
  If RptColX[I] = 0 Then Break;
  If RptColX[I] + RptColW[I] > ClipX2 Then Break;
  S := T^.Fields[I].Name;
  While (Length(S) > 0) And (TextWidth(S) > RptColW[I] - 6) Do
   S := Copy(S, 1, Length(S) - 1);
  OutTextXY(RptColX[I] + 4, RptBodyY1 + 4, S);
  If I > 1 Then VLine(RptColX[I], RptBodyY1, RptBodyY1 + GRID_HDR_H, CLR_WIN_LO);
 End;
 { Lignes }
 FirstRec := (RptPage - 1) * RptRowsPerPage + 1;
 LastRec  := FirstRec + RptRowsPerPage - 1;
 RowIdx := 0;
 J := 0;
 BaseY := RptBodyY1 + GRID_HDR_H;
 For I := 1 To T^.RecCount Do Begin
  If (T^.Records[I] = Nil) Or (T^.Records[I]^.Deleted) Then Continue;
  Inc(J);
  If J < FirstRec Then Continue;
  If J > LastRec  Then Break;
  R := T^.Records[I];
  Y1 := BaseY + RowIdx * ROW_H;
  Y2 := Y1 + ROW_H - 1;
  If (RowIdx And 1) = 1 Then FillBox(12, Y1, ClipX2, Y2, CLR_LGRAY);
  SetColor(CLR_BLACK);
  X1 := 0;
  For X2 := 1 To T^.FldCount Do Begin
   If RptColX[X2] = 0 Then Break;
   If RptColX[X2] + RptColW[X2] > ClipX2 Then Break;
   S := R^.Values[X2];
   If T^.Fields[X2].FType = FT_BOOL Then Begin
    If (S = 'T') Or (S = '1') Or (S = 'Oui') Then S := '[X]' Else S := '[ ]';
   End;
   While (Length(S) > 0) And (TextWidth(S) > RptColW[X2] - 6) Do
    S := Copy(S, 1, Length(S) - 1);
   OutTextXY(RptColX[X2] + 4, Y1 + (ROW_H - 8) Div 2, S);
   If X2 > 1 Then VLine(RptColX[X2], Y1, Y2, CLR_LGRAY);
   X1 := RptColX[X2] + RptColW[X2];
  End;
  HLine(12, ClipX2, Y2, CLR_LGRAY);
  Inc(RowIdx);
 End;
 SetColor(CLR_WIN_LO);
 Rectangle(12, RptBodyY1, ClipX2, BaseY + RptRowsPerPage * ROW_H);
 { Pied : total et boutons }
 SetColor(CLR_BLACK);
 OutTextXY(16, RptBodyY2 - 12,
           'Total : ' + IntToStr(RecsTotal) + ' enregistrement(s)');
 RptGetBtnRect(1, X1, Y1, X2, Y2); RptDrawBtn(X1, Y1, X2, Y2, '|<');
 RptGetBtnRect(2, X1, Y1, X2, Y2); RptDrawBtn(X1, Y1, X2, Y2, '<');
 RptGetBtnRect(3, X1, Y1, X2, Y2); RptDrawBtn(X1, Y1, X2, Y2, '>');
 RptGetBtnRect(4, X1, Y1, X2, Y2); RptDrawBtn(X1, Y1, X2, Y2, '>|');
 Pos := 'Esc=Retour  PgUp/PgDn=Page';
 SetColor(CLR_BLACK);
 OutTextXY(SCREEN_W - 8 - TextWidth(Pos),
           RptBtnY + (RptBtnH - 8) Div 2, Pos);
 ShowMouse;
End;

{ ====================================================================== }
{                       VUE RELATIONS                                    }
{ ====================================================================== }

Procedure RelComputeArea;
Begin
 RelArea1 := ToolY2 + 4;
 RelBtnH  := 22;
 RelBtnY  := SCREEN_H - STAT_H - 6 - RelBtnH;
 RelArea2 := RelBtnY - 6;
End;

Procedure RelInitLayout;
Var I, Cols, Col, Row, BoxW, BoxH, Gx, Gy, FldCount: Integer;
Begin
 RelComputeArea;
 If DB.TblCount < 1 Then Exit;
 Cols := 3;
 If DB.TblCount <= 1 Then Cols := 1
 Else If DB.TblCount <= 4 Then Cols := 2;
 BoxW := (SCREEN_W - 24) Div Cols - 12;
 If BoxW < 110 Then BoxW := 110;
 If BoxW > 180 Then BoxW := 180;
 For I := 1 To DB.TblCount Do Begin
  If DB.Tables[I] = Nil Then Begin
   RelBoxX[I] := 0; RelBoxY[I] := 0;
   RelBoxW[I] := 0; RelBoxH[I] := 0;
   Continue;
  End;
  FldCount := DB.Tables[I]^.FldCount;
  If FldCount > 8 Then FldCount := 8;
  BoxH := 18 + FldCount * 12 + 4;
  Col := (I - 1) Mod Cols;
  Row := (I - 1) Div Cols;
  Gx := 12 + Col * (BoxW + 12);
  Gy := RelArea1 + 8 + Row * (BoxH + 16);
  If Gy + BoxH > RelArea2 - 4 Then
   Gy := RelArea1 + 8 + (Row Mod 3) * 40;
  RelBoxX[I] := Gx;
  RelBoxY[I] := Gy;
  RelBoxW[I] := BoxW;
  RelBoxH[I] := BoxH;
 End;
 RelLayoutDone := True;
End;

Procedure RelGetBtnRect(Idx: Integer; Var X1, Y1, X2, Y2: Integer);
Const W = 90; Gap = 6;
Begin
 X1 := 12 + (Idx - 1) * (W + Gap);
 X2 := X1 + W - 1;
 Y1 := RelBtnY;
 Y2 := RelBtnY + RelBtnH - 1;
End;

Procedure RelDrawBtn(X1, Y1, X2, Y2: Integer; Const Cap: String);
Var Tw: Integer;
Begin
 DrawRaised(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 Tw := TextWidth(Cap);
 OutTextXY(X1 + ((X2 - X1) - Tw) Div 2, Y1 + ((Y2 - Y1) - 8) Div 2, Cap);
End;

Function RelFieldRowY(TblIdx, FldOrdinal: Integer): Integer;
Begin
 RelFieldRowY := RelBoxY[TblIdx] + 18 + (FldOrdinal - 1) * 12 + 6;
End;

Procedure RelDrawTableBox(I: Integer);
Var T: PTable; X1, Y1, X2, Y2, J, Yt, MaxFlds: Integer; S: String;
Begin
 If (I < 1) Or (I > DB.TblCount) Or (DB.Tables[I] = Nil) Then Exit;
 T := DB.Tables[I];
 X1 := RelBoxX[I];
 Y1 := RelBoxY[I];
 X2 := X1 + RelBoxW[I] - 1;
 Y2 := Y1 + RelBoxH[I] - 1;
 DropShadow(X1, Y1, X2, Y2);
 DrawRaised(X1, Y1, X2, Y2, CLR_WHITE, CLR_WIN_HI, CLR_WIN_LO);
 { Bandeau titre }
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 S := T^.Name;
 If TextWidth(S) > RelBoxW[I] - 12 Then
  While (Length(S) > 0) And (TextWidth(S + '..') > RelBoxW[I] - 12) Do
   Delete(S, Length(S), 1);
 OutTextXY(X1 + 6, Y1 + 4, S);
 { Champs }
 MaxFlds := T^.FldCount;
 If MaxFlds > 8 Then MaxFlds := 8;
 For J := 1 To MaxFlds Do Begin
  Yt := RelFieldRowY(I, J) - 4;
  SetColor(CLR_BLACK);
  S := T^.Fields[J].Name;
  If T^.Fields[J].PrimaryKey Then S := S + ' *';
  If TextWidth(S) > RelBoxW[I] - 12 Then
   While (Length(S) > 0) And (TextWidth(S + '..') > RelBoxW[I] - 12) Do
    Delete(S, Length(S), 1);
  OutTextXY(X1 + 6, Yt, S);
 End;
 If T^.FldCount > MaxFlds Then Begin
  SetColor(CLR_DGRAY);
  OutTextXY(X1 + 6, Y2 - 10, '...');
 End;
End;

Procedure RelDrawJoin(R: PRelation; Selected: Boolean);
Var T1, T2: Integer; Y1L, Y2L, X1L, X2L, Mx, My: Integer; Col: Integer;
Begin
 T1 := R^.TblFromIdx; T2 := R^.TblToIdx;
 If (T1 < 1) Or (T1 > DB.TblCount) Or (DB.Tables[T1] = Nil) Then Exit;
 If (T2 < 1) Or (T2 > DB.TblCount) Or (DB.Tables[T2] = Nil) Then Exit;
 If (R^.FldFromIdx < 1) Or (R^.FldFromIdx > DB.Tables[T1]^.FldCount) Then Exit;
 If (R^.FldToIdx < 1) Or (R^.FldToIdx > DB.Tables[T2]^.FldCount) Then Exit;
 { Determine cote droit/gauche pour points d'ancrage }
 If RelBoxX[T1] + RelBoxW[T1] Div 2 <= RelBoxX[T2] + RelBoxW[T2] Div 2 Then Begin
  X1L := RelBoxX[T1] + RelBoxW[T1] - 1;
  X2L := RelBoxX[T2];
 End Else Begin
  X1L := RelBoxX[T1];
  X2L := RelBoxX[T2] + RelBoxW[T2] - 1;
 End;
 Y1L := RelFieldRowY(T1, R^.FldFromIdx);
 Y2L := RelFieldRowY(T2, R^.FldToIdx);
 If Selected Then Col := CLR_LRED Else Col := CLR_BLUE;
 SetColor(Col);
 Line(X1L, Y1L, X2L, Y2L);
 If Selected Then Begin
  Line(X1L, Y1L - 1, X2L, Y2L - 1);
  Line(X1L, Y1L + 1, X2L, Y2L + 1);
 End;
 { Marqueur 1 cote source }
 SetColor(CLR_BLACK);
 OutTextXY(X1L + 4 * (Ord(X2L > X1L) * 2 - 1) - 4, Y1L - 10, '1');
 { Marqueur infini (N) cote cible }
 Mx := X2L + 4 * (Ord(X1L > X2L) * 2 - 1) - 4;
 My := Y2L - 10;
 OutTextXY(Mx, My, 'N');
 If R^.Enforce Then Begin
  SetColor(CLR_DGRAY);
  OutTextXY((X1L + X2L) Div 2 - 4, (Y1L + Y2L) Div 2 - 4, '#');
 End;
End;

Procedure DrawRelationsView;
Var I, X1, Y1, X2, Y2: Integer; Hint, S: String;
Begin
 RelComputeArea;
 If Not RelLayoutDone Then RelInitLayout;
 HideMouse;
 FillBox(0, RelArea1, SCREEN_W - 1, RelArea2, CLR_WIN_BG);
 { Bandeau titre du mode }
 FillBox(0, RelArea1, SCREEN_W - 1, RelArea1 + 16, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(8, RelArea1 + 4, 'Relations - ' + DB.Name);
 SetColor(CLR_BLACK);
 If DB.TblCount = 0 Then Begin
  OutTextXY(20, RelArea1 + 40,
            'Aucune table. Creez d''abord des tables pour definir des relations.');
 End Else Begin
  { Boites tables }
  For I := 1 To DB.TblCount Do RelDrawTableBox(I);
  { Lignes de jointure }
  For I := 1 To DB.RelCount Do
   If DB.Relations[I] <> Nil Then
    RelDrawJoin(DB.Relations[I], I = RelSelIdx);
 End;
 { Barre de boutons }
 FillBox(0, RelBtnY - 4, SCREEN_W - 1, RelBtnY + RelBtnH + 2, CLR_LGRAY);
 HLine(0, SCREEN_W - 1, RelBtnY - 4, CLR_WIN_HI);
 RelGetBtnRect(1, X1, Y1, X2, Y2); RelDrawBtn(X1, Y1, X2, Y2, 'Ajouter...');
 RelGetBtnRect(2, X1, Y1, X2, Y2); RelDrawBtn(X1, Y1, X2, Y2, 'Supprimer');
 RelGetBtnRect(3, X1, Y1, X2, Y2); RelDrawBtn(X1, Y1, X2, Y2, 'Reorganiser');
 RelGetBtnRect(4, X1, Y1, X2, Y2); RelDrawBtn(X1, Y1, X2, Y2, 'Fermer');
 SetColor(CLR_BLACK);
 If RelSelIdx > 0 Then Begin
  S := 'Relation: ' + DB.Relations[RelSelIdx]^.Name;
  OutTextXY(SCREEN_W - 8 - TextWidth(S),
            RelBtnY + (RelBtnH - 8) Div 2 - 7, S);
 End;
 Hint := 'Esc=Retour  Tab=Selection  Del=Supprimer  Ins=Ajouter';
 OutTextXY(SCREEN_W - 8 - TextWidth(Hint),
           RelBtnY + (RelBtnH - 8) Div 2 + 5, Hint);
 ShowMouse;
End;

Function RelTableAt(MX, MY: Integer): Integer;
Var I: Integer;
Begin
 RelTableAt := 0;
 For I := DB.TblCount DownTo 1 Do
  If (DB.Tables[I] <> Nil) And
     InRect(MX, MY, RelBoxX[I], RelBoxY[I],
                    RelBoxX[I] + RelBoxW[I] - 1,
                    RelBoxY[I] + RelBoxH[I] - 1) Then Begin
   RelTableAt := I; Exit;
  End;
End;

Function RelHitTest(MX, MY: Integer): Integer;
Var I, T1, T2: Integer; R: PRelation;
    X1L, Y1L, X2L, Y2L: Integer;
    Dx, Dy, NumL, DenL: LongInt;
Begin
 RelHitTest := 0;
 For I := 1 To DB.RelCount Do Begin
  R := DB.Relations[I];
  If R = Nil Then Continue;
  T1 := R^.TblFromIdx; T2 := R^.TblToIdx;
  If (T1 < 1) Or (T1 > DB.TblCount) Or (DB.Tables[T1] = Nil) Then Continue;
  If (T2 < 1) Or (T2 > DB.TblCount) Or (DB.Tables[T2] = Nil) Then Continue;
  If (R^.FldFromIdx < 1) Or (R^.FldFromIdx > DB.Tables[T1]^.FldCount) Then Continue;
  If (R^.FldToIdx < 1) Or (R^.FldToIdx > DB.Tables[T2]^.FldCount) Then Continue;
  If RelBoxX[T1] + RelBoxW[T1] Div 2 <= RelBoxX[T2] + RelBoxW[T2] Div 2 Then Begin
   X1L := RelBoxX[T1] + RelBoxW[T1] - 1;
   X2L := RelBoxX[T2];
  End Else Begin
   X1L := RelBoxX[T1];
   X2L := RelBoxX[T2] + RelBoxW[T2] - 1;
  End;
  Y1L := RelFieldRowY(T1, R^.FldFromIdx);
  Y2L := RelFieldRowY(T2, R^.FldToIdx);
  { Distance point-segment, tol = 4 px }
  Dx := X2L - X1L; Dy := Y2L - Y1L;
  DenL := Dx*Dx + Dy*Dy;
  If DenL = 0 Then Continue;
  NumL := (LongInt(MX - X1L)*Dx + LongInt(MY - Y1L)*Dy);
  If (NumL < 0) Or (NumL > DenL) Then Continue;
  { Cross product magnitude / sqrt(DenL); compare squared }
  NumL := LongInt(MX - X1L)*Dy - LongInt(MY - Y1L)*Dx;
  If NumL < 0 Then NumL := -NumL;
  If LongInt(NumL)*NumL <= 16 * DenL Then Begin
   RelHitTest := I; Exit;
  End;
 End;
End;

{ ====================================================================== }
{                       REDRAW                                           }
{ ====================================================================== }

Procedure RedrawAll;
Begin
 HideMouse;
 FillBox(0, 0, SCREEN_W - 1, SCREEN_H - 1, CLR_WIN_BG);
 ShowMouse;
 DrawMenuBar;
 DrawToolbar;
 Case CurView Of
  VIEW_NAV    : DrawNavView;
  VIEW_DSHEET : DrawDSheetView;
  VIEW_DESIGN : DrawDesignView;
  VIEW_QUERY  : DrawQueryView;
  VIEW_FORM   : DrawFormView;
  VIEW_REPORT : DrawReportView;
  VIEW_RELATIONS : DrawRelationsView;
 End;
 DrawStatusBar;
 If MenuOpen > 0 Then DrawDropDown;
End;

Procedure Redraw;
Begin
 If NeedFullRedraw Then Begin
  RedrawAll;
  NeedFullRedraw := False;
  NeedGridRedraw := False;
  NeedMenuRedraw := False;
  NeedStatRedraw := False;
  NeedDropRedraw := False;
  NeedNavRedraw  := False;
  Exit;
 End;
 If NeedMenuRedraw Then Begin DrawMenuBar; NeedMenuRedraw := False; End;
 If NeedGridRedraw Then Begin
  Case CurView Of
   VIEW_DSHEET: DrawDSheetView;
  End;
  NeedGridRedraw := False;
 End;
 If NeedNavRedraw And (CurView = VIEW_NAV) Then Begin
  DrawNavView; NeedNavRedraw := False;
 End;
 If NeedStatRedraw Then Begin DrawStatusBar; NeedStatRedraw := False; End;
 If (MenuOpen > 0) And NeedDropRedraw Then Begin
  DrawDropDown; NeedDropRedraw := False;
 End;
End;

{ ====================================================================== }
{                       ACTIONS                                          }
{ ====================================================================== }

{ ====================================================================== }
{                       LOGO / IMAGES (vectoriel)                        }
{ ====================================================================== }

{ Dessine une cle stylisee (logo Access) centree en (Cx, Cy).
  S = facteur d'echelle approx. en pixels (rayon de l'anneau). }
Procedure DrawAccessLogo(Cx, Cy, S: Integer);
Var ShaftLen, ToothH, ToothW, R1, R2, Hole, K: Integer;
    X, Y: Integer;
Begin
 R1   := S;
 R2   := S Div 2;
 Hole := S Div 3;
 ShaftLen := S * 4;
 ToothH   := S Div 2 + 1;
 ToothW   := S Div 2 + 1;
 { Ombre }
 SetFillStyle(1, CLR_BLACK);
 SetColor(CLR_BLACK);
 FillEllipse(Cx + 2, Cy + 3, R1 + 1, R1 + 1);
 FillBox(Cx + R1 + 2, Cy + 3 - R2 Div 2, Cx + R1 + ShaftLen + 2,
         Cy + 3 + R2 Div 2, CLR_BLACK);
 { Anneau exterieur en magenta }
 SetFillStyle(1, CLR_LMAGENTA);
 SetColor(CLR_LMAGENTA);
 FillEllipse(Cx, Cy, R1, R1);
 { Bordure de l'anneau }
 SetColor(CLR_MAGENTA);
 Circle(Cx, Cy, R1);
 { Trou central }
 SetFillStyle(1, CLR_WHITE);
 SetColor(CLR_WHITE);
 FillEllipse(Cx, Cy, Hole, Hole);
 SetColor(CLR_DGRAY);
 Circle(Cx, Cy, Hole);
 { Tige (shaft) }
 FillBox(Cx + R1 - 2, Cy - R2 Div 2, Cx + R1 + ShaftLen,
         Cy + R2 Div 2, CLR_LMAGENTA);
 SetColor(CLR_MAGENTA);
 Rectangle(Cx + R1 - 2, Cy - R2 Div 2, Cx + R1 + ShaftLen,
           Cy + R2 Div 2);
 { Deux dents }
 X := Cx + R1 + ShaftLen - ToothW;
 Y := Cy + R2 Div 2;
 FillBox(X, Y, X + ToothW, Y + ToothH, CLR_LMAGENTA);
 SetColor(CLR_MAGENTA); Rectangle(X, Y, X + ToothW, Y + ToothH);
 X := Cx + R1 + ShaftLen Div 2;
 FillBox(X, Y, X + ToothW Div 2, Y + ToothH - 2, CLR_LMAGENTA);
 SetColor(CLR_MAGENTA); Rectangle(X, Y, X + ToothW Div 2, Y + ToothH - 2);
 { Reflet (highlight) sur l'anneau }
 SetColor(CLR_WHITE);
 K := R1 - 2;
 Arc(Cx, Cy, 100, 160, K);
End;

Procedure ShowSplash;
Var X1, Y1, X2, Y2: Integer; T0, T1: LongInt;
    Done: Boolean; K: Char;
Begin
 X1 := 80; Y1 := 80; X2 := 560; Y2 := 400;
 HideMouse;
 SetFillStyle(1, CLR_BLUE);
 Bar(0, 0, SCREEN_W - 1, SCREEN_H - 1);
 { Cadre arriere-plan en degrade simule }
 FillBox(X1 - 4, Y1 - 4, X2 + 4, Y2 + 4, CLR_BLACK);
 FillBox(X1, Y1, X2, Y2, CLR_LGRAY);
 HLine(X1, X2 - 1, Y1, CLR_WIN_HI); VLine(X1, Y1, Y2 - 1, CLR_WIN_HI);
 HLine(X1, X2, Y2, CLR_DGRAY);      VLine(X2, Y1, Y2, CLR_DGRAY);
 { Bande titre }
 FillBox(X1 + 4, Y1 + 4, X2 - 4, Y1 + 50, CLR_BLUE);
 SetColor(CLR_WHITE);
 SetTextStyle(DefaultFont, HorizDir, 2);
 OutTextXY(X1 + 24, Y1 + 14, 'Office-0  Access');
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(CLR_YELLOW);
 OutTextXY(X1 + 24, Y1 + 40, 'Systeme de gestion de bases de donnees');
 { Logo cle }
 DrawAccessLogo(X1 + 100, Y1 + 150, 28);
 { Infos }
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 180, Y1 + 110, 'Version 1.00');
 OutTextXY(X1 + 180, Y1 + 130, 'Copyright (c) 2026 Sylvain Maltais');
 OutTextXY(X1 + 180, Y1 + 150, 'www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 180, Y1 + 180, 'Formats : .MDB  .SQL  .CSV');
 OutTextXY(X1 + 180, Y1 + 196, 'Compilateur : Free Pascal 3.2 (-Mtp)');
 OutTextXY(X1 + 180, Y1 + 212, 'Affichage : 640 x 480 x 16 (VGA)');
 { Pied de page }
 FillBox(X1 + 4, Y2 - 28, X2 - 4, Y2 - 4, CLR_DGRAY);
 SetColor(CLR_WHITE);
 OutTextXY(X1 + 20, Y2 - 22,
           'Appuyez sur une touche ou cliquez pour continuer...');
 ShowMouse;
 T0 := TickCount;
 Done := False;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey; If K = #0 Then ReadKey; Done := True;
  End;
  If LeftPressed Then Begin Done := True; While LeftDown Do UpdateMouse; End;
  T1 := TickCount;
  If (T1 - T0) > 40 Then Done := True;  { ~2.2s }
  Delay(20);
 Until Done;
End;

Procedure ActionAbout;
Var X1, Y1, X2, Y2: Integer; K: Char;
Begin
 X1 := 110; Y1 := 90; X2 := 530; Y2 := 390;
 DlgFrame(X1, Y1, X2, Y2, 'A propos de Office-0 Access');
 HideMouse;
 { Logo }
 DrawAccessLogo(X1 + 60, Y1 + 90, 20);
 { Texte }
 SetColor(CLR_BLACK);
 SetTextStyle(DefaultFont, HorizDir, 2);
 OutTextXY(X1 + 140, Y1 + 28, 'Office-0  Access');
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(CLR_BLUE);
 OutTextXY(X1 + 140, Y1 + 58, 'Clone de Microsoft Access');
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 140, Y1 + 76, 'Version 1.00 - 2026');
 OutTextXY(X1 + 140, Y1 + 92, '(c) Sylvain Maltais');
 OutTextXY(X1 + 140, Y1 + 108,'www.gladir.com');
 { Separateur }
 HLine(X1 + 16, X2 - 16, Y1 + 140, CLR_DGRAY);
 HLine(X1 + 16, X2 - 16, Y1 + 141, CLR_WIN_HI);
 { Caracteristiques }
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 20, Y1 + 152, 'Tables, requetes SQL, formulaires, etats, relations.');
 OutTextXY(X1 + 20, Y1 + 168, 'Formats : .MDB (binaire)  .SQL  .CSV');
 OutTextXY(X1 + 20, Y1 + 184, 'Compilateur : Free Pascal 3.2 (mode -Mtp)');
 OutTextXY(X1 + 20, Y1 + 200, 'Mode graphique : 640 x 480 x 16 couleurs');
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 20, Y1 + 224, 'Raccourcis : F1 Aide  F11 Base  F5 Executer');
 OutTextXY(X1 + 20, Y1 + 240, '             Ctrl+N/O/S/P  Ctrl+Z/Y');
 DlgBtn(X2 - 90, Y2 - 32, X2 - 20, Y2 - 12, 'OK', False, True);
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
   If InRect(Mouse.X, Mouse.Y, X2 - 90, Y2 - 32, X2 - 20, Y2 - 12) Then Begin
    NeedFullRedraw := True; Exit;
   End;
 Until False;
End;

Procedure ActionQuit;
Begin
 Quitting := True;
End;

Procedure ActionView(V: Integer);
Begin
 CurView := V;
 NeedFullRedraw := True;
End;

Procedure ActionNavObjType(OT: Integer);
Begin
 CurObjType := OT;
 NavSelObj  := 1;
 NavScroll  := 0;
 NeedFullRedraw := True;
End;

Procedure ActionOpenSelectedObj;
Begin
 Case CurObjType Of
  OBJ_TABLE:
   If (NavSelObj >= 1) And (NavSelObj <= DB.TblCount) Then Begin
    CurTblIdx := NavSelObj;
    CurRecIdx := 1;
    CurFldIdx := 1;
    CurView   := VIEW_DSHEET;
    NeedFullRedraw := True;
   End;
  OBJ_QUERY:
   If (NavSelObj >= 1) And (NavSelObj <= DB.QryCount) And (DB.Queries[NavSelObj] <> Nil) Then Begin
    CurQryIdx := NavSelObj;
    QSqlBuf := DB.Queries[NavSelObj]^.SQL + DB.Queries[NavSelObj]^.SQL2;
    QCaret  := Length(QSqlBuf);
    QFocus  := 0;
    QResColCount := 0; QResRowCount := 0;
    QStatusMsg := ''; QStatusErr := False;
    QDirty := False;
    CurView := VIEW_QUERY;
    NeedFullRedraw := True;
   End;
  OBJ_FORM:
   If (NavSelObj >= 1) And (NavSelObj <= DB.FrmCount) And (DB.Forms[NavSelObj] <> Nil) Then Begin
    CurFrmIdx := NavSelObj;
    If (DB.Forms[NavSelObj]^.SrcTable >= 1) And
       (DB.Forms[NavSelObj]^.SrcTable <= DB.TblCount) Then Begin
     CurTblIdx := DB.Forms[NavSelObj]^.SrcTable;
     CurFldIdx := 1;
     CurRecIdx := 1;
     If DB.Tables[CurTblIdx]^.RecCount < 1 Then CurRecIdx := 0;
    End;
    FormScroll := 1;
    CurView := VIEW_FORM;
    NeedFullRedraw := True;
   End;
  OBJ_REPORT:
   If (NavSelObj >= 1) And (NavSelObj <= DB.RptCount) And (DB.Reports[NavSelObj] <> Nil) Then Begin
    CurRptIdx := NavSelObj;
    If (DB.Reports[NavSelObj]^.SrcTable >= 1) And
       (DB.Reports[NavSelObj]^.SrcTable <= DB.TblCount) Then
     CurTblIdx := DB.Reports[NavSelObj]^.SrcTable;
    RptPage := 1;
    CurView := VIEW_REPORT;
    NeedFullRedraw := True;
   End;
 End;
End;

Procedure ActionFirstRec;
Begin
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) And
    (DB.Tables[CurTblIdx] <> Nil) Then
  If DB.Tables[CurTblIdx]^.RecCount > 0 Then Begin
   CurRecIdx := 1; NeedGridRedraw := True; NeedStatRedraw := True;
  End;
End;

Procedure ActionLastRec;
Begin
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) And
    (DB.Tables[CurTblIdx] <> Nil) Then
  If DB.Tables[CurTblIdx]^.RecCount > 0 Then Begin
   CurRecIdx := DB.Tables[CurTblIdx]^.RecCount;
   NeedGridRedraw := True; NeedStatRedraw := True;
  End;
End;

Procedure ActionPrevRec;
Begin
 If CurRecIdx > 1 Then Begin
  Dec(CurRecIdx); NeedGridRedraw := True; NeedStatRedraw := True;
 End;
End;

Procedure ActionNextRec;
Begin
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) And
    (DB.Tables[CurTblIdx] <> Nil) Then
  If CurRecIdx < DB.Tables[CurTblIdx]^.RecCount Then Begin
   Inc(CurRecIdx); NeedGridRedraw := True; NeedStatRedraw := True;
  End;
End;

Procedure ActionInsRec;
Var T: PTable; I: Integer; R: PRecord; Op: PUndoOp; FType: Byte;
Begin
 If EditMode Then CommitEdit;
 T := CurTable;
 If T = Nil Then Exit;
 If T^.RecCount >= MAX_RECORDS Then Begin
  StatusMsg := 'Limite d''enregistrements atteinte.';
  NeedStatRedraw := True; Exit;
 End;
 If CurRecIdx < 1 Then CurRecIdx := 1;
 If CurRecIdx > T^.RecCount + 1 Then CurRecIdx := T^.RecCount + 1;
 GetMem(R, SizeOf(TRecordData));
 FillChar(R^, SizeOf(TRecordData), 0);
 For I := 1 To T^.FldCount Do Begin
  FType := T^.Fields[I].FType;
  If FType = FT_AUTONUM Then Begin
   R^.Values[I] := IntToStr(T^.NextAutoNum);
   Inc(T^.NextAutoNum);
  End
  Else If T^.Fields[I].DefaultVal <> '' Then
   R^.Values[I] := T^.Fields[I].DefaultVal
  Else
   R^.Values[I] := '';
 End;
 For I := T^.RecCount Downto CurRecIdx Do T^.Records[I + 1] := T^.Records[I];
 T^.Records[CurRecIdx] := R;
 Inc(T^.RecCount);
 T^.Dirty := True; DB.Dirty := True;

 GetMem(Op, SizeOf(TUndoOp));
 FillChar(Op^, SizeOf(TUndoOp), 0);
 Op^.Kind   := UND_INSREC;
 Op^.TblIdx := CurTblIdx;
 Op^.RecIdx := CurRecIdx;
 Op^.RecBak := R^;
 UndoPush(Op);
 NeedGridRedraw := True; NeedStatRedraw := True;
End;

Procedure ActionDelRec;
Var T: PTable; I: Integer; R: PRecord; Op: PUndoOp;
Begin
 If EditMode Then CancelEdit;
 T := CurTable;
 If T = Nil Then Exit;
 If (CurRecIdx < 1) Or (CurRecIdx > T^.RecCount) Then Exit;
 R := T^.Records[CurRecIdx];
 If R = Nil Then Exit;

 GetMem(Op, SizeOf(TUndoOp));
 FillChar(Op^, SizeOf(TUndoOp), 0);
 Op^.Kind   := UND_DELREC;
 Op^.TblIdx := CurTblIdx;
 Op^.RecIdx := CurRecIdx;
 Op^.RecBak := R^;
 UndoPush(Op);

 FreeMem(R, SizeOf(TRecordData));
 For I := CurRecIdx To T^.RecCount - 1 Do T^.Records[I] := T^.Records[I + 1];
 T^.Records[T^.RecCount] := Nil;
 Dec(T^.RecCount);
 If CurRecIdx > T^.RecCount Then CurRecIdx := T^.RecCount;
 If CurRecIdx < 1 Then CurRecIdx := 1;
 T^.Dirty := True; DB.Dirty := True;
 NeedGridRedraw := True; NeedStatRedraw := True;
End;

Procedure ActionNewRec;
Var T: PTable;
Begin
 T := CurTable;
 If T = Nil Then Exit;
 If EditMode Then CommitEdit;
 CurRecIdx := T^.RecCount + 1;
 ActionInsRec;
 CurFldIdx := 1;
 NeedGridRedraw := True;
End;

Procedure DoUndo;
Var Op: PUndoOp; T: PTable; I: Integer; R: PRecord; Rebak: PUndoOp;
Begin
 If UndoTop = 0 Then Exit;
 If EditMode Then CancelEdit;
 Op := UndoStack[UndoTop];
 UndoStack[UndoTop] := Nil;
 Dec(UndoTop);
 If Op = Nil Then Exit;
 If (Op^.TblIdx < 1) Or (Op^.TblIdx > DB.TblCount) Then Begin
  FreeMem(Op, SizeOf(TUndoOp)); Exit;
 End;
 T := DB.Tables[Op^.TblIdx];
 If T = Nil Then Begin FreeMem(Op, SizeOf(TUndoOp)); Exit; End;
 CurTblIdx := Op^.TblIdx;
 Case Op^.Kind Of
  UND_EDIT:
   Begin
    If (Op^.RecIdx >= 1) And (Op^.RecIdx <= T^.RecCount) Then Begin
     T^.Records[Op^.RecIdx]^.Values[Op^.FldIdx] := Op^.OldVal;
     CurRecIdx := Op^.RecIdx; CurFldIdx := Op^.FldIdx;
    End;
   End;
  UND_INSREC:
   Begin
    If (Op^.RecIdx >= 1) And (Op^.RecIdx <= T^.RecCount) Then Begin
     R := T^.Records[Op^.RecIdx];
     If R <> Nil Then Begin
      Op^.RecBak := R^;
      FreeMem(R, SizeOf(TRecordData));
     End;
     For I := Op^.RecIdx To T^.RecCount - 1 Do
      T^.Records[I] := T^.Records[I + 1];
     T^.Records[T^.RecCount] := Nil;
     Dec(T^.RecCount);
     CurRecIdx := Op^.RecIdx;
     If CurRecIdx > T^.RecCount Then CurRecIdx := T^.RecCount;
     If CurRecIdx < 1 Then CurRecIdx := 1;
    End;
   End;
  UND_DELREC:
   Begin
    If T^.RecCount < MAX_RECORDS Then Begin
     GetMem(R, SizeOf(TRecordData));
     R^ := Op^.RecBak;
     For I := T^.RecCount Downto Op^.RecIdx Do
      T^.Records[I + 1] := T^.Records[I];
     T^.Records[Op^.RecIdx] := R;
     Inc(T^.RecCount);
     CurRecIdx := Op^.RecIdx;
    End;
   End;
 End;
 { Push to redo stack }
 GetMem(Rebak, SizeOf(TUndoOp));
 Rebak^ := Op^;
 FreeMem(Op, SizeOf(TUndoOp));
 If RedoTop < UNDO_STACK Then Begin
  Inc(RedoTop); RedoStack[RedoTop] := Rebak;
 End
 Else FreeMem(Rebak, SizeOf(TUndoOp));
 T^.Dirty := True; DB.Dirty := True;
 NeedGridRedraw := True; NeedStatRedraw := True;
End;

Procedure DoRedo;
Var Op: PUndoOp; T: PTable; I: Integer; R: PRecord; Pushb: PUndoOp;
Begin
 If RedoTop = 0 Then Exit;
 If EditMode Then CancelEdit;
 Op := RedoStack[RedoTop];
 RedoStack[RedoTop] := Nil;
 Dec(RedoTop);
 If Op = Nil Then Exit;
 If (Op^.TblIdx < 1) Or (Op^.TblIdx > DB.TblCount) Then Begin
  FreeMem(Op, SizeOf(TUndoOp)); Exit;
 End;
 T := DB.Tables[Op^.TblIdx];
 If T = Nil Then Begin FreeMem(Op, SizeOf(TUndoOp)); Exit; End;
 CurTblIdx := Op^.TblIdx;
 Case Op^.Kind Of
  UND_EDIT:
   Begin
    If (Op^.RecIdx >= 1) And (Op^.RecIdx <= T^.RecCount) Then Begin
     T^.Records[Op^.RecIdx]^.Values[Op^.FldIdx] := Op^.NewVal;
     CurRecIdx := Op^.RecIdx; CurFldIdx := Op^.FldIdx;
    End;
   End;
  UND_INSREC:
   Begin
    If T^.RecCount < MAX_RECORDS Then Begin
     GetMem(R, SizeOf(TRecordData));
     R^ := Op^.RecBak;
     For I := T^.RecCount Downto Op^.RecIdx Do
      T^.Records[I + 1] := T^.Records[I];
     T^.Records[Op^.RecIdx] := R;
     Inc(T^.RecCount);
     CurRecIdx := Op^.RecIdx;
    End;
   End;
  UND_DELREC:
   Begin
    If (Op^.RecIdx >= 1) And (Op^.RecIdx <= T^.RecCount) Then Begin
     R := T^.Records[Op^.RecIdx];
     If R <> Nil Then FreeMem(R, SizeOf(TRecordData));
     For I := Op^.RecIdx To T^.RecCount - 1 Do
      T^.Records[I] := T^.Records[I + 1];
     T^.Records[T^.RecCount] := Nil;
     Dec(T^.RecCount);
     If CurRecIdx > T^.RecCount Then CurRecIdx := T^.RecCount;
     If CurRecIdx < 1 Then CurRecIdx := 1;
    End;
   End;
 End;
 { Re-push to undo stack }
 GetMem(Pushb, SizeOf(TUndoOp));
 Pushb^ := Op^;
 FreeMem(Op, SizeOf(TUndoOp));
 If UndoTop < UNDO_STACK Then Begin
  Inc(UndoTop); UndoStack[UndoTop] := Pushb;
 End
 Else FreeMem(Pushb, SizeOf(TUndoOp));
 T^.Dirty := True; DB.Dirty := True;
 NeedGridRedraw := True; NeedStatRedraw := True;
End;

Procedure DoAction(A: Integer); Forward;

Procedure ActionNewTable;
Var T: PTable; F: PField; N: Integer;
Begin
 If DB.TblCount >= MAX_TABLES Then Begin
  MessageBox('Erreur', 'Nombre maximal de tables atteint.');
  Exit;
 End;
 GetMem(T, SizeOf(TTable));
 FillChar(T^, SizeOf(TTable), 0);
 N := DB.TblCount + 1;
 T^.Name        := 'Table' + IntToStr(N);
 T^.Description := '';
 T^.FldCount    := 1;
 F := @T^.Fields[1];
 FillChar(F^, SizeOf(TField), 0);
 F^.Name       := 'ID';
 F^.FType      := FT_AUTONUM;
 F^.Size       := 4;
 F^.PrimaryKey := True;
 F^.Required   := True;
 F^.Indexed    := 2;
 F^.AllowNull  := False;
 T^.NextAutoNum := 1;
 T^.RecCount   := 0;
 T^.Dirty      := True;
 Inc(DB.TblCount);
 DB.Tables[DB.TblCount] := T;
 DB.Dirty := True;
 CurTblIdx := DB.TblCount;
 CurObjType := OBJ_TABLE;
 CurView := VIEW_DESIGN;
 DesignSelRow := 1; DesignSelCol := 2; DesignTopRow := 0;
 DesignFocus := 0; DesignPropSel := 1; DesignTypeDrop := False;
 NeedFullRedraw := True;
End;

Procedure ActionDeleteObj;
Var I: Integer;
Begin
 If CurObjType = OBJ_TABLE Then Begin
  If (NavSelObj < 1) Or (NavSelObj > DB.TblCount) Then Exit;
  If DB.Tables[NavSelObj] <> Nil Then Begin
   For I := 1 To DB.Tables[NavSelObj]^.RecCount Do
    If DB.Tables[NavSelObj]^.Records[I] <> Nil Then
     FreeMem(DB.Tables[NavSelObj]^.Records[I], SizeOf(TRecordData));
   FreeMem(DB.Tables[NavSelObj], SizeOf(TTable));
  End;
  For I := NavSelObj To DB.TblCount - 1 Do DB.Tables[I] := DB.Tables[I + 1];
  DB.Tables[DB.TblCount] := Nil;
  Dec(DB.TblCount);
  If NavSelObj > DB.TblCount Then NavSelObj := DB.TblCount;
  If NavSelObj < 1 Then NavSelObj := 1;
  DB.Dirty := True;
  NeedFullRedraw := True;
 End;
End;



Procedure ActionStub(Const N: String);
Begin
 MessageBox('Information', N + ' : sera implemente dans une phase ulterieure.');
End;

Procedure ActionNewQuery;
Var Q: PQuery; N: Integer;
Begin
 If DB.QryCount >= MAX_QUERIES Then Begin
  MessageBox('Erreur', 'Nombre maximum de requetes atteint.');
  Exit;
 End;
 New(Q);
 FillChar(Q^, SizeOf(TQuery), 0);
 N := DB.QryCount + 1;
 Q^.Name := 'Requete' + IntToStr(N);
 Q^.SQL  := 'SELECT * FROM ';
 Q^.SQL2 := '';
 Inc(DB.QryCount);
 DB.Queries[DB.QryCount] := Q;
 CurQryIdx := DB.QryCount;
 QSqlBuf := Q^.SQL;
 QCaret  := Length(QSqlBuf);
 QFocus  := 0;
 QResColCount := 0; QResRowCount := 0;
 QStatusMsg := ''; QStatusErr := False;
 QDirty := False;
 DB.Dirty := True;
 CurObjType := OBJ_QUERY;
 CurView := VIEW_QUERY;
 NeedFullRedraw := True;
End;

Procedure ActionRunQuery;
Var Q: PQuery;
Begin
 If CurView <> VIEW_QUERY Then Begin
  Q := CurQuery;
  If Q = Nil Then Begin
   ActionNewQuery;
   Exit;
  End;
  QSqlBuf := Q^.SQL + Q^.SQL2;
  QCaret  := Length(QSqlBuf);
  CurView := VIEW_QUERY;
 End;
 ExecSql(QSqlBuf);
 QFocus := 1;
 QResSelRow := 1; QResScroll := 0;
 NeedFullRedraw := True;
End;

Procedure SaveQuerySql;
Var Q: PQuery; L: Integer;
Begin
 Q := CurQuery; If Q = Nil Then Exit;
 L := Length(QSqlBuf);
 If L <= 250 Then Begin Q^.SQL := QSqlBuf; Q^.SQL2 := ''; End
 Else Begin Q^.SQL := Copy(QSqlBuf, 1, 250); Q^.SQL2 := Copy(QSqlBuf, 251, 250); End;
 QDirty := False; DB.Dirty := True;
End;

Procedure QEditInsertChar(C: Char);
Begin
 If Length(QSqlBuf) >= 250 Then Exit;
 If QCaret > Length(QSqlBuf) Then QCaret := Length(QSqlBuf);
 QSqlBuf := Copy(QSqlBuf, 1, QCaret) + C + Copy(QSqlBuf, QCaret + 1, 250);
 Inc(QCaret);
 QDirty := True;
 NeedFullRedraw := True;
End;

Procedure QEditBackspace;
Begin
 If QCaret <= 0 Then Exit;
 QSqlBuf := Copy(QSqlBuf, 1, QCaret - 1) + Copy(QSqlBuf, QCaret + 1, 250);
 Dec(QCaret);
 QDirty := True;
 NeedFullRedraw := True;
End;

Procedure QEditDelete;
Begin
 If QCaret >= Length(QSqlBuf) Then Exit;
 QSqlBuf := Copy(QSqlBuf, 1, QCaret) + Copy(QSqlBuf, QCaret + 2, 250);
 QDirty := True;
 NeedFullRedraw := True;
End;

Procedure HandleQueryClick;
Var EditY1, EditY2, ResY1, ResY2, X1, X2, ApproxIdx, ColW, Cx, I: Integer;
Begin
 X1 := 4; X2 := SCREEN_W - 4;
 EditY1 := ToolY2 + 1 + 22;
 EditY2 := QSplitY - 2;
 ResY1  := QSplitY + 5;
 ResY2  := SCREEN_H - STAT_H - 18;
 If InRect(Mouse.X, Mouse.Y, X1, EditY1, X2, EditY2) Then Begin
  QFocus := 0;
  { Approximation : ligne 1, position colonne par division par 6 }
  ApproxIdx := (Mouse.X - X1 - 4) Div 6;
  If ApproxIdx < 0 Then ApproxIdx := 0;
  If ApproxIdx > Length(QSqlBuf) Then ApproxIdx := Length(QSqlBuf);
  QCaret := ApproxIdx;
  NeedFullRedraw := True;
  Exit;
 End;
 If InRect(Mouse.X, Mouse.Y, X1, ResY1, X2, ResY2) Then Begin
  QFocus := 1;
  If QResRowCount > 0 Then Begin
   I := QResScroll + 1 + (Mouse.Y - (ResY1 + 3 + GRID_HDR_H)) Div ROW_H;
   If I >= 1 Then Begin
    If I > QResRowCount Then I := QResRowCount;
    QResSelRow := I;
   End;
   Cx := X1 + 4;
   For I := QResColScroll + 1 To QResColCount Do Begin
    ColW := QResColW[I];
    If (Mouse.X >= Cx) And (Mouse.X < Cx + ColW) Then Begin
     QResSelCol := I; Break;
    End;
    Cx := Cx + ColW;
   End;
  End;
  NeedFullRedraw := True;
 End;
End;

Procedure ActionNewForm;
Var Frm: PForm; N, SrcTbl: Integer;
Begin
 If DB.TblCount < 1 Then Begin
  MessageBox('Erreur', 'Aucune table : creez d''abord une table.'); Exit;
 End;
 If DB.FrmCount >= MAX_FORMS Then Begin
  MessageBox('Erreur', 'Nombre maximum de formulaires atteint.'); Exit;
 End;
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) Then SrcTbl := CurTblIdx
 Else If (CurObjType = OBJ_TABLE) And (NavSelObj >= 1) And (NavSelObj <= DB.TblCount) Then SrcTbl := NavSelObj
 Else SrcTbl := 1;
 GetMem(Frm, SizeOf(TForm));
 FillChar(Frm^, SizeOf(TForm), 0);
 N := DB.FrmCount + 1;
 Frm^.Name      := 'Formulaire' + IntToStr(N);
 Frm^.SrcTable  := SrcTbl;
 Frm^.CtrlCount := 0;
 Inc(DB.FrmCount);
 DB.Forms[DB.FrmCount] := Frm;
 CurFrmIdx := DB.FrmCount;
 CurTblIdx := SrcTbl;
 CurFldIdx := 1;
 CurRecIdx := 1;
 If DB.Tables[SrcTbl]^.RecCount < 1 Then CurRecIdx := 0;
 FormScroll := 1;
 CurObjType := OBJ_FORM;
 CurView := VIEW_FORM;
 DB.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure HandleFormClick;
Var T: PTable; F: PField; I, Y, BX1, BY1, BX2, BY2: Integer;
    EX1, EY1, EX2, EY2: Integer;
    Cur, V: String;
Begin
 If (CurFrmIdx < 1) Or (CurFrmIdx > DB.FrmCount) Then Exit;
 FormBindTable;
 If (CurTblIdx < 1) Or (CurTblIdx > DB.TblCount) Then Exit;
 T := DB.Tables[CurTblIdx];
 FormComputeLayout(T);
 { Boutons }
 For I := 1 To 6 Do Begin
  FormGetNavBtnRect(I, BX1, BY1, BX2, BY2);
  If InRect(Mouse.X, Mouse.Y, BX1, BY1, BX2, BY2) Then Begin
   If EditMode Then CommitEdit;
   Case I Of
    1: ActionFirstRec;
    2: ActionPrevRec;
    3: ActionNextRec;
    4: ActionLastRec;
    5: ActionNewRec;
    6: ActionDelRec;
   End;
   NeedFullRedraw := True;
   Exit;
  End;
 End;
 { Champs }
 If T^.FldCount < 1 Then Exit;
 For I := FormScroll To FormScroll + FormVisFlds - 1 Do Begin
  If I > T^.FldCount Then Break;
  Y := FormFieldRowY(I);
  F := @T^.Fields[I];
  If F^.FType = FT_BOOL Then Begin
   EX1 := FormEditX - 2;
   EY1 := Y + (FormFldH - 12) Div 2 - 2;
   EX2 := FormEditX + 13;
   EY2 := Y + (FormFldH - 12) Div 2 + 13;
   If InRect(Mouse.X, Mouse.Y, EX1, EY1, EX2, EY2) Then Begin
    If EditMode Then CommitEdit;
    CurFldIdx := I;
    If (CurRecIdx >= 1) And (CurRecIdx <= T^.RecCount) Then Begin
     Cur := T^.Records[CurRecIdx]^.Values[I];
     If (Cur = 'T') Or (Cur = '1') Or (Cur = 'Oui') Or (Cur = 'Yes') Or (Cur = 'True') Then V := 'F'
     Else V := 'T';
     T^.Records[CurRecIdx]^.Values[I] := V;
     T^.Dirty := True; DB.Dirty := True;
    End;
    NeedFullRedraw := True;
    Exit;
   End;
  End
  Else Begin
   EX1 := FormEditX;
   EY1 := Y + 2;
   EX2 := FormEditX2;
   EY2 := Y + FormFldH - 4;
   If InRect(Mouse.X, Mouse.Y, EX1, EY1, EX2, EY2) Then Begin
    If EditMode Then CommitEdit;
    CurFldIdx := I;
    If (CurRecIdx >= 1) And (CurRecIdx <= T^.RecCount) And
       (F^.FType <> FT_AUTONUM) Then BeginEdit;
    NeedFullRedraw := True;
    Exit;
   End;
  End;
 End;
 { Clic ailleurs : sortir d'edit }
 If EditMode Then Begin
  CommitEdit; NeedFullRedraw := True;
 End;
End;

Procedure ActionNewReport;
Var Rpt: PReport; N, SrcTbl: Integer;
Begin
 If DB.TblCount < 1 Then Begin
  MessageBox('Erreur', 'Aucune table : creez d''abord une table.'); Exit;
 End;
 If DB.RptCount >= MAX_REPORTS Then Begin
  MessageBox('Erreur', 'Nombre maximum d''etats atteint.'); Exit;
 End;
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) Then SrcTbl := CurTblIdx
 Else If (CurObjType = OBJ_TABLE) And (NavSelObj >= 1) And (NavSelObj <= DB.TblCount) Then SrcTbl := NavSelObj
 Else SrcTbl := 1;
 GetMem(Rpt, SizeOf(TReport));
 FillChar(Rpt^, SizeOf(TReport), 0);
 N := DB.RptCount + 1;
 Rpt^.Name     := 'Etat' + IntToStr(N);
 Rpt^.SrcTable := SrcTbl;
 Inc(DB.RptCount);
 DB.Reports[DB.RptCount] := Rpt;
 CurRptIdx := DB.RptCount;
 CurTblIdx := SrcTbl;
 RptPage   := 1;
 CurObjType := OBJ_REPORT;
 CurView := VIEW_REPORT;
 DB.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure ActionRptPrev;
Begin
 If RptPage > 1 Then Begin Dec(RptPage); NeedFullRedraw := True; End;
End;

Procedure ActionRptNext;
Begin
 If RptPage < RptPageCount Then Begin Inc(RptPage); NeedFullRedraw := True; End;
End;

Procedure ActionRptFirst;
Begin
 If RptPage <> 1 Then Begin RptPage := 1; NeedFullRedraw := True; End;
End;

Procedure ActionRptLast;
Begin
 If RptPage <> RptPageCount Then Begin RptPage := RptPageCount; NeedFullRedraw := True; End;
End;

Procedure HandleReportClick;
Var I, BX1, BY1, BX2, BY2: Integer;
Begin
 For I := 1 To 4 Do Begin
  RptGetBtnRect(I, BX1, BY1, BX2, BY2);
  If InRect(Mouse.X, Mouse.Y, BX1, BY1, BX2, BY2) Then Begin
   Case I Of
    1: ActionRptFirst;
    2: ActionRptPrev;
    3: ActionRptNext;
    4: ActionRptLast;
   End;
   Exit;
  End;
 End;
End;

{ ====================================================================== }
{                       ACTIONS - RELATIONS                              }
{ ====================================================================== }

Procedure ActionRelEdit;
Begin
 If DB.TblCount < 1 Then Begin
  MessageBox('Relations', 'Aucune table : creez d''abord une table.');
  Exit;
 End;
 RelSelIdx  := 0;
 RelDragTbl := 0;
 If Not RelLayoutDone Then RelInitLayout;
 CurView := VIEW_RELATIONS;
 NeedFullRedraw := True;
End;

Procedure ActionRelReorganize;
Begin
 RelLayoutDone := False;
 RelInitLayout;
 NeedFullRedraw := True;
End;

Procedure RelCycleField(Var FieldVal: Integer; LimitMax: Integer; Delta: Integer);
Begin
 If LimitMax < 1 Then Begin FieldVal := 0; Exit; End;
 FieldVal := FieldVal + Delta;
 If FieldVal < 1 Then FieldVal := LimitMax;
 If FieldVal > LimitMax Then FieldVal := 1;
End;

Procedure DrawAddRelDlg(T1, F1, T2, F2, Foc: Integer;
                        Enf, Cu, Cd: Boolean;
                        X1, Y1, X2, Y2: Integer);
Var Lx, Vx, Vx2, Y, RowH: Integer; S: String;
Begin
 DlgFrame(X1, Y1, X2, Y2, 'Ajouter une relation');
 HideMouse;
 Lx := X1 + 14;
 Vx := X1 + 110;
 Vx2 := X2 - 14;
 RowH := 22;
 Y := Y1 + 28;

 DlgLabel(Lx, Y + 4, 'Table 1 :');
 If (T1 >= 1) And (T1 <= DB.TblCount) And (DB.Tables[T1] <> Nil)
  Then S := DB.Tables[T1]^.Name Else S := '(aucune)';
 DlgEdit(Vx, Y, Vx2, Y + 15, S, Foc = 0, 0);
 Inc(Y, RowH);

 DlgLabel(Lx, Y + 4, 'Champ 1 :');
 If (T1 >= 1) And (T1 <= DB.TblCount) And (DB.Tables[T1] <> Nil) And
    (F1 >= 1) And (F1 <= DB.Tables[T1]^.FldCount)
  Then S := DB.Tables[T1]^.Fields[F1].Name Else S := '(aucun)';
 DlgEdit(Vx, Y, Vx2, Y + 15, S, Foc = 1, 0);
 Inc(Y, RowH);

 DlgLabel(Lx, Y + 4, 'Table 2 :');
 If (T2 >= 1) And (T2 <= DB.TblCount) And (DB.Tables[T2] <> Nil)
  Then S := DB.Tables[T2]^.Name Else S := '(aucune)';
 DlgEdit(Vx, Y, Vx2, Y + 15, S, Foc = 2, 0);
 Inc(Y, RowH);

 DlgLabel(Lx, Y + 4, 'Champ 2 :');
 If (T2 >= 1) And (T2 <= DB.TblCount) And (DB.Tables[T2] <> Nil) And
    (F2 >= 1) And (F2 <= DB.Tables[T2]^.FldCount)
  Then S := DB.Tables[T2]^.Fields[F2].Name Else S := '(aucun)';
 DlgEdit(Vx, Y, Vx2, Y + 15, S, Foc = 3, 0);
 Inc(Y, RowH + 4);

 DlgCheck(Lx, Y,      'Appliquer l''integrite referentielle', Enf);
 If Foc = 4 Then Begin SetColor(CLR_BLACK); Rectangle(Lx-2, Y-2, Lx+260, Y+12); End;
 Inc(Y, 16);
 DlgCheck(Lx, Y,      'Mettre a jour en cascade les enregistrements', Cu);
 If Foc = 5 Then Begin SetColor(CLR_BLACK); Rectangle(Lx-2, Y-2, Lx+260, Y+12); End;
 Inc(Y, 16);
 DlgCheck(Lx, Y,      'Effacer en cascade les enregistrements', Cd);
 If Foc = 6 Then Begin SetColor(CLR_BLACK); Rectangle(Lx-2, Y-2, Lx+260, Y+12); End;

 { Boutons }
 DlgBtn(X2 - 170, Y2 - 28, X2 - 100, Y2 - 8, 'OK',     False, Foc = 7);
 DlgBtn(X2 -  90, Y2 - 28, X2 -  20, Y2 - 8, 'Annuler', False, Foc = 8);

 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 14, Y2 - 26,
           'Tab=Suivant  Left/Right=Modifier  Espace=Cocher');
 ShowMouse;
End;

Procedure ActionNewRelation;
Var X1, Y1, X2, Y2: Integer;
    T1, F1, T2, F2, Foc, I, RealMax: Integer;
    Enf, Cu, Cd, Done, Confirm: Boolean;
    K, K2: Char;
    R: PRelation;
Begin
 If DB.TblCount < 2 Then Begin
  MessageBox('Relations',
             'Au moins deux tables sont requises pour creer une relation.');
  Exit;
 End;
 If DB.RelCount >= MAX_RELATIONS Then Begin
  MessageBox('Relations', 'Nombre maximum de relations atteint.');
  Exit;
 End;
 X1 := 100; Y1 := 100; X2 := 540; Y2 := 340;
 T1 := 1; T2 := 2; F1 := 1; F2 := 1;
 If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) Then T1 := CurTblIdx;
 If T2 = T1 Then T2 := T1 + 1;
 If T2 > DB.TblCount Then T2 := 1;
 Foc := 0;
 Enf := True; Cu := False; Cd := False; Confirm := False;
 Done := False;
 DrawAddRelDlg(T1, F1, T2, F2, Foc, Enf, Cu, Cd, X1, Y1, X2, Y2);
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey; K2 := #0;
   If K = #0 Then K2 := ReadKey;
   If K = #27 Then Begin Done := True; Confirm := False; End
   Else If K = #13 Then Begin
    If Foc = 8 Then Begin Done := True; Confirm := False; End
    Else Begin Done := True; Confirm := True; End;
   End
   Else If K = #9 Then Foc := (Foc + 1) Mod 9
   Else If K = ' ' Then Begin
    Case Foc Of
     4: Enf := Not Enf;
     5: Cu  := Not Cu;
     6: Cd  := Not Cd;
     7: Begin Done := True; Confirm := True; End;
     8: Begin Done := True; Confirm := False; End;
    End;
   End
   Else If K = #0 Then Begin
    Case K2 Of
     #15 : Begin { Shift+Tab }
            If Foc = 0 Then Foc := 8 Else Dec(Foc);
           End;
     #75 : Begin { Left }
            Case Foc Of
             0: Begin RelCycleField(T1, DB.TblCount, -1);
                      If T1 = T2 Then RelCycleField(T1, DB.TblCount, -1);
                      F1 := 1; End;
             1: If (T1 >= 1) And (T1 <= DB.TblCount) Then
                 RelCycleField(F1, DB.Tables[T1]^.FldCount, -1);
             2: Begin RelCycleField(T2, DB.TblCount, -1);
                      If T2 = T1 Then RelCycleField(T2, DB.TblCount, -1);
                      F2 := 1; End;
             3: If (T2 >= 1) And (T2 <= DB.TblCount) Then
                 RelCycleField(F2, DB.Tables[T2]^.FldCount, -1);
            End;
           End;
     #77 : Begin { Right }
            Case Foc Of
             0: Begin RelCycleField(T1, DB.TblCount, 1);
                      If T1 = T2 Then RelCycleField(T1, DB.TblCount, 1);
                      F1 := 1; End;
             1: If (T1 >= 1) And (T1 <= DB.TblCount) Then
                 RelCycleField(F1, DB.Tables[T1]^.FldCount, 1);
             2: Begin RelCycleField(T2, DB.TblCount, 1);
                      If T2 = T1 Then RelCycleField(T2, DB.TblCount, 1);
                      F2 := 1; End;
             3: If (T2 >= 1) And (T2 <= DB.TblCount) Then
                 RelCycleField(F2, DB.Tables[T2]^.FldCount, 1);
            End;
           End;
     #72 : If Foc > 0 Then Dec(Foc);   { Up }
     #80 : If Foc < 8 Then Inc(Foc);   { Down }
    End;
   End;
   DrawAddRelDlg(T1, F1, T2, F2, Foc, Enf, Cu, Cd, X1, Y1, X2, Y2);
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, X2 - 170, Y2 - 28, X2 - 100, Y2 - 8) Then Begin
    Done := True; Confirm := True;
   End Else If InRect(Mouse.X, Mouse.Y, X2 - 90, Y2 - 28, X2 - 20, Y2 - 8) Then Begin
    Done := True; Confirm := False;
   End;
  End;
 Until Done;
 NeedFullRedraw := True;
 If Not Confirm Then Exit;
 If (T1 < 1) Or (T1 > DB.TblCount) Or (T2 < 1) Or (T2 > DB.TblCount) Or
    (T1 = T2) Then Begin
  MessageBox('Relations', 'Tables invalides.'); Exit;
 End;
 If (F1 < 1) Or (F1 > DB.Tables[T1]^.FldCount) Or
    (F2 < 1) Or (F2 > DB.Tables[T2]^.FldCount) Then Begin
  MessageBox('Relations', 'Champs invalides.'); Exit;
 End;
 { Doublon ? }
 For I := 1 To DB.RelCount Do
  If (DB.Relations[I] <> Nil) And
     (DB.Relations[I]^.TblFromIdx = T1) And
     (DB.Relations[I]^.FldFromIdx = F1) And
     (DB.Relations[I]^.TblToIdx   = T2) And
     (DB.Relations[I]^.FldToIdx   = F2) Then Begin
   MessageBox('Relations', 'Cette relation existe deja.'); Exit;
  End;
 GetMem(R, SizeOf(TRelation));
 FillChar(R^, SizeOf(TRelation), 0);
 RealMax := DB.RelCount + 1;
 R^.Name       := 'Rel' + IntToStr(RealMax);
 R^.TblFromIdx := T1;
 R^.FldFromIdx := F1;
 R^.TblToIdx   := T2;
 R^.FldToIdx   := F2;
 R^.Enforce    := Enf;
 R^.CascadeUpd := Cu;
 R^.CascadeDel := Cd;
 Inc(DB.RelCount);
 DB.Relations[DB.RelCount] := R;
 RelSelIdx := DB.RelCount;
 DB.Dirty  := True;
End;

Procedure ActionDelRelation;
Var I: Integer;
Begin
 If (RelSelIdx < 1) Or (RelSelIdx > DB.RelCount) Then Begin
  MessageBox('Relations', 'Aucune relation selectionnee.'); Exit;
 End;
 If DB.Relations[RelSelIdx] <> Nil Then
  FreeMem(DB.Relations[RelSelIdx], SizeOf(TRelation));
 For I := RelSelIdx To DB.RelCount - 1 Do
  DB.Relations[I] := DB.Relations[I + 1];
 DB.Relations[DB.RelCount] := Nil;
 Dec(DB.RelCount);
 RelSelIdx := 0;
 DB.Dirty  := True;
 NeedFullRedraw := True;
End;

Procedure HandleRelationsClick;
Var I, BX1, BY1, BX2, BY2, Hit, Tbl: Integer;
Begin
 { Boutons en bas }
 For I := 1 To 4 Do Begin
  RelGetBtnRect(I, BX1, BY1, BX2, BY2);
  If InRect(Mouse.X, Mouse.Y, BX1, BY1, BX2, BY2) Then Begin
   Case I Of
    1: ActionNewRelation;
    2: ActionDelRelation;
    3: ActionRelReorganize;
    4: Begin CurView := VIEW_NAV; NeedFullRedraw := True; End;
   End;
   Exit;
  End;
 End;
 { Selection d'une relation ? }
 Hit := RelHitTest(Mouse.X, Mouse.Y);
 If Hit > 0 Then Begin
  RelSelIdx := Hit;
  NeedFullRedraw := True;
  Exit;
 End;
 { Drag table ? }
 Tbl := RelTableAt(Mouse.X, Mouse.Y);
 If Tbl > 0 Then Begin
  RelDragTbl := Tbl;
  RelDragDX  := Mouse.X - RelBoxX[Tbl];
  RelDragDY  := Mouse.Y - RelBoxY[Tbl];
  RelSelIdx  := 0;
  NeedFullRedraw := True;
 End Else Begin
  If RelSelIdx <> 0 Then Begin
   RelSelIdx := 0; NeedFullRedraw := True;
  End;
 End;
End;

Procedure HandleRelationsDrag;
Var NewX, NewY: Integer;
Begin
 If RelDragTbl = 0 Then Exit;
 If Not LeftDown Then Begin RelDragTbl := 0; Exit; End;
 NewX := Mouse.X - RelDragDX;
 NewY := Mouse.Y - RelDragDY;
 If NewX < 4 Then NewX := 4;
 If NewY < RelArea1 + 4 Then NewY := RelArea1 + 4;
 If NewX + RelBoxW[RelDragTbl] > SCREEN_W - 4 Then
  NewX := SCREEN_W - 4 - RelBoxW[RelDragTbl];
 If NewY + RelBoxH[RelDragTbl] > RelArea2 - 4 Then
  NewY := RelArea2 - 4 - RelBoxH[RelDragTbl];
 If (NewX <> RelBoxX[RelDragTbl]) Or (NewY <> RelBoxY[RelDragTbl]) Then Begin
  RelBoxX[RelDragTbl] := NewX;
  RelBoxY[RelDragTbl] := NewY;
  NeedFullRedraw := True;
 End;
End;

{ ====================================================================== }
{                       DIALOGUE FICHIER (style VS)                      }
{ ====================================================================== }

Const
 MAX_FDLG_FILES = 200;
 FDLG_ROWS      = 14;

Var
 FdlgFiles   : Array[1..MAX_FDLG_FILES] Of String[64];
 FdlgIsDir   : Array[1..MAX_FDLG_FILES] Of Boolean;
 FdlgCount   : Integer;
 FdlgScroll  : Integer;
 FdlgSel     : Integer;
 FdlgCurDir  : String[120];

Procedure FdlgEnsureVisible;
Begin
 If FdlgSel < 1 Then FdlgSel := 1;
 If FdlgSel > FdlgCount Then FdlgSel := FdlgCount;
 If FdlgSel < FdlgScroll Then FdlgScroll := FdlgSel;
 If FdlgSel >= FdlgScroll + FDLG_ROWS Then
  FdlgScroll := FdlgSel - FDLG_ROWS + 1;
 If FdlgScroll < 1 Then FdlgScroll := 1;
End;

Procedure FdlgAdd(Const Name: String; IsDir: Boolean);
Begin
 If FdlgCount >= MAX_FDLG_FILES Then Exit;
 Inc(FdlgCount);
 FdlgFiles[FdlgCount] := Name;
 FdlgIsDir[FdlgCount] := IsDir;
End;

Procedure FdlgScan(Const Filter: String);
Var Sr: SearchRec; P: Integer; Pat, S: String;
Begin
 FdlgCount  := 0;
 FdlgScroll := 1;
 FdlgSel    := 1;
 GetDir(0, FdlgCurDir);
 { Repertoires d'abord }
 FindFirst('*.*', Directory, Sr);
 While DosError = 0 Do Begin
  If ((Sr.Attr And Directory) <> 0) And (Sr.Name <> '.') Then
   FdlgAdd(Sr.Name, True);
  FindNext(Sr);
 End;
 FindClose(Sr);
 { Fichiers selon filtre }
 S := Filter;
 If S = '' Then S := '*.*';
 While S <> '' Do Begin
  P := Pos(';', S);
  If P > 0 Then Begin Pat := Copy(S, 1, P - 1); Delete(S, 1, P); End
  Else Begin Pat := S; S := ''; End;
  If Pat = '' Then Continue;
  FindFirst(Pat, AnyFile - Directory - VolumeId, Sr);
  While DosError = 0 Do Begin
   If (Sr.Attr And Directory) = 0 Then FdlgAdd(Sr.Name, False);
   FindNext(Sr);
  End;
  FindClose(Sr);
 End;
End;

Procedure FdlgDraw(Const Title: String; Const FName: String; Focus: Integer);
Const X1 = 90; Y1 = 60; X2 = 550; Y2 = 420;
Var Lx1, Ly1, Lx2, Ly2, I, Idx, Vy, By, Cw: Integer; S: String;
Begin
 DlgFrame(X1, Y1, X2, Y2, Title);
 HideMouse;
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 12, Y1 + 24, 'Chemin :');
 S := FdlgCurDir;
 If Length(S) > 60 Then S := '...' + Copy(S, Length(S) - 56, 57);
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 72, Y1 + 24, S);
 { Liste }
 Lx1 := X1 + 12; Ly1 := Y1 + 42;
 Lx2 := X2 - 28; Ly2 := Y2 - 72;
 FillBox(Lx1, Ly1, Lx2, Ly2, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(Lx1, Ly1, Lx2, Ly2);
 If Focus = 0 Then Begin
  SetColor(CLR_BLACK); Rectangle(Lx1 - 1, Ly1 - 1, Lx2 + 1, Ly2 + 1);
 End;
 For I := 0 To FDLG_ROWS - 1 Do Begin
  Idx := FdlgScroll + I;
  If Idx > FdlgCount Then Break;
  Vy := Ly1 + 2 + I * 12;
  If Idx = FdlgSel Then Begin
   FillBox(Lx1 + 1, Vy, Lx2 - 1, Vy + 11, CLR_BLUE);
   SetColor(CLR_WHITE);
  End Else SetColor(CLR_BLACK);
  If FdlgIsDir[Idx] Then S := '[' + FdlgFiles[Idx] + ']'
  Else S := FdlgFiles[Idx];
  If Length(S) > 50 Then S := Copy(S, 1, 47) + '...';
  OutTextXY(Lx1 + 6, Vy + 2, S);
 End;
 { Scrollbar marker }
 If FdlgCount > FDLG_ROWS Then Begin
  Vy := Ly1 + ((Ly2 - Ly1 - 12) * (FdlgScroll - 1)) Div
        (FdlgCount - FDLG_ROWS + 1);
  FillBox(Lx2 + 2, Ly1, Lx2 + 12, Ly2, CLR_LGRAY);
  DrawRaised(Lx2 + 3, Vy, Lx2 + 11, Vy + 12, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 End;
 { Edit }
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 12, Y2 - 60, 'Fichier :');
 Cw := Length(FName);
 DlgEdit(X1 + 78, Y2 - 64, X2 - 12, Y2 - 48, FName, Focus = 1, Cw);
 { Boutons }
 By := Y2 - 36;
 DlgBtn(X2 - 174, By, X2 - 100, By + 20, 'OK',      False, Focus = 2);
 DlgBtn(X2 -  90, By, X2 -  16, By + 20, 'Annuler', False, Focus = 3);
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 12, Y2 - 14,
           'Enter=Ouvrir  Tab=Focus  Esc=Annuler');
 ShowMouse;
End;

Function FdlgRowAt(MX, MY: Integer; Var RowIdx: Integer): Boolean;
Const X1 = 90; Y1 = 60; X2 = 550; Y2 = 420;
Var Lx1, Ly1, Lx2, Ly2, I: Integer;
Begin
 FdlgRowAt := False;
 Lx1 := X1 + 12; Ly1 := Y1 + 42;
 Lx2 := X2 - 28; Ly2 := Y2 - 72;
 If Not InRect(MX, MY, Lx1, Ly1, Lx2, Ly2) Then Exit;
 I := (MY - Ly1 - 2) Div 12;
 If (I < 0) Or (I >= FDLG_ROWS) Then Exit;
 RowIdx := FdlgScroll + I;
 If (RowIdx < 1) Or (RowIdx > FdlgCount) Then Exit;
 FdlgRowAt := True;
End;

Function ShowFileDialog(Const Title: String; Var FName: String;
                         SaveMode: Boolean; Const FilterExt: String): Boolean;
Var Filter, Sel: String;
    Focus: Integer; Done, Confirm: Boolean;
    K, K2: Char; RowIdx: Integer; Last: LongInt; Now: LongInt;
    P: Integer; OldDir: String[120]; Ext: String;
Begin
 ShowFileDialog := False;
 { Construit le filtre : ext sont les extensions sans point separees par , }
 Filter := '';
 If FilterExt = '*' Then Filter := '*.*'
 Else Begin
  Sel := FilterExt;
  While Sel <> '' Do Begin
   P := Pos(',', Sel);
   If P > 0 Then Begin Ext := Copy(Sel, 1, P - 1); Delete(Sel, 1, P); End
   Else Begin Ext := Sel; Sel := ''; End;
   If Ext <> '' Then Begin
    If Filter <> '' Then Filter := Filter + ';';
    Filter := Filter + '*.' + Ext;
   End;
  End;
  If Filter = '' Then Filter := '*.*';
 End;
 GetDir(0, OldDir);
 FdlgScan(Filter);
 If SaveMode Then Focus := 1 Else Focus := 0;
 Last := 0;
 FdlgDraw(Title, FName, Focus);
 Done := False; Confirm := False;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey; K2 := #0;
   If K = #0 Then K2 := ReadKey;
   If K = #27 Then Begin Done := True; Confirm := False; End
   Else If K = #9 Then Focus := (Focus + 1) Mod 4
   Else If K = #13 Then Begin
    If Focus = 3 Then Begin Done := True; Confirm := False; End
    Else If Focus = 0 Then Begin
     If (FdlgSel >= 1) And (FdlgSel <= FdlgCount) Then Begin
      If FdlgIsDir[FdlgSel] Then Begin
       {$I-} ChDir(FdlgFiles[FdlgSel]); {$I+}
       If IOResult = 0 Then FdlgScan(Filter);
      End Else Begin
       FName := FdlgFiles[FdlgSel];
       Done := True; Confirm := True;
      End;
     End;
    End Else Begin
     If FName <> '' Then Begin Done := True; Confirm := True; End;
    End;
   End
   Else If K = #8 Then Begin
    If Focus = 1 Then
     If Length(FName) > 0 Then Delete(FName, Length(FName), 1);
   End
   Else If K = #0 Then Begin
    Case K2 Of
     #72 : If (Focus = 0) And (FdlgSel > 1) Then Begin
            Dec(FdlgSel); FdlgEnsureVisible;
            If Not FdlgIsDir[FdlgSel] Then FName := FdlgFiles[FdlgSel];
           End;
     #80 : If (Focus = 0) And (FdlgSel < FdlgCount) Then Begin
            Inc(FdlgSel); FdlgEnsureVisible;
            If Not FdlgIsDir[FdlgSel] Then FName := FdlgFiles[FdlgSel];
           End;
     #73 : If Focus = 0 Then Begin
            Dec(FdlgSel, FDLG_ROWS); FdlgEnsureVisible;
            If (FdlgSel >= 1) And Not FdlgIsDir[FdlgSel] Then
             FName := FdlgFiles[FdlgSel];
           End;
     #81 : If Focus = 0 Then Begin
            Inc(FdlgSel, FDLG_ROWS); FdlgEnsureVisible;
            If (FdlgSel >= 1) And (FdlgSel <= FdlgCount) And
               Not FdlgIsDir[FdlgSel] Then FName := FdlgFiles[FdlgSel];
           End;
     #71 : If Focus = 0 Then Begin FdlgSel := 1; FdlgEnsureVisible; End;
     #79 : If Focus = 0 Then Begin FdlgSel := FdlgCount; FdlgEnsureVisible; End;
     #83 : If Focus = 1 Then
            If Length(FName) > 0 Then Delete(FName, Length(FName), 1);
    End;
   End
   Else If (Focus = 1) And (K >= ' ') And (K <= #126) Then Begin
    If Length(FName) < 60 Then FName := FName + K;
   End;
   FdlgDraw(Title, FName, Focus);
  End;
  If LeftPressed Then Begin
   { Boutons }
   If InRect(Mouse.X, Mouse.Y, 550 - 174, 420 - 36, 550 - 100, 420 - 16) Then Begin
    Done := True; Confirm := True;
   End Else If InRect(Mouse.X, Mouse.Y, 550 - 90, 420 - 36, 550 - 16, 420 - 16) Then Begin
    Done := True; Confirm := False;
   End Else If FdlgRowAt(Mouse.X, Mouse.Y, RowIdx) Then Begin
    Focus := 0;
    { Double-clic ? }
    Now := TickCount;
    If (RowIdx = FdlgSel) And ((Now - Last) < 14) Then Begin
     If FdlgIsDir[RowIdx] Then Begin
      {$I-} ChDir(FdlgFiles[RowIdx]); {$I+}
      If IOResult = 0 Then FdlgScan(Filter);
     End Else Begin
      FName := FdlgFiles[RowIdx];
      Done := True; Confirm := True;
     End;
    End Else Begin
     FdlgSel := RowIdx;
     If Not FdlgIsDir[RowIdx] Then FName := FdlgFiles[RowIdx];
    End;
    Last := Now;
   End Else If InRect(Mouse.X, Mouse.Y, 90 + 78, 420 - 64,
                       550 - 12, 420 - 48) Then Focus := 1;
   FdlgDraw(Title, FName, Focus);
   { Anti-rebond }
   While LeftDown Do UpdateMouse;
  End;
  Delay(15);
 Until Done;
 If Confirm Then Begin
  GetDir(0, FdlgCurDir);
  If Pos(':', FName) = 0 Then Begin
   If (Length(FdlgCurDir) > 0) And
      (FdlgCurDir[Length(FdlgCurDir)] <> '\') And
      (FdlgCurDir[Length(FdlgCurDir)] <> '/') Then
    FName := FdlgCurDir + '\' + FName
   Else
    FName := FdlgCurDir + FName;
  End;
 End;
 {$I-} ChDir(OldDir); {$I+}
 If IOResult <> 0 Then ;
 NeedFullRedraw := True;
 ShowFileDialog := Confirm;
End;

{ ====================================================================== }
{                       CSV                                              }
{ ====================================================================== }

Function CsvQuoteIfNeeded(Const S: String): String;
Var I: Integer; NeedQ: Boolean; R: String;
Begin
 NeedQ := False;
 For I := 1 To Length(S) Do
  If (S[I] = ',') Or (S[I] = '"') Or (S[I] = #10) Or (S[I] = #13) Then Begin
   NeedQ := True; Break;
  End;
 If Not NeedQ Then Begin CsvQuoteIfNeeded := S; Exit; End;
 R := '"';
 For I := 1 To Length(S) Do Begin
  If S[I] = '"' Then R := R + '""'
  Else R := R + S[I];
 End;
 R := R + '"';
 CsvQuoteIfNeeded := R;
End;

Function CsvParseLine(Const Line: String; Var Cells: Array Of String;
                      MaxCells: Integer): Integer;
Var I, N: Integer; Cur: String; InQ: Boolean; C: Char;
Begin
 N := 0; Cur := ''; InQ := False; I := 1;
 While I <= Length(Line) Do Begin
  C := Line[I];
  If InQ Then Begin
   If C = '"' Then Begin
    If (I < Length(Line)) And (Line[I + 1] = '"') Then Begin
     Cur := Cur + '"'; Inc(I, 2); Continue;
    End Else Begin
     InQ := False; Inc(I); Continue;
    End;
   End Else Begin
    Cur := Cur + C; Inc(I); Continue;
   End;
  End Else Begin
   If C = '"' Then Begin InQ := True; Inc(I); Continue; End;
   If C = ',' Then Begin
    If N < MaxCells Then Begin Cells[N] := Cur; Inc(N); End;
    Cur := ''; Inc(I); Continue;
   End;
   Cur := Cur + C; Inc(I);
  End;
 End;
 If N < MaxCells Then Begin Cells[N] := Cur; Inc(N); End;
 CsvParseLine := N;
End;

Procedure ActionImportCsv;
Var FName, Line: String;
    F: Text;
    Cells: Array[0..MAX_FIELDS - 1] Of String;
    NCells, I, TIdx, RIdx: Integer;
    T: PTable; S: String;
Begin
 FName := '';
 If Not ShowFileDialog('Importer CSV', FName, False, 'CSV') Then Exit;
 If DB.TblCount >= MAX_TABLES Then Begin
  MessageBox('Importer', 'Limite de tables atteinte.'); Exit;
 End;
 {$I-} Assign(F, FName); Reset(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Importer', 'Impossible d''ouvrir le fichier.'); Exit;
 End;
 { Entete }
 If Eof(F) Then Begin
  Close(F); MessageBox('Importer', 'Fichier vide.'); Exit;
 End;
 ReadLn(F, Line);
 NCells := CsvParseLine(Line, Cells, MAX_FIELDS);
 If NCells < 1 Then Begin
  Close(F); MessageBox('Importer', 'En-tete invalide.'); Exit;
 End;
 { Cree la table }
 S := 'CsvImport';
 For I := 1 To 99 Do Begin
  S := 'CsvImport' + IntToStr(I);
  TIdx := 0;
  For RIdx := 1 To DB.TblCount Do
   If (DB.Tables[RIdx] <> Nil) And (DB.Tables[RIdx]^.Name = S) Then Begin
    TIdx := 1; Break;
   End;
  If TIdx = 0 Then Break;
 End;
 TIdx := NewTable(S);
 If TIdx = 0 Then Begin
  Close(F); MessageBox('Importer', 'Echec de creation de la table.'); Exit;
 End;
 T := DB.Tables[TIdx];
 For I := 0 To NCells - 1 Do Begin
  S := Cells[I];
  If S = '' Then S := 'Col' + IntToStr(I + 1);
  If Length(S) > FLD_NAME_LEN Then S := Copy(S, 1, FLD_NAME_LEN);
  AddField(TIdx, S, FT_TEXT, VAL_LEN);
 End;
 { Donnees }
 While Not Eof(F) Do Begin
  ReadLn(F, Line);
  If Line = '' Then Continue;
  If T^.RecCount >= MAX_RECORDS Then Break;
  NCells := CsvParseLine(Line, Cells, MAX_FIELDS);
  RIdx := NewRecord(TIdx);
  If RIdx = 0 Then Break;
  For I := 0 To NCells - 1 Do Begin
   If I >= T^.FldCount Then Break;
   S := Cells[I];
   If Length(S) > VAL_LEN Then S := Copy(S, 1, VAL_LEN);
   T^.Records[RIdx]^.Values[I + 1] := S;
  End;
 End;
 Close(F);
 CurTblIdx := TIdx;
 CurRecIdx := 1;
 CurFldIdx := 1;
 DB.Dirty := True;
 StatusMsg := 'Importe : ' + IntToStr(T^.RecCount) + ' enregistrement(s).';
 NeedFullRedraw := True;
End;

Procedure ActionExportCsv;
Var FName, S, Line: String;
    F: Text;
    T: PTable;
    I, J: Integer;
Begin
 T := CurTable;
 If T = Nil Then Begin
  MessageBox('Exporter', 'Aucune table active.'); Exit;
 End;
 FName := T^.Name + '.CSV';
 If Not ShowFileDialog('Exporter CSV', FName, True, 'CSV') Then Exit;
 {$I-} Assign(F, FName); Rewrite(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Exporter', 'Impossible de creer le fichier.'); Exit;
 End;
 { Entete }
 Line := '';
 For I := 1 To T^.FldCount Do Begin
  If I > 1 Then Line := Line + ',';
  Line := Line + CsvQuoteIfNeeded(T^.Fields[I].Name);
 End;
 WriteLn(F, Line);
 { Donnees }
 For J := 1 To T^.RecCount Do
  If (T^.Records[J] <> Nil) And (Not T^.Records[J]^.Deleted) Then Begin
   Line := '';
   For I := 1 To T^.FldCount Do Begin
    If I > 1 Then Line := Line + ',';
    S := T^.Records[J]^.Values[I];
    Line := Line + CsvQuoteIfNeeded(S);
   End;
   WriteLn(F, Line);
  End;
 Close(F);
 StatusMsg := 'Exporte : ' + IntToStr(T^.RecCount) + ' enregistrement(s).';
 NeedStatRedraw := True;
End;

{ ====================================================================== }
{                       IMPRESSION (vers fichier texte)                  }
{ ====================================================================== }

Function PadRight(Const S: String; W: Integer): String;
Var R: String; I, L: Integer;
Begin
 R := S; L := Length(R);
 If L > W Then R := Copy(R, 1, W)
 Else For I := L + 1 To W Do R := R + ' ';
 PadRight := R;
End;

Function MakeBar(W: Integer): String;
Var I: Integer; R: String;
Begin
 R := ''; For I := 1 To W Do R := R + '-'; MakeBar := R;
End;

Procedure PrintTableTo(Var F: Text; T: PTable);
Var Cw: Array[1..MAX_FIELDS] Of Integer;
    I, J, L, Total: Integer; Line, S: String; R: PRecord;
Begin
 If T = Nil Then Exit;
 For I := 1 To T^.FldCount Do Begin
  Cw[I] := Length(T^.Fields[I].Name);
  If Cw[I] < 4 Then Cw[I] := 4;
  For J := 1 To T^.RecCount Do
   If T^.Records[J] <> Nil Then Begin
    L := Length(T^.Records[J]^.Values[I]);
    If L > Cw[I] Then Cw[I] := L;
   End;
  If Cw[I] > 20 Then Cw[I] := 20;
 End;
 Total := 0;
 For I := 1 To T^.FldCount Do Total := Total + Cw[I] + 1;
 WriteLn(F, 'Table : ', T^.Name);
 If T^.Description <> '' Then WriteLn(F, '        ', T^.Description);
 WriteLn(F);
 Line := '';
 For I := 1 To T^.FldCount Do Line := Line + PadRight(T^.Fields[I].Name, Cw[I]) + ' ';
 WriteLn(F, Line);
 WriteLn(F, MakeBar(Total));
 For J := 1 To T^.RecCount Do Begin
  R := T^.Records[J];
  If (R = Nil) Or R^.Deleted Then Continue;
  Line := '';
  For I := 1 To T^.FldCount Do Begin
   S := R^.Values[I];
   Line := Line + PadRight(S, Cw[I]) + ' ';
  End;
  WriteLn(F, Line);
 End;
 WriteLn(F, MakeBar(Total));
 WriteLn(F, IntToStr(T^.RecCount), ' enregistrement(s).');
End;

Procedure PrintQueryTo(Var F: Text);
Var Cw: Array[1..MAX_QRES_COLS] Of Integer;
    I, J, L, Total: Integer; Line: String;
Begin
 If QResColCount = 0 Then Begin
  WriteLn(F, '(Aucun resultat de requete.)'); Exit;
 End;
 For I := 1 To QResColCount Do Begin
  Cw[I] := Length(QResColName[I]);
  If Cw[I] < 4 Then Cw[I] := 4;
  For J := 1 To QResRowCount Do Begin
   L := Length(QResRows[J, I]);
   If L > Cw[I] Then Cw[I] := L;
  End;
  If Cw[I] > 20 Then Cw[I] := 20;
 End;
 Total := 0;
 For I := 1 To QResColCount Do Total := Total + Cw[I] + 1;
 WriteLn(F, 'Resultat de requete');
 WriteLn(F);
 Line := '';
 For I := 1 To QResColCount Do Line := Line + PadRight(QResColName[I], Cw[I]) + ' ';
 WriteLn(F, Line);
 WriteLn(F, MakeBar(Total));
 For J := 1 To QResRowCount Do Begin
  Line := '';
  For I := 1 To QResColCount Do
   Line := Line + PadRight(QResRows[J, I], Cw[I]) + ' ';
  WriteLn(F, Line);
 End;
 WriteLn(F, MakeBar(Total));
 WriteLn(F, IntToStr(QResRowCount), ' ligne(s).');
End;

Procedure ActionPrint;
Var FName: String; F: Text; T: PTable; What: String;
Begin
 What := '';
 Case CurView Of
  VIEW_DSHEET, VIEW_DESIGN:
   If CurTblIdx > 0 Then Begin
    T := DB.Tables[CurTblIdx];
    If T <> Nil Then What := T^.Name;
   End;
  VIEW_QUERY:
   If QResColCount > 0 Then What := 'Requete';
  VIEW_REPORT:
   If CurRptIdx > 0 Then Begin
    If (CurTblIdx > 0) And (DB.Tables[CurTblIdx] <> Nil) Then
     What := DB.Tables[CurTblIdx]^.Name
    Else What := 'Etat';
   End;
 End;
 If What = '' Then Begin
  MessageBox('Imprimer', 'Aucune vue imprimable.'); Exit;
 End;
 FName := What + '.TXT';
 If Not ShowFileDialog('Imprimer vers fichier', FName, True, 'TXT,PRN') Then Exit;
 {$I-} Assign(F, FName); Rewrite(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Imprimer', 'Impossible de creer : ' + FName); Exit;
 End;
 WriteLn(F, '================================================================');
 WriteLn(F, 'Office-0 Access  -  Base : ', DB.Name);
 WriteLn(F, '================================================================');
 WriteLn(F);
 Case CurView Of
  VIEW_DSHEET, VIEW_DESIGN, VIEW_REPORT:
   PrintTableTo(F, DB.Tables[CurTblIdx]);
  VIEW_QUERY:
   PrintQueryTo(F);
 End;
 WriteLn(F);
 WriteLn(F, '-- Fin --');
 Close(F);
 StatusMsg := 'Imprime vers ' + FName;
 NeedStatRedraw := True;
End;

{ ====================================================================== }
{                       NOUVELLE / OUVRIR / ENREGISTRER                  }
{ ====================================================================== }

Function ExtOf(Const F: String): String;
Var I: Integer; E: String;
Begin
 E := '';
 For I := Length(F) DownTo 1 Do Begin
  If F[I] = '.' Then Begin E := Copy(F, I + 1, Length(F) - I); Break; End;
  If (F[I] = '\') Or (F[I] = '/') Or (F[I] = ':') Then Break;
 End;
 ExtOf := UpperStr(E);
End;

Function ConfirmDiscardChanges: Boolean;
Var X1, Y1, X2, Y2, Bx, By: Integer; K, K2: Char;
    Done: Boolean; Result: Boolean;
Begin
 ConfirmDiscardChanges := True;
 If Not DB.Dirty Then Exit;
 X1 := 160; Y1 := 170; X2 := 480; Y2 := 290;
 DlgFrame(X1, Y1, X2, Y2, 'Modifications non enregistrees');
 HideMouse;
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 16, Y1 + 36,
           'La base courante a ete modifiee.');
 OutTextXY(X1 + 16, Y1 + 52,
           'Voulez-vous continuer et perdre les changements ?');
 Bx := X1 + 40; By := Y2 - 32;
 DlgBtn(Bx,        By, Bx +  70, By + 20, 'Oui',     False, True);
 DlgBtn(Bx + 90,   By, Bx + 160, By + 20, 'Non',     False, False);
 DlgBtn(Bx + 180,  By, Bx + 250, By + 20, 'Annuler', False, False);
 ShowMouse;
 Result := False; Done := False;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey; K2 := #0;
   If K = #0 Then K2 := ReadKey;
   If (K = 'O') Or (K = 'o') Or (K = 'Y') Or (K = 'y') Or (K = #13) Then Begin
    Result := True; Done := True;
   End Else If (K = 'N') Or (K = 'n') Or (K = #27) Then Begin
    Result := False; Done := True;
   End;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, Bx, By, Bx + 70, By + 20) Then Begin
    Result := True; Done := True;
   End Else If InRect(Mouse.X, Mouse.Y, Bx + 90, By, Bx + 160, By + 20) Then Begin
    Result := False; Done := True;
   End Else If InRect(Mouse.X, Mouse.Y, Bx + 180, By, Bx + 250, By + 20) Then Begin
    Result := False; Done := True;
   End;
  End;
 Until Done;
 NeedFullRedraw := True;
 ConfirmDiscardChanges := Result;
End;

{ ====================================================================== }
{                       FORMAT .MDB                                      }
{ ====================================================================== }

Const
 MDB_MAGIC_1 = 'O'; MDB_MAGIC_2 = 'F'; MDB_MAGIC_3 = 'F'; MDB_MAGIC_4 = 'A';
 MDB_VERSION = 1;

Var
 MdbErr : Boolean;

Procedure MdbWrBytes(Var F: File; Var Buf; N: Word);
Begin
 If MdbErr Then Exit;
 BlockWrite(F, Buf, N);
 If IOResult <> 0 Then MdbErr := True;
End;

Procedure MdbRdBytes(Var F: File; Var Buf; N: Word);
Var Got: Word;
Begin
 If MdbErr Then Exit;
 BlockRead(F, Buf, N, Got);
 If (IOResult <> 0) Or (Got <> N) Then MdbErr := True;
End;

Procedure MdbWrByte(Var F: File; B: Byte);
Begin MdbWrBytes(F, B, 1); End;

Function MdbRdByte(Var F: File): Byte;
Var B: Byte;
Begin B := 0; MdbRdBytes(F, B, 1); MdbRdByte := B; End;

Procedure MdbWrWord(Var F: File; W: Word);
Begin MdbWrBytes(F, W, 2); End;

Function MdbRdWord(Var F: File): Word;
Var W: Word;
Begin W := 0; MdbRdBytes(F, W, 2); MdbRdWord := W; End;

Procedure MdbWrLong(Var F: File; L: LongInt);
Begin MdbWrBytes(F, L, 4); End;

Function MdbRdLong(Var F: File): LongInt;
Var L: LongInt;
Begin L := 0; MdbRdBytes(F, L, 4); MdbRdLong := L; End;

{ Slot longueur fixe : 1 octet de longueur + MaxLen octets de donnees. }
Procedure MdbWrStr(Var F: File; Const S: String; MaxLen: Byte);
Var L: Byte; Buf: Array[0..255] Of Byte; I: Integer;
Begin
 If MdbErr Then Exit;
 L := Length(S); If L > MaxLen Then L := MaxLen;
 Buf[0] := L;
 For I := 1 To MaxLen Do
  If I <= L Then Buf[I] := Ord(S[I]) Else Buf[I] := 0;
 MdbWrBytes(F, Buf, MaxLen + 1);
End;

Function MdbRdStr(Var F: File; MaxLen: Byte): String;
Var L: Byte; Buf: Array[0..255] Of Byte; I: Integer; S: String;
Begin
 MdbRdStr := '';
 If MdbErr Then Exit;
 FillChar(Buf, SizeOf(Buf), 0);
 MdbRdBytes(F, Buf, MaxLen + 1);
 If MdbErr Then Exit;
 L := Buf[0];
 If L > MaxLen Then L := MaxLen;
 S := '';
 For I := 1 To L Do S := S + Chr(Buf[I]);
 MdbRdStr := S;
End;

Function LoadMdb(Const FName: String): Boolean; Forward;
Function LoadSql(Const FName: String): Boolean; Forward;
Function SaveMdb(Const FName: String): Boolean; Forward;
Function SaveSql(Const FName: String): Boolean; Forward;

Function LoadMdb(Const FName: String): Boolean;
Var F: File; Hdr: Array[1..4] Of Char; Ver, Flags, TC, RC: Word;
    I, J, K, FC, NumNonNil: Integer;
    RecN, AutoN: LongInt;
    T: PTable; Fld: PField; R: PRecord; Rel: PRelation;
    Del: Byte; TIdx, RIdx, RelIdx: Integer;
Begin
 LoadMdb := False;
 MdbErr := False;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Ouvrir', 'Impossible d''ouvrir : ' + FName); Exit;
 End;
 MdbRdBytes(F, Hdr, 4);
 If MdbErr Or (Hdr[1] <> MDB_MAGIC_1) Or (Hdr[2] <> MDB_MAGIC_2) Or
    (Hdr[3] <> MDB_MAGIC_3) Or (Hdr[4] <> MDB_MAGIC_4) Then Begin
  Close(F);
  MessageBox('Ouvrir', 'Format MDB non reconnu (magic).'); Exit;
 End;
 Ver   := MdbRdWord(F);
 Flags := MdbRdWord(F);
 If Ver > MDB_VERSION Then Begin
  Close(F);
  MessageBox('Ouvrir', 'Version MDB non supportee : ' + IntToStr(Ver));
  Exit;
 End;
 If Flags = 0 Then ;
 { Meta DB }
 DB.Name     := MdbRdStr(F, 40);
 DB.Title    := MdbRdStr(F, 60);
 DB.Author   := MdbRdStr(F, 40);
 DB.Company  := MdbRdStr(F, 60);
 DB.Comments := MdbRdStr(F, 120);
 TC := MdbRdWord(F);
 RC := MdbRdWord(F);
 If MdbErr Then Begin Close(F); MessageBox('Ouvrir', 'Fichier MDB tronque.'); Exit; End;
 { Tables }
 For I := 1 To TC Do Begin
  If I > MAX_TABLES Then Break;
  TIdx := NewTable(MdbRdStr(F, 32));
  If TIdx = 0 Then Begin
   MdbErr := True; Break;
  End;
  T := DB.Tables[TIdx];
  T^.Description := MdbRdStr(F, 64);
  FC := MdbRdWord(F);
  RecN  := MdbRdLong(F);
  AutoN := MdbRdLong(F);
  T^.NextAutoNum := AutoN;
  For J := 1 To FC Do Begin
   If J > MAX_FIELDS Then Begin
    { On lit quand meme pour ne pas desyncroniser }
    MdbRdStr(F, 32);
    MdbRdByte(F); MdbRdWord(F);
    MdbRdByte(F); MdbRdByte(F); MdbRdByte(F); MdbRdByte(F); MdbRdByte(F);
    MdbRdStr(F, 40); MdbRdStr(F, 40); MdbRdStr(F, 64);
    MdbRdStr(F, 24); MdbRdStr(F, 24); MdbRdStr(F, 60); MdbRdStr(F, 60);
    Continue;
   End;
   Inc(T^.FldCount);
   Fld := @T^.Fields[T^.FldCount];
   FillChar(Fld^, SizeOf(TField), 0);
   Fld^.Name        := MdbRdStr(F, 32);
   Fld^.FType       := MdbRdByte(F);
   Fld^.Size        := MdbRdWord(F);
   Fld^.Decimals    := MdbRdByte(F);
   Fld^.Required    := MdbRdByte(F) <> 0;
   Fld^.Indexed     := MdbRdByte(F);
   Fld^.PrimaryKey  := MdbRdByte(F) <> 0;
   Fld^.AllowNull   := MdbRdByte(F) <> 0;
   Fld^.DefaultVal  := MdbRdStr(F, 40);
   Fld^.Caption     := MdbRdStr(F, 40);
   Fld^.Description := MdbRdStr(F, 64);
   Fld^.Format      := MdbRdStr(F, 24);
   Fld^.InputMask   := MdbRdStr(F, 24);
   Fld^.ValidRule   := MdbRdStr(F, 60);
   Fld^.ValidText   := MdbRdStr(F, 60);
  End;
  For J := 1 To RecN Do Begin
   Del := MdbRdByte(F);
   If T^.RecCount >= MAX_RECORDS Then Begin
    { skip }
    For K := 1 To FC Do MdbRdStr(F, 80);
    Continue;
   End;
   RIdx := NewRecord(TIdx);
   If RIdx = 0 Then Begin
    For K := 1 To FC Do MdbRdStr(F, 80);
    Continue;
   End;
   R := T^.Records[RIdx];
   R^.Deleted := Del <> 0;
   For K := 1 To FC Do Begin
    If K <= T^.FldCount Then R^.Values[K] := MdbRdStr(F, 80)
    Else MdbRdStr(F, 80);
   End;
  End;
  If MdbErr Then Break;
 End;
 { Relations }
 If Not MdbErr Then
  For I := 1 To RC Do Begin
   If DB.RelCount >= MAX_RELATIONS Then Begin
    { skip remaining bytes }
    MdbRdStr(F, 32);
    MdbRdWord(F); MdbRdWord(F); MdbRdWord(F); MdbRdWord(F);
    MdbRdByte(F); MdbRdByte(F); MdbRdByte(F);
    Continue;
   End;
   GetMem(Rel, SizeOf(TRelation));
   FillChar(Rel^, SizeOf(TRelation), 0);
   Rel^.Name       := MdbRdStr(F, 32);
   Rel^.TblFromIdx := MdbRdWord(F);
   Rel^.FldFromIdx := MdbRdWord(F);
   Rel^.TblToIdx   := MdbRdWord(F);
   Rel^.FldToIdx   := MdbRdWord(F);
   Rel^.Enforce    := MdbRdByte(F) <> 0;
   Rel^.CascadeUpd := MdbRdByte(F) <> 0;
   Rel^.CascadeDel := MdbRdByte(F) <> 0;
   Inc(DB.RelCount);
   DB.Relations[DB.RelCount] := Rel;
  End;
 Close(F);
 If MdbErr Then Begin
  MessageBox('Ouvrir', 'Erreur de lecture MDB.'); Exit;
 End;
 { Compte non-nil pour info }
 NumNonNil := 0;
 For I := 1 To DB.TblCount Do If DB.Tables[I] <> Nil Then Inc(NumNonNil);
 ComputeNavLayout;
 RelLayoutDone := False;
 StatusMsg := 'Charge MDB : ' + IntToStr(NumNonNil) + ' table(s), ' +
              IntToStr(DB.RelCount) + ' relation(s).';
 NeedStatRedraw := True;
 LoadMdb := True;
End;

Function SqlTypeStr(Ft: Byte; Size: Word): String;
Var Sz: Word;
Begin
 Case Ft Of
  FT_TEXT     : Begin
                 Sz := Size; If Sz = 0 Then Sz := 50;
                 SqlTypeStr := 'TEXT(' + IntToStr(Sz) + ')';
                End;
  FT_MEMO     : SqlTypeStr := 'MEMO';
  FT_INTEGER  : SqlTypeStr := 'INTEGER';
  FT_LONG     : SqlTypeStr := 'LONG';
  FT_SINGLE   : SqlTypeStr := 'SINGLE';
  FT_DOUBLE   : SqlTypeStr := 'DOUBLE';
  FT_CURRENCY : SqlTypeStr := 'CURRENCY';
  FT_DATE     : SqlTypeStr := 'DATE';
  FT_TIME     : SqlTypeStr := 'TIME';
  FT_DATETIME : SqlTypeStr := 'DATETIME';
  FT_BOOL     : SqlTypeStr := 'BOOLEAN';
  FT_AUTONUM  : SqlTypeStr := 'AUTONUMBER';
 Else
  SqlTypeStr := 'TEXT(50)';
 End;
End;

Function SqlEscape(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := '''';
 For I := 1 To Length(S) Do
  If S[I] = '''' Then R := R + '''''' Else R := R + S[I];
 R := R + '''';
 SqlEscape := R;
End;

Function SqlIsNumType(Ft: Byte): Boolean;
Begin
 SqlIsNumType := (Ft = FT_INTEGER) Or (Ft = FT_LONG) Or
                 (Ft = FT_SINGLE)  Or (Ft = FT_DOUBLE) Or
                 (Ft = FT_CURRENCY) Or (Ft = FT_AUTONUM);
End;

Function SqlValueLit(Const Val: String; Ft: Byte): String;
Var V: String; I: Integer; Ok: Boolean;
Begin
 V := TrimStr(Val);
 If V = '' Then Begin SqlValueLit := 'NULL'; Exit; End;
 If Ft = FT_BOOL Then Begin
  If (UpperStr(V) = 'TRUE') Or (V = '1') Or (UpperStr(V) = 'OUI') Or
     (UpperStr(V) = 'YES') Or (UpperStr(V) = '-1') Then SqlValueLit := '1'
  Else SqlValueLit := '0';
  Exit;
 End;
 If SqlIsNumType(Ft) Then Begin
  Ok := True; I := 1;
  If (V[1] = '-') Or (V[1] = '+') Then Inc(I);
  If I > Length(V) Then Ok := False;
  While Ok And (I <= Length(V)) Do Begin
   If Not ((V[I] In ['0'..'9']) Or (V[I] = '.')) Then Ok := False;
   Inc(I);
  End;
  If Ok Then Begin SqlValueLit := V; Exit; End;
 End;
 SqlValueLit := SqlEscape(Val);
End;

Function LoadSql(Const FName: String): Boolean;
Var F: Text; Line, Stmt, T: String;
    I, LineNo, StmtCount: Integer;
    InStr, PrevErr: Boolean; C: Char;
Begin
 LoadSql := False;
 {$I-} Assign(F, FName); Reset(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Ouvrir', 'Impossible d''ouvrir : ' + FName); Exit;
 End;
 Stmt := ''; InStr := False; LineNo := 0; StmtCount := 0; PrevErr := False;
 While Not Eof(F) Do Begin
  ReadLn(F, Line); Inc(LineNo);
  T := TrimStr(Line);
  If (Length(T) >= 2) And (T[1] = '-') And (T[2] = '-') Then Continue;
  If Stmt <> '' Then Stmt := Stmt + ' ';
  I := 1;
  While I <= Length(Line) Do Begin
   C := Line[I];
   If C = '''' Then Begin
    If Length(Stmt) < 250 Then Stmt := Stmt + C;
    InStr := Not InStr; Inc(I); Continue;
   End;
   If (Not InStr) And (C = '-') And (I < Length(Line)) And
      (Line[I + 1] = '-') Then Break;
   If (Not InStr) And (C = ';') Then Begin
    If TrimStr(Stmt) <> '' Then Begin
     ExecSql(Stmt); Inc(StmtCount);
     If SqlErr Then Begin
      MessageBox('Erreur SQL',
                 'Ligne ' + IntToStr(LineNo) + ' : ' + SqlErrMsg);
      PrevErr := True; Stmt := ''; Break;
     End;
    End;
    Stmt := ''; Inc(I); Continue;
   End;
   If Length(Stmt) < 250 Then Stmt := Stmt + C;
   Inc(I);
  End;
  If PrevErr Then Break;
 End;
 If (Not PrevErr) And (TrimStr(Stmt) <> '') Then Begin
  ExecSql(Stmt); Inc(StmtCount);
  If SqlErr Then Begin
   MessageBox('Erreur SQL', SqlErrMsg); PrevErr := True;
  End;
 End;
 Close(F);
 If PrevErr Then Exit;
 ComputeNavLayout;
 StatusMsg := 'Charge : ' + IntToStr(StmtCount) + ' instruction(s) SQL.';
 NeedStatRedraw := True;
 LoadSql := True;
End;

Function SaveMdb(Const FName: String): Boolean;
Var F: File; Hdr: Array[1..4] Of Char;
    I, J, K, NumT, NumR: Integer;
    T: PTable; Fld: PField; R: PRecord; Rel: PRelation;
    RealRecCount: LongInt; B: Byte;
Begin
 SaveMdb := False;
 MdbErr := False;
 {$I-} Assign(F, FName); Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Enregistrer', 'Impossible de creer : ' + FName); Exit;
 End;
 Hdr[1] := MDB_MAGIC_1; Hdr[2] := MDB_MAGIC_2;
 Hdr[3] := MDB_MAGIC_3; Hdr[4] := MDB_MAGIC_4;
 MdbWrBytes(F, Hdr, 4);
 MdbWrWord(F, MDB_VERSION);
 MdbWrWord(F, 0);  { flags }
 MdbWrStr(F, DB.Name,     40);
 MdbWrStr(F, DB.Title,    60);
 MdbWrStr(F, DB.Author,   40);
 MdbWrStr(F, DB.Company,  60);
 MdbWrStr(F, DB.Comments, 120);
 { Compte tables et relations effectivement presentes }
 NumT := 0;
 For I := 1 To DB.TblCount Do If DB.Tables[I] <> Nil Then Inc(NumT);
 NumR := 0;
 For I := 1 To DB.RelCount Do If DB.Relations[I] <> Nil Then Inc(NumR);
 MdbWrWord(F, NumT);
 MdbWrWord(F, NumR);
 For I := 1 To DB.TblCount Do Begin
  T := DB.Tables[I];
  If T = Nil Then Continue;
  MdbWrStr(F, T^.Name, 32);
  MdbWrStr(F, T^.Description, 64);
  MdbWrWord(F, T^.FldCount);
  RealRecCount := 0;
  For J := 1 To T^.RecCount Do
   If T^.Records[J] <> Nil Then Inc(RealRecCount);
  MdbWrLong(F, RealRecCount);
  MdbWrLong(F, T^.NextAutoNum);
  For J := 1 To T^.FldCount Do Begin
   Fld := @T^.Fields[J];
   MdbWrStr(F,  Fld^.Name, 32);
   MdbWrByte(F, Fld^.FType);
   MdbWrWord(F, Fld^.Size);
   MdbWrByte(F, Fld^.Decimals);
   If Fld^.Required   Then B := 1 Else B := 0; MdbWrByte(F, B);
   MdbWrByte(F, Fld^.Indexed);
   If Fld^.PrimaryKey Then B := 1 Else B := 0; MdbWrByte(F, B);
   If Fld^.AllowNull  Then B := 1 Else B := 0; MdbWrByte(F, B);
   MdbWrStr(F, Fld^.DefaultVal,  40);
   MdbWrStr(F, Fld^.Caption,     40);
   MdbWrStr(F, Fld^.Description, 64);
   MdbWrStr(F, Fld^.Format,      24);
   MdbWrStr(F, Fld^.InputMask,   24);
   MdbWrStr(F, Fld^.ValidRule,   60);
   MdbWrStr(F, Fld^.ValidText,   60);
  End;
  For J := 1 To T^.RecCount Do Begin
   R := T^.Records[J];
   If R = Nil Then Continue;
   If R^.Deleted Then B := 1 Else B := 0;
   MdbWrByte(F, B);
   For K := 1 To T^.FldCount Do MdbWrStr(F, R^.Values[K], 80);
  End;
  If MdbErr Then Break;
 End;
 If Not MdbErr Then
  For I := 1 To DB.RelCount Do Begin
   Rel := DB.Relations[I];
   If Rel = Nil Then Continue;
   MdbWrStr(F,  Rel^.Name, 32);
   MdbWrWord(F, Rel^.TblFromIdx);
   MdbWrWord(F, Rel^.FldFromIdx);
   MdbWrWord(F, Rel^.TblToIdx);
   MdbWrWord(F, Rel^.FldToIdx);
   If Rel^.Enforce    Then B := 1 Else B := 0; MdbWrByte(F, B);
   If Rel^.CascadeUpd Then B := 1 Else B := 0; MdbWrByte(F, B);
   If Rel^.CascadeDel Then B := 1 Else B := 0; MdbWrByte(F, B);
  End;
 Close(F);
 If MdbErr Then Begin
  MessageBox('Enregistrer', 'Erreur d''ecriture MDB.'); Exit;
 End;
 StatusMsg := 'Enregistre MDB : ' + IntToStr(NumT) + ' table(s).';
 NeedStatRedraw := True;
 SaveMdb := True;
End;

Function SaveSql(Const FName: String): Boolean;
Var F: Text; T: PTable; R: PRelation;
    I, J, K, N: Integer; Line, V: String; Fld: PField;
Begin
 SaveSql := False;
 {$I-} Assign(F, FName); Rewrite(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Enregistrer', 'Impossible de creer : ' + FName); Exit;
 End;
 WriteLn(F, '-- Base de donnees : ', DB.Name);
 WriteLn(F, '-- Generee par ACCESS clone (Office-0)');
 WriteLn(F);
 N := 0;
 For I := 1 To DB.TblCount Do Begin
  T := DB.Tables[I];
  If T = Nil Then Continue;
  Inc(N);
  WriteLn(F, '-- Table : ', T^.Name);
  WriteLn(F, 'CREATE TABLE ', T^.Name, ' (');
  For J := 1 To T^.FldCount Do Begin
   Fld := @T^.Fields[J];
   Line := '  ' + Fld^.Name + ' ' + SqlTypeStr(Fld^.FType, Fld^.Size);
   If Fld^.PrimaryKey Then Line := Line + ' PRIMARY KEY'
   Else If Not Fld^.AllowNull Then Line := Line + ' NOT NULL';
   If J < T^.FldCount Then Line := Line + ',';
   WriteLn(F, Line);
  End;
  WriteLn(F, ');');
  WriteLn(F);
  For J := 1 To T^.RecCount Do
   If (T^.Records[J] <> Nil) And (Not T^.Records[J]^.Deleted) Then Begin
    Line := 'INSERT INTO ' + T^.Name + ' VALUES (';
    For K := 1 To T^.FldCount Do Begin
     If K > 1 Then Line := Line + ', ';
     V := SqlValueLit(T^.Records[J]^.Values[K], T^.Fields[K].FType);
     If Length(Line) + Length(V) > 230 Then Begin
      WriteLn(F, Line); Line := '       ';
     End;
     Line := Line + V;
    End;
    Line := Line + ');';
    WriteLn(F, Line);
   End;
  WriteLn(F);
 End;
 If DB.RelCount > 0 Then Begin
  WriteLn(F, '-- Relations');
  For I := 1 To DB.RelCount Do Begin
   R := DB.Relations[I];
   If R = Nil Then Continue;
   Line := '-- ' + R^.Name + ' : ';
   If (R^.TblFromIdx >= 1) And (R^.TblFromIdx <= DB.TblCount) And
      (DB.Tables[R^.TblFromIdx] <> Nil) And
      (R^.FldFromIdx >= 1) And
      (R^.FldFromIdx <= DB.Tables[R^.TblFromIdx]^.FldCount) Then
    Line := Line + DB.Tables[R^.TblFromIdx]^.Name + '.' +
            DB.Tables[R^.TblFromIdx]^.Fields[R^.FldFromIdx].Name;
   Line := Line + ' -> ';
   If (R^.TblToIdx >= 1) And (R^.TblToIdx <= DB.TblCount) And
      (DB.Tables[R^.TblToIdx] <> Nil) And
      (R^.FldToIdx >= 1) And
      (R^.FldToIdx <= DB.Tables[R^.TblToIdx]^.FldCount) Then
    Line := Line + DB.Tables[R^.TblToIdx]^.Name + '.' +
            DB.Tables[R^.TblToIdx]^.Fields[R^.FldToIdx].Name;
   WriteLn(F, Line);
  End;
 End;
 Close(F);
 StatusMsg := 'Enregistre : ' + IntToStr(N) + ' table(s) SQL.';
 NeedStatRedraw := True;
 SaveSql := True;
End;

Procedure ActionNewDb;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FreeDatabase;
 InitDatabase;
 CurTblIdx := 0; CurFldIdx := 0; CurRecIdx := 0; CurFrmIdx := 0; CurRptIdx := 0;
 CurView := VIEW_NAV;
 RelLayoutDone := False;
 StatusMsg := 'Nouvelle base creee.';
 NeedFullRedraw := True;
End;

Procedure ActionOpenDb;
Var FName, Ext: String; Ok: Boolean;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FName := '';
 If Not ShowFileDialog('Ouvrir une base', FName, False, 'MDB,SQL') Then Exit;
 Ext := ExtOf(FName);
 FreeDatabase;
 InitDatabase;
 RelLayoutDone := False;
 If Ext = 'MDB' Then Ok := LoadMdb(FName)
 Else If Ext = 'SQL' Then Ok := LoadSql(FName)
 Else Begin
  MessageBox('Ouvrir', 'Extension inconnue : ' + Ext);
  Ok := False;
 End;
 If Ok Then Begin
  DB.FileName := FName;
  DB.Dirty := False;
  StatusMsg := 'Base chargee : ' + FName;
 End;
 CurView := VIEW_NAV;
 NeedFullRedraw := True;
End;

Procedure ActionSaveDbAs;
Var FName, Ext: String; Ok: Boolean;
Begin
 FName := DB.FileName;
 If FName = '' Then FName := DB.Name + '.MDB';
 If Not ShowFileDialog('Enregistrer sous', FName, True, 'MDB,SQL') Then Exit;
 Ext := ExtOf(FName);
 If Ext = 'MDB' Then Ok := SaveMdb(FName)
 Else If Ext = 'SQL' Then Ok := SaveSql(FName)
 Else Begin
  MessageBox('Enregistrer', 'Extension inconnue : ' + Ext);
  Ok := False;
 End;
 If Ok Then Begin
  DB.FileName := FName;
  DB.Dirty := False;
  StatusMsg := 'Base enregistree : ' + FName;
  NeedFullRedraw := True;
 End;
End;

Procedure ActionSaveDb;
Var Ext: String; Ok: Boolean;
Begin
 If DB.FileName = '' Then Begin ActionSaveDbAs; Exit; End;
 Ext := ExtOf(DB.FileName);
 If Ext = 'MDB' Then Ok := SaveMdb(DB.FileName)
 Else If Ext = 'SQL' Then Ok := SaveSql(DB.FileName)
 Else Begin ActionSaveDbAs; Exit; End;
 If Ok Then Begin
  DB.Dirty := False;
  StatusMsg := 'Base enregistree.';
  NeedStatRedraw := True;
 End;
End;

Procedure DoAction(A: Integer);
Begin
 Case A Of
  ACT_QUIT:        ActionQuit;
  ACT_NEW:         ActionNewDb;
  ACT_OPEN:        ActionOpenDb;
  ACT_SAVE:        ActionSaveDb;
  ACT_SAVEAS:      ActionSaveDbAs;
  ACT_IMPORT_CSV:  ActionImportCsv;
  ACT_EXPORT_CSV:  ActionExportCsv;
  ACT_PRINT:       ActionPrint;
  ACT_HELP_ABOUT:  ActionAbout;
  ACT_HELP_TOPIC:  ActionAbout;
  ACT_VIEW_NAV:    ActionView(VIEW_NAV);
  ACT_VIEW_DSHEET: ActionView(VIEW_DSHEET);
  ACT_VIEW_DESIGN: ActionView(VIEW_DESIGN);
  ACT_VIEW_QUERY:  ActionView(VIEW_QUERY);
  ACT_SQL_VIEW:    ActionView(VIEW_QUERY);
  ACT_VIEW_FORM:   ActionView(VIEW_FORM);
  ACT_VIEW_REPORT: ActionView(VIEW_REPORT);
  ACT_OPEN_OBJ:    ActionOpenSelectedObj;
  ACT_FIRST_REC:   ActionFirstRec;
  ACT_PREV_REC:    ActionPrevRec;
  ACT_NEXT_REC:    ActionNextRec;
  ACT_LAST_REC:    ActionLastRec;
  ACT_INS_REC:     ActionInsRec;
  ACT_DEL_REC:     ActionDelRec;
  ACT_NEW_REC:     ActionNewRec;
  ACT_UNDO:        DoUndo;
  ACT_REDO:        DoRedo;
  ACT_NEW_TABLE:   ActionNewTable;
  ACT_DELETE_OBJ:  ActionDeleteObj;
  ACT_TABLE_ADDF:  If CurView = VIEW_DESIGN Then DesignAddField;
  ACT_TABLE_DELF:  If CurView = VIEW_DESIGN Then DesignDelField;
  ACT_TABLE_KEY:   If CurView = VIEW_DESIGN Then DesignTogglePK;
  ACT_NEW_QUERY:   ActionNewQuery;
  ACT_NEW_FORM:    ActionNewForm;
  ACT_NEW_REPORT:  ActionNewReport;
  ACT_REL_EDIT:    ActionRelEdit;
  ACT_NEW_RELATION: ActionNewRelation;
  ACT_DEL_RELATION: ActionDelRelation;
  ACT_RUN_QUERY:   ActionRunQuery;
  ACT_RUN_SQL:     ActionRunQuery;
 Else
  StatusMsg := 'Action ' + IntToStr(A) + ' : a implementer.';
  NeedStatRedraw := True;
 End;
End;

{ ====================================================================== }
{                       HOVERS / EVENTS                                  }
{ ====================================================================== }

Procedure UpdateHovers;
Var M, T, OldM, OldT, OldI: Integer;
Begin
 OldM := MenuHover; OldT := ToolHover; OldI := MenuItemHover;
 M := 0; T := 0;
 If (Mouse.Y >= MenuY1) And (Mouse.Y <= MenuY2) Then
  M := MenuAtX(Mouse.X)
 Else If (Mouse.Y >= ToolY1) And (Mouse.Y <= ToolY2) Then
  T := ToolAtXY(Mouse.X, Mouse.Y);
 MenuHover := M;
 ToolHover := T;
 If (MenuOpen > 0) And (M > 0) And (M <> MenuOpen) Then Begin
  MenuOpen := M;
  MenuItemHover := 0;
  NeedFullRedraw := True;
 End;
 If MenuOpen > 0 Then Begin
  ComputeDropLayout(MenuOpen);
  If InRect(Mouse.X, Mouse.Y, DropX, DropY, DropX + DropW, DropY + DropH) Then
   MenuItemHover := DropItemAtY(MenuOpen, Mouse.Y)
  Else MenuItemHover := 0;
 End
 Else MenuItemHover := 0;
 If MenuHover <> OldM Then NeedMenuRedraw := True;
 If (ToolHover <> OldT) And (MenuOpen = 0) Then NeedFullRedraw := True;
 If (MenuItemHover <> OldI) And (MenuOpen > 0) Then NeedDropRedraw := True;
 If (ToolHover > 0) And (Not Tools[ToolHover].IsSep) Then Begin
  If StatusMsg <> Tools[ToolHover].Hint Then Begin
   StatusMsg := Tools[ToolHover].Hint;
   NeedStatRedraw := True;
  End;
 End
 Else If StatusMsg <> '' Then Begin
  StatusMsg := '';
  NeedStatRedraw := True;
 End;
End;

Procedure HandleDesignClick;
Var T: PTable; Row, Col, I, Y: Integer;
Begin
 T := CurTable; If T = Nil Then Exit;
 { Liste deroulante de type : prioritaire }
 If DesignTypeDrop Then Begin
  If InRect(Mouse.X, Mouse.Y, DesignTypeDropX, DesignTypeDropY,
            DesignTypeDropX + DesignColumnW(3) + 2, DesignTypeDropY + 15 * 14) Then Begin
   I := (Mouse.Y - DesignTypeDropY) Div 14 + 1;
   If (I >= 1) And (I <= 15) Then Begin
    DesignSetType(I);
    DesignTypeDrop := False;
   End;
  End
  Else DesignTypeDrop := False;
  NeedFullRedraw := True;
  Exit;
 End;
 { Clic dans la grille }
 If (Mouse.Y >= DesignBodyY) And (Mouse.Y < DesignGridY2) Then Begin
  Row := DesignTopRow + (Mouse.Y - DesignBodyY) Div 16 + 1;
  If Row < 1 Then Row := 1;
  If Row > T^.FldCount + 1 Then Exit;
  Col := 0;
  If Mouse.X < DesignColumnX(2) Then Col := 1
  Else If Mouse.X < DesignColumnX(3) Then Col := 2
  Else If Mouse.X < DesignColumnX(4) Then Col := 3
  Else Col := 4;
  If EditMode Then CommitDesignEdit;
  DesignFocus  := 0;
  DesignSelRow := Row;
  DesignSelCol := Col;
  NeedFullRedraw := True;
  If Col = 1 Then Begin
   If Row <= T^.FldCount Then DesignTogglePK;
   Exit;
  End;
  If Col = 3 Then Begin
   { Clic sur fleche combo ou double-clic ouvre la liste }
   If (Mouse.X >= DesignColumnX(3) + DesignColumnW(3) - 14) Or DoubleClicked Then Begin
    If Row <= T^.FldCount Then Begin
     DesignTypeDrop := True;
     DesignTypeDropSel := T^.Fields[Row].FType;
     NeedFullRedraw := True;
    End;
   End;
   Exit;
  End;
  If DoubleClicked Then BeginDesignEdit;
  Exit;
 End;
 { Clic dans le panneau de proprietes }
 If (Mouse.Y >= DesignPropY + 18) And (Mouse.Y < SCREEN_H - STAT_H - 1) Then Begin
  Y := DesignPropY + 18;
  For I := 1 To PROP_COUNT Do Begin
   If (Mouse.Y >= Y) And (Mouse.Y < Y + 12) Then Begin
    If EditMode Then CommitDesignEdit;
    DesignFocus   := 1;
    DesignPropSel := I;
    NeedFullRedraw := True;
    If DoubleClicked Then BeginDesignEdit;
    Exit;
   End;
   Y := Y + 12;
  End;
 End;
End;

Procedure HandleDSheetClick;
Var Fld, Row: Integer; OverSep: Boolean;
Begin
 { En-tete : drag de redimensionnement }
 If (Mouse.Y >= DSheetHdrY) And (Mouse.Y < DSheetHdrY + GRID_HDR_H) Then Begin
  Fld := FieldAtX(Mouse.X, OverSep);
  If OverSep And (Fld > 0) Then Begin
   DragCol    := Fld;
   DragStartX := Mouse.X;
   DragStartW := DSheetColW[Fld];
   { Boucle locale de drag }
   Repeat
    UpdateMouse;
    If LeftDown Then Begin
     DSheetColW[Fld] := DragStartW + (Mouse.X - DragStartX);
     If DSheetColW[Fld] < 20  Then DSheetColW[Fld] := 20;
     If DSheetColW[Fld] > 400 Then DSheetColW[Fld] := 400;
     NeedGridRedraw := True;
     Redraw;
    End;
    Delay(15);
   Until Not LeftDown;
   DragCol := 0;
   NeedGridRedraw := True;
   Exit;
  End;
  If Fld > 0 Then Begin
   If EditMode Then CommitEdit;
   CurFldIdx := Fld;
   NeedGridRedraw := True;
  End;
  Exit;
 End;
 { Corps : selection cellule }
 If (Mouse.Y >= DSheetBodyY) And (Mouse.Y < DSheetBodyY2) Then Begin
  Row := RowAtY(Mouse.Y);
  Fld := FieldAtX(Mouse.X, OverSep);
  If (Row >= 1) And (Row <= CurTable^.RecCount) And (Fld > 0) Then Begin
   If EditMode And ((Row <> CurRecIdx) Or (Fld <> CurFldIdx)) Then CommitEdit;
   CurRecIdx := Row;
   CurFldIdx := Fld;
   If DoubleClicked Then BeginEdit;
   NeedGridRedraw := True;
  End;
 End;
End;

Procedure HandleMouseClick;
Var M, I, Idx, A: Integer;
Begin
 { Barre de menu }
 If (Mouse.Y >= MenuY1) And (Mouse.Y <= MenuY2) Then Begin
  M := MenuAtX(Mouse.X);
  If M > 0 Then Begin
   If MenuOpen = M Then MenuOpen := 0
   Else Begin MenuOpen := M; MenuItemHover := 0; End;
   NeedFullRedraw := True;
  End
  Else Begin MenuOpen := 0; NeedFullRedraw := True; End;
  Exit;
 End;
 { Drop-down menu ouvert }
 If MenuOpen > 0 Then Begin
  ComputeDropLayout(MenuOpen);
  If InRect(Mouse.X, Mouse.Y, DropX, DropY, DropX + DropW, DropY + DropH) Then Begin
   Idx := DropItemAtY(MenuOpen, Mouse.Y);
   If (Idx > 0) And (Not Menus[MenuOpen].Items[Idx].IsSep) Then Begin
    A := Menus[MenuOpen].Items[Idx].Action;
    MenuOpen := 0;
    NeedFullRedraw := True;
    DoAction(A);
   End;
   Exit;
  End
  Else Begin MenuOpen := 0; NeedFullRedraw := True; End;
 End;
 { Barre d'outils }
 If (Mouse.Y >= ToolY1) And (Mouse.Y <= ToolY2) Then Begin
  I := ToolAtXY(Mouse.X, Mouse.Y);
  If I > 0 Then DoAction(Tools[I].Action);
  Exit;
 End;
 { Navigation : panneau lateral }
 If CurView = VIEW_NAV Then Begin
  If InRect(Mouse.X, Mouse.Y, 0, NavTabY, 100, NavListY2) Then Begin
   If InRect(Mouse.X, Mouse.Y, 4, NavTabY + 32, 96, NavTabY + 44) Then
    ActionNavObjType(OBJ_TABLE);
   If InRect(Mouse.X, Mouse.Y, 4, NavTabY + 50, 96, NavTabY + 62) Then
    ActionNavObjType(OBJ_QUERY);
   If InRect(Mouse.X, Mouse.Y, 4, NavTabY + 68, 96, NavTabY + 80) Then
    ActionNavObjType(OBJ_FORM);
   If InRect(Mouse.X, Mouse.Y, 4, NavTabY + 86, 96, NavTabY + 98) Then
    ActionNavObjType(OBJ_REPORT);
   Exit;
  End;
  { Onglets en haut }
  For I := 1 To 4 Do
   If InRect(Mouse.X, Mouse.Y,
             NavTabBoxes[I].X1, NavTabBoxes[I].Y1,
             NavTabBoxes[I].X2, NavTabBoxes[I].Y2) Then Begin
    Case I Of
     1: ActionNavObjType(OBJ_TABLE);
     2: ActionNavObjType(OBJ_QUERY);
     3: ActionNavObjType(OBJ_FORM);
     4: ActionNavObjType(OBJ_REPORT);
    End;
    Exit;
   End;
  { Liste }
  If InRect(Mouse.X, Mouse.Y, 102, NavListY1 + 32, SCREEN_W - 4, NavListY2) Then Begin
   Idx := (Mouse.Y - (NavListY1 + 32)) Div 22 + 1 + NavScroll;
   If (Idx >= 1) And (Idx <= NavObjCount(CurObjType)) Then Begin
    NavSelObj := Idx;
    NeedNavRedraw := True;
    If DoubleClicked Then ActionOpenSelectedObj;
   End;
   Exit;
  End;
 End;
 { Feuille de donnees : navigation enregistrements }
 If CurView = VIEW_DSHEET Then Begin
  If InRect(Mouse.X, Mouse.Y, 120, SCREEN_H - STAT_H - NAV_H, 139,
            SCREEN_H - STAT_H - 2) Then Begin ActionFirstRec; Exit; End;
  If InRect(Mouse.X, Mouse.Y, 140, SCREEN_H - STAT_H - NAV_H, 159,
            SCREEN_H - STAT_H - 2) Then Begin ActionPrevRec;  Exit; End;
  If InRect(Mouse.X, Mouse.Y, 250, SCREEN_H - STAT_H - NAV_H, 269,
            SCREEN_H - STAT_H - 2) Then Begin ActionNextRec;  Exit; End;
  If InRect(Mouse.X, Mouse.Y, 270, SCREEN_H - STAT_H - NAV_H, 289,
            SCREEN_H - STAT_H - 2) Then Begin ActionLastRec;  Exit; End;
  If InRect(Mouse.X, Mouse.Y, 296, SCREEN_H - STAT_H - NAV_H, 315,
            SCREEN_H - STAT_H - 2) Then Begin ActionInsRec;   Exit; End;
  If InRect(Mouse.X, Mouse.Y, 320, SCREEN_H - STAT_H - NAV_H, 339,
            SCREEN_H - STAT_H - 2) Then Begin ActionDelRec;   Exit; End;
  HandleDSheetClick;
 End;
 { Mode Creation }
 If CurView = VIEW_DESIGN Then HandleDesignClick;
 If CurView = VIEW_QUERY  Then HandleQueryClick;
 If CurView = VIEW_FORM   Then HandleFormClick;
 If CurView = VIEW_REPORT Then HandleReportClick;
 If CurView = VIEW_RELATIONS Then HandleRelationsClick;
End;

Procedure HandleKey(K, K2: Char);
Var T: PTable;
Begin
 { ===== RACCOURCIS GLOBAUX (toutes vues) ===== }
 If K = #0 Then Begin
  Case K2 Of
   #107: Begin DoAction(ACT_QUIT); Exit; End;  { Alt+F4 }
   #45 : Begin DoAction(ACT_QUIT); Exit; End;  { Alt+X  }
  End;
 End;
 { ===== MODE RELATIONS ===== }
 If CurView = VIEW_RELATIONS Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #59 : Begin DoAction(ACT_HELP_TOPIC); Exit; End;                  { F1 }
    #133: Begin CurView := VIEW_NAV; NeedFullRedraw := True; Exit; End; { F11 }
    #82 : Begin ActionNewRelation; Exit; End;                         { Ins }
    #83 : Begin ActionDelRelation; Exit; End;                         { Del }
    #15 : Begin                                                      { Shift+Tab }
           If DB.RelCount > 0 Then Begin
            If RelSelIdx <= 1 Then RelSelIdx := DB.RelCount
            Else Dec(RelSelIdx);
            NeedFullRedraw := True;
           End; Exit;
          End;
   End;
   Exit;
  End;
  If K = #9 Then Begin   { Tab : cycle selection }
   If DB.RelCount > 0 Then Begin
    If RelSelIdx >= DB.RelCount Then RelSelIdx := 1
    Else Inc(RelSelIdx);
    NeedFullRedraw := True;
   End;
   Exit;
  End;
  If K = #27 Then Begin CurView := VIEW_NAV; NeedFullRedraw := True; Exit; End;
  Exit;
 End;
 { ===== MODE ETAT ===== }
 If CurView = VIEW_REPORT Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #59 : Begin DoAction(ACT_HELP_TOPIC); Exit; End;               { F1 }
    #133: Begin CurView := VIEW_NAV; NeedFullRedraw := True; Exit; End; { F11 }
    #73 : Begin ActionRptPrev;  Exit; End;                         { PgUp }
    #81 : Begin ActionRptNext;  Exit; End;                         { PgDn }
    #71 : Begin ActionRptFirst; Exit; End;                         { Home }
    #79 : Begin ActionRptLast;  Exit; End;                         { End }
    #75 : Begin ActionRptPrev;  Exit; End;                         { Left }
    #77 : Begin ActionRptNext;  Exit; End;                         { Right }
    #119: Begin ActionRptFirst; Exit; End;                         { Ctrl+Home }
    #117: Begin ActionRptLast;  Exit; End;                         { Ctrl+End }
   End;
   Exit;
  End;
  If K = #27 Then Begin
   CurView := VIEW_NAV; NeedFullRedraw := True; Exit;
  End;
  Exit;
 End;
 { ===== MODE FORMULAIRE ===== }
 If CurView = VIEW_FORM Then Begin
  T := Nil;
  If (CurTblIdx >= 1) And (CurTblIdx <= DB.TblCount) Then T := DB.Tables[CurTblIdx];
  If K = #0 Then Begin
   Case K2 Of
    #59: Begin DoAction(ACT_HELP_TOPIC); Exit; End;                { F1 }
    #133: Begin                                                    { F11 }
     If EditMode Then CommitEdit;
     CurView := VIEW_NAV; NeedFullRedraw := True; Exit;
    End;
    #72: Begin                                                     { Up }
     If EditMode Then CommitEdit;
     If (T <> Nil) And (CurFldIdx > 1) Then Begin Dec(CurFldIdx); NeedFullRedraw := True; End;
     Exit;
    End;
    #80: Begin                                                     { Down }
     If EditMode Then CommitEdit;
     If (T <> Nil) And (CurFldIdx < T^.FldCount) Then Begin Inc(CurFldIdx); NeedFullRedraw := True; End;
     Exit;
    End;
    #73: Begin                                                     { PgUp = prev rec }
     If EditMode Then CommitEdit;
     ActionPrevRec; NeedFullRedraw := True; Exit;
    End;
    #81: Begin                                                     { PgDn = next rec }
     If EditMode Then CommitEdit;
     ActionNextRec; NeedFullRedraw := True; Exit;
    End;
    #71: Begin                                                     { Home }
     If EditMode Then Begin EditCaret := 0; NeedFullRedraw := True; End
     Else Begin
      If T <> Nil Then CurFldIdx := 1;
      NeedFullRedraw := True;
     End;
     Exit;
    End;
    #79: Begin                                                     { End }
     If EditMode Then Begin EditCaret := Length(EditBuf); NeedFullRedraw := True; End
     Else Begin
      If T <> Nil Then CurFldIdx := T^.FldCount;
      NeedFullRedraw := True;
     End;
     Exit;
    End;
    #75: Begin                                                     { Left }
     If EditMode Then Begin
      If EditCaret > 0 Then Dec(EditCaret); NeedFullRedraw := True;
     End;
     Exit;
    End;
    #77: Begin                                                     { Right }
     If EditMode Then Begin
      If EditCaret < Length(EditBuf) Then Inc(EditCaret); NeedFullRedraw := True;
     End;
     Exit;
    End;
    #83: Begin                                                     { Delete }
     If EditMode Then Begin EditDeleteChar; NeedFullRedraw := True; End;
     Exit;
    End;
    #119: Begin ActionFirstRec; NeedFullRedraw := True; Exit; End; { Ctrl+Home }
    #117: Begin ActionLastRec;  NeedFullRedraw := True; Exit; End; { Ctrl+End }
   End;
   Exit;
  End;
  If K = #27 Then Begin
   If EditMode Then Begin CancelEdit; NeedFullRedraw := True; Exit; End;
   CurView := VIEW_NAV; NeedFullRedraw := True; Exit;
  End;
  If K = #13 Then Begin                                            { Enter }
   If EditMode Then Begin CommitEdit; NeedFullRedraw := True; End
   Else Begin
    If T <> Nil Then Begin
     If (CurRecIdx >= 1) And (CurRecIdx <= T^.RecCount) And
        (CurFldIdx >= 1) And (CurFldIdx <= T^.FldCount) Then Begin
      If T^.Fields[CurFldIdx].FType = FT_BOOL Then Begin
       Begin
        If (T^.Records[CurRecIdx]^.Values[CurFldIdx] = 'T') Or
           (T^.Records[CurRecIdx]^.Values[CurFldIdx] = '1') Or
           (T^.Records[CurRecIdx]^.Values[CurFldIdx] = 'Oui') Then
         T^.Records[CurRecIdx]^.Values[CurFldIdx] := 'F'
        Else
         T^.Records[CurRecIdx]^.Values[CurFldIdx] := 'T';
        T^.Dirty := True; DB.Dirty := True;
       End;
      End
      Else If T^.Fields[CurFldIdx].FType <> FT_AUTONUM Then BeginEdit;
     End;
    End;
    NeedFullRedraw := True;
   End;
   Exit;
  End;
  If K = #9 Then Begin                                             { Tab }
   If EditMode Then CommitEdit;
   If T <> Nil Then Begin
    Inc(CurFldIdx);
    If CurFldIdx > T^.FldCount Then CurFldIdx := 1;
   End;
   NeedFullRedraw := True; Exit;
  End;
  If K = #8 Then Begin                                             { Backspace }
   If EditMode Then Begin EditBackspace; NeedFullRedraw := True; End;
   Exit;
  End;
  If (K >= ' ') And (K <= #126) And (T <> Nil) Then Begin
   If (CurRecIdx >= 1) And (CurRecIdx <= T^.RecCount) And
      (CurFldIdx >= 1) And (CurFldIdx <= T^.FldCount) And
      (T^.Fields[CurFldIdx].FType <> FT_AUTONUM) And
      (T^.Fields[CurFldIdx].FType <> FT_BOOL) Then Begin
    If Not EditMode Then Begin
     EditBuf := ''; EditCaret := 0; EditMode := True;
    End;
    EditInsertChar(K);
    NeedFullRedraw := True;
   End;
   Exit;
  End;
  Exit;
 End;
 { ===== MODE REQUETE ===== }
 If CurView = VIEW_QUERY Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #63: Begin ActionRunQuery; Exit; End;                          { F5 }
    #64: Begin QFocus := 1 - QFocus; NeedFullRedraw := True; Exit; End; { F6 }
    #59: Begin DoAction(ACT_HELP_TOPIC); Exit; End;                { F1 }
    #133: Begin                                                    { F11 }
     If QDirty Then SaveQuerySql;
     CurView := VIEW_NAV; NeedFullRedraw := True; Exit;
    End;
   End;
   If QFocus = 0 Then Begin
    Case K2 Of
     #75: Begin If QCaret > 0 Then Dec(QCaret); NeedFullRedraw := True; End;
     #77: Begin If QCaret < Length(QSqlBuf) Then Inc(QCaret); NeedFullRedraw := True; End;
     #71: Begin QCaret := 0; NeedFullRedraw := True; End;
     #79: Begin QCaret := Length(QSqlBuf); NeedFullRedraw := True; End;
     #83: QEditDelete;                                             { Delete }
    End;
   End
   Else Begin
    Case K2 Of
     #72: If QResSelRow > 1 Then Begin Dec(QResSelRow); NeedFullRedraw := True; End;
     #80: If QResSelRow < QResRowCount Then Begin Inc(QResSelRow); NeedFullRedraw := True; End;
     #75: If QResSelCol > 1 Then Begin Dec(QResSelCol); NeedFullRedraw := True; End;
     #77: If QResSelCol < QResColCount Then Begin Inc(QResSelCol); NeedFullRedraw := True; End;
     #71: Begin QResSelRow := 1; QResScroll := 0; NeedFullRedraw := True; End;
     #79: Begin QResSelRow := QResRowCount; NeedFullRedraw := True; End;
     #73: Begin Dec(QResSelRow, 10); If QResSelRow < 1 Then QResSelRow := 1; NeedFullRedraw := True; End;
     #81: Begin Inc(QResSelRow, 10); If QResSelRow > QResRowCount Then QResSelRow := QResRowCount; NeedFullRedraw := True; End;
    End;
   End;
   Exit;
  End;
  If QFocus = 0 Then Begin
   If K = #27 Then Begin
    If QDirty Then SaveQuerySql;
    CurView := VIEW_NAV; NeedFullRedraw := True; Exit;
   End;
   If K = #13 Then Begin QEditInsertChar(#13); QEditInsertChar(#10); Exit; End;
   If K = #8  Then Begin QEditBackspace; Exit; End;
   If K = #9  Then Begin QEditInsertChar(' '); QEditInsertChar(' '); Exit; End;
   If (K >= ' ') And (K <= #126) Then Begin QEditInsertChar(K); Exit; End;
  End
  Else Begin
   If K = #27 Then Begin QFocus := 0; NeedFullRedraw := True; Exit; End;
  End;
  Exit;
 End;
 { ===== MODE CREATION : liste deroulante de type ===== }
 If (CurView = VIEW_DESIGN) And DesignTypeDrop Then Begin
  If K = #27 Then Begin DesignTypeDrop := False; NeedFullRedraw := True; Exit; End;
  If K = #13 Then Begin
   DesignSetType(DesignTypeDropSel);
   DesignTypeDrop := False;
   NeedFullRedraw := True; Exit;
  End;
  If K = #0 Then Begin
   Case K2 Of
    #72: If DesignTypeDropSel > 1  Then Dec(DesignTypeDropSel);  { Up   }
    #80: If DesignTypeDropSel < 15 Then Inc(DesignTypeDropSel);  { Down }
    #71: DesignTypeDropSel := 1;                                  { Home }
    #79: DesignTypeDropSel := 15;                                 { End  }
   End;
   NeedFullRedraw := True;
  End;
  Exit;
 End;
 { ===== MODE CREATION : edition cellule en cours ===== }
 If EditMode And (CurView = VIEW_DESIGN) Then Begin
  If K = #27 Then Begin CancelDesignEdit; Exit; End;
  If K = #13 Then Begin CommitDesignEdit; Exit; End;
  If K = #9  Then Begin
   CommitDesignEdit;
   T := CurTable;
   If T <> Nil Then Begin
    If DesignFocus = 0 Then Begin
     If DesignSelCol = 2 Then DesignSelCol := 3
     Else If DesignSelCol = 3 Then DesignSelCol := 4
     Else Begin
      DesignSelCol := 2;
      If DesignSelRow <= T^.FldCount Then Inc(DesignSelRow);
     End;
    End
    Else Begin
     If DesignPropSel < PROP_COUNT Then Inc(DesignPropSel)
     Else DesignPropSel := 1;
    End;
   End;
   NeedFullRedraw := True; Exit;
  End;
  If K = #8 Then Begin EditBackspace; Exit; End;
  If K = #0 Then Begin
   Case K2 Of
    #75: Begin If EditCaret > 0 Then Dec(EditCaret); NeedFullRedraw := True; End;
    #77: Begin If EditCaret < Length(EditBuf) Then Inc(EditCaret); NeedFullRedraw := True; End;
    #71: Begin EditCaret := 0; NeedFullRedraw := True; End;
    #79: Begin EditCaret := Length(EditBuf); NeedFullRedraw := True; End;
    #83: EditDeleteChar;
    #59: DoAction(ACT_HELP_TOPIC);
   End;
   Exit;
  End;
  If (K >= ' ') And (K <= #126) Then Begin EditInsertChar(K); Exit; End;
  Exit;
 End;
 { ===== MODE CREATION : navigation ===== }
 If (CurView = VIEW_DESIGN) And (Not EditMode) Then Begin
  T := CurTable;
  If K = #0 Then Begin
   Case K2 Of
    #59: Begin DoAction(ACT_HELP_TOPIC); Exit; End;
    #60: Begin BeginDesignEdit; Exit; End;                        { F2 }
    #62: Begin                                                    { F4 : combo type }
     If (DesignFocus = 0) And (DesignSelCol = 3) And (T <> Nil) Then
      If DesignSelRow <= T^.FldCount Then Begin
       DesignTypeDrop := True;
       DesignTypeDropSel := T^.Fields[DesignSelRow].FType;
       NeedFullRedraw := True;
      End;
     Exit;
    End;
    #64: Begin                                                    { F6 : basculer focus }
     DesignFocus := 1 - DesignFocus;
     NeedFullRedraw := True; Exit;
    End;
    #72: Begin                                                    { Up }
     If DesignFocus = 0 Then Begin If DesignSelRow > 1 Then Dec(DesignSelRow); End
     Else If DesignPropSel > 1 Then Dec(DesignPropSel);
     NeedFullRedraw := True; Exit;
    End;
    #80: Begin                                                    { Down }
     If DesignFocus = 0 Then Begin
      If T <> Nil Then If DesignSelRow < T^.FldCount + 1 Then Inc(DesignSelRow);
     End
     Else If DesignPropSel < PROP_COUNT Then Inc(DesignPropSel);
     NeedFullRedraw := True; Exit;
    End;
    #75: Begin                                                    { Left }
     If DesignFocus = 0 Then If DesignSelCol > 1 Then Dec(DesignSelCol);
     NeedFullRedraw := True; Exit;
    End;
    #77: Begin                                                    { Right }
     If DesignFocus = 0 Then If DesignSelCol < 4 Then Inc(DesignSelCol);
     NeedFullRedraw := True; Exit;
    End;
    #71: Begin                                                    { Home }
     If DesignFocus = 0 Then Begin DesignSelCol := 2; DesignSelRow := 1; End
     Else DesignPropSel := 1;
     NeedFullRedraw := True; Exit;
    End;
    #79: Begin                                                    { End }
     If DesignFocus = 0 Then Begin
      DesignSelCol := 4;
      If T <> Nil Then DesignSelRow := T^.FldCount;
     End
     Else DesignPropSel := PROP_COUNT;
     NeedFullRedraw := True; Exit;
    End;
    #82: Begin DesignAddField; Exit; End;                         { Insert }
    #83: Begin DesignDelField; Exit; End;                         { Delete }
    #133: DoAction(ACT_VIEW_NAV);
    #68: ActionQuit;
   End;
   Exit;
  End;
  If K = #13 Then Begin BeginDesignEdit; Exit; End;
  If K = #9 Then Begin
   If DesignFocus = 0 Then Begin
    If DesignSelCol < 4 Then Inc(DesignSelCol)
    Else Begin DesignSelCol := 2; If T <> Nil Then If DesignSelRow <= T^.FldCount Then Inc(DesignSelRow); End;
   End
   Else If DesignPropSel < PROP_COUNT Then Inc(DesignPropSel)
   Else DesignPropSel := 1;
   NeedFullRedraw := True; Exit;
  End;
  If K = #27 Then Begin CurView := VIEW_NAV; NeedFullRedraw := True; Exit; End;
  If (K >= ' ') And (K <= #126) Then Begin
   BeginDesignEdit;
   If EditMode Then Begin EditBuf := ''; EditCaret := 0; EditInsertChar(K); End;
   Exit;
  End;
  { Ctrl combos partages plus bas }
 End;
 { ===== EDITION CELLULE EN COURS ===== }
 If EditMode And (CurView = VIEW_DSHEET) Then Begin
  If K = #27 Then Begin CancelEdit; Exit; End;
  If K = #13 Then Begin
   CommitEdit;
   T := CurTable;
   If T <> Nil Then
    If CurRecIdx < T^.RecCount Then Inc(CurRecIdx);
   NeedGridRedraw := True; Exit;
  End;
  If K = #9 Then Begin                       { Tab }
   CommitEdit;
   T := CurTable;
   If T <> Nil Then Begin
    If CurFldIdx < T^.FldCount Then Inc(CurFldIdx)
    Else Begin
     CurFldIdx := 1;
     If CurRecIdx < T^.RecCount Then Inc(CurRecIdx);
    End;
   End;
   NeedGridRedraw := True; Exit;
  End;
  If K = #8 Then Begin EditBackspace; Exit; End;
  If K = #0 Then Begin
   Case K2 Of
    #75: Begin If EditCaret > 0 Then Dec(EditCaret); NeedGridRedraw := True; End;     { Left  }
    #77: Begin If EditCaret < Length(EditBuf) Then Inc(EditCaret); NeedGridRedraw := True; End; { Right }
    #71: Begin EditCaret := 0; NeedGridRedraw := True; End;                            { Home  }
    #79: Begin EditCaret := Length(EditBuf); NeedGridRedraw := True; End;             { End   }
    #83: EditDeleteChar;                                                               { Del   }
    #59: DoAction(ACT_HELP_TOPIC);
   End;
   Exit;
  End;
  If (K >= ' ') And (K <= #126) Then Begin EditInsertChar(K); Exit; End;
  Exit;
 End;
 { ===== HORS EDITION ===== }
 If K = #27 Then Begin
  If MenuOpen > 0 Then Begin
   MenuOpen := 0; NeedFullRedraw := True; Exit;
  End;
  If CurView <> VIEW_NAV Then Begin
   CurView := VIEW_NAV; NeedFullRedraw := True;
  End;
  Exit;
 End;
 If K = #0 Then Begin
  Case K2 Of
   #59: DoAction(ACT_HELP_TOPIC);        { F1 }
   #60: Begin                            { F2 : entrer en edition }
    If CurView = VIEW_DSHEET Then BeginEdit;
   End;
   #133: DoAction(ACT_VIEW_NAV);         { F11 }
   #71: If CurView = VIEW_DSHEET Then Begin CurFldIdx := 1; NeedGridRedraw := True; End; { Home }
   #79: If CurView = VIEW_DSHEET Then Begin                                              { End  }
    T := CurTable;
    If T <> Nil Then Begin CurFldIdx := T^.FldCount; NeedGridRedraw := True; End;
   End;
   #73: If CurView = VIEW_DSHEET Then Begin                                              { PgUp }
    CurRecIdx := CurRecIdx - DSheetVis;
    If CurRecIdx < 1 Then CurRecIdx := 1;
    NeedGridRedraw := True;
   End;
   #81: If CurView = VIEW_DSHEET Then Begin                                              { PgDn }
    T := CurTable;
    If T <> Nil Then Begin
     CurRecIdx := CurRecIdx + DSheetVis;
     If CurRecIdx > T^.RecCount Then CurRecIdx := T^.RecCount;
     NeedGridRedraw := True;
    End;
   End;
   #72: If CurView = VIEW_DSHEET Then ActionPrevRec;                                     { Up   }
   #80: If CurView = VIEW_DSHEET Then ActionNextRec;                                     { Down }
   #75: If CurView = VIEW_DSHEET Then Begin                                              { Left }
    If CurFldIdx > 1 Then Dec(CurFldIdx);
    NeedGridRedraw := True;
   End;
   #77: If CurView = VIEW_DSHEET Then Begin                                              { Right }
    T := CurTable;
    If T <> Nil Then If CurFldIdx < T^.FldCount Then Inc(CurFldIdx);
    NeedGridRedraw := True;
   End;
   #83: If CurView = VIEW_DSHEET Then ActionDelRec;                                      { Del   }
   #117:If CurView = VIEW_DSHEET Then Begin                                              { Ctrl+End  }
    T := CurTable;
    If T <> Nil Then Begin CurRecIdx := T^.RecCount; CurFldIdx := T^.FldCount; NeedGridRedraw := True; End;
   End;
   #119:If CurView = VIEW_DSHEET Then Begin                                              { Ctrl+Home }
    CurRecIdx := 1; CurFldIdx := 1; NeedGridRedraw := True;
   End;
   #68: ActionQuit;                       { F10 }
  End;
  Exit;
 End;
 If K = #13 Then Begin
  If CurView = VIEW_DSHEET Then Begin BeginEdit; Exit; End;
  If CurView = VIEW_NAV Then Begin ActionOpenSelectedObj; Exit; End;
 End;
 If K = #9 Then Begin
  If CurView = VIEW_DSHEET Then Begin
   T := CurTable;
   If T <> Nil Then Begin
    If CurFldIdx < T^.FldCount Then Inc(CurFldIdx)
    Else Begin
     CurFldIdx := 1;
     If CurRecIdx < T^.RecCount Then Inc(CurRecIdx);
    End;
    NeedGridRedraw := True;
   End;
   Exit;
  End;
 End;
 { Touches ascii / Ctrl combinations  }
 Case K Of
  #14:  DoAction(ACT_NEW);    { Ctrl+N }
  #15:  DoAction(ACT_OPEN);   { Ctrl+O }
  #19:  DoAction(ACT_SAVE);   { Ctrl+S }
  #16:  DoAction(ACT_PRINT);  { Ctrl+P }
  #26:  DoAction(ACT_UNDO);   { Ctrl+Z }
  #25:  DoAction(ACT_REDO);   { Ctrl+Y }
  #24:  DoAction(ACT_CUT);    { Ctrl+X }
  #3:   DoAction(ACT_COPY);   { Ctrl+C }
  #22:  DoAction(ACT_PASTE);  { Ctrl+V }
  #6:   DoAction(ACT_FIND);   { Ctrl+F }
 Else
  If (CurView = VIEW_DSHEET) And (K >= ' ') And (K <= #126) Then Begin
   BeginEdit;
   If EditMode Then Begin
    EditBuf := ''; EditCaret := 0;
    EditInsertChar(K);
   End;
  End;
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
   If EditMode Then NeedGridRedraw := True;
  End;
  UpdateMouse;
  UpdateHovers;
  If LeftPressed Then HandleMouseClick;
  If (CurView = VIEW_RELATIONS) And (RelDragTbl > 0) Then HandleRelationsDrag;
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
{                       PROGRAMME PRINCIPAL                              }
{ ====================================================================== }

Var
 CmdFName, CmdExt: String;
 CmdOk: Boolean;
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
 InitDatabase;
 If ParamCount >= 1 Then Begin
  CmdFName := ParamStr(1);
  CmdExt   := ExtOf(CmdFName);
  If CmdExt = 'MDB' Then CmdOk := LoadMdb(CmdFName)
  Else If CmdExt = 'SQL' Then CmdOk := LoadSql(CmdFName)
  Else Begin
   MessageBox('Ouvrir', 'Extension inconnue : ' + CmdExt);
   CmdOk := False;
  End;
  If CmdOk Then Begin
   DB.FileName := CmdFName;
   DB.Dirty := False;
   StatusMsg := 'Base chargee : ' + CmdFName;
  End
  Else Begin
   MessageBox('Ouvrir', 'Impossible de charger : ' + CmdFName);
   SeedSampleDatabase;
  End;
 End
 Else SeedSampleDatabase;
 ComputeNavLayout;

 CurView         := VIEW_NAV;
 NavSelObj       := 1;
 NavScroll       := 0;
 DSheetScroll    := 0;
 DSheetRowTop    := 0;
 MenuOpen        := 0;
 MenuHover       := 0;
 MenuItemHover   := 0;
 ToolHover       := 0;
 EditMode        := False;
 BlinkState      := True;
 Quitting        := False;
 StatusMsg       := 'Pret';
 UndoTop         := 0;
 RedoTop         := 0;
 DragCol         := 0;

 QSqlBuf         := '';
 QCaret          := 0;
 QFocus          := 0;
 QResColCount    := 0;
 QResRowCount    := 0;
 QResSelRow      := 1;
 QResSelCol      := 1;
 QResScroll      := 0;
 QResColScroll   := 0;
 QStatusMsg      := '';
 QStatusErr      := False;
 QDirty          := False;

 FormScroll      := 1;
 FormVisFlds     := 1;
 CurFrmIdx       := 0;
 CurRptIdx       := 0;

 RptPage         := 1;
 RptPageCount    := 1;
 RptRowsPerPage  := 1;

 RelLayoutDone   := False;
 RelSelIdx       := 0;
 RelDragTbl      := 0;
 RelDragDX       := 0;
 RelDragDY       := 0;

 MainLoop;

 UndoClear;
 FreeDatabase;
 HideMouse;
 CloseGraph;
End.
