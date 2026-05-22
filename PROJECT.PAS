{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Microsoft Project
}

Program MSPROJECT;

Uses {$IFDEF FPC}
      Crt,PtcGraph,PtcCrt,PtcMouse
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
  WBS          : String[20];
  Resources    : String[60];
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

 Quitting      : Boolean;
 StatusMsg     : String;

 ColCount      : Integer;
 Cols          : Array[1..MAX_COLS] Of TGridCol;

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

Procedure InitProject;
Var C: PCalendar;
Begin
 FreeProject;
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
{                       PROJET D'EXEMPLE                                 }
{ ====================================================================== }

Procedure SampleProject;
Var S: TDate;
Begin
 InitProject;
 Project.Title := 'Construction maison';
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

 ComputeSummaries;
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
Var I, X, W: Integer;
Begin
 X := GridX1 - GridScrollX;
 For I := 1 To ColCount Do Begin
  W := Cols[I].Width;
  If (X + W >= GridX1) And (X <= GridX2) Then Begin
   DrawRaised(MaxI(X, GridX1), GridHdrY1, MinI(X + W - 1, GridX2),
              GridHdrY2, CLR_GRID_HDR_BG, CLR_WIN_HI, CLR_BLACK);
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
 ShowMouse;
End;

Procedure DrawSplitter;
Begin
 FillBox(SplitX, WorkY1, SplitX + SPLIT_W - 1, WorkY2, CLR_LGRAY);
 VLine(SplitX, WorkY1, WorkY2, CLR_WIN_HI);
 VLine(SplitX + SPLIT_W - 1, WorkY1, WorkY2, CLR_WIN_LO);
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
{                       ACTIONS                                          }
{ ====================================================================== }

Procedure DoAction(A: Integer); Forward;

Procedure ActionNew;
Begin
 InitProject;
 ComputeSummaries;
 CurTaskIdx := 1;
 GridScrollY := 0;
 GanttOriginDt := Project.StartDate - 3;
 NeedFullRedraw := True;
End;

Procedure ActionAbout;
Begin
 MessageBox('A propos', 'Clone Microsoft Project - Office-0 v1.00');
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
 ComputeSummaries;
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
 ComputeSummaries;
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
 ComputeSummaries;
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
 ComputeSummaries;
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
Begin
 CurView := V;
 NeedFullRedraw := True;
End;

Procedure ActionQuit;
Begin
 Quitting := True;
End;

Procedure ActionProjInfo;
Begin
 MessageBox('Informations sur le projet',
            Project.Title + '   Debut: ' + ShortDateStr(Project.StartDate));
End;

Procedure ActionTaskInfo;
Var T: PTask;
Begin
 If (CurTaskIdx < 1) Or (CurTaskIdx > Project.TaskCount) Then Exit;
 T := Project.Tasks[CurTaskIdx];
 If T = Nil Then Exit;
 MessageBox('Informations sur la tache',
            T^.Name + '  Id: ' + IntToStr(T^.Id));
End;

Procedure DoAction(A: Integer);
Begin
 Case A Of
  ACT_NEW:        ActionNew;
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
 If K = #0 Then Begin
  K2 := ReadKey;
  Case K2 Of
   #72: Begin If CurTaskIdx > 1 Then Dec(CurTaskIdx); EnsureCurVisible;
              NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #80: Begin If CurTaskIdx < Project.TaskCount Then Inc(CurTaskIdx);
              EnsureCurVisible; NeedGridRedraw := True; NeedGanttRedraw := True; End;
   #75: Begin If GanttOriginDt > 0 Then Begin Dec(GanttOriginDt); NeedGanttRedraw := True; End; End;
   #77: Begin Inc(GanttOriginDt); NeedGanttRedraw := True; End;
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
   #59: MessageBox('Aide', 'Fleches, Ins/Del, +/-, F2=info, Esc=quitter');
   #60: ActionTaskInfo;
   #63: ActionZoomFit;
   #107: ActionQuit;
  End;
 End
 Else
  Case K Of
   #27: ActionQuit;
   '+': ActionZoomIn;
   '-': ActionZoomOut;
   '*': ActionZoomFit;
   #14: ActionNew;
  End;
End;

{ ====================================================================== }
{                       SOURIS                                           }
{ ====================================================================== }

Procedure HandleMouseClick;
Var M, I, Idx: Integer; Y, A: Integer;
Begin
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
 If InRect(Mouse.X, Mouse.Y, GridX1, GridBodyY1, GridX2, GridBodyY2) Then Begin
  Y := Mouse.Y - GridBodyY1;
  Idx := GridScrollY + (Y Div ROW_H) + 1;
  If (Idx >= 1) And (Idx <= Project.TaskCount) Then Begin
   CurTaskIdx := Idx;
   NeedGridRedraw := True;
   NeedGanttRedraw := True;
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
 If MenuOpen > 0 Then Begin
  ComputeDropLayout(MenuOpen);
  If InRect(Mouse.X, Mouse.Y, DropX, DropY, DropX + DropW, DropY + DropH) Then
   MenuItemHover := DropItemAtY(MenuOpen, Mouse.Y)
  Else MenuItemHover := 0;
 End
 Else MenuItemHover := 0;
 If MenuHover <> OldM Then NeedMenuRedraw := True;
 If ToolHover <> OldT Then NeedFullRedraw := True;
 If (MenuItemHover <> OldI) And (MenuOpen > 0) Then NeedFullRedraw := True;
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
 DrawGrid;
 DrawSplitter;
 DrawGantt;
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
  Exit;
 End;
 If NeedMenuRedraw Then Begin DrawMenuBar; NeedMenuRedraw := False; End;
 If NeedGridRedraw Then Begin DrawGrid; NeedGridRedraw := False; End;
 If NeedGanttRedraw Then Begin DrawGantt; NeedGanttRedraw := False; End;
 If NeedStatRedraw Then Begin DrawStatusBar; NeedStatRedraw := False; End;
 If MenuOpen > 0 Then DrawDropDown;
End;

{ ====================================================================== }
{                       BOUCLE PRINCIPALE                                }
{ ====================================================================== }

Procedure MainLoop;
Var K: Char;
Begin
 NeedFullRedraw := True;
 Redraw;
 Repeat
  UpdateMouse;
  UpdateHovers;
  If LeftPressed Then HandleMouseClick;
  If KeyPressed Then Begin
   K := ReadKey;
   HandleKey(K);
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
