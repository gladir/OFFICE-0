{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Microsoft Project
}

Program MSPROJECT;

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
  { Pas d'implementation pour Free Pascal }
 End;

 Procedure HideMouse;
 Begin
  { Pas d'implementation pour Free Pascal }
 End;
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
 TS_H          = 24;
 ROW_H         = 14;
 GRID_HDR_H    = 16;
 SPLIT_W       = 3;

 MAX_TASKS     = 2000;
 MAX_RESOURCES = 500;
 MAX_ASSIGN    = 4000;
 MAX_CALENDARS = 16;
 MAX_PRED      = 8;
 MAX_PICTURES  = 8;
 PIC_MAX_W     = 240;
 PIC_MAX_H     = 180;

 CLR_BLACK     = 0;  CLR_BLUE      = 1;  CLR_GREEN     = 2;  CLR_CYAN      = 3;
 CLR_RED       = 4;  CLR_MAGENTA   = 5;  CLR_BROWN     = 6;  CLR_LGRAY     = 7;
 CLR_DGRAY     = 8;  CLR_LBLUE     = 9;  CLR_LGREEN    = 10; CLR_LCYAN     = 11;
 CLR_LRED      = 12; CLR_LMAGENTA  = 13; CLR_YELLOW    = 14; CLR_WHITE     = 15;

 CLR_WIN_BG       = 7;
 CLR_WIN_TEXT     = 0;
 CLR_WIN_HI       = 15;
 CLR_WIN_LO       = 8;
 CLR_MENU_BG      = 7;
 CLR_MENU_FG      = 0;
 CLR_MENU_SEL_BG  = 1;
 CLR_MENU_SEL_FG  = 15;
 CLR_TOOL_BG      = 7;
 CLR_GRID_HDR_BG  = 8;
 CLR_GRID_HDR_FG  = 15;
 CLR_GRID_BG      = 15;
 CLR_GRID_ALT     = 7;
 CLR_GRID_TEXT    = 0;
 CLR_GRID_SEL_BG  = 1;
 CLR_GRID_SEL_FG  = 15;
 CLR_GRID_LINE    = 7;
 CLR_GANTT_BG     = 15;
 CLR_GANTT_HDR_BG = 8;
 CLR_GANTT_HDR_FG = 15;
 CLR_GANTT_GRID   = 7;
 CLR_GANTT_BAR    = 1;
 CLR_GANTT_SUM    = 0;
 CLR_GANTT_CRIT   = 4;
 CLR_GANTT_PROG   = 14;
 CLR_GANTT_MS     = 4;
 CLR_GANTT_LINK   = 8;
 CLR_GANTT_TODAY  = 4;
 CLR_STAT_BG      = 8;
 CLR_STAT_FG      = 15;
 CLR_DLG_BG       = 7;
 CLR_DLG_TITLE_BG = 1;
 CLR_DLG_TITLE_FG = 15;

 CT_ASAP = 0; CT_ALAP = 1; CT_MSO = 2; CT_MFO = 3;
 CT_SNET = 4; CT_FNET = 5; CT_SNLT = 6; CT_FNLT = 7;

 LT_FS = 0; LT_SS = 1; LT_FF = 2; LT_SF = 3;

 RT_WORK = 0; RT_MATERIAL = 1; RT_COST = 2;
 AC_START = 0; AC_PRORATED = 1; AC_END = 2;

 VIEW_GANTT = 0; VIEW_NETWORK = 1; VIEW_RESOURCE = 2;
 VIEW_USAGE = 3; VIEW_CALENDAR = 4;

 MAX_COLS = 16;

 FLD_ID = 1; FLD_IND = 2; FLD_NAME = 3; FLD_DUR = 4;
 FLD_START = 5; FLD_FINISH = 6; FLD_PRED = 7; FLD_RES = 8;
 FLD_PERCENT = 9; FLD_WBS = 10; FLD_COST = 11; FLD_WORK = 12;
 FLD_PRIO = 13; FLD_NOTES = 14;
 FLD_TSLACK = 15; FLD_FSLACK = 16; FLD_ES = 17; FLD_EF = 18;
 FLD_LS = 19; FLD_LF = 20; FLD_CRIT = 21;

 ACT_NONE = 0;
 ACT_NEW = 1;     ACT_OPEN = 2;    ACT_SAVE = 3;    ACT_SAVEAS = 4;
 ACT_CLOSE = 5;   ACT_PRINT = 6;   ACT_PROPS = 7;   ACT_QUIT = 8;
 ACT_UNDO = 10;   ACT_REDO = 11;   ACT_CUT = 12;    ACT_COPY = 13;
 ACT_PASTE = 14;  ACT_DELETE = 15; ACT_FIND = 16;   ACT_REPLACE = 17;
 ACT_GOTO = 18;
 ACT_VIEW_GANTT = 20; ACT_VIEW_NET = 21; ACT_VIEW_RES = 22;
 ACT_VIEW_USAGE = 23; ACT_VIEW_CAL = 24;
 ACT_ZOOM_IN = 25; ACT_ZOOM_OUT = 26; ACT_ZOOM_FIT = 27;
 ACT_INS_TASK = 30; ACT_INS_MS = 31;  ACT_INS_SUM = 32;
 ACT_INS_RES = 33;  ACT_INS_PIC = 34; ACT_INS_NOTE = 35; ACT_INS_COL = 36;
 ACT_FMT_FONT = 40; ACT_FMT_BAR = 41; ACT_FMT_TS = 42;
 ACT_FMT_GRID = 43; ACT_FMT_LAYOUT = 44;
 ACT_TOOL_OPT = 50; ACT_TOOL_RES = 51; ACT_TOOL_LEVEL = 52;
 ACT_TOOL_TRACK = 53; ACT_TOOL_BASE = 54;
 ACT_PROJ_INFO = 60; ACT_PROJ_CAL = 61; ACT_PROJ_STAT = 62; ACT_PROJ_FIELD = 63;
 ACT_WIN_NEW = 70; ACT_WIN_ARR = 71;
 ACT_HELP_TOPIC = 80; ACT_HELP_TUTOR = 81; ACT_HELP_ABOUT = 82;
 ACT_LINK = 90; ACT_UNLINK = 91; ACT_INDENT = 92; ACT_OUTDENT = 93;
 ACT_TASKINFO = 94; ACT_SCROLL_TASK = 95;
 ACT_RES_SHEET = 96;
 ACT_REPORTS    = 100;
 ACT_RPT_SUM    = 101;
 ACT_RPT_TASKS  = 102;
 ACT_RPT_CRIT   = 103;
 ACT_RPT_RES    = 104;
 ACT_RPT_COST   = 105;
 ACT_RPT_MS     = 106;

 ICO_NEW = 1; ICO_OPEN = 2; ICO_SAVE = 3; ICO_PRINT = 4;
 ICO_CUT = 5; ICO_COPY = 6; ICO_PASTE = 7;
 ICO_UNDO = 8; ICO_REDO = 9;
 ICO_LINK = 10; ICO_UNLINK = 11;
 ICO_INDENT = 12; ICO_OUT = 13;
 ICO_INS = 14; ICO_DEL = 15;
 ICO_INFO = 16; ICO_GOTO = 17;
 ICO_ZOOMIN = 18; ICO_ZOOMOT = 19;
 ICO_GANTT = 20; ICO_NET = 21; ICO_RES = 22;
 ICO_HELP = 23;

{ ====================================================================== }
{                       TYPES                                            }
{ ====================================================================== }

Type
 TDate = LongInt;

 TPredLink = Record
  TaskId   : Word;
  LinkType : Byte;
  Lag      : Integer;
 End;

 PTask = ^TTask;
 TTask = Record
  Id           : Word;
  OutlineLv    : Byte;
  IsSummary    : Boolean;
  IsMilestone  : Boolean;
  Critical     : Boolean;
  Collapsed    : Boolean;
  Name         : String[60];
  Duration     : LongInt;
  Start        : TDate;
  Finish       : TDate;
  ActualStart  : TDate;
  ActualFinish : TDate;
  PercentDone  : Byte;
  PercentWork  : Byte;
  Cost         : LongInt;
  Work         : LongInt;
  ConstraintTyp: Byte;
  ConstraintDt : TDate;
  Notes        : String[120];
  PredCount    : Byte;
  Pred         : Array[1..MAX_PRED] Of TPredLink;
  Calendar     : Byte;
  Priority     : Word;
  BaselineStart: TDate;
  BaselineFinish: TDate;
  BaselineDur  : LongInt;
  BaselineWork : LongInt;
  BaselineCost : LongInt;
  ActualDur    : LongInt;
  ActualWork   : LongInt;
  ActualCost   : LongInt;
  RemainingDur : LongInt;
  LevelDelay   : LongInt;
  WBS          : String[20];
  Resources    : String[60];
  EarlyStart   : TDate;
  EarlyFinish  : TDate;
  LateStart    : TDate;
  LateFinish   : TDate;
  TotalSlack   : LongInt;
  FreeSlack    : LongInt;
 End;

 PResource = ^TResource;
 TResource = Record
  Id        : Word;
  Name      : String[40];
  Initials  : String[8];
  Grp       : String[20];
  ResType   : Byte;
  MaxUnits  : Word;
  StdRate   : LongInt;
  OvtRate   : LongInt;
  CostPerUse: LongInt;
  Accrue    : Byte;
  Calendar  : Byte;
  Email     : String[40];
 End;

 PAssignment = ^TAssignment;
 TAssignment = Record
  TaskId : Word;
  ResId  : Word;
  Units  : Word;
  Work   : LongInt;
  Cost   : LongInt;
 End;

 TCalExc = Record D: TDate; IsWork: Boolean; End;

 PCalendar = ^TCalendar;
 TCalendar = Record
  Name      : String[20];
  WorkMask  : Byte;
  StartHour : Byte;
  EndHour   : Byte;
  ExcCount  : Word;
  Excs      : Array[1..32] Of TCalExc;
 End;

 TProject = Record
  Title       : String[60];
  Manager     : String[40];
  Company     : String[40];
  Subject     : String[60];
  Comments    : String[120];
  StartDate   : TDate;
  FinishDate  : TDate;
  StatusDate  : TDate;
  CurrentDt   : TDate;
  HoursPerDay : Byte;
  DaysPerWeek : Byte;
  HoursPerWeek: Word;
  DefCalendar : Byte;
  ScheduleFrom: Byte;
  TaskCount   : Integer;
  ResCount    : Integer;
  AsgCount    : Integer;
  CalCount    : Integer;
  Tasks       : Array[1..MAX_TASKS] Of PTask;
  Resources   : Array[1..MAX_RESOURCES] Of PResource;
  Assignments : Array[1..MAX_ASSIGN] Of PAssignment;
  Calendars   : Array[1..MAX_CALENDARS] Of PCalendar;
  FileName    : String[80];
  Dirty       : Boolean;
 End;

 PPicture = ^TPicture;
 TPicture = Record
  Format    : Byte;        { 1=BMP, 2=PCX, 3=GIF }
  Width     : Word;
  Height    : Word;
  AnchorTsk : Integer;     { task index this picture is anchored to, 0 = floating }
  X, Y      : Integer;     { client-area position when floating }
  FileName  : String[80];
  Pixels    : Pointer;     { Width*Height bytes, each = 0..15 VGA palette index }
 End;

 TMouseState = Record
  X       : LongInt;
  Y       : LongInt;
  B       : LongInt;
  Visible : Boolean;
 End;

 TMenuItem = Record
  Caption  : String[28];
  Shortcut : String[14];
  IsSep    : Boolean;
  Enabled  : Boolean;
  Action   : Integer;
 End;

 TMenu = Record
  Caption : String[16];
  Hotkey  : Char;
  X1, X2  : Integer;
  Count   : Integer;
  Items   : Array[1..24] Of TMenuItem;
 End;

 TToolBtn = Record
  X1, Y1, X2, Y2 : Integer;
  Icon           : Integer;
  Hint           : String[32];
  Action         : Integer;
  IsSep          : Boolean;
  Enabled        : Boolean;
 End;

 TGridCol = Record
  Title : String[16];
  Width : Integer;
  Field : Byte;
 End;

{ ====================================================================== }
{                       VARIABLES GLOBALES                               }
{ ====================================================================== }

Var
 Project       : TProject;
 Mouse         : TMouseState;
 LastClickB    : LongInt;
 Pictures      : Array[1..MAX_PICTURES] Of PPicture;
 PicCount      : Integer;

 Menus         : Array[1..9] Of TMenu;
 MenuCount     : Integer;
 MenuOpen      : Integer;
 MenuHover     : Integer;
 MenuItemHover : Integer;

 Tools         : Array[1..32] Of TToolBtn;
 ToolCount     : Integer;
 ToolHover     : Integer;

 CurView       : Byte;
 DayPx         : Integer;
 SplitX        : Integer;
 GridScrollX   : Integer;
 GridScrollY   : Integer;
 GanttOriginDt : TDate;
 CurTaskIdx    : Integer;
 CurColIdx     : Integer;

 NeedFullRedraw : Boolean;
 NeedGridRedraw : Boolean;
 NeedGanttRedraw: Boolean;
 NeedMenuRedraw : Boolean;
 NeedStatRedraw : Boolean;
 NeedDropRedraw : Boolean;

 Quitting      : Boolean;
 StatusMsg     : String;

 ColCount      : Integer;
 Cols          : Array[1..MAX_COLS] Of TGridCol;

 { Edition inline et interactions Phase 2 }
 EditMode      : Boolean;
 EditBuf       : String;
 EditCaret     : Integer;
 EditRow       : Integer;
 EditCol       : Integer;
 EditTickSave  : LongInt;
 BlinkState    : Boolean;

 DraggingSplit : Boolean;
 DragColIdx    : Integer;
 DragColStartX : Integer;
 DragColStartW : Integer;

 ClickPrevX    : LongInt;
 ClickPrevY    : LongInt;
 ClickPrevTick : LongInt;
 DoubleClicked : Boolean;

 TickCount     : LongInt;

 { Vues Phase 5 }
 NetScrollX    : Integer;
 NetScrollY    : Integer;
 UsageScrollX  : Integer;
 UsageScrollY  : Integer;
 UsageMode     : Byte;        { 0 = par tache, 1 = par ressource }
 CalMonth      : Integer;
 CalYear       : Integer;
 ResViewSelRow : Integer;
 ResViewCol    : Integer;
 ResViewScrollY: Integer;
 ResViewEdit   : Boolean;
 ResViewBuf    : String;
 ResViewCaret  : Integer;

{ ====================================================================== }
{                       UTILITAIRES                                      }
{ ====================================================================== }

Function IntToStr(N: LongInt): String;
Var S: String;
Begin Str(N, S); IntToStr := S; End;

Function StrToIntDef(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; C: Integer;
Begin Val(S, V, C); If C=0 Then StrToIntDef := V Else StrToIntDef := Def; End;

Function MinI(A, B: LongInt): LongInt;
Begin If A < B Then MinI := A Else MinI := B; End;

Function MaxI(A, B: LongInt): LongInt;
Begin If A > B Then MaxI := A Else MaxI := B; End;

Function AbsI(A: LongInt): LongInt;
Begin If A < 0 Then AbsI := -A Else AbsI := A; End;

Function TrimStr(S: String): String;
Var I, J: Integer;
Begin
 I := 1;
 While (I <= Length(S)) And (S[I] <= ' ') Do Inc(I);
 J := Length(S);
 While (J >= I) And (S[J] <= ' ') Do Dec(J);
 If J >= I Then TrimStr := Copy(S, I, J - I + 1) Else TrimStr := '';
End;

Function InRect(X, Y, X1, Y1, X2, Y2: Integer): Boolean;
Begin InRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2); End;

{ ====================================================================== }
{                       DATES                                            }
{ ====================================================================== }

Function DateToJDN(Y, M, D: Integer): TDate;
Var A, YY, MM: LongInt;
Begin
 A  := (14 - M) Div 12;
 YY := LongInt(Y) + 4800 - A;
 MM := M + 12*A - 3;
 DateToJDN := LongInt(D) + (153*MM + 2) Div 5 + 365*YY + YY Div 4
              - YY Div 100 + YY Div 400 - 32045;
End;

Procedure JDNToDate(JDN: TDate; Var Y, M, D: Integer);
Var A, B, C, DD, E, M2: LongInt;
Begin
 A  := JDN + 32044;
 B  := (4*A + 3) Div 146097;
 C  := A - (146097*B) Div 4;
 DD := (4*C + 3) Div 1461;
 E  := C - (1461*DD) Div 4;
 M2 := (5*E + 2) Div 153;
 D  := Integer(E - (153*M2 + 2) Div 5 + 1);
 M  := Integer(M2 + 3 - 12*(M2 Div 10));
 Y  := Integer(100*B + DD - 4800 + (M2 Div 10));
End;

Function DayOfWeek(JDN: TDate): Integer;
Begin
 DayOfWeek := Integer((JDN + 1) Mod 7);
End;

Function IsWeekDay(JDN: TDate): Boolean;
Var D: Integer;
Begin
 D := DayOfWeek(JDN);
 IsWeekDay := (D >= 1) And (D <= 5);
End;

Function ShortDateStr(JDN: TDate): String;
Var Y, M, D: Integer; Sd, Sm, Sy: String;
Begin
 If JDN <= 0 Then Begin ShortDateStr := ''; Exit; End;
 JDNToDate(JDN, Y, M, D);
 Str(D, Sd); If Length(Sd) < 2 Then Sd := '0' + Sd;
 Str(M, Sm); If Length(Sm) < 2 Then Sm := '0' + Sm;
 Str(Y Mod 100, Sy); If Length(Sy) < 2 Then Sy := '0' + Sy;
 ShortDateStr := Sd + '/' + Sm + '/' + Sy;
End;

Function MonthName(M: Integer): String;
Begin
 Case M Of
  1: MonthName := 'Jan';   2: MonthName := 'Fev';   3: MonthName := 'Mar';
  4: MonthName := 'Avr';   5: MonthName := 'Mai';   6: MonthName := 'Jun';
  7: MonthName := 'Jul';   8: MonthName := 'Aou';   9: MonthName := 'Sep';
  10: MonthName := 'Oct'; 11: MonthName := 'Nov';  12: MonthName := 'Dec';
 Else MonthName := '???';
 End;
End;

Function DayShortName(D: Integer): String;
Begin
 Case D Of
  0: DayShortName := 'D';   1: DayShortName := 'L';
  2: DayShortName := 'M';   3: DayShortName := 'M';
  4: DayShortName := 'J';   5: DayShortName := 'V';
  6: DayShortName := 'S';
 Else DayShortName := '?';
 End;
End;

{ ====================================================================== }
{                       SOURIS                                           }
{ ====================================================================== }

Procedure UpdateMouse;
Begin
 LastClickB := Mouse.B;
 GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
End;

Function LeftPressed: Boolean;
Begin LeftPressed := ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0); End;

Function LeftDown: Boolean;
Begin LeftDown := (Mouse.B And 1) <> 0; End;

Function RightPressed: Boolean;
Begin RightPressed := ((Mouse.B And 2) <> 0) And ((LastClickB And 2) = 0); End;

{ ====================================================================== }
{                       PRIMITIVES DE DESSIN                             }
{ ====================================================================== }

Procedure FillBox(X1, Y1, X2, Y2, Col: Integer);
Begin
 SetFillStyle(1, Col);
 Bar(X1, Y1, X2, Y2);
End;

Procedure FrameBox(X1, Y1, X2, Y2, Col: Integer);
Begin
 SetColor(Col);
 Rectangle(X1, Y1, X2, Y2);
End;

Procedure HLine(X1, X2, Y, Col: Integer);
Begin SetColor(Col); Line(X1, Y, X2, Y); End;

Procedure VLine(X, Y1, Y2, Col: Integer);
Begin SetColor(Col); Line(X, Y1, X, Y2); End;

Procedure DrawRaised(X1, Y1, X2, Y2, BgCol, HiCol, LoCol: Integer);
Begin
 FillBox(X1, Y1, X2, Y2, BgCol);
 HLine(X1, X2, Y1, HiCol);
 VLine(X1, Y1, Y2, HiCol);
 HLine(X1, X2, Y2, LoCol);
 VLine(X2, Y1, Y2, LoCol);
End;

Function ClipStr(S: String; MaxW: Integer): String;
Begin
 While (Length(S) > 0) And (TextWidth(S) > MaxW) Do S := Copy(S, 1, Length(S) - 1);
 ClipStr := S;
End;

{ ====================================================================== }
{                       ICONES VECTORIELLES                              }
{ ====================================================================== }

Procedure IconNew(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Rectangle(X + 3, Y + 2, X + 13, Y + 17);
 SetFillStyle(1, CLR_WHITE);
 Bar(X + 4, Y + 3, X + 12, Y + 16);
 SetColor(CLR_BLACK);
 Line(X + 10, Y + 2, X + 10, Y + 5);
 Line(X + 10, Y + 5, X + 13, Y + 5);
 Line(X + 5, Y + 8, X + 11, Y + 8);
 Line(X + 5, Y + 10, X + 11, Y + 10);
 Line(X + 5, Y + 12, X + 9, Y + 12);
End;

Procedure IconOpen(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_BROWN);
 Bar(X + 2, Y + 6, X + 15, Y + 16);
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 6, X + 15, Y + 16);
 Line(X + 2, Y + 6, X + 6, Y + 4);
 Line(X + 6, Y + 4, X + 9, Y + 4);
 Line(X + 9, Y + 4, X + 9, Y + 6);
 SetFillStyle(1, CLR_YELLOW);
 Bar(X + 4, Y + 8, X + 14, Y + 15);
 SetColor(CLR_BLACK);
 Rectangle(X + 4, Y + 8, X + 14, Y + 15);
End;

Procedure IconSave(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_BLUE);
 Bar(X + 2, Y + 2, X + 15, Y + 17);
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 2, X + 15, Y + 17);
 SetFillStyle(1, CLR_WHITE);
 Bar(X + 5, Y + 4, X + 13, Y + 9);
 SetColor(CLR_BLACK);
 Rectangle(X + 5, Y + 4, X + 13, Y + 9);
 Line(X + 11, Y + 5, X + 11, Y + 8);
 SetFillStyle(1, CLR_LGRAY);
 Bar(X + 4, Y + 11, X + 14, Y + 16);
 SetColor(CLR_BLACK);
 Rectangle(X + 4, Y + 11, X + 14, Y + 16);
End;

Procedure IconPrint(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LGRAY);
 Bar(X + 2, Y + 6, X + 15, Y + 13);
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 6, X + 15, Y + 13);
 SetFillStyle(1, CLR_WHITE);
 Bar(X + 4, Y + 2, X + 13, Y + 7);
 Rectangle(X + 4, Y + 2, X + 13, Y + 7);
 Bar(X + 4, Y + 11, X + 13, Y + 17);
 Rectangle(X + 4, Y + 11, X + 13, Y + 17);
End;

Procedure IconCut(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 3, X + 9, Y + 10);
 Line(X + 15, Y + 3, X + 9, Y + 10);
 Line(X + 9, Y + 10, X + 6, Y + 16);
 Line(X + 9, Y + 10, X + 12, Y + 16);
 Circle(X + 5, Y + 14, 2);
 Circle(X + 13, Y + 14, 2);
End;

Procedure IconCopy(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_WHITE);
 Bar(X + 2, Y + 2, X + 10, Y + 13);
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 2, X + 10, Y + 13);
 SetFillStyle(1, CLR_WHITE);
 Bar(X + 6, Y + 6, X + 14, Y + 17);
 Rectangle(X + 6, Y + 6, X + 14, Y + 17);
End;

Procedure IconPaste(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_BROWN);
 Bar(X + 3, Y + 4, X + 14, Y + 17);
 SetColor(CLR_BLACK);
 Rectangle(X + 3, Y + 4, X + 14, Y + 17);
 SetFillStyle(1, CLR_WHITE);
 Bar(X + 5, Y + 7, X + 12, Y + 16);
 Rectangle(X + 5, Y + 7, X + 12, Y + 16);
 SetFillStyle(1, CLR_LGRAY);
 Bar(X + 6, Y + 2, X + 11, Y + 5);
 Rectangle(X + 6, Y + 2, X + 11, Y + 5);
End;

Procedure IconUndo(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Arc(X + 9, Y + 11, 0, 180, 6);
 Line(X + 3, Y + 11, X + 6, Y + 8);
 Line(X + 3, Y + 11, X + 6, Y + 14);
End;

Procedure IconRedo(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Arc(X + 9, Y + 11, 0, 180, 6);
 Line(X + 15, Y + 11, X + 12, Y + 8);
 Line(X + 15, Y + 11, X + 12, Y + 14);
End;

Procedure IconLink(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 6, X + 8, Y + 12);
 Rectangle(X + 9, Y + 6, X + 15, Y + 12);
End;

Procedure IconUnlink(X, Y: Integer);
Begin
 IconLink(X, Y);
 SetColor(CLR_RED);
 Line(X + 2, Y + 17, X + 15, Y + 4);
End;

Procedure IconIndent(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 5, X + 14, Y + 5);
 Line(X + 6, Y + 9, X + 14, Y + 9);
 Line(X + 6, Y + 13, X + 14, Y + 13);
 Line(X + 2, Y + 17, X + 14, Y + 17);
 SetColor(CLR_BLUE);
 Line(X + 2, Y + 11, X + 5, Y + 9);
 Line(X + 2, Y + 11, X + 5, Y + 13);
End;

Procedure IconOutdent(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 5, X + 14, Y + 5);
 Line(X + 6, Y + 9, X + 14, Y + 9);
 Line(X + 6, Y + 13, X + 14, Y + 13);
 Line(X + 2, Y + 17, X + 14, Y + 17);
 SetColor(CLR_BLUE);
 Line(X + 8, Y + 11, X + 5, Y + 9);
 Line(X + 8, Y + 11, X + 5, Y + 13);
End;

Procedure IconInsTask(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LCYAN);
 Bar(X + 2, Y + 5, X + 15, Y + 9);
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 5, X + 15, Y + 9);
 SetColor(CLR_GREEN);
 Line(X + 8, Y + 12, X + 8, Y + 18);
 Line(X + 5, Y + 15, X + 11, Y + 15);
End;

Procedure IconDelTask(X, Y: Integer);
Begin
 SetFillStyle(1, CLR_LCYAN);
 Bar(X + 2, Y + 5, X + 15, Y + 9);
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 5, X + 15, Y + 9);
 SetColor(CLR_RED);
 Line(X + 4, Y + 13, X + 12, Y + 13);
 Line(X + 4, Y + 14, X + 12, Y + 14);
End;

Procedure IconInfo(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Circle(X + 9, Y + 10, 6);
 SetColor(CLR_WHITE);
 Line(X + 9, Y + 7, X + 9, Y + 8);
 Line(X + 9, Y + 10, X + 9, Y + 14);
End;

Procedure IconGoto(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Line(X + 3, Y + 10, X + 13, Y + 10);
 Line(X + 13, Y + 10, X + 9, Y + 6);
 Line(X + 13, Y + 10, X + 9, Y + 14);
End;

Procedure IconZoomIn(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Circle(X + 7, Y + 8, 4);
 Line(X + 10, Y + 11, X + 15, Y + 16);
 SetColor(CLR_BLUE);
 Line(X + 5, Y + 8, X + 9, Y + 8);
 Line(X + 7, Y + 6, X + 7, Y + 10);
End;

Procedure IconZoomOut(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Circle(X + 7, Y + 8, 4);
 Line(X + 10, Y + 11, X + 15, Y + 16);
 SetColor(CLR_BLUE);
 Line(X + 5, Y + 8, X + 9, Y + 8);
End;

Procedure IconGantt(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 2, Y + 17);
 Line(X + 2, Y + 17, X + 15, Y + 17);
 SetFillStyle(1, CLR_BLUE);
 Bar(X + 4, Y + 6, X + 9, Y + 8);
 Bar(X + 7, Y + 10, X + 12, Y + 12);
 Bar(X + 10, Y + 14, X + 15, Y + 16);
End;

Procedure IconNet(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 4, X + 6, Y + 9);
 Rectangle(X + 11, Y + 4, X + 15, Y + 9);
 Rectangle(X + 6, Y + 12, X + 12, Y + 17);
 Line(X + 6, Y + 6, X + 11, Y + 6);
 Line(X + 4, Y + 9, X + 7, Y + 12);
 Line(X + 13, Y + 9, X + 10, Y + 12);
End;

Procedure IconRes(X, Y: Integer);
Begin
 SetColor(CLR_BLACK);
 Circle(X + 9, Y + 6, 3);
 Line(X + 4, Y + 16, X + 9, Y + 9);
 Line(X + 9, Y + 9, X + 14, Y + 16);
 Line(X + 5, Y + 11, X + 13, Y + 11);
End;

Procedure IconHelp(X, Y: Integer);
Begin
 SetColor(CLR_BLUE);
 Circle(X + 9, Y + 10, 6);
 SetColor(CLR_BLACK);
 OutTextXY(X + 6, Y + 4, '?');
End;

Procedure DrawIcon(Code, X, Y: Integer);
Begin
 Case Code Of
  ICO_NEW:    IconNew(X, Y);
  ICO_OPEN:   IconOpen(X, Y);
  ICO_SAVE:   IconSave(X, Y);
  ICO_PRINT:  IconPrint(X, Y);
  ICO_CUT:    IconCut(X, Y);
  ICO_COPY:   IconCopy(X, Y);
  ICO_PASTE:  IconPaste(X, Y);
  ICO_UNDO:   IconUndo(X, Y);
  ICO_REDO:   IconRedo(X, Y);
  ICO_LINK:   IconLink(X, Y);
  ICO_UNLINK: IconUnlink(X, Y);
  ICO_INDENT: IconIndent(X, Y);
  ICO_OUT:    IconOutdent(X, Y);
  ICO_INS:    IconInsTask(X, Y);
  ICO_DEL:    IconDelTask(X, Y);
  ICO_INFO:   IconInfo(X, Y);
  ICO_GOTO:   IconGoto(X, Y);
  ICO_ZOOMIN: IconZoomIn(X, Y);
  ICO_ZOOMOT: IconZoomOut(X, Y);
  ICO_GANTT:  IconGantt(X, Y);
  ICO_NET:    IconNet(X, Y);
  ICO_RES:    IconRes(X, Y);
  ICO_HELP:   IconHelp(X, Y);
 End;
End;

{ ====================================================================== }
{                       MODELE DE DONNEES                                }
{ ====================================================================== }

Function NewTask: PTask;
Var T: PTask;
Begin
 GetMem(T, SizeOf(TTask));
 FillChar(T^, SizeOf(TTask), 0);
 T^.OutlineLv  := 1;
 T^.Duration   := 10;
 T^.Priority   := 500;
 T^.ConstraintTyp := CT_ASAP;
 NewTask := T;
End;

Function NewResource: PResource;
Var R: PResource;
Begin
 GetMem(R, SizeOf(TResource));
 FillChar(R^, SizeOf(TResource), 0);
 R^.MaxUnits := 100;
 R^.ResType  := RT_WORK;
 R^.Accrue   := AC_PRORATED;
 NewResource := R;
End;

Function NewCalendar: PCalendar;
Var C: PCalendar;
Begin
 GetMem(C, SizeOf(TCalendar));
 FillChar(C^, SizeOf(TCalendar), 0);
 C^.WorkMask := 62;
 C^.StartHour := 8;
 C^.EndHour   := 17;
 NewCalendar := C;
End;

Procedure FreeProject;
Var I: Integer;
Begin
 For I := 1 To Project.TaskCount Do
  If Project.Tasks[I] <> Nil Then Begin
   FreeMem(Project.Tasks[I], SizeOf(TTask));
   Project.Tasks[I] := Nil;
  End;
 For I := 1 To Project.ResCount Do
  If Project.Resources[I] <> Nil Then Begin
   FreeMem(Project.Resources[I], SizeOf(TResource));
   Project.Resources[I] := Nil;
  End;
 For I := 1 To Project.AsgCount Do
  If Project.Assignments[I] <> Nil Then Begin
   FreeMem(Project.Assignments[I], SizeOf(TAssignment));
   Project.Assignments[I] := Nil;
  End;
 For I := 1 To Project.CalCount Do
  If Project.Calendars[I] <> Nil Then Begin
   FreeMem(Project.Calendars[I], SizeOf(TCalendar));
   Project.Calendars[I] := Nil;
  End;
 Project.TaskCount := 0;
 Project.ResCount  := 0;
 Project.AsgCount  := 0;
 Project.CalCount  := 0;
End;

Procedure FreePictures;
Var I, Sz: Integer;
Begin
 For I := 1 To PicCount Do
  If Pictures[I] <> Nil Then Begin
   If Pictures[I]^.Pixels <> Nil Then Begin
    Sz := LongInt(Pictures[I]^.Width) * LongInt(Pictures[I]^.Height);
    If Sz < 1 Then Sz := 1;
    FreeMem(Pictures[I]^.Pixels, Sz);
   End;
   FreeMem(Pictures[I], SizeOf(TPicture));
   Pictures[I] := Nil;
  End;
 PicCount := 0;
End;

Procedure InitProject;
Var C: PCalendar;
Begin
 FreeProject;
 FreePictures;
 FillChar(Project.Tasks, SizeOf(Project.Tasks), 0);
 FillChar(Project.Resources, SizeOf(Project.Resources), 0);
 FillChar(Project.Assignments, SizeOf(Project.Assignments), 0);
 FillChar(Project.Calendars, SizeOf(Project.Calendars), 0);
 Project.Title    := 'Projet1';
 Project.Manager  := '';
 Project.Company  := '';
 Project.Subject  := '';
 Project.Comments := '';
 Project.HoursPerDay  := 8;
 Project.DaysPerWeek  := 5;
 Project.HoursPerWeek := 40;
 Project.ScheduleFrom := 0;
 Project.FileName := '';
 Project.Dirty    := False;
 Project.TaskCount:= 0;
 Project.ResCount := 0;
 Project.AsgCount := 0;
 Project.CalCount := 0;
 C := NewCalendar;
 C^.Name := 'Standard';
 Project.CalCount := 1;
 Project.Calendars[1] := C;
 Project.DefCalendar  := 1;
 Project.StartDate := DateToJDN(2026, 1, 5);
 Project.CurrentDt := Project.StartDate;
 Project.StatusDate := Project.StartDate;
 Project.FinishDate := Project.StartDate;
End;

Procedure AddTask(Const Name: String; OutLv: Byte; Dur: LongInt; St: TDate);
Var T: PTask;
Begin
 If Project.TaskCount >= MAX_TASKS Then Exit;
 T := NewTask;
 Inc(Project.TaskCount);
 T^.Id := Project.TaskCount;
 T^.OutlineLv := OutLv;
 T^.Name := Name;
 T^.Duration := Dur;
 T^.Start := St;
 T^.Finish := St + (Dur Div 10) - 1;
 If T^.Finish < T^.Start Then T^.Finish := T^.Start;
 If Dur = 0 Then Begin
  T^.IsMilestone := True;
  T^.Finish := T^.Start;
 End;
 Project.Tasks[Project.TaskCount] := T;
End;

Procedure AddResource(Const Name, Inits: String; Rate: LongInt);
Var R: PResource;
Begin
 If Project.ResCount >= MAX_RESOURCES Then Exit;
 R := NewResource;
 Inc(Project.ResCount);
 R^.Id := Project.ResCount;
 R^.Name := Name;
 R^.Initials := Inits;
 R^.StdRate := Rate;
 R^.OvtRate := (Rate * 3) Div 2;
 Project.Resources[Project.ResCount] := R;
End;

Procedure SetPredecessor(TaskIdx, PredTaskId: Integer; LinkTyp: Byte; Lag: Integer);
Var T: PTask; I: Integer;
Begin
 If (TaskIdx < 1) Or (TaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[TaskIdx];
 If T = Nil Then Exit;
 If T^.PredCount >= MAX_PRED Then Exit;
 Inc(T^.PredCount);
 I := T^.PredCount;
 T^.Pred[I].TaskId := PredTaskId;
 T^.Pred[I].LinkType := LinkTyp;
 T^.Pred[I].Lag := Lag;
End;

Procedure ComputeSummaries;
Var I, Lv, J: Integer; T, C: PTask; MinSt, MaxFn: TDate; MaxFin2: TDate;
Begin
 For I := Project.TaskCount DownTo 1 Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  T^.IsSummary := False;
  Lv := T^.OutlineLv;
  If I < Project.TaskCount Then Begin
   C := Project.Tasks[I + 1];
   If (C <> Nil) And (C^.OutlineLv > Lv) Then T^.IsSummary := True;
  End;
  If T^.IsSummary Then Begin
   MinSt := 0; MaxFn := 0;
   J := I + 1;
   While (J <= Project.TaskCount) And (Project.Tasks[J] <> Nil) And
         (Project.Tasks[J]^.OutlineLv > Lv) Do Begin
    C := Project.Tasks[J];
    If (MinSt = 0) Or (C^.Start < MinSt) Then MinSt := C^.Start;
    MaxFin2 := C^.Finish;
    If C^.IsMilestone Then MaxFin2 := C^.Start;
    If (MaxFn = 0) Or (MaxFin2 > MaxFn) Then MaxFn := MaxFin2;
    Inc(J);
   End;
   If MinSt > 0 Then T^.Start := MinSt;
   If MaxFn > 0 Then T^.Finish := MaxFn;
   T^.Duration := (T^.Finish - T^.Start + 1) * 10;
  End;
 End;
End;

{ ====================================================================== }
{                       MOTEUR CPM / CHEMIN CRITIQUE                     }
{ ====================================================================== }

Function TaskDurDays(T: PTask): LongInt;
Begin
 If T = Nil Then Begin TaskDurDays := 0; Exit; End;
 If T^.IsMilestone Or (T^.Duration <= 0) Then TaskDurDays := 0
 Else TaskDurDays := (T^.Duration + 9) Div 10;
End;

Function FindTaskByIdField(Id: Word): Integer;
Var I: Integer;
Begin
 FindTaskByIdField := 0;
 For I := 1 To Project.TaskCount Do
  If (Project.Tasks[I] <> Nil) And (Project.Tasks[I]^.Id = Id) Then Begin
   FindTaskByIdField := I; Exit;
  End;
End;

Procedure CPMForwardPass;
Var I, J, PIdx: Integer; T, U: PTask; ES, Cand: TDate; Dd, Du: LongInt;
Begin
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If T^.IsSummary Then Continue;
  ES := Project.StartDate;
  Dd := TaskDurDays(T);
  For J := 1 To T^.PredCount Do Begin
   PIdx := FindTaskByIdField(T^.Pred[J].TaskId);
   If PIdx = 0 Then Continue;
   U := Project.Tasks[PIdx];
   If U = Nil Then Continue;
   Du := TaskDurDays(U);
   Case T^.Pred[J].LinkType Of
    LT_FS: Cand := U^.EarlyFinish + 1 + T^.Pred[J].Lag;
    LT_SS: Cand := U^.EarlyStart + T^.Pred[J].Lag;
    LT_FF: Begin
            If Dd > 0 Then Cand := U^.EarlyFinish + T^.Pred[J].Lag - Dd + 1
            Else Cand := U^.EarlyFinish + T^.Pred[J].Lag;
           End;
    LT_SF: Begin
            If Dd > 0 Then Cand := U^.EarlyStart + T^.Pred[J].Lag - Dd + 1
            Else Cand := U^.EarlyStart + T^.Pred[J].Lag;
           End;
   Else Cand := U^.EarlyFinish + 1;
   End;
   If Cand > ES Then ES := Cand;
  End;
  Case T^.ConstraintTyp Of
   CT_MSO, CT_SNET: If T^.ConstraintDt > ES Then ES := T^.ConstraintDt;
   CT_MFO:          If T^.ConstraintDt - Dd + 1 > ES Then ES := T^.ConstraintDt - Dd + 1;
  End;
  T^.EarlyStart := ES;
  If Dd > 0 Then T^.EarlyFinish := ES + Dd - 1 Else T^.EarlyFinish := ES;
  T^.Start := T^.EarlyStart;
  T^.Finish := T^.EarlyFinish;
  If T^.IsMilestone Then T^.Finish := T^.Start;
 End;
End;

Procedure CPMBackwardPass;
Var I, J, SIdx: Integer; T, S: PTask;
    ProjFinish, LF, Cand: TDate; Dd, Ds: LongInt;
Begin
 ProjFinish := Project.StartDate;
 For I := 1 To Project.TaskCount Do
  If (Project.Tasks[I] <> Nil) And (Not Project.Tasks[I]^.IsSummary) Then
   If Project.Tasks[I]^.EarlyFinish > ProjFinish Then
    ProjFinish := Project.Tasks[I]^.EarlyFinish;
 Project.FinishDate := ProjFinish;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  T^.LateFinish := ProjFinish;
  T^.LateStart  := ProjFinish;
 End;
 For I := Project.TaskCount DownTo 1 Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If T^.IsSummary Then Continue;
  Dd := TaskDurDays(T);
  LF := ProjFinish;
  For J := 1 To Project.TaskCount Do Begin
   S := Project.Tasks[J];
   If (S = Nil) Or (S = T) Or S^.IsSummary Then Continue;
   For SIdx := 1 To S^.PredCount Do
    If S^.Pred[SIdx].TaskId = T^.Id Then Begin
     Ds := TaskDurDays(S);
     Case S^.Pred[SIdx].LinkType Of
      LT_FS: Cand := S^.LateStart - 1 - S^.Pred[SIdx].Lag;
      LT_SS: Begin
              If Dd > 0 Then Cand := S^.LateStart - S^.Pred[SIdx].Lag + Dd - 1
              Else Cand := S^.LateStart - S^.Pred[SIdx].Lag;
             End;
      LT_FF: Cand := S^.LateFinish - S^.Pred[SIdx].Lag;
      LT_SF: Begin
              If Ds > 0 Then Cand := S^.LateFinish - S^.Pred[SIdx].Lag - Ds + 1
              Else Cand := S^.LateFinish - S^.Pred[SIdx].Lag;
              If Dd > 0 Then Cand := Cand + Dd - 1;
             End;
     Else Cand := S^.LateStart - 1;
     End;
     If Cand < LF Then LF := Cand;
    End;
  End;
  Case T^.ConstraintTyp Of
   CT_MFO, CT_FNLT: If T^.ConstraintDt < LF Then LF := T^.ConstraintDt;
   CT_MSO:          If T^.ConstraintDt + Dd - 1 < LF Then LF := T^.ConstraintDt + Dd - 1;
  End;
  T^.LateFinish := LF;
  If Dd > 0 Then T^.LateStart := LF - Dd + 1 Else T^.LateStart := LF;
  T^.TotalSlack := T^.LateStart - T^.EarlyStart;
  T^.Critical   := T^.TotalSlack <= 0;
 End;
End;

Procedure CPMComputeFreeSlack;
Var I, J, SIdx: Integer; T, S: PTask;
    MinSuccES, Cand, Slack: TDate;
Begin
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If T^.IsSummary Then Begin T^.FreeSlack := 0; Continue; End;
  MinSuccES := -1;
  For J := 1 To Project.TaskCount Do Begin
   S := Project.Tasks[J];
   If (S = Nil) Or (S = T) Or S^.IsSummary Then Continue;
   For SIdx := 1 To S^.PredCount Do
    If S^.Pred[SIdx].TaskId = T^.Id Then Begin
     Case S^.Pred[SIdx].LinkType Of
      LT_FS: Cand := S^.EarlyStart - 1 - S^.Pred[SIdx].Lag;
      LT_SS: Cand := S^.EarlyStart - S^.Pred[SIdx].Lag - 1;
      LT_FF: Cand := S^.EarlyFinish - S^.Pred[SIdx].Lag;
      LT_SF: Cand := S^.EarlyStart - S^.Pred[SIdx].Lag;
     Else Cand := S^.EarlyStart - 1;
     End;
     If (MinSuccES < 0) Or (Cand < MinSuccES) Then MinSuccES := Cand;
    End;
  End;
  If MinSuccES < 0 Then Slack := T^.TotalSlack
  Else Slack := MinSuccES - T^.EarlyFinish;
  If Slack < 0 Then Slack := 0;
  T^.FreeSlack := Slack;
 End;
End;

Procedure CPMRecompute;
Begin
 If Project.TaskCount = 0 Then Exit;
 CPMForwardPass;
 ComputeSummaries;
 CPMBackwardPass;
 CPMComputeFreeSlack;
 ComputeSummaries;
End;

{ ====================================================================== }
{                       PHASE 6 : BASELINE / SUIVI / NIVELLEMENT         }
{ ====================================================================== }

Procedure ActionSaveBaseline;
Var I: Integer; T: PTask;
Begin
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  T^.BaselineStart  := T^.Start;
  T^.BaselineFinish := T^.Finish;
  T^.BaselineDur    := T^.Duration;
  T^.BaselineWork   := T^.Work;
  T^.BaselineCost   := T^.Cost;
 End;
 StatusMsg := 'Planning de base enregistre (' + IntToStr(Project.TaskCount) + ' taches)';
 NeedStatRedraw := True;
End;

Procedure ActionClearBaseline;
Var I: Integer; T: PTask;
Begin
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  T^.BaselineStart  := 0;
  T^.BaselineFinish := 0;
  T^.BaselineDur    := 0;
  T^.BaselineWork   := 0;
  T^.BaselineCost   := 0;
 End;
 StatusMsg := 'Planning de base efface';
 NeedStatRedraw := True;
End;

{ ---- Suivi : recalcule Actual/Remaining a partir de PercentDone ---- }
Procedure UpdateActualsFromPercent(T: PTask);
Var P: LongInt;
Begin
 If T = Nil Then Exit;
 If T^.IsSummary Then Exit;
 P := T^.PercentDone;
 If P < 0 Then P := 0;
 If P > 100 Then P := 100;
 T^.ActualDur    := (T^.Duration * P) Div 100;
 T^.RemainingDur := T^.Duration - T^.ActualDur;
 T^.ActualWork   := (T^.Work * P) Div 100;
 T^.ActualCost   := (T^.Cost * P) Div 100;
 If (P > 0) And (T^.ActualStart = 0) Then T^.ActualStart := T^.Start;
 If P >= 100 Then T^.ActualFinish := T^.Finish
  Else T^.ActualFinish := 0;
End;

Procedure RecomputeAllActuals;
Var I: Integer;
Begin
 For I := 1 To Project.TaskCount Do UpdateActualsFromPercent(Project.Tasks[I]);
End;

{ ---- Dialogue Suivi : modifier %, ActualStart, ActualFinish ---- }
Procedure DoTrackingDialog; Forward;

Procedure ActionUpdateProgress;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 DoTrackingDialog;
 RecomputeAllActuals;
 NeedFullRedraw := True;
End;

Procedure ActionMark100;
Var I: Integer; T: PTask;
Begin
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If T^.IsSummary Then Continue;
  If T^.Finish <= Project.StatusDate Then T^.PercentDone := 100;
 End;
 RecomputeAllActuals;
 StatusMsg := 'Taches terminees a la date d''etat marquees 100%';
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{   NIVELLEMENT DES RESSOURCES (Resource Leveling)                       }
{ ====================================================================== }

{ Charge journaliere = heures de travail allouees a la ressource ce jour }
Function DailyResLoad(ResIdx: Integer; D: TDate): LongInt;
Var I: Integer; T: PTask; H, Dd, Acc: LongInt; R: PResource;
Begin
 Acc := 0;
 DailyResLoad := 0;
 If (ResIdx < 1) Or (ResIdx > Project.ResCount) Then Exit;
 R := Project.Resources[ResIdx];
 If R = Nil Then Exit;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If T^.IsSummary Or T^.IsMilestone Then Continue;
  If (D < T^.Start) Or (D > T^.Finish) Then Continue;
  If Pos(R^.Initials, T^.Resources) = 0 Then Continue;
  Dd := (T^.Finish - T^.Start) + 1;
  If Dd < 1 Then Dd := 1;
  If T^.Work > 0 Then H := T^.Work Div Dd Else H := 8;
  Acc := Acc + H;
 End;
 DailyResLoad := Acc;
End;

{ Detecte la premiere surcharge et reporte la tache la plus longue }
Procedure ActionLevelResources;
Var Pass, I, J: Integer;
    T, T2: PTask; R: PResource;
    Day: TDate; Load, MaxAllowed: LongInt;
    Worst: Integer; WorstLen: LongInt;
    Conflicts: Integer;
Begin
 Conflicts := 0;
 For Pass := 1 To 50 Do Begin
  Worst := -1;
  WorstLen := 0;
  For I := 1 To Project.ResCount Do Begin
   R := Project.Resources[I];
   If R = Nil Then Continue;
   MaxAllowed := (LongInt(R^.MaxUnits) * 8) Div 100;
   If MaxAllowed < 1 Then MaxAllowed := 8;
   Day := Project.StartDate;
   If Project.FinishDate <= 0 Then Continue;
   While Day <= Project.FinishDate Do Begin
    If IsWeekDay(Day) Then Begin
     Load := DailyResLoad(I, Day);
     If Load > MaxAllowed Then Begin
      { trouve la plus grosse tache du jour qui utilise R }
      For J := 1 To Project.TaskCount Do Begin
       T := Project.Tasks[J];
       If T = Nil Then Continue;
       If T^.IsSummary Or T^.IsMilestone Then Continue;
       If (Day < T^.Start) Or (Day > T^.Finish) Then Continue;
       If Pos(R^.Initials, T^.Resources) = 0 Then Continue;
       If (T^.Duration > WorstLen) And (Day > T^.Start) Then Begin
        Worst := J; WorstLen := T^.Duration;
       End;
      End;
      If Worst > 0 Then Break;
     End;
    End;
    Inc(Day);
    If Worst > 0 Then Break;
   End;
   If Worst > 0 Then Break;
  End;
  If Worst <= 0 Then Break;
  { decale la tache "worst" d'un jour ouvrable }
  T2 := Project.Tasks[Worst];
  If T2 = Nil Then Break;
  Inc(T2^.Start);
  While Not IsWeekDay(T2^.Start) Do Inc(T2^.Start);
  T2^.Finish := T2^.Start + (T2^.Duration Div 10) - 1;
  Inc(T2^.LevelDelay);
  Inc(Conflicts);
 End;
 CPMRecompute;
 StatusMsg := 'Nivellement : ' + IntToStr(Conflicts) + ' decalage(s) applique(s)';
 NeedFullRedraw := True;
End;

Procedure ActionClearLeveling;
Var I: Integer; T: PTask;
Begin
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If T^.LevelDelay > 0 Then Begin
   T^.Start := T^.Start - T^.LevelDelay;
   T^.Finish := T^.Start + (T^.Duration Div 10) - 1;
   T^.LevelDelay := 0;
  End;
 End;
 CPMRecompute;
 StatusMsg := 'Decalages de nivellement supprimes';
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       PROJET D'EXEMPLE                                 }
{ ====================================================================== }

Procedure SampleProject;
Var S: TDate;
Begin
 InitProject;
 Project.Title := '';
 Project.Manager := 'S. Maltais';
 Project.Company := 'Gladir Inc.';
 Project.StartDate := DateToJDN(2026, 1, 5);
 S := Project.StartDate;

 AddResource('Architecte',     'AR', 9000);
 AddResource('Contremaitre',   'CM', 6500);
 AddResource('Charpentier',    'CH', 4500);
 AddResource('Electricien',    'EL', 5500);
 AddResource('Plombier',       'PL', 5500);
 AddResource('Peintre',        'PE', 3500);
 AddResource('Beton',          'BT', 0);

 AddTask('Construction maison',          1,   0, S);
 AddTask('Phase 1 - Planification',      2,   0, S);
 AddTask('Plans architecturaux',         3, 100, S);
 AddTask('Permis de construction',       3,  50, S + 10);
 AddTask('Selection entrepreneur',       3,  70, S + 14);
 AddTask('Debut chantier',               3,   0, S + 21);
 AddTask('Phase 2 - Fondations',         2,   0, S + 22);
 AddTask('Excavation',                   3,  50, S + 22);
 AddTask('Coffrage',                     3,  40, S + 27);
 AddTask('Coulee beton',                 3,  30, S + 31);
 AddTask('Sechage et controle',          3,  50, S + 34);
 AddTask('Phase 3 - Structure',          2,   0, S + 39);
 AddTask('Charpente murs',               3,  80, S + 39);
 AddTask('Toiture',                      3,  50, S + 47);
 AddTask('Fenetres et portes',           3,  30, S + 52);
 AddTask('Phase 4 - Mecanique',          2,   0, S + 55);
 AddTask('Plomberie',                    3,  60, S + 55);
 AddTask('Electricite',                  3,  70, S + 55);
 AddTask('Chauffage',                    3,  40, S + 62);
 AddTask('Inspection mecanique',         3,   0, S + 66);
 AddTask('Phase 5 - Finition',           2,   0, S + 67);
 AddTask('Isolation',                    3,  30, S + 67);
 AddTask('Cloisons seches',              3,  50, S + 70);
 AddTask('Peinture',                     3,  60, S + 75);
 AddTask('Planchers',                    3,  40, S + 81);
 AddTask('Armoires',                     3,  30, S + 85);
 AddTask('Phase 6 - Livraison',          2,   0, S + 88);
 AddTask('Nettoyage final',              3,  20, S + 88);
 AddTask('Inspection finale',            3,  10, S + 90);
 AddTask('Remise des clefs',             3,   0, S + 91);

 SetPredecessor( 4,  3, LT_FS, 0);
 SetPredecessor( 5,  4, LT_FS, 0);
 SetPredecessor( 6,  5, LT_FS, 0);
 SetPredecessor( 8,  6, LT_FS, 0);
 SetPredecessor( 9,  8, LT_FS, 0);
 SetPredecessor(10,  9, LT_FS, 0);
 SetPredecessor(11, 10, LT_FS, 0);
 SetPredecessor(13, 11, LT_FS, 0);
 SetPredecessor(14, 13, LT_FS, 0);
 SetPredecessor(15, 13, LT_FS, 0);
 SetPredecessor(17, 15, LT_FS, 0);
 SetPredecessor(18, 15, LT_FS, 0);
 SetPredecessor(19, 17, LT_FS, 0);
 SetPredecessor(20, 19, LT_FS, 0);
 SetPredecessor(22, 20, LT_FS, 0);
 SetPredecessor(23, 22, LT_FS, 0);
 SetPredecessor(24, 23, LT_FS, 0);
 SetPredecessor(25, 24, LT_FS, 0);
 SetPredecessor(26, 25, LT_FS, 0);
 SetPredecessor(28, 26, LT_FS, 0);
 SetPredecessor(29, 28, LT_FS, 0);
 SetPredecessor(30, 29, LT_FS, 0);

 Project.Tasks[3]^.Resources := 'Architecte';
 Project.Tasks[5]^.Resources := 'Architecte;Contremaitre';
 Project.Tasks[8]^.Resources := 'Contremaitre';
 Project.Tasks[9]^.Resources := 'Charpentier';
 Project.Tasks[10]^.Resources:= 'Beton';
 Project.Tasks[13]^.Resources:= 'Charpentier';
 Project.Tasks[14]^.Resources:= 'Charpentier';
 Project.Tasks[15]^.Resources:= 'Charpentier';
 Project.Tasks[17]^.Resources:= 'Plombier';
 Project.Tasks[18]^.Resources:= 'Electricien';
 Project.Tasks[19]^.Resources:= 'Plombier;Electricien';
 Project.Tasks[22]^.Resources:= 'Charpentier';
 Project.Tasks[23]^.Resources:= 'Charpentier';
 Project.Tasks[24]^.Resources:= 'Peintre';
 Project.Tasks[25]^.Resources:= 'Charpentier';
 Project.Tasks[26]^.Resources:= 'Charpentier';
 Project.Tasks[28]^.Resources:= 'Contremaitre';
 Project.Tasks[29]^.Resources:= 'Contremaitre';

 CPMRecompute;
 Project.FinishDate := Project.Tasks[1]^.Finish;
 Project.Dirty := False;
End;

{ ====================================================================== }
{                       COLONNES                                         }
{ ====================================================================== }

Procedure InitColumns;
Begin
 ColCount := 0;
 Inc(ColCount); Cols[ColCount].Title := 'ID';    Cols[ColCount].Width :=  24; Cols[ColCount].Field := FLD_ID;
 Inc(ColCount); Cols[ColCount].Title := ' ';     Cols[ColCount].Width :=  14; Cols[ColCount].Field := FLD_IND;
 Inc(ColCount); Cols[ColCount].Title := 'Nom de la tache'; Cols[ColCount].Width := 130; Cols[ColCount].Field := FLD_NAME;
 Inc(ColCount); Cols[ColCount].Title := 'Duree'; Cols[ColCount].Width :=  40; Cols[ColCount].Field := FLD_DUR;
 Inc(ColCount); Cols[ColCount].Title := 'Debut'; Cols[ColCount].Width :=  56; Cols[ColCount].Field := FLD_START;
 Inc(ColCount); Cols[ColCount].Title := 'Fin';   Cols[ColCount].Width :=  56; Cols[ColCount].Field := FLD_FINISH;
 Inc(ColCount); Cols[ColCount].Title := 'Pred.'; Cols[ColCount].Width :=  40; Cols[ColCount].Field := FLD_PRED;
 Inc(ColCount); Cols[ColCount].Title := 'Ressources'; Cols[ColCount].Width := 80; Cols[ColCount].Field := FLD_RES;
 Inc(ColCount); Cols[ColCount].Title := '%';     Cols[ColCount].Width :=  28; Cols[ColCount].Field := FLD_PERCENT;
End;

Function FieldStr(T: PTask; F: Byte): String;
Var S: String; I: Integer;
Begin
 S := '';
 Case F Of
  FLD_ID:      S := IntToStr(T^.Id);
  FLD_IND:     Begin
                If T^.IsMilestone Then S := '*'
                Else If T^.IsSummary Then S := '+'
                Else If T^.Notes <> '' Then S := 'i';
               End;
  FLD_NAME:    Begin
                For I := 1 To T^.OutlineLv - 1 Do S := S + '  ';
                S := S + T^.Name;
               End;
  FLD_DUR:     Begin
                If T^.Duration = 0 Then S := '0 j'
                Else If T^.Duration Mod 10 = 0 Then S := IntToStr(T^.Duration Div 10) + ' j'
                Else S := IntToStr(T^.Duration Div 10) + ',' +
                          IntToStr(T^.Duration Mod 10) + ' j';
               End;
  FLD_START:   S := ShortDateStr(T^.Start);
  FLD_FINISH:  S := ShortDateStr(T^.Finish);
  FLD_PRED:    Begin
                For I := 1 To T^.PredCount Do Begin
                 If S <> '' Then S := S + ';';
                 S := S + IntToStr(T^.Pred[I].TaskId);
                End;
               End;
  FLD_RES:     S := T^.Resources;
  FLD_PERCENT: S := IntToStr(T^.PercentDone) + '%';
  FLD_WBS:     S := T^.WBS;
  FLD_COST:    S := IntToStr(T^.Cost Div 100);
  FLD_WORK:    S := IntToStr(T^.Work Div 10) + ' h';
  FLD_PRIO:    S := IntToStr(T^.Priority);
  FLD_NOTES:   S := T^.Notes;
  FLD_TSLACK:  S := IntToStr(T^.TotalSlack) + ' j';
  FLD_FSLACK:  S := IntToStr(T^.FreeSlack) + ' j';
  FLD_ES:      S := ShortDateStr(T^.EarlyStart);
  FLD_EF:      S := ShortDateStr(T^.EarlyFinish);
  FLD_LS:      S := ShortDateStr(T^.LateStart);
  FLD_LF:      S := ShortDateStr(T^.LateFinish);
  FLD_CRIT:    If T^.Critical Then S := 'Oui' Else S := 'Non';
 End;
 FieldStr := S;
End;

{ ====================================================================== }
{                       AGENCEMENT                                       }
{ ====================================================================== }

Function MenuY1: Integer; Begin MenuY1 := 0; End;
Function MenuY2: Integer; Begin MenuY2 := MENU_H - 1; End;
Function ToolY1: Integer; Begin ToolY1 := MENU_H; End;
Function ToolY2: Integer; Begin ToolY2 := MENU_H + TOOL_H - 1; End;
Function WorkY1: Integer; Begin WorkY1 := MENU_H + TOOL_H; End;
Function WorkY2: Integer; Begin WorkY2 := SCREEN_H - STAT_H - 1; End;
Function StatY1: Integer; Begin StatY1 := SCREEN_H - STAT_H; End;
Function StatY2: Integer; Begin StatY2 := SCREEN_H - 1; End;

Function GridX1: Integer; Begin GridX1 := 0; End;
Function GridX2: Integer; Begin GridX2 := SplitX - 1; End;
Function GanttX1: Integer; Begin GanttX1 := SplitX + SPLIT_W; End;
Function GanttX2: Integer; Begin GanttX2 := SCREEN_W - 1; End;

Function GridHdrY1: Integer; Begin GridHdrY1 := WorkY1; End;
Function GridHdrY2: Integer; Begin GridHdrY2 := WorkY1 + GRID_HDR_H - 1; End;
Function GridBodyY1: Integer; Begin GridBodyY1 := WorkY1 + GRID_HDR_H; End;
Function GridBodyY2: Integer; Begin GridBodyY2 := WorkY2; End;

Function GanttHdrY1: Integer; Begin GanttHdrY1 := WorkY1; End;
Function GanttHdrY2: Integer; Begin GanttHdrY2 := WorkY1 + TS_H - 1; End;
Function GanttBodyY1: Integer; Begin GanttBodyY1 := WorkY1 + TS_H; End;
Function GanttBodyY2: Integer; Begin GanttBodyY2 := WorkY2; End;

Function VisibleRowCount: Integer;
Begin
 VisibleRowCount := (GridBodyY2 - GridBodyY1 + 1) Div ROW_H;
End;

{ ====================================================================== }
{                       MENU                                             }
{ ====================================================================== }

Procedure AddMenuItem(M: Integer; Const Cap, Sh: String; Sep: Boolean; Act: Integer);
Var I: Integer;
Begin
 If Menus[M].Count >= 24 Then Exit;
 Inc(Menus[M].Count);
 I := Menus[M].Count;
 Menus[M].Items[I].Caption := Cap;
 Menus[M].Items[I].Shortcut := Sh;
 Menus[M].Items[I].IsSep := Sep;
 Menus[M].Items[I].Enabled := True;
 Menus[M].Items[I].Action := Act;
End;

Procedure InitMenus;
Begin
 MenuCount := 0;

 Inc(MenuCount);
 Menus[MenuCount].Caption := '~F~ichier';
 Menus[MenuCount].Hotkey  := 'F';
 AddMenuItem(MenuCount, 'Nouveau',     'Ctrl+N', False, ACT_NEW);
 AddMenuItem(MenuCount, 'Ouvrir...',   'Ctrl+O', False, ACT_OPEN);
 AddMenuItem(MenuCount, 'Fermer',      '',       False, ACT_CLOSE);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Enregistrer', 'Ctrl+S', False, ACT_SAVE);
 AddMenuItem(MenuCount, 'Enregistrer sous...', '', False, ACT_SAVEAS);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Imprimer...', 'Ctrl+P', False, ACT_PRINT);
 AddMenuItem(MenuCount, 'Proprietes...','',      False, ACT_PROPS);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Quitter',     'Alt+F4', False, ACT_QUIT);

 Inc(MenuCount);
 Menus[MenuCount].Caption := '~E~dition';
 Menus[MenuCount].Hotkey  := 'E';
 AddMenuItem(MenuCount, 'Annuler',     'Ctrl+Z', False, ACT_UNDO);
 AddMenuItem(MenuCount, 'Retablir',    'Ctrl+Y', False, ACT_REDO);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Couper',      'Ctrl+X', False, ACT_CUT);
 AddMenuItem(MenuCount, 'Copier',      'Ctrl+C', False, ACT_COPY);
 AddMenuItem(MenuCount, 'Coller',      'Ctrl+V', False, ACT_PASTE);
 AddMenuItem(MenuCount, 'Supprimer',   'Suppr',  False, ACT_DELETE);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Lier',        'Ctrl+F2',False, ACT_LINK);
 AddMenuItem(MenuCount, 'Annuler le lien','',   False, ACT_UNLINK);

 Inc(MenuCount);
 Menus[MenuCount].Caption := '~A~ffichage';
 Menus[MenuCount].Hotkey  := 'A';
 AddMenuItem(MenuCount, 'Diagramme de Gantt', '', False, ACT_VIEW_GANTT);
 AddMenuItem(MenuCount, 'Reseau (PERT)',      '', False, ACT_VIEW_NET);
 AddMenuItem(MenuCount, 'Ressources',         '', False, ACT_VIEW_RES);
 AddMenuItem(MenuCount, 'Utilisation',        '', False, ACT_VIEW_USAGE);
 AddMenuItem(MenuCount, 'Calendrier',         '', False, ACT_VIEW_CAL);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Zoom avant',         '+', False, ACT_ZOOM_IN);
 AddMenuItem(MenuCount, 'Zoom arriere',       '-', False, ACT_ZOOM_OUT);
 AddMenuItem(MenuCount, 'Ajuster',            '*', False, ACT_ZOOM_FIT);

 Inc(MenuCount);
 Menus[MenuCount].Caption := '~I~nsertion';
 Menus[MenuCount].Hotkey  := 'I';
 AddMenuItem(MenuCount, 'Nouvelle tache',  'Inser', False, ACT_INS_TASK);
 AddMenuItem(MenuCount, 'Tache resume',    '',      False, ACT_INS_SUM);
 AddMenuItem(MenuCount, 'Jalon',           '',      False, ACT_INS_MS);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Ressource...',    '',      False, ACT_INS_RES);
 AddMenuItem(MenuCount, 'Colonne...',      '',      False, ACT_INS_COL);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Image...',        '',      False, ACT_INS_PIC);
 AddMenuItem(MenuCount, 'Note...',         '',      False, ACT_INS_NOTE);

 Inc(MenuCount);
 Menus[MenuCount].Caption := 'F~o~rmat';
 Menus[MenuCount].Hotkey  := 'O';
 AddMenuItem(MenuCount, 'Police...',         '', False, ACT_FMT_FONT);
 AddMenuItem(MenuCount, 'Barre de Gantt...', '', False, ACT_FMT_BAR);
 AddMenuItem(MenuCount, 'Echelle de temps','',   False, ACT_FMT_TS);
 AddMenuItem(MenuCount, 'Quadrillage...',    '', False, ACT_FMT_GRID);
 AddMenuItem(MenuCount, 'Disposition...',    '', False, ACT_FMT_LAYOUT);

 Inc(MenuCount);
 Menus[MenuCount].Caption := 'Ou~t~ils';
 Menus[MenuCount].Hotkey  := 'T';
 AddMenuItem(MenuCount, 'Ressources...',     '', False, ACT_TOOL_RES);
 AddMenuItem(MenuCount, 'Nivellement...',    '', False, ACT_TOOL_LEVEL);
 AddMenuItem(MenuCount, 'Suivi...',          '', False, ACT_TOOL_TRACK);
 AddMenuItem(MenuCount, 'Planning de base',  '', False, ACT_TOOL_BASE);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Options...',        '', False, ACT_TOOL_OPT);

 Inc(MenuCount);
 Menus[MenuCount].Caption := '~P~rojet';
 Menus[MenuCount].Hotkey  := 'P';
 AddMenuItem(MenuCount, 'Infos du projet...','', False, ACT_PROJ_INFO);
 AddMenuItem(MenuCount, 'Calendriers...',    '', False, ACT_PROJ_CAL);
 AddMenuItem(MenuCount, 'Statistiques...',   '', False, ACT_PROJ_STAT);
 AddMenuItem(MenuCount, 'Champs personnalises','', False, ACT_PROJ_FIELD);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'Infos sur la tache','Maj+F2', False, ACT_TASKINFO);
 AddMenuItem(MenuCount, 'Atteindre la tache','Ctrl+G', False, ACT_SCROLL_TASK);
 AddMenuItem(MenuCount, 'Abaisser',          'Alt+Droite', False, ACT_INDENT);
 AddMenuItem(MenuCount, 'Relever',           'Alt+Gauche', False, ACT_OUTDENT);

 Inc(MenuCount);
 Menus[MenuCount].Caption := 'Fe~n~etre';
 Menus[MenuCount].Hotkey  := 'N';
 AddMenuItem(MenuCount, 'Nouvelle fenetre', '', False, ACT_WIN_NEW);
 AddMenuItem(MenuCount, 'Reorganiser',      '', False, ACT_WIN_ARR);

 Inc(MenuCount);
 Menus[MenuCount].Caption := '~?~';
 Menus[MenuCount].Hotkey  := '?';
 AddMenuItem(MenuCount, 'Rubriques d''aide','F1', False, ACT_HELP_TOPIC);
 AddMenuItem(MenuCount, 'Tutoriel',         '',  False, ACT_HELP_TUTOR);
 AddMenuItem(MenuCount, '-', '', True, 0);
 AddMenuItem(MenuCount, 'A propos...',      '',  False, ACT_HELP_ABOUT);
End;

Function MenuCaptionWidth(Const S: String): Integer;
Var I: Integer; T: String;
Begin
 T := '';
 For I := 1 To Length(S) Do If S[I] <> '~' Then T := T + S[I];
 MenuCaptionWidth := TextWidth(T) + 12;
End;

Procedure LayoutMenus;
Var I, X: Integer;
Begin
 X := 4;
 For I := 1 To MenuCount Do Begin
  Menus[I].X1 := X;
  Menus[I].X2 := X + MenuCaptionWidth(Menus[I].Caption);
  X := Menus[I].X2 + 2;
 End;
End;

Procedure DrawMenuCaption(X, Y: Integer; Const S: String; Fg: Integer);
Var I, Cx, W, H: Integer; Ch: String[1]; Under: Boolean;
Begin
 Cx := X;
 Under := False;
 SetColor(Fg);
 I := 1;
 H := TextHeight('A');
 While I <= Length(S) Do Begin
  If S[I] = '~' Then Begin Under := Not Under; Inc(I); Continue; End;
  Ch := S[I];
  W := TextWidth(Ch);
  OutTextXY(Cx, Y, Ch);
  If Under Then Line(Cx, Y + H + 1, Cx + W - 1, Y + H + 1);
  Cx := Cx + W;
  Inc(I);
 End;
End;

Procedure DrawMenuBar;
Var I: Integer; Bg, Fg: Integer;
Begin
 HideMouse;
 FillBox(0, MenuY1, SCREEN_W - 1, MenuY2, CLR_MENU_BG);
 HLine(0, SCREEN_W - 1, MenuY2, CLR_WIN_LO);
 For I := 1 To MenuCount Do Begin
  If I = MenuOpen Then Begin Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG; End
  Else If I = MenuHover Then Begin Bg := CLR_DGRAY; Fg := CLR_WHITE; End
  Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
  FillBox(Menus[I].X1, MenuY1 + 1, Menus[I].X2, MenuY2 - 1, Bg);
  DrawMenuCaption(Menus[I].X1 + 6, MenuY1 + 3, Menus[I].Caption, Fg);
 End;
 SetColor(CLR_MENU_FG);
 OutTextXY(SCREEN_W - TextWidth(Project.Title) - 8, MenuY1 + 3, Project.Title);
 ShowMouse;
End;

Function MenuAtX(X: Integer): Integer;
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
 W := 110;
 For I := 1 To Menus[M].Count Do Begin
  S := Menus[M].Items[I].Caption + '   ' + Menus[M].Items[I].Shortcut;
  Tw := TextWidth(S) + 26;
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
 FillBox(DropX + 3, DropY + DropH, DropX + DropW + 3, DropY + DropH + 2, CLR_BLACK);
 FillBox(DropX + DropW, DropY + 3, DropX + DropW + 2, DropY + DropH + 2, CLR_BLACK);
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
    OutTextXY(DropX + DropW - TextWidth(S) - 6, Y + 2, S);
   End;
  End;
  Y := Y + Ih;
 End;
 ShowMouse;
End;

Function DropItemAtY(M, Y: Integer): Integer;
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
{                       BARRE D'OUTILS                                   }
{ ====================================================================== }

Procedure AddTool(Icon: Integer; Const Hint: String; Action: Integer);
Begin
 If ToolCount >= 32 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].Icon := Icon;
 Tools[ToolCount].Hint := Hint;
 Tools[ToolCount].Action := Action;
 Tools[ToolCount].IsSep := False;
 Tools[ToolCount].Enabled := True;
End;

Procedure AddToolSep;
Begin
 If ToolCount >= 32 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].IsSep := True;
 Tools[ToolCount].Enabled := False;
End;

Procedure InitTools;
Var I, X, Y: Integer;
Begin
 ToolCount := 0;
 AddTool(ICO_NEW,   'Nouveau projet',         ACT_NEW);
 AddTool(ICO_OPEN,  'Ouvrir un projet...',    ACT_OPEN);
 AddTool(ICO_SAVE,  'Enregistrer',            ACT_SAVE);
 AddTool(ICO_PRINT, 'Imprimer',               ACT_PRINT);
 AddToolSep;
 AddTool(ICO_CUT,   'Couper',                 ACT_CUT);
 AddTool(ICO_COPY,  'Copier',                 ACT_COPY);
 AddTool(ICO_PASTE, 'Coller',                 ACT_PASTE);
 AddToolSep;
 AddTool(ICO_UNDO,  'Annuler',                ACT_UNDO);
 AddTool(ICO_REDO,  'Retablir',               ACT_REDO);
 AddToolSep;
 AddTool(ICO_INS,   'Inserer une tache',      ACT_INS_TASK);
 AddTool(ICO_DEL,   'Supprimer la tache',     ACT_DELETE);
 AddTool(ICO_LINK,  'Lier les taches',        ACT_LINK);
 AddTool(ICO_UNLINK,'Annuler le lien',        ACT_UNLINK);
 AddTool(ICO_OUT,   'Relever',                ACT_OUTDENT);
 AddTool(ICO_INDENT,'Abaisser',               ACT_INDENT);
 AddToolSep;
 AddTool(ICO_INFO,  'Infos sur la tache',     ACT_TASKINFO);
 AddTool(ICO_GOTO,  'Atteindre la tache',     ACT_SCROLL_TASK);
 AddToolSep;
 AddTool(ICO_GANTT, 'Diagramme de Gantt',     ACT_VIEW_GANTT);
 AddTool(ICO_NET,   'Reseau PERT',            ACT_VIEW_NET);
 AddTool(ICO_RES,   'Tableau des ressources', ACT_VIEW_RES);
 AddToolSep;
 AddTool(ICO_ZOOMIN,'Zoom avant',             ACT_ZOOM_IN);
 AddTool(ICO_ZOOMOT,'Zoom arriere',           ACT_ZOOM_OUT);
 AddToolSep;
 AddTool(ICO_HELP,  'Aide',                   ACT_HELP_TOPIC);

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
 FillBox(0, ToolY1, SCREEN_W - 1, ToolY2, CLR_TOOL_BG);
 HLine(0, SCREEN_W - 1, ToolY1, CLR_WIN_HI);
 HLine(0, SCREEN_W - 1, ToolY2, CLR_WIN_LO);
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   VLine((Tools[I].X1 + Tools[I].X2) Div 2, Tools[I].Y1 + 1,
         Tools[I].Y2 - 1, CLR_WIN_LO);
   VLine((Tools[I].X1 + Tools[I].X2) Div 2 + 1, Tools[I].Y1 + 1,
         Tools[I].Y2 - 1, CLR_WIN_HI);
  End
  Else Begin
   If I = ToolHover Then
    DrawRaised(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2,
               CLR_TOOL_BG, CLR_WIN_HI, CLR_WIN_LO);
   DrawIcon(Tools[I].Icon, Tools[I].X1, Tools[I].Y1);
  End;
 End;
 ShowMouse;
End;

Function ToolAtXY(X, Y: Integer): Integer;
Var I: Integer;
Begin
 ToolAtXY := 0;
 If (Y < ToolY1) Or (Y > ToolY2) Then Exit;
 For I := 1 To ToolCount Do
  If (Not Tools[I].IsSep) And InRect(X, Y, Tools[I].X1, Tools[I].Y1,
       Tools[I].X2, Tools[I].Y2) Then Begin
   ToolAtXY := I; Exit;
  End;
End;

{ ====================================================================== }
{                       BARRE D'ETAT                                     }
{ ====================================================================== }

Procedure DrawStatusBar;
Var S: String;
Begin
 HideMouse;
 FillBox(0, StatY1, SCREEN_W - 1, StatY2, CLR_STAT_BG);
 HLine(0, SCREEN_W - 1, StatY1, CLR_WIN_HI);
 SetColor(CLR_STAT_FG);
 If StatusMsg <> '' Then S := StatusMsg
 Else S := 'Pret    Taches: ' + IntToStr(Project.TaskCount) +
           '    Ressources: ' + IntToStr(Project.ResCount) +
           '    Debut: ' + ShortDateStr(Project.StartDate) +
           '    Fin: ' + ShortDateStr(Project.FinishDate);
 OutTextXY(4, StatY1 + 3, S);
 Case CurView Of
  VIEW_GANTT:    S := 'Gantt';
  VIEW_NETWORK:  S := 'Reseau';
  VIEW_RESOURCE: S := 'Ressources';
  VIEW_USAGE:    S := 'Utilisation';
  VIEW_CALENDAR: S := 'Calendrier';
 Else S := '';
 End;
 OutTextXY(SCREEN_W - TextWidth(S) - 6, StatY1 + 3, S);
 ShowMouse;
End;

{ ====================================================================== }
{                       GRILLE DES TACHES                                }
{ ====================================================================== }

Procedure DrawGridHeader;
Var I, X, W, Bg: Integer;
Begin
 X := GridX1 - GridScrollX;
 For I := 1 To ColCount Do Begin
  W := Cols[I].Width;
  If (X + W >= GridX1) And (X <= GridX2) Then Begin
   If I = CurColIdx Then Bg := CLR_BLUE Else Bg := CLR_GRID_HDR_BG;
   DrawRaised(MaxI(X, GridX1), GridHdrY1, MinI(X + W - 1, GridX2),
              GridHdrY2, Bg, CLR_WIN_HI, CLR_BLACK);
   SetColor(CLR_GRID_HDR_FG);
   OutTextXY(MaxI(X + 3, GridX1 + 3), GridHdrY1 + 3,
             ClipStr(Cols[I].Title, W - 6));
  End;
  X := X + W;
 End;
End;

Procedure DrawGridRow(RowIdx, TaskIdx: Integer);
Var Y, X, W, I: Integer; Bg, Fg: Integer; T: PTask; S: String;
Begin
 Y := GridBodyY1 + RowIdx * ROW_H;
 If Y + ROW_H - 1 > GridBodyY2 Then Exit;
 If (TaskIdx < 1) Or (TaskIdx > Project.TaskCount) Then Begin
  FillBox(GridX1, Y, GridX2, Y + ROW_H - 1, CLR_GRID_BG);
  Exit;
 End;
 T := Project.Tasks[TaskIdx];
 If T = Nil Then Exit;
 If TaskIdx = CurTaskIdx Then Begin Bg := CLR_GRID_SEL_BG; Fg := CLR_GRID_SEL_FG; End
 Else Begin Bg := CLR_GRID_BG; Fg := CLR_GRID_TEXT; End;
 If (T^.Critical) And (Not T^.IsSummary) And (TaskIdx <> CurTaskIdx) Then Fg := CLR_RED;
 FillBox(GridX1, Y, GridX2, Y + ROW_H - 1, Bg);
 X := GridX1 - GridScrollX;
 For I := 1 To ColCount Do Begin
  W := Cols[I].Width;
  S := FieldStr(T, Cols[I].Field);
  If (X + W >= GridX1) And (X <= GridX2) Then Begin
   SetColor(Fg);
   OutTextXY(MaxI(X + 3, GridX1 + 3), Y + 2, ClipStr(S, W - 6));
   VLine(MinI(X + W - 1, GridX2), Y, Y + ROW_H - 1, CLR_GRID_LINE);
  End;
  X := X + W;
 End;
 HLine(GridX1, GridX2, Y + ROW_H - 1, CLR_GRID_LINE);
End;

Procedure DrawGrid;
Var I, Visible: Integer;
Begin
 HideMouse;
 FillBox(GridX1, GridHdrY1, GridX2, GridBodyY2, CLR_GRID_BG);
 DrawGridHeader;
 Visible := VisibleRowCount;
 For I := 0 To Visible - 1 Do DrawGridRow(I, I + 1 + GridScrollY);
 ShowMouse;
End;

{ ====================================================================== }
{                       DIAGRAMME DE GANTT                               }
{ ====================================================================== }

Function DateToX(D: TDate): Integer;
Begin
 DateToX := GanttX1 + Integer((D - GanttOriginDt) * LongInt(DayPx));
End;

Procedure DrawGanttHeader;
Var D: TDate; X, Y, Y2, Y3: Integer; Y0, M0, D0: Integer; Lab: String;
    PrevMonth, PrevYear: Integer;
Begin
 Y := GanttHdrY1;
 Y2 := Y + 11;
 Y3 := Y + TS_H - 1;
 FillBox(GanttX1, Y, GanttX2, Y3, CLR_GANTT_HDR_BG);
 D := GanttOriginDt;
 PrevMonth := -1; PrevYear := -1;
 X := GanttX1;
 While X < GanttX2 Do Begin
  JDNToDate(D, Y0, M0, D0);
  If DayPx >= 12 Then Begin
   SetColor(CLR_GANTT_HDR_FG);
   Lab := IntToStr(D0);
   OutTextXY(X + (DayPx - TextWidth(Lab)) Div 2, Y2 + 3, Lab);
  End
  Else If DayPx >= 4 Then Begin
   Lab := DayShortName(DayOfWeek(D));
   SetColor(CLR_GANTT_HDR_FG);
   OutTextXY(X + (DayPx - TextWidth(Lab)) Div 2, Y2 + 3, Lab);
  End;
  If (M0 <> PrevMonth) Or (Y0 <> PrevYear) Then Begin
   If PrevMonth <> -1 Then VLine(X, Y, Y2, CLR_GANTT_HDR_FG);
   Lab := MonthName(M0) + ' ' + IntToStr(Y0);
   SetColor(CLR_GANTT_HDR_FG);
   OutTextXY(X + 3, Y + 2, Lab);
   PrevMonth := M0; PrevYear := Y0;
  End;
  VLine(X, Y2, Y3, CLR_WIN_LO);
  Inc(X, DayPx);
  Inc(D);
 End;
 HLine(GanttX1, GanttX2, Y2, CLR_GANTT_HDR_FG);
 HLine(GanttX1, GanttX2, Y3, CLR_WIN_LO);
End;

Procedure DrawGanttGrid;
Var X, Y: Integer; D: TDate;
Begin
 D := GanttOriginDt;
 X := GanttX1;
 While X < GanttX2 Do Begin
  If (Not IsWeekDay(D)) And (DayPx >= 3) Then
   FillBox(X, GanttBodyY1, X + DayPx - 1, GanttBodyY2, CLR_GRID_ALT);
  If DayPx >= 8 Then VLine(X, GanttBodyY1, GanttBodyY2, CLR_GANTT_GRID);
  Inc(X, DayPx);
  Inc(D);
 End;
 If Project.CurrentDt >= GanttOriginDt Then Begin
  X := DateToX(Project.CurrentDt);
  If (X >= GanttX1) And (X <= GanttX2) Then
   VLine(X, GanttBodyY1, GanttBodyY2, CLR_GANTT_TODAY);
 End;
 For Y := 0 To VisibleRowCount Do
  HLine(GanttX1, GanttX2, GanttBodyY1 + Y * ROW_H + ROW_H - 1, CLR_GANTT_GRID);
End;

Procedure DrawGanttBar(RowIdx, TaskIdx: Integer);
Var T: PTask; Y, BarY1, BarY2, X1, X2, ProgX, Cx, Cy: Integer;
Begin
 If (TaskIdx < 1) Or (TaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[TaskIdx];
 If T = Nil Then Exit;
 Y := GanttBodyY1 + RowIdx * ROW_H;
 If (Y + ROW_H - 1 > GanttBodyY2) Or (Y < GanttBodyY1) Then Exit;
 X1 := DateToX(T^.Start);
 X2 := DateToX(T^.Finish + 1) - 1;
 If T^.IsMilestone Then Begin
  Cx := DateToX(T^.Start) + DayPx Div 2;
  Cy := Y + ROW_H Div 2;
  SetColor(CLR_GANTT_MS);
  SetFillStyle(1, CLR_GANTT_MS);
  Line(Cx - 4, Cy, Cx, Cy - 4);
  Line(Cx, Cy - 4, Cx + 4, Cy);
  Line(Cx + 4, Cy, Cx, Cy + 4);
  Line(Cx, Cy + 4, Cx - 4, Cy);
  FloodFill(Cx, Cy, CLR_GANTT_MS);
  Exit;
 End;
 If X2 < GanttX1 Then Exit;
 If X1 > GanttX2 Then Exit;
 If X1 < GanttX1 Then X1 := GanttX1;
 If X2 > GanttX2 Then X2 := GanttX2;
 If T^.IsSummary Then Begin
  BarY1 := Y + 2; BarY2 := Y + 6;
  FillBox(X1, BarY1, X2, BarY2, CLR_GANTT_SUM);
  SetColor(CLR_GANTT_SUM);
  Line(X1, BarY2, X1 + 3, BarY2 + 3);
  Line(X1, BarY2, X1, BarY2 + 3);
  Line(X1, BarY2 + 3, X1 + 3, BarY2 + 3);
  Line(X2, BarY2, X2 - 3, BarY2 + 3);
  Line(X2, BarY2, X2, BarY2 + 3);
  Line(X2, BarY2 + 3, X2 - 3, BarY2 + 3);
 End
 Else Begin
  BarY1 := Y + 3; BarY2 := Y + ROW_H - 4;
  If T^.Critical Then FillBox(X1, BarY1, X2, BarY2, CLR_GANTT_CRIT)
  Else FillBox(X1, BarY1, X2, BarY2, CLR_GANTT_BAR);
  FrameBox(X1, BarY1, X2, BarY2, CLR_BLACK);
  If T^.PercentDone > 0 Then Begin
   ProgX := X1 + Integer(LongInt(X2 - X1) * LongInt(T^.PercentDone) Div 100);
   FillBox(X1 + 1, BarY1 + 2, ProgX, BarY2 - 2, CLR_GANTT_PROG);
  End;
 End;
End;

Procedure DrawGanttLinks;
Var I, J, Vis, RowSrc, RowDst: Integer; T, U: PTask;
    Xs, Xd, Ys, Yd, XMid: Integer;
Begin
 Vis := VisibleRowCount;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  For J := 1 To T^.PredCount Do Begin
   If (T^.Pred[J].TaskId < 1) Or (T^.Pred[J].TaskId > Project.TaskCount) Then Continue;
   U := Project.Tasks[T^.Pred[J].TaskId];
   If U = Nil Then Continue;
   RowSrc := T^.Pred[J].TaskId - 1 - GridScrollY;
   RowDst := I - 1 - GridScrollY;
   If ((RowSrc < 0) And (RowDst < 0)) Or
      ((RowSrc >= Vis) And (RowDst >= Vis)) Then Continue;
   Xs := DateToX(U^.Finish + 1);
   Ys := GanttBodyY1 + RowSrc * ROW_H + ROW_H Div 2;
   Xd := DateToX(T^.Start);
   Yd := GanttBodyY1 + RowDst * ROW_H + ROW_H Div 2;
   SetColor(CLR_GANTT_LINK);
   XMid := Xd - 4;
   If XMid < Xs Then XMid := Xs + 4;
   Line(Xs, Ys, XMid, Ys);
   Line(XMid, Ys, XMid, Yd);
   Line(XMid, Yd, Xd, Yd);
   Line(Xd, Yd, Xd - 3, Yd - 2);
   Line(Xd, Yd, Xd - 3, Yd + 2);
  End;
 End;
End;

{ ====================================================================== }
{   Phase 10 - Picture support (BMP / PCX / GIF best-effort)             }
{ ====================================================================== }

Type
 TByteArr = Array[0..65520] Of Byte;
 PByteArray = ^TByteArr;

 TBMPFileHdr = Packed Record
  bfType    : Word;
  bfSize    : LongInt;
  bfRsv1    : Word;
  bfRsv2    : Word;
  bfOffBits : LongInt;
 End;

 TBMPInfoHdr = Packed Record
  biSize       : LongInt;
  biWidth      : LongInt;
  biHeight     : LongInt;
  biPlanes     : Word;
  biBitCount   : Word;
  biCompression: LongInt;
  biImageSize  : LongInt;
  biXPpm       : LongInt;
  biYPpm       : LongInt;
  biClrUsed    : LongInt;
  biClrImp     : LongInt;
 End;

 TPCXHdr = Packed Record
  Manuf    : Byte;          { 10 = ZSoft }
  Version  : Byte;
  Encoding : Byte;          { 1 = RLE }
  BitsPerPix: Byte;
  XMin, YMin, XMax, YMax: Word;
  HRes, VRes: Word;
  Pal      : Array[0..47] Of Byte;
  Reserved : Byte;
  NPlanes  : Byte;
  BytesPerLine: Word;
  PalInfo  : Word;
  HScreen  : Word;
  VScreen  : Word;
  Filler   : Array[0..53] Of Byte;
 End;

Const
 VGA_R: Array[0..15] Of Byte = (  0,  0,  0,  0,170,170,170,170,
                                 85, 85, 85, 85,255,255,255,255);
 VGA_G: Array[0..15] Of Byte = (  0,  0,170,170,  0,  0, 85,170,
                                 85, 85,255,255, 85, 85,255,255);
 VGA_B: Array[0..15] Of Byte = (  0,170,  0,170,  0,170,  0,170,
                                 85,255, 85,255, 85,255, 85,255);

Function QuantizeRGB(R, G, B: Byte): Byte;
Var I: Integer; Dr, Dg, Db: LongInt; D, Best: LongInt; BestIdx: Byte;
Begin
 Best := $7FFFFFFF; BestIdx := 0;
 For I := 0 To 15 Do Begin
  Dr := LongInt(R) - LongInt(VGA_R[I]);
  Dg := LongInt(G) - LongInt(VGA_G[I]);
  Db := LongInt(B) - LongInt(VGA_B[I]);
  D := Dr * Dr + Dg * Dg + Db * Db;
  If D < Best Then Begin Best := D; BestIdx := I; End;
 End;
 QuantizeRGB := BestIdx;
End;

Function NewPicture: PPicture;
Var P: PPicture;
Begin
 NewPicture := Nil;
 If PicCount >= MAX_PICTURES Then Exit;
 GetMem(P, SizeOf(TPicture));
 If P = Nil Then Exit;
 FillChar(P^, SizeOf(TPicture), 0);
 NewPicture := P;
End;

Function LoadBMPInto(Const FName: String; P: PPicture): Boolean;
Var
 F: File;
 FH: TBMPFileHdr;
 IH: TBMPInfoHdr;
 Pal: Array[0..255] Of Packed Record B, G, R, A: Byte; End;
 RowStride, X, Y: LongInt;
 Row: Array[0..PIC_MAX_W * 4 + 16] Of Byte;
 W, H: LongInt;
 PalCount, I: LongInt;
 Pixels: Pointer;
 PixSz: LongInt;
 Idx: Byte;
 R, G, B: Byte;
Begin
 LoadBMPInto := False;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 If FileSize(F) < SizeOf(FH) + SizeOf(IH) Then Begin Close(F); Exit; End;
 BlockRead(F, FH, SizeOf(FH));
 If FH.bfType <> $4D42 Then Begin Close(F); Exit; End;
 BlockRead(F, IH, SizeOf(IH));
 If (IH.biPlanes <> 1) Or
    ((IH.biBitCount <> 24) And (IH.biBitCount <> 8) And (IH.biBitCount <> 4))
    Then Begin Close(F); Exit; End;
 If IH.biCompression <> 0 Then Begin Close(F); Exit; End;
 W := IH.biWidth;
 H := IH.biHeight;
 If H < 0 Then H := -H;
 If (W < 1) Or (W > PIC_MAX_W) Or (H < 1) Or (H > PIC_MAX_H)
    Then Begin Close(F); Exit; End;

 { Palette }
 FillChar(Pal, SizeOf(Pal), 0);
 If IH.biBitCount <= 8 Then Begin
  PalCount := IH.biClrUsed;
  If PalCount = 0 Then PalCount := LongInt(1) Shl IH.biBitCount;
  If PalCount > 256 Then PalCount := 256;
  BlockRead(F, Pal, PalCount * 4);
 End;

 Seek(F, FH.bfOffBits);

 PixSz := W * H;
 GetMem(Pixels, PixSz);
 If Pixels = Nil Then Begin Close(F); Exit; End;
 FillChar(Pixels^, PixSz, 0);

 If IH.biBitCount = 24 Then RowStride := ((3 * W + 3) Div 4) * 4
 Else If IH.biBitCount = 8 Then RowStride := ((W + 3) Div 4) * 4
 Else RowStride := (((W + 1) Div 2 + 3) Div 4) * 4;

 If RowStride > SizeOf(Row) Then RowStride := SizeOf(Row);

 For Y := 0 To H - 1 Do Begin
  BlockRead(F, Row, RowStride);
  For X := 0 To W - 1 Do Begin
   Case IH.biBitCount Of
    24: Begin
     B := Row[X * 3 + 0];
     G := Row[X * 3 + 1];
     R := Row[X * 3 + 2];
     Idx := QuantizeRGB(R, G, B);
    End;
    8: Begin
     I := Row[X];
     Idx := QuantizeRGB(Pal[I].R, Pal[I].G, Pal[I].B);
    End;
   Else
    Begin
     If (X And 1) = 0 Then I := Row[X Shr 1] Shr 4
     Else I := Row[X Shr 1] And $0F;
     Idx := QuantizeRGB(Pal[I].R, Pal[I].G, Pal[I].B);
    End;
   End;
   { Bottom-up : flip Y }
   PByteArray(Pixels)^[(H - 1 - Y) * W + X] := Idx;
  End;
 End;

 Close(F);
 P^.Format := 1;
 P^.Width  := W;
 P^.Height := H;
 P^.Pixels := Pixels;
 LoadBMPInto := True;
End;

Function LoadPCXInto(Const FName: String; P: PPicture): Boolean;
Var
 F: File;
 H: TPCXHdr;
 PalEnd: Array[0..768] Of Byte;
 W, Hh, X, Y, Total, Pos, Cnt: LongInt;
 B: Byte;
 Buf: Array[0..PIC_MAX_W + 16] Of Byte;
 Pixels: Pointer;
 PixSz: LongInt;
 Idx: Byte;
 RawSize: LongInt;
Begin
 LoadPCXInto := False;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 If FileSize(F) < SizeOf(H) Then Begin Close(F); Exit; End;
 BlockRead(F, H, SizeOf(H));
 If (H.Manuf <> 10) Or (H.Encoding <> 1) Then Begin Close(F); Exit; End;
 If (H.BitsPerPix <> 8) Or (H.NPlanes <> 1)
    Then Begin Close(F); Exit; End;
 W  := LongInt(H.XMax) - LongInt(H.XMin) + 1;
 Hh := LongInt(H.YMax) - LongInt(H.YMin) + 1;
 If (W < 1) Or (W > PIC_MAX_W) Or (Hh < 1) Or (Hh > PIC_MAX_H)
    Then Begin Close(F); Exit; End;
 { Read VGA palette at end : last 769 bytes : 0x0C marker + 768 palette }
 RawSize := FileSize(F);
 FillChar(PalEnd, SizeOf(PalEnd), 0);
 If RawSize > 769 Then Begin
  Seek(F, RawSize - 769);
  BlockRead(F, PalEnd, 769);
 End;
 Seek(F, 128);
 PixSz := W * Hh;
 GetMem(Pixels, PixSz);
 If Pixels = Nil Then Begin Close(F); Exit; End;
 FillChar(Pixels^, PixSz, 0);
 Total := LongInt(H.BytesPerLine) * Hh;
 Pos := 0;
 X := 0; Y := 0;
 While (Pos < Total) And (Not Eof(F)) Do Begin
  BlockRead(F, B, 1);
  If (B And $C0) = $C0 Then Begin
   Cnt := B And $3F;
   BlockRead(F, B, 1);
  End
  Else Cnt := 1;
  While Cnt > 0 Do Begin
   If X < W Then Buf[X] := B;
   Inc(X);
   Inc(Pos);
   If X >= H.BytesPerLine Then Begin
    { Commit row }
    For X := 0 To W - 1 Do Begin
     Idx := QuantizeRGB(PalEnd[1 + Buf[X] * 3 + 0],
                        PalEnd[1 + Buf[X] * 3 + 1],
                        PalEnd[1 + Buf[X] * 3 + 2]);
     PByteArray(Pixels)^[Y * W + X] := Idx;
    End;
    X := 0;
    Inc(Y);
    If Y >= Hh Then Break;
   End;
   Dec(Cnt);
  End;
  If Y >= Hh Then Break;
 End;
 Close(F);
 P^.Format := 2;
 P^.Width  := W;
 P^.Height := Hh;
 P^.Pixels := Pixels;
 LoadPCXInto := True;
End;

Function LoadGIFInto(Const FName: String; P: PPicture): Boolean;
Var
 F: File;
 Sig: Array[0..5] Of Char;
 LSD: Packed Record
  W, H: Word;
  Flags, BgIdx, AspectRatio: Byte;
 End;
 GCT: Array[0..767] Of Byte;
 GCTSize: Integer;
Begin
 LoadGIFInto := False;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 If FileSize(F) < 13 Then Begin Close(F); Exit; End;
 BlockRead(F, Sig, 6);
 If (Sig[0] <> 'G') Or (Sig[1] <> 'I') Or (Sig[2] <> 'F') Then Begin
  Close(F); Exit;
 End;
 BlockRead(F, LSD, 7);
 If (LSD.Flags And $80) <> 0 Then Begin
  GCTSize := 3 * (1 Shl ((LSD.Flags And $07) + 1));
  If GCTSize > SizeOf(GCT) Then GCTSize := SizeOf(GCT);
  BlockRead(F, GCT, GCTSize);
 End;
 Close(F);
 { LZW decoding is heavy ; we just acknowledge the file format and        }
 { store a placeholder (uniform color) so the user sees something.        }
 If (LSD.W < 1) Or (LSD.W > PIC_MAX_W) Or
    (LSD.H < 1) Or (LSD.H > PIC_MAX_H) Then Exit;
 GetMem(P^.Pixels, LongInt(LSD.W) * LongInt(LSD.H));
 If P^.Pixels = Nil Then Exit;
 FillChar(P^.Pixels^, LongInt(LSD.W) * LongInt(LSD.H), 7);  { lightgray }
 P^.Format := 3;
 P^.Width  := LSD.W;
 P^.Height := LSD.H;
 LoadGIFInto := True;
End;

Function ExtMatches(Const FName, Ext: String): Boolean;
Var I, L: Integer; E, U: String;
Begin
 ExtMatches := False;
 L := Length(FName);
 If L < Length(Ext) + 1 Then Exit;
 E := Copy(FName, L - Length(Ext) + 1, Length(Ext));
 U := '';
 For I := 1 To Length(E) Do U := U + UpCase(E[I]);
 ExtMatches := U = Ext;
End;

Function LoadPictureFile(Const FName: String; P: PPicture): Boolean;
Begin
 If ExtMatches(FName, '.BMP') Then LoadPictureFile := LoadBMPInto(FName, P)
 Else If ExtMatches(FName, '.PCX') Then LoadPictureFile := LoadPCXInto(FName, P)
 Else If ExtMatches(FName, '.GIF') Then LoadPictureFile := LoadGIFInto(FName, P)
 Else LoadPictureFile := False;
End;

Procedure DrawPictureAt(P: PPicture; X0, Y0: Integer);
Var
 X, Y: Integer;
 Px, Py: Integer;
 Idx: Byte;
 Data: PByteArray;
Begin
 If (P = Nil) Or (P^.Pixels = Nil) Then Exit;
 Data := PByteArray(P^.Pixels);
 For Y := 0 To P^.Height - 1 Do Begin
  Py := Y0 + Y;
  If (Py < 0) Or (Py >= SCREEN_H) Then Continue;
  For X := 0 To P^.Width - 1 Do Begin
   Px := X0 + X;
   If (Px < 0) Or (Px >= SCREEN_W) Then Continue;
   Idx := Data^[LongInt(Y) * LongInt(P^.Width) + LongInt(X)];
   PutPixel(Px, Py, Idx);
  End;
 End;
 { Frame around picture }
 SetColor(CLR_BLACK);
 Rectangle(X0 - 1, Y0 - 1, X0 + P^.Width, Y0 + P^.Height);
End;

Procedure DrawAllPictures;
Var I, Row, Anchor: Integer; Px, Py: Integer; P: PPicture;
Begin
 If PicCount < 1 Then Exit;
 If CurView <> VIEW_GANTT Then Exit;
 For I := 1 To PicCount Do Begin
  P := Pictures[I];
  If (P = Nil) Or (P^.Pixels = Nil) Then Continue;
  Anchor := P^.AnchorTsk;
  If (Anchor > 0) And (Anchor <= Project.TaskCount) Then Begin
   Row := Anchor - 1 - GridScrollY;
   If (Row < 0) Or (Row >= VisibleRowCount) Then Continue;
   Px := GanttX1 + 8;
   Py := GanttBodyY1 + Row * ROW_H + 2;
   If Py + P^.Height > GanttBodyY2 Then Continue;
  End
  Else Begin
   Px := P^.X;
   Py := P^.Y;
  End;
  DrawPictureAt(P, Px, Py);
 End;
End;

Procedure DrawGantt;
Var I, Visible: Integer;
Begin
 HideMouse;
 FillBox(GanttX1, GanttHdrY1, GanttX2, GanttBodyY2, CLR_GANTT_BG);
 DrawGanttHeader;
 DrawGanttGrid;
 Visible := VisibleRowCount;
 For I := 0 To Visible - 1 Do DrawGanttBar(I, I + 1 + GridScrollY);
 DrawGanttLinks;
 DrawAllPictures;
 ShowMouse;
End;

Procedure DrawSplitter;
Begin
 FillBox(SplitX, WorkY1, SplitX + SPLIT_W - 1, WorkY2, CLR_LGRAY);
 VLine(SplitX, WorkY1, WorkY2, CLR_WIN_HI);
 VLine(SplitX + SPLIT_W - 1, WorkY1, WorkY2, CLR_WIN_LO);
End;

{ ====================================================================== }
{                       VUE RESEAU (PERT)                                }
{ ====================================================================== }

Const
 NET_BOX_W = 130;
 NET_BOX_H = 56;
 NET_GAP_X = 30;
 NET_GAP_Y = 18;

Function NetTaskLevel(TaskIdx: Integer): Integer;
Var T: PTask; I, PIdx, Lv, Mx: Integer;
Begin
 NetTaskLevel := 0;
 If (TaskIdx < 1) Or (TaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[TaskIdx];
 If T = Nil Then Exit;
 Mx := 0;
 For I := 1 To T^.PredCount Do Begin
  PIdx := FindTaskByIdField(T^.Pred[I].TaskId);
  If (PIdx > 0) And (PIdx < TaskIdx) Then Begin
   Lv := NetTaskLevel(PIdx) + 1;
   If Lv > Mx Then Mx := Lv;
  End;
 End;
 NetTaskLevel := Mx;
End;

Procedure NetTaskPos(TaskIdx: Integer; Var X, Y: Integer);
Var Lv, I, Cnt: Integer;
Begin
 Lv := NetTaskLevel(TaskIdx);
 Cnt := 0;
 For I := 1 To TaskIdx - 1 Do
  If NetTaskLevel(I) = Lv Then Inc(Cnt);
 X := 10 + Lv * (NET_BOX_W + NET_GAP_X) - NetScrollX;
 Y := WorkY1 + 10 + Cnt * (NET_BOX_H + NET_GAP_Y) - NetScrollY;
End;

Procedure NetDrawBox(TaskIdx: Integer);
Var T: PTask; X, Y, BgC, FgC: Integer; S: String;
Begin
 T := Project.Tasks[TaskIdx];
 If T = Nil Then Exit;
 NetTaskPos(TaskIdx, X, Y);
 If (X + NET_BOX_W < 0) Or (X > SCREEN_W) Then Exit;
 If (Y + NET_BOX_H < WorkY1) Or (Y > WorkY2) Then Exit;
 If T^.IsMilestone Then BgC := CLR_BROWN
 Else If T^.IsSummary Then BgC := CLR_LGRAY
 Else If T^.Critical Then BgC := CLR_RED
 Else BgC := CLR_LBLUE;
 If T^.Critical Or T^.IsMilestone Then FgC := CLR_WHITE Else FgC := CLR_BLACK;
 FillBox(X, Y, X + NET_BOX_W - 1, Y + NET_BOX_H - 1, BgC);
 SetColor(CLR_BLACK);
 Rectangle(X, Y, X + NET_BOX_W - 1, Y + NET_BOX_H - 1);
 If TaskIdx = CurTaskIdx Then Begin
  Rectangle(X - 1, Y - 1, X + NET_BOX_W, Y + NET_BOX_H);
  Rectangle(X - 2, Y - 2, X + NET_BOX_W + 1, Y + NET_BOX_H + 1);
 End;
 HLine(X, X + NET_BOX_W - 1, Y + 12, CLR_BLACK);
 HLine(X, X + NET_BOX_W - 1, Y + 28, CLR_BLACK);
 HLine(X, X + NET_BOX_W - 1, Y + 42, CLR_BLACK);
 SetColor(FgC);
 S := IntToStr(T^.Id) + '  ' + ClipStr(T^.Name, 18);
 OutTextXY(X + 3, Y + 2, S);
 SetColor(CLR_BLACK);
 OutTextXY(X + 3,  Y + 14, ShortDateStr(T^.Start));
 OutTextXY(X + 70, Y + 14, ShortDateStr(T^.Finish));
 OutTextXY(X + 3,  Y + 30, 'D:' + IntToStr(T^.Duration Div 10) + 'j');
 OutTextXY(X + 50, Y + 30, IntToStr(T^.PercentDone) + '%');
 OutTextXY(X + 90, Y + 30, 'M:' + IntToStr(T^.TotalSlack));
 OutTextXY(X + 3,  Y + 44, ClipStr(T^.Resources, 20));
End;

Procedure NetDrawLink(FromIdx, ToIdx: Integer; LinkTyp: Byte);
Var X1, Y1, X2, Y2, Mid: Integer; T1, T2: PTask;
Begin
 T1 := Project.Tasks[FromIdx]; T2 := Project.Tasks[ToIdx];
 If (T1 = Nil) Or (T2 = Nil) Then Exit;
 NetTaskPos(FromIdx, X1, Y1);
 NetTaskPos(ToIdx,   X2, Y2);
 Case LinkTyp Of
  LT_FS: Begin X1 := X1 + NET_BOX_W; Y1 := Y1 + NET_BOX_H Div 2;
              Y2 := Y2 + NET_BOX_H Div 2; End;
  LT_SS: Begin Y1 := Y1 + NET_BOX_H Div 2;
              Y2 := Y2 + NET_BOX_H Div 2; End;
  LT_FF: Begin X1 := X1 + NET_BOX_W; Y1 := Y1 + NET_BOX_H Div 2;
              X2 := X2 + NET_BOX_W; Y2 := Y2 + NET_BOX_H Div 2; End;
  LT_SF: Begin Y1 := Y1 + NET_BOX_H Div 2;
              X2 := X2 + NET_BOX_W; Y2 := Y2 + NET_BOX_H Div 2; End;
 End;
 SetColor(CLR_DGRAY);
 If T1^.Critical And T2^.Critical Then SetColor(CLR_RED);
 Mid := (X1 + X2) Div 2;
 Line(X1, Y1, Mid, Y1);
 Line(Mid, Y1, Mid, Y2);
 Line(Mid, Y2, X2, Y2);
 Line(X2 - 4, Y2 - 3, X2, Y2);
 Line(X2 - 4, Y2 + 3, X2, Y2);
End;

Procedure DrawNetwork;
Var I, J: Integer; T: PTask;
Begin
 HideMouse;
 FillBox(0, WorkY1, SCREEN_W - 1, WorkY2, CLR_WHITE);
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  For J := 1 To T^.PredCount Do
   NetDrawLink(FindTaskByIdField(T^.Pred[J].TaskId), I, T^.Pred[J].LinkType);
 End;
 For I := 1 To Project.TaskCount Do NetDrawBox(I);
 ShowMouse;
End;

{ ====================================================================== }
{                       VUE RESSOURCES (FEUILLE)                         }
{ ====================================================================== }

Const
 RV_ROW_H = 17;

Var
 RVColX: Array[0..6] Of Integer;
 RVColW: Array[0..5] Of Integer;
 RVColLbl: Array[0..5] Of String;
 RVInit: Boolean;

Procedure RVSetupCols;
Begin
 If RVInit Then Exit;
 RVColW[0] := 40; RVColW[1] := 220; RVColW[2] := 60;
 RVColW[3] := 140; RVColW[4] := 60; RVColW[5] := 100;
 RVColLbl[0] := 'Id';   RVColLbl[1] := 'Nom ressource';
 RVColLbl[2] := 'Init.';RVColLbl[3] := 'Groupe';
 RVColLbl[4] := 'Max%'; RVColLbl[5] := 'Cout / heure';
 RVColX[0] := 0;
 RVColX[1] := RVColX[0] + RVColW[0];
 RVColX[2] := RVColX[1] + RVColW[1];
 RVColX[3] := RVColX[2] + RVColW[2];
 RVColX[4] := RVColX[3] + RVColW[3];
 RVColX[5] := RVColX[4] + RVColW[4];
 RVColX[6] := RVColX[5] + RVColW[5];
 RVInit := True;
End;

Procedure RVCellText(R: PResource; C: Integer; Var S: String);
Begin
 Case C Of
  0: S := IntToStr(R^.Id);
  1: S := R^.Name;
  2: S := R^.Initials;
  3: S := R^.Grp;
  4: S := IntToStr(R^.MaxUnits) + '%';
  5: S := IntToStr(R^.StdRate Div 100);
 Else S := '';
 End;
End;

Procedure RVCommitEdit;
Var R: PResource; V: LongInt;
Begin
 If Not ResViewEdit Then Exit;
 If (ResViewSelRow < 1) Or (ResViewSelRow > Project.ResCount) Then Begin
  ResViewEdit := False; Exit;
 End;
 R := Project.Resources[ResViewSelRow];
 If R = Nil Then Begin ResViewEdit := False; Exit; End;
 Case ResViewCol Of
  1: R^.Name := Copy(ResViewBuf, 1, 40);
  2: R^.Initials := Copy(ResViewBuf, 1, 8);
  3: R^.Grp  := Copy(ResViewBuf, 1, 20);
  4: Begin V := StrToIntDef(ResViewBuf, 100);
          If V < 0 Then V := 0; If V > 1000 Then V := 1000;
          R^.MaxUnits := V; End;
  5: Begin V := StrToIntDef(ResViewBuf, 0); R^.StdRate := V * 100; End;
 End;
 ResViewEdit := False;
 Project.Dirty := True;
End;

Procedure RVStartEdit;
Var R: PResource; S: String;
Begin
 If ResViewCol = 0 Then Exit;
 If (ResViewSelRow < 1) Or (ResViewSelRow > Project.ResCount) Then Exit;
 R := Project.Resources[ResViewSelRow];
 If R = Nil Then Exit;
 RVCellText(R, ResViewCol, S);
 ResViewBuf := S;
 ResViewCaret := Length(ResViewBuf);
 ResViewEdit := True;
End;

Procedure DrawResourceView;
Var I, J, Y, Vis: Integer; R: PResource; S: String; Bg, Fg: Integer;
Begin
 RVSetupCols;
 HideMouse;
 FillBox(0, WorkY1, SCREEN_W - 1, WorkY2, CLR_WHITE);
 FillBox(0, WorkY1, SCREEN_W - 1, WorkY1 + RV_ROW_H - 1, CLR_LGRAY);
 For I := 0 To 5 Do Begin
  SetColor(CLR_BLACK);
  OutTextXY(RVColX[I] + 4, WorkY1 + 4, RVColLbl[I]);
  SetColor(CLR_WIN_LO);
  VLine(RVColX[I + 1] - 1, WorkY1, WorkY1 + RV_ROW_H - 1, CLR_WIN_LO);
 End;
 HLine(0, SCREEN_W - 1, WorkY1 + RV_ROW_H - 1, CLR_WIN_LO);
 Vis := (WorkY2 - WorkY1 - RV_ROW_H) Div RV_ROW_H;
 For I := 0 To Vis - 1 Do Begin
  J := ResViewScrollY + I + 1;
  Y := WorkY1 + RV_ROW_H + I * RV_ROW_H;
  If (J < 1) Or (J > Project.ResCount) Then Begin
   FillBox(0, Y, SCREEN_W - 1, Y + RV_ROW_H - 1, CLR_WHITE);
   Continue;
  End;
  R := Project.Resources[J];
  If R = Nil Then Continue;
  If J = ResViewSelRow Then Begin Bg := CLR_GRID_SEL_BG; Fg := CLR_WHITE; End
  Else Begin Bg := CLR_WHITE; Fg := CLR_BLACK; End;
  FillBox(0, Y, SCREEN_W - 1, Y + RV_ROW_H - 1, Bg);
  SetColor(Fg);
  RVCellText(R, 0, S); OutTextXY(RVColX[0] + 4, Y + 4, S);
  RVCellText(R, 1, S); OutTextXY(RVColX[1] + 4, Y + 4, S);
  RVCellText(R, 2, S); OutTextXY(RVColX[2] + 4, Y + 4, S);
  RVCellText(R, 3, S); OutTextXY(RVColX[3] + 4, Y + 4, S);
  RVCellText(R, 4, S); OutTextXY(RVColX[4] + 4, Y + 4, S);
  RVCellText(R, 5, S); OutTextXY(RVColX[5] + 4, Y + 4, S);
  If ResViewEdit And (J = ResViewSelRow) Then Begin
   FillBox(RVColX[ResViewCol] + 1, Y + 1,
           RVColX[ResViewCol + 1] - 2, Y + RV_ROW_H - 2, CLR_WHITE);
   SetColor(CLR_BLACK);
   OutTextXY(RVColX[ResViewCol] + 4, Y + 4, ResViewBuf);
   If BlinkState Then
    VLine(RVColX[ResViewCol] + 4 + TextWidth(Copy(ResViewBuf, 1, ResViewCaret)),
          Y + 2, Y + RV_ROW_H - 3, CLR_BLACK);
  End;
  SetColor(CLR_GRID_LINE);
  For J := 0 To 5 Do
   VLine(RVColX[J + 1] - 1, Y, Y + RV_ROW_H - 1, CLR_GRID_LINE);
  HLine(0, SCREEN_W - 1, Y + RV_ROW_H - 1, CLR_GRID_LINE);
 End;
 ShowMouse;
End;

{ ====================================================================== }
{                       VUE UTILISATION                                  }
{ ====================================================================== }

Const
 USG_LEFT_W = 200;
 USG_HDR_H  = 24;
 USG_ROW_H  = 16;
 USG_DAY_W  = 26;

Function TaskDaysWorkload(T: PTask; D: TDate): LongInt;
Var Dd: LongInt;
Begin
 TaskDaysWorkload := 0;
 If T = Nil Then Exit;
 If T^.IsMilestone Or T^.IsSummary Then Exit;
 If (D < T^.Start) Or (D > T^.Finish) Then Exit;
 Dd := TaskDurDays(T);
 If Dd <= 0 Then Exit;
 If T^.Work > 0 Then TaskDaysWorkload := (T^.Work Div 10) Div Dd
 Else TaskDaysWorkload := 8;
End;

Function ResDayWorkload(ResIdx: Integer; D: TDate): LongInt;
Var I, K: Integer; T: PTask; R: PResource; Cnt, Tot: LongInt;
    InitS: String;
Begin
 ResDayWorkload := 0;
 R := Project.Resources[ResIdx];
 If R = Nil Then Exit;
 InitS := R^.Initials;
 Tot := 0;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If Pos(InitS, T^.Resources) > 0 Then
   Tot := Tot + TaskDaysWorkload(T, D);
 End;
 ResDayWorkload := Tot;
End;

Procedure DrawUsage;
Var DaysVis, I, J, Y, X: Integer; D, BaseD: TDate;
    T: PTask; R: PResource; S: String;
    Bg, Fg: Integer; W: LongInt;
    RowCount, RowIdx: Integer;
    HdrY1, HdrY2, BodyY1: Integer;
Begin
 HideMouse;
 FillBox(0, WorkY1, SCREEN_W - 1, WorkY2, CLR_WHITE);
 HdrY1  := WorkY1;
 HdrY2  := WorkY1 + USG_HDR_H - 1;
 BodyY1 := HdrY2 + 1;
 FillBox(0, HdrY1, SCREEN_W - 1, HdrY2, CLR_LGRAY);
 SetColor(CLR_BLACK);
 If UsageMode = 0 Then OutTextXY(4, HdrY1 + 8, 'Nom tache')
 Else                  OutTextXY(4, HdrY1 + 8, 'Ressource');
 OutTextXY(USG_LEFT_W - 60, HdrY1 + 8, 'Travail');
 BaseD := GanttOriginDt + UsageScrollX;
 DaysVis := (SCREEN_W - USG_LEFT_W) Div USG_DAY_W;
 For I := 0 To DaysVis - 1 Do Begin
  D := BaseD + I;
  X := USG_LEFT_W + I * USG_DAY_W;
  If Not IsWeekDay(D) Then
   FillBox(X, HdrY1, X + USG_DAY_W - 1, WorkY2, CLR_LGRAY);
  SetColor(CLR_BLACK);
  S := ShortDateStr(D);
  S := Copy(S, 1, 5);
  OutTextXY(X + 2, HdrY1 + 2, S);
  SetColor(CLR_WIN_LO);
  VLine(X + USG_DAY_W - 1, HdrY1, WorkY2, CLR_WIN_LO);
 End;
 VLine(USG_LEFT_W - 1, HdrY1, WorkY2, CLR_WIN_LO);
 HLine(0, SCREEN_W - 1, HdrY2, CLR_WIN_LO);

 If UsageMode = 0 Then RowCount := Project.TaskCount
 Else RowCount := Project.ResCount;
 RowIdx := 0;
 For I := 1 To RowCount Do Begin
  If I - 1 < UsageScrollY Then Continue;
  Y := BodyY1 + RowIdx * USG_ROW_H;
  If Y + USG_ROW_H > WorkY2 Then Break;
  If UsageMode = 0 Then Begin
   T := Project.Tasks[I];
   If T = Nil Then Continue;
   If (I = CurTaskIdx) Then Begin Bg := CLR_GRID_SEL_BG; Fg := CLR_WHITE; End
   Else Begin Bg := CLR_WHITE; Fg := CLR_BLACK; End;
   FillBox(0, Y, USG_LEFT_W - 2, Y + USG_ROW_H - 1, Bg);
   SetColor(Fg);
   OutTextXY(4, Y + 3, ClipStr(IntToStr(T^.Id) + ' ' + T^.Name, 22));
   OutTextXY(USG_LEFT_W - 60, Y + 3, IntToStr(T^.Work Div 10) + 'h');
  End
  Else Begin
   R := Project.Resources[I];
   If R = Nil Then Continue;
   Bg := CLR_WHITE; Fg := CLR_BLACK;
   FillBox(0, Y, USG_LEFT_W - 2, Y + USG_ROW_H - 1, Bg);
   SetColor(Fg);
   OutTextXY(4, Y + 3, ClipStr(IntToStr(R^.Id) + ' ' + R^.Name, 22));
  End;
  For J := 0 To DaysVis - 1 Do Begin
   D := BaseD + J;
   X := USG_LEFT_W + J * USG_DAY_W;
   If UsageMode = 0 Then W := TaskDaysWorkload(Project.Tasks[I], D)
   Else                  W := ResDayWorkload(I, D);
   If W > 0 Then Begin
    If W > 8 Then SetColor(CLR_RED) Else SetColor(CLR_BLACK);
    OutTextXY(X + 4, Y + 3, IntToStr(W) + 'h');
   End;
   SetColor(CLR_GRID_LINE);
   VLine(X + USG_DAY_W - 1, Y, Y + USG_ROW_H - 1, CLR_GRID_LINE);
  End;
  HLine(0, SCREEN_W - 1, Y + USG_ROW_H - 1, CLR_GRID_LINE);
  Inc(RowIdx);
 End;
 ShowMouse;
End;

{ ====================================================================== }
{                       VUE CALENDRIER                                   }
{ ====================================================================== }

Function DaysInMonth(M, Y: Integer): Integer;
Begin
 Case M Of
  1, 3, 5, 7, 8, 10, 12: DaysInMonth := 31;
  4, 6, 9, 11: DaysInMonth := 30;
  2: If (Y Mod 4 = 0) And ((Y Mod 100 <> 0) Or (Y Mod 400 = 0))
     Then DaysInMonth := 29 Else DaysInMonth := 28;
 Else DaysInMonth := 30;
 End;
End;

Procedure DrawCalendar;
Var D, FirstDay, LastDay, FirstJDN: TDate;
    Wd, Col, Row, X, Y, Cw, Ch, CellY, CellX: Integer;
    I, MaxRow: Integer; T: PTask;
    HdrH, CellH: Integer; S: String;
    DayBarY, BarC: Integer;
Begin
 HideMouse;
 FillBox(0, WorkY1, SCREEN_W - 1, WorkY2, CLR_WHITE);
 HdrH := 36;
 FillBox(0, WorkY1, SCREEN_W - 1, WorkY1 + HdrH - 1, CLR_LGRAY);
 SetColor(CLR_BLACK);
 S := MonthName(CalMonth) + ' ' + IntToStr(CalYear);
 OutTextXY(SCREEN_W Div 2 - TextWidth(S) Div 2, WorkY1 + 4, S);
 { Boutons mois <  > }
 SetColor(CLR_BLACK);
 OutTextXY(20, WorkY1 + 4, '<<');
 OutTextXY(50, WorkY1 + 4, '<');
 OutTextXY(SCREEN_W - 60, WorkY1 + 4, '>');
 OutTextXY(SCREEN_W - 35, WorkY1 + 4, '>>');
 Cw := SCREEN_W Div 7;
 For I := 0 To 6 Do Begin
  X := I * Cw;
  SetColor(CLR_BLACK);
  OutTextXY(X + 4, WorkY1 + 20, DayShortName((I + 1) Mod 7));
  SetColor(CLR_WIN_LO);
  VLine(X + Cw - 1, WorkY1, WorkY2, CLR_WIN_LO);
 End;
 HLine(0, SCREEN_W - 1, WorkY1 + HdrH - 1, CLR_WIN_LO);

 FirstJDN := DateToJDN(CalYear, CalMonth, 1);
 LastDay := DaysInMonth(CalMonth, CalYear);
 Wd := DayOfWeek(FirstJDN);    { 0=Sun..6=Sat in our convention }
 MaxRow := (Wd + LastDay + 6) Div 7;
 If MaxRow < 5 Then MaxRow := 5;
 If MaxRow > 6 Then MaxRow := 6;
 CellH := (WorkY2 - WorkY1 - HdrH) Div MaxRow;
 For D := 1 To LastDay Do Begin
  Col := (Wd + D - 1) Mod 7;
  Row := (Wd + D - 1) Div 7;
  X := Col * Cw;
  Y := WorkY1 + HdrH + Row * CellH;
  SetColor(CLR_BLACK);
  OutTextXY(X + 4, Y + 2, IntToStr(D));
  FirstDay := DateToJDN(CalYear, CalMonth, D);
  If Not IsWeekDay(FirstDay) Then
   FillBox(X + 1, Y + 14, X + Cw - 2, Y + CellH - 2, CLR_LGRAY);
  DayBarY := Y + 16;
  For I := 1 To Project.TaskCount Do Begin
   T := Project.Tasks[I];
   If T = Nil Then Continue;
   If T^.IsSummary Then Continue;
   If (FirstDay >= T^.Start) And (FirstDay <= T^.Finish) Then Begin
   If T^.Critical Then BarC := CLR_RED
    Else If T^.IsMilestone Then BarC := CLR_BROWN
    Else BarC := CLR_LBLUE;
    FillBox(X + 2, DayBarY, X + Cw - 4, DayBarY + 10, BarC);
    SetColor(CLR_BLACK);
    Rectangle(X + 2, DayBarY, X + Cw - 4, DayBarY + 10);
    OutTextXY(X + 5, DayBarY + 1, ClipStr(T^.Name, (Cw - 12) Div 8));
    Inc(DayBarY, 12);
    If DayBarY > Y + CellH - 12 Then Break;
   End;
  End;
  SetColor(CLR_WIN_LO);
  HLine(X, X + Cw - 1, Y + CellH - 1, CLR_WIN_LO);
 End;
 ShowMouse;
End;

{ ====================================================================== }
{                       BOITE DE MESSAGE                                 }
{ ====================================================================== }

Procedure MessageBox(Const Title, Msg: String);
Var X1, Y1, X2, Y2: Integer; K: Char;
Begin
 X1 := 140; Y1 := 170; X2 := 500; Y2 := 290;
 HideMouse;
 FillBox(X1 + 4, Y2 + 1, X2 + 4, Y2 + 3, CLR_BLACK);
 FillBox(X2 + 1, Y1 + 4, X2 + 3, Y2 + 3, CLR_BLACK);
 DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 6, Y1 + 4, Title);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 16, Y1 + 32, Msg);
 DrawRaised(X1 + 150, Y2 - 30, X1 + 210, Y2 - 10, CLR_LGRAY,
            CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 175, Y2 - 24, 'OK');
 ShowMouse;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If (K = #13) Or (K = #27) Or (K = ' ') Then Begin
    NeedFullRedraw := True; Exit;
   End;
   If K = #0 Then ReadKey;
  End;
  If LeftPressed Then
   If InRect(Mouse.X, Mouse.Y, X1 + 150, Y2 - 30, X1 + 210, Y2 - 10) Then Begin
    NeedFullRedraw := True; Exit;
   End;
 Until False;
End;

{ ====================================================================== }
{                       PARSING TEXTE                                    }
{ ====================================================================== }

Function ParseDateStr(Const S: String; Var D: TDate): Boolean;
Var T: String; I, P1, P2, DD, MM, YY: Integer; OK: Boolean;
Begin
 ParseDateStr := False;
 T := TrimStr(S);
 If T = '' Then Exit;
 P1 := 0; P2 := 0;
 For I := 1 To Length(T) Do
  If (T[I] = '/') Or (T[I] = '-') Or (T[I] = '.') Then Begin
   If P1 = 0 Then P1 := I Else If P2 = 0 Then P2 := I;
  End;
 If (P1 = 0) Or (P2 = 0) Then Exit;
 DD := StrToIntDef(Copy(T, 1, P1 - 1), 0);
 MM := StrToIntDef(Copy(T, P1 + 1, P2 - P1 - 1), 0);
 YY := StrToIntDef(Copy(T, P2 + 1, Length(T) - P2), 0);
 If YY < 100 Then Begin
  If YY < 50 Then YY := YY + 2000 Else YY := YY + 1900;
 End;
 OK := (DD >= 1) And (DD <= 31) And (MM >= 1) And (MM <= 12)
       And (YY >= 1900) And (YY <= 2200);
 If Not OK Then Exit;
 D := DateToJDN(YY, MM, DD);
 ParseDateStr := True;
End;

Function ParseDurStr(Const S: String; Var Dur: LongInt): Boolean;
Var T: String; I: Integer; HasDot: Boolean; Whole, Frac: LongInt;
Begin
 ParseDurStr := False;
 T := TrimStr(S);
 If T = '' Then Exit;
 I := 1;
 Whole := 0; Frac := 0; HasDot := False;
 While (I <= Length(T)) And ((T[I] In ['0'..'9']) Or (T[I] = ',') Or (T[I] = '.')) Do Begin
  If (T[I] = ',') Or (T[I] = '.') Then Begin HasDot := True; Inc(I); Continue; End;
  If Not HasDot Then Whole := Whole * 10 + LongInt(Ord(T[I]) - Ord('0'))
  Else If Frac = 0 Then Frac := LongInt(Ord(T[I]) - Ord('0'));
  Inc(I);
 End;
 Dur := Whole * 10 + Frac;
 If Dur < 0 Then Dur := 0;
 ParseDurStr := True;
End;

{ ====================================================================== }
{                       EDITION INLINE                                   }
{ ====================================================================== }

Procedure EnsureCurVisible; Forward;

Function ColAbsLeft(I: Integer): Integer;
Var J, X: Integer;
Begin
 X := 0;
 For J := 1 To I - 1 Do X := X + Cols[J].Width;
 ColAbsLeft := X;
End;

Function ColScreenX(I: Integer): Integer;
Begin
 ColScreenX := GridX1 + ColAbsLeft(I) - GridScrollX;
End;

Function ColHit(X: Integer): Integer;
Var I, Xx: Integer;
Begin
 ColHit := 0;
 If (X < GridX1) Or (X > GridX2) Then Exit;
 Xx := GridX1 - GridScrollX;
 For I := 1 To ColCount Do Begin
  If (X >= Xx) And (X < Xx + Cols[I].Width) Then Begin
   ColHit := I; Exit;
  End;
  Xx := Xx + Cols[I].Width;
 End;
End;

Function ColResizeHit(X, Y: Integer): Integer;
Var I, Xx: Integer;
Begin
 ColResizeHit := 0;
 If (Y < GridHdrY1) Or (Y > GridHdrY2) Then Exit;
 Xx := GridX1 - GridScrollX;
 For I := 1 To ColCount Do Begin
  Xx := Xx + Cols[I].Width;
  If (X >= Xx - 2) And (X <= Xx + 2) Then Begin
   ColResizeHit := I; Exit;
  End;
 End;
End;

Function FieldIsEditable(F: Byte): Boolean;
Begin
 FieldIsEditable := (F = FLD_NAME) Or (F = FLD_DUR) Or (F = FLD_START)
                  Or (F = FLD_FINISH) Or (F = FLD_RES) Or (F = FLD_PERCENT)
                  Or (F = FLD_NOTES) Or (F = FLD_WBS);
End;

Procedure CancelEdit;
Begin
 If Not EditMode Then Exit;
 EditMode := False;
 EditBuf := '';
 NeedGridRedraw := True;
End;

Procedure BeginEdit(Row, Col: Integer);
Var T: PTask; F: Byte;
Begin
 If EditMode Then CancelEdit;
 If (Col < 1) Or (Col > ColCount) Then Exit;
 If (Row < 1) Or (Row > Project.TaskCount) Then Exit;
 F := Cols[Col].Field;
 If Not FieldIsEditable(F) Then Exit;
 T := Project.Tasks[Row];
 If T = Nil Then Exit;
 EditMode := True;
 EditRow := Row;
 EditCol := Col;
 Case F Of
  FLD_NAME:    EditBuf := T^.Name;
  FLD_DUR:     EditBuf := IntToStr(T^.Duration Div 10);
  FLD_START:   EditBuf := ShortDateStr(T^.Start);
  FLD_FINISH:  EditBuf := ShortDateStr(T^.Finish);
  FLD_RES:     EditBuf := T^.Resources;
  FLD_PERCENT: EditBuf := IntToStr(T^.PercentDone);
  FLD_NOTES:   EditBuf := T^.Notes;
  FLD_WBS:     EditBuf := T^.WBS;
 Else EditBuf := '';
 End;
 EditCaret := Length(EditBuf);
 BlinkState := True;
 NeedGridRedraw := True;
End;

Procedure CommitEdit;
Var T: PTask; F: Byte; D: TDate; L: LongInt; P: Integer;
Begin
 If Not EditMode Then Exit;
 If (EditRow < 1) Or (EditRow > Project.TaskCount) Then Begin
  CancelEdit; Exit;
 End;
 T := Project.Tasks[EditRow];
 If T = Nil Then Begin CancelEdit; Exit; End;
 F := Cols[EditCol].Field;
 Case F Of
  FLD_NAME:    T^.Name := Copy(EditBuf, 1, 60);
  FLD_DUR:     If ParseDurStr(EditBuf, L) Then Begin
                T^.Duration := L;
                If L = 0 Then Begin
                 T^.IsMilestone := True;
                 T^.Finish := T^.Start;
                End
                Else Begin
                 T^.IsMilestone := False;
                 T^.Finish := T^.Start + (L Div 10) - 1;
                 If T^.Finish < T^.Start Then T^.Finish := T^.Start;
                End;
               End;
  FLD_START:   If ParseDateStr(EditBuf, D) Then Begin
                L := T^.Finish - T^.Start;
                T^.Start := D;
                T^.Finish := D + L;
                If T^.IsMilestone Then T^.Finish := D;
               End;
  FLD_FINISH:  If ParseDateStr(EditBuf, D) Then Begin
                If D < T^.Start Then D := T^.Start;
                T^.Finish := D;
                T^.Duration := (D - T^.Start + 1) * 10;
                If T^.Duration = 0 Then T^.IsMilestone := True
                Else T^.IsMilestone := False;
               End;
  FLD_RES:     T^.Resources := Copy(EditBuf, 1, 60);
  FLD_PERCENT: Begin
                P := Integer(StrToIntDef(EditBuf, T^.PercentDone));
                If P < 0 Then P := 0;
                If P > 100 Then P := 100;
                T^.PercentDone := Byte(P);
               End;
  FLD_NOTES:   T^.Notes := Copy(EditBuf, 1, 120);
  FLD_WBS:     T^.WBS := Copy(EditBuf, 1, 20);
 End;
 EditMode := False;
 Project.Dirty := True;
 CPMRecompute;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
End;

Procedure DrawEditBox;
Var X1, X2, Y1, Y2, Cx, W: Integer; S: String;
Begin
 If Not EditMode Then Exit;
 If (EditRow - 1 < GridScrollY) Or
    (EditRow - 1 >= GridScrollY + VisibleRowCount) Then Exit;
 X1 := ColScreenX(EditCol);
 W := Cols[EditCol].Width;
 X2 := X1 + W - 1;
 If X1 < GridX1 Then X1 := GridX1;
 If X2 > GridX2 Then X2 := GridX2;
 Y1 := GridBodyY1 + (EditRow - 1 - GridScrollY) * ROW_H;
 Y2 := Y1 + ROW_H - 1;
 HideMouse;
 FillBox(X1, Y1, X2, Y2, CLR_WHITE);
 FrameBox(X1, Y1, X2, Y2, CLR_BLACK);
 S := EditBuf;
 While (Length(S) > 0) And (TextWidth(S) > X2 - X1 - 8) Do S := Copy(S, 2, Length(S) - 1);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 3, Y1 + 2, S);
 If BlinkState Then Begin
  Cx := X1 + 3 + TextWidth(Copy(EditBuf, 1, EditCaret));
  If Cx > X2 - 2 Then Cx := X2 - 2;
  VLine(Cx, Y1 + 2, Y2 - 2, CLR_BLACK);
 End;
 ShowMouse;
End;

Procedure HandleEditKey(K: Char);
Var K2: Char;
Begin
 If K = #0 Then Begin
  K2 := ReadKey;
  Case K2 Of
   #75: If EditCaret > 0 Then Dec(EditCaret);
   #77: If EditCaret < Length(EditBuf) Then Inc(EditCaret);
   #71: EditCaret := 0;
   #79: EditCaret := Length(EditBuf);
   #83: Begin
         If EditCaret < Length(EditBuf) Then
          Delete(EditBuf, EditCaret + 1, 1);
        End;
   #72,#80: Begin
             CommitEdit;
             If (K2 = #72) And (EditRow > 1) Then Dec(CurTaskIdx)
             Else If (K2 = #80) And (EditRow < Project.TaskCount) Then Inc(CurTaskIdx);
             EnsureCurVisible;
            End;
  End;
  BlinkState := True;
  NeedGridRedraw := True;
  Exit;
 End;
 Case K Of
  #13: Begin CommitEdit; NeedGridRedraw := True; End;
  #27: CancelEdit;
  #9:  Begin
        CommitEdit;
        Repeat
         If EditCol < ColCount Then Inc(EditCol) Else EditCol := 1;
        Until FieldIsEditable(Cols[EditCol].Field) Or (EditCol = CurColIdx);
        CurColIdx := EditCol;
        BeginEdit(CurTaskIdx, CurColIdx);
       End;
  #8:  Begin
        If EditCaret > 0 Then Begin
         Delete(EditBuf, EditCaret, 1);
         Dec(EditCaret);
        End;
        BlinkState := True;
        NeedGridRedraw := True;
       End;
 Else
  If (K >= ' ') And (Length(EditBuf) < 120) Then Begin
   Insert(K, EditBuf, EditCaret + 1);
   Inc(EditCaret);
   BlinkState := True;
   NeedGridRedraw := True;
  End;
 End;
End;

{ ====================================================================== }
{                       FRAMEWORK DIALOGUES                              }
{ ====================================================================== }

Procedure DlgFrame(X1, Y1, X2, Y2: Integer; Const Title: String);
Begin
 FillBox(X1 + 5, Y2 + 1, X2 + 5, Y2 + 4, CLR_BLACK);
 FillBox(X2 + 1, Y1 + 5, X2 + 4, Y2 + 4, CLR_BLACK);
 DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 17, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 8, Y1 + 5, Title);
 FillBox(X2 - 18, Y1 + 4, X2 - 6, Y1 + 14, CLR_LGRAY);
 SetColor(CLR_BLACK);
 OutTextXY(X2 - 15, Y1 + 5, 'x');
End;

Procedure DlgBtn(X1, Y1, X2, Y2: Integer; Const Caption: String;
                 Pressed, Focused: Boolean);
Var Tw: Integer;
Begin
 If Pressed Then
  DrawRaised(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_LO, CLR_WIN_HI)
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
 OutTextXY(X1 + 3, Y1 + 3, S);
 If Focused And BlinkState Then Begin
  If Caret < 0 Then Caret := Length(Text);
  Cx := X1 + 3 + TextWidth(Copy(Text, 1, Caret));
  If Cx > X2 - 2 Then Cx := X2 - 2;
  VLine(Cx, Y1 + 2, Y2 - 2, CLR_BLACK);
 End;
End;

Procedure DlgLabel(X, Y: Integer; Const S: String);
Begin
 SetColor(CLR_BLACK);
 OutTextXY(X, Y, S);
End;

Procedure DlgCheck(X, Y: Integer; Const Caption: String;
                   Checked, Focused: Boolean);
Begin
 FillBox(X, Y, X + 12, Y + 12, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(X, Y, X + 12, Y + 12);
 If Checked Then Begin
  SetColor(CLR_BLACK);
  Line(X + 2, Y + 6, X + 5, Y + 9);
  Line(X + 5, Y + 9, X + 10, Y + 3);
  Line(X + 2, Y + 7, X + 5, Y + 10);
  Line(X + 5, Y + 10, X + 10, Y + 4);
 End;
 SetColor(CLR_BLACK);
 OutTextXY(X + 18, Y + 2, Caption);
 If Focused Then Begin
  SetColor(CLR_BLACK);
  Rectangle(X + 16, Y, X + 20 + TextWidth(Caption), Y + 12);
 End;
End;

Procedure DlgGroup(X1, Y1, X2, Y2: Integer; Const Caption: String);
Begin
 SetColor(CLR_WIN_LO);
 Line(X1, Y1 + 4, X1, Y2);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y2, X2, Y1 + 4);
 Line(X1, Y1 + 4, X1 + 6, Y1 + 4);
 Line(X1 + 14 + TextWidth(Caption), Y1 + 4, X2, Y1 + 4);
 SetColor(CLR_WIN_HI);
 Line(X1 + 1, Y1 + 5, X1 + 1, Y2 - 1);
 Line(X1 + 1, Y2 - 1, X2 - 1, Y2 - 1);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 10, Y1, Caption);
End;

Procedure DlgTab(X, Y, W: Integer; Const Caption: String; Active: Boolean);
Var Bg, Tw: Integer;
Begin
 If Active Then Bg := CLR_DLG_BG Else Bg := CLR_LGRAY;
 FillBox(X + 2, Y, X + W - 2, Y + 22, Bg);
 SetColor(CLR_WIN_HI);
 Line(X, Y + 2, X + 2, Y);
 Line(X + 2, Y, X + W - 2, Y);
 Line(X, Y + 2, X, Y + 22);
 SetColor(CLR_WIN_LO);
 Line(X + W - 2, Y, X + W, Y + 2);
 Line(X + W, Y + 2, X + W, Y + 22);
 If Active Then Begin
  SetColor(Bg);
  HLine(X + 1, X + W - 1, Y + 22, Bg);
 End;
 SetColor(CLR_BLACK);
 Tw := TextWidth(Caption);
 OutTextXY(X + (W - Tw) Div 2, Y + 7, Caption);
End;

{ Modal helpers: wait for redraw needs etc. }
Var DlgNeedRedraw: Boolean;
    DlgResult: Integer;     { 0=none, 1=OK, 2=Cancel }

Procedure DlgPumpRedraw;
Begin
 If DlgNeedRedraw Then DlgNeedRedraw := False;
End;

{ ====================================================================== }
{                       DIALOGUE INFOS PROJET                            }
{ ====================================================================== }

Procedure DoProjectInfoDialog;
Var X1, Y1, X2, Y2: Integer;
    BufTitle, BufMgr, BufComp, BufStart, BufStatus, BufNotes: String;
    Focus, I: Integer;
    Buf: ^String;
    Caret: Integer;
    K, K2: Char;
    Done: Boolean;
    BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2: Integer;
    BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2: Integer;
    NewStart: TDate;

  Procedure FocusBuf;
  Begin
   Case Focus Of
    0: Buf := @BufTitle;
    1: Buf := @BufMgr;
    2: Buf := @BufComp;
    3: Buf := @BufStart;
    4: Buf := @BufStatus;
    5: Buf := @BufNotes;
   Else Buf := Nil;
   End;
   If Buf <> Nil Then Caret := Length(Buf^);
  End;

  Procedure DrawDlg;
  Var L: Integer;
  Begin
   HideMouse;
   DlgFrame(X1, Y1, X2, Y2, 'Informations sur le projet');
   L := X1 + 20;
   DlgLabel(L, Y1 + 36, 'Titre :');
   DlgEdit (L + 100, Y1 + 32, L + 320, Y1 + 50, BufTitle,  Focus = 0,
            Caret * Ord(Focus = 0));
   DlgLabel(L, Y1 + 60, 'Gestionnaire :');
   DlgEdit (L + 100, Y1 + 56, L + 320, Y1 + 74, BufMgr,    Focus = 1,
            Caret * Ord(Focus = 1));
   DlgLabel(L, Y1 + 84, 'Societe :');
   DlgEdit (L + 100, Y1 + 80, L + 320, Y1 + 98, BufComp,   Focus = 2,
            Caret * Ord(Focus = 2));
   DlgLabel(L, Y1 + 108, 'Date debut :');
   DlgEdit (L + 100, Y1 + 104, L + 200, Y1 + 122, BufStart, Focus = 3,
            Caret * Ord(Focus = 3));
   DlgLabel(L + 210, Y1 + 108, 'Etat :');
   DlgEdit (L + 260, Y1 + 104, L + 360, Y1 + 122, BufStatus, Focus = 4,
            Caret * Ord(Focus = 4));
   DlgLabel(L, Y1 + 132, 'Fin calculee :');
   SetColor(CLR_BLACK);
   OutTextXY(L + 100, Y1 + 132, ShortDateStr(Project.FinishDate)
             + '   Duree : '
             + IntToStr(Project.FinishDate - Project.StartDate + 1) + ' j');
   DlgLabel(L, Y1 + 156, 'Notes :');
   DlgEdit (L + 100, Y1 + 152, L + 320, Y1 + 170, BufNotes,   Focus = 5,
            Caret * Ord(Focus = 5));
   DlgLabel(L, Y1 + 184, 'Calendrier : Standard');
   DlgLabel(L, Y1 + 200, 'Taches : ' + IntToStr(Project.TaskCount)
            + '    Ressources : ' + IntToStr(Project.ResCount));
   DlgBtn(BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2, 'OK',     False, Focus = 6);
   DlgBtn(BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2, 'Annuler', False, Focus = 7);
   ShowMouse;
  End;

  Procedure Validate;
  Begin
   Project.Title   := Copy(BufTitle,  1, 60);
   Project.Manager := Copy(BufMgr,    1, 40);
   Project.Company := Copy(BufComp,   1, 40);
   If ParseDateStr(BufStart, NewStart) Then Project.StartDate := NewStart;
   If ParseDateStr(BufStatus, NewStart) Then Project.StatusDate := NewStart;
   Project.Comments := Copy(BufNotes, 1, 120);
   Project.Dirty := True;
   CPMRecompute;
  End;

  Procedure HandleChar(C: Char);
  Begin
   If Buf = Nil Then Exit;
   If (C >= ' ') And (Length(Buf^) < 120) Then Begin
    Insert(C, Buf^, Caret + 1);
    Inc(Caret);
   End;
  End;

Begin
 X1 := 140; Y1 := 80; X2 := 500; Y2 := 380;
 BtnOkX1 := X2 - 180; BtnOkY1 := Y2 - 38; BtnOkX2 := X2 - 110; BtnOkY2 := Y2 - 14;
 BtnCnX1 := X2 - 100; BtnCnY1 := Y2 - 38; BtnCnX2 := X2 - 30;  BtnCnY2 := Y2 - 14;
 BufTitle := Project.Title;
 BufMgr   := Project.Manager;
 BufComp  := Project.Company;
 BufStart := ShortDateStr(Project.StartDate);
 BufStatus:= ShortDateStr(Project.StatusDate);
 BufNotes := Project.Comments;
 Focus := 0;
 FocusBuf;
 Done := False;
 DrawDlg;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #15: Begin                              { Shift+Tab }
           If Focus > 0 Then Dec(Focus) Else Focus := 7;
           FocusBuf;
          End;
     #75: If (Buf <> Nil) And (Caret > 0) Then Dec(Caret);
     #77: If (Buf <> Nil) And (Caret < Length(Buf^)) Then Inc(Caret);
     #71: If Buf <> Nil Then Caret := 0;
     #79: If Buf <> Nil Then Caret := Length(Buf^);
     #83: If (Buf <> Nil) And (Caret < Length(Buf^)) Then
           Delete(Buf^, Caret + 1, 1);
    End;
   End
   Else
    Case K Of
     #9:  Begin
           If Focus < 7 Then Inc(Focus) Else Focus := 0;
           FocusBuf;
          End;
     #13: Begin Validate; Done := True; End;
     #27: Done := True;
     #8:  If (Buf <> Nil) And (Caret > 0) Then Begin
           Delete(Buf^, Caret, 1); Dec(Caret);
          End;
    Else HandleChar(K);
    End;
   BlinkState := True;
   DrawDlg;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2) Then
    Begin Validate; Done := True; End
   Else If InRect(Mouse.X, Mouse.Y, BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2) Then
    Done := True
   Else Begin
    For I := 0 To 5 Do
     If InRect(Mouse.X, Mouse.Y, X1 + 120, Y1 + 32 + I * 24,
               X1 + 340, Y1 + 50 + I * 24) Then Begin
      Focus := I; FocusBuf; DrawDlg; Break;
     End;
   End;
  End;
  Inc(TickCount);
  If TickCount Mod 8 = 0 Then Begin
   BlinkState := Not BlinkState;
   If Focus <= 5 Then DrawDlg;
  End;
 Until Done;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       DIALOGUE INFOS TACHE                             }
{ ====================================================================== }

Procedure DoTaskInfoDialog;
Var X1, Y1, X2, Y2: Integer;
    Tab, Focus, I, J: Integer;
    BufName, BufDur, BufStart, BufFinish, BufPct, BufPrio,
    BufWBS, BufCost, BufWork, BufNotes, BufRes,
    BufPred, BufConstrDt: String;
    BufConstr: Integer;
    BufMilestone, BufSummary: Boolean;
    Buf: ^String;
    Caret: Integer;
    K, K2: Char; Done: Boolean;
    BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2: Integer;
    BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2: Integer;
    T: PTask;
    Tabs: Array[0..3] Of String;
    TabX: Array[0..3] Of Integer;
    NewDt: TDate;

  Procedure FocusBuf;
  Begin
   Buf := Nil;
   Case Tab Of
    0: Case Focus Of                  { General }
        0: Buf := @BufName;
        1: Buf := @BufDur;
        2: Buf := @BufStart;
        3: Buf := @BufFinish;
        4: Buf := @BufPct;
        5: Buf := @BufPrio;
       End;
    1: Case Focus Of                  { Predecesseurs }
        0: Buf := @BufPred;
       End;
    2: Case Focus Of                  { Ressources }
        0: Buf := @BufRes;
       End;
    3: Case Focus Of                  { Avancees }
        0: Buf := @BufWBS;
        1: Buf := @BufCost;
        2: Buf := @BufWork;
        3: Buf := @BufConstrDt;
        4: Buf := @BufNotes;
       End;
   End;
   If Buf <> Nil Then Caret := Length(Buf^);
  End;

  Function ConstrName(C: Integer): String;
  Begin
   Case C Of
    CT_ASAP:    ConstrName := 'Des que possible';
    CT_ALAP:    ConstrName := 'Le plus tard possible';
    CT_MSO:     ConstrName := 'Doit commencer le';
    CT_MFO:     ConstrName := 'Doit finir le';
    CT_SNET:    ConstrName := 'Debut au plus tot le';
    CT_FNLT:    ConstrName := 'Fin au plus tard le';
   Else ConstrName := '?';
   End;
  End;

  Procedure DrawTabs;
  Var IT: Integer;
  Begin
   For IT := 0 To 3 Do
    DlgTab(TabX[IT], Y1 + 24, 90, Tabs[IT], IT = Tab);
   SetColor(CLR_WIN_HI);
   HLine(X1 + 8, X2 - 8, Y1 + 46, CLR_WIN_HI);
  End;

  Procedure DrawGeneral;
  Var L: Integer;
  Begin
   L := X1 + 20;
   DlgLabel(L, Y1 + 64, 'Nom :');
   DlgEdit (L + 80, Y1 + 60, L + 340, Y1 + 78, BufName, (Focus = 0), Caret * Ord(Focus = 0));
   DlgLabel(L, Y1 + 88, 'Duree :');
   DlgEdit (L + 80, Y1 + 84, L + 180, Y1 + 102, BufDur, (Focus = 1), Caret * Ord(Focus = 1));
   DlgLabel(L + 200, Y1 + 88, '% acheve :');
   DlgEdit (L + 280, Y1 + 84, L + 340, Y1 + 102, BufPct, (Focus = 4), Caret * Ord(Focus = 4));
   DlgLabel(L, Y1 + 112, 'Debut :');
   DlgEdit (L + 80, Y1 + 108, L + 180, Y1 + 126, BufStart, (Focus = 2), Caret * Ord(Focus = 2));
   DlgLabel(L + 200, Y1 + 112, 'Fin :');
   DlgEdit (L + 280, Y1 + 108, L + 380, Y1 + 126, BufFinish, (Focus = 3), Caret * Ord(Focus = 3));
   DlgLabel(L, Y1 + 136, 'Priorite :');
   DlgEdit (L + 80, Y1 + 132, L + 140, Y1 + 150, BufPrio, (Focus = 5), Caret * Ord(Focus = 5));
   DlgCheck(L + 200, Y1 + 134, 'Jalon',      BufMilestone, Focus = 6);
   DlgCheck(L + 280, Y1 + 134, 'Recap.',     BufSummary,   Focus = 7);
   DlgLabel(L, Y1 + 160, 'Marge totale : ' + IntToStr(T^.TotalSlack) + ' j');
   DlgLabel(L + 200, Y1 + 160, 'Marge libre : ' + IntToStr(T^.FreeSlack) + ' j');
   If T^.Critical Then DlgLabel(L, Y1 + 178, 'TACHE CRITIQUE');
  End;

  Procedure DrawPredecessors;
  Var L, Y, IP, PIdx: Integer; P: PTask; LT: String;
  Begin
   L := X1 + 20;
   DlgLabel(L, Y1 + 60, 'Liste des predecesseurs (Id, Type, Decalage) :');
   For IP := 1 To T^.PredCount Do Begin
    Y := Y1 + 80 + (IP - 1) * 16;
    If Y > Y2 - 80 Then Break;
    PIdx := FindTaskByIdField(T^.Pred[IP].TaskId);
    Case T^.Pred[IP].LinkType Of
     LT_FS: LT := 'FD';
     LT_SS: LT := 'DD';
     LT_FF: LT := 'FF';
     LT_SF: LT := 'DF';
    Else LT := '??';
    End;
    SetColor(CLR_BLACK);
    OutTextXY(L, Y, IntToStr(T^.Pred[IP].TaskId) + '  ' + LT + '  '
              + IntToStr(T^.Pred[IP].Lag) + 'j  ');
    If (PIdx > 0) And (Project.Tasks[PIdx] <> Nil) Then
     OutTextXY(L + 140, Y, Project.Tasks[PIdx]^.Name);
   End;
   DlgLabel(L, Y2 - 70, 'Saisir (ex: 3FD+2j, 5DD) :');
   DlgEdit (L + 180, Y2 - 74, L + 340, Y2 - 56, BufPred, Focus = 0,
            Caret * Ord(Focus = 0));
   DlgBtn  (L + 350, Y2 - 76, L + 410, Y2 - 56, 'Ajouter', False, False);
  End;

  Procedure DrawResources;
  Var L, Y, IR: Integer;
  Begin
   L := X1 + 20;
   DlgLabel(L, Y1 + 60, 'Ressources affectees :');
   SetColor(CLR_BLACK);
   OutTextXY(L, Y1 + 80, T^.Resources);
   DlgLabel(L, Y1 + 110, 'Pool de ressources :');
   For IR := 1 To Project.ResCount Do Begin
    Y := Y1 + 130 + (IR - 1) * 14;
    If Y > Y2 - 80 Then Break;
    If Project.Resources[IR] <> Nil Then
     OutTextXY(L + 20, Y, IntToStr(IR) + '. '
               + Project.Resources[IR]^.Name + '  ('
               + Project.Resources[IR]^.Initials + ')');
   End;
   DlgLabel(L, Y2 - 70, 'Editer (CSV) :');
   DlgEdit (L + 100, Y2 - 74, L + 420, Y2 - 56, BufRes, Focus = 0,
            Caret * Ord(Focus = 0));
  End;

  Procedure DrawAdvanced;
  Var L: Integer;
  Begin
   L := X1 + 20;
   DlgLabel(L, Y1 + 64, 'WBS :');
   DlgEdit (L + 100, Y1 + 60, L + 260, Y1 + 78, BufWBS, Focus = 0,
            Caret * Ord(Focus = 0));
   DlgLabel(L, Y1 + 88, 'Cout fixe :');
   DlgEdit (L + 100, Y1 + 84, L + 260, Y1 + 102, BufCost, Focus = 1,
            Caret * Ord(Focus = 1));
   DlgLabel(L, Y1 + 112, 'Travail (h) :');
   DlgEdit (L + 100, Y1 + 108, L + 260, Y1 + 126, BufWork, Focus = 2,
            Caret * Ord(Focus = 2));
   DlgLabel(L, Y1 + 136, 'Contrainte :');
   SetColor(CLR_WIN_LO);
   Rectangle(L + 100, Y1 + 132, L + 280, Y1 + 150);
   SetColor(CLR_BLACK);
   OutTextXY(L + 104, Y1 + 135, ConstrName(BufConstr));
   DlgLabel(L + 290, Y1 + 136, 'Date :');
   DlgEdit (L + 340, Y1 + 132, L + 440, Y1 + 150, BufConstrDt, Focus = 3,
            Caret * Ord(Focus = 3));
   DlgLabel(L, Y1 + 160, 'Notes :');
   DlgEdit (L + 100, Y1 + 156, L + 440, Y1 + 174, BufNotes, Focus = 4,
            Caret * Ord(Focus = 4));
  End;

  Procedure DrawDlg;
  Begin
   HideMouse;
   DlgFrame(X1, Y1, X2, Y2, 'Informations sur la tache - '
            + IntToStr(T^.Id) + ' ' + T^.Name);
   DrawTabs;
   FillBox(X1 + 4, Y1 + 47, X2 - 4, Y2 - 50, CLR_DLG_BG);
   Case Tab Of
    0: DrawGeneral;
    1: DrawPredecessors;
    2: DrawResources;
    3: DrawAdvanced;
   End;
   DlgBtn(BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2, 'OK', False, False);
   DlgBtn(BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2, 'Annuler', False, False);
   ShowMouse;
  End;

  Procedure CycleConstr;
  Begin
   Inc(BufConstr);
   If BufConstr > CT_FNLT Then BufConstr := CT_ASAP;
  End;

  Procedure ParsePredAdd;
  Var S: String; IT, K3, Lag: Integer; LtCode: Integer; TaskRef: Integer;
  Begin
   S := TrimStr(BufPred);
   If S = '' Then Exit;
   K3 := 1;
   While (K3 <= Length(S)) And (S[K3] >= '0') And (S[K3] <= '9') Do Inc(K3);
   TaskRef := StrToIntDef(Copy(S, 1, K3 - 1), 0);
   If TaskRef = 0 Then Exit;
   LtCode := LT_FS;
   If K3 + 1 <= Length(S) Then Begin
    If (UpCase(S[K3]) = 'F') And (UpCase(S[K3 + 1]) = 'D') Then LtCode := LT_FS
    Else If (UpCase(S[K3]) = 'D') And (UpCase(S[K3 + 1]) = 'D') Then LtCode := LT_SS
    Else If (UpCase(S[K3]) = 'F') And (UpCase(S[K3 + 1]) = 'F') Then LtCode := LT_FF
    Else If (UpCase(S[K3]) = 'D') And (UpCase(S[K3 + 1]) = 'F') Then LtCode := LT_SF;
    Inc(K3, 2);
   End;
   Lag := 0;
   If K3 <= Length(S) Then Begin
    IT := K3;
    If (S[K3] = '+') Or (S[K3] = '-') Then Inc(K3);
    While (K3 <= Length(S)) And (S[K3] >= '0') And (S[K3] <= '9') Do Inc(K3);
    Lag := StrToIntDef(Copy(S, IT, K3 - IT), 0);
   End;
   If T^.PredCount >= MAX_PRED Then Exit;
   Inc(T^.PredCount);
   T^.Pred[T^.PredCount].TaskId   := TaskRef;
   T^.Pred[T^.PredCount].LinkType := LtCode;
   T^.Pred[T^.PredCount].Lag      := Lag;
   BufPred := '';
   Caret := 0;
  End;

  Procedure Validate;
  Begin
   T^.Name     := Copy(BufName, 1, 60);
   T^.Duration := StrToIntDef(BufDur, T^.Duration Div 10) * 10;
   If ParseDateStr(BufStart, NewDt) Then T^.Start := NewDt;
   If ParseDateStr(BufFinish, NewDt) Then T^.Finish := NewDt;
   T^.PercentDone := StrToIntDef(BufPct, T^.PercentDone);
   If T^.PercentDone > 100 Then T^.PercentDone := 100;
   T^.Priority := StrToIntDef(BufPrio, T^.Priority);
   T^.IsMilestone := BufMilestone;
   T^.IsSummary   := BufSummary;
   T^.WBS    := Copy(BufWBS, 1, 20);
   T^.Cost   := StrToIntDef(BufCost, T^.Cost Div 100) * 100;
   T^.Work   := StrToIntDef(BufWork, T^.Work Div 10) * 10;
   T^.ConstraintTyp := BufConstr;
   If ParseDateStr(BufConstrDt, NewDt) Then T^.ConstraintDt := NewDt;
   T^.Notes  := Copy(BufNotes, 1, 120);
   T^.Resources := Copy(BufRes, 1, 60);
   Project.Dirty := True;
   CPMRecompute;
  End;

  Procedure HandleChar(C: Char);
  Begin
   If Buf = Nil Then Exit;
   If (C >= ' ') And (Length(Buf^) < 120) Then Begin
    Insert(C, Buf^, Caret + 1);
    Inc(Caret);
   End;
  End;

Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 X1 := 80; Y1 := 50; X2 := 560; Y2 := 420;
 BtnOkX1 := X2 - 180; BtnOkY1 := Y2 - 38; BtnOkX2 := X2 - 110; BtnOkY2 := Y2 - 14;
 BtnCnX1 := X2 - 100; BtnCnY1 := Y2 - 38; BtnCnX2 := X2 - 30;  BtnCnY2 := Y2 - 14;
 Tabs[0] := 'General';
 Tabs[1] := 'Predecesseurs';
 Tabs[2] := 'Ressources';
 Tabs[3] := 'Avancees';
 For I := 0 To 3 Do TabX[I] := X1 + 10 + I * 92;
 BufName    := T^.Name;
 BufDur     := IntToStr(T^.Duration Div 10);
 BufStart   := ShortDateStr(T^.Start);
 BufFinish  := ShortDateStr(T^.Finish);
 BufPct     := IntToStr(T^.PercentDone);
 BufPrio    := IntToStr(T^.Priority);
 BufMilestone := T^.IsMilestone;
 BufSummary   := T^.IsSummary;
 BufWBS     := T^.WBS;
 BufCost    := IntToStr(T^.Cost Div 100);
 BufWork    := IntToStr(T^.Work Div 10);
 BufConstr  := T^.ConstraintTyp;
 BufConstrDt:= ShortDateStr(T^.ConstraintDt);
 BufNotes   := T^.Notes;
 BufRes     := T^.Resources;
 BufPred    := '';
 Tab := 0; Focus := 0;
 FocusBuf;
 Done := False;
 DrawDlg;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #75: If (Buf <> Nil) And (Caret > 0) Then Dec(Caret);
     #77: If (Buf <> Nil) And (Caret < Length(Buf^)) Then Inc(Caret);
     #71: If Buf <> Nil Then Caret := 0;
     #79: If Buf <> Nil Then Caret := Length(Buf^);
     #83: If (Buf <> Nil) And (Caret < Length(Buf^)) Then
           Delete(Buf^, Caret + 1, 1);
     #59,#60,#61,#62: Begin                 { F1..F4 = changement onglet }
      Tab := Ord(K2) - 59;
      Focus := 0; FocusBuf;
     End;
    End;
   End
   Else
    Case K Of
     #9:  Begin
           Inc(Focus);
           Case Tab Of
            0: If Focus > 7 Then Begin
                Focus := 0;
                Inc(Tab); If Tab > 3 Then Tab := 0;
               End;
            1: If Focus > 0 Then Begin Focus := 0; Inc(Tab); If Tab > 3 Then Tab := 0; End;
            2: If Focus > 0 Then Begin Focus := 0; Inc(Tab); If Tab > 3 Then Tab := 0; End;
            3: If Focus > 4 Then Begin Focus := 0; Inc(Tab); If Tab > 3 Then Tab := 0; End;
           End;
           FocusBuf;
          End;
     #13: Begin
           If (Tab = 0) And (Focus = 6) Then BufMilestone := Not BufMilestone
           Else If (Tab = 0) And (Focus = 7) Then BufSummary := Not BufSummary
           Else If Tab = 1 Then ParsePredAdd
           Else Begin Validate; Done := True; End;
          End;
     #27: Done := True;
     #32: If (Tab = 0) And (Focus = 6) Then BufMilestone := Not BufMilestone
          Else If (Tab = 0) And (Focus = 7) Then BufSummary := Not BufSummary
          Else HandleChar(K);
     #8:  If (Buf <> Nil) And (Caret > 0) Then Begin
           Delete(Buf^, Caret, 1); Dec(Caret);
          End;
    Else HandleChar(K);
    End;
   BlinkState := True;
   DrawDlg;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2) Then
    Begin Validate; Done := True; End
   Else If InRect(Mouse.X, Mouse.Y, BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2) Then
    Done := True
   Else Begin
    For J := 0 To 3 Do
     If InRect(Mouse.X, Mouse.Y, TabX[J], Y1 + 24, TabX[J] + 88, Y1 + 46) Then Begin
      Tab := J; Focus := 0; FocusBuf; DrawDlg; Break;
     End;
    If (Tab = 3) And InRect(Mouse.X, Mouse.Y, X1 + 120, Y1 + 132,
                              X1 + 300, Y1 + 150) Then Begin
     CycleConstr; DrawDlg;
    End;
   End;
  End;
  Inc(TickCount);
  If TickCount Mod 8 = 0 Then Begin
   BlinkState := Not BlinkState;
   If Buf <> Nil Then DrawDlg;
  End;
 Until Done;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       DIALOGUE SUIVI (Phase 6)                         }
{ ====================================================================== }

Procedure DoTrackingDialog;
Var X1, Y1, X2, Y2: Integer;
    BufPct, BufActS, BufActF, BufActD, BufRemD: String;
    Focus: Integer;
    Buf: ^String;
    Caret: Integer;
    K, K2: Char;
    Done: Boolean;
    BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2: Integer;
    BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2: Integer;
    T: PTask; D: TDate; V: LongInt; E: Integer;

  Procedure FocusBuf;
  Begin
   Case Focus Of
    0: Buf := @BufPct;
    1: Buf := @BufActS;
    2: Buf := @BufActF;
    3: Buf := @BufActD;
    4: Buf := @BufRemD;
   Else Buf := Nil;
   End;
   If Buf <> Nil Then Caret := Length(Buf^);
  End;

  Procedure DrawDlg;
  Var L: Integer;
  Begin
   HideMouse;
   DlgFrame(X1, Y1, X2, Y2, 'Mettre a jour les taches');
   L := X1 + 20;
   DlgLabel(L, Y1 + 36, 'Tache : ' + T^.Name);
   DlgLabel(L, Y1 + 60, '% acheve :');
   DlgEdit (L + 130, Y1 + 56, L + 230, Y1 + 74, BufPct,  Focus = 0,
            Caret * Ord(Focus = 0));
   DlgLabel(L, Y1 + 84, 'Debut reel :');
   DlgEdit (L + 130, Y1 + 80, L + 280, Y1 + 98, BufActS, Focus = 1,
            Caret * Ord(Focus = 1));
   DlgLabel(L, Y1 + 108, 'Fin reelle :');
   DlgEdit (L + 130, Y1 + 104, L + 280, Y1 + 122, BufActF, Focus = 2,
            Caret * Ord(Focus = 2));
   DlgLabel(L, Y1 + 132, 'Duree reelle (j) :');
   DlgEdit (L + 130, Y1 + 128, L + 230, Y1 + 146, BufActD, Focus = 3,
            Caret * Ord(Focus = 3));
   DlgLabel(L, Y1 + 156, 'Duree restante (j) :');
   DlgEdit (L + 130, Y1 + 152, L + 230, Y1 + 170, BufRemD, Focus = 4,
            Caret * Ord(Focus = 4));
   DlgLabel(L, Y1 + 188, 'Planifie : ' + ShortDateStr(T^.Start) + ' -> '
            + ShortDateStr(T^.Finish)
            + '   Duree ' + IntToStr(T^.Duration Div 10) + ' j');
   DlgBtn(BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2, 'OK',     False, Focus = 5);
   DlgBtn(BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2, 'Annuler', False, Focus = 6);
   ShowMouse;
  End;

  Procedure Validate;
  Begin
   Val(BufPct, V, E);
   If E = 0 Then Begin
    If V < 0 Then V := 0;
    If V > 100 Then V := 100;
    T^.PercentDone := Byte(V);
   End;
   If ParseDateStr(BufActS, D) Then T^.ActualStart := D;
   If ParseDateStr(BufActF, D) Then T^.ActualFinish := D;
   Val(BufActD, V, E);
   If E = 0 Then T^.ActualDur := V * 10;
   Val(BufRemD, V, E);
   If E = 0 Then T^.RemainingDur := V * 10;
   UpdateActualsFromPercent(T);
   Project.Dirty := True;
  End;

  Procedure HandleChar(C: Char);
  Begin
   If Buf = Nil Then Exit;
   If (C >= ' ') And (Length(Buf^) < 30) Then Begin
    Insert(C, Buf^, Caret + 1);
    Inc(Caret);
   End;
  End;

Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 X1 := 140; Y1 := 100; X2 := 500; Y2 := 340;
 BtnOkX1 := X2 - 180; BtnOkY1 := Y2 - 38; BtnOkX2 := X2 - 110; BtnOkY2 := Y2 - 14;
 BtnCnX1 := X2 - 100; BtnCnY1 := Y2 - 38; BtnCnX2 := X2 - 30;  BtnCnY2 := Y2 - 14;
 BufPct  := IntToStr(T^.PercentDone);
 BufActS := ShortDateStr(T^.ActualStart);
 If T^.ActualStart = 0 Then BufActS := '';
 BufActF := ShortDateStr(T^.ActualFinish);
 If T^.ActualFinish = 0 Then BufActF := '';
 BufActD := IntToStr(T^.ActualDur Div 10);
 BufRemD := IntToStr(T^.RemainingDur Div 10);
 Focus := 0;
 FocusBuf;
 Done := False;
 DrawDlg;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #15: Begin If Focus > 0 Then Dec(Focus) Else Focus := 6; FocusBuf; End;
     #75: If (Buf <> Nil) And (Caret > 0) Then Dec(Caret);
     #77: If (Buf <> Nil) And (Caret < Length(Buf^)) Then Inc(Caret);
     #71: If Buf <> Nil Then Caret := 0;
     #79: If Buf <> Nil Then Caret := Length(Buf^);
     #83: If (Buf <> Nil) And (Caret < Length(Buf^)) Then
           Delete(Buf^, Caret + 1, 1);
    End;
   End
   Else
    Case K Of
     #9:  Begin If Focus < 6 Then Inc(Focus) Else Focus := 0; FocusBuf; End;
     #13: Begin Validate; Done := True; End;
     #27: Done := True;
     #8:  If (Buf <> Nil) And (Caret > 0) Then Begin
           Delete(Buf^, Caret, 1); Dec(Caret);
          End;
    Else HandleChar(K);
    End;
   BlinkState := True;
   DrawDlg;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2) Then
    Begin Validate; Done := True; End
   Else If InRect(Mouse.X, Mouse.Y, BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2) Then
    Done := True;
  End;
  Inc(TickCount);
  If TickCount Mod 8 = 0 Then Begin
   BlinkState := Not BlinkState;
   If Focus <= 4 Then DrawDlg;
  End;
 Until Done;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       DIALOGUE TABLEAU RESSOURCES                      }
{ ====================================================================== }

Procedure DoResourceSheetDialog;
Var X1, Y1, X2, Y2: Integer;
    SelRow, ScrollY, FocusCol: Integer;
    EditingCell: Boolean;
    Caret: Integer;
    EditTxt: String;
    K, K2: Char; Done: Boolean;
    BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2: Integer;
    BtnAddX1, BtnAddX2: Integer;
    BtnDelX1, BtnDelX2: Integer;
    BtnY1, BtnY2: Integer;
    RowH, HdrY, BodyY1, BodyY2: Integer;
    ColX: Array[0..6] Of Integer;
    ColW: Array[0..5] Of Integer;
    ColLbl: Array[0..5] Of String;
    I, J, RowCnt: Integer;
    R: PResource;

  Function VisibleRows: Integer;
  Begin
   VisibleRows := (BodyY2 - BodyY1) Div RowH;
  End;

  Procedure CellTextOf(R: PResource; Col: Integer; Var S: String);
  Begin
   Case Col Of
    0: S := IntToStr(R^.Id);
    1: S := R^.Name;
    2: S := R^.Initials;
    3: S := R^.Grp;
    4: S := IntToStr(R^.MaxUnits) + '%';
    5: S := IntToStr(R^.StdRate Div 100);
   Else S := '';
   End;
  End;

  Procedure CommitCell;
  Var V: LongInt;
  Begin
   If Not EditingCell Then Exit;
   If (SelRow < 1) Or (SelRow > Project.ResCount) Then Begin
    EditingCell := False; Exit;
   End;
   R := Project.Resources[SelRow];
   If R = Nil Then Begin EditingCell := False; Exit; End;
   Case FocusCol Of
    1: R^.Name := Copy(EditTxt, 1, 40);
    2: R^.Initials := Copy(EditTxt, 1, 8);
    3: R^.Grp    := Copy(EditTxt, 1, 20);
    4: Begin
        V := StrToIntDef(EditTxt, 100);
        If V < 0 Then V := 0; If V > 1000 Then V := 1000;
        R^.MaxUnits := V;
       End;
    5: Begin
        V := StrToIntDef(EditTxt, 0);
        R^.StdRate := V * 100;
       End;
   End;
   EditingCell := False;
   Project.Dirty := True;
  End;

  Procedure StartEdit;
  Var S: String;
  Begin
   If FocusCol = 0 Then Exit;
   If (SelRow < 1) Or (SelRow > Project.ResCount) Then Exit;
   R := Project.Resources[SelRow];
   If R = Nil Then Exit;
   CellTextOf(R, FocusCol, S);
   EditTxt := S;
   Caret := Length(EditTxt);
   EditingCell := True;
  End;

  Procedure DrawHdr;
  Var IC, Cx: Integer;
  Begin
   FillBox(X1 + 8, HdrY, X2 - 8, HdrY + RowH - 1, CLR_LGRAY);
   SetColor(CLR_WIN_LO);
   HLine(X1 + 8, X2 - 8, HdrY + RowH - 1, CLR_WIN_LO);
   For IC := 0 To 5 Do Begin
    Cx := ColX[IC];
    SetColor(CLR_BLACK);
    OutTextXY(Cx + 4, HdrY + 4, ColLbl[IC]);
    SetColor(CLR_WIN_LO);
    VLine(ColX[IC + 1] - 1, HdrY, HdrY + RowH - 1, CLR_WIN_LO);
   End;
  End;

  Procedure DrawRow(RowIdx, ResIdx: Integer);
  Var Y, IC, Cx: Integer; Rr: PResource; S: String; Bg, Fg: Integer;
  Begin
   Y := BodyY1 + RowIdx * RowH;
   If Y + RowH > BodyY2 Then Exit;
   If ResIdx = SelRow Then Begin Bg := CLR_GRID_SEL_BG; Fg := CLR_WHITE; End
   Else Begin Bg := CLR_WHITE; Fg := CLR_BLACK; End;
   FillBox(X1 + 8, Y, X2 - 8, Y + RowH - 1, Bg);
   If (ResIdx < 1) Or (ResIdx > Project.ResCount) Then Exit;
   Rr := Project.Resources[ResIdx];
   If Rr = Nil Then Exit;
   For IC := 0 To 5 Do Begin
    Cx := ColX[IC];
    CellTextOf(Rr, IC, S);
    If EditingCell And (ResIdx = SelRow) And (IC = FocusCol) Then Begin
     FillBox(Cx + 1, Y + 1, ColX[IC + 1] - 2, Y + RowH - 2, CLR_WHITE);
     SetColor(CLR_BLACK);
     OutTextXY(Cx + 4, Y + 4, EditTxt);
     If BlinkState Then
      VLine(Cx + 4 + TextWidth(Copy(EditTxt, 1, Caret)),
            Y + 2, Y + RowH - 3, CLR_BLACK);
    End
    Else Begin
     SetColor(Fg);
     OutTextXY(Cx + 4, Y + 4, S);
    End;
    SetColor(CLR_GRID_LINE);
    VLine(ColX[IC + 1] - 1, Y, Y + RowH - 1, CLR_GRID_LINE);
   End;
   HLine(X1 + 8, X2 - 8, Y + RowH - 1, CLR_GRID_LINE);
  End;

  Procedure DrawDlg;
  Var IR: Integer;
  Begin
   HideMouse;
   DlgFrame(X1, Y1, X2, Y2, 'Tableau des ressources');
   DrawHdr;
   RowCnt := VisibleRows;
   For IR := 0 To RowCnt - 1 Do
    DrawRow(IR, ScrollY + IR + 1);
   DlgBtn(BtnAddX1, BtnY1, BtnAddX2, BtnY2, 'Ajouter', False, False);
   DlgBtn(BtnDelX1, BtnY1, BtnDelX2, BtnY2, 'Supprimer', False, False);
   DlgBtn(BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2, 'OK', False, False);
   ShowMouse;
  End;

  Procedure AddResource;
  Var Rn: PResource;
  Begin
   If Project.ResCount >= MAX_RESOURCES Then Exit;
   Rn := NewResource;
   Inc(Project.ResCount);
   Rn^.Id := Project.ResCount;
   Rn^.Name := 'Nouvelle ressource';
   Rn^.Initials := 'NR';
   Rn^.MaxUnits := 100;
   Rn^.StdRate := 5000;
   Project.Resources[Project.ResCount] := Rn;
   SelRow := Project.ResCount;
   Project.Dirty := True;
  End;

  Procedure DelResource;
  Var IX: Integer;
  Begin
   If (SelRow < 1) Or (SelRow > Project.ResCount) Then Exit;
   If Project.Resources[SelRow] <> Nil Then
    FreeMem(Project.Resources[SelRow], SizeOf(TResource));
   For IX := SelRow To Project.ResCount - 1 Do Begin
    Project.Resources[IX] := Project.Resources[IX + 1];
    If Project.Resources[IX] <> Nil Then Project.Resources[IX]^.Id := IX;
   End;
   Project.Resources[Project.ResCount] := Nil;
   Dec(Project.ResCount);
   If SelRow > Project.ResCount Then SelRow := Project.ResCount;
   If SelRow < 1 Then SelRow := 1;
   Project.Dirty := True;
  End;

  Procedure HandleChar(C: Char);
  Begin
   If Not EditingCell Then Exit;
   If (C >= ' ') And (Length(EditTxt) < 60) Then Begin
    Insert(C, EditTxt, Caret + 1);
    Inc(Caret);
   End;
  End;

  Procedure EnsureVisible;
  Begin
   If SelRow - 1 < ScrollY Then ScrollY := SelRow - 1;
   If SelRow - 1 >= ScrollY + VisibleRows Then
    ScrollY := SelRow - VisibleRows;
   If ScrollY < 0 Then ScrollY := 0;
  End;

Begin
 X1 := 60; Y1 := 60; X2 := 580; Y2 := 410;
 RowH := 16;
 HdrY := Y1 + 28;
 BodyY1 := HdrY + RowH;
 BodyY2 := Y2 - 50;
 BtnOkY1 := Y2 - 38; BtnOkY2 := Y2 - 14;
 BtnOkX1 := X2 - 100; BtnOkX2 := X2 - 20;
 BtnY1 := Y2 - 38; BtnY2 := Y2 - 14;
 BtnAddX1 := X1 + 20; BtnAddX2 := X1 + 110;
 BtnDelX1 := X1 + 120; BtnDelX2 := X1 + 220;
 ColW[0] := 30; ColW[1] := 160; ColW[2] := 60; ColW[3] := 100;
 ColW[4] := 60; ColW[5] := 80;
 ColLbl[0] := 'Id'; ColLbl[1] := 'Nom'; ColLbl[2] := 'Init.';
 ColLbl[3] := 'Groupe'; ColLbl[4] := 'Max'; ColLbl[5] := 'Cout/h';
 ColX[0] := X1 + 8;
 For I := 1 To 6 Do ColX[I] := ColX[I - 1] + ColW[I - 1];
 SelRow := 1; ScrollY := 0; FocusCol := 1;
 EditingCell := False;
 If Project.ResCount = 0 Then SelRow := 0;
 Done := False;
 DrawDlg;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #72: Begin
           If EditingCell Then CommitCell;
           If SelRow > 1 Then Dec(SelRow); EnsureVisible;
          End;
     #80: Begin
           If EditingCell Then CommitCell;
           If SelRow < Project.ResCount Then Inc(SelRow); EnsureVisible;
          End;
     #75: If EditingCell Then Begin
           If Caret > 0 Then Dec(Caret);
          End
          Else If FocusCol > 1 Then Dec(FocusCol);
     #77: If EditingCell Then Begin
           If Caret < Length(EditTxt) Then Inc(Caret);
          End
          Else If FocusCol < 5 Then Inc(FocusCol);
     #71: If EditingCell Then Caret := 0;
     #79: If EditingCell Then Caret := Length(EditTxt);
     #83: If EditingCell And (Caret < Length(EditTxt)) Then
           Delete(EditTxt, Caret + 1, 1);
     #82: AddResource;       { Ins }
     #93: DelResource;       { Shift+Del approx }
    End;
   End
   Else
    Case K Of
     #13: If EditingCell Then Begin CommitCell;
           If SelRow < Project.ResCount Then Inc(SelRow);
          End
          Else StartEdit;
     #9:  Begin
           If EditingCell Then CommitCell;
           If FocusCol < 5 Then Inc(FocusCol) Else FocusCol := 1;
          End;
     #27: If EditingCell Then EditingCell := False Else Done := True;
     #8:  If EditingCell And (Caret > 0) Then Begin
           Delete(EditTxt, Caret, 1); Dec(Caret);
          End;
    Else
     If (K >= ' ') And Not EditingCell Then Begin
      StartEdit;
      EditTxt := '';
      Caret := 0;
      HandleChar(K);
     End
     Else HandleChar(K);
    End;
   BlinkState := True;
   DrawDlg;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2) Then Begin
    If EditingCell Then CommitCell;
    Done := True;
   End
   Else If InRect(Mouse.X, Mouse.Y, BtnAddX1, BtnY1, BtnAddX2, BtnY2) Then
    Begin AddResource; DrawDlg; End
   Else If InRect(Mouse.X, Mouse.Y, BtnDelX1, BtnY1, BtnDelX2, BtnY2) Then
    Begin DelResource; DrawDlg; End
   Else If InRect(Mouse.X, Mouse.Y, X1 + 8, BodyY1, X2 - 8, BodyY2) Then Begin
    If EditingCell Then CommitCell;
    SelRow := ScrollY + (Mouse.Y - BodyY1) Div RowH + 1;
    If SelRow > Project.ResCount Then SelRow := Project.ResCount;
    For J := 0 To 5 Do
     If (Mouse.X >= ColX[J]) And (Mouse.X < ColX[J + 1]) Then Begin
      FocusCol := J; Break;
     End;
    DrawDlg;
   End;
  End;
  Inc(TickCount);
  If TickCount Mod 8 = 0 Then Begin
   BlinkState := Not BlinkState;
   If EditingCell Then DrawDlg;
  End;
 Until Done;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{           PHASE 7 : DIALOGUE OUVRIR / ENREGISTRER (Visio) + CSV        }
{ ====================================================================== }

Const
 FILT_COUNT = 7;
 FILT_NAMES: Array[1..FILT_COUNT] Of String[40] = (
  'Microsoft Project (*.MPP;*.MPT)',
  'Microsoft Project Database (*.MPD)',
  'Microsoft Project Exchange (*.MPX)',
  'XML Project 2003 (*.XML)',
  'Plantilla MS Project (*.PPM)',
  'Valeurs separees par virgule (*.CSV)',
  'Tous les fichiers (*.*)');
 FILT_MASKS: Array[1..FILT_COUNT] Of String[16] = (
  '*.MPP', '*.MPD', '*.MPX', '*.XML', '*.PPM', '*.CSV', '*.*');
 FDLG_MAX = 256;

Var
 FDlgItems   : Array[1..FDLG_MAX] Of String[40];
 FDlgIsDir   : Array[1..FDLG_MAX] Of Boolean;
 FDlgCount   : Integer;
 FDlgCurDir  : String;

Function ExtMatchesMask(Const Name, Mask: String): Boolean;
Var E, M: String; I: Integer;
Begin
 ExtMatchesMask := False;
 If Mask = '*.*' Then Begin ExtMatchesMask := True; Exit; End;
 I := Pos('.', Mask);
 If I = 0 Then Exit;
 M := Copy(Mask, I, Length(Mask) - I + 1);
 I := Length(Name);
 While (I > 0) And (Name[I] <> '.') Do Dec(I);
 If I = 0 Then Exit;
 E := Copy(Name, I, Length(Name) - I + 1);
 For I := 1 To Length(E) Do E[I] := UpCase(E[I]);
 For I := 1 To Length(M) Do M[I] := UpCase(M[I]);
 ExtMatchesMask := E = M;
End;

Procedure FDlgScanDir(Const Mask: String);
Var SR: SearchRec; Sub: String;
Begin
 FDlgCount := 0;
 { Dossiers d'abord }
 FindFirst('*.*', Directory, SR);
 While DosError = 0 Do Begin
  If ((SR.Attr And Directory) <> 0) And (SR.Name <> '.') Then Begin
   If FDlgCount < FDLG_MAX Then Begin
    Inc(FDlgCount);
    Sub := SR.Name;
    If Length(Sub) > 38 Then Sub := Copy(Sub, 1, 38);
    FDlgItems[FDlgCount] := '[' + Sub + ']';
    FDlgIsDir[FDlgCount] := True;
   End;
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC} FindClose(SR); {$ENDIF}
 { Puis fichiers correspondants au masque }
 FindFirst(Mask, Archive Or ReadOnly, SR);
 While DosError = 0 Do Begin
  If (SR.Attr And Directory) = 0 Then
   If FDlgCount < FDLG_MAX Then Begin
    Inc(FDlgCount);
    Sub := SR.Name;
    If Length(Sub) > 38 Then Sub := Copy(Sub, 1, 38);
    FDlgItems[FDlgCount] := Sub;
    FDlgIsDir[FDlgCount] := False;
   End;
  FindNext(SR);
 End;
 {$IFDEF FPC} FindClose(SR); {$ENDIF}
End;

Procedure FDlgUpdateDir;
Var D: String;
Begin
 GetDir(0, D);
 FDlgCurDir := D;
End;

Function DoFileDialog(IsSave: Boolean; Var FName: String;
                     Var FiltIdx: Integer): Boolean;
Var X1, Y1, X2, Y2: Integer;
    Focus: Integer; { 0=name 1=list 2=filter 3=ok 4=cancel 5=up }
    Buf: String;
    Caret: Integer;
    Sel, ScrY, Rows: Integer;
    K, K2: Char;
    Done, Result: Boolean;
    BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2: Integer;
    BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2: Integer;
    BtnUpX1, BtnUpY1, BtnUpX2, BtnUpY2: Integer;
    LstX1, LstY1, LstX2, LstY2: Integer;
    EditX1, EditY1, EditX2, EditY2: Integer;
    FltX1, FltY1, FltX2, FltY2: Integer;
    I, J: Integer;

  Procedure Refresh;
  Begin
   FDlgUpdateDir;
   FDlgScanDir(FILT_MASKS[FiltIdx]);
   If Sel > FDlgCount Then Sel := FDlgCount;
   If Sel < 1 Then Sel := 1;
   ScrY := 0;
  End;

  Procedure DrawList;
  Var I2, Yy: Integer; S: String;
  Begin
   FillBox(LstX1, LstY1, LstX2, LstY2, CLR_WHITE);
   SetColor(CLR_WIN_LO); Rectangle(LstX1, LstY1, LstX2, LstY2);
   For I2 := 0 To Rows - 1 Do Begin
    Yy := LstY1 + 2 + I2 * 14;
    If (ScrY + I2 + 1) > FDlgCount Then Break;
    If (ScrY + I2 + 1) = Sel Then Begin
     FillBox(LstX1 + 2, Yy, LstX2 - 2, Yy + 13, CLR_LBLUE);
     SetColor(CLR_WHITE);
    End
    Else SetColor(CLR_BLACK);
    S := FDlgItems[ScrY + I2 + 1];
    OutTextXY(LstX1 + 6, Yy + 3, S);
   End;
  End;

  Procedure DrawDlg;
  Var Title: String; S: String;
  Begin
   HideMouse;
   If IsSave Then Title := 'Enregistrer sous' Else Title := 'Ouvrir';
   DlgFrame(X1, Y1, X2, Y2, Title);
   DlgLabel(X1 + 12, Y1 + 32, 'Dossier :');
   S := FDlgCurDir;
   If Length(S) > 48 Then S := '...' + Copy(S, Length(S) - 44, 45);
   DlgLabel(X1 + 80, Y1 + 32, S);
   DlgBtn(BtnUpX1, BtnUpY1, BtnUpX2, BtnUpY2, '..', False, Focus = 5);
   DrawList;
   DlgLabel(X1 + 12, EditY1 - 14, 'Nom du fichier :');
   DlgEdit (EditX1, EditY1, EditX2, EditY2, Buf, Focus = 0,
            Caret * Ord(Focus = 0));
   DlgLabel(X1 + 12, FltY1 - 14, 'Type :');
   DlgEdit (FltX1, FltY1, FltX2, FltY2, FILT_NAMES[FiltIdx],
            Focus = 2, -1);
   DlgBtn(BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2,
          'OK', False, Focus = 3);
   DlgBtn(BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2,
          'Annuler', False, Focus = 4);
   ShowMouse;
  End;

  Procedure NextFilter;
  Begin
   Inc(FiltIdx);
   If FiltIdx > FILT_COUNT Then FiltIdx := 1;
   Refresh;
  End;

  Procedure GoUp;
  Begin
   ChDir('..');
   Refresh;
   Buf := ''; Caret := 0;
  End;

  Procedure ActivateSel;
  Begin
   If (Sel < 1) Or (Sel > FDlgCount) Then Exit;
   If FDlgIsDir[Sel] Then Begin
    ChDir(Copy(FDlgItems[Sel], 2, Length(FDlgItems[Sel]) - 2));
    Refresh;
    Buf := ''; Caret := 0;
   End
   Else Begin
    Buf := FDlgItems[Sel];
    Caret := Length(Buf);
   End;
  End;

  Procedure DoAccept;
  Begin
   If (Buf = '') And (Sel >= 1) And (Sel <= FDlgCount)
      And (Not FDlgIsDir[Sel]) Then Buf := FDlgItems[Sel];
   If Buf = '' Then Exit;
   { ajoute extension si manquante (Save) }
   If IsSave And (Pos('.', Buf) = 0) Then Begin
    Case FiltIdx Of
     1: Buf := Buf + '.MPP';
     2: Buf := Buf + '.MPD';
     3: Buf := Buf + '.MPX';
     4: Buf := Buf + '.XML';
     5: Buf := Buf + '.PPM';
     6: Buf := Buf + '.CSV';
    End;
   End;
   { si pas de chemin, prefixe dossier courant }
   If (Pos(':', Buf) = 0) And (Pos('\', Buf) = 0)
      And (Pos('/', Buf) = 0) Then Begin
    If (Length(FDlgCurDir) > 0)
       And (FDlgCurDir[Length(FDlgCurDir)] <> '\')
       And (FDlgCurDir[Length(FDlgCurDir)] <> '/') Then
     FName := FDlgCurDir + '\' + Buf
    Else FName := FDlgCurDir + Buf;
   End
   Else FName := Buf;
   Result := True;
   Done := True;
  End;

Begin
 X1 := 70; Y1 := 60; X2 := 570; Y2 := 410;
 LstX1 := X1 + 12; LstY1 := Y1 + 52; LstX2 := X2 - 12; LstY2 := Y1 + 252;
 EditX1 := X1 + 120; EditY1 := LstY2 + 26;
 EditX2 := X2 - 12; EditY2 := EditY1 + 18;
 FltX1 := X1 + 120; FltY1 := EditY2 + 16;
 FltX2 := X2 - 12; FltY2 := FltY1 + 18;
 BtnOkX1 := X2 - 180; BtnOkY1 := Y2 - 36; BtnOkX2 := X2 - 100; BtnOkY2 := Y2 - 12;
 BtnCnX1 := X2 - 90;  BtnCnY1 := Y2 - 36; BtnCnX2 := X2 - 12;  BtnCnY2 := Y2 - 12;
 BtnUpX1 := X2 - 50;  BtnUpY1 := Y1 + 26; BtnUpX2 := X2 - 12;  BtnUpY2 := Y1 + 46;
 Rows := (LstY2 - LstY1 - 4) Div 14;
 Buf := FName;
 Caret := Length(Buf);
 If (FiltIdx < 1) Or (FiltIdx > FILT_COUNT) Then FiltIdx := 1;
 Focus := 0;
 Sel := 1; ScrY := 0;
 Refresh;
 Done := False; Result := False;
 DrawDlg;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #15: Begin If Focus > 0 Then Dec(Focus) Else Focus := 5; End;
     #72: If Focus = 1 Then Begin
           If Sel > 1 Then Dec(Sel);
           If Sel - 1 < ScrY Then ScrY := Sel - 1;
          End;
     #80: If Focus = 1 Then Begin
           If Sel < FDlgCount Then Inc(Sel);
           If Sel - 1 >= ScrY + Rows Then ScrY := Sel - Rows;
          End;
     #73: If Focus = 1 Then Begin
           Sel := Sel - Rows; If Sel < 1 Then Sel := 1;
           ScrY := Sel - 1;
          End;
     #81: If Focus = 1 Then Begin
           Sel := Sel + Rows;
           If Sel > FDlgCount Then Sel := FDlgCount;
           ScrY := Sel - Rows; If ScrY < 0 Then ScrY := 0;
          End;
     #75: If Focus = 0 Then Begin
           If Caret > 0 Then Dec(Caret);
          End;
     #77: If Focus = 0 Then Begin
           If Caret < Length(Buf) Then Inc(Caret);
          End;
     #83: If (Focus = 0) And (Caret < Length(Buf)) Then
           Delete(Buf, Caret + 1, 1);
    End;
   End
   Else
    Case K Of
     #9:  Begin
           If Focus < 5 Then Inc(Focus) Else Focus := 0;
          End;
     #13: Begin
           Case Focus Of
            1: ActivateSel;
            2: NextFilter;
            5: GoUp;
            4: Done := True;
           Else DoAccept;
           End;
          End;
     #27: Done := True;
     #8:  If (Focus = 0) And (Caret > 0) Then Begin
           Delete(Buf, Caret, 1); Dec(Caret);
          End;
    Else
     If (K >= ' ') And (Focus = 0) And (Length(Buf) < 80) Then Begin
      Insert(K, Buf, Caret + 1); Inc(Caret);
     End;
    End;
   BlinkState := True;
   DrawDlg;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, BtnOkX1, BtnOkY1, BtnOkX2, BtnOkY2) Then
    DoAccept
   Else If InRect(Mouse.X, Mouse.Y, BtnCnX1, BtnCnY1, BtnCnX2, BtnCnY2) Then
    Done := True
   Else If InRect(Mouse.X, Mouse.Y, BtnUpX1, BtnUpY1, BtnUpX2, BtnUpY2) Then
    GoUp
   Else If InRect(Mouse.X, Mouse.Y, FltX1, FltY1, FltX2, FltY2) Then
    NextFilter
   Else If InRect(Mouse.X, Mouse.Y, EditX1, EditY1, EditX2, EditY2) Then
    Focus := 0
   Else If InRect(Mouse.X, Mouse.Y, LstX1, LstY1, LstX2, LstY2) Then Begin
    Focus := 1;
    I := (Mouse.Y - LstY1 - 2) Div 14;
    J := ScrY + I + 1;
    If (J >= 1) And (J <= FDlgCount) Then Begin
     If (Sel = J) And DoubleClicked Then ActivateSel
     Else Sel := J;
    End;
   End;
   DrawDlg;
  End;
  Inc(TickCount);
  If TickCount Mod 8 = 0 Then Begin
   BlinkState := Not BlinkState;
   If Focus = 0 Then DrawDlg;
  End;
 Until Done;
 DoFileDialog := Result;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       CSV : LECTURE / ECRITURE                         }
{ ====================================================================== }

Function CsvField(Const S: String): String;
Var I: Integer; R: String; Q: Boolean;
Begin
 Q := False;
 R := '';
 For I := 1 To Length(S) Do Begin
  If (S[I] = ',') Or (S[I] = '"') Or (S[I] = #10)
     Or (S[I] = #13) Or (S[I] = ';') Then Q := True;
  If S[I] = '"' Then R := R + '""' Else R := R + S[I];
 End;
 If Q Then CsvField := '"' + R + '"' Else CsvField := R;
End;

Function ParseCsvLine(Const Line: String; Var Fields: Array Of String;
                     Max: Integer): Integer;
Var I, N: Integer; Cur: String; InQ: Boolean;
Begin
 N := 0; Cur := ''; InQ := False;
 I := 1;
 While I <= Length(Line) Do Begin
  If InQ Then Begin
   If Line[I] = '"' Then Begin
    If (I < Length(Line)) And (Line[I + 1] = '"') Then Begin
     Cur := Cur + '"'; Inc(I);
    End
    Else InQ := False;
   End
   Else Cur := Cur + Line[I];
  End
  Else Begin
   If Line[I] = '"' Then InQ := True
   Else If (Line[I] = ',') Or (Line[I] = ';') Then Begin
    If N < Max Then Begin Fields[N] := Cur; Inc(N); End;
    Cur := '';
   End
   Else Cur := Cur + Line[I];
  End;
  Inc(I);
 End;
 If N < Max Then Begin Fields[N] := Cur; Inc(N); End;
 ParseCsvLine := N;
End;

Function SaveProjectCSV(Const FName: String): Boolean;
Var F: Text; I: Integer; T: PTask;
Begin
 SaveProjectCSV := False;
 Assign(F, FName);
 {$I-} Rewrite(F); {$I+}
 If IOResult <> 0 Then Exit;
 WriteLn(F, 'Id,Niveau,Nom,Duree,Debut,Fin,PercentDone,Cost,Work,Predecesseurs,Ressources,Jalon,Recapitulatif,Notes');
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  Write(F, T^.Id, ',', T^.OutlineLv, ',');
  Write(F, CsvField(T^.Name), ',');
  Write(F, T^.Duration Div 10, ',');
  Write(F, CsvField(ShortDateStr(T^.Start)), ',');
  Write(F, CsvField(ShortDateStr(T^.Finish)), ',');
  Write(F, T^.PercentDone, ',');
  Write(F, T^.Cost, ',');
  Write(F, T^.Work, ',');
  Write(F, CsvField(''), ',');
  Write(F, CsvField(T^.Resources), ',');
  Write(F, Ord(T^.IsMilestone), ',');
  Write(F, Ord(T^.IsSummary), ',');
  WriteLn(F, CsvField(T^.Notes));
 End;
 Close(F);
 SaveProjectCSV := IOResult = 0;
End;

Function LoadProjectCSV(Const FName: String): Boolean;
Var F: Text; Line: String; N, LineNo: Integer;
    Fields: Array[0..15] Of String;
    T: PTask; D: TDate; V, E: LongInt;
Begin
 LoadProjectCSV := False;
 Assign(F, FName);
 {$I-} Reset(F); {$I+}
 If IOResult <> 0 Then Exit;
 InitProject;
 LineNo := 0;
 While Not Eof(F) Do Begin
  ReadLn(F, Line);
  Inc(LineNo);
  If (Line = '') Or (LineNo = 1) Then Continue;
  N := ParseCsvLine(Line, Fields, 14);
  If N < 3 Then Continue;
  If Project.TaskCount >= MAX_TASKS Then Break;
  T := NewTask;
  If T = Nil Then Break;
  Inc(Project.TaskCount);
  Project.Tasks[Project.TaskCount] := T;
  T^.Id := Project.TaskCount;
  Val(Fields[1], V, E); If E = 0 Then T^.OutlineLv := Byte(V);
  T^.Name := Copy(Fields[2], 1, 60);
  Val(Fields[3], V, E); If E = 0 Then T^.Duration := V * 10;
  If ParseDateStr(Fields[4], D) Then T^.Start := D;
  If ParseDateStr(Fields[5], D) Then T^.Finish := D;
  Val(Fields[6], V, E); If E = 0 Then T^.PercentDone := Byte(V);
  Val(Fields[7], V, E); If E = 0 Then T^.Cost := V;
  Val(Fields[8], V, E); If E = 0 Then T^.Work := V;
  T^.Resources := Copy(Fields[10], 1, 60);
  Val(Fields[11], V, E); T^.IsMilestone := (E = 0) And (V <> 0);
  Val(Fields[12], V, E); T^.IsSummary := (E = 0) And (V <> 0);
  T^.Notes := Copy(Fields[13], 1, 120);
 End;
 Close(F);
 Project.FileName := FName;
 Project.Dirty := False;
 CPMRecompute;
 LoadProjectCSV := True;
End;

{ ====================================================================== }
{        STUBS FORMATS (Phases 8..10 implementeront le contenu)          }
{ ====================================================================== }

Function SaveProjectMPX(Const FName: String): Boolean; Forward;
Function LoadProjectMPX(Const FName: String): Boolean; Forward;
Function SaveProjectXML(Const FName: String): Boolean; Forward;
Function LoadProjectXML(Const FName: String): Boolean; Forward;
Function SaveProjectMPP(Const FName: String): Boolean; Forward;
Function LoadProjectMPP(Const FName: String): Boolean; Forward;

Function SaveProjectMPX(Const FName: String): Boolean;
Var F: Text; I: Integer; T: PTask; R: PResource;
Begin
 SaveProjectMPX := False;
 Assign(F, FName);
 {$I-} Rewrite(F); {$I+}
 If IOResult <> 0 Then Exit;
 { En-tete MPX 4.0 (Microsoft Project Exchange) }
 WriteLn(F, 'MPX,4.0,ANSI');
 WriteLn(F, '10,$,2,$,1,.,0,0,0,0');
 WriteLn(F, '11,h,d,8,40,20,1,8,17,d');
 WriteLn(F, '12,mm/dd/yy,12,17,9,m,1,1,1');
 WriteLn(F, '20,Standard,1,1,1,1,1,1,0');
 WriteLn(F, '25,8:00,12:00,13:00,17:00');
 { Record 30 : Project Header }
 Write(F, '30,');
 Write(F, CsvField(Project.Title), ',');
 Write(F, CsvField(Project.Subject), ',');
 Write(F, CsvField(Project.Manager), ',');
 Write(F, CsvField(''), ',');                  { Keywords }
 Write(F, CsvField(Project.Comments), ',');
 Write(F, CsvField(Project.Manager), ',');     { Manager }
 Write(F, CsvField(Project.Company), ',');
 Write(F, 'Standard,');
 Write(F, CsvField(ShortDateStr(Project.StartDate)), ',');
 Write(F, CsvField(ShortDateStr(Project.FinishDate)), ',');
 Write(F, CsvField(ShortDateStr(Project.StatusDate)), ',');
 WriteLn(F, '8.00,40.00');
 { Modeles de champs : declarent l'ordre des colonnes }
 { Record 40 = Resource Field Numeric : ID, MaxUnits, StdRate, OvtRate, Cost }
 WriteLn(F, '40,32,41,51,44,26');
 { Record 41 = Resource Field Text    : Name, Initials, Group, Notes }
 WriteLn(F, '41,1,2,3,22');
 { Ressources : un record 50 par ressource (champs numeriques puis texte) }
 For I := 1 To Project.ResCount Do Begin
  R := Project.Resources[I];
  If R = Nil Then Continue;
  Write(F, '50,', R^.Id, ',', R^.MaxUnits, ',', R^.StdRate, ',',
         R^.OvtRate, ',', R^.CostPerUse, ',');
  Write(F, CsvField(R^.Name), ',');
  Write(F, CsvField(R^.Initials), ',');
  Write(F, CsvField(R^.Grp), ',');
  WriteLn(F, CsvField(''));
 End;
 { Record 70 = Task Field Numeric : ID, UID, OutlineLv, Duration, %Done,
   Cost, Work, Milestone, Summary }
 WriteLn(F, '70,45,86,50,30,12,24,88,35,36');
 { Record 71 = Task Field Text   : Name, Start, Finish, Resources,
   Predecessors, Notes, WBS }
 WriteLn(F, '71,1,80,39,33,71,20,75');
 { Taches : un record 70 par tache }
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  Write(F, '70,', T^.Id, ',', T^.Id, ',', T^.OutlineLv, ',',
         T^.Duration Div 10, ',', T^.PercentDone, ',',
         T^.Cost, ',', T^.Work, ',',
         Ord(T^.IsMilestone), ',', Ord(T^.IsSummary), ',');
  Write(F, CsvField(T^.Name), ',');
  Write(F, CsvField(ShortDateStr(T^.Start)), ',');
  Write(F, CsvField(ShortDateStr(T^.Finish)), ',');
  Write(F, CsvField(T^.Resources), ',');
  Write(F, CsvField(''), ',');                  { Predecesseurs }
  Write(F, CsvField(T^.Notes), ',');
  WriteLn(F, CsvField(T^.WBS));
 End;
 Close(F);
 SaveProjectMPX := IOResult = 0;
End;

Function LoadProjectMPX(Const FName: String): Boolean;
Var F: Text; Line: String; N: Integer;
    Fields: Array[0..40] Of String;
    T: PTask; R: PResource; D: TDate; V, E: LongInt;
    RecType: Integer;
Begin
 LoadProjectMPX := False;
 Assign(F, FName);
 {$I-} Reset(F); {$I+}
 If IOResult <> 0 Then Exit;
 { Premiere ligne : doit commencer par MPX }
 ReadLn(F, Line);
 If Copy(Line, 1, 3) <> 'MPX' Then Begin Close(F); Exit; End;
 InitProject;
 While Not Eof(F) Do Begin
  ReadLn(F, Line);
  If Line = '' Then Continue;
  N := ParseCsvLine(Line, Fields, 40);
  If N < 1 Then Continue;
  Val(Fields[0], RecType, E);
  If E <> 0 Then Continue;
  Case RecType Of
   30: Begin
    If N > 1 Then Project.Title    := Copy(Fields[1], 1, 60);
    If N > 2 Then Project.Subject  := Copy(Fields[2], 1, 60);
    If N > 5 Then Project.Comments := Copy(Fields[5], 1, 120);
    If N > 6 Then Project.Manager  := Copy(Fields[6], 1, 40);
    If N > 7 Then Project.Company  := Copy(Fields[7], 1, 40);
    If (N > 9)  And ParseDateStr(Fields[9],  D) Then Project.StartDate  := D;
    If (N > 10) And ParseDateStr(Fields[10], D) Then Project.FinishDate := D;
    If (N > 11) And ParseDateStr(Fields[11], D) Then Project.StatusDate := D;
   End;
   50: Begin
    { Modele MPX : ID, MaxUnits, StdRate, OvtRate, Cost, Name, Init, Grp, Notes }
    If Project.ResCount >= MAX_RESOURCES Then Continue;
    R := NewResource;
    If R = Nil Then Continue;
    Inc(Project.ResCount);
    Project.Resources[Project.ResCount] := R;
    R^.Id := Project.ResCount;
    If N > 1 Then Begin Val(Fields[1], V, E);
                  If E = 0 Then R^.Id := Word(V); End;
    If N > 2 Then Begin Val(Fields[2], V, E);
                  If E = 0 Then R^.MaxUnits := Word(V); End;
    If N > 3 Then Begin Val(Fields[3], V, E);
                  If E = 0 Then R^.StdRate := V; End;
    If N > 4 Then Begin Val(Fields[4], V, E);
                  If E = 0 Then R^.OvtRate := V; End;
    If N > 5 Then Begin Val(Fields[5], V, E);
                  If E = 0 Then R^.CostPerUse := V; End;
    If N > 6 Then R^.Name     := Copy(Fields[6], 1, 40);
    If N > 7 Then R^.Initials := Copy(Fields[7], 1, 8);
    If N > 8 Then R^.Grp      := Copy(Fields[8], 1, 20);
   End;
   70: Begin
    { Si premiere occurrence et tous champs numeriques : c'est la
      definition de modele (ignore). Detection heuristique : si plus de
      moitie des champs sont des entiers purs ET texte est court. }
    { Modele MPX : ID, UID, OutlineLv, Duration, %Done, Cost, Work,
      Milestone, Summary, Name, Start, Finish, Resources, Pred, Notes, WBS }
    If Project.TaskCount >= MAX_TASKS Then Continue;
    If N < 10 Then Continue;
    T := NewTask;
    If T = Nil Then Continue;
    Inc(Project.TaskCount);
    Project.Tasks[Project.TaskCount] := T;
    T^.Id := Project.TaskCount;
    Val(Fields[1], V, E); If E = 0 Then T^.Id := Word(V);
    Val(Fields[3], V, E); If E = 0 Then T^.OutlineLv := Byte(V);
    Val(Fields[4], V, E); If E = 0 Then T^.Duration := V * 10;
    Val(Fields[5], V, E); If E = 0 Then T^.PercentDone := Byte(V);
    Val(Fields[6], V, E); If E = 0 Then T^.Cost := V;
    Val(Fields[7], V, E); If E = 0 Then T^.Work := V;
    Val(Fields[8], V, E); T^.IsMilestone := (E = 0) And (V <> 0);
    Val(Fields[9], V, E); T^.IsSummary   := (E = 0) And (V <> 0);
    If N > 10 Then T^.Name := Copy(Fields[10], 1, 60);
    If (N > 11) And ParseDateStr(Fields[11], D) Then T^.Start  := D;
    If (N > 12) And ParseDateStr(Fields[12], D) Then T^.Finish := D;
    If N > 13 Then T^.Resources := Copy(Fields[13], 1, 60);
    If N > 15 Then T^.Notes     := Copy(Fields[15], 1, 120);
    If N > 16 Then T^.WBS       := Copy(Fields[16], 1, 20);
   End;
  End;
 End;
 Close(F);
 Project.FileName := FName;
 Project.Dirty := False;
 CPMRecompute;
 LoadProjectMPX := True;
End;
Function SaveProjectXML(Const FName: String): Boolean;
Var F: Text; I, J: Integer; T: PTask; R: PResource;

  Function XmlEsc(Const S: String): String;
  Var K: Integer; R: String;
  Begin
   R := '';
   For K := 1 To Length(S) Do
    Case S[K] Of
     '&':  R := R + '&amp;';
     '<':  R := R + '&lt;';
     '>':  R := R + '&gt;';
     '"':  R := R + '&quot;';
     '''': R := R + '&apos;';
    Else R := R + S[K];
    End;
   XmlEsc := R;
  End;

  Function XmlDateTime(JDN: TDate): String;
  Var Y, M, D: Integer; S: String;
  Begin
   If JDN <= 0 Then Begin XmlDateTime := '2000-01-01T08:00:00'; Exit; End;
   JDNToDate(JDN, Y, M, D);
   S := IntToStr(Y) + '-';
   If M < 10 Then S := S + '0';
   S := S + IntToStr(M) + '-';
   If D < 10 Then S := S + '0';
   S := S + IntToStr(D) + 'T08:00:00';
   XmlDateTime := S;
  End;

  Function XmlDuration(Tenths: LongInt): String;
  Var H: LongInt;
  Begin
   { Duration en jours dixiemes -> heures (8h/jour ouvrable) }
   H := (Tenths * 8) Div 10;
   XmlDuration := 'PT' + IntToStr(H) + 'H0M0S';
  End;

  Function XmlWorkH(Hours: LongInt): String;
  Begin
   XmlWorkH := 'PT' + IntToStr(Hours) + 'H0M0S';
  End;

  Function XmlMoney(V: LongInt): String;
  Var S: String;
  Begin
   { Stocke en cents ? Notre Cost est entier - on emet en .00 }
   S := IntToStr(V);
   XmlMoney := S + '.00';
  End;

Begin
 SaveProjectXML := False;
 Assign(F, FName);
 {$I-} Rewrite(F); {$I+}
 If IOResult <> 0 Then Exit;
 WriteLn(F, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 WriteLn(F, '<Project xmlns="http://schemas.microsoft.com/project">');
 WriteLn(F, '  <Name>', XmlEsc(FName), '</Name>');
 WriteLn(F, '  <Title>', XmlEsc(Project.Title), '</Title>');
 WriteLn(F, '  <Subject>', XmlEsc(Project.Subject), '</Subject>');
 WriteLn(F, '  <Author>', XmlEsc(Project.Manager), '</Author>');
 WriteLn(F, '  <Manager>', XmlEsc(Project.Manager), '</Manager>');
 WriteLn(F, '  <Company>', XmlEsc(Project.Company), '</Company>');
 WriteLn(F, '  <Comments>', XmlEsc(Project.Comments), '</Comments>');
 WriteLn(F, '  <ScheduleFromStart>1</ScheduleFromStart>');
 WriteLn(F, '  <StartDate>', XmlDateTime(Project.StartDate), '</StartDate>');
 WriteLn(F, '  <FinishDate>', XmlDateTime(Project.FinishDate), '</FinishDate>');
 WriteLn(F, '  <StatusDate>', XmlDateTime(Project.StatusDate), '</StatusDate>');
 WriteLn(F, '  <CalendarUID>1</CalendarUID>');
 WriteLn(F, '  <DefaultStartTime>08:00:00</DefaultStartTime>');
 WriteLn(F, '  <DefaultFinishTime>17:00:00</DefaultFinishTime>');
 WriteLn(F, '  <MinutesPerDay>480</MinutesPerDay>');
 WriteLn(F, '  <MinutesPerWeek>2400</MinutesPerWeek>');
 WriteLn(F, '  <DaysPerMonth>20</DaysPerMonth>');
 { ----- Calendriers ----- }
 WriteLn(F, '  <Calendars>');
 WriteLn(F, '    <Calendar>');
 WriteLn(F, '      <UID>1</UID>');
 WriteLn(F, '      <Name>Standard</Name>');
 WriteLn(F, '      <IsBaseCalendar>1</IsBaseCalendar>');
 WriteLn(F, '      <BaseCalendarUID>-1</BaseCalendarUID>');
 WriteLn(F, '      <WeekDays>');
 For I := 1 To 7 Do Begin
  WriteLn(F, '        <WeekDay>');
  WriteLn(F, '          <DayType>', I, '</DayType>');
  If (I = 1) Or (I = 7) Then
   WriteLn(F, '          <DayWorking>0</DayWorking>')
  Else Begin
   WriteLn(F, '          <DayWorking>1</DayWorking>');
   WriteLn(F, '          <WorkingTimes>');
   WriteLn(F, '            <WorkingTime>');
   WriteLn(F, '              <FromTime>08:00:00</FromTime>');
   WriteLn(F, '              <ToTime>12:00:00</ToTime>');
   WriteLn(F, '            </WorkingTime>');
   WriteLn(F, '            <WorkingTime>');
   WriteLn(F, '              <FromTime>13:00:00</FromTime>');
   WriteLn(F, '              <ToTime>17:00:00</ToTime>');
   WriteLn(F, '            </WorkingTime>');
   WriteLn(F, '          </WorkingTimes>');
  End;
  WriteLn(F, '        </WeekDay>');
 End;
 WriteLn(F, '      </WeekDays>');
 WriteLn(F, '    </Calendar>');
 WriteLn(F, '  </Calendars>');
 { ----- Taches ----- }
 WriteLn(F, '  <Tasks>');
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  WriteLn(F, '    <Task>');
  WriteLn(F, '      <UID>', T^.Id, '</UID>');
  WriteLn(F, '      <ID>',  T^.Id, '</ID>');
  WriteLn(F, '      <Name>', XmlEsc(T^.Name), '</Name>');
  WriteLn(F, '      <Type>0</Type>');
  WriteLn(F, '      <IsNull>0</IsNull>');
  WriteLn(F, '      <Active>1</Active>');
  WriteLn(F, '      <CreateDate>', XmlDateTime(Project.StartDate), '</CreateDate>');
  WriteLn(F, '      <WBS>', XmlEsc(T^.WBS), '</WBS>');
  WriteLn(F, '      <OutlineLevel>', T^.OutlineLv + 1, '</OutlineLevel>');
  WriteLn(F, '      <Priority>', T^.Priority, '</Priority>');
  WriteLn(F, '      <Start>',  XmlDateTime(T^.Start),  '</Start>');
  WriteLn(F, '      <Finish>', XmlDateTime(T^.Finish), '</Finish>');
  WriteLn(F, '      <Duration>', XmlDuration(T^.Duration), '</Duration>');
  WriteLn(F, '      <DurationFormat>7</DurationFormat>');
  WriteLn(F, '      <Work>', XmlWorkH(T^.Work), '</Work>');
  WriteLn(F, '      <Cost>', XmlMoney(T^.Cost), '</Cost>');
  WriteLn(F, '      <FixedCost>0</FixedCost>');
  WriteLn(F, '      <PercentComplete>', T^.PercentDone, '</PercentComplete>');
  WriteLn(F, '      <PercentWorkComplete>', T^.PercentWork, '</PercentWorkComplete>');
  WriteLn(F, '      <Milestone>', Ord(T^.IsMilestone), '</Milestone>');
  WriteLn(F, '      <Summary>',   Ord(T^.IsSummary),   '</Summary>');
  WriteLn(F, '      <Critical>',  Ord(T^.Critical),    '</Critical>');
  WriteLn(F, '      <ConstraintType>', T^.ConstraintTyp, '</ConstraintType>');
  If T^.ConstraintDt > 0 Then
   WriteLn(F, '      <ConstraintDate>',
           XmlDateTime(T^.ConstraintDt), '</ConstraintDate>');
  If T^.BaselineStart > 0 Then Begin
   WriteLn(F, '      <BaselineStart>',
           XmlDateTime(T^.BaselineStart), '</BaselineStart>');
   WriteLn(F, '      <BaselineFinish>',
           XmlDateTime(T^.BaselineFinish), '</BaselineFinish>');
   WriteLn(F, '      <BaselineDuration>',
           XmlDuration(T^.BaselineDur), '</BaselineDuration>');
   WriteLn(F, '      <BaselineCost>', XmlMoney(T^.BaselineCost), '</BaselineCost>');
  End;
  If T^.ActualStart > 0 Then
   WriteLn(F, '      <ActualStart>',
           XmlDateTime(T^.ActualStart), '</ActualStart>');
  If T^.ActualFinish > 0 Then
   WriteLn(F, '      <ActualFinish>',
           XmlDateTime(T^.ActualFinish), '</ActualFinish>');
  WriteLn(F, '      <RemainingDuration>',
          XmlDuration(T^.RemainingDur), '</RemainingDuration>');
  If T^.Notes <> '' Then
   WriteLn(F, '      <Notes>', XmlEsc(T^.Notes), '</Notes>');
  For J := 1 To T^.PredCount Do Begin
   WriteLn(F, '      <PredecessorLink>');
   WriteLn(F, '        <PredecessorUID>', T^.Pred[J].TaskId, '</PredecessorUID>');
   WriteLn(F, '        <Type>', T^.Pred[J].LinkType, '</Type>');
   WriteLn(F, '        <CrossProject>0</CrossProject>');
   WriteLn(F, '        <LinkLag>', T^.Pred[J].Lag, '</LinkLag>');
   WriteLn(F, '        <LagFormat>7</LagFormat>');
   WriteLn(F, '      </PredecessorLink>');
  End;
  WriteLn(F, '    </Task>');
 End;
 WriteLn(F, '  </Tasks>');
 { ----- Ressources ----- }
 WriteLn(F, '  <Resources>');
 For I := 1 To Project.ResCount Do Begin
  R := Project.Resources[I];
  If R = Nil Then Continue;
  WriteLn(F, '    <Resource>');
  WriteLn(F, '      <UID>', R^.Id, '</UID>');
  WriteLn(F, '      <ID>',  R^.Id, '</ID>');
  WriteLn(F, '      <Name>', XmlEsc(R^.Name), '</Name>');
  WriteLn(F, '      <Type>', R^.ResType, '</Type>');
  WriteLn(F, '      <IsNull>0</IsNull>');
  WriteLn(F, '      <Initials>', XmlEsc(R^.Initials), '</Initials>');
  WriteLn(F, '      <Group>',    XmlEsc(R^.Grp),      '</Group>');
  WriteLn(F, '      <MaxUnits>', R^.MaxUnits / 100.0:0:2, '</MaxUnits>');
  WriteLn(F, '      <StandardRate>', XmlMoney(R^.StdRate), '</StandardRate>');
  WriteLn(F, '      <OvertimeRate>', XmlMoney(R^.OvtRate), '</OvertimeRate>');
  WriteLn(F, '      <CostPerUse>',   XmlMoney(R^.CostPerUse), '</CostPerUse>');
  WriteLn(F, '      <CalendarUID>1</CalendarUID>');
  WriteLn(F, '      <AccrueAt>', R^.Accrue + 1, '</AccrueAt>');
  WriteLn(F, '      <CanLevel>1</CanLevel>');
  WriteLn(F, '      <EmailAddress>', XmlEsc(R^.Email), '</EmailAddress>');
  WriteLn(F, '    </Resource>');
 End;
 WriteLn(F, '  </Resources>');
 { ----- Affectations ----- }
 WriteLn(F, '  <Assignments>');
 For I := 1 To Project.AsgCount Do Begin
  If Project.Assignments[I] = Nil Then Continue;
  WriteLn(F, '    <Assignment>');
  WriteLn(F, '      <UID>', I, '</UID>');
  WriteLn(F, '      <TaskUID>',
          Project.Assignments[I]^.TaskId, '</TaskUID>');
  WriteLn(F, '      <ResourceUID>',
          Project.Assignments[I]^.ResId, '</ResourceUID>');
  WriteLn(F, '      <Units>',
          Project.Assignments[I]^.Units / 100.0:0:2, '</Units>');
  WriteLn(F, '      <Work>',
          XmlWorkH(Project.Assignments[I]^.Work), '</Work>');
  WriteLn(F, '    </Assignment>');
 End;
 WriteLn(F, '  </Assignments>');
 WriteLn(F, '</Project>');
 Close(F);
 SaveProjectXML := IOResult = 0;
End;

{ ---- Mini parseur XML pour lecture du format Project 2003 ---- }
Function LoadProjectXML(Const FName: String): Boolean;
Var F: Text; Buf, Tag, Txt, Path: String;
    Ch: Char;
    InTag, SelfClose, IsEnd, IsDecl, IsComment: Boolean;
    T: PTask; R: PResource; A: PAssignment;
    V, E: LongInt; D: TDate;
    InTask, InResource, InAssignment, InPredLink: Boolean;
    InCalendar, InWeekDay: Boolean;
    LinkPredId, LinkType: Integer;

  Function ParseXmlDate(Const S: String): TDate;
  Var Y, M, Dd, K: Integer; V2: LongInt; E2: Integer; T2: String;
  Begin
   ParseXmlDate := 0;
   K := Pos('T', S);
   If K = 0 Then T2 := S Else T2 := Copy(S, 1, K - 1);
   If Length(T2) < 10 Then Exit;
   Val(Copy(T2, 1, 4), V2, E2); If E2 <> 0 Then Exit; Y := V2;
   Val(Copy(T2, 6, 2), V2, E2); If E2 <> 0 Then Exit; M := V2;
   Val(Copy(T2, 9, 2), V2, E2); If E2 <> 0 Then Exit; Dd := V2;
   ParseXmlDate := DateToJDN(Y, M, Dd);
  End;

  Function ParseHours(Const S: String): LongInt;
  Var I, K, H: Integer; V2: LongInt; E2: Integer;
  Begin
   ParseHours := 0;
   I := Pos('PT', S);
   If I = 0 Then Exit;
   K := Pos('H', S);
   If K = 0 Then Exit;
   Val(Copy(S, I + 2, K - I - 2), V2, E2);
   If E2 = 0 Then ParseHours := V2;
  End;

  Function ParseTenthsFromDuration(Const S: String): LongInt;
  Var H: LongInt;
  Begin
   H := ParseHours(S);
   ParseTenthsFromDuration := (H * 10) Div 8;
  End;

  Function ParseFloatPct(Const S: String): LongInt;
  Var I: Integer; V2: LongInt; F2: LongInt; E2: Integer;
      Whole, Frac: String;
  Begin
   I := Pos('.', S);
   If I = 0 Then Begin
    Val(S, V2, E2);
    If E2 = 0 Then ParseFloatPct := V2 * 100
              Else ParseFloatPct := 0;
    Exit;
   End;
   Whole := Copy(S, 1, I - 1);
   Frac := Copy(S, I + 1, 2);
   While Length(Frac) < 2 Do Frac := Frac + '0';
   Val(Whole, V2, E2); If E2 <> 0 Then V2 := 0;
   Val(Frac,  F2, E2); If E2 <> 0 Then F2 := 0;
   ParseFloatPct := V2 * 100 + F2;
  End;

  Function ParseMoney(Const S: String): LongInt;
  Var I: Integer; V2: LongInt; E2: Integer; W: String;
  Begin
   I := Pos('.', S);
   If I > 0 Then W := Copy(S, 1, I - 1) Else W := S;
   Val(W, V2, E2);
   If E2 = 0 Then ParseMoney := V2 Else ParseMoney := 0;
  End;

  Function XmlUnesc(Const S: String): String;
  Var I, K: Integer; R: String;
  Begin
   R := ''; I := 1;
   While I <= Length(S) Do Begin
    If S[I] = '&' Then Begin
     K := Pos(';', Copy(S, I, Length(S) - I + 1));
     If K > 0 Then Begin
      If Copy(S, I, K) = '&amp;'  Then R := R + '&'
      Else If Copy(S, I, K) = '&lt;'   Then R := R + '<'
      Else If Copy(S, I, K) = '&gt;'   Then R := R + '>'
      Else If Copy(S, I, K) = '&quot;' Then R := R + '"'
      Else If Copy(S, I, K) = '&apos;' Then R := R + ''''
      Else R := R + Copy(S, I, K);
      Inc(I, K); Continue;
     End;
    End;
    R := R + S[I]; Inc(I);
   End;
   XmlUnesc := R;
  End;

  Procedure HandleText;
  Var Trimmed: String; I: Integer;
  Begin
   { Trim leading/trailing whitespace }
   Trimmed := Txt;
   While (Length(Trimmed) > 0)
      And ((Trimmed[1] = ' ') Or (Trimmed[1] = #9)
       Or (Trimmed[1] = #10) Or (Trimmed[1] = #13)) Do
    Delete(Trimmed, 1, 1);
   I := Length(Trimmed);
   While (I > 0) And ((Trimmed[I] = ' ') Or (Trimmed[I] = #9)
       Or (Trimmed[I] = #10) Or (Trimmed[I] = #13)) Do
    Dec(I);
   Trimmed := Copy(Trimmed, 1, I);
   If Trimmed = '' Then Exit;
   Trimmed := XmlUnesc(Trimmed);
   { --- Top-level Project fields --- }
   If (Not InTask) And (Not InResource) And (Not InAssignment)
      And (Not InCalendar) Then Begin
    If Tag = 'Title'      Then Project.Title    := Copy(Trimmed, 1, 60);
    If Tag = 'Subject'    Then Project.Subject  := Copy(Trimmed, 1, 60);
    If Tag = 'Author'     Then Project.Manager  := Copy(Trimmed, 1, 40);
    If Tag = 'Manager'    Then Project.Manager  := Copy(Trimmed, 1, 40);
    If Tag = 'Company'    Then Project.Company  := Copy(Trimmed, 1, 40);
    If Tag = 'Comments'   Then Project.Comments := Copy(Trimmed, 1, 120);
    If Tag = 'StartDate'  Then Project.StartDate  := ParseXmlDate(Trimmed);
    If Tag = 'FinishDate' Then Project.FinishDate := ParseXmlDate(Trimmed);
    If Tag = 'StatusDate' Then Project.StatusDate := ParseXmlDate(Trimmed);
   End;
   { --- Task fields --- }
   If InTask And (T <> Nil) Then Begin
    If Tag = 'UID' Then Begin Val(Trimmed, V, E);
                              If E = 0 Then T^.Id := Word(V); End;
    If Tag = 'Name' Then T^.Name := Copy(Trimmed, 1, 60);
    If Tag = 'WBS'  Then T^.WBS  := Copy(Trimmed, 1, 20);
    If Tag = 'OutlineLevel' Then Begin Val(Trimmed, V, E);
                                       If (E = 0) And (V > 0) Then
                                        T^.OutlineLv := Byte(V - 1); End;
    If Tag = 'Priority' Then Begin Val(Trimmed, V, E);
                                   If E = 0 Then T^.Priority := Word(V); End;
    If Tag = 'Start'  Then T^.Start  := ParseXmlDate(Trimmed);
    If Tag = 'Finish' Then T^.Finish := ParseXmlDate(Trimmed);
    If Tag = 'Duration' Then T^.Duration := ParseTenthsFromDuration(Trimmed);
    If Tag = 'Work' Then T^.Work := ParseHours(Trimmed);
    If Tag = 'Cost' Then T^.Cost := ParseMoney(Trimmed);
    If Tag = 'PercentComplete' Then Begin Val(Trimmed, V, E);
                                          If E = 0 Then T^.PercentDone := Byte(V); End;
    If Tag = 'PercentWorkComplete' Then Begin Val(Trimmed, V, E);
                                              If E = 0 Then T^.PercentWork := Byte(V); End;
    If Tag = 'Milestone' Then T^.IsMilestone := Trimmed = '1';
    If Tag = 'Summary'   Then T^.IsSummary   := Trimmed = '1';
    If Tag = 'Critical'  Then T^.Critical    := Trimmed = '1';
    If Tag = 'ConstraintType' Then Begin Val(Trimmed, V, E);
                                         If E = 0 Then T^.ConstraintTyp := Byte(V); End;
    If Tag = 'ConstraintDate' Then T^.ConstraintDt := ParseXmlDate(Trimmed);
    If Tag = 'BaselineStart'  Then T^.BaselineStart  := ParseXmlDate(Trimmed);
    If Tag = 'BaselineFinish' Then T^.BaselineFinish := ParseXmlDate(Trimmed);
    If Tag = 'BaselineDuration' Then T^.BaselineDur := ParseTenthsFromDuration(Trimmed);
    If Tag = 'ActualStart'    Then T^.ActualStart    := ParseXmlDate(Trimmed);
    If Tag = 'ActualFinish'   Then T^.ActualFinish   := ParseXmlDate(Trimmed);
    If Tag = 'Notes' Then T^.Notes := Copy(Trimmed, 1, 120);
    If InPredLink Then Begin
     If Tag = 'PredecessorUID' Then Begin Val(Trimmed, V, E);
                                          If E = 0 Then LinkPredId := V; End;
     If Tag = 'Type' Then Begin Val(Trimmed, V, E);
                                If E = 0 Then LinkType := V; End;
    End;
   End;
   { --- Resource fields --- }
   If InResource And (R <> Nil) Then Begin
    If Tag = 'UID' Then Begin Val(Trimmed, V, E);
                              If E = 0 Then R^.Id := Word(V); End;
    If Tag = 'Name'     Then R^.Name     := Copy(Trimmed, 1, 40);
    If Tag = 'Initials' Then R^.Initials := Copy(Trimmed, 1, 8);
    If Tag = 'Group'    Then R^.Grp      := Copy(Trimmed, 1, 20);
    If Tag = 'Type' Then Begin Val(Trimmed, V, E);
                               If E = 0 Then R^.ResType := Byte(V); End;
    If Tag = 'MaxUnits' Then R^.MaxUnits := Word(ParseFloatPct(Trimmed));
    If Tag = 'StandardRate' Then R^.StdRate    := ParseMoney(Trimmed);
    If Tag = 'OvertimeRate' Then R^.OvtRate    := ParseMoney(Trimmed);
    If Tag = 'CostPerUse'   Then R^.CostPerUse := ParseMoney(Trimmed);
    If Tag = 'AccrueAt' Then Begin Val(Trimmed, V, E);
                                   If (E = 0) And (V > 0) Then
                                    R^.Accrue := Byte(V - 1); End;
    If Tag = 'EmailAddress' Then R^.Email := Copy(Trimmed, 1, 40);
   End;
   { --- Assignment fields --- }
   If InAssignment And (A <> Nil) Then Begin
    If Tag = 'TaskUID' Then Begin Val(Trimmed, V, E);
                                  If E = 0 Then A^.TaskId := Word(V); End;
    If Tag = 'ResourceUID' Then Begin Val(Trimmed, V, E);
                                      If E = 0 Then A^.ResId := Word(V); End;
    If Tag = 'Units' Then A^.Units := Word(ParseFloatPct(Trimmed));
    If Tag = 'Work'  Then A^.Work  := ParseHours(Trimmed);
   End;
  End;

  Procedure StartElem(Const N: String);
  Begin
   If N = 'Task' Then Begin
    If Project.TaskCount < MAX_TASKS Then Begin
     T := NewTask;
     If T <> Nil Then Begin
      Inc(Project.TaskCount);
      Project.Tasks[Project.TaskCount] := T;
      T^.Id := Project.TaskCount;
      InTask := True;
     End;
    End;
   End
   Else If N = 'Resource' Then Begin
    If Project.ResCount < MAX_RESOURCES Then Begin
     R := NewResource;
     If R <> Nil Then Begin
      Inc(Project.ResCount);
      Project.Resources[Project.ResCount] := R;
      R^.Id := Project.ResCount;
      InResource := True;
     End;
    End;
   End
   Else If N = 'Assignment' Then Begin
    GetMem(A, SizeOf(TAssignment));
    If A <> Nil Then Begin
     FillChar(A^, SizeOf(TAssignment), 0);
     InAssignment := True;
    End;
   End
   Else If N = 'Calendar' Then InCalendar := True
   Else If N = 'WeekDay'  Then InWeekDay := True
   Else If N = 'PredecessorLink' Then Begin
    InPredLink := True;
    LinkPredId := 0; LinkType := 1;
   End;
  End;

  Procedure EndElem(Const N: String);
  Var Idx: Integer;
  Begin
   If N = 'Task' Then InTask := False
   Else If N = 'Resource' Then InResource := False
   Else If N = 'Assignment' Then Begin
    If A <> Nil Then Begin
     If Project.AsgCount < MAX_ASSIGN Then Begin
      Inc(Project.AsgCount);
      Project.Assignments[Project.AsgCount] := A;
     End;
     A := Nil;
    End;
    InAssignment := False;
   End
   Else If N = 'Calendar' Then InCalendar := False
   Else If N = 'WeekDay'  Then InWeekDay  := False
   Else If N = 'PredecessorLink' Then Begin
    If (T <> Nil) And (T^.PredCount < MAX_PRED) And (LinkPredId > 0) Then Begin
     Inc(T^.PredCount);
     Idx := T^.PredCount;
     T^.Pred[Idx].TaskId := Word(LinkPredId);
     T^.Pred[Idx].LinkType := Byte(LinkType);
     T^.Pred[Idx].Lag := 0;
    End;
    InPredLink := False;
   End;
  End;

Begin
 LoadProjectXML := False;
 Assign(F, FName);
 {$I-} Reset(F); {$I+}
 If IOResult <> 0 Then Exit;
 InitProject;
 T := Nil; R := Nil; A := Nil;
 InTask := False; InResource := False; InAssignment := False;
 InCalendar := False; InWeekDay := False; InPredLink := False;
 InTag := False; IsEnd := False; IsDecl := False; IsComment := False;
 SelfClose := False;
 Tag := ''; Txt := ''; Buf := '';
 While Not Eof(F) Do Begin
  ReadLn(F, Buf);
  Buf := Buf + #10;
  V := 1;
  While V <= Length(Buf) Do Begin
   Ch := Buf[V];
   If IsComment Then Begin
    If (Ch = '>') And (V >= 3)
       And (Buf[V - 1] = '-') And (Buf[V - 2] = '-') Then
     IsComment := False;
    Inc(V); Continue;
   End;
   If Ch = '<' Then Begin
    HandleText; Txt := '';
    InTag := True; Tag := ''; IsEnd := False; IsDecl := False;
    SelfClose := False;
    { check for <? or <!-- }
    If (V + 1 <= Length(Buf)) And (Buf[V + 1] = '?') Then Begin
     IsDecl := True; InTag := False;
     { skip till ?> }
     While V <= Length(Buf) Do Begin
      If (Buf[V] = '>') And (V > 1) And (Buf[V - 1] = '?') Then Begin
       Inc(V); Break;
      End;
      Inc(V);
     End;
     Continue;
    End;
    If (V + 3 <= Length(Buf)) And (Buf[V + 1] = '!')
       And (Buf[V + 2] = '-') And (Buf[V + 3] = '-') Then Begin
     IsComment := True; InTag := False;
     Inc(V, 4); Continue;
    End;
    Inc(V);
    If (V <= Length(Buf)) And (Buf[V] = '/') Then Begin
     IsEnd := True; Inc(V);
    End;
    { collect tag name }
    While V <= Length(Buf) Do Begin
     Ch := Buf[V];
     If (Ch = ' ') Or (Ch = '>') Or (Ch = '/') Or (Ch = #9)
        Or (Ch = #10) Or (Ch = #13) Then Break;
     Tag := Tag + Ch;
     Inc(V);
    End;
    { skip attributes }
    While (V <= Length(Buf)) And (Buf[V] <> '>') Do Begin
     If Buf[V] = '/' Then SelfClose := True;
     Inc(V);
    End;
    If V <= Length(Buf) Then Inc(V); { skip > }
    InTag := False;
    If IsEnd Then EndElem(Tag)
    Else Begin
     StartElem(Tag);
     If SelfClose Then EndElem(Tag);
    End;
   End
   Else Begin
    Txt := Txt + Ch;
    Inc(V);
   End;
  End;
  HandleText; Txt := '';
 End;
 Close(F);
 Project.FileName := FName;
 Project.Dirty := False;
 CPMRecompute;
 LoadProjectXML := True;
End;
{ ====================================================================== }
{   Phase 10 - CFBF / OLE2 Compound Document wrapper                     }
{                                                                        }
{   Best-effort .MPP/.MPT/.MPD/.PPM support : we write a valid CFBF      }
{   v3 (sector 512) container with a single stream "ProjectXML"          }
{   holding our XML Project 2003 payload, and on load we walk the        }
{   directory chain to find that stream and re-parse it.                 }
{                                                                        }
{   File layout (single FAT sector, single dir sector, no mini-FAT) :    }
{     Sector -1  : 512-byte header                                       }
{     Sector  0  : FAT (128 LongInt entries)                             }
{     Sector  1  : Directory (4 entries x 128 bytes)                     }
{     Sector  2+ : Stream "ProjectXML" content                           }
{ ====================================================================== }

Const
 CFBF_ENDOFCHAIN : LongInt = -2;        { $FFFFFFFE }
 CFBF_FREESECT   : LongInt = -1;        { $FFFFFFFF }
 CFBF_FATSECT    : LongInt = -3;        { $FFFFFFFD }
 CFBF_SEC_SIZE   = 512;
 CFBF_MAGIC      : Array[0..7] Of Byte = ($D0,$CF,$11,$E0,$A1,$B1,$1A,$E1);

Function MakeTempName(Const Tag: String): String;
Var S: String; N: LongInt;
Begin
 N := LongInt(Project.TaskCount) * 17 + LongInt(Project.AsgCount) * 31 +
      LongInt(PicCount) * 7 + LongInt(Project.ResCount);
 If N < 0 Then N := -N;
 S := '~' + Tag;
 While Length(S) < 6 Do S := S + '0';
 MakeTempName := S + IntToStr(N Mod 10000) + '.TMP';
End;

Procedure CfbfWriteLong(Var F: File; V: LongInt);
Var B: Array[0..3] Of Byte;
Begin
 B[0] := Byte(V And $FF);
 B[1] := Byte((V Shr 8) And $FF);
 B[2] := Byte((V Shr 16) And $FF);
 B[3] := Byte((V Shr 24) And $FF);
 BlockWrite(F, B, 4);
End;

Procedure CfbfWriteWord(Var F: File; V: Word);
Var B: Array[0..1] Of Byte;
Begin
 B[0] := Byte(V And $FF);
 B[1] := Byte((V Shr 8) And $FF);
 BlockWrite(F, B, 2);
End;

Procedure CfbfWriteUtf16(Var F: File; Const S: String; PadTo: Integer);
Var I, L, N: Integer; B: Array[0..127] Of Byte;
Begin
 FillChar(B, SizeOf(B), 0);
 L := Length(S);
 If L > 31 Then L := 31;
 For I := 1 To L Do Begin
  B[(I - 1) * 2] := Byte(S[I]);
  B[(I - 1) * 2 + 1] := 0;
 End;
 N := PadTo;
 If N > SizeOf(B) Then N := SizeOf(B);
 BlockWrite(F, B, N);
End;

Procedure CfbfWriteHeader(Var F: File; NumFAT: LongInt; FirstDir: LongInt);
Var Pad: Array[0..15] Of Byte; I: Integer;
Begin
 FillChar(Pad, SizeOf(Pad), 0);
 BlockWrite(F, CFBF_MAGIC, 8);
 BlockWrite(F, Pad, 16);              { CLSID }
 CfbfWriteWord(F, $003E);             { Minor version }
 CfbfWriteWord(F, $0003);             { Major version (v3) }
 CfbfWriteWord(F, $FFFE);             { Byte order LE }
 CfbfWriteWord(F, $0009);             { Sector shift = 512 }
 CfbfWriteWord(F, $0006);             { Mini sector shift = 64 }
 BlockWrite(F, Pad, 6);               { Reserved }
 CfbfWriteLong(F, 0);                 { Num dir sectors (0 for v3) }
 CfbfWriteLong(F, NumFAT);            { Num FAT sectors }
 CfbfWriteLong(F, FirstDir);          { First dir sector }
 CfbfWriteLong(F, 0);                 { Transaction signature }
 CfbfWriteLong(F, 4096);              { Mini stream cutoff }
 CfbfWriteLong(F, CFBF_ENDOFCHAIN);   { First mini FAT sector }
 CfbfWriteLong(F, 0);                 { Num mini FAT sectors }
 CfbfWriteLong(F, CFBF_ENDOFCHAIN);   { First DIFAT sector }
 CfbfWriteLong(F, 0);                 { Num DIFAT sectors }
 CfbfWriteLong(F, 0);                 { DIFAT[0] -> FAT at sector 0 }
 For I := 1 To 108 Do CfbfWriteLong(F, CFBF_FREESECT);
End;

Procedure CfbfWriteDirEntry(Var F: File; Const Name: String;
                            EntryType: Byte; LeftSib, RightSib, Child: LongInt;
                            StartSec: LongInt; SizeLow: LongInt);
Var NameLen: Word; Pad: Array[0..15] Of Byte;
Begin
 FillChar(Pad, SizeOf(Pad), 0);
 CfbfWriteUtf16(F, Name, 64);
 NameLen := (Length(Name) + 1) * 2;
 If Length(Name) = 0 Then NameLen := 0;
 CfbfWriteWord(F, NameLen);
 BlockWrite(F, EntryType, 1);
 BlockWrite(F, Pad[0], 1);            { Color = 0 (red) }
 CfbfWriteLong(F, LeftSib);
 CfbfWriteLong(F, RightSib);
 CfbfWriteLong(F, Child);
 BlockWrite(F, Pad, 16);              { CLSID }
 CfbfWriteLong(F, 0);                 { State bits }
 CfbfWriteLong(F, 0); CfbfWriteLong(F, 0);   { Creation time }
 CfbfWriteLong(F, 0); CfbfWriteLong(F, 0);   { Modified time }
 CfbfWriteLong(F, StartSec);
 CfbfWriteLong(F, SizeLow);
 CfbfWriteLong(F, 0);                 { Size high }
End;

Function SaveProjectMPP(Const FName: String): Boolean;
Var
 F, X: File;
 TempXml: String;
 XmlSize, NumStreamSec, SecIdx, BytesLeft, ToRead, I: LongInt;
 Buf: Array[0..CFBF_SEC_SIZE - 1] Of Byte;
 ZeroBuf: Array[0..CFBF_SEC_SIZE - 1] Of Byte;
 OK: Boolean;
Begin
 OK := False;
 TempXml := MakeTempName('PRX');
 If Not SaveProjectXML(TempXml) Then Begin
  SaveProjectMPP := False; Exit;
 End;
 {$I-}
 Assign(X, TempXml); Reset(X, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  SaveProjectMPP := False; Exit;
 End;
 XmlSize := FileSize(X);
 NumStreamSec := (XmlSize + CFBF_SEC_SIZE - 1) Div CFBF_SEC_SIZE;
 If NumStreamSec < 1 Then NumStreamSec := 1;

 {$I-}
 Assign(F, FName); Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  Close(X);
  Erase(X);
  SaveProjectMPP := False; Exit;
 End;

 FillChar(ZeroBuf, SizeOf(ZeroBuf), 0);

 { --- Header --- }
 CfbfWriteHeader(F, 1, 1);

 { --- FAT sector (sector 0) --- }
 CfbfWriteLong(F, CFBF_FATSECT);       { FAT[0] = sector 0 is itself FAT }
 CfbfWriteLong(F, CFBF_ENDOFCHAIN);    { FAT[1] = dir chain end }
 For I := 0 To NumStreamSec - 1 Do
  If I = NumStreamSec - 1 Then CfbfWriteLong(F, CFBF_ENDOFCHAIN)
  Else CfbfWriteLong(F, 2 + I + 1);
 For I := 2 + NumStreamSec To 127 Do CfbfWriteLong(F, CFBF_FREESECT);

 { --- Directory sector (sector 1) --- }
 { Entry 0 : Root Entry, child = 1 (ProjectXML) }
 CfbfWriteDirEntry(F, 'Root Entry', 5, CFBF_ENDOFCHAIN, CFBF_ENDOFCHAIN, 1,
                   CFBF_ENDOFCHAIN, 0);
 { Entry 1 : ProjectXML stream }
 CfbfWriteDirEntry(F, 'ProjectXML', 2, CFBF_ENDOFCHAIN, CFBF_ENDOFCHAIN,
                   CFBF_ENDOFCHAIN, 2, XmlSize);
 { Entries 2,3 : unused }
 CfbfWriteDirEntry(F, '', 0, CFBF_ENDOFCHAIN, CFBF_ENDOFCHAIN, CFBF_ENDOFCHAIN,
                   CFBF_ENDOFCHAIN, 0);
 CfbfWriteDirEntry(F, '', 0, CFBF_ENDOFCHAIN, CFBF_ENDOFCHAIN, CFBF_ENDOFCHAIN,
                   CFBF_ENDOFCHAIN, 0);

 { --- Stream content : copy XML, padded to sector boundary --- }
 BytesLeft := XmlSize;
 SecIdx := 0;
 While SecIdx < NumStreamSec Do Begin
  FillChar(Buf, SizeOf(Buf), 0);
  ToRead := BytesLeft;
  If ToRead > CFBF_SEC_SIZE Then ToRead := CFBF_SEC_SIZE;
  If ToRead > 0 Then Begin
   BlockRead(X, Buf, ToRead);
   Dec(BytesLeft, ToRead);
  End;
  BlockWrite(F, Buf, CFBF_SEC_SIZE);
  Inc(SecIdx);
 End;

 Close(X);
 Erase(X);
 Close(F);
 OK := True;
 SaveProjectMPP := OK;
End;

Procedure CfbfReadLong(Var F: File; Var V: LongInt);
Var B: Array[0..3] Of Byte;
Begin
 BlockRead(F, B, 4);
 V := LongInt(B[0]) Or (LongInt(B[1]) Shl 8) Or
      (LongInt(B[2]) Shl 16) Or (LongInt(B[3]) Shl 24);
End;

Procedure CfbfReadWord(Var F: File; Var V: Word);
Var B: Array[0..1] Of Byte;
Begin
 BlockRead(F, B, 2);
 V := Word(B[0]) Or (Word(B[1]) Shl 8);
End;

Procedure CfbfSeekSector(Var F: File; Sec: LongInt);
Begin
 Seek(F, LongInt(CFBF_SEC_SIZE) + Sec * LongInt(CFBF_SEC_SIZE));
End;

Function CfbfReadDirName(Const Buf: Array Of Byte; Ofs: Integer): String;
Var I: Integer; S: String; B: Byte;
Begin
 S := '';
 For I := 0 To 31 Do Begin
  B := Buf[Ofs + I * 2];
  If B = 0 Then Break;
  S := S + Chr(B);
 End;
 CfbfReadDirName := S;
End;

Function LoadProjectMPP(Const FName: String): Boolean;
Var
 F, X: File;
 Hdr: Array[0..7] Of Byte;
 I, NumFat, FirstDir: LongInt;
 DirSec: LongInt;
 DirBuf: Array[0..CFBF_SEC_SIZE - 1] Of Byte;
 FatBuf: Array[0..127] Of LongInt;
 FatSec0: LongInt;
 StreamStart, StreamSize, SecCur: LongInt;
 EntryOfs, EntryIdx: Integer;
 EntryType: Byte;
 EntryStart, EntrySize: LongInt;
 Name: String;
 Found: Boolean;
 TempXml: String;
 BytesLeft, ToWrite: LongInt;
 Buf: Array[0..CFBF_SEC_SIZE - 1] Of Byte;
 Safety: Integer;
Begin
 LoadProjectMPP := False;
 {$I-}
 Assign(F, FName); Reset(F, 1);
 {$I+}
 If IOResult <> 0 Then Exit;

 { --- Read magic --- }
 BlockRead(F, Hdr, 8);
 For I := 0 To 7 Do
  If Hdr[I] <> CFBF_MAGIC[I] Then Begin
   Close(F);
   StatusMsg := 'Fichier non CFBF : signature invalide';
   NeedStatRedraw := True;
   Exit;
  End;

 { --- Skip to NumFAT/FirstDir fields at offsets 44, 48 --- }
 Seek(F, 44);
 CfbfReadLong(F, NumFat);
 CfbfReadLong(F, FirstDir);
 { Skip transaction, cutoff }
 Seek(F, 76);
 CfbfReadLong(F, FatSec0);             { DIFAT[0] = first FAT sector }
 If (FatSec0 < 0) Or (NumFat < 1) Then Begin
  Close(F);
  StatusMsg := 'CFBF : FAT introuvable'; NeedStatRedraw := True; Exit;
 End;

 { --- Read FAT sector --- }
 CfbfSeekSector(F, FatSec0);
 For I := 0 To 127 Do CfbfReadLong(F, FatBuf[I]);

 { --- Walk directory chain looking for "ProjectXML" --- }
 Found := False;
 EntryStart := 0; EntrySize := 0;
 DirSec := FirstDir;
 Safety := 0;
 While (DirSec >= 0) And (Not Found) And (Safety < 1024) Do Begin
  Inc(Safety);
  CfbfSeekSector(F, DirSec);
  BlockRead(F, DirBuf, CFBF_SEC_SIZE);
  For EntryIdx := 0 To 3 Do Begin
   EntryOfs := EntryIdx * 128;
   EntryType := DirBuf[EntryOfs + 66];
   If (EntryType = 2) Then Begin
    Name := CfbfReadDirName(DirBuf, EntryOfs);
    If (Name = 'ProjectXML') Or (Name = 'PROJECTXML') Then Begin
     EntryStart := LongInt(DirBuf[EntryOfs + 116]) Or
                   (LongInt(DirBuf[EntryOfs + 117]) Shl 8) Or
                   (LongInt(DirBuf[EntryOfs + 118]) Shl 16) Or
                   (LongInt(DirBuf[EntryOfs + 119]) Shl 24);
     EntrySize := LongInt(DirBuf[EntryOfs + 120]) Or
                  (LongInt(DirBuf[EntryOfs + 121]) Shl 8) Or
                  (LongInt(DirBuf[EntryOfs + 122]) Shl 16) Or
                  (LongInt(DirBuf[EntryOfs + 123]) Shl 24);
     Found := True;
     Break;
    End;
   End;
  End;
  If Not Found Then Begin
   If (DirSec >= 0) And (DirSec < 128) Then DirSec := FatBuf[DirSec]
   Else DirSec := CFBF_ENDOFCHAIN;
   If DirSec = CFBF_ENDOFCHAIN Then Break;
  End;
 End;

 If Not Found Then Begin
  Close(F);
  StatusMsg := 'Stream ProjectXML absent (.MPP natif non supporte)';
  NeedStatRedraw := True;
  Exit;
 End;

 { --- Extract stream to temp file --- }
 TempXml := MakeTempName('PRR');
 {$I-}
 Assign(X, TempXml); Rewrite(X, 1);
 {$I+}
 If IOResult <> 0 Then Begin Close(F); Exit; End;

 BytesLeft := EntrySize;
 SecCur := EntryStart;
 Safety := 0;
 NumFat := NumFat;   { silence warning }
 While (SecCur >= 0) And (BytesLeft > 0) And (Safety < 65536) Do Begin
  Inc(Safety);
  CfbfSeekSector(F, SecCur);
  BlockRead(F, Buf, CFBF_SEC_SIZE);
  ToWrite := BytesLeft;
  If ToWrite > CFBF_SEC_SIZE Then ToWrite := CFBF_SEC_SIZE;
  BlockWrite(X, Buf, ToWrite);
  Dec(BytesLeft, ToWrite);
  If (SecCur >= 0) And (SecCur < 128) Then SecCur := FatBuf[SecCur]
  Else SecCur := CFBF_ENDOFCHAIN;
  If SecCur = CFBF_ENDOFCHAIN Then Break;
 End;

 Close(X);
 Close(F);

 If LoadProjectXML(TempXml) Then Begin
  Erase(X);
  Project.FileName := FName;
  Project.Dirty := False;
  LoadProjectMPP := True;
 End
 Else Begin
  Assign(X, TempXml);
  {$I-} Erase(X); {$I+} If IOResult <> 0 Then ;
  LoadProjectMPP := False;
 End;
End;

Function GetFileExt(Const F: String): String;
Var I: Integer; R: String;
Begin
 I := Length(F);
 While (I > 0) And (F[I] <> '.') And (F[I] <> '\') And (F[I] <> '/') Do
  Dec(I);
 If (I = 0) Or (F[I] <> '.') Then GetFileExt := ''
 Else Begin
  R := Copy(F, I, Length(F) - I + 1);
  For I := 1 To Length(R) Do R[I] := UpCase(R[I]);
  GetFileExt := R;
 End;
End;

Function SaveProjectByExt(Const FName: String): Boolean;
Var Ext: String;
Begin
 Ext := GetFileExt(FName);
 If      Ext = '.CSV' Then SaveProjectByExt := SaveProjectCSV(FName)
 Else If Ext = '.MPX' Then SaveProjectByExt := SaveProjectMPX(FName)
 Else If Ext = '.XML' Then SaveProjectByExt := SaveProjectXML(FName)
 Else If (Ext = '.MPP') Or (Ext = '.MPT') Or (Ext = '.MPD')
                          Or (Ext = '.PPM') Then
  SaveProjectByExt := SaveProjectMPP(FName)
 Else SaveProjectByExt := False;
End;

Function LoadProjectByExt(Const FName: String): Boolean;
Var Ext: String;
Begin
 Ext := GetFileExt(FName);
 If      Ext = '.CSV' Then LoadProjectByExt := LoadProjectCSV(FName)
 Else If Ext = '.MPX' Then LoadProjectByExt := LoadProjectMPX(FName)
 Else If Ext = '.XML' Then LoadProjectByExt := LoadProjectXML(FName)
 Else If (Ext = '.MPP') Or (Ext = '.MPT') Or (Ext = '.MPD')
                          Or (Ext = '.PPM') Then
  LoadProjectByExt := LoadProjectMPP(FName)
 Else LoadProjectByExt := False;
End;

Procedure ActionOpen;
Var FName: String; Filt: Integer;
Begin
 FName := ''; Filt := 1;
 If Not DoFileDialog(False, FName, Filt) Then Exit;
 If Not LoadProjectByExt(FName) Then Begin
  MessageBox('Ouvrir',
   'Format non encore supporte ou fichier illisible :' + #13 + FName);
  Exit;
 End;
 StatusMsg := 'Charge : ' + FName;
 NeedStatRedraw := True;
 NeedFullRedraw := True;
End;

Procedure ActionSaveAs;
Var FName: String; Filt: Integer;
Begin
 FName := Project.FileName;
 Filt := 6; { CSV par defaut puisque seul format Phase 7 }
 If Not DoFileDialog(True, FName, Filt) Then Exit;
 If Not SaveProjectByExt(FName) Then Begin
  MessageBox('Enregistrer',
   'Format non encore supporte (CSV operationnel pour l''instant) :' + #13
    + FName);
  Exit;
 End;
 Project.FileName := Copy(FName, 1, 80);
 Project.Dirty := False;
 StatusMsg := 'Enregistre : ' + FName;
 NeedStatRedraw := True;
End;

Procedure ActionSave;
Begin
 If Project.FileName = '' Then ActionSaveAs
 Else If Not SaveProjectByExt(Project.FileName) Then ActionSaveAs
 Else Begin
  Project.Dirty := False;
  StatusMsg := 'Enregistre';
  NeedStatRedraw := True;
 End;
End;

{ ====================================================================== }
{                       ACTIONS                                          }
{ ====================================================================== }

Procedure DoAction(A: Integer); Forward;

Procedure ActionNew;
Begin
 InitProject;
 CPMRecompute;
 CurTaskIdx := 1;
 GridScrollY := 0;
 GanttOriginDt := Project.StartDate - 3;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{   Phase 11 - Rapports + Impression + Polissage                         }
{ ====================================================================== }

Const
 RPT_BUFLINES = 800;
 RPT_LINEMAX  = 100;

Var
 RptLines     : Array[1..RPT_BUFLINES] Of String[RPT_LINEMAX];
 RptLineCount : Integer;
 RptTitle     : String;
 RptScroll    : Integer;

Procedure RptClear;
Begin
 RptLineCount := 0;
 RptScroll    := 0;
 RptTitle     := '';
End;

Procedure RptAdd(Const S: String);
Begin
 If RptLineCount >= RPT_BUFLINES Then Exit;
 Inc(RptLineCount);
 If Length(S) > RPT_LINEMAX Then RptLines[RptLineCount] := Copy(S, 1, RPT_LINEMAX)
 Else RptLines[RptLineCount] := S;
End;

Procedure RptSep(C: Char; Len: Integer);
Var S: String; I: Integer;
Begin
 If Len > RPT_LINEMAX Then Len := RPT_LINEMAX;
 S := '';
 For I := 1 To Len Do S := S + C;
 RptAdd(S);
End;

Function PadRight(Const S: String; W: Integer): String;
Var R: String; I: Integer;
Begin
 R := S;
 If Length(R) > W Then R := Copy(R, 1, W);
 For I := Length(R) + 1 To W Do R := R + ' ';
 PadRight := R;
End;

Function PadLeft(Const S: String; W: Integer): String;
Var R: String; I: Integer;
Begin
 R := S;
 If Length(R) > W Then R := Copy(R, 1, W);
 For I := Length(R) + 1 To W Do R := ' ' + R;
 PadLeft := R;
End;

Function MoneyStr(V: LongInt): String;
Begin
 MoneyStr := IntToStr(V) + ' $';
End;

Function DurStr(Tenths: LongInt): String;
Var W, F: LongInt; S: String;
Begin
 W := Tenths Div 10;
 F := Tenths Mod 10;
 If F < 0 Then F := -F;
 S := IntToStr(W);
 If F <> 0 Then S := S + ',' + IntToStr(F);
 DurStr := S + 'j';
End;

Procedure GenReportHeader(Const Title: String);
Begin
 RptClear;
 RptTitle := Title;
 RptAdd('================================================================');
 RptAdd('  ' + Project.Title + ' - ' + Title);
 RptAdd('  Manager : ' + Project.Manager +
        '   Imprime : ' + ShortDateStr(Project.CurrentDt));
 RptAdd('================================================================');
 RptAdd('');
End;

Procedure GenReportSummary;
Var TotCost, ActCost, BasCost, TotWork, ActWork: LongInt;
    I, Crit, Done, MS, Sum: Integer;
    T: PTask;
Begin
 GenReportHeader('SYNTHESE DU PROJET');
 RptAdd('  Projet    : ' + Project.Title);
 RptAdd('  Manager   : ' + Project.Manager);
 RptAdd('  Societe   : ' + Project.Company);
 RptAdd('  Sujet     : ' + Project.Subject);
 RptAdd('  Debut     : ' + ShortDateStr(Project.StartDate));
 RptAdd('  Fin       : ' + ShortDateStr(Project.FinishDate));
 RptAdd('  Statut    : ' + ShortDateStr(Project.StatusDate));
 RptAdd('  Heures/jr : ' + IntToStr(Project.HoursPerDay));
 RptAdd('  H/semaine : ' + IntToStr(Project.HoursPerWeek));
 RptAdd('  Commentaires : ' + Project.Comments);
 RptSep('-', 64);
 TotCost := 0; ActCost := 0; BasCost := 0;
 TotWork := 0; ActWork := 0;
 Crit := 0; Done := 0; MS := 0; Sum := 0;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  TotCost := TotCost + T^.Cost;
  ActCost := ActCost + T^.ActualCost;
  BasCost := BasCost + T^.BaselineCost;
  TotWork := TotWork + T^.Work;
  ActWork := ActWork + T^.ActualWork;
  If T^.Critical Then Inc(Crit);
  If T^.PercentDone >= 100 Then Inc(Done);
  If T^.IsMilestone Then Inc(MS);
  If T^.IsSummary Then Inc(Sum);
 End;
 RptAdd('  TACHES');
 RptAdd('   Total           : ' + IntToStr(Project.TaskCount));
 RptAdd('   Recapitulatives : ' + IntToStr(Sum));
 RptAdd('   Jalons          : ' + IntToStr(MS));
 RptAdd('   Critiques       : ' + IntToStr(Crit));
 RptAdd('   Terminees       : ' + IntToStr(Done));
 RptAdd('  RESSOURCES');
 RptAdd('   Total           : ' + IntToStr(Project.ResCount));
 RptAdd('   Affectations    : ' + IntToStr(Project.AsgCount));
 RptAdd('  COUTS');
 RptAdd('   Reference       : ' + MoneyStr(BasCost));
 RptAdd('   Reel            : ' + MoneyStr(ActCost));
 RptAdd('   Prevu           : ' + MoneyStr(TotCost));
 RptAdd('   Ecart           : ' + MoneyStr(TotCost - BasCost));
 RptAdd('  TRAVAIL (heures)');
 RptAdd('   Reel            : ' + IntToStr(ActWork));
 RptAdd('   Prevu           : ' + IntToStr(TotWork));
End;

Procedure GenReportTasks;
Var I: Integer; T: PTask; Ind: String; J: Integer; Line: String;
Begin
 GenReportHeader('LISTE DES TACHES');
 RptAdd(' Id  ' + PadRight('Nom', 36) + PadRight('Debut', 11) +
        PadRight('Fin', 11) + PadLeft('Duree', 8) + PadLeft('%', 5));
 RptSep('-', 75);
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  Ind := '';
  For J := 1 To T^.OutlineLv Do Ind := Ind + '  ';
  Line := PadLeft(IntToStr(T^.Id), 3) + ' ' +
          PadRight(Ind + T^.Name, 36) +
          PadRight(ShortDateStr(T^.Start), 11) +
          PadRight(ShortDateStr(T^.Finish), 11) +
          PadLeft(DurStr(T^.Duration), 8) +
          PadLeft(IntToStr(T^.PercentDone) + '%', 5);
  RptAdd(Line);
 End;
End;

Procedure GenReportCritical;
Var I, K: Integer; T: PTask;
Begin
 GenReportHeader('TACHES CRITIQUES');
 RptAdd(' Id  ' + PadRight('Nom', 32) + PadRight('Debut', 11) +
        PadRight('Fin', 11) + PadLeft('Slack', 8));
 RptSep('-', 70);
 K := 0;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If Not T^.Critical Then Continue;
  Inc(K);
  RptAdd(PadLeft(IntToStr(T^.Id), 3) + ' ' +
         PadRight(T^.Name, 32) +
         PadRight(ShortDateStr(T^.EarlyStart), 11) +
         PadRight(ShortDateStr(T^.EarlyFinish), 11) +
         PadLeft(DurStr(T^.TotalSlack), 8));
 End;
 RptSep('-', 70);
 RptAdd(' Total taches critiques : ' + IntToStr(K));
End;

Procedure GenReportMilestones;
Var I, K: Integer; T: PTask;
Begin
 GenReportHeader('JALONS DU PROJET');
 RptAdd(' Id  ' + PadRight('Nom', 40) + PadRight('Date', 12) +
        PadLeft('%', 5));
 RptSep('-', 65);
 K := 0;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  If Not T^.IsMilestone Then Continue;
  Inc(K);
  RptAdd(PadLeft(IntToStr(T^.Id), 3) + ' ' +
         PadRight(T^.Name, 40) +
         PadRight(ShortDateStr(T^.Start), 12) +
         PadLeft(IntToStr(T^.PercentDone) + '%', 5));
 End;
 RptSep('-', 65);
 RptAdd(' Total jalons : ' + IntToStr(K));
End;

Procedure GenReportResources;
Var I, J: Integer; R: PResource; A: PAssignment;
    TotWork: LongInt;
Begin
 GenReportHeader('LISTE DES RESSOURCES');
 RptAdd(' Id  ' + PadRight('Nom', 24) + PadRight('Init', 6) +
        PadRight('Type', 8) + PadLeft('Max%', 6) +
        PadLeft('TauxStd', 10) + PadLeft('Travail', 9));
 RptSep('-', 75);
 For I := 1 To Project.ResCount Do Begin
  R := Project.Resources[I];
  If R = Nil Then Continue;
  TotWork := 0;
  For J := 1 To Project.AsgCount Do Begin
   A := Project.Assignments[J];
   If (A <> Nil) And (A^.ResId = R^.Id) Then TotWork := TotWork + A^.Work;
  End;
  RptAdd(PadLeft(IntToStr(R^.Id), 3) + ' ' +
         PadRight(R^.Name, 24) +
         PadRight(R^.Initials, 6) +
         PadRight(IntToStr(R^.ResType), 8) +
         PadLeft(IntToStr(R^.MaxUnits Div 100) + '%', 6) +
         PadLeft(MoneyStr(R^.StdRate), 10) +
         PadLeft(IntToStr(TotWork) + 'h', 9));
 End;
End;

Procedure GenReportCosts;
Var I: Integer; T: PTask;
    Tot, ActT, BasT, RemT: LongInt;
Begin
 GenReportHeader('RAPPORT DES COUTS');
 RptAdd(' Id  ' + PadRight('Nom', 30) + PadLeft('Reference', 12) +
        PadLeft('Prevu', 12) + PadLeft('Reel', 12) + PadLeft('Ecart', 12));
 RptSep('-', 90);
 Tot := 0; ActT := 0; BasT := 0; RemT := 0;
 For I := 1 To Project.TaskCount Do Begin
  T := Project.Tasks[I];
  If T = Nil Then Continue;
  Tot := Tot + T^.Cost;
  ActT := ActT + T^.ActualCost;
  BasT := BasT + T^.BaselineCost;
  RemT := RemT + (T^.Cost - T^.ActualCost);
  RptAdd(PadLeft(IntToStr(T^.Id), 3) + ' ' +
         PadRight(T^.Name, 30) +
         PadLeft(MoneyStr(T^.BaselineCost), 12) +
         PadLeft(MoneyStr(T^.Cost), 12) +
         PadLeft(MoneyStr(T^.ActualCost), 12) +
         PadLeft(MoneyStr(T^.Cost - T^.BaselineCost), 12));
 End;
 RptSep('-', 90);
 RptAdd(PadRight('  TOTAL', 34) +
        PadLeft(MoneyStr(BasT), 12) +
        PadLeft(MoneyStr(Tot), 12) +
        PadLeft(MoneyStr(ActT), 12) +
        PadLeft(MoneyStr(Tot - BasT), 12));
 RptAdd('');
 RptAdd('  Cout restant prevu : ' + MoneyStr(RemT));
End;

Function RptSaveToFile(Const FName: String): Boolean;
Var F: Text; I: Integer;
Begin
 RptSaveToFile := False;
 {$I-} Assign(F, FName); Rewrite(F); {$I+}
 If IOResult <> 0 Then Exit;
 For I := 1 To RptLineCount Do WriteLn(F, RptLines[I]);
 Close(F);
 RptSaveToFile := True;
End;

Function RptPrintToLPT: Boolean;
Var F: Text; I: Integer;
Begin
 RptPrintToLPT := False;
 {$I-} Assign(F, 'PRN'); Rewrite(F); {$I+}
 If IOResult <> 0 Then Begin
  {$I-} Assign(F, 'LPT1'); Rewrite(F); {$I+}
  If IOResult <> 0 Then Begin
   { Fallback : ecrit dans un fichier RAPPORT.PRN dans le repertoire courant }
   {$I-} Assign(F, 'RAPPORT.PRN'); Rewrite(F); {$I+}
   If IOResult <> 0 Then Exit;
  End;
 End;
 For I := 1 To RptLineCount Do WriteLn(F, RptLines[I]);
 Write(F, #12);              { Form-feed final }
 Close(F);
 RptPrintToLPT := True;
End;

Procedure DrawReportPreview;
Var X1, Y1, X2, Y2, I, Yy, Vis: Integer;
    BtnPrnX1, BtnPrnX2, BtnExpX1, BtnExpX2, BtnClX1, BtnClX2, BtnY1, BtnY2: Integer;
Begin
 HideMouse;
 X1 := 20; Y1 := 30; X2 := 619; Y2 := 449;
 FillBox(X1 + 4, Y2 + 1, X2 + 4, Y2 + 3, CLR_BLACK);
 FillBox(X2 + 1, Y1 + 4, X2 + 3, Y2 + 3, CLR_BLACK);
 DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 6, Y1 + 4, 'Rapport : ' + RptTitle);

 { Body }
 FillBox(X1 + 8, Y1 + 22, X2 - 8, Y2 - 40, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(X1 + 8, Y1 + 22, X2 - 8, Y2 - 40);
 Vis := (Y2 - 40 - (Y1 + 24)) Div 12;
 SetColor(CLR_BLACK);
 For I := 0 To Vis - 1 Do Begin
  If RptScroll + I + 1 > RptLineCount Then Break;
  Yy := Y1 + 26 + I * 12;
  OutTextXY(X1 + 12, Yy, RptLines[RptScroll + I + 1]);
 End;
 { Scrollbar mark }
 FillBox(X2 - 14, Y1 + 22, X2 - 8, Y2 - 40, CLR_LGRAY);
 If RptLineCount > Vis Then Begin
  Yy := Y1 + 24 + (RptScroll * (Y2 - 42 - (Y1 + 24))) Div RptLineCount;
  FillBox(X2 - 13, Yy, X2 - 9, Yy + 8, CLR_DGRAY);
 End;

 { Buttons }
 BtnY1 := Y2 - 32; BtnY2 := Y2 - 10;
 BtnPrnX1 := X1 + 16; BtnPrnX2 := BtnPrnX1 + 90;
 BtnExpX1 := BtnPrnX2 + 12; BtnExpX2 := BtnExpX1 + 90;
 BtnClX1 := X2 - 90 - 16; BtnClX2 := X2 - 16;
 DlgBtn(BtnPrnX1, BtnY1, BtnPrnX2, BtnY2, 'Imprimer', False, False);
 DlgBtn(BtnExpX1, BtnY1, BtnExpX2, BtnY2, 'Exporter', False, False);
 DlgBtn(BtnClX1, BtnY1, BtnClX2, BtnY2, 'Fermer',   False, True);

 ShowMouse;
End;

Procedure DoReportPreview;
Var X1, Y1, X2, Y2: Integer; K, K2: Char;
    BtnPrnX1, BtnPrnX2, BtnExpX1, BtnExpX2, BtnClX1, BtnClX2: Integer;
    BtnY1, BtnY2: Integer;
    Vis: Integer;
    FName: String; Filt: Integer;
Begin
 X1 := 20; Y1 := 30; X2 := 619; Y2 := 449;
 BtnY1 := Y2 - 32; BtnY2 := Y2 - 10;
 BtnPrnX1 := X1 + 16; BtnPrnX2 := BtnPrnX1 + 90;
 BtnExpX1 := BtnPrnX2 + 12; BtnExpX2 := BtnExpX1 + 90;
 BtnClX1 := X2 - 90 - 16; BtnClX2 := X2 - 16;
 Vis := (Y2 - 40 - (Y1 + 24)) Div 12;
 RptScroll := 0;
 Repeat
  DrawReportPreview;
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #27 Then Begin NeedFullRedraw := True; Exit; End;
   If K = #13 Then Begin NeedFullRedraw := True; Exit; End;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #72: If RptScroll > 0 Then Dec(RptScroll);
     #80: If RptScroll < RptLineCount - Vis Then Inc(RptScroll);
     #73: Begin
           RptScroll := RptScroll - Vis;
           If RptScroll < 0 Then RptScroll := 0;
          End;
     #81: Begin
           RptScroll := RptScroll + Vis;
           If RptScroll > RptLineCount - Vis Then RptScroll := RptLineCount - Vis;
           If RptScroll < 0 Then RptScroll := 0;
          End;
     #71: RptScroll := 0;
     #79: Begin
           RptScroll := RptLineCount - Vis;
           If RptScroll < 0 Then RptScroll := 0;
          End;
    End;
   End;
  End;
  If LeftPressed Then Begin
   If InRect(Mouse.X, Mouse.Y, BtnClX1, BtnY1, BtnClX2, BtnY2) Then Begin
    NeedFullRedraw := True; Exit;
   End;
   If InRect(Mouse.X, Mouse.Y, BtnPrnX1, BtnY1, BtnPrnX2, BtnY2) Then Begin
    If RptPrintToLPT Then
     MessageBox('Imprimer', 'Rapport envoye a l''imprimante.')
    Else
     MessageBox('Imprimer', 'Echec d''impression (imprimante absente).');
   End;
   If InRect(Mouse.X, Mouse.Y, BtnExpX1, BtnY1, BtnExpX2, BtnY2) Then Begin
    FName := 'RAPPORT.TXT'; Filt := 7;
    If DoFileDialog(True, FName, Filt) Then Begin
     If RptSaveToFile(FName) Then
      MessageBox('Exporter', 'Rapport enregistre :' + #13 + FName)
     Else
      MessageBox('Exporter', 'Erreur lors de l''ecriture du fichier.');
    End;
   End;
  End;
 Until False;
End;

Procedure DoReportsDialog;
Var X1, Y1, X2, Y2: Integer; K, K2: Char;
    Sel: Integer;
    Items: Array[1..6] Of String[30];
    ItemAct: Array[1..6] Of Integer;
    I, Iy: Integer;
    Done: Boolean;
    BtnOkX1, BtnOkX2, BtnCnX1, BtnCnX2, BtnY1, BtnY2: Integer;
    Act: Integer;
Begin
 Items[1] := 'Synthese du projet';      ItemAct[1] := ACT_RPT_SUM;
 Items[2] := 'Liste des taches';        ItemAct[2] := ACT_RPT_TASKS;
 Items[3] := 'Taches critiques';        ItemAct[3] := ACT_RPT_CRIT;
 Items[4] := 'Jalons du projet';        ItemAct[4] := ACT_RPT_MS;
 Items[5] := 'Liste des ressources';    ItemAct[5] := ACT_RPT_RES;
 Items[6] := 'Rapport des couts';       ItemAct[6] := ACT_RPT_COST;
 Sel := 1;
 X1 := 180; Y1 := 130; X2 := 460; Y2 := 350;
 BtnY1 := Y2 - 32; BtnY2 := Y2 - 10;
 BtnOkX1 := X1 + 30;  BtnOkX2 := BtnOkX1 + 90;
 BtnCnX1 := X2 - 120; BtnCnX2 := X2 - 30;
 Done := False;
 Act := 0;
 While Not Done Do Begin
  HideMouse;
  FillBox(X1 + 4, Y2 + 1, X2 + 4, Y2 + 3, CLR_BLACK);
  FillBox(X2 + 1, Y1 + 4, X2 + 3, Y2 + 3, CLR_BLACK);
  DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
  FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
  SetColor(CLR_DLG_TITLE_FG);
  OutTextXY(X1 + 6, Y1 + 4, 'Rapports');
  SetColor(CLR_BLACK);
  OutTextXY(X1 + 16, Y1 + 24, 'Selectionnez un rapport :');
  For I := 1 To 6 Do Begin
   Iy := Y1 + 44 + (I - 1) * 18;
   If I = Sel Then Begin
    FillBox(X1 + 16, Iy - 2, X2 - 16, Iy + 14, CLR_LBLUE);
    SetColor(CLR_WHITE);
   End
   Else Begin
    FillBox(X1 + 16, Iy - 2, X2 - 16, Iy + 14, CLR_DLG_BG);
    SetColor(CLR_BLACK);
   End;
   OutTextXY(X1 + 24, Iy, Items[I]);
  End;
  DlgBtn(BtnOkX1, BtnY1, BtnOkX2, BtnY2, 'Afficher', False, True);
  DlgBtn(BtnCnX1, BtnY1, BtnCnX2, BtnY2, 'Annuler',  False, False);
  ShowMouse;

  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #27 Then Begin NeedFullRedraw := True; Exit; End;
   If K = #13 Then Begin Act := ItemAct[Sel]; Done := True; End;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     #72: If Sel > 1 Then Dec(Sel);
     #80: If Sel < 6 Then Inc(Sel);
    End;
   End;
  End;
  If LeftPressed Then Begin
   For I := 1 To 6 Do Begin
    Iy := Y1 + 44 + (I - 1) * 18;
    If InRect(Mouse.X, Mouse.Y, X1 + 16, Iy - 2, X2 - 16, Iy + 14) Then Begin
     Sel := I;
     If DoubleClicked Then Begin Act := ItemAct[Sel]; Done := True; End;
    End;
   End;
   If InRect(Mouse.X, Mouse.Y, BtnOkX1, BtnY1, BtnOkX2, BtnY2) Then Begin
    Act := ItemAct[Sel]; Done := True;
   End;
   If InRect(Mouse.X, Mouse.Y, BtnCnX1, BtnY1, BtnCnX2, BtnY2) Then Begin
    NeedFullRedraw := True; Exit;
   End;
  End;
 End;

 Case Act Of
  ACT_RPT_SUM:   GenReportSummary;
  ACT_RPT_TASKS: GenReportTasks;
  ACT_RPT_CRIT:  GenReportCritical;
  ACT_RPT_RES:   GenReportResources;
  ACT_RPT_COST:  GenReportCosts;
  ACT_RPT_MS:    GenReportMilestones;
 End;
 DoReportPreview;
 NeedFullRedraw := True;
End;

Procedure ActionReports;
Begin
 DoReportsDialog;
End;

Procedure ActionPrintEx;   { Imprime la vue Gantt courante comme rapport }
Begin
 GenReportTasks;
 DoReportPreview;
 NeedFullRedraw := True;
End;

Procedure ActionAbout;
Var X1, Y1, X2, Y2: Integer; K: Char;
Begin
 X1 := 120; Y1 := 110; X2 := 520; Y2 := 370;
 HideMouse;
 FillBox(X1 + 4, Y2 + 1, X2 + 4, Y2 + 3, CLR_BLACK);
 FillBox(X2 + 1, Y1 + 4, X2 + 3, Y2 + 3, CLR_BLACK);
 DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 6, Y1 + 4, 'A propos de Office-0 Project');
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 16, Y1 + 30, 'Clone de Microsoft Project');
 OutTextXY(X1 + 16, Y1 + 46, 'Office-0 v1.00 - 2026');
 OutTextXY(X1 + 16, Y1 + 62, '(c) Sylvain Maltais - www.gladir.com');
 OutTextXY(X1 + 16, Y1 + 84, 'Fonctionnalites :');
 OutTextXY(X1 + 32, Y1 + 100, '- Vues Gantt, Reseau (PERT), Ressources, Utilisation, Calendrier');
 OutTextXY(X1 + 32, Y1 + 114, '- Algorithme du chemin critique (CPM) avec slacks');
 OutTextXY(X1 + 32, Y1 + 128, '- Lignes de reference + suivi (% acheve, cout reel)');
 OutTextXY(X1 + 32, Y1 + 142, '- Nivellement des ressources');
 OutTextXY(X1 + 32, Y1 + 156, '- Formats : MPX, XML Project 2003, CSV, MPP/MPT/MPD/PPM (CFBF)');
 OutTextXY(X1 + 32, Y1 + 170, '- Insertion images BMP, PCX, GIF');
 OutTextXY(X1 + 32, Y1 + 184, '- Rapports et impression');
 OutTextXY(X1 + 16, Y1 + 206, 'Raccourcis : F1 Aide  Ctrl+S Sauver  Ctrl+O Ouvrir  Ctrl+P Imprimer');
 DrawRaised(X1 + 170, Y2 - 32, X1 + 230, Y2 - 12, CLR_LGRAY,
            CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 195, Y2 - 26, 'OK');
 ShowMouse;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If (K = #13) Or (K = #27) Or (K = ' ') Then Begin
    NeedFullRedraw := True; Exit;
   End;
   If K = #0 Then ReadKey;
  End;
  If LeftPressed Then
   If InRect(Mouse.X, Mouse.Y, X1 + 170, Y2 - 32, X1 + 230, Y2 - 12) Then Begin
    NeedFullRedraw := True; Exit;
   End;
 Until False;
End;

Procedure ActionInsTask;
Var I: Integer; T: PTask;
Begin
 If Project.TaskCount >= MAX_TASKS Then Exit;
 If CurTaskIdx < 1 Then CurTaskIdx := 0;
 For I := Project.TaskCount DownTo CurTaskIdx + 1 Do Begin
  Project.Tasks[I + 1] := Project.Tasks[I];
  If Project.Tasks[I + 1] <> Nil Then Project.Tasks[I + 1]^.Id := I + 1;
 End;
 T := NewTask;
 Inc(Project.TaskCount);
 T^.Id := CurTaskIdx + 1;
 T^.Name := 'Nouvelle tache';
 T^.Duration := 10;
 T^.Start := Project.StartDate;
 T^.Finish := T^.Start;
 Project.Tasks[CurTaskIdx + 1] := T;
 Inc(CurTaskIdx);
 Project.Dirty := True;
 CPMRecompute;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
End;

Procedure ActionDeleteTask;
Var I: Integer;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 If Project.Tasks[CurTaskIdx] <> Nil Then
  FreeMem(Project.Tasks[CurTaskIdx], SizeOf(TTask));
 For I := CurTaskIdx To Project.TaskCount - 1 Do Begin
  Project.Tasks[I] := Project.Tasks[I + 1];
  If Project.Tasks[I] <> Nil Then Project.Tasks[I]^.Id := I;
 End;
 Project.Tasks[Project.TaskCount] := Nil;
 Dec(Project.TaskCount);
 If CurTaskIdx > Project.TaskCount Then CurTaskIdx := Project.TaskCount;
 Project.Dirty := True;
 CPMRecompute;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
End;

Procedure ActionIndent;
Var T: PTask;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 If T^.OutlineLv < 9 Then Inc(T^.OutlineLv);
 CPMRecompute;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
 Project.Dirty := True;
End;

Procedure ActionOutdent;
Var T: PTask;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 If T^.OutlineLv > 1 Then Dec(T^.OutlineLv);
 CPMRecompute;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
 Project.Dirty := True;
End;

Procedure ActionLink;
Begin
 If (CurTaskIdx < 2) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 SetPredecessor(CurTaskIdx, CurTaskIdx - 1, LT_FS, 0);
 Project.Dirty := True;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
End;

Procedure ActionUnlink;
Var T: PTask;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 T^.PredCount := 0;
 Project.Dirty := True;
 NeedGridRedraw := True;
 NeedGanttRedraw := True;
End;

Procedure ActionZoomIn;
Begin
 If DayPx < 32 Then Inc(DayPx, 2);
 NeedGanttRedraw := True;
End;

Procedure ActionZoomOut;
Begin
 If DayPx > 2 Then Dec(DayPx, 2);
 NeedGanttRedraw := True;
End;

Procedure ActionZoomFit;
Var Span: LongInt;
Begin
 Span := Project.FinishDate - Project.StartDate + 5;
 If Span < 1 Then Span := 1;
 DayPx := (GanttX2 - GanttX1 - 4) Div Integer(Span);
 If DayPx < 1 Then DayPx := 1;
 If DayPx > 32 Then DayPx := 32;
 GanttOriginDt := Project.StartDate - 2;
 NeedGanttRedraw := True;
End;

Procedure ActionScrollTask;
Var T: PTask;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 GanttOriginDt := T^.Start - 2;
 NeedGanttRedraw := True;
End;

Procedure ActionView(V: Byte);
Var Y0, M0, D0: Integer;
Begin
 CurView := V;
 If (V = VIEW_CALENDAR) And (CalYear = 2025) And (CalMonth = 1)
    And (Project.StartDate > 0) Then Begin
  JDNToDate(Project.StartDate, Y0, M0, D0);
  CalMonth := M0; CalYear := Y0;
 End;
 NeedFullRedraw := True;
End;

Procedure ActionQuit;
Begin
 Quitting := True;
End;

Procedure ActionProjInfo;
Begin
 DoProjectInfoDialog;
End;

Procedure ActionTaskInfo;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 If Project.Tasks[CurTaskIdx] = Nil Then Exit;
 DoTaskInfoDialog;
End;

Procedure ActionResourceSheet;
Begin
 DoResourceSheetDialog;
End;

Procedure ActionInsertPicture;
Var
 FName: String;
 Filt: Integer;
 P: PPicture;
Begin
 FName := ''; Filt := 7;     { Tous les fichiers - user types *.BMP/*.PCX/*.GIF }
 If Not DoFileDialog(False, FName, Filt) Then Exit;
 P := NewPicture;
 If P = Nil Then Begin
  MessageBox('Image', 'Limite d''images atteinte.'); Exit;
 End;
 If Not LoadPictureFile(FName, P) Then Begin
  FreeMem(P, SizeOf(TPicture));
  MessageBox('Image',
   'Format non reconnu ou fichier illisible.' + #13 +
   'Formats supportes : BMP (4/8/24 bits), PCX 8 bits, GIF (entete).');
  Exit;
 End;
 P^.FileName := Copy(FName, 1, 80);
 If (CurTaskIdx > 0) And (CurTaskIdx <= Project.TaskCount) Then
  P^.AnchorTsk := CurTaskIdx
 Else Begin
  P^.AnchorTsk := 0;
  P^.X := GanttX1 + 20;
  P^.Y := GanttBodyY1 + 20;
 End;
 Inc(PicCount);
 Pictures[PicCount] := P;
 Project.Dirty := True;
 StatusMsg := 'Image inseree : ' + FName + ' (' +
              IntToStr(P^.Width) + 'x' + IntToStr(P^.Height) + ')';
 NeedStatRedraw := True;
 NeedFullRedraw := True;
End;

Procedure DoAction(A: Integer);
Begin
 Case A Of
  ACT_NEW:        ActionNew;
  ACT_OPEN:       ActionOpen;
  ACT_SAVE:       ActionSave;
  ACT_SAVEAS:     ActionSaveAs;
  ACT_QUIT:       ActionQuit;
  ACT_HELP_ABOUT: ActionAbout;
  ACT_INS_TASK:   ActionInsTask;
  ACT_DELETE:     ActionDeleteTask;
  ACT_INDENT:     ActionIndent;
  ACT_OUTDENT:    ActionOutdent;
  ACT_LINK:       ActionLink;
  ACT_UNLINK:     ActionUnlink;
  ACT_ZOOM_IN:    ActionZoomIn;
  ACT_ZOOM_OUT:   ActionZoomOut;
  ACT_ZOOM_FIT:   ActionZoomFit;
  ACT_SCROLL_TASK:ActionScrollTask;
  ACT_VIEW_GANTT: ActionView(VIEW_GANTT);
  ACT_VIEW_NET:   ActionView(VIEW_NETWORK);
  ACT_VIEW_RES:   ActionView(VIEW_RESOURCE);
  ACT_VIEW_USAGE: ActionView(VIEW_USAGE);
  ACT_VIEW_CAL:   ActionView(VIEW_CALENDAR);
  ACT_PROJ_INFO:  ActionProjInfo;
  ACT_TASKINFO:   ActionTaskInfo;
  ACT_RES_SHEET:  ActionResourceSheet;
  ACT_TOOL_BASE:  ActionSaveBaseline;
  ACT_TOOL_LEVEL: ActionLevelResources;
  ACT_TOOL_TRACK: ActionUpdateProgress;
  ACT_INS_PIC:    ActionInsertPicture;
  ACT_PRINT:      ActionPrintEx;
  ACT_REPORTS:    ActionReports;
  ACT_RPT_SUM:    Begin GenReportSummary;     DoReportPreview; NeedFullRedraw := True; End;
  ACT_RPT_TASKS:  Begin GenReportTasks;       DoReportPreview; NeedFullRedraw := True; End;
  ACT_RPT_CRIT:   Begin GenReportCritical;    DoReportPreview; NeedFullRedraw := True; End;
  ACT_RPT_RES:    Begin GenReportResources;   DoReportPreview; NeedFullRedraw := True; End;
  ACT_RPT_COST:   Begin GenReportCosts;       DoReportPreview; NeedFullRedraw := True; End;
  ACT_RPT_MS:     Begin GenReportMilestones;  DoReportPreview; NeedFullRedraw := True; End;
  ACT_HELP_TOPIC: ActionAbout;
  ACT_HELP_TUTOR: ActionAbout;
 Else
  StatusMsg := 'Action non implementee : ' + IntToStr(A);
  NeedStatRedraw := True;
 End;
End;

{ ====================================================================== }
{                       NAVIGATION                                       }
{ ====================================================================== }

Procedure EnsureCurVisible;
Var Vis: Integer;
Begin
 Vis := VisibleRowCount;
 If CurTaskIdx - 1 < GridScrollY Then GridScrollY := CurTaskIdx - 1;
 If CurTaskIdx - 1 >= GridScrollY + Vis Then GridScrollY := CurTaskIdx - Vis;
 If GridScrollY < 0 Then GridScrollY := 0;
End;

Procedure HandleKey(K: Char);
Var K2: Char;
Begin
 If EditMode Then Begin HandleEditKey(K); Exit; End;
 { --- Vues non Gantt : navigation specifique --- }
 If CurView <> VIEW_GANTT Then Begin
  If K = #0 Then Begin
   K2 := ReadKey;
   Case CurView Of
    VIEW_NETWORK:
     Case K2 Of
      #72: If CurTaskIdx > 1 Then Dec(CurTaskIdx);
      #80: If CurTaskIdx < Project.TaskCount Then Inc(CurTaskIdx);
      #75: Begin If NetScrollX >= 40 Then Dec(NetScrollX, 40); End;
      #77: Inc(NetScrollX, 40);
      #73: If NetScrollY >= 80 Then Dec(NetScrollY, 80);
      #81: Inc(NetScrollY, 80);
      #71: Begin NetScrollX := 0; NetScrollY := 0; End;
      #107: ActionQuit;
     End;
    VIEW_RESOURCE:
     Case K2 Of
      #72: Begin If ResViewEdit Then RVCommitEdit;
                 If ResViewSelRow > 1 Then Dec(ResViewSelRow); End;
      #80: Begin If ResViewEdit Then RVCommitEdit;
                 If ResViewSelRow < Project.ResCount Then Inc(ResViewSelRow); End;
      #75: If ResViewEdit Then Begin
            If ResViewCaret > 0 Then Dec(ResViewCaret);
           End
           Else If ResViewCol > 1 Then Dec(ResViewCol);
      #77: If ResViewEdit Then Begin
            If ResViewCaret < Length(ResViewBuf) Then Inc(ResViewCaret);
           End
           Else If ResViewCol < 5 Then Inc(ResViewCol);
      #71: If ResViewEdit Then ResViewCaret := 0;
      #79: If ResViewEdit Then ResViewCaret := Length(ResViewBuf);
      #83: If ResViewEdit And (ResViewCaret < Length(ResViewBuf)) Then
            Delete(ResViewBuf, ResViewCaret + 1, 1);
      #107: ActionQuit;
     End;
    VIEW_USAGE:
     Case K2 Of
      #72: If CurTaskIdx > 1 Then Dec(CurTaskIdx);
      #80: If CurTaskIdx < Project.TaskCount Then Inc(CurTaskIdx);
      #75: If UsageScrollX > 0 Then Dec(UsageScrollX);
      #77: Inc(UsageScrollX);
      #73: If UsageScrollY > 0 Then Dec(UsageScrollY, 8);
      #81: Inc(UsageScrollY, 8);
      #107: ActionQuit;
     End;
    VIEW_CALENDAR:
     Case K2 Of
      #75: Begin Dec(CalMonth);
                 If CalMonth < 1 Then Begin CalMonth := 12; Dec(CalYear); End; End;
      #77: Begin Inc(CalMonth);
                 If CalMonth > 12 Then Begin CalMonth := 1; Inc(CalYear); End; End;
      #73: Dec(CalYear);
      #81: Inc(CalYear);
      #107: ActionQuit;
     End;
   End;
   NeedGanttRedraw := True;
  End
  Else
   Case K Of
    #13: Begin
          If CurView = VIEW_RESOURCE Then Begin
           If ResViewEdit Then Begin RVCommitEdit;
            If ResViewSelRow < Project.ResCount Then Inc(ResViewSelRow);
           End
           Else RVStartEdit;
          End
          Else If CurView = VIEW_NETWORK Then ActionTaskInfo;
         End;
    #27: If (CurView = VIEW_RESOURCE) And ResViewEdit Then ResViewEdit := False
         Else ActionQuit;
    #9:  If CurView = VIEW_RESOURCE Then Begin
          If ResViewEdit Then RVCommitEdit;
          If ResViewCol < 5 Then Inc(ResViewCol) Else ResViewCol := 1;
         End;
    #8:  If (CurView = VIEW_RESOURCE) And ResViewEdit And (ResViewCaret > 0) Then Begin
          Delete(ResViewBuf, ResViewCaret, 1); Dec(ResViewCaret);
         End;
   Else
    If (CurView = VIEW_RESOURCE) And (K >= ' ') Then Begin
     If Not ResViewEdit Then Begin RVStartEdit; ResViewBuf := ''; ResViewCaret := 0; End;
     If Length(ResViewBuf) < 60 Then Begin
      Insert(K, ResViewBuf, ResViewCaret + 1); Inc(ResViewCaret);
     End;
    End;
   End;
  NeedGanttRedraw := True;
  Exit;
 End;
 If K = #0 Then Begin
  K2 := ReadKey;
  Case K2 Of
   #72: Begin If CurTaskIdx > 1 Then Dec(CurTaskIdx); EnsureCurVisible;
              NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #80: Begin If CurTaskIdx < Project.TaskCount Then Inc(CurTaskIdx);
              EnsureCurVisible; NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #75: Begin If CurColIdx > 1 Then Begin Dec(CurColIdx);
              NeedGridRedraw := True; End; End;
   #77: Begin If CurColIdx < ColCount Then Begin Inc(CurColIdx);
              NeedGridRedraw := True; End; End;
   #115: Begin If GanttOriginDt > 0 Then Begin Dec(GanttOriginDt); NeedGanttRedraw := True; End; End;
   #116: Begin Inc(GanttOriginDt); NeedGanttRedraw := True; End;
   #71: Begin CurTaskIdx := 1; GridScrollY := 0;
              NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #79: Begin CurTaskIdx := Project.TaskCount; EnsureCurVisible;
              NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #73: Begin CurTaskIdx := CurTaskIdx - VisibleRowCount;
              If CurTaskIdx < 1 Then CurTaskIdx := 1; EnsureCurVisible;
              NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #81: Begin CurTaskIdx := CurTaskIdx + VisibleRowCount;
              If CurTaskIdx > Project.TaskCount Then CurTaskIdx := Project.TaskCount;
              EnsureCurVisible; NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #82: ActionInsTask;
   #83: ActionDeleteTask;
   #59: MessageBox('Aide', 'F2=editer, Tab=colonne, Inser/Del, +/-, Esc=quitter');
   #60: BeginEdit(CurTaskIdx, CurColIdx);
   #63: ActionZoomFit;
   #107: ActionQuit;
   #30: ActionNew;
   #31: DoAction(ACT_SAVE);
   #24: DoAction(ACT_OPEN);
   #25: DoAction(ACT_PRINT);
  End;
 End
 Else
  Case K Of
   #13: BeginEdit(CurTaskIdx, CurColIdx);
   #27: ActionQuit;
   #9:  Begin
         If CurColIdx < ColCount Then Inc(CurColIdx) Else CurColIdx := 1;
         NeedGridRedraw := True;
        End;
   '+': ActionZoomIn;
   '-': ActionZoomOut;
   '*': ActionZoomFit;
  Else
   If (K >= ' ') And (CurTaskIdx >= 1) And (CurTaskIdx <= Project.TaskCount)
      And FieldIsEditable(Cols[CurColIdx].Field) Then Begin
    BeginEdit(CurTaskIdx, CurColIdx);
    EditBuf := K;
    EditCaret := 1;
    NeedGridRedraw := True;
   End;
  End;
End;

{ ====================================================================== }
{                       SOURIS                                           }
{ ====================================================================== }

Procedure HandleMouseClick;
Var M, I, Idx, Col, RC: Integer; Y, A: Integer;
Begin
 If EditMode Then Begin
  If InRect(Mouse.X, Mouse.Y, GridBodyY1 - 1, 0, SCREEN_W, SCREEN_H) Then Begin
   { laissez le clic passer pour resituer; toute interaction ailleurs commit }
  End;
  CommitEdit;
 End;
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
 If (Mouse.Y >= ToolY1) And (Mouse.Y <= ToolY2) Then Begin
  I := ToolAtXY(Mouse.X, Mouse.Y);
  If I > 0 Then DoAction(Tools[I].Action);
  Exit;
 End;
 If InRect(Mouse.X, Mouse.Y, SplitX, WorkY1, SplitX + SPLIT_W - 1, WorkY2) Then Begin
  DraggingSplit := True;
  Exit;
 End;
 RC := ColResizeHit(Mouse.X, Mouse.Y);
 If RC > 0 Then Begin
  DragColIdx := RC;
  DragColStartX := Mouse.X;
  DragColStartW := Cols[RC].Width;
  Exit;
 End;
 If (Mouse.Y >= GridHdrY1) And (Mouse.Y <= GridHdrY2) Then Begin
  Col := ColHit(Mouse.X);
  If Col > 0 Then Begin
   CurColIdx := Col;
   NeedGridRedraw := True;
  End;
  Exit;
 End;
 If InRect(Mouse.X, Mouse.Y, GridX1, GridBodyY1, GridX2, GridBodyY2) Then Begin
  Y := Mouse.Y - GridBodyY1;
  Idx := GridScrollY + (Y Div ROW_H) + 1;
  Col := ColHit(Mouse.X);
  If (Idx >= 1) And (Idx <= Project.TaskCount) Then Begin
   CurTaskIdx := Idx;
   If Col > 0 Then CurColIdx := Col;
   NeedGridRedraw := True;
   NeedGanttRedraw := True;
   If DoubleClicked And (Col > 0) Then
    BeginEdit(Idx, Col);
  End;
  Exit;
 End;
 If InRect(Mouse.X, Mouse.Y, GanttX1, GanttBodyY1, GanttX2, GanttBodyY2) Then Begin
  Y := Mouse.Y - GanttBodyY1;
  Idx := GridScrollY + (Y Div ROW_H) + 1;
  If (Idx >= 1) And (Idx <= Project.TaskCount) Then Begin
   CurTaskIdx := Idx;
   NeedGridRedraw := True;
   NeedGanttRedraw := True;
   If DoubleClicked Then ActionTaskInfo;
  End;
  Exit;
 End;
End;

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
  VIEW_GANTT: Begin
   DrawGrid;
   DrawSplitter;
   DrawGantt;
  End;
  VIEW_NETWORK:  DrawNetwork;
  VIEW_RESOURCE: DrawResourceView;
  VIEW_USAGE:    DrawUsage;
  VIEW_CALENDAR: DrawCalendar;
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
  NeedGanttRedraw := False;
  NeedMenuRedraw := False;
  NeedStatRedraw := False;
  NeedDropRedraw := False;
  Exit;
 End;
 If NeedMenuRedraw Then Begin DrawMenuBar; NeedMenuRedraw := False; End;
 Case CurView Of
  VIEW_GANTT: Begin
   If NeedGridRedraw Then Begin DrawGrid; NeedGridRedraw := False; End;
   If NeedGanttRedraw Then Begin DrawGantt; NeedGanttRedraw := False; End;
  End;
  VIEW_NETWORK:  If NeedGanttRedraw Or NeedGridRedraw Then
                  Begin DrawNetwork; NeedGanttRedraw := False;
                        NeedGridRedraw := False; End;
  VIEW_RESOURCE: If NeedGanttRedraw Or NeedGridRedraw Then
                  Begin DrawResourceView; NeedGanttRedraw := False;
                        NeedGridRedraw := False; End;
  VIEW_USAGE:    If NeedGanttRedraw Or NeedGridRedraw Then
                  Begin DrawUsage; NeedGanttRedraw := False;
                        NeedGridRedraw := False; End;
  VIEW_CALENDAR: If NeedGanttRedraw Or NeedGridRedraw Then
                  Begin DrawCalendar; NeedGanttRedraw := False;
                        NeedGridRedraw := False; End;
 End;
 If NeedStatRedraw Then Begin DrawStatusBar; NeedStatRedraw := False; End;
 If (MenuOpen > 0) And NeedDropRedraw Then Begin
  DrawDropDown; NeedDropRedraw := False;
 End;
 If EditMode And (CurView = VIEW_GANTT) Then DrawEditBox;
End;

{ ====================================================================== }
{                       BOUCLE PRINCIPALE                                }
{ ====================================================================== }

Procedure MainLoop;
Var K: Char; NewSplit, NewW: Integer; Dx: Integer;
Begin
 NeedFullRedraw := True;
 Redraw;
 Repeat
  Inc(TickCount);
  UpdateMouse;
  UpdateHovers;
  If DraggingSplit Then Begin
   If LeftDown Then Begin
    NewSplit := Mouse.X;
    If NewSplit < 80 Then NewSplit := 80;
    If NewSplit > SCREEN_W - 100 Then NewSplit := SCREEN_W - 100;
    If NewSplit <> SplitX Then Begin
     SplitX := NewSplit;
     NeedFullRedraw := True;
    End;
   End
   Else DraggingSplit := False;
  End
  Else If DragColIdx > 0 Then Begin
   If LeftDown Then Begin
    Dx := Mouse.X - DragColStartX;
    NewW := DragColStartW + Dx;
    If NewW < 16 Then NewW := 16;
    If NewW > 400 Then NewW := 400;
    If NewW <> Cols[DragColIdx].Width Then Begin
     Cols[DragColIdx].Width := NewW;
     NeedGridRedraw := True;
    End;
   End
   Else DragColIdx := 0;
  End
  Else If LeftPressed Then Begin
   DoubleClicked := (AbsI(Mouse.X - ClickPrevX) <= 4)
                And (AbsI(Mouse.Y - ClickPrevY) <= 4)
                And ((TickCount - ClickPrevTick) < 30);
   HandleMouseClick;
   ClickPrevX := Mouse.X;
   ClickPrevY := Mouse.Y;
   ClickPrevTick := TickCount;
   DoubleClicked := False;
  End;
  If KeyPressed Then Begin
   K := ReadKey;
   HandleKey(K);
  End;
  If EditMode And ((TickCount - EditTickSave) >= 8) Then Begin
   BlinkState := Not BlinkState;
   EditTickSave := TickCount;
   NeedGridRedraw := True;
  End;
  Redraw;
 Until Quitting;
End;

Procedure InitGlobals;
Begin
 Mouse.X := 0; Mouse.Y := 0; Mouse.B := 0; Mouse.Visible := True;
 LastClickB := 0;
 MenuOpen := 0; MenuHover := 0; MenuItemHover := 0;
 ToolHover := 0;
 CurView := VIEW_GANTT;
 DayPx := 6;
 SplitX := 280;
 GridScrollX := 0;
 GridScrollY := 0;
 CurTaskIdx := 1;
 CurColIdx := 3;
 NeedFullRedraw := True;
 NeedGridRedraw := False;
 NeedGanttRedraw := False;
 NeedMenuRedraw := False;
 NeedStatRedraw := False;
 Quitting := False;
 StatusMsg := '';
 EditMode := False;
 EditBuf := '';
 EditCaret := 0;
 EditRow := 0;
 EditCol := 0;
 EditTickSave := 0;
 BlinkState := False;
 DraggingSplit := False;
 DragColIdx := 0;
 DragColStartX := 0;
 DragColStartW := 0;
 ClickPrevX := -100; ClickPrevY := -100;
 ClickPrevTick := -10000;
 DoubleClicked := False;
 TickCount := 0;
 NetScrollX := 0; NetScrollY := 0;
 UsageScrollX := 0; UsageScrollY := 0;
 UsageMode := 0;
 ResViewSelRow := 1; ResViewCol := 1; ResViewScrollY := 0;
 ResViewEdit := False; ResViewBuf := ''; ResViewCaret := 0;
 CalMonth := 1; CalYear := 2025;
End;

BEGIN
 InitializeGraphics;
 InitGlobals;
 InitColumns;
 InitMenus;
 LayoutMenus;
 InitTools;
 InitProject;
 SampleProject;
 GanttOriginDt := Project.StartDate - 3;
 If MouseDriverFound Then ShowMouse;
 MainLoop;
 FreeProject;
 CloseGraph;
END.
