{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application Lotus 1-2-3
}

Program LOTUS123;

{$IFNDEF FPC}
 {$N+,E+}
 {$M 65520,0,655360}
{$ENDIF}

Uses {$IFDEF FPC}
      DOS,Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      DOS,Crt,Graph
     {$ENDIF};

{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 SCR_W        = 640;
 SCR_H        = 480;

 MAX_SHEETS   = 8;          { feuilles A: a H: }
 MAX_COLS     = 256;        { A .. IV }
 MAX_ROWS     = 8192;
 MAX_NAMES    = 40;
 MAX_CHARTS   = 10;
 MAX_PLACED   = 8;
 MAX_DRAW     = 24;
 MAX_PTS      = 300;
 NSER         = 6;          { series A..F }
 MAX_DEPTH    = {$IFDEF FPC}150{$ELSE}16{$ENDIF};

 { Disposition de l'ecran }
 TITLE_H      = 18;
 MENU_Y       = 18;
 MENU_H       = 18;
 EDIT_Y       = 36;
 EDIT_H       = 20;
 TOOL_Y       = 56;
 TOOL_H       = 28;
 HDR_Y        = 84;
 HDR_H        = 16;
 GRID_TOP     = 100;
 GRID_BOTTOM  = 447;
 GRID_RIGHT   = 623;
 HSB_Y        = 448;
 STAT_Y       = 464;
 RH_W         = 36;         { largeur des en-tetes de lignes }
 ROW_H        = 16;
 DEF_COLW     = 9;          { caracteres }
 CHAR_W       = 8;

 { Couleurs VGA }
 CL_BLACK     = 0;
 CL_BLUE      = 1;
 CL_DKGRAY    = 8;
 CL_BG        = 7;
 CL_WHITE     = 15;
 CL_SEL       = 11;
 CL_NONE      = 255;

 { Types de cellule }
 CK_EMPTY     = 0;
 CK_LABEL     = 1;
 CK_VALUE     = 2;
 CK_FORMULA   = 3;

 { Formats numeriques }
 FM_GENERAL   = 0;
 FM_FIXED     = 1;
 FM_SCI       = 2;
 FM_CURRENCY  = 3;
 FM_COMMA     = 4;
 FM_PERCENT   = 5;
 FM_PLUSMINUS = 6;
 FM_DATE1     = 7;    { DD-MMM-YY }
 FM_DATE2     = 8;    { DD-MMM }
 FM_DATE3     = 9;    { MMM-YY }
 FM_DATE4     = 10;   { MM/DD/YY }
 FM_TIME1     = 11;   { HH:MM AM/PM }
 FM_TEXT      = 12;
 FM_HIDDEN    = 13;

 { Styles }
 ST_BOLD      = 1;
 ST_ITALIC    = 2;
 ST_UNDER     = 4;

 { Alignement }
 AL_GENERAL   = 0;
 AL_LEFT      = 1;
 AL_CENTER    = 2;
 AL_RIGHT     = 3;

 { Codes d'erreur de formule }
 E_NONE       = 0;
 E_ERR        = 1;
 E_NA         = 2;
 E_CIRC       = 3;

 { Types de graphique }
 CH_LINE      = 1;
 CH_BAR       = 2;
 CH_STACK     = 3;
 CH_HBAR      = 4;
 CH_AREA      = 5;
 CH_PIE       = 6;
 CH_XY        = 7;

 { Outils de dessin }
 DT_NONE      = 0;
 DT_LINE      = 1;
 DT_ARROW     = 2;
 DT_RECT      = 3;
 DT_ELLIPSE   = 4;
 DT_TEXT      = 5;

 { Touches etendues (apres #0) }
 K_UP         = #72;
 K_DOWN       = #80;
 K_LEFT       = #75;
 K_RIGHT      = #77;
 K_HOME       = #71;
 K_END        = #79;
 K_PGUP       = #73;
 K_PGDN       = #81;
 K_INS        = #82;
 K_DEL        = #83;
 K_F1         = #59;
 K_F2         = #60;
 K_F3         = #61;
 K_F4         = #62;
 K_F5         = #63;
 K_F9         = #67;
 K_F10        = #68;
 K_CTRL_LEFT  = #115;
 K_CTRL_RIGHT = #116;
 K_CTRL_HOME  = #119;
 K_CTRL_END   = #117;
 K_CTRL_PGUP  = #132;
 K_CTRL_PGDN  = #118;
 K_SHIFT_TAB  = #15;

{ ====================================================================== }
{                              TYPES                                     }
{ ====================================================================== }

Type
 PStr = ^String;

 PCell = ^TCell;
 TCell = Record
  Kind   : Byte;
  Pfx    : Char;        { prefixe d'etiquette : ' " ^ \ ou #0 }
  Fmt    : Byte;
  Dec    : Byte;
  Align  : Byte;
  Style  : Byte;
  Fg, Bg : Byte;
  Err    : Byte;
  IsStr  : Boolean;
  Busy   : Boolean;
  Stamp  : Word;
  Num    : Double;
  Txt    : PStr;        { etiquette ou source de la formule }
  Res    : PStr;        { resultat texte d'une formule }
 End;

 PRow = ^TRow;
 TRow = Array[0..MAX_COLS-1] Of PCell;

 PSheet = ^TSheet;
 TSheet = Record
  Rows : Array[0..MAX_ROWS-1] Of PRow;
  ColW : Array[0..MAX_COLS-1] Of Byte;
  RowH : Array[0..MAX_ROWS-1] Of Byte;
  MaxR, MaxC : Integer;
 End;

 TNameRec = Record
  Name           : String[15];
  Sheet          : Integer;
  R1, C1, R2, C2 : Integer;
 End;

 TVal = Record
  K : Byte;             { 0 nombre, 1 texte, 2 erreur, 3 etiquette (0 en calcul) }
  N : Double;
  S : String[80];
 End;

 TDraw = Record
  Kind           : Byte;
  X1, Y1, X2, Y2 : Integer;
  Col            : Byte;
  Txt            : String[40];
 End;

 PChart = ^TChart;
 TChart = Record
  Name      : String[15];
  CType     : Byte;
  ThreeD    : Boolean;
  XRng      : String[30];
  Rng       : Array[1..NSER] Of String[30];
  Legend    : Array[1..NSER] Of String[14];
  SCol      : Array[1..NSER] Of Byte;
  Title1    : String[40];
  Title2    : String[40];
  XTitle    : String[30];
  YTitle    : String[30];
  ShowLeg   : Boolean;
  GridH     : Boolean;
  GridV     : Boolean;
  Markers   : Boolean;
  Frame     : Boolean;
  Bg        : Byte;
  Depth     : Integer;
  AutoY     : Boolean;
  YMin, YMax: Double;
  NDraw     : Integer;
  Draws     : Array[1..MAX_DRAW] Of TDraw;
 End;

 TPlaced = Record
  Used           : Boolean;
  Sheet          : Integer;
  Chart          : Integer;
  R1, C1, R2, C2 : Integer;
 End;

 TChData = Record
  N, S  : Integer;
  Used  : Array[1..NSER] Of Boolean;
  V     : Array[1..NSER, 1..MAX_PTS] Of Double;
  X     : Array[1..MAX_PTS] Of Double;
  XLab  : Array[1..MAX_PTS] Of String[10];
  HasX  : Boolean;
 End;
 PChData = ^TChData;

 { Entree du menu : libelle, commande, sous-menu }
 TMI = Record
  L : String[40];
  C : Integer;
  S : Integer;
 End;

 TMouse = Record
  X, Y, B : LongInt;
 End;

 TSnapCell = Record
  R, C : Integer;
  P    : PCell;
 End;

 PUndo = ^TUndo;
 TUndo = Record
  Sheet          : Integer;
  R1, C1, R2, C2 : Integer;
  N              : Integer;
  Cells          : ^TSnapArr;
  Next           : PUndo;
 End;
 TSnapArr = Array[0..0] Of TSnapCell;

Const
 UNDO_MAX = 12;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 Sheets      : Array[1..MAX_SHEETS] Of PSheet;
 ActSheet    : Integer;
 CurR, CurC  : Integer;       { curseur }
 SelR1, SelC1, SelR2, SelC2 : Integer;   { selection normalisee }
 AncR, AncC  : Integer;       { ancre de la selection }
 ScrollR, ScrollC : Integer;
 Names       : Array[1..MAX_NAMES] Of TNameRec;
 NameCount   : Integer;
 Charts      : Array[1..MAX_CHARTS] Of PChart;
 CurChart    : Integer;
 Placed      : Array[1..MAX_PLACED] Of TPlaced;
 ChD         : PChData;
 FileName    : String;
 Modified    : Boolean;
 CalcStamp   : Word;
 AutoCalc    : Boolean;
 ShowGrid    : Boolean;
 ShowHead    : Boolean;
 ShowTools   : Boolean;
 CircFound   : Boolean;
 ParseFail   : Boolean;

 { Evaluation de formules }
 FSrc        : String;
 FPos        : Integer;
 FSheet      : Integer;
 FDepth      : Integer;

 { Souris et saisie }
 Mouse       : TMouse;
 LastB       : LongInt;
 NeedRedraw  : Boolean;
 InputMode   : Boolean;
 InputBuf    : String;
 InputPos    : Integer;
 InputEdit   : Boolean;       { True = mode EDIT (F2), False = LABEL/VALUE }
 InsertMode  : Boolean;
 EndMode     : Boolean;
 StatusMsg   : String;
 Dragging    : Boolean;
 AppMode     : Integer;       { 0 = feuille, 1 = fenetre graphique }
 Quit        : Boolean;

 { Menus }
 MenuOpen    : Integer;
 MenuHi      : Integer;
 SubOpen     : Integer;
 SubHi       : Integer;
 MenuActive  : Boolean;

 { Presse-papiers }
 ClipN       : Integer;
 ClipRows    : Integer;
 ClipCols    : Integer;
 ClipCells   : Array[1..600] Of TSnapCell;
 ClipCut     : Boolean;
 ClipSrcR    : Integer;
 ClipSrcC    : Integer;
 ClipSheet   : Integer;
 UndoTop     : PUndo;
 UndoCount   : Integer;

 { Fenetre graphique }
 DrawTool    : Integer;
 GObjSel     : Integer;
 OffX, OffY  : Integer;      { decalage de dessin (graphique incorpore) }

 FindText    : String;
 French      : Boolean;

{ ====================================================================== }
{                  INITIALISATION GRAPHIQUE ET SOURIS                    }
{ ====================================================================== }

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

Procedure UpdateMouse;
Begin
 LastB:=Mouse.B;
 GetMouseState(Mouse.X,Mouse.Y,Mouse.B);
End;

Function LeftPressed: Boolean;
Begin
 LeftPressed:=((Mouse.B And 1)<>0) And ((LastB And 1)=0);
End;

Function RightPressed: Boolean;
Begin
 RightPressed:=((Mouse.B And 2)<>0) And ((LastB And 2)=0);
End;

Function LeftDown: Boolean;
Begin
 LeftDown:=(Mouse.B And 1)<>0;
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

{ ====================================================================== }
{                       UTILITAIRES GENERAUX                             }
{ ====================================================================== }

Function IntToStr(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 IntToStr:=S;
End;

Function MinI(A,B: LongInt): LongInt;
Begin
 If A<B Then MinI:=A Else MinI:=B;
End;

Function MaxI(A,B: LongInt): LongInt;
Begin
 If A>B Then MaxI:=A Else MaxI:=B;
End;

Function UpStr(Const S: String): String;
Var I: Integer; T: String;
Begin
 T:=S;
 For I:=1 To Length(T) Do T[I]:=UpCase(T[I]);
 UpStr:=T;
End;

Function TrimStr(Const S: String): String;
Var A,B: Integer;
Begin
 A:=1;
 B:=Length(S);
 While (A<=B) And (S[A]=' ') Do Inc(A);
 While (B>=A) And (S[B]=' ') Do Dec(B);
 TrimStr:=Copy(S,A,B-A+1);
End;

Function PadR(Const S: String; W: Integer): String;
Var T: String;
Begin
 T:=S;
 While Length(T)<W Do T:=T+' ';
 PadR:=Copy(T,1,W);
End;

Function RepStr(Ch: Char; N: Integer): String;
Var S: String; I: Integer;
Begin
 S:='';
 For I:=1 To N Do S:=S+Ch;
 RepStr:=S;
End;

Function IsLetter(C: Char): Boolean;
Begin
 IsLetter:=(C>='A') And (C<='Z') Or (C>='a') And (C<='z');
End;

Function IsDigit(C: Char): Boolean;
Begin
 IsDigit:=(C>='0') And (C<='9');
End;

Function Pow10(E: Integer): Double;
Var V: Double; I: Integer;
Begin
 V:=1;
 If E>=0 Then For I:=1 To E Do V:=V*10
         Else For I:=1 To -E Do V:=V/10;
 Pow10:=V;
End;

Function ColName(C: Integer): String;
Begin
 If C<26 Then ColName:=Chr(65+C)
         Else ColName:=Chr(64+C Div 26)+Chr(65+C Mod 26);
End;

Function CellName(R,C: Integer): String;
Begin
 CellName:=ColName(C)+IntToStr(R+1);
End;

Function SheetLetter(N: Integer): Char;
Begin
 SheetLetter:=Chr(64+N);
End;

Function StrToNum(Const S0: String; Var V: Double): Boolean;
{ Convertit un texte en nombre (formats : 12, -3.5, .5, 1E3, 10%) }
Var S: String; Code,I: Integer; Pct,Ok: Boolean; HasDigit: Boolean;
Begin
 StrToNum:=False;
 S:=TrimStr(S0);
 If S='' Then Exit;
 Pct:=False;
 If S[Length(S)]='%' Then Begin
  Pct:=True;
  Delete(S,Length(S),1);
 End;
 HasDigit:=False;
 Ok:=True;
 For I:=1 To Length(S) Do Begin
  If IsDigit(S[I]) Then HasDigit:=True
  Else If Not (S[I] In ['+','-','.','E','e']) Then Ok:=False;
 End;
 If (Not Ok) Or (Not HasDigit) Then Exit;
 If S[1]='.' Then S:='0'+S;
 If (Length(S)>1) And (S[1] In ['+','-']) And (S[2]='.') Then Insert('0',S,2);
 If S[Length(S)]='.' Then Delete(S,Length(S),1);
 Val(S,V,Code);
 If Code<>0 Then Exit;
 If Pct Then V:=V/100;
 StrToNum:=True;
End;

Function NumToStr(V: Double; Dc: Integer): String;
Var S: String;
Begin
 Str(V:0:Dc,S);
 NumToStr:=S;
End;

{ ====================================================================== }
{                       CELLULES ET FEUILLES                             }
{ ====================================================================== }

Function NewPStr(Const S: String): PStr;
Var P: PStr;
Begin
 If S='' Then Begin NewPStr:=Nil; Exit; End;
 GetMem(P,Length(S)+1);
 Move(S,P^,Length(S)+1);
 NewPStr:=P;
End;

Procedure FreePStr(Var P: PStr);
Begin
 If P<>Nil Then Begin
  FreeMem(P,Length(P^)+1);
  P:=Nil;
 End;
End;

Function PStrVal(P: PStr): String;
Begin
 If P=Nil Then PStrVal:='' Else PStrVal:=P^;
End;

Procedure InitCell(P: PCell);
Begin
 FillChar(P^,SizeOf(TCell),0);
 P^.Dec:=2;
 P^.Fg:=CL_NONE;
 P^.Bg:=CL_NONE;
End;

Function SheetPtr(N: Integer): PSheet;
Var Sh: PSheet; I: Integer;
Begin
 If (N<1) Or (N>MAX_SHEETS) Then Begin SheetPtr:=Nil; Exit; End;
 If Sheets[N]=Nil Then Begin
  New(Sh);
  FillChar(Sh^,SizeOf(TSheet),0);
  For I:=0 To MAX_COLS-1 Do Sh^.ColW[I]:=DEF_COLW;
  Sh^.MaxR:=0;
  Sh^.MaxC:=0;
  Sheets[N]:=Sh;
 End;
 SheetPtr:=Sheets[N];
End;

Function CellAt(Sh: PSheet; R,C: Integer): PCell;
Begin
 CellAt:=Nil;
 If Sh=Nil Then Exit;
 If (R<0) Or (R>=MAX_ROWS) Or (C<0) Or (C>=MAX_COLS) Then Exit;
 If Sh^.Rows[R]=Nil Then Exit;
 CellAt:=Sh^.Rows[R]^[C];
End;

Function CellNew(Sh: PSheet; R,C: Integer): PCell;
Var Row: PRow; P: PCell;
Begin
 CellNew:=Nil;
 If (R<0) Or (R>=MAX_ROWS) Or (C<0) Or (C>=MAX_COLS) Then Exit;
 If Sh^.Rows[R]=Nil Then Begin
  New(Row);
  FillChar(Row^,SizeOf(TRow),0);
  Sh^.Rows[R]:=Row;
 End;
 P:=Sh^.Rows[R]^[C];
 If P=Nil Then Begin
  New(P);
  InitCell(P);
  Sh^.Rows[R]^[C]:=P;
  If R>Sh^.MaxR Then Sh^.MaxR:=R;
  If C>Sh^.MaxC Then Sh^.MaxC:=C;
 End;
 CellNew:=P;
End;

Procedure CellFreeContent(P: PCell);
Begin
 FreePStr(P^.Txt);
 FreePStr(P^.Res);
 P^.Kind:=CK_EMPTY;
 P^.Pfx:=#0;
 P^.Num:=0;
 P^.Err:=0;
 P^.IsStr:=False;
End;

Procedure CellDispose(Var P: PCell);
Begin
 If P=Nil Then Exit;
 CellFreeContent(P);
 Dispose(P);
 P:=Nil;
End;

Procedure CellKill(Sh: PSheet; R,C: Integer);
Begin
 If Sh=Nil Then Exit;
 If (R<0) Or (R>=MAX_ROWS) Or (C<0) Or (C>=MAX_COLS) Then Exit;
 If Sh^.Rows[R]=Nil Then Exit;
 CellDispose(Sh^.Rows[R]^[C]);
End;

Function CellCopy(Src: PCell): PCell;
Var P: PCell;
Begin
 New(P);
 Move(Src^,P^,SizeOf(TCell));
 P^.Txt:=NewPStr(PStrVal(Src^.Txt));
 P^.Res:=NewPStr(PStrVal(Src^.Res));
 P^.Busy:=False;
 CellCopy:=P;
End;

Function CurSheet: PSheet;
Begin
 CurSheet:=SheetPtr(ActSheet);
End;

Function ColPx(Sh: PSheet; C: Integer): Integer;
Begin
 ColPx:=Sh^.ColW[C]*CHAR_W;
End;

Function RowPx(Sh: PSheet; R: Integer): Integer;
Begin
 If Sh^.RowH[R]=0 Then RowPx:=ROW_H Else RowPx:=Sh^.RowH[R];
End;

Procedure NormSel;
Var T: Integer;
Begin
 SelR1:=AncR; SelC1:=AncC; SelR2:=CurR; SelC2:=CurC;
 If SelR1>SelR2 Then Begin T:=SelR1; SelR1:=SelR2; SelR2:=T; End;
 If SelC1>SelC2 Then Begin T:=SelC1; SelC1:=SelC2; SelC2:=T; End;
End;

Procedure CollapseSel;
Begin
 AncR:=CurR; AncC:=CurC;
 SelR1:=CurR; SelC1:=CurC; SelR2:=CurR; SelC2:=CurC;
End;

Function SelIsSingle: Boolean;
Begin
 SelIsSingle:=(SelR1=SelR2) And (SelC1=SelC2);
End;

{ Limite la plage aux lignes/colonnes utilisees quand elle est tres grande }
Procedure ClampToUsed(Var R1,C1,R2,C2: Integer);
Var Sh: PSheet; Cnt: LongInt;
Begin
 Sh:=CurSheet;
 Cnt:=LongInt(R2-R1+1)*LongInt(C2-C1+1);
 If Cnt>6000 Then Begin
  If R2>Sh^.MaxR Then R2:=MaxI(Sh^.MaxR,R1);
  If C2>Sh^.MaxC Then C2:=MaxI(Sh^.MaxC,C1);
 End;
End;

{ ====================================================================== }
{                              DATES                                     }
{ ====================================================================== }

Function DaysFromCivil(Y,M,D: LongInt): LongInt;
Var Era,YoE,DoY,DoE: LongInt; Mp: LongInt;
Begin
 If M<=2 Then Y:=Y-1;
 If Y>=0 Then Era:=Y Div 400 Else Era:=(Y-399) Div 400;
 YoE:=Y-Era*400;
 If M>2 Then Mp:=M-3 Else Mp:=M+9;
 DoY:=(153*Mp+2) Div 5+D-1;
 DoE:=YoE*365+YoE Div 4-YoE Div 100+DoY;
 DaysFromCivil:=Era*146097+DoE-719468;
End;

Procedure CivilFromDays(Z: LongInt; Var Y,M,D: LongInt);
Var Era,DoE,YoE,DoY,Mp: LongInt;
Begin
 Z:=Z+719468;
 If Z>=0 Then Era:=Z Div 146097 Else Era:=(Z-146096) Div 146097;
 DoE:=Z-Era*146097;
 YoE:=(DoE-DoE Div 1460+DoE Div 36524-DoE Div 146096) Div 365;
 Y:=YoE+Era*400;
 DoY:=DoE-(365*YoE+YoE Div 4-YoE Div 100);
 Mp:=(5*DoY+2) Div 153;
 D:=DoY-(153*Mp+2) Div 5+1;
 If Mp<10 Then M:=Mp+3 Else M:=Mp-9;
 If M<=2 Then Y:=Y+1;
End;

Function DateToSerial(Y,M,D: LongInt): LongInt;
Var N: LongInt;
Begin
 N:=DaysFromCivil(Y,M,D)-DaysFromCivil(1899,12,30);
 If N<61 Then N:=N-1;
 DateToSerial:=N;
End;

Procedure SerialToDate(N: LongInt; Var Y,M,D: LongInt);
Begin
 If N<61 Then N:=N+1;
 CivilFromDays(N+DaysFromCivil(1899,12,30),Y,M,D);
End;

Function TodaySerial: LongInt;
Var Y,M,D,DW: Word;
Begin
 GetDate(Y,M,D,DW);
 TodaySerial:=DateToSerial(Y,M,D);
End;

Function NowSerial: Double;
Var H,Mi,S,S100: Word;
Begin
 GetTime(H,Mi,S,S100);
 NowSerial:=TodaySerial+(H*3600.0+Mi*60.0+S)/86400.0;
End;

Const
 MonthNames: Array[1..12] Of String[3] =
  ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

Function TwoDig(N: LongInt): String;
Begin
 If N<10 Then TwoDig:='0'+IntToStr(N) Else TwoDig:=IntToStr(N);
End;

{ ====================================================================== }
{                       FORMATAGE DES NOMBRES                            }
{ ====================================================================== }

Function AddCommas(Const S: String): String;
Var Neg: Boolean; T,Ip,Fp,R: String; P,I,K: Integer;
Begin
 T:=S;
 Neg:=False;
 If (T<>'') And (T[1]='-') Then Begin Neg:=True; Delete(T,1,1); End;
 P:=Pos('.',T);
 If P>0 Then Begin Ip:=Copy(T,1,P-1); Fp:=Copy(T,P,255); End
        Else Begin Ip:=T; Fp:=''; End;
 R:='';
 K:=0;
 For I:=Length(Ip) DownTo 1 Do Begin
  If (K>0) And (K Mod 3=0) Then R:=','+R;
  R:=Ip[I]+R;
  Inc(K);
 End;
 If Neg Then R:='-'+R;
 AddCommas:=R+Fp;
End;

Function SciStr(V: Double; Dc: Integer): String;
Var E: Integer; M,A: Double; S,Es: String;
Begin
 If V=0 Then Begin
  S:=NumToStr(0,Dc);
  SciStr:=S+'E+00';
  Exit;
 End;
 A:=Abs(V);
 E:=0;
 While A>=10 Do Begin A:=A/10; Inc(E); End;
 While A<1 Do Begin A:=A*10; Dec(E); End;
 If V<0 Then M:=-A Else M:=A;
 S:=NumToStr(M,Dc);
 If (Abs(M)>=9.9999999) And (Pos('10',S)>0) And (Copy(S,1,2)='10') Then Begin
  M:=M/10; Inc(E);
  S:=NumToStr(M,Dc);
 End;
 If E<0 Then Es:='E-'+TwoDig(-E) Else Es:='E+'+TwoDig(E);
 SciStr:=S+Es;
End;

Function GeneralStr(V: Double; W: Integer): String;
Var S: String; D: Integer;
Begin
 If (V=Int(V)) And (Abs(V)<1E15) Then Begin
  Str(V:0:0,S);
  If Length(S)<=W Then Begin GeneralStr:=S; Exit; End;
 End Else Begin
  For D:=9 DownTo 0 Do Begin
   Str(V:0:D,S);
   If Pos('.',S)>0 Then Begin
    While S[Length(S)]='0' Do Delete(S,Length(S),1);
    If S[Length(S)]='.' Then Delete(S,Length(S),1);
   End;
   If (Length(S)<=W) And (Abs(V)>=0.0005) Then Begin GeneralStr:=S; Exit; End;
  End;
 End;
 For D:=6 DownTo 0 Do Begin
  S:=SciStr(V,D);
  If Length(S)<=W Then Begin GeneralStr:=S; Exit; End;
 End;
 GeneralStr:=SciStr(V,0);
End;

Function FormatTime(V: Double): String;
Var F: Double; T,H,M: LongInt; Ap: String;
Begin
 F:=V-Int(V);
 T:=Round(F*86400);
 H:=T Div 3600;
 M:=(T Mod 3600) Div 60;
 If H>=12 Then Ap:='PM' Else Ap:='AM';
 H:=H Mod 12;
 If H=0 Then H:=12;
 FormatTime:=TwoDig(H)+':'+TwoDig(M)+' '+Ap;
End;

Function FormatValue(V: Double; Fmt,Dc: Integer; W: Integer): String;
Var S: String; Y,M,D: LongInt; Neg: Boolean;
Begin
 Case Fmt Of
  FM_FIXED: S:=NumToStr(V,Dc);
  FM_SCI: S:=SciStr(V,Dc);
  FM_CURRENCY,FM_COMMA: Begin
   Neg:=V<0;
   S:=AddCommas(NumToStr(Abs(V),Dc));
   If Fmt=FM_CURRENCY Then S:='$'+S;
   If Neg Then S:='('+S+')';
  End;
  FM_PERCENT: S:=NumToStr(V*100,Dc)+'%';
  FM_PLUSMINUS: Begin
   D:=Round(V);
   If D>60 Then D:=60;
   If D<-60 Then D:=-60;
   If D>0 Then S:=RepStr('+',D)
   Else If D<0 Then S:=RepStr('-',-D)
   Else S:='.';
  End;
  FM_DATE1,FM_DATE2,FM_DATE3,FM_DATE4: Begin
   SerialToDate(Trunc(V),Y,M,D);
   If (M<1) Or (M>12) Then S:='ERR'
   Else Case Fmt Of
    FM_DATE1: S:=TwoDig(D)+'-'+MonthNames[M]+'-'+TwoDig(Y Mod 100);
    FM_DATE2: S:=TwoDig(D)+'-'+MonthNames[M];
    FM_DATE3: S:=MonthNames[M]+'-'+TwoDig(Y Mod 100);
    Else S:=TwoDig(M)+'/'+TwoDig(D)+'/'+TwoDig(Y Mod 100);
   End;
  End;
  FM_TIME1: S:=FormatTime(V);
  FM_HIDDEN: S:='';
  Else S:=GeneralStr(V,W);
 End;
 FormatValue:=S;
End;

{ ====================================================================== }
{                  LANGUE : FRANCAIS (defaut) / ANGLAIS                  }
{ ====================================================================== }

{ Choisit entre l'anglais et le francais }
Function Tx(Const En,Fr: String): String;
Begin
 If French Then Tx:=Fr Else Tx:=En;
End;

{ Traduit un texte anglais en francais (identite si LANGUAGE=EN ou inconnu) }
Function Tr(Const S: String): String;
Begin
 Tr:=S;
 If Not French Then Exit;
 If S='&File' Then Begin Tr:='&Fichier'; Exit; End;
 If S='&Edit' Then Begin Tr:='&Edition'; Exit; End;
 If S='&Worksheet' Then Begin Tr:='Fe&uille'; Exit; End;
 If S='&Range' Then Begin Tr:='&Plage'; Exit; End;
 If S='&Graph' Then Begin Tr:='&Graphique'; Exit; End;
 If S='&Data' Then Begin Tr:='&Donnees'; Exit; End;
 If S='&Style' Then Begin Tr:='&Style'; Exit; End;
 If S='&Tools' Then Begin Tr:='&Outils'; Exit; End;
 If S='Wi&ndow' Then Begin Tr:='Fene&tre'; Exit; End;
 If S='&Help' Then Begin Tr:='&Aide'; Exit; End;
 If S='&Chart' Then Begin Tr:='&Graphique'; Exit; End;
 If S='&Draw' Then Begin Tr:='&Dessin'; Exit; End;
 If S='&Layout' Then Begin Tr:='&Mise en page'; Exit; End;
 If S='Re&arrange' Then Begin Tr:='&Reorganiser'; Exit; End;
 If S='&New...|Ctrl+N' Then Begin Tr:='&Nouveau...|Ctrl+N'; Exit; End;
 If S='&Open...|Ctrl+O' Then Begin Tr:='&Ouvrir...|Ctrl+O'; Exit; End;
 If S='&Close' Then Begin Tr:='&Fermer'; Exit; End;
 If S='&Save|Ctrl+S' Then Begin Tr:='&Enregistrer|Ctrl+S'; Exit; End;
 If S='Save &As...' Then Begin Tr:='Enregistrer &sous...'; Exit; End;
 If S='&Print...|Ctrl+P' Then Begin Tr:='&Imprimer...|Ctrl+P'; Exit; End;
 If S='E&xit|Alt+F4' Then Begin Tr:='&Quitter|Alt+F4'; Exit; End;
 If S='&Undo|Ctrl+Z' Then Begin Tr:='&Annuler|Ctrl+Z'; Exit; End;
 If S='Cu&t|Ctrl+X' Then Begin Tr:='Co&uper|Ctrl+X'; Exit; End;
 If S='&Copy|Ctrl+C' Then Begin Tr:='&Copier|Ctrl+C'; Exit; End;
 If S='&Paste|Ctrl+V' Then Begin Tr:='C&oller|Ctrl+V'; Exit; End;
 If S='Paste &Special...' Then Begin Tr:='Collage &special...'; Exit; End;
 If S='Cl&ear|Del' Then Begin Tr:='E&ffacer|Suppr'; Exit; End;
 If S='Clear A&ll' Then Begin Tr:='Effacer &tout'; Exit; End;
 If S='&Find...' Then Begin Tr:='&Rechercher...'; Exit; End;
 If S='&Go To...|F5' Then Begin Tr:='A&ller a...|F5'; Exit; End;
 If S='&Insert' Then Begin Tr:='&Inserer'; Exit; End;
 If S='&Delete' Then Begin Tr:='&Supprimer'; Exit; End;
 If S='Column &Width...' Then Begin Tr:='Largeur de &colonne...'; Exit; End;
 If S='Set Row &Height...' Then Begin Tr:='&Hauteur de ligne...'; Exit; End;
 If S='&Hide...' Then Begin Tr:='Mas&quer...'; Exit; End;
 If S='&Titles...' Then Begin Tr:='&Titres...'; Exit; End;
 If S='Global &Settings' Then Begin Tr:='&Parametres globaux'; Exit; End;
 If S='&Number Format' Then Begin Tr:='&Format numerique'; Exit; End;
 If S='&Decimal Places...' Then Begin Tr:='&Decimales...'; Exit; End;
 If S='&Name' Then Begin Tr:='No&m'; Exit; End;
 If S='&Transpose...' Then Begin Tr:='&Transposer...'; Exit; End;
 If S='&Justify' Then Begin Tr:='&Justifier'; Exit; End;
 If S='&Protect' Then Begin Tr:='&Proteger'; Exit; End;
 If S='&Unprotect' Then Begin Tr:='D&eproteger'; Exit; End;
 If S='&New...' Then Begin Tr:='&Nouveau...'; Exit; End;
 If S='&View...' Then Begin Tr:='&Voir...'; Exit; End;
 If S='&Add to Sheet...' Then Begin Tr:='&Ajouter a la feuille...'; Exit; End;
 If S='&Import...' Then Begin Tr:='&Importer...'; Exit; End;
 If S='&Size...' Then Begin Tr:='&Taille...'; Exit; End;
 If S='&Refresh' Then Begin Tr:='&Reactualiser'; Exit; End;
 If S='&Go To...' Then Begin Tr:='A&ller a...'; Exit; End;
 If S='&Fill...' Then Begin Tr:='&Remplir...'; Exit; End;
 If S='&Sort...' Then Begin Tr:='&Trier...'; Exit; End;
 If S='&Query...' Then Begin Tr:='Re&quete...'; Exit; End;
 If S='&Table' Then Begin Tr:='Tabl&e'; Exit; End;
 If S='&Distribution' Then Begin Tr:='&Distribution'; Exit; End;
 If S='&Matrix' Then Begin Tr:='&Matrice'; Exit; End;
 If S='&Regression' Then Begin Tr:='Re&gression'; Exit; End;
 If S='&Parse...' Then Begin Tr:='A&nalyser...'; Exit; End;
 If S='Font && Attributes' Then Begin Tr:='&Police et attributs'; Exit; End;
 If S='Lines && Color' Then Begin Tr:='&Lignes et couleurs'; Exit; End;
 If S='&Alignment' Then Begin Tr:='&Alignement'; Exit; End;
 If S='&Row Height...' Then Begin Tr:='&Hauteur de ligne...'; Exit; End;
 If S='Named &Style...' Then Begin Tr:='Style &nomme...'; Exit; End;
 If S='&Spell Check...' Then Begin Tr:='&Orthographe...'; Exit; End;
 If S='&Recalculate|F9' Then Begin Tr:='&Recalculer|F9'; Exit; End;
 If S='Smart&Icons' Then Begin Tr:='&Icones'; Exit; End;
 If S='&Macro' Then Begin Tr:='&Macro'; Exit; End;
 If S='&User Setup...' Then Begin Tr:='&Preferences...'; Exit; End;
 If S='&Next Sheet|Ctrl+PgUp' Then Begin Tr:='Feuille &suivante|Ctrl+PgUp'; Exit; End;
 If S='&Previous Sheet|Ctrl+PgDn' Then Begin Tr:='Feuille &precedente|Ctrl+PgDn'; Exit; End;
 If S='&Gridlines' Then Begin Tr:='&Quadrillage'; Exit; End;
 If S='&Headings' Then Begin Tr:='&En-tetes'; Exit; End;
 If S='&Help Topics|F1' Then Begin Tr:='&Aide sur 1-2-3|F1'; Exit; End;
 If S='&About 1-2-3...' Then Begin Tr:='A &propos de 1-2-3...'; Exit; End;
 If S='&Row' Then Begin Tr:='&Ligne'; Exit; End;
 If S='&Column' Then Begin Tr:='&Colonne'; Exit; End;
 If S='&Sheet' Then Begin Tr:='&Feuille'; Exit; End;
 If S='Default Column &Width...' Then Begin Tr:='&Largeur de colonne par defaut...'; Exit; End;
 If S='&Automatic Recalc' Then Begin Tr:='&Recalcul automatique'; Exit; End;
 If S='&General' Then Begin Tr:='&General'; Exit; End;
 If S='&Fixed' Then Begin Tr:='&Fixe'; Exit; End;
 If S='&Scientific' Then Begin Tr:='&Scientifique'; Exit; End;
 If S='&Currency' Then Begin Tr:='&Monetaire'; Exit; End;
 If S='Co&mma (,)' Then Begin Tr:='&Virgule (,)'; Exit; End;
 If S='&Percent' Then Begin Tr:='&Pourcentage'; Exit; End;
 If S='+/-  &Bars' Then Begin Tr:='+/-  &Barres'; Exit; End;
 If S='Date D-MMM-YY' Then Begin Tr:='Date JJ-MMM-AA'; Exit; End;
 If S='Date DD-MMM' Then Begin Tr:='Date JJ-MMM'; Exit; End;
 If S='Date MMM-YY' Then Begin Tr:='Date MMM-AA'; Exit; End;
 If S='Date MM/DD/YY' Then Begin Tr:='Date MM/JJ/AA'; Exit; End;
 If S='&Time HH:MM AM/PM' Then Begin Tr:='He&ure HH:MM AM/PM'; Exit; End;
 If S='T&ext (formulas)' Then Begin Tr:='T&exte (formules)'; Exit; End;
 If S='&Hidden' Then Begin Tr:='&Cache'; Exit; End;
 If S='&Create...' Then Begin Tr:='&Creer...'; Exit; End;
 If S='&Reset (delete all)' Then Begin Tr:='&Tout supprimer'; Exit; End;
 If S='&Use...' Then Begin Tr:='&Utiliser...'; Exit; End;
 If S='&Bold|Ctrl+B' Then Begin Tr:='&Gras|Ctrl+B'; Exit; End;
 If S='&Italic|Ctrl+I' Then Begin Tr:='&Italique|Ctrl+I'; Exit; End;
 If S='&Underline|Ctrl+U' Then Begin Tr:='&Souligne|Ctrl+U'; Exit; End;
 If S='&Normal' Then Begin Tr:='&Normal'; Exit; End;
 If S='&Text Color...' Then Begin Tr:='Couleur du &texte...'; Exit; End;
 If S='&Background Color...' Then Begin Tr:='Couleur de &fond...'; Exit; End;
 If S='&Border...' Then Begin Tr:='&Bordure...'; Exit; End;
 If S='&Left' Then Begin Tr:='Ga&uche'; Exit; End;
 If S='&Center' Then Begin Tr:='&Centre'; Exit; End;
 If S='&Right' Then Begin Tr:='&Droite'; Exit; End;
 If S='&Undo' Then Begin Tr:='&Annuler'; Exit; End;
 If S='Cu&t' Then Begin Tr:='Co&uper'; Exit; End;
 If S='&Copy' Then Begin Tr:='&Copier'; Exit; End;
 If S='&Paste' Then Begin Tr:='C&oller'; Exit; End;
 If S='Cl&ear Object|Del' Then Begin Tr:='E&ffacer objet|Suppr'; Exit; End;
 If S='Clear &All Objects' Then Begin Tr:='Effacer &tous les objets'; Exit; End;
 If S='&Print...' Then Begin Tr:='&Imprimer...'; Exit; End;
 If S='&Type' Then Begin Tr:='&Type'; Exit; End;
 If S='&3D View' Then Begin Tr:='Vue &3D'; Exit; End;
 If S='&Ranges...' Then Begin Tr:='&Plages...'; Exit; End;
 If S='&Headings...' Then Begin Tr:='T&itres...'; Exit; End;
 If S='Legend &Text...' Then Begin Tr:='Texte de &legende...'; Exit; End;
 If S='&Axis Scale...' Then Begin Tr:='&Echelle des axes...'; Exit; End;
 If S='&Name...' Then Begin Tr:='&Nom...'; Exit; End;
 If S='&Select' Then Begin Tr:='&Selection'; Exit; End;
 If S='&Line' Then Begin Tr:='&Ligne'; Exit; End;
 If S='&Arrow' Then Begin Tr:='&Fleche'; Exit; End;
 If S='&Rectangle' Then Begin Tr:='&Rectangle'; Exit; End;
 If S='&Ellipse' Then Begin Tr:='&Ellipse'; Exit; End;
 If S='&Text...' Then Begin Tr:='&Texte...'; Exit; End;
 If S='&Legend' Then Begin Tr:='&Legende'; Exit; End;
 If S='&Frame' Then Begin Tr:='&Cadre'; Exit; End;
 If S='&Grid' Then Begin Tr:='&Quadrillage'; Exit; End;
 If S='&Markers' Then Begin Tr:='&Marqueurs'; Exit; End;
 If S='&Flip Series Order' Then Begin Tr:='&Inverser lordre des series'; Exit; End;
 If S='3D Depth &Larger' Then Begin Tr:='Profondeur 3D &plus grande'; Exit; End;
 If S='3D Depth &Smaller' Then Begin Tr:='Profondeur 3D plus p&etite'; Exit; End;
 If S='&Series Colors' Then Begin Tr:='&Couleurs des series'; Exit; End;
 If S='&Refresh Data' Then Begin Tr:='&Actualiser les donnees'; Exit; End;
 If S='Return to &Worksheet' Then Begin Tr:='&Retour a la feuille'; Exit; End;
 If S='&Bar' Then Begin Tr:='&Barres'; Exit; End;
 If S='&Stacked Bar' Then Begin Tr:='Barres &empilees'; Exit; End;
 If S='&Horizontal Bar' Then Begin Tr:='Barres &horizontales'; Exit; End;
 If S='&Area' Then Begin Tr:='&Aires'; Exit; End;
 If S='&Pie' Then Begin Tr:='&Secteurs'; Exit; End;
 If S='&XY' Then Begin Tr:='&XY'; Exit; End;
 If S='&None' Then Begin Tr:='&Aucun'; Exit; End;
 If S='&Horizontal' Then Begin Tr:='&Horizontal'; Exit; End;
 If S='&Vertical' Then Begin Tr:='&Vertical'; Exit; End;
 If S='&Both' Then Begin Tr:='&Les deux'; Exit; End;
 If S='Series &1...' Then Begin Tr:='Serie &1...'; Exit; End;
 If S='Series &2...' Then Begin Tr:='Serie &2...'; Exit; End;
 If S='Series &3...' Then Begin Tr:='Serie &3...'; Exit; End;
 If S='Series &4...' Then Begin Tr:='Serie &4...'; Exit; End;
 If S='Series &5...' Then Begin Tr:='Serie &5...'; Exit; End;
 If S='Series &6...' Then Begin Tr:='Serie &6...'; Exit; End;
 If S='Create a new worksheet file' Then Begin Tr:='Cree un nouveau fichier de feuille de calcul'; Exit; End;
 If S='Open an existing file' Then Begin Tr:='Ouvre un fichier existant'; Exit; End;
 If S='Save the current file' Then Begin Tr:='Enregistre le fichier courant'; Exit; End;
 If S='Save the current file under a new name' Then Begin Tr:='Enregistre le fichier courant sous un nouveau nom'; Exit; End;
 If S='Print the worksheet to a text file' Then Begin Tr:='Imprime la feuille dans un fichier texte'; Exit; End;
 If S='Exit 1-2-3' Then Begin Tr:='Quitte 1-2-3'; Exit; End;
 If S='Undo the last change' Then Begin Tr:='Annule la derniere modification'; Exit; End;
 If S='Move the selected range to the clipboard' Then Begin Tr:='Deplace la plage selectionnee vers le presse-papiers'; Exit; End;
 If S='Copy the selected range to the clipboard' Then Begin Tr:='Copie la plage selectionnee dans le presse-papiers'; Exit; End;
 If S='Paste the clipboard contents at the cell pointer' Then Begin Tr:='Colle le contenu du presse-papiers a la cellule courante'; Exit; End;
 If S='Erase the contents of the selected range' Then Begin Tr:='Efface le contenu de la plage selectionnee'; Exit; End;
 If S='Erase contents and styles of the selected range' Then Begin Tr:='Efface le contenu et les styles de la plage selectionnee'; Exit; End;
 If S='Find text in the worksheet' Then Begin Tr:='Recherche du texte dans la feuille'; Exit; End;
 If S='Move the cell pointer to a cell address or range name' Then Begin Tr:='Deplace le curseur vers une adresse ou un nom de plage'; Exit; End;
 If S='Insert rows above the selected range' Then Begin Tr:='Insere des lignes au-dessus de la plage selectionnee'; Exit; End;
 If S='Insert columns left of the selected range' Then Begin Tr:='Insere des colonnes a gauche de la plage selectionnee'; Exit; End;
 If S='Delete the rows of the selected range' Then Begin Tr:='Supprime les lignes de la plage selectionnee'; Exit; End;
 If S='Delete the columns of the selected range' Then Begin Tr:='Supprime les colonnes de la plage selectionnee'; Exit; End;
 If S='Change the width of the selected columns' Then Begin Tr:='Modifie la largeur des colonnes selectionnees'; Exit; End;
 If S='Change the height of the selected rows' Then Begin Tr:='Modifie la hauteur des lignes selectionnees'; Exit; End;
 If S='Set the default column width' Then Begin Tr:='Definit la largeur de colonne par defaut'; Exit; End;
 If S='Recalculate formulas automatically' Then Begin Tr:='Recalcule les formules automatiquement'; Exit; End;
 If S='Show or hide the worksheet gridlines' Then Begin Tr:='Affiche ou masque le quadrillage de la feuille'; Exit; End;
 If S='Show or hide the row and column headings' Then Begin Tr:='Affiche ou masque les en-tetes de lignes et colonnes'; Exit; End;
 If S='Set the number of decimal places' Then Begin Tr:='Definit le nombre de decimales'; Exit; End;
 If S='Assign a name to the selected range' Then Begin Tr:='Attribue un nom a la plage selectionnee'; Exit; End;
 If S='Delete a range name' Then Begin Tr:='Supprime un nom de plage'; Exit; End;
 If S='Delete all range names' Then Begin Tr:='Supprime tous les noms de plages'; Exit; End;
 If S='Copy the range, swapping rows and columns' Then Begin Tr:='Copie la plage en echangeant lignes et colonnes'; Exit; End;
 If S='Create and name a graph based on data in the current worksheet' Then Begin Tr:='Cree et nomme un graphique a partir des donnees de la feuille courante'; Exit; End;
 If S='Display a named graph' Then Begin Tr:='Affiche un graphique nomme'; Exit; End;
 If S='Place a named graph in the worksheet' Then Begin Tr:='Place un graphique nomme dans la feuille'; Exit; End;
 If S='Make a named graph current' Then Begin Tr:='Rend un graphique nomme courant'; Exit; End;
 If S='Name the current graph' Then Begin Tr:='Nomme le graphique courant'; Exit; End;
 If S='Delete a named graph' Then Begin Tr:='Supprime un graphique nomme'; Exit; End;
 If S='Redraw graphs with the latest worksheet data' Then Begin Tr:='Redessine les graphiques avec les donnees a jour'; Exit; End;
 If S='Move to a graph placed in the worksheet' Then Begin Tr:='Se deplace vers un graphique place dans la feuille'; Exit; End;
 If S='Fill the selected range with a series of numbers' Then Begin Tr:='Remplit la plage selectionnee avec une serie de nombres'; Exit; End;
 If S='Sort the selected range' Then Begin Tr:='Trie la plage selectionnee'; Exit; End;
 If S='Make the selected text bold' Then Begin Tr:='Met le texte selectionne en gras'; Exit; End;
 If S='Make the selected text italic' Then Begin Tr:='Met le texte selectionne en italique'; Exit; End;
 If S='Underline the selected text' Then Begin Tr:='Souligne le texte selectionne'; Exit; End;
 If S='Remove all text attributes' Then Begin Tr:='Supprime tous les attributs de texte'; Exit; End;
 If S='Change the text color of the selected range' Then Begin Tr:='Change la couleur du texte de la plage selectionnee'; Exit; End;
 If S='Change the background color of the selected range' Then Begin Tr:='Change la couleur de fond de la plage selectionnee'; Exit; End;
 If S='Use the default alignment' Then Begin Tr:='Utilise lalignement par defaut'; Exit; End;
 If S='Align contents to the left' Then Begin Tr:='Aligne le contenu a gauche'; Exit; End;
 If S='Center the contents' Then Begin Tr:='Centre le contenu'; Exit; End;
 If S='Align contents to the right' Then Begin Tr:='Aligne le contenu a droite'; Exit; End;
 If S='Recalculate all formulas' Then Begin Tr:='Recalcule toutes les formules'; Exit; End;
 If S='Show or hide the SmartIcons palette' Then Begin Tr:='Affiche ou masque la palette dicones'; Exit; End;
 If S='Move to the next worksheet' Then Begin Tr:='Passe a la feuille suivante'; Exit; End;
 If S='Move to the previous worksheet' Then Begin Tr:='Passe a la feuille precedente'; Exit; End;
 If S='Display help on using 1-2-3' Then Begin Tr:='Affiche laide sur 1-2-3'; Exit; End;
 If S='Display program information' Then Begin Tr:='Affiche les informations sur le programme'; Exit; End;
 If S='Sum the cells above or to the left' Then Begin Tr:='Additionne les cellules au-dessus ou a gauche'; Exit; End;
 If S='Create a chart from the selected range' Then Begin Tr:='Cree un graphique a partir de la plage selectionnee'; Exit; End;
 If S='Return to the worksheet' Then Begin Tr:='Retourne a la feuille de calcul'; Exit; End;
 If S='Remove the last drawn object' Then Begin Tr:='Supprime le dernier objet dessine'; Exit; End;
 If S='Delete the last drawn object' Then Begin Tr:='Supprime le dernier objet dessine'; Exit; End;
 If S='Delete all drawn objects' Then Begin Tr:='Supprime tous les objets dessines'; Exit; End;
 If S='Switch between 2D and 3D display' Then Begin Tr:='Bascule entre laffichage 2D et 3D'; Exit; End;
 If S='Specify the worksheet ranges the graph uses' Then Begin Tr:='Indique les plages de la feuille utilisees par le graphique'; Exit; End;
 If S='Enter the titles of the graph' Then Begin Tr:='Saisit les titres du graphique'; Exit; End;
 If S='Show or hide the legend' Then Begin Tr:='Affiche ou masque la legende'; Exit; End;
 If S='Enter the legend text for each data series' Then Begin Tr:='Saisit le texte de la legende de chaque serie'; Exit; End;
 If S='Show or hide the frame around the graph' Then Begin Tr:='Affiche ou masque le cadre du graphique'; Exit; End;
 If S='Set the scale of the Y axis' Then Begin Tr:='Definit lechelle de laxe Y'; Exit; End;
 If S='Show or hide markers on line graphs' Then Begin Tr:='Affiche ou masque les marqueurs des graphiques en ligne'; Exit; End;
 If S='Reverse the order of the data series' Then Begin Tr:='Inverse lordre des series de donnees'; Exit; End;
 If S='Change the background color of the graph' Then Begin Tr:='Change la couleur de fond du graphique'; Exit; End;
 If S='Redraw the graph with current data' Then Begin Tr:='Redessine le graphique avec les donnees courantes'; Exit; End;
 If S='Choose a drawing tool for the graph' Then Begin Tr:='Choisit un outil de dessin pour le graphique'; Exit; End;
 If S='Set the number format of the selected range' Then Begin Tr:='Definit le format numerique de la plage selectionnee'; Exit; End;
 If S='Change the type of the graph' Then Begin Tr:='Change le type du graphique'; Exit; End;
 If S='READY' Then Begin Tr:='PRET'; Exit; End;
 If S='LABEL' Then Begin Tr:='ETIQ'; Exit; End;
 If S='VALUE' Then Begin Tr:='VALEUR'; Exit; End;
 If S='ERROR' Then Begin Tr:='ERREUR'; Exit; End;
 If S='Over' Then Begin Tr:='Ecras'; Exit; End;
 If S='Calc' Then Begin Tr:='Calc'; Exit; End;
 If S='End' Then Begin Tr:='Fin'; Exit; End;
 If S='Saved' Then Begin Tr:='Enregistre'; Exit; End;
 If S='Invalid formula' Then Begin Tr:='Formule invalide'; Exit; End;
 If S='Untitled' Then Begin Tr:='Sans titre'; Exit; End;
 If S='(No data to graph)' Then Begin Tr:='(Aucune donnee a representer)'; Exit; End;
 If S='OK' Then Begin Tr:='OK'; Exit; End;
 If S='Cancel' Then Begin Tr:='Annuler'; Exit; End;
 If S='Yes' Then Begin Tr:='Oui'; Exit; End;
 If S='No' Then Begin Tr:='Non'; Exit; End;
 If S='Default' Then Begin Tr:='Defaut'; Exit; End;
 If S='Open File' Then Begin Tr:='Ouvrir un fichier'; Exit; End;
 If S='Save As' Then Begin Tr:='Enregistrer sous'; Exit; End;
 If S='About 1-2-3' Then Begin Tr:='A propos de 1-2-3'; Exit; End;
 If S='Sort' Then Begin Tr:='Trier'; Exit; End;
 If S='Data Fill' Then Begin Tr:='Remplissage de donnees'; Exit; End;
 If S='1-2-3 Help' Then Begin Tr:='Aide de 1-2-3'; Exit; End;
 If S='Chart Ranges' Then Begin Tr:='Plages du graphique'; Exit; End;
 If S='Chart Headings' Then Begin Tr:='Titres du graphique'; Exit; End;
 If S='Legend Text' Then Begin Tr:='Texte de la legende'; Exit; End;
 If S='Axis Scale (blank = automatic)' Then Begin Tr:='Echelle des axes (vide = automatique)'; Exit; End;
 If S='Go To' Then Begin Tr:='Aller a'; Exit; End;
 If S='Find' Then Begin Tr:='Rechercher'; Exit; End;
 If S='SUM' Then Begin Tr:='SOMME'; Exit; End;
 If S='Graph' Then Begin Tr:='Graphique'; Exit; End;
 If S='Print' Then Begin Tr:='Imprimer'; Exit; End;
 If S='Range Name Create' Then Begin Tr:='Creer un nom de plage'; Exit; End;
 If S='Range Name' Then Begin Tr:='Nom de plage'; Exit; End;
 If S='Delete Range Name' Then Begin Tr:='Supprimer un nom de plage'; Exit; End;
 If S='Transpose' Then Begin Tr:='Transposer'; Exit; End;
 If S='Column Width' Then Begin Tr:='Largeur de colonne'; Exit; End;
 If S='Row Height' Then Begin Tr:='Hauteur de ligne'; Exit; End;
 If S='Default Column Width' Then Begin Tr:='Largeur de colonne par defaut'; Exit; End;
 If S='Text Color' Then Begin Tr:='Couleur du texte'; Exit; End;
 If S='Background Color' Then Begin Tr:='Couleur de fond'; Exit; End;
 If S='Decimal Places' Then Begin Tr:='Decimales'; Exit; End;
 If S='Graph New' Then Begin Tr:='Nouveau graphique'; Exit; End;
 If S='Graph View' Then Begin Tr:='Afficher un graphique'; Exit; End;
 If S='Graph Name Use' Then Begin Tr:='Utiliser un graphique'; Exit; End;
 If S='Add Graph to Sheet' Then Begin Tr:='Ajouter un graphique a la feuille'; Exit; End;
 If S='Graph Name' Then Begin Tr:='Nom du graphique'; Exit; End;
 If S='Graph Name Create' Then Begin Tr:='Nommer le graphique'; Exit; End;
 If S='Graph Name Delete' Then Begin Tr:='Supprimer un graphique'; Exit; End;
 If S='Graph Go To' Then Begin Tr:='Aller au graphique'; Exit; End;
 If S='Draw' Then Begin Tr:='Dessin'; Exit; End;
 If S='Draw Text' Then Begin Tr:='Texte du dessin'; Exit; End;
 If S='Save' Then Begin Tr:='Enregistrer'; Exit; End;
 If S='Cut' Then Begin Tr:='Couper'; Exit; End;
 If S='Copy' Then Begin Tr:='Copier'; Exit; End;
 If S='File name:' Then Begin Tr:='Nom du fichier :'; Exit; End;
 If S='Types: *.WKC (1-2-3 clone)  *.WK1' Then Begin Tr:='Types : *.WKC (clone 1-2-3)  *.WK1'; Exit; End;
 If S='Spreadsheet for Windows' Then Begin Tr:='Tableur pour Windows'; Exit; End;
 If S='Clone' Then Begin Tr:='Clone'; Exit; End;
 If S='Clone of the Lotus 1-2-3 spreadsheet' Then Begin Tr:='Clone du tableur Lotus 1-2-3'; Exit; End;
 If S='Target: Turbo Pascal 7 / Free Pascal' Then Begin Tr:='Cible : Turbo Pascal 7 / Free Pascal'; Exit; End;
 If S='8 sheets, 256 columns, 8192 rows' Then Begin Tr:='8 feuilles, 256 colonnes, 8192 lignes'; Exit; End;
 If S='There are no named graphs.' Then Begin Tr:='Il ny a aucun graphique nomme.'; Exit; End;
 If S='Invalid cell or range address.' Then Begin Tr:='Adresse de cellule ou de plage invalide.'; Exit; End;
 If S='Find text:' Then Begin Tr:='Texte a rechercher :'; Exit; End;
 If S='Text not found.' Then Begin Tr:='Texte introuvable.'; Exit; End;
 If S='No numbers found above or to the left.' Then Begin Tr:='Aucun nombre trouve au-dessus ou a gauche.'; Exit; End;
 If S='Select the range to sort first.' Then Begin Tr:='Selectionnez dabord la plage a trier.'; Exit; End;
 If S='Sort key column:' Then Begin Tr:='Colonne cle du tri :'; Exit; End;
 If S='Order (A/D):' Then Begin Tr:='Ordre (C/D) :'; Exit; End;
 If S='The key column must be inside the selected range.' Then Begin Tr:='La colonne cle doit etre dans la plage selectionnee.'; Exit; End;
 If S='Start:' Then Begin Tr:='Debut :'; Exit; End;
 If S='Step:' Then Begin Tr:='Pas :'; Exit; End;
 If S='Stop:' Then Begin Tr:='Fin :'; Exit; End;
 If S='Please enter numbers.' Then Begin Tr:='Veuillez saisir des nombres.'; Exit; End;
 If S='Too many graphs placed in the worksheet.' Then Begin Tr:='Trop de graphiques places dans la feuille.'; Exit; End;
 If S='Too many named graphs.' Then Begin Tr:='Trop de graphiques nommes.'; Exit; End;
 If S='X range:' Then Begin Tr:='Plage X :'; Exit; End;
 If S='One of the ranges is invalid.' Then Begin Tr:='Une des plages est invalide.'; Exit; End;
 If S='Title:' Then Begin Tr:='Titre :'; Exit; End;
 If S='Subtitle:' Then Begin Tr:='Sous-titre :'; Exit; End;
 If S='X axis title:' Then Begin Tr:='Titre de laxe X :'; Exit; End;
 If S='Y axis title:' Then Begin Tr:='Titre de laxe Y :'; Exit; End;
 If S='Y minimum:' Then Begin Tr:='Minimum Y :'; Exit; End;
 If S='Y maximum:' Then Begin Tr:='Maximum Y :'; Exit; End;
 If S='Enter two numbers with maximum > minimum.' Then Begin Tr:='Saisissez deux nombres avec maximum > minimum.'; Exit; End;
 If S='Save changes to the current file?' Then Begin Tr:='Enregistrer les modifications du fichier courant ?'; Exit; End;
 If S='Print the range to this text file:' Then Begin Tr:='Imprimer la plage dans ce fichier texte :'; Exit; End;
 If S='Name for the selected range:' Then Begin Tr:='Nom de la plage selectionnee :'; Exit; End;
 If S='Invalid name.' Then Begin Tr:='Nom invalide.'; Exit; End;
 If S='Too many names.' Then Begin Tr:='Trop de noms.'; Exit; End;
 If S='There are no range names.' Then Begin Tr:='Il ny a aucun nom de plage.'; Exit; End;
 If S='Copy the range transposed to (top-left cell):' Then Begin Tr:='Copier la plage transposee vers (cellule en haut a gauche) :'; Exit; End;
 If S='Invalid cell address.' Then Begin Tr:='Adresse de cellule invalide.'; Exit; End;
 If S='The range is too large for the clipboard.' Then Begin Tr:='La plage est trop grande pour le presse-papiers.'; Exit; End;
 If S='Enter a cell address or range name:' Then Begin Tr:='Saisissez une adresse de cellule ou un nom de plage :'; Exit; End;
 If S='Name for the new graph:' Then Begin Tr:='Nom du nouveau graphique :'; Exit; End;
 If S='That name is empty or already used.' Then Begin Tr:='Ce nom est vide ou deja utilise.'; Exit; End;
 If S='There is no current graph.' Then Begin Tr:='Il ny a pas de graphique courant.'; Exit; End;
 If S='Name for the current graph:' Then Begin Tr:='Nom du graphique courant :'; Exit; End;
 If S='No graph is placed in the worksheet.' Then Begin Tr:='Aucun graphique nest place dans la feuille.'; Exit; End;
 If S='Too many objects on this graph.' Then Begin Tr:='Trop dobjets sur ce graphique.'; Exit; End;
 If S='Text to place on the graph:' Then Begin Tr:='Texte a placer sur le graphique :'; Exit; End;
 If S='Width (characters, 1-240):' Then Begin Tr:='Largeur (caracteres, 1-240) :'; Exit; End;
 If S='Height (pixels, 10-120):' Then Begin Tr:='Hauteur (pixels, 10-120) :'; Exit; End;
 If S='Number of decimal places (0-15):' Then Begin Tr:='Nombre de decimales (0-15) :'; Exit; End;
 If S='(not a 1-2-3 clone or WK1 file)' Then Begin Tr:='(ce nest pas un fichier clone 1-2-3 ni WK1)'; Exit; End;
 If S='&Worksheet window' Then Begin Tr:='&Fenetre de la feuille'; Exit; End;
End;
{ ====================================================================== }
{                  NOMS DE PLAGES ET VALEURS                             }
{ ====================================================================== }

Function FindName(Const N: String): Integer;
Var I: Integer; U: String;
Begin
 FindName:=0;
 U:=UpStr(N);
 For I:=1 To NameCount Do
  If UpStr(Names[I].Name)=U Then Begin FindName:=I; Exit; End;
End;

Function ErrVal(C: Integer): TVal;
Var V: TVal;
Begin
 V.K:=2; V.N:=C; V.S:='';
 ErrVal:=V;
End;

Function NumVal(X: Double): TVal;
Var V: TVal;
Begin
 V.K:=0; V.N:=X; V.S:='';
 NumVal:=V;
End;

Function StrVal(Const S: String): TVal;
Var V: TVal;
Begin
 V.K:=1; V.N:=0; V.S:=Copy(S,1,80);
 StrVal:=V;
End;

{ Convertit une valeur en nombre. Faux si texte ou erreur. }
Function ToNum(Const V: TVal; Var X: Double): Boolean;
Begin
 ToNum:=True;
 X:=0;
 Case V.K Of
  0: X:=V.N;
  3: X:=0;
  Else ToNum:=False;
 End;
End;

Function ValToStr(Const V: TVal): String;
Begin
 Case V.K Of
  0: ValToStr:=GeneralStr(V.N,15);
  1,3: ValToStr:=V.S;
  Else ValToStr:='ERR';
 End;
End;

{ ====================================================================== }
{                  ANALYSE LEXICALE DES REFERENCES                       }
{ ====================================================================== }

Procedure SkipSp;
Begin
 While (FPos<=Length(FSrc)) And (FSrc[FPos]=' ') Do Inc(FPos);
End;

Function PeekCh: Char;
Begin
 SkipSp;
 If FPos<=Length(FSrc) Then PeekCh:=FSrc[FPos] Else PeekCh:=#0;
End;

Function TryCellRef(Var Sh,R,C: Integer; Var AbsR,AbsC: Boolean): Boolean;
Var Save,Cn,Rn,NL: Integer; L1,L2: Char; Digits: String; Code: Integer;
Begin
 TryCellRef:=False;
 Save:=FPos;
 Sh:=FSheet;
 If (FPos+2<=Length(FSrc)) And IsLetter(FSrc[FPos]) And (FSrc[FPos+1]=':') And
    (IsLetter(FSrc[FPos+2]) Or (FSrc[FPos+2]='$')) Then Begin
  Sh:=Ord(UpCase(FSrc[FPos]))-64;
  If (Sh<1) Or (Sh>MAX_SHEETS) Then Begin FPos:=Save; Exit; End;
  Inc(FPos,2);
 End;
 AbsC:=False; AbsR:=False;
 If (FPos<=Length(FSrc)) And (FSrc[FPos]='$') Then Begin AbsC:=True; Inc(FPos); End;
 NL:=0; L1:=' '; L2:=' ';
 While (FPos<=Length(FSrc)) And IsLetter(FSrc[FPos]) And (NL<3) Do Begin
  If NL=0 Then L1:=UpCase(FSrc[FPos]) Else L2:=UpCase(FSrc[FPos]);
  Inc(NL); Inc(FPos);
 End;
 If (NL<1) Or (NL>2) Then Begin FPos:=Save; Exit; End;
 If (FPos<=Length(FSrc)) And (FSrc[FPos]='$') Then Begin AbsR:=True; Inc(FPos); End;
 Digits:='';
 While (FPos<=Length(FSrc)) And IsDigit(FSrc[FPos]) And (Length(Digits)<5) Do Begin
  Digits:=Digits+FSrc[FPos]; Inc(FPos);
 End;
 If Digits='' Then Begin FPos:=Save; Exit; End;
 If (FPos<=Length(FSrc)) And (IsLetter(FSrc[FPos]) Or IsDigit(FSrc[FPos]) Or (FSrc[FPos]='_')
    Or (FSrc[FPos]='(')) Then Begin FPos:=Save; Exit; End;
 If NL=1 Then Cn:=Ord(L1)-65 Else Cn:=(Ord(L1)-64)*26+(Ord(L2)-65);
 Val(Digits,Rn,Code);
 If (Cn<0) Or (Cn>=MAX_COLS) Or (Rn<1) Or (Rn>MAX_ROWS) Then Begin FPos:=Save; Exit; End;
 C:=Cn; R:=Rn-1;
 TryCellRef:=True;
End;

Function TryIdent(Var Id: String): Boolean;
Begin
 Id:='';
 TryIdent:=False;
 If (FPos>Length(FSrc)) Or Not (IsLetter(FSrc[FPos]) Or (FSrc[FPos]='_')) Then Exit;
 While (FPos<=Length(FSrc)) And (IsLetter(FSrc[FPos]) Or IsDigit(FSrc[FPos]) Or (FSrc[FPos]='_')) Do Begin
  Id:=Id+FSrc[FPos];
  Inc(FPos);
 End;
 TryIdent:=True;
End;

Function TryRange(Var Sh,R1,C1,R2,C2: Integer): Boolean;
Var S2,R,C,N: Integer; A1,A2: Boolean; Save: Integer; Id: String; T: Integer;
Begin
 TryRange:=False;
 SkipSp;
 Save:=FPos;
 If TryCellRef(Sh,R1,C1,A1,A2) Then Begin
  R2:=R1; C2:=C1;
  If (FPos<=Length(FSrc)) And ((FSrc[FPos]='.') Or (FSrc[FPos]=':')) Then Begin
   N:=FPos;
   If FSrc[FPos]='.' Then Begin
    Inc(FPos);
    If (FPos<=Length(FSrc)) And (FSrc[FPos]='.') Then Inc(FPos);
   End Else Inc(FPos);
   If Not TryCellRef(S2,R,C,A1,A2) Then FPos:=N
   Else Begin R2:=R; C2:=C; End;
  End;
 End Else Begin
  FPos:=Save;
  If TryIdent(Id) Then Begin
   N:=FindName(Id);
   If (N=0) Or ((FPos<=Length(FSrc)) And (FSrc[FPos]='(')) Then Begin FPos:=Save; Exit; End;
   Sh:=Names[N].Sheet; R1:=Names[N].R1; C1:=Names[N].C1;
   R2:=Names[N].R2; C2:=Names[N].C2;
  End Else Begin FPos:=Save; Exit; End;
 End;
 If R1>R2 Then Begin T:=R1; R1:=R2; R2:=T; End;
 If C1>C2 Then Begin T:=C1; C1:=C2; C2:=T; End;
 TryRange:=True;
End;

{ Analyse un texte de plage ("A:B2..B9", nom...) }
Function ParseRangeText(Const S: String; Var Sh,R1,C1,R2,C2: Integer): Boolean;
Var SSrc: String; SPos,SSh: Integer; Ok: Boolean;
Begin
 SSrc:=FSrc; SPos:=FPos; SSh:=FSheet;
 FSrc:=TrimStr(S); FPos:=1; FSheet:=ActSheet;
 Ok:=TryRange(Sh,R1,C1,R2,C2);
 If Ok Then Begin
  SkipSp;
  If FPos<=Length(FSrc) Then Ok:=False;
 End;
 FSrc:=SSrc; FPos:=SPos; FSheet:=SSh;
 ParseRangeText:=Ok;
End;

Function RangeText(Sh,R1,C1,R2,C2: Integer): String;
Var S: String;
Begin
 S:=SheetLetter(Sh)+':'+CellName(R1,C1);
 If (R1<>R2) Or (C1<>C2) Then S:=S+'..'+CellName(R2,C2);
 RangeText:=S;
End;

{ ====================================================================== }
{                  EVALUATION DES FORMULES                               }
{ ====================================================================== }

Var
 DepthHit : Boolean;

Function PLogic: TVal; Forward;

Procedure EvalCell(ShI,R,C: Integer; P: PCell); Forward;

Function CellVal(ShI,R,C: Integer): TVal;
Var P: PCell; V: TVal; Sh: PSheet;
Begin
 V.K:=0; V.N:=0; V.S:='';
 CellVal:=V;
 Sh:=Sheets[ShI];
 P:=CellAt(Sh,R,C);
 If P=Nil Then Exit;
 Case P^.Kind Of
  CK_VALUE: V.N:=P^.Num;
  CK_LABEL: Begin V.K:=3; V.S:=Copy(PStrVal(P^.Txt),1,80); End;
  CK_FORMULA: Begin
   If P^.Busy Then Begin CircFound:=True; CellVal:=ErrVal(E_CIRC); Exit; End;
   If P^.Stamp<>CalcStamp Then EvalCell(ShI,R,C,P);
   If P^.Stamp<>CalcStamp Then Begin CellVal:=ErrVal(E_ERR); Exit; End;
   If P^.Err<>0 Then Begin CellVal:=ErrVal(P^.Err); Exit; End;
   If P^.IsStr Then Begin V.K:=3; V.S:=Copy(PStrVal(P^.Res),1,80); End
               Else V.N:=P^.Num;
  End;
 End;
 CellVal:=V;
End;

Function ToStrArg(Const V: TVal): String;
Begin
 ToStrArg:=ValToStr(V);
End;

Function PNumber: TVal;
Var S: String; X: Double; Code: Integer;
Begin
 S:='';
 While (FPos<=Length(FSrc)) And (IsDigit(FSrc[FPos]) Or (FSrc[FPos]='.')) Do Begin
  If (FSrc[FPos]='.') And (FPos<Length(FSrc)) And (FSrc[FPos+1]='.') Then Break;
  S:=S+FSrc[FPos];
  Inc(FPos);
 End;
 If (FPos<=Length(FSrc)) And (UpCase(FSrc[FPos])='E') Then Begin
  If (FPos<Length(FSrc)) And (IsDigit(FSrc[FPos+1]) Or
     ((FSrc[FPos+1] In ['+','-']) And (FPos+1<Length(FSrc)) And IsDigit(FSrc[FPos+2]))) Then Begin
   S:=S+'E'; Inc(FPos);
   If FSrc[FPos] In ['+','-'] Then Begin S:=S+FSrc[FPos]; Inc(FPos); End;
   While (FPos<=Length(FSrc)) And IsDigit(FSrc[FPos]) Do Begin S:=S+FSrc[FPos]; Inc(FPos); End;
  End;
 End;
 If S[1]='.' Then S:='0'+S;
 If S[Length(S)]='.' Then Delete(S,Length(S),1);
 Val(S,X,Code);
 If Code<>0 Then Begin ParseFail:=True; PNumber:=ErrVal(E_ERR); Exit; End;
 PNumber:=NumVal(X);
End;

Function PStringLit: TVal;
Var Q: Char; S: String;
Begin
 Q:=FSrc[FPos];
 Inc(FPos);
 S:='';
 While (FPos<=Length(FSrc)) And (FSrc[FPos]<>Q) Do Begin
  S:=S+FSrc[FPos];
  Inc(FPos);
 End;
 If FPos>Length(FSrc) Then ParseFail:=True Else Inc(FPos);
 PStringLit:=StrVal(S);
End;

{ --- Agregats --- }
Type
 TAgg = Record
  Sum, SumSq, Mn, Mx: Double;
  Cnt, NCnt: LongInt;
  Err: Integer;
 End;

Procedure AggInit(Var A: TAgg);
Begin
 A.Sum:=0; A.SumSq:=0; A.Mn:=0; A.Mx:=0; A.Cnt:=0; A.NCnt:=0; A.Err:=0;
End;

Procedure AggNum(Var A: TAgg; X: Double);
Begin
 If A.NCnt=0 Then Begin A.Mn:=X; A.Mx:=X; End
 Else Begin
  If X<A.Mn Then A.Mn:=X;
  If X>A.Mx Then A.Mx:=X;
 End;
 A.Sum:=A.Sum+X;
 A.SumSq:=A.SumSq+X*X;
 Inc(A.NCnt);
 Inc(A.Cnt);
End;

Procedure AggRange(Var A: TAgg; ShI,R1,C1,R2,C2: Integer);
Var R,C,CE: Integer; P: PCell; V: TVal; Sh: PSheet;
Begin
 Sh:=Sheets[ShI];
 If Sh=Nil Then Exit;
 If R2>Sh^.MaxR Then R2:=Sh^.MaxR;
 CE:=C2;
 If CE>Sh^.MaxC Then CE:=Sh^.MaxC;
 For R:=R1 To R2 Do Begin
  If Sh^.Rows[R]=Nil Then Continue;
  For C:=C1 To CE Do Begin
   P:=Sh^.Rows[R]^[C];
   If (P=Nil) Or (P^.Kind=CK_EMPTY) Then Continue;
   V:=CellVal(ShI,R,C);
   If V.K=2 Then Begin If A.Err=0 Then A.Err:=Trunc(V.N); End
   Else If V.K=0 Then AggNum(A,V.N)
   Else Inc(A.Cnt);
  End;
 End;
End;

Function PAggFunc(Const Nm: String): TVal;
Var A: TAgg; Sh,R1,C1,R2,C2: Integer; V: TVal; X,M: Double; Done: Boolean; Save: Integer;
Begin
 AggInit(A);
 SkipSp;
 If (FPos>Length(FSrc)) Or (FSrc[FPos]<>'(') Then Begin ParseFail:=True; PAggFunc:=ErrVal(E_ERR); Exit; End;
 Inc(FPos);
 Done:=False;
 If PeekCh=')' Then Done:=True;
 While Not Done Do Begin
  SkipSp;
  Save:=FPos;
  If TryRange(Sh,R1,C1,R2,C2) And (PeekCh In [',',';',')']) Then
   AggRange(A,Sh,R1,C1,R2,C2)
  Else Begin
   FPos:=Save;
   V:=PLogic;
   If V.K=2 Then Begin If A.Err=0 Then A.Err:=Trunc(V.N); End
   Else If V.K=0 Then AggNum(A,V.N)
   Else If V.K=3 Then AggNum(A,0)
   Else A.Err:=E_ERR;
  End;
  SkipSp;
  If (FPos<=Length(FSrc)) And (FSrc[FPos] In [',',';']) Then Inc(FPos)
  Else Done:=True;
 End;
 SkipSp;
 If (FPos<=Length(FSrc)) And (FSrc[FPos]=')') Then Inc(FPos) Else ParseFail:=True;
 If A.Err<>0 Then Begin PAggFunc:=ErrVal(A.Err); Exit; End;
 If Nm='SUM' Then PAggFunc:=NumVal(A.Sum)
 Else If Nm='COUNT' Then PAggFunc:=NumVal(A.Cnt)
 Else If Nm='AVG' Then Begin
  If A.Cnt=0 Then PAggFunc:=ErrVal(E_NA) Else PAggFunc:=NumVal(A.Sum/A.Cnt);
 End
 Else If Nm='MIN' Then PAggFunc:=NumVal(A.Mn)
 Else If Nm='MAX' Then PAggFunc:=NumVal(A.Mx)
 Else Begin
  { STD (population) et VAR }
  If A.NCnt=0 Then Begin PAggFunc:=NumVal(0); Exit; End;
  M:=A.Sum/A.NCnt;
  X:=A.SumSq/A.NCnt-M*M;
  If X<0 Then X:=0;
  If Nm='STD' Then PAggFunc:=NumVal(Sqrt(X)) Else PAggFunc:=NumVal(X);
 End;
End;

{ --- Fonctions a recherche : VLOOKUP, HLOOKUP, NPV --- }
Function PRangeFunc(Const Nm: String): TVal;
Var Sh,R1,C1,R2,C2,Off,I,Hit: Integer; Key,Y,V,Rate,Tot: Double; KeyS: String;
    VK,Vi,Rv: TVal; IsStr,Found: Boolean; Save: Integer;
Begin
 SkipSp;
 If (FPos>Length(FSrc)) Or (FSrc[FPos]<>'(') Then Begin ParseFail:=True; PRangeFunc:=ErrVal(E_ERR); Exit; End;
 Inc(FPos);
 If Nm='NPV' Then Begin
  VK:=PLogic;
  If Not ToNum(VK,Rate) Then Begin PRangeFunc:=ErrVal(E_ERR); Exit; End;
  SkipSp; If (FPos<=Length(FSrc)) And (FSrc[FPos] In [',',';']) Then Inc(FPos) Else ParseFail:=True;
  If Not TryRange(Sh,R1,C1,R2,C2) Then Begin ParseFail:=True; PRangeFunc:=ErrVal(E_ERR); Exit; End;
  SkipSp; If (FPos<=Length(FSrc)) And (FSrc[FPos]=')') Then Inc(FPos) Else ParseFail:=True;
  Tot:=0; I:=0;
  For Hit:=R1 To R2 Do For Off:=C1 To C2 Do Begin
   Vi:=CellVal(Sh,Hit,Off);
   If Vi.K=0 Then Begin Inc(I); Tot:=Tot+Vi.N/Exp(I*Ln(1+Rate)); End;
  End;
  PRangeFunc:=NumVal(Tot);
  Exit;
 End;
 { VLOOKUP / HLOOKUP : cle, plage, decalage }
 VK:=PLogic;
 SkipSp; If (FPos<=Length(FSrc)) And (FSrc[FPos] In [',',';']) Then Inc(FPos) Else ParseFail:=True;
 If Not TryRange(Sh,R1,C1,R2,C2) Then Begin ParseFail:=True; PRangeFunc:=ErrVal(E_ERR); Exit; End;
 SkipSp; If (FPos<=Length(FSrc)) And (FSrc[FPos] In [',',';']) Then Inc(FPos) Else ParseFail:=True;
 Vi:=PLogic;
 SkipSp; If (FPos<=Length(FSrc)) And (FSrc[FPos]=')') Then Inc(FPos) Else ParseFail:=True;
 If VK.K=2 Then Begin PRangeFunc:=VK; Exit; End;
 If Not ToNum(Vi,Y) Then Begin PRangeFunc:=ErrVal(E_ERR); Exit; End;
 Off:=Trunc(Y);
 IsStr:=(VK.K=1) Or (VK.K=3);
 KeyS:=UpStr(VK.S);
 Key:=VK.N;
 Hit:=-1;
 If Nm='VLOOKUP' Then Begin
  If (Off<0) Or (C1+Off>C2) Then Begin PRangeFunc:=ErrVal(E_ERR); Exit; End;
  For I:=R1 To R2 Do Begin
   Rv:=CellVal(Sh,I,C1);
   If IsStr Then Begin
    If ((Rv.K=1) Or (Rv.K=3)) And (UpStr(Rv.S)=KeyS) Then Begin Hit:=I; Break; End;
   End Else If Rv.K=0 Then Begin
    If Rv.N<=Key Then Hit:=I Else Break;
   End;
  End;
  If Hit<0 Then PRangeFunc:=ErrVal(E_NA) Else PRangeFunc:=CellVal(Sh,Hit,C1+Off);
 End Else Begin
  If (Off<0) Or (R1+Off>R2) Then Begin PRangeFunc:=ErrVal(E_ERR); Exit; End;
  For I:=C1 To C2 Do Begin
   Rv:=CellVal(Sh,R1,I);
   If IsStr Then Begin
    If ((Rv.K=1) Or (Rv.K=3)) And (UpStr(Rv.S)=KeyS) Then Begin Hit:=I; Break; End;
   End Else If Rv.K=0 Then Begin
    If Rv.N<=Key Then Hit:=I Else Break;
   End;
  End;
  If Hit<0 Then PRangeFunc:=ErrVal(E_NA) Else PRangeFunc:=CellVal(Sh,R1+Off,Hit);
 End;
End;

Function PFunction: TVal;
Var Nm: String; A: Array[1..6] Of TVal; N,I: Integer; X,Y,Z: Double; S,T: String;
    HasParen,Done: Boolean; Yr,Mo,Dy: LongInt; Ok: Boolean; Res: TVal;
    Sh,R1,C1,R2,C2: Integer;
Begin
 Inc(FPos);   { @ }
 If Not TryIdent(Nm) Then Begin ParseFail:=True; PFunction:=ErrVal(E_ERR); Exit; End;
 Nm:=UpStr(Nm);
 If (Nm='SUM') Or (Nm='AVG') Or (Nm='MIN') Or (Nm='MAX') Or (Nm='COUNT') Or
    (Nm='STD') Or (Nm='VAR') Then Begin PFunction:=PAggFunc(Nm); Exit; End;
 If (Nm='NPV') Or (Nm='VLOOKUP') Or (Nm='HLOOKUP') Then Begin PFunction:=PRangeFunc(Nm); Exit; End;
 If (Nm='ROWS') Or (Nm='COLS') Then Begin
  SkipSp;
  If (FPos<=Length(FSrc)) And (FSrc[FPos]='(') Then Begin
   Inc(FPos);
   If TryRange(Sh,R1,C1,R2,C2) Then Begin
    SkipSp; If (FPos<=Length(FSrc)) And (FSrc[FPos]=')') Then Inc(FPos) Else ParseFail:=True;
    If Nm='ROWS' Then PFunction:=NumVal(R2-R1+1) Else PFunction:=NumVal(C2-C1+1);
    Exit;
   End;
  End;
  ParseFail:=True; PFunction:=ErrVal(E_ERR); Exit;
 End;
 { Lecture des arguments }
 N:=0;
 HasParen:=(FPos<=Length(FSrc)) And (FSrc[FPos]='(');
 If HasParen Then Begin
  Inc(FPos);
  Done:=PeekCh=')';
  While Not Done Do Begin
   If N>=6 Then Begin ParseFail:=True; Break; End;
   Inc(N);
   A[N]:=PLogic;
   SkipSp;
   If (FPos<=Length(FSrc)) And (FSrc[FPos] In [',',';']) Then Inc(FPos) Else Done:=True;
  End;
  SkipSp;
  If (FPos<=Length(FSrc)) And (FSrc[FPos]=')') Then Inc(FPos) Else ParseFail:=True;
 End;
 PFunction:=ErrVal(E_ERR);
 { Fonctions sans argument }
 If Nm='PI' Then Begin PFunction:=NumVal(Pi); Exit; End;
 If Nm='RAND' Then Begin PFunction:=NumVal(Random); Exit; End;
 If Nm='NOW' Then Begin PFunction:=NumVal(NowSerial); Exit; End;
 If Nm='TODAY' Then Begin PFunction:=NumVal(TodaySerial); Exit; End;
 If Nm='NA' Then Begin PFunction:=ErrVal(E_NA); Exit; End;
 If Nm='ERR' Then Begin PFunction:=ErrVal(E_ERR); Exit; End;
 If Nm='TRUE' Then Begin PFunction:=NumVal(1); Exit; End;
 If Nm='FALSE' Then Begin PFunction:=NumVal(0); Exit; End;
 { Les tests d'erreur ne propagent pas l'erreur }
 If (Nm='ISERR') Or (Nm='ISNA') Or (Nm='ISNUMBER') Or (Nm='ISSTRING') Then Begin
  If N<1 Then Begin ParseFail:=True; Exit; End;
  If Nm='ISERR' Then Begin
   If (A[1].K=2) And (Trunc(A[1].N)<>E_NA) Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
  End Else If Nm='ISNA' Then Begin
   If (A[1].K=2) And (Trunc(A[1].N)=E_NA) Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
  End Else If Nm='ISNUMBER' Then Begin
   If A[1].K=0 Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
  End Else Begin
   If (A[1].K=1) Or (A[1].K=3) Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
  End;
  Exit;
 End;
 If N=0 Then Begin ParseFail:=True; Exit; End;
 For I:=1 To N Do If A[I].K=2 Then Begin PFunction:=A[I]; Exit; End;
 If Nm='IF' Then Begin
  If N<3 Then Begin ParseFail:=True; Exit; End;
  If Not ToNum(A[1],X) Then Exit;
  If X<>0 Then PFunction:=A[2] Else PFunction:=A[3];
  Exit;
 End;
 If Nm='CHOOSE' Then Begin
  If N<2 Then Begin ParseFail:=True; Exit; End;
  If Not ToNum(A[1],X) Then Exit;
  I:=Trunc(X)+2;
  If (I<2) Or (I>N) Then PFunction:=ErrVal(E_ERR) Else PFunction:=A[I];
  Exit;
 End;
 { Fonctions texte }
 If (Nm='LEFT') Or (Nm='RIGHT') Then Begin
  If N<2 Then Begin ParseFail:=True; Exit; End;
  If Not ToNum(A[2],X) Then Exit;
  S:=ValToStr(A[1]); I:=Trunc(X);
  If I<0 Then Exit;
  If Nm='LEFT' Then PFunction:=StrVal(Copy(S,1,I))
               Else PFunction:=StrVal(Copy(S,MaxI(1,Length(S)-I+1),I));
  Exit;
 End;
 If Nm='MID' Then Begin
  If N<3 Then Begin ParseFail:=True; Exit; End;
  If (Not ToNum(A[2],X)) Or (Not ToNum(A[3],Y)) Then Exit;
  If (X<0) Or (Y<0) Then Exit;
  PFunction:=StrVal(Copy(ValToStr(A[1]),Trunc(X)+1,Trunc(Y)));
  Exit;
 End;
 If Nm='LENGTH' Then Begin PFunction:=NumVal(Length(ValToStr(A[1]))); Exit; End;
 If Nm='UPPER' Then Begin PFunction:=StrVal(UpStr(ValToStr(A[1]))); Exit; End;
 If Nm='LOWER' Then Begin
  S:=ValToStr(A[1]);
  For I:=1 To Length(S) Do If (S[I]>='A') And (S[I]<='Z') Then S[I]:=Chr(Ord(S[I])+32);
  PFunction:=StrVal(S); Exit;
 End;
 If Nm='PROPER' Then Begin
  S:=ValToStr(A[1]); Ok:=True;
  For I:=1 To Length(S) Do Begin
   If IsLetter(S[I]) Then Begin
    If Ok Then S[I]:=UpCase(S[I])
    Else If (S[I]>='A') And (S[I]<='Z') Then S[I]:=Chr(Ord(S[I])+32);
    Ok:=False;
   End Else Ok:=True;
  End;
  PFunction:=StrVal(S); Exit;
 End;
 If Nm='TRIM' Then Begin PFunction:=StrVal(TrimStr(ValToStr(A[1]))); Exit; End;
 If Nm='REPEAT' Then Begin
  If (N<2) Or (Not ToNum(A[2],X)) Then Exit;
  S:=ValToStr(A[1]); T:='';
  For I:=1 To Trunc(X) Do If Length(T)+Length(S)<=80 Then T:=T+S;
  PFunction:=StrVal(T); Exit;
 End;
 If Nm='STRING' Then Begin
  If (N<2) Or (Not ToNum(A[1],X)) Or (Not ToNum(A[2],Y)) Then Exit;
  PFunction:=StrVal(NumToStr(X,Trunc(Y))); Exit;
 End;
 If Nm='VALUE' Then Begin
  If StrToNum(ValToStr(A[1]),X) Then PFunction:=NumVal(X);
  Exit;
 End;
 If Nm='EXACT' Then Begin
  If N<2 Then Exit;
  If ValToStr(A[1])=ValToStr(A[2]) Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
  Exit;
 End;
 If Nm='FIND' Then Begin
  If N<3 Then Exit;
  If Not ToNum(A[3],X) Then Exit;
  S:=Copy(ValToStr(A[2]),Trunc(X)+1,255);
  I:=Pos(ValToStr(A[1]),S);
  If I=0 Then PFunction:=ErrVal(E_NA) Else PFunction:=NumVal(I-1+Trunc(X));
  Exit;
 End;
 { Fonctions numeriques }
 If Not ToNum(A[1],X) Then Exit;
 Y:=0; Z:=0;
 If N>=2 Then If Not ToNum(A[2],Y) Then Exit;
 If N>=3 Then If Not ToNum(A[3],Z) Then Exit;
 If Nm='ABS' Then PFunction:=NumVal(Abs(X))
 Else If Nm='INT' Then PFunction:=NumVal(Int(X))
 Else If Nm='SQRT' Then Begin If X<0 Then PFunction:=ErrVal(E_ERR) Else PFunction:=NumVal(Sqrt(X)); End
 Else If Nm='EXP' Then PFunction:=NumVal(Exp(X))
 Else If Nm='LN' Then Begin If X<=0 Then PFunction:=ErrVal(E_ERR) Else PFunction:=NumVal(Ln(X)); End
 Else If Nm='LOG' Then Begin If X<=0 Then PFunction:=ErrVal(E_ERR) Else PFunction:=NumVal(Ln(X)/Ln(10)); End
 Else If Nm='SIN' Then PFunction:=NumVal(Sin(X))
 Else If Nm='COS' Then PFunction:=NumVal(Cos(X))
 Else If Nm='TAN' Then Begin If Cos(X)=0 Then PFunction:=ErrVal(E_ERR) Else PFunction:=NumVal(Sin(X)/Cos(X)); End
 Else If Nm='ATAN' Then PFunction:=NumVal(ArcTan(X))
 Else If Nm='ASIN' Then Begin
  If Abs(X)>1 Then PFunction:=ErrVal(E_ERR)
  Else If Abs(X)=1 Then PFunction:=NumVal(X*Pi/2)
  Else PFunction:=NumVal(ArcTan(X/Sqrt(1-X*X)));
 End
 Else If Nm='ACOS' Then Begin
  If Abs(X)>1 Then PFunction:=ErrVal(E_ERR)
  Else If X=0 Then PFunction:=NumVal(Pi/2)
  Else If X=1 Then PFunction:=NumVal(0)
  Else If X=-1 Then PFunction:=NumVal(Pi)
  Else Begin
   Z:=ArcTan(Sqrt(1-X*X)/X);
   If X<0 Then Z:=Z+Pi;
   PFunction:=NumVal(Z);
  End;
 End
 Else If Nm='ATAN2' Then Begin
  If X=0 Then Begin
   If Y>0 Then PFunction:=NumVal(Pi/2) Else If Y<0 Then PFunction:=NumVal(-Pi/2) Else PFunction:=ErrVal(E_ERR);
  End Else Begin
   Z:=ArcTan(Y/X);
   If X<0 Then Begin If Y>=0 Then Z:=Z+Pi Else Z:=Z-Pi; End;
   PFunction:=NumVal(Z);
  End;
 End
 Else If Nm='MOD' Then Begin
  If Y=0 Then PFunction:=ErrVal(E_ERR) Else PFunction:=NumVal(X-Y*Int(X/Y));
 End
 Else If Nm='ROUND' Then Begin
  Z:=Pow10(Trunc(Y));
  If X<0 Then PFunction:=NumVal(-Int(-X*Z+0.5)/Z) Else PFunction:=NumVal(Int(X*Z+0.5)/Z);
 End
 Else If Nm='PMT' Then Begin
  If (N<3) Or (Y=0) Then PFunction:=ErrVal(E_ERR)
  Else PFunction:=NumVal(X*Y/(1-Exp(-Z*Ln(1+Y))));
 End
 Else If Nm='PV' Then Begin
  If (N<3) Or (Y=0) Then PFunction:=ErrVal(E_ERR)
  Else PFunction:=NumVal(X*(1-Exp(-Z*Ln(1+Y)))/Y);
 End
 Else If Nm='FV' Then Begin
  If (N<3) Or (Y=0) Then PFunction:=ErrVal(E_ERR)
  Else PFunction:=NumVal(X*(Exp(Z*Ln(1+Y))-1)/Y);
 End
 Else If Nm='DATE' Then Begin
  If N<3 Then PFunction:=ErrVal(E_ERR)
  Else Begin
   Yr:=Trunc(X);
   If Yr<1000 Then Yr:=Yr+1900;
   PFunction:=NumVal(DateToSerial(Yr,Trunc(Y),Trunc(Z)));
  End;
 End
 Else If (Nm='YEAR') Or (Nm='MONTH') Or (Nm='DAY') Then Begin
  SerialToDate(Trunc(X),Yr,Mo,Dy);
  If Nm='YEAR' Then PFunction:=NumVal(Yr-1900)
  Else If Nm='MONTH' Then PFunction:=NumVal(Mo)
  Else PFunction:=NumVal(Dy);
 End
 Else If Nm='SIGN' Then Begin
  If X>0 Then PFunction:=NumVal(1) Else If X<0 Then PFunction:=NumVal(-1) Else PFunction:=NumVal(0);
 End
 Else If Nm='AND' Then Begin
  If (X<>0) And ((N<2) Or (Y<>0)) Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
 End
 Else If Nm='OR' Then Begin
  If (X<>0) Or ((N>=2) And (Y<>0)) Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
 End
 Else If Nm='NOT' Then Begin
  If X=0 Then PFunction:=NumVal(1) Else PFunction:=NumVal(0);
 End
 Else ParseFail:=True;
End;

Function PPrimary: TVal;
Var Sh,R,C,R2,C2,N: Integer; A1,A2: Boolean; Id: String; V: TVal; Save: Integer;
Begin
 SkipSp;
 If FPos>Length(FSrc) Then Begin ParseFail:=True; PPrimary:=ErrVal(E_ERR); Exit; End;
 Case FSrc[FPos] Of
  '(': Begin
   Inc(FPos);
   V:=PLogic;
   SkipSp;
   If (FPos<=Length(FSrc)) And (FSrc[FPos]=')') Then Inc(FPos) Else ParseFail:=True;
   PPrimary:=V;
   Exit;
  End;
  '0'..'9','.': Begin PPrimary:=PNumber; Exit; End;
  '"','''': Begin PPrimary:=PStringLit; Exit; End;
  '@': Begin PPrimary:=PFunction; Exit; End;
 End;
 Save:=FPos;
 If TryRange(Sh,R,C,R2,C2) Then Begin
  PPrimary:=CellVal(Sh,R,C);
  Exit;
 End;
 FPos:=Save;
 ParseFail:=True;
 PPrimary:=ErrVal(E_ERR);
End;
Function PPower: TVal;
Var L,R: TVal; X,Y: Double;
Begin
 L:=PPrimary;
 While PeekCh='^' Do Begin
  Inc(FPos);
  R:=PPrimary;
  If (L.K=2) Then Continue;
  If R.K=2 Then Begin L:=R; Continue; End;
  If (Not ToNum(L,X)) Or (Not ToNum(R,Y)) Then Begin L:=ErrVal(E_ERR); Continue; End;
  If (X=0) And (Y<=0) Then L:=ErrVal(E_ERR)
  Else If X>0 Then L:=NumVal(Exp(Y*Ln(X)))
  Else If Y=Int(Y) Then Begin
   If Odd(Trunc(Y)) Then L:=NumVal(-Exp(Y*Ln(-X))) Else L:=NumVal(Exp(Y*Ln(-X)));
  End Else L:=ErrVal(E_ERR);
 End;
 PPower:=L;
End;

Function PUnary: TVal; Forward;
Function PNot: TVal; Forward;

Function PUnaryR: TVal;
Begin
 PUnaryR:=PUnary;
End;

Function PNotR: TVal;
Begin
 PNotR:=PNot;
End;

Function PUnary: TVal;
Var V: TVal; Ch: Char;
Begin
 Ch:=PeekCh;
 If (Ch='-') Or (Ch='+') Then Begin
  Inc(FPos);
  V:=PUnaryR;
  If V.K=2 Then Begin PUnary:=V; Exit; End;
  If V.K=1 Then Begin PUnary:=ErrVal(E_ERR); Exit; End;
  If V.K=3 Then V:=NumVal(0);
  If Ch='-' Then V.N:=-V.N;
  PUnary:=V;
 End Else PUnary:=PPower;
End;

Function PMul: TVal;
Var L,R: TVal; X,Y: Double; Op: Char;
Begin
 L:=PUnary;
 While PeekCh In ['*','/'] Do Begin
  Op:=FSrc[FPos];
  Inc(FPos);
  R:=PUnary;
  If L.K=2 Then Continue;
  If R.K=2 Then Begin L:=R; Continue; End;
  If (Not ToNum(L,X)) Or (Not ToNum(R,Y)) Then Begin L:=ErrVal(E_ERR); Continue; End;
  If Op='*' Then L:=NumVal(X*Y)
  Else If Y=0 Then L:=ErrVal(E_ERR)
  Else L:=NumVal(X/Y);
 End;
 PMul:=L;
End;

Function PAdd: TVal;
Var L,R: TVal; X,Y: Double; Op: Char;
Begin
 L:=PMul;
 While PeekCh In ['+','-','&'] Do Begin
  Op:=FSrc[FPos];
  Inc(FPos);
  R:=PMul;
  If L.K=2 Then Continue;
  If R.K=2 Then Begin L:=R; Continue; End;
  If Op='&' Then Begin
   L:=StrVal(ValToStr(L)+ValToStr(R));
   Continue;
  End;
  If (Not ToNum(L,X)) Or (Not ToNum(R,Y)) Then Begin L:=ErrVal(E_ERR); Continue; End;
  If Op='+' Then L:=NumVal(X+Y) Else L:=NumVal(X-Y);
 End;
 PAdd:=L;
End;

Function PCompare: TVal;
Var L,R: TVal; Op: String[2]; Cmp: Integer; X,Y: Double; SL,SR: Boolean; A,B: String;
    Res: Boolean;
Begin
 L:=PAdd;
 While PeekCh In ['=','<','>'] Do Begin
  Op:=FSrc[FPos];
  Inc(FPos);
  If (FPos<=Length(FSrc)) And (FSrc[FPos] In ['=','>']) And
     ((Op='<') Or ((Op='>') And (FSrc[FPos]='='))) Then Begin
   Op:=Op+FSrc[FPos];
   Inc(FPos);
  End;
  R:=PAdd;
  If L.K=2 Then Continue;
  If R.K=2 Then Begin L:=R; Continue; End;
  SL:=(L.K=1) Or (L.K=3);
  SR:=(R.K=1) Or (R.K=3);
  If SL And SR Then Begin
   A:=UpStr(L.S); B:=UpStr(R.S);
   If A<B Then Cmp:=-1 Else If A>B Then Cmp:=1 Else Cmp:=0;
  End Else If SL Or SR Then Begin
   If SL Then Cmp:=1 Else Cmp:=-1;
  End Else Begin
   X:=L.N; Y:=R.N;
   If X<Y Then Cmp:=-1 Else If X>Y Then Cmp:=1 Else Cmp:=0;
  End;
  Res:=False;
  If Op='=' Then Res:=Cmp=0
  Else If Op='<>' Then Res:=Cmp<>0
  Else If Op='<' Then Res:=Cmp<0
  Else If Op='>' Then Res:=Cmp>0
  Else If Op='<=' Then Res:=Cmp<=0
  Else If Op='>=' Then Res:=Cmp>=0;
  If Res Then L:=NumVal(1) Else L:=NumVal(0);
 End;
 PCompare:=L;
End;

Function PNot: TVal;
Var V: TVal; X: Double; Save: Integer; W: String;
Begin
 SkipSp;
 If (FPos<=Length(FSrc)) And (FSrc[FPos]='#') Then Begin
  Save:=FPos;
  W:=UpStr(Copy(FSrc,FPos,5));
  If W='#NOT#' Then Begin
   Inc(FPos,5);
   V:=PNotR;
   If V.K=2 Then Begin PNot:=V; Exit; End;
   If Not ToNum(V,X) Then Begin PNot:=ErrVal(E_ERR); Exit; End;
   If X=0 Then PNot:=NumVal(1) Else PNot:=NumVal(0);
   Exit;
  End;
  FPos:=Save;
 End;
 PNot:=PCompare;
End;

Function PLogic: TVal;
Var L,R: TVal; X,Y: Double; W: String; IsAnd: Boolean;
Begin
 L:=PNot;
 While True Do Begin
  SkipSp;
  If (FPos>Length(FSrc)) Or (FSrc[FPos]<>'#') Then Break;
  W:=UpStr(Copy(FSrc,FPos,5));
  If W='#AND#' Then IsAnd:=True
  Else If Copy(W,1,4)='#OR#' Then IsAnd:=False
  Else Break;
  If IsAnd Then Inc(FPos,5) Else Inc(FPos,4);
  R:=PNot;
  If L.K=2 Then Continue;
  If R.K=2 Then Begin L:=R; Continue; End;
  If (Not ToNum(L,X)) Or (Not ToNum(R,Y)) Then Begin L:=ErrVal(E_ERR); Continue; End;
  If IsAnd Then Begin
   If (X<>0) And (Y<>0) Then L:=NumVal(1) Else L:=NumVal(0);
  End Else Begin
   If (X<>0) Or (Y<>0) Then L:=NumVal(1) Else L:=NumVal(0);
  End;
 End;
 PLogic:=L;
End;

Function EvalText(Const Src: String; ShI: Integer): TVal;
Var SSrc: String; SPos,SSh: Integer; V: TVal;
Begin
 SSrc:=FSrc; SPos:=FPos; SSh:=FSheet;
 FSrc:=Src; FPos:=1; FSheet:=ShI;
 V:=PLogic;
 SkipSp;
 If FPos<=Length(FSrc) Then ParseFail:=True;
 FSrc:=SSrc; FPos:=SPos; FSheet:=SSh;
 EvalText:=V;
End;

Procedure EvalCell(ShI,R,C: Integer; P: PCell);
Var V: TVal; Hit: Boolean; PF: Boolean;
Begin
 If P^.Stamp=CalcStamp Then Exit;
 If P^.Busy Then Exit;
 If FDepth>=MAX_DEPTH Then Begin DepthHit:=True; Exit; End;
 P^.Busy:=True;
 Inc(FDepth);
 PF:=ParseFail;
 V:=EvalText(PStrVal(P^.Txt),ShI);
 ParseFail:=PF;
 Dec(FDepth);
 P^.Busy:=False;
 If DepthHit Then Exit;
 P^.Err:=0;
 P^.IsStr:=False;
 FreePStr(P^.Res);
 Case V.K Of
  0: P^.Num:=V.N;
  1,3: Begin P^.IsStr:=True; P^.Res:=NewPStr(V.S); P^.Num:=0; End;
  Else Begin P^.Err:=Trunc(V.N); P^.Num:=0; End;
 End;
 P^.Stamp:=CalcStamp;
End;

Procedure RecalcPass(Rev: Boolean);
Var S,R,C: Integer; Sh: PSheet; P: PCell; R0,R1,Rs,C0,C1,Cs: Integer;
Begin
 For S:=1 To MAX_SHEETS Do Begin
  Sh:=Sheets[S];
  If Sh=Nil Then Continue;
  If Rev Then Begin R0:=Sh^.MaxR; R1:=0; Rs:=-1; End
         Else Begin R0:=0; R1:=Sh^.MaxR; Rs:=1; End;
  R:=R0;
  While (R>=0) And (R<=Sh^.MaxR) Do Begin
   If Sh^.Rows[R]<>Nil Then Begin
    If Rev Then Begin C0:=Sh^.MaxC; C1:=0; Cs:=-1; End
           Else Begin C0:=0; C1:=Sh^.MaxC; Cs:=1; End;
    C:=C0;
    While (C>=0) And (C<=Sh^.MaxC) Do Begin
     P:=Sh^.Rows[R]^[C];
     If (P<>Nil) And (P^.Kind=CK_FORMULA) And (P^.Stamp<>CalcStamp) Then Begin
      DepthHit:=False;
      FDepth:=0;
      EvalCell(S,R,C,P);
     End;
     C:=C+Cs;
    End;
   End;
   If R=R1 Then Break;
   R:=R+Rs;
  End;
 End;
End;

Procedure Recalc;
Var Round_,S,R,C: Integer; Sh: PSheet; P: PCell; Pending: Boolean; PF: Boolean;
Begin
 PF:=ParseFail;
 Inc(CalcStamp);
 If CalcStamp=0 Then CalcStamp:=1;
 CircFound:=False;
 For Round_:=1 To 4 Do Begin
  RecalcPass(Odd(Round_)=False);
  Pending:=False;
  For S:=1 To MAX_SHEETS Do Begin
   Sh:=Sheets[S];
   If Sh=Nil Then Continue;
   For R:=0 To Sh^.MaxR Do Begin
    If Sh^.Rows[R]=Nil Then Continue;
    For C:=0 To Sh^.MaxC Do Begin
     P:=Sh^.Rows[R]^[C];
     If (P<>Nil) And (P^.Kind=CK_FORMULA) And (P^.Stamp<>CalcStamp) Then Pending:=True;
    End;
   End;
  End;
  If Not Pending Then Break;
 End;
 If Pending Then Begin
  For S:=1 To MAX_SHEETS Do Begin
   Sh:=Sheets[S];
   If Sh=Nil Then Continue;
   For R:=0 To Sh^.MaxR Do Begin
    If Sh^.Rows[R]=Nil Then Continue;
    For C:=0 To Sh^.MaxC Do Begin
     P:=Sh^.Rows[R]^[C];
     If (P<>Nil) And (P^.Kind=CK_FORMULA) And (P^.Stamp<>CalcStamp) Then Begin
      P^.Err:=E_CIRC; P^.Stamp:=CalcStamp; CircFound:=True;
     End;
    End;
   End;
  End;
 End;
 ParseFail:=PF;
End;

{ ====================================================================== }
{              REECRITURE DES REFERENCES DANS LES FORMULES               }
{ ====================================================================== }

Const
 RW_SHIFT   = 1;   { copie : decalage relatif }
 RW_INSROW  = 2;
 RW_DELROW  = 3;
 RW_INSCOL  = 4;
 RW_DELCOL  = 5;

Function RewriteFormula(Const Src: String; FSh: Integer; Mode,P1,P2,TgtSh: Integer): String;
{ FSh : feuille contenant la formule ; TgtSh : feuille touchee (insertion/suppression) }
Var Res,Id: String; I,J,Sh,Cn,Rn,NL,Dg: Integer; Ch: Char; AbsC,AbsR,Bad,Ok: Boolean;
    L1,L2: Char; Digits,Pre: String; InQ: Char; Code: Integer; HasSh: Boolean;
    NewC,NewR: Integer; Applies: Boolean;
Begin
 Res:='';
 I:=1;
 InQ:=#0;
 While I<=Length(Src) Do Begin
  Ch:=Src[I];
  If InQ<>#0 Then Begin
   Res:=Res+Ch;
   If Ch=InQ Then InQ:=#0;
   Inc(I);
   Continue;
  End;
  If (Ch='"') Or (Ch='''') Then Begin InQ:=Ch; Res:=Res+Ch; Inc(I); Continue; End;
  If Ch='@' Then Begin
   Res:=Res+Ch; Inc(I);
   While (I<=Length(Src)) And (IsLetter(Src[I]) Or IsDigit(Src[I]) Or (Src[I]='_')) Do Begin
    Res:=Res+Src[I]; Inc(I);
   End;
   Continue;
  End;
  If IsLetter(Ch) Or (Ch='$') Then Begin
   { jeton candidat }
   J:=I;
   Sh:=FSh; HasSh:=False; Pre:='';
   If (J+2<=Length(Src)) And IsLetter(Src[J]) And (Src[J+1]=':') And
      (IsLetter(Src[J+2]) Or (Src[J+2]='$')) Then Begin
    Sh:=Ord(UpCase(Src[J]))-64; HasSh:=True;
    Pre:=Copy(Src,J,2);
    Inc(J,2);
   End;
   AbsC:=False; AbsR:=False;
   If (J<=Length(Src)) And (Src[J]='$') Then Begin AbsC:=True; Inc(J); End;
   NL:=0; L1:=' '; L2:=' ';
   While (J<=Length(Src)) And IsLetter(Src[J]) And (NL<3) Do Begin
    If NL=0 Then L1:=UpCase(Src[J]) Else L2:=UpCase(Src[J]);
    Inc(NL); Inc(J);
   End;
   Ok:=(NL>=1) And (NL<=2);
   If Ok Then Begin
    If (J<=Length(Src)) And (Src[J]='$') Then Begin AbsR:=True; Inc(J); End;
    Digits:='';
    While (J<=Length(Src)) And IsDigit(Src[J]) And (Length(Digits)<5) Do Begin
     Digits:=Digits+Src[J]; Inc(J);
    End;
    If Digits='' Then Ok:=False;
    If Ok And (J<=Length(Src)) And (IsLetter(Src[J]) Or IsDigit(Src[J]) Or (Src[J]='_') Or (Src[J]='(')) Then Ok:=False;
   End;
   If Not Ok Then Begin
    { identificateur ordinaire : on le recopie en entier }
    While (I<=Length(Src)) And (IsLetter(Src[I]) Or IsDigit(Src[I]) Or (Src[I]='_') Or (Src[I]='$')) Do Begin
     Res:=Res+Src[I]; Inc(I);
    End;
    If (I<=Length(Src)) And (Res<>'') And (Src[I]=':') And (Length(Res)=1) Then Begin
     Res:=Res+':'; Inc(I);
    End;
    If I=J Then Begin End;
    Continue;
   End;
   If NL=1 Then Cn:=Ord(L1)-65 Else Cn:=(Ord(L1)-64)*26+(Ord(L2)-65);
   Val(Digits,Rn,Code);
   Dec(Rn);
   NewC:=Cn; NewR:=Rn; Bad:=False;
   Applies:=(Sh=TgtSh);
   Case Mode Of
    RW_SHIFT: Begin
     If Not AbsC Then NewC:=Cn+P2;
     If Not AbsR Then NewR:=Rn+P1;
     If (NewC<0) Or (NewC>=MAX_COLS) Or (NewR<0) Or (NewR>=MAX_ROWS) Then Bad:=True;
    End;
    RW_INSROW: If Applies And (Rn>=P1) Then NewR:=Rn+P2;
    RW_DELROW: If Applies Then Begin
     If Rn>=P1+P2 Then NewR:=Rn-P2 Else If Rn>=P1 Then NewR:=P1;
    End;
    RW_INSCOL: If Applies And (Cn>=P1) Then NewC:=Cn+P2;
    RW_DELCOL: If Applies Then Begin
     If Cn>=P1+P2 Then NewC:=Cn-P2 Else If Cn>=P1 Then NewC:=P1;
    End;
   End;
   If (NewC<0) Or (NewC>=MAX_COLS) Or (NewR<0) Or (NewR>=MAX_ROWS) Then Bad:=True;
   If Bad Then Res:=Res+'ERR'
   Else Begin
    Res:=Res+Pre;
    If AbsC Then Res:=Res+'$';
    Res:=Res+ColName(NewC);
    If AbsR Then Res:=Res+'$';
    Res:=Res+IntToStr(NewR+1);
   End;
   I:=J;
   Continue;
  End;
  Res:=Res+Ch;
  Inc(I);
 End;
 RewriteFormula:=Res;
End;

{ ====================================================================== }
{                       SAISIE D'UNE ENTREE DE CELLULE                   }
{ ====================================================================== }

Function IsValueStart(C: Char): Boolean;
Begin
 IsValueStart:=C In ['0'..'9','+','-','.','(','@','#','$'];
End;

Procedure SetCellContent(Sh: PSheet; R,C: Integer; Const Entry: String);
{ Interprete l'entree comme le fait 1-2-3 : valeur, formule ou etiquette }
Var P: PCell; S: String; X: Double; Ch: Char;
Begin
 S:=Entry;
 If S='' Then Begin
  P:=CellAt(Sh,R,C);
  If P<>Nil Then CellFreeContent(P);
  Exit;
 End;
 P:=CellNew(Sh,R,C);
 If P=Nil Then Exit;
 CellFreeContent(P);
 Ch:=S[1];
 If Ch In ['''','"','^','\'] Then Begin
  P^.Kind:=CK_LABEL;
  P^.Pfx:=Ch;
  P^.Txt:=NewPStr(Copy(S,2,255));
  Exit;
 End;
 If IsValueStart(Ch) Then Begin
  If StrToNum(S,X) Then Begin
   P^.Kind:=CK_VALUE;
   P^.Num:=X;
   Exit;
  End;
  P^.Kind:=CK_FORMULA;
  P^.Txt:=NewPStr(S);
  P^.Stamp:=0;
  Exit;
 End;
 P^.Kind:=CK_LABEL;
 P^.Pfx:=#0;
 P^.Txt:=NewPStr(S);
End;

{ Texte d'edition d'une cellule }
Function CellEditText(P: PCell): String;
Var S: String;
Begin
 CellEditText:='';
 If P=Nil Then Exit;
 Case P^.Kind Of
  CK_LABEL: Begin
   If P^.Pfx<>#0 Then CellEditText:=P^.Pfx+PStrVal(P^.Txt)
                 Else CellEditText:=PStrVal(P^.Txt);
  End;
  CK_VALUE: Begin
   S:=GeneralStr(P^.Num,15);
   CellEditText:=S;
  End;
  CK_FORMULA: CellEditText:=PStrVal(P^.Txt);
 End;
End;

{ ====================================================================== }
{                  ANNULER, PRESSE-PAPIERS, EDITION                      }
{ ====================================================================== }

Procedure PlaceCell(Sh: PSheet; R,C: Integer; P: PCell);
Var Old: PCell;
Begin
 If CellNew(Sh,R,C)=Nil Then Begin CellDispose(P); Exit; End;
 Old:=Sh^.Rows[R]^[C];
 CellDispose(Old);
 Sh^.Rows[R]^[C]:=P;
 If R>Sh^.MaxR Then Sh^.MaxR:=R;
 If C>Sh^.MaxC Then Sh^.MaxC:=C;
End;

Procedure EraseRect(Sh: PSheet; R1,C1,R2,C2: Integer);
Var R,C,CE: Integer;
Begin
 If R2>Sh^.MaxR Then R2:=Sh^.MaxR;
 CE:=C2;
 If CE>Sh^.MaxC Then CE:=Sh^.MaxC;
 For R:=R1 To R2 Do Begin
  If Sh^.Rows[R]=Nil Then Continue;
  For C:=C1 To CE Do CellDispose(Sh^.Rows[R]^[C]);
 End;
End;

Procedure UndoFree(U: PUndo);
Var I: Integer;
Begin
 If U=Nil Then Exit;
 If U^.Cells<>Nil Then Begin
  For I:=0 To U^.N-1 Do CellDispose(U^.Cells^[I].P);
  FreeMem(U^.Cells,U^.N*SizeOf(TSnapCell));
 End;
 Dispose(U);
End;

Procedure UndoClear;
Var U,N: PUndo;
Begin
 U:=UndoTop;
 While U<>Nil Do Begin N:=U^.Next; UndoFree(U); U:=N; End;
 UndoTop:=Nil;
 UndoCount:=0;
End;

Procedure UndoPush(ShI,R1,C1,R2,C2: Integer);
Var U,T: PUndo; Sh: PSheet; R,C,CE,RE,N,I: Integer; P: PCell;
Begin
 Sh:=SheetPtr(ShI);
 New(U);
 U^.Sheet:=ShI; U^.R1:=R1; U^.C1:=C1; U^.R2:=R2; U^.C2:=C2;
 U^.Cells:=Nil; U^.N:=0;
 RE:=R2; If RE>Sh^.MaxR Then RE:=Sh^.MaxR;
 CE:=C2; If CE>Sh^.MaxC Then CE:=Sh^.MaxC;
 N:=0;
 For R:=R1 To RE Do
  If Sh^.Rows[R]<>Nil Then
   For C:=C1 To CE Do If Sh^.Rows[R]^[C]<>Nil Then Inc(N);
 If (N>0) And (LongInt(N)*SizeOf(TSnapCell)<60000) Then Begin
  GetMem(U^.Cells,N*SizeOf(TSnapCell));
  I:=0;
  For R:=R1 To RE Do
   If Sh^.Rows[R]<>Nil Then
    For C:=C1 To CE Do Begin
     P:=Sh^.Rows[R]^[C];
     If P<>Nil Then Begin
      U^.Cells^[I].R:=R; U^.Cells^[I].C:=C; U^.Cells^[I].P:=CellCopy(P);
      Inc(I);
     End;
    End;
  U^.N:=N;
 End Else If N>0 Then Begin
  Dispose(U);
  UndoClear;
  Exit;
 End;
 U^.Next:=UndoTop;
 UndoTop:=U;
 Inc(UndoCount);
 If UndoCount>UNDO_MAX Then Begin
  T:=UndoTop;
  For I:=2 To UNDO_MAX Do T:=T^.Next;
  UndoFree(T^.Next);
  T^.Next:=Nil;
  UndoCount:=UNDO_MAX;
 End;
End;

Procedure UndoPop;
Var U: PUndo; Sh: PSheet; I: Integer;
Begin
 If UndoTop=Nil Then Exit;
 U:=UndoTop;
 UndoTop:=U^.Next;
 Dec(UndoCount);
 Sh:=SheetPtr(U^.Sheet);
 EraseRect(Sh,U^.R1,U^.C1,U^.R2,U^.C2);
 For I:=0 To U^.N-1 Do Begin
  PlaceCell(Sh,U^.Cells^[I].R,U^.Cells^[I].C,U^.Cells^[I].P);
  U^.Cells^[I].P:=Nil;
 End;
 UndoFree(U);
 Recalc;
End;

Procedure ClipClear;
Var I: Integer;
Begin
 For I:=1 To ClipN Do CellDispose(ClipCells[I].P);
 ClipN:=0;
 ClipRows:=0; ClipCols:=0;
End;

Function DoCopy(Cut: Boolean): Boolean;
Var Sh: PSheet; R,C,RE,CE,N: Integer; P: PCell;
Begin
 DoCopy:=False;
 Sh:=CurSheet;
 ClipClear;
 RE:=SelR2; If RE>Sh^.MaxR Then RE:=Sh^.MaxR;
 CE:=SelC2; If CE>Sh^.MaxC Then CE:=Sh^.MaxC;
 N:=0;
 For R:=SelR1 To RE Do
  If Sh^.Rows[R]<>Nil Then
   For C:=SelC1 To CE Do
    If Sh^.Rows[R]^[C]<>Nil Then Begin
     Inc(N);
     If N>600 Then Exit;
     ClipCells[N].R:=R-SelR1;
     ClipCells[N].C:=C-SelC1;
     ClipCells[N].P:=CellCopy(Sh^.Rows[R]^[C]);
    End;
 ClipN:=N;
 ClipRows:=SelR2-SelR1+1;
 ClipCols:=SelC2-SelC1+1;
 ClipCut:=Cut;
 ClipSrcR:=SelR1; ClipSrcC:=SelC1; ClipSheet:=ActSheet;
 DoCopy:=True;
End;

Procedure DoPaste;
Var Sh: PSheet; R0,C0,R,C,I,TR,TC,R2,C2,DR,DC: Integer; P: PCell; S: String;
Begin
 If ClipRows=0 Then Exit;
 Sh:=CurSheet;
 R2:=SelR1+ClipRows-1;
 C2:=SelC1+ClipCols-1;
 If (SelR2>R2) Then R2:=SelR2;
 If (SelC2>C2) Then C2:=SelC2;
 If R2>=MAX_ROWS Then R2:=MAX_ROWS-1;
 If C2>=MAX_COLS Then C2:=MAX_COLS-1;
 UndoPush(ActSheet,SelR1,SelC1,R2,C2);
 TR:=SelR1;
 While TR<=R2 Do Begin
  TC:=SelC1;
  While TC<=C2 Do Begin
   EraseRect(Sh,TR,TC,MinI(TR+ClipRows-1,MAX_ROWS-1),MinI(TC+ClipCols-1,MAX_COLS-1));
   For I:=1 To ClipN Do Begin
    R:=TR+ClipCells[I].R;
    C:=TC+ClipCells[I].C;
    If (R>=MAX_ROWS) Or (C>=MAX_COLS) Then Continue;
    P:=CellCopy(ClipCells[I].P);
    If (P^.Kind=CK_FORMULA) And Not ClipCut Then Begin
     DR:=R-(ClipSrcR+ClipCells[I].R);
     DC:=C-(ClipSrcC+ClipCells[I].C);
     S:=RewriteFormula(PStrVal(P^.Txt),ClipSheet,RW_SHIFT,DR,DC,0);
     FreePStr(P^.Txt);
     P^.Txt:=NewPStr(S);
    End;
    P^.Stamp:=0;
    PlaceCell(Sh,R,C,P);
   End;
   TC:=TC+ClipCols;
  End;
  TR:=TR+ClipRows;
 End;
 If ClipCut Then Begin
  EraseRect(SheetPtr(ClipSheet),ClipSrcR,ClipSrcC,ClipSrcR+ClipRows-1,ClipSrcC+ClipCols-1);
  ClipClear;
 End;
 Modified:=True;
 Recalc;
End;

Procedure DoClear(All: Boolean);
Var Sh: PSheet; R,C,RE,CE,R1,C1,R2,C2: Integer; P: PCell;
Begin
 Sh:=CurSheet;
 R1:=SelR1; C1:=SelC1; R2:=SelR2; C2:=SelC2;
 UndoPush(ActSheet,R1,C1,R2,C2);
 If All Then EraseRect(Sh,R1,C1,R2,C2)
 Else Begin
  RE:=R2; If RE>Sh^.MaxR Then RE:=Sh^.MaxR;
  CE:=C2; If CE>Sh^.MaxC Then CE:=Sh^.MaxC;
  For R:=R1 To RE Do
   If Sh^.Rows[R]<>Nil Then
    For C:=C1 To CE Do Begin
     P:=Sh^.Rows[R]^[C];
     If P<>Nil Then CellFreeContent(P);
    End;
 End;
 Modified:=True;
 Recalc;
End;

{ Application d'attributs sur la selection }
Const
 AT_FORMAT = 1;
 AT_ALIGN  = 2;
 AT_STYLE  = 3;
 AT_FG     = 4;
 AT_BG     = 5;
 AT_DEC    = 6;

Procedure SetAttr(What,V1,V2: Integer);
Var Sh: PSheet; R,C,R1,C1,R2,C2: Integer; P: PCell; On: Boolean;
Begin
 Sh:=CurSheet;
 R1:=SelR1; C1:=SelC1; R2:=SelR2; C2:=SelC2;
 ClampToUsed(R1,C1,R2,C2);
 UndoPush(ActSheet,R1,C1,R2,C2);
 On:=True;
 If What=AT_STYLE Then Begin
  P:=CellAt(Sh,SelR1,SelC1);
  If (P<>Nil) And ((P^.Style And V1)<>0) And (V1<>0) Then On:=False;
 End;
 For R:=R1 To R2 Do
  For C:=C1 To C2 Do Begin
   P:=CellNew(Sh,R,C);
   If P=Nil Then Continue;
   Case What Of
    AT_FORMAT: Begin P^.Fmt:=V1; P^.Dec:=V2; End;
    AT_DEC: P^.Dec:=V1;
    AT_ALIGN: P^.Align:=V1;
    AT_STYLE: Begin
     If V1=0 Then P^.Style:=0
     Else If On Then P^.Style:=P^.Style Or V1
     Else P^.Style:=P^.Style And (Not V1);
    End;
    AT_FG: P^.Fg:=V1;
    AT_BG: P^.Bg:=V1;
   End;
  End;
 Modified:=True;
End;

{ ====================================================================== }
{                 INSERTION / SUPPRESSION LIGNES, COLONNES               }
{ ====================================================================== }

Procedure RewriteAll(Mode,P1,P2: Integer);
Var S,R,C,I: Integer; Sh: PSheet; P: PCell; T: String;
Begin
 For S:=1 To MAX_SHEETS Do Begin
  Sh:=Sheets[S];
  If Sh=Nil Then Continue;
  For R:=0 To Sh^.MaxR Do Begin
   If Sh^.Rows[R]=Nil Then Continue;
   For C:=0 To Sh^.MaxC Do Begin
    P:=Sh^.Rows[R]^[C];
    If (P<>Nil) And (P^.Kind=CK_FORMULA) Then Begin
     T:=RewriteFormula(PStrVal(P^.Txt),S,Mode,P1,P2,ActSheet);
     FreePStr(P^.Txt);
     P^.Txt:=NewPStr(T);
    End;
   End;
  End;
 End;
 For I:=1 To MAX_CHARTS Do
  If Charts[I]<>Nil Then Begin
   Charts[I]^.XRng:=RewriteFormula(Charts[I]^.XRng,1,Mode,P1,P2,ActSheet);
   For C:=1 To NSER Do
    Charts[I]^.Rng[C]:=RewriteFormula(Charts[I]^.Rng[C],1,Mode,P1,P2,ActSheet);
  End;
 For I:=1 To NameCount Do
  If Names[I].Sheet=ActSheet Then Begin
   Case Mode Of
    RW_INSROW: Begin
     If Names[I].R1>=P1 Then Inc(Names[I].R1,P2);
     If Names[I].R2>=P1 Then Inc(Names[I].R2,P2);
    End;
    RW_DELROW: Begin
     If Names[I].R1>=P1+P2 Then Dec(Names[I].R1,P2) Else If Names[I].R1>=P1 Then Names[I].R1:=P1;
     If Names[I].R2>=P1+P2 Then Dec(Names[I].R2,P2) Else If Names[I].R2>=P1 Then Names[I].R2:=MaxI(P1-1,0);
     If Names[I].R2<Names[I].R1 Then Names[I].R2:=Names[I].R1;
    End;
    RW_INSCOL: Begin
     If Names[I].C1>=P1 Then Inc(Names[I].C1,P2);
     If Names[I].C2>=P1 Then Inc(Names[I].C2,P2);
    End;
    RW_DELCOL: Begin
     If Names[I].C1>=P1+P2 Then Dec(Names[I].C1,P2) Else If Names[I].C1>=P1 Then Names[I].C1:=P1;
     If Names[I].C2>=P1+P2 Then Dec(Names[I].C2,P2) Else If Names[I].C2>=P1 Then Names[I].C2:=MaxI(P1-1,0);
     If Names[I].C2<Names[I].C1 Then Names[I].C2:=Names[I].C1;
    End;
   End;
  End;
End;

Procedure InsertRows(At,N: Integer);
Var Sh: PSheet; R,C: Integer; Row: PRow;
Begin
 Sh:=CurSheet;
 UndoClear;
 If At+N>=MAX_ROWS Then Exit;
 For R:=MAX_ROWS-N To MAX_ROWS-1 Do Begin
  Row:=Sh^.Rows[R];
  If Row<>Nil Then Begin
   For C:=0 To MAX_COLS-1 Do CellDispose(Row^[C]);
   Dispose(Row);
   Sh^.Rows[R]:=Nil;
  End;
 End;
 For R:=MAX_ROWS-1 DownTo At+N Do Begin
  Sh^.Rows[R]:=Sh^.Rows[R-N];
  Sh^.RowH[R]:=Sh^.RowH[R-N];
 End;
 For R:=At To At+N-1 Do Begin Sh^.Rows[R]:=Nil; Sh^.RowH[R]:=0; End;
 Sh^.MaxR:=MinI(Sh^.MaxR+N,MAX_ROWS-1);
 RewriteAll(RW_INSROW,At,N);
 Modified:=True;
 Recalc;
End;

Procedure DeleteRows(At,N: Integer);
Var Sh: PSheet; R,C: Integer; Row: PRow;
Begin
 Sh:=CurSheet;
 UndoClear;
 If At+N>MAX_ROWS Then N:=MAX_ROWS-At;
 For R:=At To At+N-1 Do Begin
  Row:=Sh^.Rows[R];
  If Row<>Nil Then Begin
   For C:=0 To MAX_COLS-1 Do CellDispose(Row^[C]);
   Dispose(Row);
   Sh^.Rows[R]:=Nil;
  End;
 End;
 For R:=At To MAX_ROWS-1-N Do Begin
  Sh^.Rows[R]:=Sh^.Rows[R+N];
  Sh^.RowH[R]:=Sh^.RowH[R+N];
 End;
 For R:=MAX_ROWS-N To MAX_ROWS-1 Do Begin Sh^.Rows[R]:=Nil; Sh^.RowH[R]:=0; End;
 RewriteAll(RW_DELROW,At,N);
 Modified:=True;
 Recalc;
End;

Procedure InsertCols(At,N: Integer);
Var Sh: PSheet; R,C: Integer;
Begin
 Sh:=CurSheet;
 UndoClear;
 If At+N>=MAX_COLS Then Exit;
 For R:=0 To Sh^.MaxR Do Begin
  If Sh^.Rows[R]=Nil Then Continue;
  For C:=MAX_COLS-N To MAX_COLS-1 Do CellDispose(Sh^.Rows[R]^[C]);
  For C:=MAX_COLS-1 DownTo At+N Do Sh^.Rows[R]^[C]:=Sh^.Rows[R]^[C-N];
  For C:=At To At+N-1 Do Sh^.Rows[R]^[C]:=Nil;
 End;
 For C:=MAX_COLS-1 DownTo At+N Do Sh^.ColW[C]:=Sh^.ColW[C-N];
 For C:=At To At+N-1 Do Sh^.ColW[C]:=DEF_COLW;
 Sh^.MaxC:=MinI(Sh^.MaxC+N,MAX_COLS-1);
 RewriteAll(RW_INSCOL,At,N);
 Modified:=True;
 Recalc;
End;

Procedure DeleteCols(At,N: Integer);
Var Sh: PSheet; R,C: Integer;
Begin
 Sh:=CurSheet;
 UndoClear;
 If At+N>MAX_COLS Then N:=MAX_COLS-At;
 For R:=0 To Sh^.MaxR Do Begin
  If Sh^.Rows[R]=Nil Then Continue;
  For C:=At To At+N-1 Do CellDispose(Sh^.Rows[R]^[C]);
  For C:=At To MAX_COLS-1-N Do Sh^.Rows[R]^[C]:=Sh^.Rows[R]^[C+N];
  For C:=MAX_COLS-N To MAX_COLS-1 Do Sh^.Rows[R]^[C]:=Nil;
 End;
 For C:=At To MAX_COLS-1-N Do Sh^.ColW[C]:=Sh^.ColW[C+N];
 For C:=MAX_COLS-N To MAX_COLS-1 Do Sh^.ColW[C]:=DEF_COLW;
 RewriteAll(RW_DELCOL,At,N);
 Modified:=True;
 Recalc;
End;

{ ====================================================================== }
{                       TRI, REMPLISSAGE, TRANSPOSITION                  }
{ ====================================================================== }

Type
 TIdxArr = Array[0..MAX_ROWS-1] Of Integer;
 PIdxArr = ^TIdxArr;
 TPtrArr = Array[0..MAX_ROWS-1] Of PCell;
 PPtrArr = ^TPtrArr;

Procedure EnsureRow(Sh: PSheet; R: Integer);
Var Row: PRow;
Begin
 If Sh^.Rows[R]=Nil Then Begin
  New(Row);
  FillChar(Row^,SizeOf(TRow),0);
  Sh^.Rows[R]:=Row;
 End;
End;

Function CompareCells(P,Q: PCell; ShI: Integer; R1,R2,C: Integer; Asc: Boolean): Integer;
{ Compare deux cellules pour le tri (vides toujours en dernier) }
Var A,B: TVal; PE,QE: Boolean; Res: Integer;
Begin
 PE:=(P=Nil) Or (P^.Kind=CK_EMPTY);
 QE:=(Q=Nil) Or (Q^.Kind=CK_EMPTY);
 If PE And QE Then Begin CompareCells:=0; Exit; End;
 If PE Then Begin CompareCells:=1; Exit; End;
 If QE Then Begin CompareCells:=-1; Exit; End;
 A:=CellVal(ShI,R1,C);
 B:=CellVal(ShI,R2,C);
 If (A.K=0) And (B.K=0) Then Begin
  If A.N<B.N Then Res:=-1 Else If A.N>B.N Then Res:=1 Else Res:=0;
 End Else If A.K=0 Then Res:=-1
 Else If B.K=0 Then Res:=1
 Else Begin
  If UpStr(A.S)<UpStr(B.S) Then Res:=-1
  Else If UpStr(A.S)>UpStr(B.S) Then Res:=1
  Else Res:=0;
 End;
 If Not Asc Then Res:=-Res;
 CompareCells:=Res;
End;

Procedure SortSelection(KeyCol: Integer; Asc: Boolean);
Var Sh: PSheet; Idx: PIdxArr; Tmp: PPtrArr; N,I,J,T,C,R1: Integer; Fs: String;
Begin
 Sh:=CurSheet;
 N:=SelR2-SelR1+1;
 If (N<2) Or (KeyCol<SelC1) Or (KeyCol>SelC2) Then Exit;
 R1:=SelR1;
 UndoPush(ActSheet,SelR1,SelC1,SelR2,SelC2);
 GetMem(Idx,N*SizeOf(Integer));
 GetMem(Tmp,N*SizeOf(PCell));
 For I:=0 To N-1 Do Idx^[I]:=I;
 For I:=1 To N-1 Do Begin
  T:=Idx^[I];
  J:=I-1;
  While J>=0 Do Begin
   If CompareCells(CellAt(Sh,R1+Idx^[J],KeyCol),CellAt(Sh,R1+T,KeyCol),ActSheet,
                   R1+Idx^[J],R1+T,KeyCol,Asc)<=0 Then Break;
   Idx^[J+1]:=Idx^[J];
   Dec(J);
  End;
  Idx^[J+1]:=T;
 End;
 For C:=SelC1 To SelC2 Do Begin
  For I:=0 To N-1 Do Begin
   If Sh^.Rows[R1+Idx^[I]]<>Nil Then Tmp^[I]:=Sh^.Rows[R1+Idx^[I]]^[C] Else Tmp^[I]:=Nil;
  End;
  For I:=0 To N-1 Do Begin
   If Tmp^[I]<>Nil Then Begin
    EnsureRow(Sh,R1+I);
    If (Tmp^[I]^.Kind=CK_FORMULA) And (I<>Idx^[I]) Then Begin
     Fs:=RewriteFormula(PStrVal(Tmp^[I]^.Txt),ActSheet,RW_SHIFT,I-Idx^[I],0,0);
     FreePStr(Tmp^[I]^.Txt);
     Tmp^[I]^.Txt:=NewPStr(Fs);
    End;
    Sh^.Rows[R1+I]^[C]:=Tmp^[I];
   End Else If Sh^.Rows[R1+I]<>Nil Then Sh^.Rows[R1+I]^[C]:=Nil;
  End;
 End;
 FreeMem(Idx,N*SizeOf(Integer));
 FreeMem(Tmp,N*SizeOf(PCell));
 Modified:=True;
 Recalc;
End;

Procedure FillSelection(Start,Step,Stop: Double);
Var Sh: PSheet; R,C: Integer; V: Double; P: PCell;
Begin
 Sh:=CurSheet;
 UndoPush(ActSheet,SelR1,SelC1,SelR2,SelC2);
 V:=Start;
 For C:=SelC1 To SelC2 Do
  For R:=SelR1 To SelR2 Do Begin
   If ((Step>0) And (V>Stop)) Or ((Step<0) And (V<Stop)) Then Continue;
   P:=CellNew(Sh,R,C);
   If P=Nil Then Continue;
   CellFreeContent(P);
   P^.Kind:=CK_VALUE;
   P^.Num:=V;
   V:=V+Step;
  End;
 Modified:=True;
 Recalc;
End;

Procedure TransposeTo(DR,DC: Integer);
Var Sh: PSheet; R,C: Integer; P,Q: PCell; V: TVal;
Begin
 Sh:=CurSheet;
 If (DR+(SelC2-SelC1)>=MAX_ROWS) Or (DC+(SelR2-SelR1)>=MAX_COLS) Then Exit;
 UndoPush(ActSheet,DR,DC,DR+(SelC2-SelC1),DC+(SelR2-SelR1));
 For R:=SelR1 To SelR2 Do
  For C:=SelC1 To SelC2 Do Begin
   P:=CellAt(Sh,R,C);
   If (P=Nil) Or (P^.Kind=CK_EMPTY) Then Begin
    CellKill(Sh,DR+(C-SelC1),DC+(R-SelR1));
    Continue;
   End;
   Q:=CellCopy(P);
   If Q^.Kind=CK_FORMULA Then Begin
    V:=CellVal(ActSheet,R,C);
    CellFreeContent(Q);
    If V.K=0 Then Begin Q^.Kind:=CK_VALUE; Q^.Num:=V.N; End
    Else If (V.K=1) Or (V.K=3) Then Begin Q^.Kind:=CK_LABEL; Q^.Pfx:=#0; Q^.Txt:=NewPStr(V.S); End;
   End;
   PlaceCell(Sh,DR+(C-SelC1),DC+(R-SelR1),Q);
  End;
 Modified:=True;
 Recalc;
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES                            }
{ ====================================================================== }

Procedure FillBox(X1,Y1,X2,Y2: Integer; Color: Integer);
Begin
 SetFillStyle(1,Color);
 Bar(X1,Y1,X2,Y2);
End;

Procedure DrawFrame(X1,Y1,X2,Y2: Integer; Light,Dark: Integer);
Begin
 SetColor(Light);
 Line(X1,Y1,X2,Y1);
 Line(X1,Y1,X1,Y2);
 SetColor(Dark);
 Line(X1,Y2,X2,Y2);
 Line(X2,Y1,X2,Y2);
End;

Procedure RaisedFrame(X1,Y1,X2,Y2: Integer);
Begin
 DrawFrame(X1,Y1,X2,Y2,CL_WHITE,CL_DKGRAY);
End;

Procedure SunkenFrame(X1,Y1,X2,Y2: Integer);
Begin
 DrawFrame(X1,Y1,X2,Y2,CL_DKGRAY,CL_WHITE);
End;

Procedure Rect(X1,Y1,X2,Y2: Integer; Color: Integer);
Begin
 SetColor(Color);
 Rectangle(X1,Y1,X2,Y2);
End;

Procedure TextAt(X,Y: Integer; Color: Integer; Const S: String);
Begin
 SetColor(Color);
 OutTextXY(X,Y,S);
End;

Procedure BoldAt(X,Y: Integer; Color: Integer; Const S: String);
Begin
 SetColor(Color);
 OutTextXY(X,Y,S);
 OutTextXY(X+1,Y,S);
End;

Procedure LineC(X1,Y1,X2,Y2,Color: Integer);
Begin
 SetColor(Color);
 Line(X1,Y1,X2,Y2);
End;

{ Fenetre de dialogue standard : retourne la zone interieure }
Procedure DlgFrame(X1,Y1,X2,Y2: Integer; Const Title: String);
Begin
 FillBox(X1,Y1,X2,Y2,CL_BG);
 RaisedFrame(X1,Y1,X2,Y2);
 RaisedFrame(X1+1,Y1+1,X2-1,Y2-1);
 FillBox(X1+3,Y1+3,X2-3,Y1+19,CL_BLUE);
 BoldAt(X1+8,Y1+7,CL_WHITE,Tr(Title));
End;

Procedure DrawButton(X1,Y1,X2,Y2: Integer; Const Cap0: String; Default: Boolean);
Var Tx: Integer; Cap: String;
Begin
 Cap:=Tr(Cap0);
 FillBox(X1,Y1,X2,Y2,CL_BG);
 If Default Then Rect(X1-1,Y1-1,X2+1,Y2+1,CL_BLACK);
 RaisedFrame(X1,Y1,X2,Y2);
 SetColor(CL_DKGRAY);
 Line(X1+1,Y2-1,X2-1,Y2-1);
 Line(X2-1,Y1+1,X2-1,Y2-1);
 Tx:=X1+(X2-X1+1-8*Length(Cap)) Div 2;
 TextAt(Tx,Y1+(Y2-Y1-7) Div 2+1,CL_BLACK,Cap);
End;

Procedure DrawEditBox(X1,Y1,X2,Y2: Integer; Const S: String; CurPos: Integer; ShowCur: Boolean);
Var W,Off,Vis: Integer; T: String;
Begin
 FillBox(X1,Y1,X2,Y2,CL_WHITE);
 SunkenFrame(X1,Y1,X2,Y2);
 W:=(X2-X1-6) Div 8;
 Off:=0;
 If ShowCur And (CurPos>W) Then Off:=CurPos-W;
 T:=Copy(S,Off+1,W);
 TextAt(X1+4,Y1+(Y2-Y1-7) Div 2+1,CL_BLACK,T);
 If ShowCur Then Begin
  Vis:=CurPos-1-Off;
  LineC(X1+4+Vis*8,Y1+3,X1+4+Vis*8,Y2-3,CL_BLACK);
 End;
End;

{ Remplissage d'un polygone par balayage (regle pair/impair) }
Procedure PolyFill(N: Integer; Var P: Array Of PointType; Fill,Outline: Integer);
Var Y,YMin,YMax,I,J,C,T,Y1,Y2,X1,X2: Integer; XS: Array[0..15] Of Integer;
Begin
 If (N<3) Or (N>16) Then Exit;
 YMin:=P[0].Y; YMax:=P[0].Y;
 For I:=1 To N-1 Do Begin
  If P[I].Y<YMin Then YMin:=P[I].Y;
  If P[I].Y>YMax Then YMax:=P[I].Y;
 End;
 SetColor(Fill);
 SetLineStyle(0,0,1);
 For Y:=YMin To YMax Do Begin
  C:=0;
  For I:=0 To N-1 Do Begin
   J:=I+1; If J>=N Then J:=0;
   Y1:=P[I].Y; Y2:=P[J].Y; X1:=P[I].X; X2:=P[J].X;
   If ((Y1<=Y) And (Y2>Y)) Or ((Y2<=Y) And (Y1>Y)) Then
    If C<16 Then Begin
     XS[C]:=X1+Round((Y-Y1)*(X2-X1)/(Y2-Y1));
     Inc(C);
    End;
  End;
  For I:=1 To C-1 Do Begin
   T:=XS[I]; J:=I-1;
   While (J>=0) And (XS[J]>T) Do Begin XS[J+1]:=XS[J]; Dec(J); End;
   XS[J+1]:=T;
  End;
  I:=0;
  While I<C-1 Do Begin
   Line(XS[I],Y,XS[I+1],Y);
   Inc(I,2);
  End;
 End;
 If Outline>=0 Then Begin
  SetColor(Outline);
  For I:=0 To N-1 Do Begin
   J:=I+1; If J>=N Then J:=0;
   Line(P[I].X,P[I].Y,P[J].X,P[J].Y);
  End;
 End;
End;

{ ====================================================================== }
{                              ICONES                                    }
{ ====================================================================== }

Const
 IC_NEW=1; IC_OPEN=2; IC_SAVE=3; IC_PRINT=4; IC_CUT=5; IC_COPY=6; IC_PASTE=7;
 IC_UNDO=8; IC_BOLD=9; IC_ITALIC=10; IC_UNDER=11; IC_LEFT=12; IC_CENTER=13;
 IC_RIGHT=14; IC_CURR=15; IC_COMMA=16; IC_PCT=17; IC_SUM=18; IC_ASC=19;
 IC_DESC=20; IC_CHART=21; IC_HELP=22;
 IC_GARROW=30; IC_GLINE=31; IC_GELLIPSE=32; IC_GRECT=33; IC_GTEXT=34;
 IC_TLINE=35; IC_TBAR=36; IC_THBAR=37; IC_TSTACK=38; IC_TAREA=39; IC_TPIE=40;
 IC_TXY=41; IC_G3D=42; IC_GBACK=43; IC_GSEL=44; IC_GFLIP=45;

Procedure DrawIcon(Id,X,Y: Integer);
Var Cx,Cy,I: Integer; Pts: Array[0..5] Of PointType;
Begin
 Cx:=X+13; Cy:=Y+12;
 Case Id Of
  IC_NEW: Begin
   FillBox(Cx-6,Cy-9,Cx+5,Cy+8,CL_WHITE);
   Rect(Cx-6,Cy-9,Cx+5,Cy+8,CL_BLACK);
   For I:=0 To 3 Do LineC(Cx-4,Cy-4+I*3,Cx+3,Cy-4+I*3,CL_DKGRAY);
  End;
  IC_OPEN: Begin
   FillBox(Cx-9,Cy-5,Cx-3,Cy-3,14);
   FillBox(Cx-9,Cy-3,Cx+8,Cy+6,14);
   Rect(Cx-9,Cy-3,Cx+8,Cy+6,CL_BLACK);
   LineC(Cx-9,Cy-5,Cx-3,Cy-5,CL_BLACK);
   LineC(Cx-6,Cy+6,Cx+8,Cy-1,CL_BLACK);
  End;
  IC_SAVE: Begin
   FillBox(Cx-8,Cy-8,Cx+8,Cy+8,CL_BLUE);
   Rect(Cx-8,Cy-8,Cx+8,Cy+8,CL_BLACK);
   FillBox(Cx-5,Cy-8,Cx+5,Cy-2,CL_WHITE);
   FillBox(Cx-5,Cy+2,Cx+5,Cy+8,CL_BG);
   FillBox(Cx+1,Cy+3,Cx+3,Cy+7,CL_BLACK);
  End;
  IC_PRINT: Begin
   FillBox(Cx-5,Cy-9,Cx+5,Cy-2,CL_WHITE);
   Rect(Cx-5,Cy-9,Cx+5,Cy-2,CL_BLACK);
   FillBox(Cx-9,Cy-2,Cx+9,Cy+5,CL_DKGRAY);
   Rect(Cx-9,Cy-2,Cx+9,Cy+5,CL_BLACK);
   FillBox(Cx-5,Cy+3,Cx+5,Cy+9,CL_WHITE);
   Rect(Cx-5,Cy+3,Cx+5,Cy+9,CL_BLACK);
  End;
  IC_CUT: Begin
   LineC(Cx-5,Cy-9,Cx+4,Cy+3,CL_BLACK);
   LineC(Cx+5,Cy-9,Cx-4,Cy+3,CL_BLACK);
   SetColor(CL_BLUE);
   Circle(Cx-5,Cy+6,3);
   Circle(Cx+5,Cy+6,3);
  End;
  IC_COPY: Begin
   FillBox(Cx-8,Cy-8,Cx+2,Cy+3,CL_WHITE);
   Rect(Cx-8,Cy-8,Cx+2,Cy+3,CL_BLACK);
   FillBox(Cx-3,Cy-3,Cx+7,Cy+8,CL_WHITE);
   Rect(Cx-3,Cy-3,Cx+7,Cy+8,CL_BLACK);
  End;
  IC_PASTE: Begin
   FillBox(Cx-8,Cy-8,Cx+4,Cy+8,6);
   Rect(Cx-8,Cy-8,Cx+4,Cy+8,CL_BLACK);
   FillBox(Cx-4,Cy-10,Cx,Cy-6,CL_DKGRAY);
   FillBox(Cx-1,Cy-2,Cx+9,Cy+9,CL_WHITE);
   Rect(Cx-1,Cy-2,Cx+9,Cy+9,CL_BLACK);
  End;
  IC_UNDO: Begin
   SetColor(CL_BLUE);
   SetLineStyle(0,0,3);
   Arc(Cx+1,Cy+1,0,180,6);
   Line(Cx-5,Cy+1,Cx-5,Cy+4);
   SetLineStyle(0,0,1);
   Pts[0].X:=Cx-9; Pts[0].Y:=Cy+1;
   Pts[1].X:=Cx-1; Pts[1].Y:=Cy+1;
   Pts[2].X:=Cx-5; Pts[2].Y:=Cy+7;
   PolyFill(3,Pts,CL_BLUE,CL_BLUE);
  End;
  IC_BOLD: BoldAt(Cx-4,Cy-4,CL_BLACK,'B');
  IC_ITALIC: Begin
   TextAt(Cx-3,Cy-4,CL_BLACK,'I');
   LineC(Cx,Cy-5,Cx-2,Cy+3,CL_BLACK);
  End;
  IC_UNDER: Begin
   TextAt(Cx-4,Cy-5,CL_BLACK,'U');
   LineC(Cx-5,Cy+5,Cx+4,Cy+5,CL_BLACK);
  End;
  IC_LEFT: For I:=0 To 4 Do LineC(Cx-8,Cy-8+I*4,Cx-8+11-(I And 1)*5,Cy-8+I*4,CL_BLACK);
  IC_CENTER: For I:=0 To 4 Do
   LineC(Cx-6+(I And 1)*2,Cy-8+I*4,Cx+6-(I And 1)*2,Cy-8+I*4,CL_BLACK);
  IC_RIGHT: For I:=0 To 4 Do LineC(Cx+8-11+(I And 1)*5,Cy-8+I*4,Cx+8,Cy-8+I*4,CL_BLACK);
  IC_CURR: BoldAt(Cx-4,Cy-4,2,'$');
  IC_COMMA: TextAt(Cx-10,Cy-4,CL_BLACK,'0,0');
  IC_PCT: BoldAt(Cx-4,Cy-4,CL_BLACK,'%');
  IC_SUM: Begin
   SetLineStyle(0,0,1);
   LineC(Cx+5,Cy-8,Cx-5,Cy-8,CL_BLACK);
   LineC(Cx-5,Cy-8,Cx,Cy,CL_BLACK);
   LineC(Cx,Cy,Cx-5,Cy+8,CL_BLACK);
   LineC(Cx-5,Cy+8,Cx+5,Cy+8,CL_BLACK);
   LineC(Cx+5,Cy-8,Cx+5,Cy-5,CL_BLACK);
   LineC(Cx+5,Cy+8,Cx+5,Cy+5,CL_BLACK);
  End;
  IC_ASC: Begin
   TextAt(Cx-9,Cy-9,CL_BLACK,'A');
   TextAt(Cx-9,Cy+2,CL_BLACK,'Z');
   LineC(Cx+5,Cy-8,Cx+5,Cy+7,CL_BLUE);
   LineC(Cx+5,Cy+8,Cx+2,Cy+4,CL_BLUE);
   LineC(Cx+5,Cy+8,Cx+8,Cy+4,CL_BLUE);
  End;
  IC_DESC: Begin
   TextAt(Cx-9,Cy-9,CL_BLACK,'Z');
   TextAt(Cx-9,Cy+2,CL_BLACK,'A');
   LineC(Cx+5,Cy-8,Cx+5,Cy+7,CL_BLUE);
   LineC(Cx+5,Cy+8,Cx+2,Cy+4,CL_BLUE);
   LineC(Cx+5,Cy+8,Cx+8,Cy+4,CL_BLUE);
  End;
  IC_CHART,IC_TBAR: Begin
   FillBox(Cx-8,Cy-1,Cx-4,Cy+8,12);
   FillBox(Cx-3,Cy-8,Cx+1,Cy+8,10);
   FillBox(Cx+2,Cy-4,Cx+6,Cy+8,9);
   Rect(Cx-8,Cy-1,Cx-4,Cy+8,CL_BLACK);
   Rect(Cx-3,Cy-8,Cx+1,Cy+8,CL_BLACK);
   Rect(Cx+2,Cy-4,Cx+6,Cy+8,CL_BLACK);
  End;
  IC_HELP: BoldAt(Cx-4,Cy-4,CL_BLUE,'?');
  IC_GARROW: Begin
   LineC(Cx-8,Cy-8,Cx+7,Cy+7,CL_BLACK);
   LineC(Cx-8,Cy-8,Cx-1,Cy-8,CL_BLACK);
   LineC(Cx-8,Cy-8,Cx-8,Cy-1,CL_BLACK);
  End;
  IC_GLINE: LineC(Cx-8,Cy+8,Cx+8,Cy-8,CL_BLACK);
  IC_GELLIPSE: Begin SetColor(CL_BLACK); Ellipse(Cx,Cy,0,360,9,6); End;
  IC_GRECT: Rect(Cx-8,Cy-6,Cx+8,Cy+6,CL_BLACK);
  IC_GTEXT: BoldAt(Cx-12,Cy-4,CL_BLACK,'abc');
  IC_GSEL: Begin
   Pts[0].X:=Cx-5; Pts[0].Y:=Cy-8;
   Pts[1].X:=Cx-5; Pts[1].Y:=Cy+6;
   Pts[2].X:=Cx-1; Pts[2].Y:=Cy+2;
   Pts[3].X:=Cx+4; Pts[3].Y:=Cy+2;
   PolyFill(3,Pts,CL_BLACK,CL_BLACK);
  End;
  IC_TLINE: Begin
   LineC(Cx-9,Cy+6,Cx-4,Cy-3,12);
   LineC(Cx-4,Cy-3,Cx+1,Cy+3,12);
   LineC(Cx+1,Cy+3,Cx+9,Cy-7,12);
   FillBox(Cx-5,Cy-4,Cx-3,Cy-2,CL_BLACK);
   FillBox(Cx,Cy+2,Cx+2,Cy+4,CL_BLACK);
  End;
  IC_THBAR: Begin
   FillBox(Cx-8,Cy-8,Cx+2,Cy-4,12);
   FillBox(Cx-8,Cy-3,Cx+7,Cy+1,10);
   FillBox(Cx-8,Cy+2,Cx+4,Cy+6,9);
   LineC(Cx-8,Cy-9,Cx-8,Cy+7,CL_BLACK);
  End;
  IC_TSTACK: Begin
   FillBox(Cx-7,Cy-2,Cx-2,Cy+8,12);
   FillBox(Cx-7,Cy-8,Cx-2,Cy-3,10);
   FillBox(Cx+2,Cy+2,Cx+7,Cy+8,12);
   FillBox(Cx+2,Cy-4,Cx+7,Cy+1,10);
  End;
  IC_TAREA: Begin
   Pts[0].X:=Cx-9; Pts[0].Y:=Cy+8;
   Pts[1].X:=Cx-9; Pts[1].Y:=Cy+1;
   Pts[2].X:=Cx-2; Pts[2].Y:=Cy-6;
   Pts[3].X:=Cx+3; Pts[3].Y:=Cy-1;
   Pts[4].X:=Cx+9; Pts[4].Y:=Cy-5;
   Pts[5].X:=Cx+9; Pts[5].Y:=Cy+8;
   PolyFill(6,Pts,10,CL_BLACK);
  End;
  IC_TPIE: Begin
   SetFillStyle(1,12); SetColor(CL_BLACK);
   PieSlice(Cx,Cy,0,120,9);
   SetFillStyle(1,10);
   PieSlice(Cx,Cy,120,250,9);
   SetFillStyle(1,9);
   PieSlice(Cx,Cy,250,360,9);
  End;
  IC_TXY: Begin
   LineC(Cx-9,Cy-9,Cx-9,Cy+8,CL_BLACK);
   LineC(Cx-9,Cy+8,Cx+9,Cy+8,CL_BLACK);
   FillBox(Cx-5,Cy+2,Cx-3,Cy+4,12);
   FillBox(Cx-1,Cy-2,Cx+1,Cy,12);
   FillBox(Cx+3,Cy-6,Cx+5,Cy-4,12);
   FillBox(Cx+5,Cy+3,Cx+7,Cy+5,12);
  End;
  IC_G3D: Begin
   Rect(Cx-8,Cy-3,Cx+3,Cy+8,CL_BLACK);
   LineC(Cx-8,Cy-3,Cx-3,Cy-8,CL_BLACK);
   LineC(Cx+3,Cy-3,Cx+8,Cy-8,CL_BLACK);
   LineC(Cx-3,Cy-8,Cx+8,Cy-8,CL_BLACK);
   LineC(Cx+8,Cy-8,Cx+8,Cy+3,CL_BLACK);
   LineC(Cx+3,Cy+8,Cx+8,Cy+3,CL_BLACK);
  End;
  IC_GBACK: Begin
   LineC(Cx-8,Cy-8,Cx-8,Cy+8,CL_BLACK);
   LineC(Cx-8,Cy-3,Cx+8,Cy-3,CL_BLACK);
   LineC(Cx-8,Cy+3,Cx+8,Cy+3,CL_BLACK);
   LineC(Cx,Cy-8,Cx,Cy+8,CL_BLACK);
   LineC(Cx+8,Cy-8,Cx+8,Cy+8,CL_BLACK);
   LineC(Cx-8,Cy-8,Cx+8,Cy-8,CL_BLACK);
   LineC(Cx-8,Cy+8,Cx+8,Cy+8,CL_BLACK);
  End;
  IC_GFLIP: Begin
   LineC(Cx-8,Cy-5,Cx+6,Cy-5,CL_BLUE);
   LineC(Cx+6,Cy-5,Cx+3,Cy-8,CL_BLUE);
   LineC(Cx+6,Cy-5,Cx+3,Cy-2,CL_BLUE);
   LineC(Cx+8,Cy+5,Cx-6,Cy+5,CL_BLUE);
   LineC(Cx-6,Cy+5,Cx-3,Cy+2,CL_BLUE);
   LineC(Cx-6,Cy+5,Cx-3,Cy+8,CL_BLUE);
  End;
 End;
End;

{ ====================================================================== }
{                  COMMANDES (identifiants)                              }
{ ====================================================================== }

Const
 CM_NONE=0;
 CM_NEW=101; CM_OPEN=102; CM_CLOSE=103; CM_SAVE=104; CM_SAVEAS=105;
 CM_PRINT=106; CM_EXIT=107; CM_PRINTSETUP=108;
 CM_UNDO=110; CM_CUT=111; CM_COPY=112; CM_PASTE=113; CM_PASTESP=114;
 CM_CLEAR=115; CM_CLEARALL=116; CM_FIND=117; CM_GOTO=118; CM_SELALL=119;
 CM_INSROW=120; CM_INSCOL=121; CM_INSSHEET=122; CM_DELROW=123; CM_DELCOL=124;
 CM_DELSHEET=125; CM_COLW=126; CM_ROWH=127; CM_HIDE=128; CM_TITLES=129;
 CM_DEFCOLW=130; CM_AUTOCALC=131; CM_GRIDLINES=132; CM_HEADINGS=133;
 CM_FMT_BASE=140;     { +FM_xxx }
 CM_DECIMALS=155; CM_NAMECREATE=156; CM_NAMEDEL=157; CM_NAMERESET=158;
 CM_TRANSPOSE=159; CM_JUSTIFY=160; CM_PROTECT=161; CM_UNPROTECT=162;
 CM_GNEW=170; CM_GVIEW=171; CM_GADD=172; CM_GUSE=173; CM_GCREATE=174;
 CM_GDELETE=175; CM_GIMPORT=176; CM_GSIZE=177; CM_GREFRESH=178; CM_GGOTO=179;
 CM_FILL=180; CM_SORT=181; CM_QUERY=182; CM_TABLE=183; CM_DIST=184;
 CM_MATRIX=185; CM_REGR=186; CM_PARSE=187;
 CM_BOLD=190; CM_ITALIC=191; CM_UNDERLINE=192; CM_NORMALSTYLE=193;
 CM_TEXTCOLOR=194; CM_BGCOLOR=195; CM_ALIGN_GEN=196; CM_ALIGN_L=197;
 CM_ALIGN_C=198; CM_ALIGN_R=199; CM_BORDER=200; CM_NAMEDSTYLE=201;
 CM_SPELL=210; CM_RECALC=211; CM_ICONS=212; CM_DRAWTOOL=213; CM_MACRO=214;
 CM_USERSETUP=215;
 CM_NEXTSHEET=220; CM_PREVSHEET=221; CM_WINDOC=222;
 CM_HELP=230; CM_ABOUT=231;
 CM_SUM=240; CM_SORTASC=241; CM_SORTDESC=242; CM_CURRENCY=243; CM_COMMA=244;
 CM_PERCENT=245; CM_CHARTWIZ=246;
 CM_GW_CLOSE=300; CM_GW_UNDO=305; CM_GW_DELOBJ=306; CM_GW_CLEARDRAW=307;
 CM_GT_BASE=310;      { +CH_xxx }
 CM_G3D=320; CM_GRANGES=321; CM_GHEADINGS=322; CM_GLEGEND=323; CM_GFRAME=324;
 CM_GGRID_NONE=325; CM_GGRID_H=326; CM_GGRID_V=327; CM_GGRID_BOTH=328;
 CM_GAXIS=329; CM_GMARKERS=330; CM_GLEGTEXT=331;
 CM_GD_SELECT=335; CM_GD_LINE=336; CM_GD_ARROW=337; CM_GD_RECT=338;
 CM_GD_ELLIPSE=339; CM_GD_TEXT=340;
 CM_GR_FLIP=345; CM_GR_DEEPER=346; CM_GR_SHALLOWER=347;
 CM_GS_BG=350; CM_GS_SERCOL=351;      { +1..6 }
 CM_GT_REFRESH=361;

 { Identifiants de menus }
 MN_FILE=1; MN_EDIT=2; MN_WS=3; MN_RANGE=4; MN_GRAPH=5; MN_DATA=6; MN_STYLE=7;
 MN_TOOLS=8; MN_WINDOW=9; MN_HELP=10;
 MG_FILE=21; MG_EDIT=22; MG_CHART=23; MG_DRAW=24; MG_LAYOUT=25; MG_REARR=26;
 MG_STYLE=27; MG_TOOLS=28; MG_WINDOW=29; MG_HELP=30;
 SM_INS=40; SM_DEL=41; SM_GLOBAL=42; SM_NUMFMT=43; SM_NAME=44; SM_GNAME=45;
 SM_FONT=46; SM_LINES=47; SM_ALIGN=48; SM_CTYPE=50; SM_CGRID=51; SM_SERCOL=52;

Const
 M_FILE: Array[1..10] Of TMI = (
  (L:'&New...|Ctrl+N';C:CM_NEW;S:0),
  (L:'&Open...|Ctrl+O';C:CM_OPEN;S:0),
  (L:'&Close';C:CM_CLOSE;S:0),
  (L:'-';C:0;S:0),
  (L:'&Save|Ctrl+S';C:CM_SAVE;S:0),
  (L:'Save &As...';C:CM_SAVEAS;S:0),
  (L:'-';C:0;S:0),
  (L:'&Print...|Ctrl+P';C:CM_PRINT;S:0),
  (L:'-';C:0;S:0),
  (L:'E&xit|Alt+F4';C:CM_EXIT;S:0));
 M_EDIT: Array[1..12] Of TMI = (
  (L:'&Undo|Ctrl+Z';C:CM_UNDO;S:0),
  (L:'-';C:0;S:0),
  (L:'Cu&t|Ctrl+X';C:CM_CUT;S:0),
  (L:'&Copy|Ctrl+C';C:CM_COPY;S:0),
  (L:'&Paste|Ctrl+V';C:CM_PASTE;S:0),
  (L:'Paste &Special...';C:CM_PASTESP;S:0),
  (L:'-';C:0;S:0),
  (L:'Cl&ear|Del';C:CM_CLEAR;S:0),
  (L:'Clear A&ll';C:CM_CLEARALL;S:0),
  (L:'-';C:0;S:0),
  (L:'&Find...';C:CM_FIND;S:0),
  (L:'&Go To...|F5';C:CM_GOTO;S:0));
 M_WS: Array[1..9] Of TMI = (
  (L:'&Insert';C:0;S:SM_INS),
  (L:'&Delete';C:0;S:SM_DEL),
  (L:'-';C:0;S:0),
  (L:'Column &Width...';C:CM_COLW;S:0),
  (L:'Set Row &Height...';C:CM_ROWH;S:0),
  (L:'&Hide...';C:CM_HIDE;S:0),
  (L:'&Titles...';C:CM_TITLES;S:0),
  (L:'-';C:0;S:0),
  (L:'Global &Settings';C:0;S:SM_GLOBAL));
 M_RANGE: Array[1..8] Of TMI = (
  (L:'&Number Format';C:0;S:SM_NUMFMT),
  (L:'&Decimal Places...';C:CM_DECIMALS;S:0),
  (L:'-';C:0;S:0),
  (L:'&Name';C:0;S:SM_NAME),
  (L:'&Transpose...';C:CM_TRANSPOSE;S:0),
  (L:'&Justify';C:CM_JUSTIFY;S:0),
  (L:'&Protect';C:CM_PROTECT;S:0),
  (L:'&Unprotect';C:CM_UNPROTECT;S:0));
 M_GRAPH: Array[1..11] Of TMI = (
  (L:'&New...';C:CM_GNEW;S:0),
  (L:'&View...';C:CM_GVIEW;S:0),
  (L:'-';C:0;S:0),
  (L:'&Add to Sheet...';C:CM_GADD;S:0),
  (L:'&Name';C:0;S:SM_GNAME),
  (L:'-';C:0;S:0),
  (L:'&Import...';C:CM_GIMPORT;S:0),
  (L:'&Size...';C:CM_GSIZE;S:0),
  (L:'&Refresh';C:CM_GREFRESH;S:0),
  (L:'-';C:0;S:0),
  (L:'&Go To...';C:CM_GGOTO;S:0));
 M_DATA: Array[1..10] Of TMI = (
  (L:'&Fill...';C:CM_FILL;S:0),
  (L:'&Sort...';C:CM_SORT;S:0),
  (L:'-';C:0;S:0),
  (L:'&Query...';C:CM_QUERY;S:0),
  (L:'&Table';C:CM_TABLE;S:0),
  (L:'-';C:0;S:0),
  (L:'&Distribution';C:CM_DIST;S:0),
  (L:'&Matrix';C:CM_MATRIX;S:0),
  (L:'&Regression';C:CM_REGR;S:0),
  (L:'&Parse...';C:CM_PARSE;S:0));
 M_STYLE: Array[1..10] Of TMI = (
  (L:'&Font && Attributes';C:0;S:SM_FONT),
  (L:'&Lines && Color';C:0;S:SM_LINES),
  (L:'-';C:0;S:0),
  (L:'&Number Format';C:0;S:SM_NUMFMT),
  (L:'&Alignment';C:0;S:SM_ALIGN),
  (L:'-';C:0;S:0),
  (L:'Column &Width...';C:CM_COLW;S:0),
  (L:'&Row Height...';C:CM_ROWH;S:0),
  (L:'-';C:0;S:0),
  (L:'Named &Style...';C:CM_NAMEDSTYLE;S:0));
 M_TOOLS: Array[1..9] Of TMI = (
  (L:'&Spell Check...';C:CM_SPELL;S:0),
  (L:'-';C:0;S:0),
  (L:'&Recalculate|F9';C:CM_RECALC;S:0),
  (L:'-';C:0;S:0),
  (L:'Smart&Icons';C:CM_ICONS;S:0),
  (L:'&Draw';C:CM_DRAWTOOL;S:0),
  (L:'&Macro';C:CM_MACRO;S:0),
  (L:'-';C:0;S:0),
  (L:'&User Setup...';C:CM_USERSETUP;S:0));
 M_WINDOW: Array[1..5] Of TMI = (
  (L:'&Next Sheet|Ctrl+PgUp';C:CM_NEXTSHEET;S:0),
  (L:'&Previous Sheet|Ctrl+PgDn';C:CM_PREVSHEET;S:0),
  (L:'-';C:0;S:0),
  (L:'&Gridlines';C:CM_GRIDLINES;S:0),
  (L:'&Headings';C:CM_HEADINGS;S:0));
 M_HELP: Array[1..3] Of TMI = (
  (L:'&Help Topics|F1';C:CM_HELP;S:0),
  (L:'-';C:0;S:0),
  (L:'&About 1-2-3...';C:CM_ABOUT;S:0));
 M_INS: Array[1..3] Of TMI = (
  (L:'&Row';C:CM_INSROW;S:0),
  (L:'&Column';C:CM_INSCOL;S:0),
  (L:'&Sheet';C:CM_INSSHEET;S:0));
 M_DEL: Array[1..3] Of TMI = (
  (L:'&Row';C:CM_DELROW;S:0),
  (L:'&Column';C:CM_DELCOL;S:0),
  (L:'&Sheet';C:CM_DELSHEET;S:0));
 M_GLOBAL: Array[1..4] Of TMI = (
  (L:'Default Column &Width...';C:CM_DEFCOLW;S:0),
  (L:'&Automatic Recalc';C:CM_AUTOCALC;S:0),
  (L:'&Gridlines';C:CM_GRIDLINES;S:0),
  (L:'&Headings';C:CM_HEADINGS;S:0));
 M_NUMFMT: Array[1..15] Of TMI = (
  (L:'&General';C:CM_FMT_BASE+FM_GENERAL;S:0),
  (L:'&Fixed';C:CM_FMT_BASE+FM_FIXED;S:0),
  (L:'&Scientific';C:CM_FMT_BASE+FM_SCI;S:0),
  (L:'&Currency';C:CM_FMT_BASE+FM_CURRENCY;S:0),
  (L:'Co&mma (,)';C:CM_FMT_BASE+FM_COMMA;S:0),
  (L:'&Percent';C:CM_FMT_BASE+FM_PERCENT;S:0),
  (L:'+/-  &Bars';C:CM_FMT_BASE+FM_PLUSMINUS;S:0),
  (L:'-';C:0;S:0),
  (L:'Date D-MMM-YY';C:CM_FMT_BASE+FM_DATE1;S:0),
  (L:'Date DD-MMM';C:CM_FMT_BASE+FM_DATE2;S:0),
  (L:'Date MMM-YY';C:CM_FMT_BASE+FM_DATE3;S:0),
  (L:'Date MM/DD/YY';C:CM_FMT_BASE+FM_DATE4;S:0),
  (L:'&Time HH:MM AM/PM';C:CM_FMT_BASE+FM_TIME1;S:0),
  (L:'T&ext (formulas)';C:CM_FMT_BASE+FM_TEXT;S:0),
  (L:'&Hidden';C:CM_FMT_BASE+FM_HIDDEN;S:0));
 M_NAME: Array[1..3] Of TMI = (
  (L:'&Create...';C:CM_NAMECREATE;S:0),
  (L:'&Delete...';C:CM_NAMEDEL;S:0),
  (L:'&Reset (delete all)';C:CM_NAMERESET;S:0));
 M_GNAME: Array[1..3] Of TMI = (
  (L:'&Use...';C:CM_GUSE;S:0),
  (L:'&Create...';C:CM_GCREATE;S:0),
  (L:'&Delete...';C:CM_GDELETE;S:0));
 M_FONT: Array[1..5] Of TMI = (
  (L:'&Bold|Ctrl+B';C:CM_BOLD;S:0),
  (L:'&Italic|Ctrl+I';C:CM_ITALIC;S:0),
  (L:'&Underline|Ctrl+U';C:CM_UNDERLINE;S:0),
  (L:'-';C:0;S:0),
  (L:'&Normal';C:CM_NORMALSTYLE;S:0));
 M_LINES: Array[1..3] Of TMI = (
  (L:'&Text Color...';C:CM_TEXTCOLOR;S:0),
  (L:'&Background Color...';C:CM_BGCOLOR;S:0),
  (L:'&Border...';C:CM_BORDER;S:0));
 M_ALIGN: Array[1..4] Of TMI = (
  (L:'&General';C:CM_ALIGN_GEN;S:0),
  (L:'&Left';C:CM_ALIGN_L;S:0),
  (L:'&Center';C:CM_ALIGN_C;S:0),
  (L:'&Right';C:CM_ALIGN_R;S:0));
 { Fenetre graphique }
 G_FILE: Array[1..8] Of TMI = (
  (L:'&New...';C:CM_GNEW;S:0),
  (L:'&Close';C:CM_GW_CLOSE;S:0),
  (L:'-';C:0;S:0),
  (L:'&Save|Ctrl+S';C:CM_SAVE;S:0),
  (L:'Save &As...';C:CM_SAVEAS;S:0),
  (L:'-';C:0;S:0),
  (L:'&Print...';C:CM_PRINT;S:0),
  (L:'E&xit|Alt+F4';C:CM_EXIT;S:0));
 G_EDIT: Array[1..8] Of TMI = (
  (L:'&Undo';C:CM_GW_UNDO;S:0),
  (L:'-';C:0;S:0),
  (L:'Cu&t';C:CM_CUT;S:0),
  (L:'&Copy';C:CM_COPY;S:0),
  (L:'&Paste';C:CM_PASTE;S:0),
  (L:'-';C:0;S:0),
  (L:'Cl&ear Object|Del';C:CM_GW_DELOBJ;S:0),
  (L:'Clear &All Objects';C:CM_GW_CLEARDRAW;S:0));
 G_CHART: Array[1..8] Of TMI = (
  (L:'&Type';C:0;S:SM_CTYPE),
  (L:'&3D View';C:CM_G3D;S:0),
  (L:'-';C:0;S:0),
  (L:'&Ranges...';C:CM_GRANGES;S:0),
  (L:'&Headings...';C:CM_GHEADINGS;S:0),
  (L:'Legend &Text...';C:CM_GLEGTEXT;S:0),
  (L:'&Axis Scale...';C:CM_GAXIS;S:0),
  (L:'&Name...';C:CM_GCREATE;S:0));
 G_DRAW: Array[1..6] Of TMI = (
  (L:'&Select';C:CM_GD_SELECT;S:0),
  (L:'&Line';C:CM_GD_LINE;S:0),
  (L:'&Arrow';C:CM_GD_ARROW;S:0),
  (L:'&Rectangle';C:CM_GD_RECT;S:0),
  (L:'&Ellipse';C:CM_GD_ELLIPSE;S:0),
  (L:'&Text...';C:CM_GD_TEXT;S:0));
 G_LAYOUT: Array[1..4] Of TMI = (
  (L:'&Legend';C:CM_GLEGEND;S:0),
  (L:'&Frame';C:CM_GFRAME;S:0),
  (L:'&Grid';C:0;S:SM_CGRID),
  (L:'&Markers';C:CM_GMARKERS;S:0));
 G_REARR: Array[1..4] Of TMI = (
  (L:'&Flip Series Order';C:CM_GR_FLIP;S:0),
  (L:'-';C:0;S:0),
  (L:'3D Depth &Larger';C:CM_GR_DEEPER;S:0),
  (L:'3D Depth &Smaller';C:CM_GR_SHALLOWER;S:0));
 G_STYLE: Array[1..2] Of TMI = (
  (L:'&Background Color...';C:CM_GS_BG;S:0),
  (L:'&Series Colors';C:0;S:SM_SERCOL));
 G_TOOLS: Array[1..2] Of TMI = (
  (L:'&Refresh Data';C:CM_GT_REFRESH;S:0),
  (L:'Return to &Worksheet';C:CM_GW_CLOSE;S:0));
 G_WINDOW: Array[1..1] Of TMI = (
  (L:'&Worksheet window';C:CM_GW_CLOSE;S:0));
 S_CTYPE: Array[1..7] Of TMI = (
  (L:'&Line';C:CM_GT_BASE+CH_LINE;S:0),
  (L:'&Bar';C:CM_GT_BASE+CH_BAR;S:0),
  (L:'&Stacked Bar';C:CM_GT_BASE+CH_STACK;S:0),
  (L:'&Horizontal Bar';C:CM_GT_BASE+CH_HBAR;S:0),
  (L:'&Area';C:CM_GT_BASE+CH_AREA;S:0),
  (L:'&Pie';C:CM_GT_BASE+CH_PIE;S:0),
  (L:'&XY';C:CM_GT_BASE+CH_XY;S:0));
 S_CGRID: Array[1..4] Of TMI = (
  (L:'&None';C:CM_GGRID_NONE;S:0),
  (L:'&Horizontal';C:CM_GGRID_H;S:0),
  (L:'&Vertical';C:CM_GGRID_V;S:0),
  (L:'&Both';C:CM_GGRID_BOTH;S:0));
 S_SERCOL: Array[1..6] Of TMI = (
  (L:'Series &1...';C:CM_GS_SERCOL+1;S:0),
  (L:'Series &2...';C:CM_GS_SERCOL+2;S:0),
  (L:'Series &3...';C:CM_GS_SERCOL+3;S:0),
  (L:'Series &4...';C:CM_GS_SERCOL+4;S:0),
  (L:'Series &5...';C:CM_GS_SERCOL+5;S:0),
  (L:'Series &6...';C:CM_GS_SERCOL+6;S:0));
 BAR_SHEET: Array[1..10] Of String[12] = ('&File','&Edit','&Worksheet','&Range',
  '&Graph','&Data','&Style','&Tools','Wi&ndow','&Help');
 BAR_GRAPH: Array[1..10] Of String[12] = ('&File','&Edit','&Chart','&Draw',
  '&Layout','Re&arrange','&Style','&Tools','Wi&ndow','&Help');

Function MenuCount(M: Integer): Integer;
Begin
 Case M Of
  MN_FILE: MenuCount:=10;  MN_EDIT: MenuCount:=12;  MN_WS: MenuCount:=9;
  MN_RANGE: MenuCount:=8;  MN_GRAPH: MenuCount:=11; MN_DATA: MenuCount:=10;
  MN_STYLE: MenuCount:=10; MN_TOOLS: MenuCount:=9;  MN_WINDOW: MenuCount:=5;
  MN_HELP,MG_HELP: MenuCount:=3;
  SM_INS,SM_DEL: MenuCount:=3; SM_GLOBAL: MenuCount:=4; SM_NUMFMT: MenuCount:=15;
  SM_NAME,SM_GNAME: MenuCount:=3; SM_FONT: MenuCount:=5; SM_LINES: MenuCount:=3;
  SM_ALIGN: MenuCount:=4;
  MG_FILE: MenuCount:=8; MG_EDIT: MenuCount:=8; MG_CHART: MenuCount:=8;
  MG_DRAW: MenuCount:=6; MG_LAYOUT: MenuCount:=4; MG_REARR: MenuCount:=4;
  MG_STYLE: MenuCount:=2; MG_TOOLS: MenuCount:=2; MG_WINDOW: MenuCount:=1;
  SM_CTYPE: MenuCount:=7; SM_CGRID: MenuCount:=4; SM_SERCOL: MenuCount:=6;
  Else MenuCount:=0;
 End;
End;

Function MenuItemEn(M,I: Integer): TMI;
Begin
 Case M Of
  MN_FILE: MenuItemEn:=M_FILE[I];
  MN_EDIT: MenuItemEn:=M_EDIT[I];
  MN_WS: MenuItemEn:=M_WS[I];
  MN_RANGE: MenuItemEn:=M_RANGE[I];
  MN_GRAPH: MenuItemEn:=M_GRAPH[I];
  MN_DATA: MenuItemEn:=M_DATA[I];
  MN_STYLE: MenuItemEn:=M_STYLE[I];
  MN_TOOLS: MenuItemEn:=M_TOOLS[I];
  MN_WINDOW: MenuItemEn:=M_WINDOW[I];
  MN_HELP,MG_HELP: MenuItemEn:=M_HELP[I];
  SM_INS: MenuItemEn:=M_INS[I];
  SM_DEL: MenuItemEn:=M_DEL[I];
  SM_GLOBAL: MenuItemEn:=M_GLOBAL[I];
  SM_NUMFMT: MenuItemEn:=M_NUMFMT[I];
  SM_NAME: MenuItemEn:=M_NAME[I];
  SM_GNAME: MenuItemEn:=M_GNAME[I];
  SM_FONT: MenuItemEn:=M_FONT[I];
  SM_LINES: MenuItemEn:=M_LINES[I];
  SM_ALIGN: MenuItemEn:=M_ALIGN[I];
  MG_FILE: MenuItemEn:=G_FILE[I];
  MG_EDIT: MenuItemEn:=G_EDIT[I];
  MG_CHART: MenuItemEn:=G_CHART[I];
  MG_DRAW: MenuItemEn:=G_DRAW[I];
  MG_LAYOUT: MenuItemEn:=G_LAYOUT[I];
  MG_REARR: MenuItemEn:=G_REARR[I];
  MG_STYLE: MenuItemEn:=G_STYLE[I];
  MG_TOOLS: MenuItemEn:=G_TOOLS[I];
  MG_WINDOW: MenuItemEn:=G_WINDOW[I];
  SM_CTYPE: MenuItemEn:=S_CTYPE[I];
  SM_CGRID: MenuItemEn:=S_CGRID[I];
  SM_SERCOL: MenuItemEn:=S_SERCOL[I];
 End;
End;

Function MenuItem(M,I: Integer): TMI;
Var It: TMI;
Begin
 It:=MenuItemEn(M,I);
 It.L:=Copy(Tr(It.L),1,40);
 MenuItem:=It;
End;

{ ====================================================================== }
{                       MENUS : ETAT ET GEOMETRIE                        }
{ ====================================================================== }

Function CurCh: PChart;
Begin
 If (CurChart>=1) And (CurChart<=MAX_CHARTS) Then CurCh:=Charts[CurChart] Else CurCh:=Nil;
End;

Function ChartCount: Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To MAX_CHARTS Do If Charts[I]<>Nil Then Inc(N);
 ChartCount:=N;
End;

Function CmdEnabled(Cmd: Integer): Boolean;
Var Ch: PChart;
Begin
 CmdEnabled:=True;
 Ch:=CurCh;
 Case Cmd Of
  CM_CLOSE,CM_PASTESP,CM_HIDE,CM_TITLES,CM_INSSHEET,CM_DELSHEET,CM_JUSTIFY,
  CM_PROTECT,CM_UNPROTECT,CM_GIMPORT,CM_GSIZE,CM_QUERY,CM_TABLE,CM_DIST,
  CM_MATRIX,CM_REGR,CM_PARSE,CM_BORDER,CM_NAMEDSTYLE,CM_SPELL,CM_DRAWTOOL,
  CM_MACRO,CM_USERSETUP,CM_PRINTSETUP: CmdEnabled:=False;
  CM_UNDO: CmdEnabled:=UndoTop<>Nil;
  CM_CUT,CM_COPY: CmdEnabled:=AppMode=0;
  CM_PASTE: CmdEnabled:=(AppMode=0) And (ClipRows>0);
  CM_GVIEW,CM_GADD,CM_GUSE,CM_GDELETE,CM_GGOTO: CmdEnabled:=ChartCount>0;
  CM_GW_UNDO,CM_GW_DELOBJ,CM_GW_CLEARDRAW: CmdEnabled:=(Ch<>Nil) And (Ch^.NDraw>0);
  CM_PRINT: CmdEnabled:=AppMode=0;
 End;
End;

Function CmdChecked(Cmd: Integer): Boolean;
Var Ch: PChart; P: PCell; T: Integer;
Begin
 CmdChecked:=False;
 Ch:=CurCh;
 P:=CellAt(CurSheet,CurR,CurC);
 Case Cmd Of
  CM_AUTOCALC: CmdChecked:=AutoCalc;
  CM_GRIDLINES: CmdChecked:=ShowGrid;
  CM_HEADINGS: CmdChecked:=ShowHead;
  CM_ICONS: CmdChecked:=ShowTools;
  CM_G3D: CmdChecked:=(Ch<>Nil) And Ch^.ThreeD;
  CM_GLEGEND: CmdChecked:=(Ch<>Nil) And Ch^.ShowLeg;
  CM_GFRAME: CmdChecked:=(Ch<>Nil) And Ch^.Frame;
  CM_GMARKERS: CmdChecked:=(Ch<>Nil) And Ch^.Markers;
  CM_GGRID_NONE: CmdChecked:=(Ch<>Nil) And Not Ch^.GridH And Not Ch^.GridV;
  CM_GGRID_H: CmdChecked:=(Ch<>Nil) And Ch^.GridH And Not Ch^.GridV;
  CM_GGRID_V: CmdChecked:=(Ch<>Nil) And Not Ch^.GridH And Ch^.GridV;
  CM_GGRID_BOTH: CmdChecked:=(Ch<>Nil) And Ch^.GridH And Ch^.GridV;
  CM_GD_SELECT: CmdChecked:=DrawTool=DT_NONE;
  CM_GD_LINE: CmdChecked:=DrawTool=DT_LINE;
  CM_GD_ARROW: CmdChecked:=DrawTool=DT_ARROW;
  CM_GD_RECT: CmdChecked:=DrawTool=DT_RECT;
  CM_GD_ELLIPSE: CmdChecked:=DrawTool=DT_ELLIPSE;
  CM_GD_TEXT: CmdChecked:=DrawTool=DT_TEXT;
  CM_BOLD: CmdChecked:=(P<>Nil) And ((P^.Style And ST_BOLD)<>0);
  CM_ITALIC: CmdChecked:=(P<>Nil) And ((P^.Style And ST_ITALIC)<>0);
  CM_UNDERLINE: CmdChecked:=(P<>Nil) And ((P^.Style And ST_UNDER)<>0);
  CM_ALIGN_GEN: CmdChecked:=(P=Nil) Or (P^.Align=AL_GENERAL);
  CM_ALIGN_L: CmdChecked:=(P<>Nil) And (P^.Align=AL_LEFT);
  CM_ALIGN_C: CmdChecked:=(P<>Nil) And (P^.Align=AL_CENTER);
  CM_ALIGN_R: CmdChecked:=(P<>Nil) And (P^.Align=AL_RIGHT);
 Else
  If (Cmd>=CM_FMT_BASE) And (Cmd<=CM_FMT_BASE+FM_HIDDEN) Then Begin
   T:=Cmd-CM_FMT_BASE;
   If P=Nil Then CmdChecked:=T=FM_GENERAL Else CmdChecked:=P^.Fmt=T;
  End Else If (Cmd>=CM_GT_BASE+1) And (Cmd<=CM_GT_BASE+7) Then
   CmdChecked:=(Ch<>Nil) And (Ch^.CType=Cmd-CM_GT_BASE);
 End;
End;

Function CmdDesc(Cmd: Integer): String;
Begin
 Case Cmd Of
  CM_NEW: CmdDesc:='Create a new worksheet file';
  CM_OPEN: CmdDesc:='Open an existing file';
  CM_SAVE: CmdDesc:='Save the current file';
  CM_SAVEAS: CmdDesc:='Save the current file under a new name';
  CM_PRINT: CmdDesc:='Print the worksheet to a text file';
  CM_EXIT: CmdDesc:='Exit 1-2-3';
  CM_UNDO: CmdDesc:='Undo the last change';
  CM_CUT: CmdDesc:='Move the selected range to the clipboard';
  CM_COPY: CmdDesc:='Copy the selected range to the clipboard';
  CM_PASTE: CmdDesc:='Paste the clipboard contents at the cell pointer';
  CM_CLEAR: CmdDesc:='Erase the contents of the selected range';
  CM_CLEARALL: CmdDesc:='Erase contents and styles of the selected range';
  CM_FIND: CmdDesc:='Find text in the worksheet';
  CM_GOTO: CmdDesc:='Move the cell pointer to a cell address or range name';
  CM_INSROW: CmdDesc:='Insert rows above the selected range';
  CM_INSCOL: CmdDesc:='Insert columns left of the selected range';
  CM_DELROW: CmdDesc:='Delete the rows of the selected range';
  CM_DELCOL: CmdDesc:='Delete the columns of the selected range';
  CM_COLW: CmdDesc:='Change the width of the selected columns';
  CM_ROWH: CmdDesc:='Change the height of the selected rows';
  CM_DEFCOLW: CmdDesc:='Set the default column width';
  CM_AUTOCALC: CmdDesc:='Recalculate formulas automatically';
  CM_GRIDLINES: CmdDesc:='Show or hide the worksheet gridlines';
  CM_HEADINGS: CmdDesc:='Show or hide the row and column headings';
  CM_DECIMALS: CmdDesc:='Set the number of decimal places';
  CM_NAMECREATE: CmdDesc:='Assign a name to the selected range';
  CM_NAMEDEL: CmdDesc:='Delete a range name';
  CM_NAMERESET: CmdDesc:='Delete all range names';
  CM_TRANSPOSE: CmdDesc:='Copy the range, swapping rows and columns';
  CM_GNEW: CmdDesc:='Create and name a graph based on data in the current worksheet';
  CM_GVIEW: CmdDesc:='Display a named graph';
  CM_GADD: CmdDesc:='Place a named graph in the worksheet';
  CM_GUSE: CmdDesc:='Make a named graph current';
  CM_GCREATE: CmdDesc:='Name the current graph';
  CM_GDELETE: CmdDesc:='Delete a named graph';
  CM_GREFRESH: CmdDesc:='Redraw graphs with the latest worksheet data';
  CM_GGOTO: CmdDesc:='Move to a graph placed in the worksheet';
  CM_FILL: CmdDesc:='Fill the selected range with a series of numbers';
  CM_SORT: CmdDesc:='Sort the selected range';
  CM_BOLD: CmdDesc:='Make the selected text bold';
  CM_ITALIC: CmdDesc:='Make the selected text italic';
  CM_UNDERLINE: CmdDesc:='Underline the selected text';
  CM_NORMALSTYLE: CmdDesc:='Remove all text attributes';
  CM_TEXTCOLOR: CmdDesc:='Change the text color of the selected range';
  CM_BGCOLOR: CmdDesc:='Change the background color of the selected range';
  CM_ALIGN_GEN: CmdDesc:='Use the default alignment';
  CM_ALIGN_L: CmdDesc:='Align contents to the left';
  CM_ALIGN_C: CmdDesc:='Center the contents';
  CM_ALIGN_R: CmdDesc:='Align contents to the right';
  CM_RECALC: CmdDesc:='Recalculate all formulas';
  CM_ICONS: CmdDesc:='Show or hide the SmartIcons palette';
  CM_NEXTSHEET: CmdDesc:='Move to the next worksheet';
  CM_PREVSHEET: CmdDesc:='Move to the previous worksheet';
  CM_HELP: CmdDesc:='Display help on using 1-2-3';
  CM_ABOUT: CmdDesc:='Display program information';
  CM_SUM: CmdDesc:='Sum the cells above or to the left';
  CM_CHARTWIZ: CmdDesc:='Create a chart from the selected range';
  CM_GW_CLOSE: CmdDesc:='Return to the worksheet';
  CM_GW_UNDO: CmdDesc:='Remove the last drawn object';
  CM_GW_DELOBJ: CmdDesc:='Delete the last drawn object';
  CM_GW_CLEARDRAW: CmdDesc:='Delete all drawn objects';
  CM_G3D: CmdDesc:='Switch between 2D and 3D display';
  CM_GRANGES: CmdDesc:='Specify the worksheet ranges the graph uses';
  CM_GHEADINGS: CmdDesc:='Enter the titles of the graph';
  CM_GLEGEND: CmdDesc:='Show or hide the legend';
  CM_GLEGTEXT: CmdDesc:='Enter the legend text for each data series';
  CM_GFRAME: CmdDesc:='Show or hide the frame around the graph';
  CM_GAXIS: CmdDesc:='Set the scale of the Y axis';
  CM_GMARKERS: CmdDesc:='Show or hide markers on line graphs';
  CM_GR_FLIP: CmdDesc:='Reverse the order of the data series';
  CM_GS_BG: CmdDesc:='Change the background color of the graph';
  CM_GT_REFRESH: CmdDesc:='Redraw the graph with current data';
  CM_GD_SELECT..CM_GD_TEXT: CmdDesc:='Choose a drawing tool for the graph';
  Else
   If (Cmd>=CM_FMT_BASE) And (Cmd<=CM_FMT_BASE+FM_HIDDEN) Then
    CmdDesc:='Set the number format of the selected range'
   Else If (Cmd>=CM_GT_BASE+1) And (Cmd<=CM_GT_BASE+7) Then
    CmdDesc:='Change the type of the graph'
   Else CmdDesc:='';
 End;
End;

Function MenuIdOf(B: Integer): Integer;
Begin
 MenuIdOf:=B+20*AppMode;
End;

Function BarLabel(B: Integer): String;
Begin
 If AppMode=0 Then BarLabel:=Tr(BAR_SHEET[B]) Else BarLabel:=Tr(BAR_GRAPH[B]);
End;

{ Largeur en pixels du libelle visible (sans & ni raccourci) }
Function LabelW(Const S: String): Integer;
Var I,N: Integer;
Begin
 N:=0;
 I:=1;
 While (I<=Length(S)) And (S[I]<>'|') Do Begin
  If S[I]='&' Then Begin
   If (I<Length(S)) And (S[I+1]='&') Then Begin Inc(N); Inc(I); End;
  End Else Inc(N);
  Inc(I);
 End;
 LabelW:=N*8;
End;

Function ShortW(Const S: String): Integer;
Var P: Integer;
Begin
 P:=Pos('|',S);
 If P=0 Then ShortW:=0 Else ShortW:=(Length(S)-P)*8;
End;

Function BarGap: Integer;
Var I,T,G: Integer;
Begin
 T:=0;
 For I:=1 To 10 Do T:=T+LabelW(BarLabel(I));
 G:=(SCR_W-40-26-T) Div 10;
 If G>16 Then G:=16;
 If G<6 Then G:=6;
 BarGap:=G;
End;

Function BarX(B: Integer): Integer;
Var I,X,G: Integer;
Begin
 X:=26;
 G:=BarGap;
 For I:=1 To B-1 Do X:=X+LabelW(BarLabel(I))+G;
 BarX:=X;
End;

Function BarHit(MX,MY: Integer): Integer;
Var B: Integer;
Begin
 BarHit:=0;
 If (MY<MENU_Y) Or (MY>=MENU_Y+MENU_H) Then Exit;
 For B:=1 To 10 Do
  If (MX>=BarX(B)-5) And (MX<=BarX(B)+LabelW(BarLabel(B))+5) Then Begin BarHit:=B; Exit; End;
End;

Function ItemH(Const It: TMI): Integer;
Begin
 If It.L='-' Then ItemH:=8 Else ItemH:=16;
End;

Procedure PopupGeom(M,X0,Y0: Integer; Var X,Y,W,H: Integer);
Var I,MaxL,MaxS: Integer; It: TMI;
Begin
 MaxL:=0; MaxS:=0; H:=6;
 For I:=1 To MenuCount(M) Do Begin
  It:=MenuItem(M,I);
  If LabelW(It.L)>MaxL Then MaxL:=LabelW(It.L);
  If ShortW(It.L)>MaxS Then MaxS:=ShortW(It.L);
  H:=H+ItemH(It);
 End;
 W:=24+MaxL+16+22;
 If MaxS>0 Then W:=W+MaxS+8;
 X:=X0; Y:=Y0;
 If X+W>SCR_W-3 Then X:=SCR_W-3-W;
End;

Function PopupItemY(M,Y,I: Integer): Integer;
Var K,T: Integer;
Begin
 T:=Y+3;
 For K:=1 To I-1 Do T:=T+ItemH(MenuItem(M,K));
 PopupItemY:=T;
End;

Function PopupItemAt(M,X,Y,W,H,MX,MY: Integer): Integer;
Var I,T: Integer; It: TMI;
Begin
 PopupItemAt:=0;
 If (MX<X) Or (MX>X+W) Or (MY<Y) Or (MY>Y+H) Then Exit;
 T:=Y+3;
 For I:=1 To MenuCount(M) Do Begin
  It:=MenuItem(M,I);
  If (MY>=T) And (MY<T+ItemH(It)) Then Begin PopupItemAt:=I; Exit; End;
  T:=T+ItemH(It);
 End;
End;

Function AltLetter(K2: Char): Char;
Const Scan: String = 'QWERTYUIOP'; Scan2: String = 'ASDFGHJKL'; Scan3: String = 'ZXCVBNM';
Begin
 AltLetter:=#0;
 If (K2>=#16) And (K2<=#25) Then AltLetter:=Scan[Ord(K2)-15]
 Else If (K2>=#30) And (K2<=#38) Then AltLetter:=Scan2[Ord(K2)-29]
 Else If (K2>=#44) And (K2<=#50) Then AltLetter:=Scan3[Ord(K2)-43];
End;

Function ItemEnabled(Const It: TMI): Boolean;
Begin
 If It.L='-' Then ItemEnabled:=False
 Else If It.S>0 Then ItemEnabled:=True
 Else ItemEnabled:=CmdEnabled(It.C);
End;

Function ItemHot(Const L: String): Char;
Var I: Integer;
Begin
 ItemHot:=#0;
 I:=1;
 While I<Length(L) Do Begin
  If L[I]='|' Then Exit;
  If L[I]='&' Then Begin
   If L[I+1]='&' Then Inc(I) Else Begin ItemHot:=UpCase(L[I+1]); Exit; End;
  End;
  Inc(I);
 End;
End;

{ Dessine un libelle avec lettre d'acces soulignee }
Procedure DrawMenuLabel(X,Y: Integer; Const L: String; Color: Integer; Underline: Boolean);
Var I,Tx: Integer; Ch: String;
Begin
 Tx:=X;
 I:=1;
 While (I<=Length(L)) And (L[I]<>'|') Do Begin
  If L[I]='&' Then Begin
   If (I<Length(L)) And (L[I+1]='&') Then Begin
    TextAt(Tx,Y,Color,'&'); Tx:=Tx+8; Inc(I);
   End Else If I<Length(L) Then Begin
    Ch:=L[I+1];
    TextAt(Tx,Y,Color,Ch);
    If Underline Then LineC(Tx,Y+9,Tx+7,Y+9,Color);
    Tx:=Tx+8; Inc(I);
   End;
  End Else Begin
   Ch:=L[I];
   TextAt(Tx,Y,Color,Ch);
   Tx:=Tx+8;
  End;
  Inc(I);
 End;
End;

Procedure DrawPopup(M,X,Y,W,H,Hi: Integer);
Var I,T,Ty: Integer; It: TMI; Col: Integer; En: Boolean; P: Integer; Sh: String;
Begin
 FillBox(X,Y,X+W,Y+H,CL_BG);
 Rect(X,Y,X+W,Y+H,CL_BLACK);
 RaisedFrame(X+1,Y+1,X+W-1,Y+H-1);
 SetColor(CL_DKGRAY);
 Line(X+W+1,Y+3,X+W+1,Y+H+1);
 Line(X+3,Y+H+1,X+W+1,Y+H+1);
 T:=Y+3;
 For I:=1 To MenuCount(M) Do Begin
  It:=MenuItem(M,I);
  If It.L='-' Then Begin
   LineC(X+4,T+3,X+W-4,T+3,CL_DKGRAY);
   LineC(X+4,T+4,X+W-4,T+4,CL_WHITE);
  End Else Begin
   En:=ItemEnabled(It);
   Ty:=T+4;
   If I=Hi Then Begin
    FillBox(X+3,T,X+W-3,T+15,CL_BLUE);
    If En Then Col:=CL_WHITE Else Col:=CL_BG;
   End Else Begin
    If En Then Col:=CL_BLACK Else Col:=CL_DKGRAY;
   End;
   If CmdChecked(It.C) And (It.S=0) Then Begin
    LineC(X+8,Ty+3,X+10,Ty+6,Col);
    LineC(X+10,Ty+6,X+15,Ty,Col);
    LineC(X+8,Ty+4,X+10,Ty+7,Col);
    LineC(X+10,Ty+7,X+15,Ty+1,Col);
   End;
   If (Not En) And (I<>Hi) Then Begin
    DrawMenuLabel(X+25,Ty+1,It.L,CL_WHITE,False);
   End;
   DrawMenuLabel(X+24,Ty,It.L,Col,En Or (I=Hi));
   P:=Pos('|',It.L);
   If P>0 Then Begin
    Sh:=Copy(It.L,P+1,30);
    TextAt(X+W-12-8*Length(Sh),Ty,Col,Sh);
   End;
   If It.S>0 Then Begin
    LineC(X+W-12,Ty+1,X+W-12,Ty+7,Col);
    LineC(X+W-11,Ty+2,X+W-11,Ty+6,Col);
    LineC(X+W-10,Ty+3,X+W-10,Ty+5,Col);
    LineC(X+W-9,Ty+4,X+W-9,Ty+4,Col);
   End;
  End;
  T:=T+ItemH(It);
 End;
End;

Procedure TopGeom(Var X,Y,W,H: Integer);
Begin
 PopupGeom(MenuIdOf(MenuOpen),BarX(MenuOpen)-6,MENU_Y+MENU_H,X,Y,W,H);
End;

Procedure SubGeom(Var X,Y,W,H: Integer);
Var TX,TY,TW,TH,SX: Integer;
Begin
 TopGeom(TX,TY,TW,TH);
 PopupGeom(SubOpen,TX+TW-3,PopupItemY(MenuIdOf(MenuOpen),TY,MenuHi)-3,X,Y,W,H);
 If X<TX+TW-3 Then Begin
  PopupGeom(SubOpen,TX-W+3,PopupItemY(MenuIdOf(MenuOpen),TY,MenuHi)-3,X,Y,W,H);
 End;
End;

Procedure DrawMenuPopups;
Var X,Y,W,H: Integer;
Begin
 If (Not MenuActive) Or (MenuOpen=0) Then Exit;
 TopGeom(X,Y,W,H);
 DrawPopup(MenuIdOf(MenuOpen),X,Y,W,H,MenuHi);
 If SubOpen>0 Then Begin
  SubGeom(X,Y,W,H);
  DrawPopup(SubOpen,X,Y,W,H,SubHi);
 End;
End;

Function BarFromAlt(K2: Char): Integer;
Var L: Char; B: Integer;
Begin
 BarFromAlt:=0;
 L:=AltLetter(K2);
 If L=#0 Then Exit;
 For B:=1 To 10 Do
  If ItemHot(BarLabel(B))=L Then Begin BarFromAlt:=B; Exit; End;
End;

Function CurrentHiCmd: Integer;
Begin
 CurrentHiCmd:=0;
 If (Not MenuActive) Or (MenuOpen=0) Then Exit;
 If (SubOpen>0) And (SubHi>0) Then CurrentHiCmd:=MenuItem(SubOpen,SubHi).C
 Else If MenuHi>0 Then CurrentHiCmd:=MenuItem(MenuIdOf(MenuOpen),MenuHi).C;
End;

{ ====================================================================== }
{                  DESSIN DE LA FEUILLE DE CALCUL                        }
{ ====================================================================== }

Procedure DrawGraphScreen; Forward;
Procedure DrawPlacedCharts; Forward;
Procedure ExecCmd(Cmd: Integer); Forward;

Function DocTitle: String;
Var S: String; I: Integer;
Begin
 If FileName='' Then S:=Tr('Untitled')
 Else Begin
  S:=FileName;
  For I:=Length(S) DownTo 1 Do
   If (S[I]='\') Or (S[I]='/') Then Begin S:=Copy(S,I+1,255); Break; End;
  S:=UpStr(S);
 End;
 DocTitle:=S;
End;

Procedure DrawTriangle(Cx,Cy,Dir,Color: Integer);
{ Dir : 0 haut, 1 bas, 2 gauche, 3 droite }
Var I: Integer;
Begin
 SetColor(Color);
 For I:=0 To 3 Do Begin
  Case Dir Of
   0: Line(Cx-I,Cy+I-2,Cx+I,Cy+I-2);
   1: Line(Cx-I,Cy-I+2,Cx+I,Cy-I+2);
   2: Line(Cx+I-2,Cy-I,Cx+I-2,Cy+I);
   3: Line(Cx-I+2,Cy-I,Cx-I+2,Cy+I);
  End;
 End;
End;

Procedure DrawTitleBar;
Var Desc,T: String; Cmd: Integer;
Begin
 FillBox(0,0,SCR_W-1,TITLE_H-1,CL_BLUE);
 FillBox(3,2,17,15,CL_BG);
 RaisedFrame(3,2,17,15);
 LineC(6,8,14,8,CL_BLACK);
 LineC(6,9,14,9,CL_BLACK);
 Cmd:=CurrentHiCmd;
 Desc:='';
 If Cmd<>0 Then Desc:=CmdDesc(Cmd);
 If Desc<>'' Then BoldAt(26,5,CL_WHITE,Tr(Desc))
 Else Begin
  T:=Tx('1-2-3 for Windows - [','1-2-3 pour Windows - [')+DocTitle;
  If AppMode=1 Then Begin
   If CurCh<>Nil Then T:=Tx('1-2-3 for Windows - [','1-2-3 pour Windows - [')+Tr('Untitled')+' '+CurCh^.Name+']'
                 Else T:=Tx('1-2-3 for Windows - [','1-2-3 pour Windows - [')+Tr('Untitled')+' GRAPH]';
  End Else T:=T+']';
  BoldAt((SCR_W-8*Length(T)) Div 2,5,CL_WHITE,T);
 End;
 FillBox(SCR_W-18,2,SCR_W-4,15,CL_BG);
 RaisedFrame(SCR_W-18,2,SCR_W-4,15);
 DrawTriangle(SCR_W-11,8,1,CL_BLACK);
 FillBox(SCR_W-34,2,SCR_W-20,15,CL_BG);
 RaisedFrame(SCR_W-34,2,SCR_W-20,15);
 DrawTriangle(SCR_W-27,8,0,CL_BLACK);
End;

Procedure DrawMenuBar;
Var B,X,W: Integer; Hot: Boolean;
Begin
 FillBox(0,MENU_Y,SCR_W-1,MENU_Y+MENU_H-1,CL_BG);
 LineC(0,MENU_Y+MENU_H-1,SCR_W-1,MENU_Y+MENU_H-1,CL_DKGRAY);
 FillBox(4,MENU_Y+3,18,MENU_Y+15,CL_BG);
 RaisedFrame(4,MENU_Y+3,18,MENU_Y+15);
 LineC(7,MENU_Y+9,15,MENU_Y+9,CL_BLACK);
 For B:=1 To 10 Do Begin
  X:=BarX(B);
  W:=LabelW(BarLabel(B));
  Hot:=MenuActive And (MenuOpen=B);
  If Hot Then Begin
   FillBox(X-5,MENU_Y+1,X+W+5,MENU_Y+MENU_H-2,CL_BLUE);
   DrawMenuLabel(X,MENU_Y+5,BarLabel(B),CL_WHITE,True);
  End Else DrawMenuLabel(X,MENU_Y+5,BarLabel(B),CL_BLACK,True);
 End;
 FillBox(SCR_W-34,MENU_Y+3,SCR_W-20,MENU_Y+15,CL_BG);
 RaisedFrame(SCR_W-34,MENU_Y+3,SCR_W-20,MENU_Y+15);
 DrawTriangle(SCR_W-27,MENU_Y+9,1,CL_BLACK);
 FillBox(SCR_W-18,MENU_Y+3,SCR_W-4,MENU_Y+15,CL_BG);
 RaisedFrame(SCR_W-18,MENU_Y+3,SCR_W-4,MENU_Y+15);
 DrawTriangle(SCR_W-11,MENU_Y+9,0,CL_BLACK);
End;

Function ModeName: String;
Begin
 If MenuActive Then ModeName:='MENU'
 Else If ParseFail And InputMode Then ModeName:='ERROR'
 Else If InputMode Then Begin
  If InputEdit Then ModeName:='EDIT'
  Else If (InputBuf<>'') And IsValueStart(InputBuf[1]) Then ModeName:='VALUE'
  Else ModeName:='LABEL';
 End Else ModeName:='READY';
End;

Procedure DrawEditLine;
Var P: PCell; S,Ref: String; X: Integer; Ca: Integer;
Begin
 FillBox(0,EDIT_Y,SCR_W-1,EDIT_Y+EDIT_H-1,CL_BG);
 LineC(0,EDIT_Y+EDIT_H-1,SCR_W-1,EDIT_Y+EDIT_H-1,CL_DKGRAY);
 Ref:=SheetLetter(ActSheet)+':'+CellName(CurR,CurC);
 If Not SelIsSingle Then Ref:=Ref+'..'+CellName(SelR2,SelC2);
 FillBox(4,EDIT_Y+2,100,EDIT_Y+EDIT_H-3,CL_BG);
 SunkenFrame(4,EDIT_Y+2,100,EDIT_Y+EDIT_H-3);
 BoldAt(10,EDIT_Y+6,CL_BLACK,Copy(Ref,1,11));
 { boutons annuler / valider }
 If InputMode Then Ca:=CL_BLACK Else Ca:=CL_DKGRAY;
 FillBox(106,EDIT_Y+3,120,EDIT_Y+EDIT_H-4,CL_BG);
 RaisedFrame(106,EDIT_Y+3,120,EDIT_Y+EDIT_H-4);
 LineC(109,EDIT_Y+6,117,EDIT_Y+13,Ca);
 LineC(117,EDIT_Y+6,109,EDIT_Y+13,Ca);
 FillBox(124,EDIT_Y+3,138,EDIT_Y+EDIT_H-4,CL_BG);
 RaisedFrame(124,EDIT_Y+3,138,EDIT_Y+EDIT_H-4);
 LineC(127,EDIT_Y+9,130,EDIT_Y+12,Ca);
 LineC(130,EDIT_Y+12,136,EDIT_Y+6,Ca);
 { zone du contenu }
 X:=146;
 If InputMode Then DrawEditBox(X,EDIT_Y+2,SCR_W-92,EDIT_Y+EDIT_H-3,InputBuf,InputPos,True)
 Else Begin
  P:=CellAt(CurSheet,CurR,CurC);
  S:=CellEditText(P);
  FillBox(X,EDIT_Y+2,SCR_W-92,EDIT_Y+EDIT_H-3,CL_BG);
  SunkenFrame(X,EDIT_Y+2,SCR_W-92,EDIT_Y+EDIT_H-3);
  TextAt(X+4,EDIT_Y+6,CL_BLACK,Copy(S,1,(SCR_W-92-X-6) Div 8));
 End;
 { indicateur de mode }
 FillBox(SCR_W-84,EDIT_Y+2,SCR_W-4,EDIT_Y+EDIT_H-3,CL_BG);
 SunkenFrame(SCR_W-84,EDIT_Y+2,SCR_W-4,EDIT_Y+EDIT_H-3);
 S:=Tr(ModeName);
 If MenuActive Then BoldAt(SCR_W-84+(80-8*Length(S)) Div 2,EDIT_Y+6,CL_BLACK,S)
 Else TextAt(SCR_W-84+(80-8*Length(S)) Div 2,EDIT_Y+6,CL_BLACK,S);
End;

{ ---- Barre d'outils ---- }

Const
 TB_PITCH = 25;
 TB_SHEET_N = 28;
 TB_SHEET_I: Array[1..TB_SHEET_N] Of Integer = (
  IC_NEW,IC_OPEN,IC_SAVE,0,IC_PRINT,0,IC_CUT,IC_COPY,IC_PASTE,IC_UNDO,0,
  IC_BOLD,IC_ITALIC,IC_UNDER,0,IC_LEFT,IC_CENTER,IC_RIGHT,0,IC_CURR,IC_COMMA,IC_PCT,
  0,IC_SUM,IC_ASC,IC_DESC,IC_CHART,IC_HELP);
 TB_SHEET_C: Array[1..TB_SHEET_N] Of Integer = (
  CM_NEW,CM_OPEN,CM_SAVE,0,CM_PRINT,0,CM_CUT,CM_COPY,CM_PASTE,CM_UNDO,0,
  CM_BOLD,CM_ITALIC,CM_UNDERLINE,0,CM_ALIGN_L,CM_ALIGN_C,CM_ALIGN_R,0,CM_CURRENCY,CM_COMMA,CM_PERCENT,
  0,CM_SUM,CM_SORTASC,CM_SORTDESC,CM_CHARTWIZ,CM_HELP);
 TB_GRAPH_N = 19;
 TB_GRAPH_I: Array[1..TB_GRAPH_N] Of Integer = (
  IC_GSEL,IC_GLINE,IC_GARROW,IC_GRECT,IC_GELLIPSE,IC_GTEXT,0,
  IC_TLINE,IC_TBAR,IC_TSTACK,IC_THBAR,IC_TAREA,IC_TPIE,IC_TXY,0,
  IC_G3D,IC_GFLIP,0,IC_GBACK);
 TB_GRAPH_C: Array[1..TB_GRAPH_N] Of Integer = (
  CM_GD_SELECT,CM_GD_LINE,CM_GD_ARROW,CM_GD_RECT,CM_GD_ELLIPSE,CM_GD_TEXT,0,
  CM_GT_BASE+CH_LINE,CM_GT_BASE+CH_BAR,CM_GT_BASE+CH_STACK,CM_GT_BASE+CH_HBAR,
  CM_GT_BASE+CH_AREA,CM_GT_BASE+CH_PIE,CM_GT_BASE+CH_XY,0,
  CM_G3D,CM_GR_FLIP,0,CM_GW_CLOSE);

Function ToolCount: Integer;
Begin
 If AppMode=0 Then ToolCount:=TB_SHEET_N Else ToolCount:=TB_GRAPH_N;
End;

Function ToolIcon(I: Integer): Integer;
Begin
 If AppMode=0 Then ToolIcon:=TB_SHEET_I[I] Else ToolIcon:=TB_GRAPH_I[I];
End;

Function ToolCmd(I: Integer): Integer;
Begin
 If AppMode=0 Then ToolCmd:=TB_SHEET_C[I] Else ToolCmd:=TB_GRAPH_C[I];
End;

Function ToolX(I: Integer): Integer;
Var K,X: Integer;
Begin
 X:=6;
 For K:=1 To I-1 Do If ToolIcon(K)=0 Then X:=X+8 Else X:=X+TB_PITCH;
 ToolX:=X;
End;

Function ToolHit(MX,MY: Integer): Integer;
Var I,X: Integer;
Begin
 ToolHit:=0;
 If Not ShowTools Then Exit;
 If (MY<TOOL_Y+2) Or (MY>TOOL_Y+TOOL_H-3) Then Exit;
 For I:=1 To ToolCount Do Begin
  If ToolIcon(I)=0 Then Continue;
  X:=ToolX(I);
  If (MX>=X) And (MX<X+TB_PITCH-1) Then Begin ToolHit:=I; Exit; End;
 End;
End;

Procedure DrawToolbar;
Var I,X,Cmd: Integer; Down: Boolean;
Begin
 FillBox(0,TOOL_Y,SCR_W-1,TOOL_Y+TOOL_H-1,CL_BG);
 LineC(0,TOOL_Y+TOOL_H-1,SCR_W-1,TOOL_Y+TOOL_H-1,CL_DKGRAY);
 If Not ShowTools Then Exit;
 For I:=1 To ToolCount Do Begin
  If ToolIcon(I)=0 Then Continue;
  X:=ToolX(I);
  Cmd:=ToolCmd(I);
  Down:=False;
  If AppMode=1 Then Down:=CmdChecked(Cmd) And (Cmd<>CM_GW_CLOSE) And (Cmd<>CM_GR_FLIP);
  FillBox(X,TOOL_Y+2,X+TB_PITCH-2,TOOL_Y+TOOL_H-3,CL_BG);
  If Down Then SunkenFrame(X,TOOL_Y+2,X+TB_PITCH-2,TOOL_Y+TOOL_H-3)
  Else RaisedFrame(X,TOOL_Y+2,X+TB_PITCH-2,TOOL_Y+TOOL_H-3);
  DrawIcon(ToolIcon(I),X-1,TOOL_Y+2);
 End;
End;

{ ---- Geometrie de la grille ---- }

Function GX0: Integer;
Begin
 If ShowHead Then GX0:=RH_W Else GX0:=0;
End;

Function GY0: Integer;
Begin
 If ShowHead Then GY0:=GRID_TOP Else GY0:=HDR_Y;
End;

Function ColXOf(C: Integer): Integer;
{ coordonnee X du bord gauche de la colonne C (visible depuis ScrollC) }
Var X,K: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 X:=GX0;
 If C>=ScrollC Then
  For K:=ScrollC To C-1 Do X:=X+ColPx(Sh,K)
 Else
  For K:=C To ScrollC-1 Do X:=X-ColPx(Sh,K);
 ColXOf:=X;
End;

Function RowYOf(R: Integer): Integer;
Var Y,K: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 Y:=GY0;
 If R>=ScrollR Then
  For K:=ScrollR To R-1 Do Y:=Y+RowPx(Sh,K)
 Else
  For K:=R To ScrollR-1 Do Y:=Y-RowPx(Sh,K);
 RowYOf:=Y;
End;

Function LastVisCol: Integer;
Var X,C: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 X:=GX0; C:=ScrollC;
 While (C<MAX_COLS-1) And (X+ColPx(Sh,C)<=GRID_RIGHT) Do Begin X:=X+ColPx(Sh,C); Inc(C); End;
 If C>0 Then If X+ColPx(Sh,C)>GRID_RIGHT+1 Then Dec(C);
 If C<ScrollC Then C:=ScrollC;
 LastVisCol:=C;
End;

Function LastVisRow: Integer;
Var Y,R: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 Y:=GY0; R:=ScrollR;
 While (R<MAX_ROWS-1) And (Y+RowPx(Sh,R)<=GRID_BOTTOM+1) Do Begin Y:=Y+RowPx(Sh,R); Inc(R); End;
 If R>0 Then If Y+RowPx(Sh,R)>GRID_BOTTOM+1 Then Dec(R);
 If R<ScrollR Then R:=ScrollR;
 LastVisRow:=R;
End;

Function GridHitCol(MX: Integer): Integer;
Var X,C: Integer; Sh: PSheet;
Begin
 GridHitCol:=-1;
 If (MX<GX0) Or (MX>GRID_RIGHT) Then Exit;
 Sh:=CurSheet;
 X:=GX0; C:=ScrollC;
 While (C<MAX_COLS) And (X<=GRID_RIGHT) Do Begin
  If (MX>=X) And (MX<X+ColPx(Sh,C)) Then Begin GridHitCol:=C; Exit; End;
  X:=X+ColPx(Sh,C); Inc(C);
 End;
End;

Function GridHitRow(MY: Integer): Integer;
Var Y,R: Integer; Sh: PSheet;
Begin
 GridHitRow:=-1;
 If (MY<GY0) Or (MY>GRID_BOTTOM) Then Exit;
 Sh:=CurSheet;
 Y:=GY0; R:=ScrollR;
 While (R<MAX_ROWS) And (Y<=GRID_BOTTOM) Do Begin
  If (MY>=Y) And (MY<Y+RowPx(Sh,R)) Then Begin GridHitRow:=R; Exit; End;
  Y:=Y+RowPx(Sh,R); Inc(R);
 End;
End;

{ ---- Contenu d'une cellule ---- }

Procedure CellDisplay(Sh: PSheet; P: PCell; C: Integer; W: Integer; Var Txt: String;
                      Var Al: Integer; Var Rep: Boolean);
Var Chars: Integer; V: Double; Pf: Char;
Begin
 Txt:=''; Al:=AL_LEFT; Rep:=False;
 If (P=Nil) Or (P^.Kind=CK_EMPTY) Then Exit;
 Chars:=W Div CHAR_W;
 If Chars<1 Then Chars:=1;
 Case P^.Kind Of
  CK_LABEL: Begin
   Txt:=PStrVal(P^.Txt);
   Pf:=P^.Pfx;
   If Pf='\' Then Rep:=True;
   Case Pf Of
    '"': Al:=AL_RIGHT;
    '^': Al:=AL_CENTER;
    Else Al:=AL_LEFT;
   End;
   If P^.Align<>AL_GENERAL Then Al:=P^.Align;
  End;
  CK_VALUE,CK_FORMULA: Begin
   If (P^.Kind=CK_FORMULA) And (P^.Fmt=FM_TEXT) Then Begin
    Txt:=PStrVal(P^.Txt);
    Al:=AL_LEFT;
    Exit;
   End;
   If P^.Kind=CK_FORMULA Then Begin
    If P^.Err<>0 Then Begin
     If P^.Err=E_NA Then Txt:='NA' Else Txt:='ERR';
     Al:=AL_RIGHT;
     If P^.Align<>AL_GENERAL Then Al:=P^.Align;
     Exit;
    End;
    If P^.IsStr Then Begin
     Txt:=PStrVal(P^.Res);
     Al:=AL_LEFT;
     If P^.Align<>AL_GENERAL Then Al:=P^.Align;
     Exit;
    End;
   End;
   V:=P^.Num;
   If P^.Fmt=FM_HIDDEN Then Begin Txt:=''; Exit; End;
   Txt:=FormatValue(V,P^.Fmt,P^.Dec,Chars-1);
   If (Length(Txt)>Chars) Or ((Length(Txt)>=Chars) And (P^.Fmt<>FM_GENERAL)) Then Txt:=RepStr('*',Chars-1);
   Al:=AL_RIGHT;
   If P^.Align<>AL_GENERAL Then Al:=P^.Align;
  End;
 End;
End;

Procedure DrawStyledText(X,Y,Color: Integer; Const S: String; Style: Byte);
Var I: Integer;
Begin
 If (Style And ST_ITALIC)<>0 Then Begin
  SetViewPort(0,Y-1,SCR_W-1,Y+3,True);
  TextAt(X+1,1-1,Color,S);
  SetViewPort(0,Y+4,SCR_W-1,Y+10,True);
  TextAt(X,-4,Color,S);
  SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 End Else If (Style And ST_BOLD)<>0 Then BoldAt(X,Y,Color,S)
 Else TextAt(X,Y,Color,S);
 If (Style And ST_BOLD)<>0 Then I:=1 Else I:=0;
 If (Style And ST_UNDER)<>0 Then LineC(X,Y+9,X+8*Length(S)-1+I,Y+9,Color);
End;

Procedure DrawCellText(Sh: PSheet; R,C,X,Y,W,H,VisW: Integer);
Var P,Q: PCell; Txt: String; Al,Chars,Avail,K,Tx,Fg: Integer; Rep: Boolean; XX: Integer;
Begin
 P:=CellAt(Sh,R,C);
 If (P=Nil) Or (P^.Kind=CK_EMPTY) Then Exit;
 CellDisplay(Sh,P,C,W,Txt,Al,Rep);
 If Rep Then Begin
  Chars:=W Div CHAR_W;
  Txt:=Copy(RepStr(Txt[1],Chars),1,Chars);
  If Txt='' Then Exit;
 End;
 If Txt='' Then Exit;
 Avail:=W;
 If (Al=AL_LEFT) Or (Al=AL_CENTER) Then Begin
  If (P^.Kind=CK_LABEL) Or ((P^.Kind=CK_FORMULA) And (P^.IsStr Or (P^.Fmt=FM_TEXT))) Then Begin
   K:=C+1;
   XX:=X+W;
   While (K<MAX_COLS) And (XX<=GRID_RIGHT) And (Avail<8*Length(Txt)+4) Do Begin
    Q:=CellAt(Sh,R,K);
    If (Q<>Nil) And (Q^.Kind<>CK_EMPTY) Then Break;
    Avail:=Avail+ColPx(Sh,K);
    XX:=XX+ColPx(Sh,K);
    Inc(K);
   End;
  End;
 End;
 Chars:=(Avail-2) Div CHAR_W;
 If X+Avail>GRID_RIGHT+1 Then Chars:=(GRID_RIGHT+1-X-2) Div CHAR_W;
 If Chars<1 Then Exit;
 If Length(Txt)>Chars Then Txt:=Copy(Txt,1,Chars);
 Case Al Of
  AL_RIGHT: Tx:=X+W-3-8*Length(Txt);
  AL_CENTER: Tx:=X+(Avail-8*Length(Txt)) Div 2;
  Else Tx:=X+3;
 End;
 If Tx<X+1 Then Tx:=X+1;
 If P^.Fg<>CL_NONE Then Fg:=P^.Fg Else Fg:=CL_BLACK;
 If (P^.Kind<>CK_LABEL) And (P^.Kind<>CK_VALUE) And (P^.Err<>0) Then Fg:=4;
 If Y+H-1>GRID_BOTTOM Then Exit;
 DrawStyledText(Tx,Y+(H-8) Div 2,Fg,Txt,P^.Style);
End;

Function InSel(R,C: Integer): Boolean;
Begin
 InSel:=(R>=SelR1) And (R<=SelR2) And (C>=SelC1) And (C<=SelC2);
End;

Procedure DrawGrid;
Var Sh: PSheet; X,Y,W,H,R,C,LR,LC,Bg,Hx: Integer; P: PCell; S: String;
    Sel: Boolean; XS: Array[0..40] Of Integer; N,I: Integer;
Begin
 Sh:=CurSheet;
 FillBox(GX0,GY0,GRID_RIGHT,GRID_BOTTOM,CL_WHITE);
 LR:=LastVisRow;
 LC:=LastVisCol;
 If ShowHead Then Begin
  { en-tetes de colonnes }
  FillBox(0,HDR_Y,SCR_W-1,HDR_Y+HDR_H-1,CL_BG);
  FillBox(0,HDR_Y,RH_W-1,HDR_Y+HDR_H-1,CL_BLUE);
  BoldAt(RH_W Div 2-4,HDR_Y+5,CL_WHITE,SheetLetter(ActSheet));
  X:=GX0;
  For C:=ScrollC To MinI(LC+1,MAX_COLS-1) Do Begin
   W:=ColPx(Sh,C);
   If X>GRID_RIGHT Then Break;
   Hx:=MinI(X+W-1,GRID_RIGHT);
   Sel:=(C>=SelC1) And (C<=SelC2);
   If Sel Then Begin FillBox(X,HDR_Y,Hx,HDR_Y+HDR_H-1,CL_BLUE); RaisedFrame(X,HDR_Y,Hx,HDR_Y+HDR_H-1); End
   Else Begin FillBox(X,HDR_Y,Hx,HDR_Y+HDR_H-1,CL_BG); RaisedFrame(X,HDR_Y,Hx,HDR_Y+HDR_H-1); End;
   S:=ColName(C);
   If W>=8*Length(S)+2 Then Begin
    If Sel Then TextAt(X+(W-8*Length(S)) Div 2,HDR_Y+5,CL_WHITE,S)
           Else TextAt(X+(W-8*Length(S)) Div 2,HDR_Y+5,CL_BLACK,S);
   End;
   X:=X+W;
  End;
  { en-tetes de lignes }
  Y:=GY0;
  For R:=ScrollR To MinI(LR+1,MAX_ROWS-1) Do Begin
   H:=RowPx(Sh,R);
   If Y>GRID_BOTTOM Then Break;
   Hx:=MinI(Y+H-1,GRID_BOTTOM);
   Sel:=(R>=SelR1) And (R<=SelR2);
   FillBox(0,Y,RH_W-1,Hx,CL_BG);
   If Sel Then FillBox(0,Y,RH_W-1,Hx,CL_BLUE);
   RaisedFrame(0,Y,RH_W-1,Hx);
   S:=IntToStr(R+1);
   If H>=11 Then Begin
    If Sel Then TextAt((RH_W-8*Length(S)) Div 2,Y+(H-8) Div 2,CL_WHITE,S)
           Else TextAt((RH_W-8*Length(S)) Div 2,Y+(H-8) Div 2,CL_BLACK,S);
   End;
   Y:=Y+H;
  End;
 End;
 { cellules : fonds puis textes }
 Y:=GY0;
 R:=ScrollR;
 While (R<MAX_ROWS) And (Y<=GRID_BOTTOM) Do Begin
  H:=RowPx(Sh,R);
  N:=0;
  X:=GX0;
  C:=ScrollC;
  While (C<MAX_COLS) And (X<=GRID_RIGHT) Do Begin
   W:=ColPx(Sh,C);
   P:=CellAt(Sh,R,C);
   Bg:=CL_WHITE;
   If (P<>Nil) And (P^.Bg<>CL_NONE) Then Bg:=P^.Bg;
   If InSel(R,C) And Not SelIsSingle Then Begin
    If (R=CurR) And (C=CurC) Then Bg:=CL_WHITE Else Bg:=CL_SEL;
   End;
   FillBox(X,Y,MinI(X+W-1,GRID_RIGHT),MinI(Y+H-1,GRID_BOTTOM),Bg);
   If ShowGrid Then Begin
    SetColor(CL_BG);
    If X+W-1<=GRID_RIGHT Then Line(X+W-1,Y,X+W-1,MinI(Y+H-1,GRID_BOTTOM));
    If Y+H-1<=GRID_BOTTOM Then Line(X,Y+H-1,MinI(X+W-1,GRID_RIGHT),Y+H-1);
   End;
   X:=X+W;
   Inc(C);
  End;
  X:=GX0;
  C:=ScrollC;
  While (C<MAX_COLS) And (X<=GRID_RIGHT) Do Begin
   W:=ColPx(Sh,C);
   DrawCellText(Sh,R,C,X,Y,W,H,0);
   X:=X+W;
   Inc(C);
  End;
  Y:=Y+H;
  Inc(R);
 End;
End;

Procedure DrawSelectionBorder;
Var X1,Y1,X2,Y2: Integer;
Begin
 X1:=ColXOf(CurC); Y1:=RowYOf(CurR);
 X2:=X1+ColPx(CurSheet,CurC)-1; Y2:=Y1+RowPx(CurSheet,CurR)-1;
 If (CurC>=ScrollC) And (CurR>=ScrollR) And (X1<=GRID_RIGHT) And (Y1<=GRID_BOTTOM) Then Begin
  If X2>GRID_RIGHT Then X2:=GRID_RIGHT;
  If Y2>GRID_BOTTOM Then Y2:=GRID_BOTTOM;
  Rect(X1,Y1,X2,Y2,CL_BLACK);
  Rect(X1+1,Y1+1,X2-1,Y2-1,CL_BLACK);
 End;
 If Not SelIsSingle Then Begin
  X1:=ColXOf(MaxI(SelC1,ScrollC));
  Y1:=RowYOf(MaxI(SelR1,ScrollR));
  X2:=ColXOf(SelC2+1)-1;
  Y2:=RowYOf(SelR2+1)-1;
  If X2>GRID_RIGHT Then X2:=GRID_RIGHT;
  If Y2>GRID_BOTTOM Then Y2:=GRID_BOTTOM;
  If (X2>X1) And (Y2>Y1) Then Rect(X1,Y1,X2,Y2,CL_BLUE);
 End;
End;

Procedure DrawScrollBars;
Var TH,TW,Pos: Integer;
Begin
 { verticale }
 FillBox(GRID_RIGHT+1,HDR_Y,SCR_W-1,HSB_Y-1,CL_BG);
 FillBox(GRID_RIGHT+1,GRID_TOP,SCR_W-1,HSB_Y-17,CL_WHITE);
 FillBox(GRID_RIGHT+1,GRID_TOP,SCR_W-1,GRID_TOP+15,CL_BG);
 RaisedFrame(GRID_RIGHT+1,GRID_TOP,SCR_W-1,GRID_TOP+15);
 DrawTriangle(GRID_RIGHT+9,GRID_TOP+8,0,CL_BLACK);
 FillBox(GRID_RIGHT+1,HSB_Y-16,SCR_W-1,HSB_Y-1,CL_BG);
 RaisedFrame(GRID_RIGHT+1,HSB_Y-16,SCR_W-1,HSB_Y-1);
 DrawTriangle(GRID_RIGHT+9,HSB_Y-8,1,CL_BLACK);
 TH:=HSB_Y-17-(GRID_TOP+16)-12;
 Pos:=GRID_TOP+16+(LongInt(ScrollR)*TH) Div (MAX_ROWS-1);
 FillBox(GRID_RIGHT+1,Pos,SCR_W-1,Pos+11,CL_BG);
 RaisedFrame(GRID_RIGHT+1,Pos,SCR_W-1,Pos+11);
 { horizontale }
 FillBox(0,HSB_Y,SCR_W-1,HSB_Y+15,CL_WHITE);
 FillBox(0,HSB_Y,15,HSB_Y+15,CL_BG);
 RaisedFrame(0,HSB_Y,15,HSB_Y+15);
 DrawTriangle(7,HSB_Y+8,2,CL_BLACK);
 FillBox(GRID_RIGHT-15,HSB_Y,GRID_RIGHT,HSB_Y+15,CL_BG);
 RaisedFrame(GRID_RIGHT-15,HSB_Y,GRID_RIGHT,HSB_Y+15);
 DrawTriangle(GRID_RIGHT-8,HSB_Y+8,3,CL_BLACK);
 TW:=GRID_RIGHT-15-16-12;
 Pos:=16+(LongInt(ScrollC)*TW) Div (MAX_COLS-1);
 FillBox(Pos,HSB_Y,Pos+11,HSB_Y+15,CL_BG);
 RaisedFrame(Pos,HSB_Y,Pos+11,HSB_Y+15);
 FillBox(GRID_RIGHT+1,HSB_Y,SCR_W-1,HSB_Y+15,CL_BG);
End;

Function ClockText: String;
Var Y,M,D,DW,H,Mi,S,S100: Word; Ap: String; HH: Integer;
Begin
 GetDate(Y,M,D,DW);
 GetTime(H,Mi,S,S100);
 If H>=12 Then Ap:='PM' Else Ap:='AM';
 HH:=H Mod 12;
 If HH=0 Then HH:=12;
 If (M<1) Or (M>12) Then M:=1;
 ClockText:=TwoDig(D)+'-'+MonthNames[M]+'-'+IntToStr(Y)+' '+TwoDig(HH)+':'+TwoDig(Mi)+' '+Ap;
End;

Procedure DrawStatusBar;
Var X: Integer; S: String;
Begin
 FillBox(0,STAT_Y,SCR_W-1,SCR_H-1,CL_BG);
 LineC(0,STAT_Y,SCR_W-1,STAT_Y,CL_WHITE);
 SunkenFrame(2,STAT_Y+2,150,SCR_H-2);
 SunkenFrame(152,STAT_Y+2,208,SCR_H-2);
 SunkenFrame(210,STAT_Y+2,266,SCR_H-2);
 SunkenFrame(268,STAT_Y+2,324,SCR_H-2);
 SunkenFrame(326,STAT_Y+2,382,SCR_H-2);
 SunkenFrame(384,STAT_Y+2,440,SCR_H-2);
 SunkenFrame(442,STAT_Y+2,640-2,SCR_H-2);
 TextAt(6,STAT_Y+5,CL_BLACK,Copy(Tr(StatusMsg),1,18));
 S:='';
 If CircFound And (AppMode=0) Then S:='CIRC'
 Else If EndMode Then S:=Tr('End');
 TextAt(156,STAT_Y+5,CL_BLACK,S);
 If InsertMode Then TextAt(214,STAT_Y+5,CL_BLACK,Tr('Over'));
 TextAt(272,STAT_Y+5,CL_BLACK,'Num');
 If Not AutoCalc Then TextAt(330,STAT_Y+5,CL_BLACK,Tr('Calc'));
 TextAt(446,STAT_Y+5,CL_BLACK,ClockText);
End;

Procedure DrawSheetScreen;
Begin
 DrawTitleBar;
 DrawMenuBar;
 DrawEditLine;
 DrawToolbar;
 DrawGrid;
 DrawPlacedCharts;
 DrawSelectionBorder;
 DrawScrollBars;
 DrawStatusBar;
End;

Procedure DrawAll;
Begin
 HideMouse;
 If AppMode=0 Then DrawSheetScreen Else DrawGraphScreen;
 DrawMenuPopups;
 ShowMouse;
End;

{ ====================================================================== }
{                       MOTEUR DE GRAPHIQUES                             }
{ ====================================================================== }

Const
 DEF_SCOL: Array[1..NSER] Of Byte = (12,10,9,14,13,5);

Procedure ChartDefaults(Ch: PChart; Const Nm: String);
Var I: Integer;
Begin
 FillChar(Ch^,SizeOf(TChart),0);
 Ch^.Name:=Nm;
 Ch^.CType:=CH_LINE;
 For I:=1 To NSER Do Ch^.SCol[I]:=DEF_SCOL[I];
 Ch^.Bg:=11;
 Ch^.Frame:=True;
 Ch^.Markers:=True;
 Ch^.AutoY:=True;
 Ch^.ShowLeg:=False;
End;

Function FindChart(Const Nm: String): Integer;
Var I: Integer;
Begin
 FindChart:=0;
 For I:=1 To MAX_CHARTS Do
  If (Charts[I]<>Nil) And (UpStr(Charts[I]^.Name)=UpStr(Nm)) Then Begin FindChart:=I; Exit; End;
End;

Function NewChart(Const Nm: String): Integer;
Var I: Integer;
Begin
 NewChart:=0;
 For I:=1 To MAX_CHARTS Do
  If Charts[I]=Nil Then Begin
   New(Charts[I]);
   ChartDefaults(Charts[I],Nm);
   NewChart:=I;
   Exit;
  End;
End;

Procedure DeleteChart(Idx: Integer);
Var I: Integer;
Begin
 If (Idx<1) Or (Idx>MAX_CHARTS) Or (Charts[Idx]=Nil) Then Exit;
 Dispose(Charts[Idx]);
 Charts[Idx]:=Nil;
 For I:=1 To MAX_PLACED Do
  If Placed[I].Used And (Placed[I].Chart=Idx) Then Placed[I].Used:=False;
 If CurChart=Idx Then Begin
  CurChart:=0;
  For I:=1 To MAX_CHARTS Do If (Charts[I]<>Nil) And (CurChart=0) Then CurChart:=I;
 End;
End;

{ Remplit les plages du graphique a partir de la selection courante }
Procedure ChartFromSelection(Ch: PChart);
Var Sh: PSheet; R1,C1,R2,C2,K,C,SC,HR,N: Integer; P: PCell; HasX,HasHdr: Boolean;
    Rr: Integer; Allnum: Boolean;
Begin
 Sh:=CurSheet;
 R1:=SelR1; C1:=SelC1; R2:=SelR2; C2:=SelC2;
 If SelIsSingle Then Begin
  R1:=0; C1:=0; R2:=Sh^.MaxR; C2:=Sh^.MaxC;
  If CellAt(Sh,CurR,CurC)<>Nil Then Begin
   { region contigue autour du curseur : on prend toute la zone utilisee }
  End;
 End;
 If C2-C1>NSER Then C2:=C1+NSER;
 HasX:=False; HasHdr:=False;
 { en-tete : etiquettes sur la premiere ligne (hors premiere colonne) ? }
 For C:=C1+1 To C2 Do Begin
  P:=CellAt(Sh,R1,C);
  If (P<>Nil) And (P^.Kind=CK_LABEL) Then HasHdr:=True;
 End;
 If (C1=C2) Then Begin
  P:=CellAt(Sh,R1,C1);
  If (P<>Nil) And (P^.Kind=CK_LABEL) And (R2>R1) Then HasHdr:=True;
 End;
 HR:=R1;
 If HasHdr Then HR:=R1+1;
 { premiere colonne = etiquettes ? }
 If C2>C1 Then Begin
  N:=0;
  For Rr:=HR To MinI(R2,HR+20) Do Begin
   P:=CellAt(Sh,Rr,C1);
   If (P<>Nil) And (P^.Kind=CK_LABEL) Then Inc(N);
  End;
  If N>0 Then HasX:=True;
 End;
 For K:=1 To NSER Do Begin Ch^.Rng[K]:=''; Ch^.Legend[K]:=''; End;
 Ch^.XRng:='';
 If HasX Then Ch^.XRng:=RangeText(ActSheet,HR,C1,R2,C1);
 SC:=C1;
 If HasX Then SC:=C1+1;
 K:=0;
 For C:=SC To C2 Do Begin
  If K>=NSER Then Break;
  Inc(K);
  Ch^.Rng[K]:=RangeText(ActSheet,HR,C,R2,C);
  If HasHdr Then Begin
   P:=CellAt(Sh,R1,C);
   If (P<>Nil) And (P^.Kind=CK_LABEL) Then Ch^.Legend[K]:=Copy(PStrVal(P^.Txt),1,14);
  End;
 End;
 If Ch^.Title1='' Then Ch^.Title1:='';
End;

{ ---- Chargement des donnees ---- }

Procedure LoadChartData(Ch: PChart);
Var K,I,Sh,R1,C1,R2,C2,R,C,N,Cnt: Integer; V: TVal; S: String; Sv: Integer;
Begin
 If ChD=Nil Then New(ChD);
 FillChar(ChD^,SizeOf(TChData),0);
 N:=0;
 For K:=1 To NSER Do Begin
  If TrimStr(Ch^.Rng[K])='' Then Continue;
  If Not ParseRangeText(Ch^.Rng[K],Sh,R1,C1,R2,C2) Then Continue;
  ChD^.Used[K]:=True;
  Inc(ChD^.S);
  Cnt:=0;
  For R:=R1 To R2 Do
   For C:=C1 To C2 Do
    If Cnt<MAX_PTS Then Begin
     Inc(Cnt);
     V:=CellVal(Sh,R,C);
     If V.K=0 Then ChD^.V[K,Cnt]:=V.N Else ChD^.V[K,Cnt]:=0;
    End;
  If Cnt>N Then N:=Cnt;
 End;
 ChD^.N:=N;
 If (TrimStr(Ch^.XRng)<>'') And ParseRangeText(Ch^.XRng,Sh,R1,C1,R2,C2) Then Begin
  ChD^.HasX:=True;
  Cnt:=0;
  For R:=R1 To R2 Do
   For C:=C1 To C2 Do
    If Cnt<MAX_PTS Then Begin
     Inc(Cnt);
     V:=CellVal(Sh,R,C);
     If V.K=0 Then Begin
      ChD^.X[Cnt]:=V.N;
      ChD^.XLab[Cnt]:=Copy(GeneralStr(V.N,10),1,10);
     End Else Begin
      ChD^.X[Cnt]:=Cnt;
      ChD^.XLab[Cnt]:=Copy(V.S,1,10);
     End;
    End;
  If Cnt>ChD^.N Then ChD^.N:=Cnt;
 End Else
  For I:=1 To ChD^.N Do ChD^.X[I]:=I;
End;

{ ---- Primitives avec decalage ---- }

Procedure cBar(X1,Y1,X2,Y2,Col: Integer);
Begin
 FillBox(X1-OffX,Y1-OffY,X2-OffX,Y2-OffY,Col);
End;

Procedure cRect(X1,Y1,X2,Y2,Col: Integer);
Begin
 Rect(X1-OffX,Y1-OffY,X2-OffX,Y2-OffY,Col);
End;

Procedure cLine(X1,Y1,X2,Y2,Col: Integer);
Begin
 LineC(X1-OffX,Y1-OffY,X2-OffX,Y2-OffY,Col);
End;

Procedure cText(X,Y,Col: Integer; Const S: String);
Begin
 TextAt(X-OffX,Y-OffY,Col,S);
End;

Procedure cPoly(N: Integer; Var Pts: Array Of PointType; Fill,Line_: Integer);
Var T: Array[0..7] Of PointType; I: Integer;
Begin
 For I:=0 To N-1 Do Begin
  T[I].X:=Pts[I].X-OffX;
  T[I].Y:=Pts[I].Y-OffY;
 End;
 PolyFill(N,T,Fill,Line_);
End;

Procedure Quad(X1,Y1,X2,Y2,X3,Y3,X4,Y4,Fill,Line_: Integer);
Var P: Array[0..3] Of PointType;
Begin
 P[0].X:=X1; P[0].Y:=Y1; P[1].X:=X2; P[1].Y:=Y2;
 P[2].X:=X3; P[2].Y:=Y3; P[3].X:=X4; P[3].Y:=Y4;
 cPoly(4,P,Fill,Line_);
End;

Function DarkOf(C: Integer): Integer;
Begin
 If C>=8 Then DarkOf:=C-8 Else DarkOf:=C;
End;

{ ---- Echelle ---- }

Procedure NiceScale(Lo,Hi: Double; Var SMin,SMax,Step: Double);
Var Range,Raw,Mag,R: Double; E: Integer;
Begin
 If Hi<=Lo Then Hi:=Lo+1;
 Range:=Hi-Lo;
 Raw:=Range/5;
 E:=0;
 Mag:=1;
 While Raw/Mag>=10 Do Begin Mag:=Mag*10; Inc(E); End;
 While Raw/Mag<1 Do Begin Mag:=Mag/10; Dec(E); End;
 R:=Raw/Mag;
 If R<=1 Then Step:=1*Mag
 Else If R<=2 Then Step:=2*Mag
 Else If R<=5 Then Step:=5*Mag
 Else Step:=10*Mag;
 SMin:=Int(Lo/Step)*Step;
 If SMin>Lo Then SMin:=SMin-Step;
 SMax:=Int(Hi/Step)*Step;
 If SMax<Hi Then SMax:=SMax+Step;
 If SMax<=SMin Then SMax:=SMin+Step;
End;

Function TickStr(V,Step: Double): String;
Var D: Integer; S: Double;
Begin
 D:=0;
 S:=Abs(Step);
 While (S<0.999) And (D<6) Do Begin S:=S*10; Inc(D); End;
 If Abs(V)<Step/1000 Then V:=0;
 TickStr:=NumToStr(V,D);
End;

Var
 GX1,GY1,GX2,GY2 : Integer;   { zone de trace (avant) }
 GLo,GHi,GStep    : Double;
 GN,GSN,GD        : Integer;
 GOrd             : Array[1..NSER] Of Integer;

Function MapY(V: Double): Integer;
Begin
 MapY:=GY2-Round((V-GLo)/(GHi-GLo)*(GY2-GY1));
End;

Function MapXc(I: Integer): Integer;
Begin
 MapXc:=GX1+Round((I-0.5)*(GX2-GX1)/GN);
End;

Function MapXe(I: Integer): Integer;
Begin
 If GN<=1 Then MapXe:=(GX1+GX2) Div 2
 Else MapXe:=GX1+Round((I-1)*(GX2-GX1)/(GN-1));
End;

{ ---- Cadre 3D ---- }

Procedure Frame3D(Ch: PChart);
Var D: Integer; Y: Double; Yp: Integer;
Begin
 D:=GD;
 Quad(GX1,GY2,GX2,GY2,GX2+D,GY2-D,GX1+D,GY2-D,Ch^.Bg,CL_DKGRAY);
 Quad(GX1,GY1,GX1,GY2,GX1+D,GY2-D,GX1+D,GY1-D,Ch^.Bg,CL_DKGRAY);
 cBar(GX1+D,GY1-D,GX2+D,GY2-D,Ch^.Bg);
 cRect(GX1+D,GY1-D,GX2+D,GY2-D,CL_DKGRAY);
 If Ch^.GridH Then Begin
  Y:=GLo;
  While Y<=GHi+GStep/2 Do Begin
   Yp:=MapY(Y);
   cLine(GX1+D,Yp-D,GX2+D,Yp-D,CL_DKGRAY);
   cLine(GX1,Yp,GX1+D,Yp-D,CL_DKGRAY);
   Y:=Y+GStep;
  End;
 End;
End;

{ ---- Axes 2D ---- }

Procedure Axes2D(Ch: PChart; Horizontal: Boolean);
Var Y: Double; Yp,I,K,LW,Xp: Integer; S: String; Mx: Integer;
Begin
 { axe Y (ou X pour les barres horizontales) }
 If Ch^.GridH And Not Horizontal Then Begin
  Y:=GLo;
  While Y<=GHi+GStep/2 Do Begin
   Yp:=MapY(Y);
   cLine(GX1,Yp,GX2,Yp,CL_DKGRAY);
   Y:=Y+GStep;
  End;
 End;
 If Not Ch^.ThreeD Then Begin
  cLine(GX1,GY1,GX1,GY2,CL_BLACK);
  cLine(GX1,GY2,GX2,GY2,CL_BLACK);
 End;
 If Not Horizontal Then Begin
  Y:=GLo;
  While Y<=GHi+GStep/2 Do Begin
   Yp:=MapY(Y);
   S:=TickStr(Y,GStep);
   cText(GX1-6-8*Length(S),Yp-4,CL_BLACK,S);
   cLine(GX1-3,Yp,GX1,Yp,CL_BLACK);
   Y:=Y+GStep;
  End;
 End;
End;

Procedure XLabels(Ch: PChart; Cat: Boolean);
{ graduations et etiquettes de l'axe X (categories) }
Var I,K,Xp,Mx,Skip: Integer; S: String;
Begin
 Mx:=0;
 If ChD^.HasX Then
  For I:=1 To GN Do If Length(ChD^.XLab[I])>Mx Then Mx:=Length(ChD^.XLab[I]);
 Skip:=1;
 If GN>0 Then Begin
  If Mx>0 Then Skip:=((Mx*8+6)*GN) Div MaxI(1,(GX2-GX1))+1
  Else If GN>60 Then Skip:=GN Div 30;
 End;
 If Skip<1 Then Skip:=1;
 I:=1;
 While I<=GN Do Begin
  If Cat Then Xp:=MapXc(I) Else Xp:=MapXe(I);
  cLine(Xp,GY2,Xp,GY2+3,CL_BLACK);
  If ChD^.HasX Then Begin
   S:=ChD^.XLab[I];
   cText(Xp-4*Length(S),GY2+6,CL_BLACK,S);
  End;
  Inc(I,Skip);
 End;
End;

{ ---- Types de graphiques 2D ---- }

Procedure DrawLine2D(Ch: PChart);
Var K,S,I,X,Y,PX,PY: Integer; Mk: Integer;
Begin
 If GN>60 Then Mk:=1 Else Mk:=2;
 For S:=1 To GSN Do Begin
  K:=GOrd[S];
  PX:=0; PY:=0;
  For I:=1 To GN Do Begin
   X:=MapXc(I); Y:=MapY(ChD^.V[K,I]);
   If I>1 Then Begin
    If GN<=60 Then SetLineStyle(0,0,3);
    cLine(PX,PY,X,Y,Ch^.SCol[K]);
    SetLineStyle(0,0,1);
   End;
   If Ch^.Markers Then cBar(X-Mk,Y-Mk,X+Mk,Y+Mk,Ch^.SCol[K]);
   PX:=X; PY:=Y;
  End;
 End;
End;

Procedure DrawBars2D(Ch: PChart; Stacked: Boolean);
Var K,S,I,X0,BW,Gw,Y0,Y1,Yb: Integer; Acc,V: Double;
Begin
 Gw:=(GX2-GX1) Div GN;
 If Gw<2 Then Gw:=2;
 If Stacked Then BW:=Gw*7 Div 10 Else BW:=Gw*8 Div (10*GSN);
 If BW<1 Then BW:=1;
 Y0:=MapY(0);
 If GLo>0 Then Y0:=GY2;
 For I:=1 To GN Do Begin
  Acc:=0;
  For S:=1 To GSN Do Begin
   K:=GOrd[S];
   V:=ChD^.V[K,I];
   If Stacked Then Begin
    If V<0 Then V:=0;
    Y1:=MapY(Acc+V);
    Yb:=MapY(Acc);
    X0:=GX1+(I-1)*Gw+(Gw-BW) Div 2;
    Acc:=Acc+V;
   End Else Begin
    Y1:=MapY(V);
    Yb:=Y0;
    X0:=GX1+(I-1)*Gw+(Gw-BW*GSN) Div 2+(S-1)*BW;
   End;
   If Y1>Yb Then Begin Yb:=Y1; Y1:=MapY(0); End;
   cBar(X0,Y1,X0+BW-1,Yb,Ch^.SCol[K]);
   cRect(X0,Y1,X0+BW-1,Yb,CL_BLACK);
  End;
 End;
End;

Procedure DrawHBars(Ch: PChart);
Var K,S,I,Y0,BH,Gh,Xv,Xz,X1,X2,YY: Integer; V,F: Double; Xp: Double; Lbl: String;
Begin
 Gh:=(GY2-GY1) Div GN;
 If Gh<2 Then Gh:=2;
 BH:=Gh*8 Div (10*GSN);
 If BH<1 Then BH:=1;
 F:=(GX2-GX1)/(GHi-GLo);
 Xz:=GX1+Round((0-GLo)*F);
 If Xz<GX1 Then Xz:=GX1;
 { axe horizontal des valeurs }
 Xp:=GLo;
 While Xp<=GHi+GStep/2 Do Begin
  Xv:=GX1+Round((Xp-GLo)*F);
  If Ch^.GridV Then cLine(Xv,GY1,Xv,GY2,CL_DKGRAY);
  cLine(Xv,GY2,Xv,GY2+3,CL_BLACK);
  Lbl:=TickStr(Xp,GStep);
  cText(Xv-4*Length(Lbl),GY2+6,CL_BLACK,Lbl);
  Xp:=Xp+GStep;
 End;
 cLine(GX1,GY1,GX1,GY2,CL_BLACK);
 cLine(GX1,GY2,GX2,GY2,CL_BLACK);
 For I:=1 To GN Do Begin
  For S:=1 To GSN Do Begin
   K:=GOrd[S];
   V:=ChD^.V[K,I];
   YY:=GY1+(I-1)*Gh+(Gh-BH*GSN) Div 2+(S-1)*BH;
   Xv:=GX1+Round((V-GLo)*F);
   If Xv>=Xz Then Begin X1:=Xz; X2:=Xv; End Else Begin X1:=Xv; X2:=Xz; End;
   cBar(X1,YY,X2,YY+BH-1,Ch^.SCol[K]);
   cRect(X1,YY,X2,YY+BH-1,CL_BLACK);
  End;
  If ChD^.HasX Then Begin
   Lbl:=ChD^.XLab[I];
   cText(GX1-6-8*Length(Lbl),GY1+(I-1)*Gh+Gh Div 2-4,CL_BLACK,Lbl);
  End;
 End;
End;

Procedure DrawArea2D(Ch: PChart);
Var K,S,I: Integer; Acc: Array[1..MAX_PTS] Of Double; Prev: Array[1..MAX_PTS] Of Double;
    P: Array[0..3] Of PointType;
Begin
 For I:=1 To GN Do Prev[I]:=0;
 For S:=1 To GSN Do Begin
  K:=GOrd[S];
  For I:=1 To GN Do Acc[I]:=Prev[I]+ChD^.V[K,I];
  If GN=1 Then Begin
   cBar(GX1,MapY(Acc[1]),GX2,MapY(Prev[1]),Ch^.SCol[K]);
  End Else
   For I:=1 To GN-1 Do Begin
    P[0].X:=MapXe(I); P[0].Y:=MapY(Prev[I]);
    P[1].X:=MapXe(I); P[1].Y:=MapY(Acc[I]);
    P[2].X:=MapXe(I+1); P[2].Y:=MapY(Acc[I+1]);
    P[3].X:=MapXe(I+1); P[3].Y:=MapY(Prev[I+1]);
    cPoly(4,P,Ch^.SCol[K],Ch^.SCol[K]);
   End;
  For I:=1 To GN Do Prev[I]:=Acc[I];
 End;
End;

Procedure DrawXY2D(Ch: PChart);
Var K,S,I,X,Y,PX,PY: Integer; XLo,XHi,XS,XF: Double; XMn,XMx: Double;
Begin
 XMn:=ChD^.X[1]; XMx:=XMn;
 For I:=1 To GN Do Begin
  If ChD^.X[I]<XMn Then XMn:=ChD^.X[I];
  If ChD^.X[I]>XMx Then XMx:=ChD^.X[I];
 End;
 NiceScale(XMn,XMx,XLo,XHi,XS);
 XF:=(GX2-GX1)/(XHi-XLo);
 { graduations X }
 XMn:=XLo;
 While XMn<=XHi+XS/2 Do Begin
  X:=GX1+Round((XMn-XLo)*XF);
  If Ch^.GridV Then cLine(X,GY1,X,GY2,CL_DKGRAY);
  cLine(X,GY2,X,GY2+3,CL_BLACK);
  cText(X-4*Length(TickStr(XMn,XS)),GY2+6,CL_BLACK,TickStr(XMn,XS));
  XMn:=XMn+XS;
 End;
 For S:=1 To GSN Do Begin
  K:=GOrd[S];
  PX:=0; PY:=0;
  For I:=1 To GN Do Begin
   X:=GX1+Round((ChD^.X[I]-XLo)*XF);
   Y:=MapY(ChD^.V[K,I]);
   If Ch^.Markers Then cBar(X-2,Y-2,X+2,Y+2,Ch^.SCol[K]);
   PX:=X; PY:=Y;
  End;
 End;
End;

Procedure DrawPie(Ch: PChart; X1,Y1,X2,Y2: Integer);
Var Tot,A0,A1,Mid: Double; I,K,Cx,Cy,R,Sa,Ea,Lx,Ly: Integer; Lbl: String; Col: Integer;
    Pal: Array[0..5] Of Integer;
Begin
 Pal[0]:=12; Pal[1]:=10; Pal[2]:=9; Pal[3]:=14; Pal[4]:=13; Pal[5]:=5;
 K:=GOrd[1];
 Tot:=0;
 For I:=1 To GN Do If ChD^.V[K,I]>0 Then Tot:=Tot+ChD^.V[K,I];
 If Tot<=0 Then Exit;
 Cx:=(X1+X2) Div 2;
 Cy:=(Y1+Y2) Div 2;
 R:=MinI((X2-X1) Div 2-34,(Y2-Y1) Div 2-18);
 If R<8 Then R:=8;
 If Ch^.ThreeD Then Begin
  Cy:=Cy-4;
  For I:=8 DownTo 1 Do Begin
   SetFillStyle(1,CL_DKGRAY);
   SetColor(CL_DKGRAY);
   PieSlice(Cx-OffX,Cy+I-OffY,0,360,R);
  End;
 End;
 A0:=0;
 For I:=1 To GN Do Begin
  If ChD^.V[K,I]<=0 Then Continue;
  A1:=A0+ChD^.V[K,I]/Tot*360;
  Sa:=Round(90-A1); Ea:=Round(90-A0);
  While Sa<0 Do Sa:=Sa+360;
  While Ea<0 Do Ea:=Ea+360;
  Col:=Pal[(I-1) Mod 6];
  SetFillStyle(1,Col);
  SetColor(CL_BLACK);
  If (A1-A0)>=359.9 Then PieSlice(Cx-OffX,Cy-OffY,0,360,R)
  Else PieSlice(Cx-OffX,Cy-OffY,Sa,Ea,R);
  Mid:=(A0+A1)/2*Pi/180;
  Lx:=Cx+Round(Sin(Mid)*(R+8));
  Ly:=Cy-Round(Cos(Mid)*(R+8));
  If ChD^.HasX Then Lbl:=ChD^.XLab[I]+' ' Else Lbl:='';
  Lbl:=Lbl+NumToStr(ChD^.V[K,I]/Tot*100,0)+'%';
  If Lx<Cx-4 Then Lx:=Lx-8*Length(Lbl) Else If Lx<=Cx+4 Then Lx:=Lx-4*Length(Lbl);
  If Ly<Cy-4 Then Ly:=Ly-8 Else If Ly>Cy+4 Then Ly:=Ly+2 Else Ly:=Ly-4;
  cText(Lx,Ly,CL_BLACK,Lbl);
  A0:=A1;
 End;
End;

{ ---- Types 3D ---- }

Procedure DrawLine3D(Ch: PChart);
Var K,S,I,X,Y,PX,PY,D0,D1: Integer;
Begin
 For S:=GSN DownTo 1 Do Begin
  K:=GOrd[S];
  D0:=(S-1)*GD Div GSN+GD Div (GSN*5);
  D1:=S*GD Div GSN-GD Div (GSN*5);
  If D1<=D0 Then D1:=D0+2;
  For I:=2 To GN Do Begin
   PX:=MapXc(I-1); PY:=MapY(ChD^.V[K,I-1]);
   X:=MapXc(I); Y:=MapY(ChD^.V[K,I]);
   Quad(PX+D0,PY-D0,X+D0,Y-D0,X+D1,Y-D1,PX+D1,PY-D1,Ch^.SCol[K],CL_BLACK);
  End;
 End;
End;

Procedure DrawArea3D(Ch: PChart);
Var K,S,I,X,Y,D0,D1,YB: Integer; P: Array[0..3] Of PointType;
Begin
 YB:=MapY(0);
 If GLo>0 Then YB:=GY2;
 For S:=GSN DownTo 1 Do Begin
  K:=GOrd[S];
  D0:=(S-1)*GD Div GSN+GD Div (GSN*5);
  D1:=S*GD Div GSN-GD Div (GSN*5);
  If D1<=D0 Then D1:=D0+2;
  For I:=1 To GN-1 Do Begin
   P[0].X:=MapXe(I)+D0; P[0].Y:=YB-D0;
   P[1].X:=MapXe(I)+D0; P[1].Y:=MapY(ChD^.V[K,I])-D0;
   P[2].X:=MapXe(I+1)+D0; P[2].Y:=MapY(ChD^.V[K,I+1])-D0;
   P[3].X:=MapXe(I+1)+D0; P[3].Y:=YB-D0;
   cPoly(4,P,Ch^.SCol[K],Ch^.SCol[K]);
  End;
  For I:=1 To GN-1 Do
   Quad(MapXe(I)+D0,MapY(ChD^.V[K,I])-D0,MapXe(I+1)+D0,MapY(ChD^.V[K,I+1])-D0,
        MapXe(I+1)+D1,MapY(ChD^.V[K,I+1])-D1,MapXe(I)+D1,MapY(ChD^.V[K,I])-D1,
        DarkOf(Ch^.SCol[K]),CL_BLACK);
  X:=MapXe(GN);
  Quad(X+D0,YB-D0,X+D0,MapY(ChD^.V[K,GN])-D0,X+D1,MapY(ChD^.V[K,GN])-D1,X+D1,YB-D1,
       DarkOf(Ch^.SCol[K]),CL_BLACK);
 End;
End;

Procedure DrawBars3D(Ch: PChart);
Var K,S,I,X0,BW,Gw,Y0,Y1,D0,D1: Integer; V: Double;
Begin
 Gw:=(GX2-GX1) Div GN;
 If Gw<3 Then Gw:=3;
 BW:=Gw*6 Div 10;
 If BW<2 Then BW:=2;
 Y0:=MapY(0);
 If GLo>0 Then Y0:=GY2;
 For S:=GSN DownTo 1 Do Begin
  K:=GOrd[S];
  D0:=(S-1)*GD Div GSN+GD Div (GSN*5);
  D1:=S*GD Div GSN-GD Div (GSN*5);
  If D1<=D0 Then D1:=D0+2;
  For I:=1 To GN Do Begin
   V:=ChD^.V[K,I];
   Y1:=MapY(V);
   X0:=GX1+(I-1)*Gw+(Gw-BW) Div 2;
   If Y1>Y0 Then Begin
    cBar(X0+D0,Y0-D0,X0+BW+D0,Y1-D0,Ch^.SCol[K]);
    cRect(X0+D0,Y0-D0,X0+BW+D0,Y1-D0,CL_BLACK);
   End Else Begin
    cBar(X0+D0,Y1-D0,X0+BW+D0,Y0-D0,Ch^.SCol[K]);
    cRect(X0+D0,Y1-D0,X0+BW+D0,Y0-D0,CL_BLACK);
    Quad(X0+D0,Y1-D0,X0+BW+D0,Y1-D0,X0+BW+D1,Y1-D1,X0+D1,Y1-D1,Ch^.SCol[K],CL_BLACK);
    Quad(X0+BW+D0,Y1-D0,X0+BW+D1,Y1-D1,X0+BW+D1,Y0-D1,X0+BW+D0,Y0-D0,DarkOf(Ch^.SCol[K]),CL_BLACK);
   End;
  End;
 End;
End;

{ ---- Legende et objets dessines ---- }

Procedure DrawLegend(Ch: PChart; X1,X2,Y: Integer);
Var S,K,W,X: Integer; T: String;
Begin
 W:=0;
 If Ch^.CType=CH_PIE Then Exit;
 For S:=1 To GSN Do Begin
  K:=GOrd[S];
  T:=Ch^.Legend[K];
  If T='' Then T:=Chr(64+K);
  W:=W+22+8*Length(T);
 End;
 X:=(X1+X2-W) Div 2;
 For S:=1 To GSN Do Begin
  K:=GOrd[S];
  T:=Ch^.Legend[K];
  If T='' Then T:=Chr(64+K);
  cBar(X,Y+1,X+10,Y+7,Ch^.SCol[K]);
  cRect(X,Y+1,X+10,Y+7,CL_BLACK);
  cText(X+14,Y,CL_BLACK,T);
  X:=X+22+8*Length(T);
 End;
End;

Function ArcTan2Safe(Dy,Dx: Double): Double;
Begin
 If Dx=0 Then Begin
  If Dy>=0 Then ArcTan2Safe:=Pi/2 Else ArcTan2Safe:=-Pi/2;
 End Else Begin
  If Dx<0 Then ArcTan2Safe:=ArcTan(Dy/Dx)+Pi Else ArcTan2Safe:=ArcTan(Dy/Dx);
 End;
End;

Procedure DrawChartObjects(Ch: PChart);
Var I: Integer; D: TDraw; Ang: Double; Ax,Ay: Integer;
Begin
 For I:=1 To Ch^.NDraw Do Begin
  D:=Ch^.Draws[I];
  Case D.Kind Of
   DT_LINE: cLine(D.X1,D.Y1,D.X2,D.Y2,D.Col);
   DT_ARROW: Begin
    cLine(D.X1,D.Y1,D.X2,D.Y2,D.Col);
    Ang:=ArcTan2Safe(D.Y2-D.Y1,D.X2-D.X1);
    Ax:=D.X2-Round(10*Cos(Ang-0.4)); Ay:=D.Y2-Round(10*Sin(Ang-0.4));
    cLine(D.X2,D.Y2,Ax,Ay,D.Col);
    Ax:=D.X2-Round(10*Cos(Ang+0.4)); Ay:=D.Y2-Round(10*Sin(Ang+0.4));
    cLine(D.X2,D.Y2,Ax,Ay,D.Col);
   End;
   DT_RECT: cRect(D.X1,D.Y1,D.X2,D.Y2,D.Col);
   DT_ELLIPSE: Begin
    SetColor(D.Col);
    Ellipse((D.X1+D.X2) Div 2-OffX,(D.Y1+D.Y2) Div 2-OffY,0,360,Abs(D.X2-D.X1) Div 2,Abs(D.Y2-D.Y1) Div 2);
   End;
   DT_TEXT: BoldAt(D.X1-OffX,D.Y1-OffY,D.Col,D.Txt);
  End;
 End;
End;

Procedure cBold(X,Y,Col: Integer; Const S: String);
Begin
 BoldAt(X-OffX,Y-OffY,Col,S);
End;

Procedure DrawChart(Ch: PChart; X1,Y1,X2,Y2: Integer);
Var K,S,I,TopM,BotM,LM,RM,Mx,L: Integer; Lo,Hi,Acc,V: Double; Eff: Byte; Sm,Sx,St: Double;
    Y: Double; T: String; Is3D: Boolean;
Begin
 LoadChartData(Ch);
 cBar(X1,Y1,X2,Y2,Ch^.Bg);
 If Ch^.Frame Then cRect(X1,Y1,X2,Y2,CL_BLACK);
 TopM:=8;
 If Ch^.Title1<>'' Then Begin
  cBold((X1+X2-8*Length(Ch^.Title1)) Div 2,Y1+6,CL_BLACK,Ch^.Title1);
  TopM:=24;
 End;
 If Ch^.Title2<>'' Then Begin
  cText((X1+X2-8*Length(Ch^.Title2)) Div 2,Y1+TopM-2,CL_BLACK,Ch^.Title2);
  TopM:=TopM+14;
 End;
 GSN:=0;
 For K:=1 To NSER Do If ChD^.Used[K] Then Begin Inc(GSN); GOrd[GSN]:=K; End;
 GN:=ChD^.N;
 If (GSN=0) Or (GN=0) Then Begin
  T:=Tr('(No data to graph)');
  cText((X1+X2-8*Length(T)) Div 2,(Y1+Y2) Div 2-4,CL_BLACK,T);
  Exit;
 End;
 BotM:=20;
 If Ch^.XTitle<>'' Then BotM:=BotM+12;
 If Ch^.ShowLeg And (Ch^.CType<>CH_PIE) Then BotM:=BotM+16;
 If Ch^.CType=CH_PIE Then Begin
  DrawPie(Ch,X1,Y1+TopM-4,X2,Y2-BotM+14);
  Exit;
 End;
 Is3D:=Ch^.ThreeD And (Ch^.CType In [CH_LINE,CH_BAR,CH_STACK,CH_AREA]);
 Eff:=Ch^.CType;
 If Is3D And (Eff=CH_STACK) Then Eff:=CH_BAR;
 { echelle }
 Lo:=ChD^.V[GOrd[1],1]; Hi:=Lo;
 If Eff=CH_XY Then Begin End;
 For I:=1 To GN Do Begin
  Acc:=0;
  For S:=1 To GSN Do Begin
   V:=ChD^.V[GOrd[S],I];
   If (Eff=CH_STACK) Or ((Eff=CH_AREA) And Not Is3D) Then Begin
    Acc:=Acc+V;
    If Acc>Hi Then Hi:=Acc;
    If Acc<Lo Then Lo:=Acc;
   End Else Begin
    If V>Hi Then Hi:=V;
    If V<Lo Then Lo:=V;
   End;
  End;
 End;
 If Eff In [CH_BAR,CH_STACK,CH_HBAR,CH_AREA] Then Begin
  If Lo>0 Then Lo:=0;
  If Hi<0 Then Hi:=0;
 End;
 If Not Ch^.AutoY Then Begin Lo:=Ch^.YMin; Hi:=Ch^.YMax; End;
 NiceScale(Lo,Hi,Sm,Sx,St);
 GLo:=Sm; GHi:=Sx; GStep:=St;
 If Not Ch^.AutoY Then Begin GLo:=Ch^.YMin; GHi:=Ch^.YMax; If GHi<=GLo Then GHi:=GLo+1; End;
 { marges }
 Mx:=0;
 If Eff=CH_HBAR Then Begin
  If ChD^.HasX Then For I:=1 To GN Do If Length(ChD^.XLab[I])>Mx Then Mx:=Length(ChD^.XLab[I]);
 End Else Begin
  Y:=GLo;
  While Y<=GHi+GStep/2 Do Begin
   L:=Length(TickStr(Y,GStep));
   If L>Mx Then Mx:=L;
   Y:=Y+GStep;
  End;
 End;
 LM:=10+8*Mx+6;
 RM:=14;
 GX1:=X1+LM; GX2:=X2-RM; GY1:=Y1+TopM; GY2:=Y2-BotM;
 GD:=0;
 If Is3D Then Begin
  GD:=Ch^.Depth;
  If GD<=0 Then GD:=MinI(GX2-GX1,GY2-GY1) Div 14;
  If GD<10 Then GD:=10;
  If GD>30 Then GD:=30;
  GX2:=GX2-GD;
  GY1:=GY1+GD;
  Frame3D(Ch);
 End;
 If Ch^.YTitle<>'' Then cText(GX1-4,GY1-GD-12,CL_BLACK,Ch^.YTitle);
 Axes2D(Ch,Eff=CH_HBAR);
 Case Eff Of
  CH_LINE: Begin
   If Is3D Then DrawLine3D(Ch) Else DrawLine2D(Ch);
   XLabels(Ch,True);
  End;
  CH_BAR,CH_STACK: Begin
   If Is3D Then DrawBars3D(Ch) Else DrawBars2D(Ch,Eff=CH_STACK);
   XLabels(Ch,True);
  End;
  CH_HBAR: DrawHBars(Ch);
  CH_AREA: Begin
   If Is3D Then DrawArea3D(Ch) Else DrawArea2D(Ch);
   XLabels(Ch,False);
  End;
  CH_XY: DrawXY2D(Ch);
 End;
 If Ch^.XTitle<>'' Then
  cText((GX1+GX2) Div 2-4*Length(Ch^.XTitle),GY2+20,CL_BLACK,Ch^.XTitle);
 If Ch^.ShowLeg Then DrawLegend(Ch,X1,X2,Y2-16);
End;

Procedure DrawPlacedCharts;
Var I,X1,Y1,X2,Y2: Integer; Ch: PChart;
Begin
 For I:=1 To MAX_PLACED Do Begin
  If (Not Placed[I].Used) Or (Placed[I].Sheet<>ActSheet) Then Continue;
  Ch:=Charts[Placed[I].Chart];
  If Ch=Nil Then Continue;
  If (Placed[I].C2<ScrollC) Or (Placed[I].R2<ScrollR) Then Continue;
  X1:=ColXOf(Placed[I].C1); Y1:=RowYOf(Placed[I].R1);
  X2:=ColXOf(Placed[I].C2+1)-1; Y2:=RowYOf(Placed[I].R2+1)-1;
  If (X1>GRID_RIGHT) Or (Y1>GRID_BOTTOM) Then Continue;
  SetViewPort(GX0,GY0,GRID_RIGHT,GRID_BOTTOM,True);
  OffX:=GX0; OffY:=GY0;
  DrawChart(Ch,X1,Y1,X2,Y2);
  OffX:=0; OffY:=0;
  SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
  SetLineStyle(0,0,1);
 End;
End;

{ ---- Fenetre graphique ---- }

Const
 GP_X1 = 24;
 GP_Y1 = 92;
 GP_X2 = 616;
 GP_Y2 = 454;

Procedure DrawGraphScreen;
Var Ch: PChart;
Begin
 DrawTitleBar;
 DrawMenuBar;
 FillBox(0,EDIT_Y,SCR_W-1,EDIT_Y+EDIT_H-1,CL_BG);
 LineC(0,EDIT_Y+EDIT_H-1,SCR_W-1,EDIT_Y+EDIT_H-1,CL_DKGRAY);
 Ch:=CurCh;
 SunkenFrame(4,EDIT_Y+2,100,EDIT_Y+EDIT_H-3);
 If Ch<>Nil Then BoldAt(10,EDIT_Y+6,CL_BLACK,Copy(Ch^.Name,1,11));
 SunkenFrame(SCR_W-84,EDIT_Y+2,SCR_W-4,EDIT_Y+EDIT_H-3);
 If MenuActive Then BoldAt(SCR_W-84+(80-32) Div 2,EDIT_Y+6,CL_BLACK,'MENU')
 Else TextAt(SCR_W-84+(80-40) Div 2,EDIT_Y+6,CL_BLACK,'READY');
 DrawToolbar;
 FillBox(0,HDR_Y,SCR_W-1,STAT_Y-1,CL_BG);
 If Ch<>Nil Then Begin
  OffX:=0; OffY:=0;
  DrawChart(Ch,GP_X1,GP_Y1,GP_X2,GP_Y2);
  DrawChartObjects(Ch);
 End;
 DrawStatusBar;
End;

{ ====================================================================== }
{                       BOITES DE DIALOGUE                               }
{ ====================================================================== }

Var
 FormLbl  : Array[1..8] Of String[24];
 FormVal  : Array[1..8] Of String[40];
 ListItem : Array[1..80] Of String[30];

{ Attend une touche ou un clic. Retourne True si touche. }
Function WaitInput(Var K1,K2: Char): Boolean;
Begin
 K1:=#0; K2:=#0;
 While True Do Begin
  UpdateMouse;
  If KeyPressed Then Begin
   K1:=ReadKey;
   If K1=#0 Then K2:=ReadKey;
   If (K1=#255) Then Continue;
   WaitInput:=True;
   Exit;
  End;
  If LeftPressed Then Begin WaitInput:=False; Exit; End;
  Delay(2);
 End;
End;

Procedure EditKey(Var S: String; Var Pos: Integer; Var Fresh: Boolean; MaxLen: Integer; K1,K2: Char);
Begin
 If K1=#0 Then Begin
  Case K2 Of
   K_LEFT: Begin If Pos>1 Then Dec(Pos); Fresh:=False; End;
   K_RIGHT: Begin If Pos<=Length(S) Then Inc(Pos); Fresh:=False; End;
   K_HOME: Begin Pos:=1; Fresh:=False; End;
   K_END: Begin Pos:=Length(S)+1; Fresh:=False; End;
   K_DEL: Begin
    If Fresh Then Begin S:=''; Pos:=1; Fresh:=False; End
    Else If Pos<=Length(S) Then Delete(S,Pos,1);
   End;
  End;
 End Else Begin
  If K1=#8 Then Begin
   If Fresh Then Begin S:=''; Pos:=1; Fresh:=False; End
   Else If Pos>1 Then Begin Delete(S,Pos-1,1); Dec(Pos); End;
  End Else If K1>=' ' Then Begin
   If Fresh Then Begin S:=''; Pos:=1; Fresh:=False; End;
   If Length(S)<MaxLen Then Begin Insert(K1,S,Pos); Inc(Pos); End;
  End;
 End;
End;

Procedure MessageBox(Const Title,Msg: String);
Var Lines: Array[0..7] Of String[70]; N,I,MaxW,W,H,X1,Y1,X2,Y2: Integer; K1,K2: Char; Done: Boolean;
    T: String; P: Integer;
Begin
 T:=Msg; N:=0; MaxW:=0;
 While (T<>'') And (N<8) Do Begin
  P:=Pos('|',T);
  If P=0 Then Begin Lines[N]:=Copy(Tr(T),1,70); T:=''; End
  Else Begin Lines[N]:=Copy(Tr(Copy(T,1,P-1)),1,70); Delete(T,1,P); End;
  If Length(Lines[N])>MaxW Then MaxW:=Length(Lines[N]);
  Inc(N);
 End;
 W:=MaxI(MaxW*8+48,200);
 H:=60+N*14+30;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 DrawAll;
 HideMouse;
 DlgFrame(X1,Y1,X2,Y2,Title);
 For I:=0 To N-1 Do TextAt(X1+24,Y1+34+I*14,CL_BLACK,Lines[I]);
 DrawButton((X1+X2) Div 2-36,Y2-34,(X1+X2) Div 2+36,Y2-12,'OK',True);
 ShowMouse;
 Done:=False;
 While Not Done Do Begin
  If WaitInput(K1,K2) Then Begin
   If (K1=#13) Or (K1=#27) Or (K1=' ') Then Done:=True;
  End Else If InBox(Mouse.X,Mouse.Y,(X1+X2) Div 2-36,Y2-34,(X1+X2) Div 2+36,Y2-12) Then Done:=True;
 End;
 NeedRedraw:=True;
End;

{ Oui / Non / Annuler : retourne 1, 2 ou 0 }
Function ConfirmDialog(Const Title,Msg: String): Integer;
Var W,H,X1,Y1,X2,Y2,Bx: Integer; K1,K2: Char; Done: Boolean; Res: Integer;
Begin
 W:=MaxI(Length(Msg)*8+48,280);
 H:=116;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 DrawAll;
 HideMouse;
 DlgFrame(X1,Y1,X2,Y2,Title);
 TextAt(X1+24,Y1+38,CL_BLACK,Tr(Msg));
 Bx:=(X1+X2) Div 2-110;
 DrawButton(Bx,Y2-38,Bx+64,Y2-16,'Yes',True);
 DrawButton(Bx+78,Y2-38,Bx+142,Y2-16,'No',False);
 DrawButton(Bx+156,Y2-38,Bx+220,Y2-16,'Cancel',False);
 ShowMouse;
 Done:=False; Res:=0;
 While Not Done Do Begin
  If WaitInput(K1,K2) Then Begin
   Case UpCase(K1) Of
    'Y','O',#13: Begin Res:=1; Done:=True; End;
    'N': Begin Res:=2; Done:=True; End;
    #27: Begin Res:=0; Done:=True; End;
   End;
  End Else Begin
   If InBox(Mouse.X,Mouse.Y,Bx,Y2-38,Bx+64,Y2-16) Then Begin Res:=1; Done:=True; End
   Else If InBox(Mouse.X,Mouse.Y,Bx+78,Y2-38,Bx+142,Y2-16) Then Begin Res:=2; Done:=True; End
   Else If InBox(Mouse.X,Mouse.Y,Bx+156,Y2-38,Bx+220,Y2-16) Then Begin Res:=0; Done:=True; End;
  End;
 End;
 NeedRedraw:=True;
 ConfirmDialog:=Res;
End;

Function InputDialog(Const Title,Prompt: String; Var S: String; MaxLen: Integer): Boolean;
Var X1,Y1,X2,Y2,W,Pos: Integer; K1,K2: Char; Done,Fresh,Ok: Boolean; T: String;
Begin
 W:=MaxI(MaxI(Length(Prompt)*8,MaxLen*8)+56,300);
 If W>SCR_W-20 Then W:=SCR_W-20;
 X1:=(SCR_W-W) Div 2; Y1:=170; X2:=X1+W; Y2:=Y1+130;
 T:=S; Pos:=Length(T)+1; Fresh:=True; Done:=False; Ok:=False;
 While Not Done Do Begin
  DrawAll;
  HideMouse;
  DlgFrame(X1,Y1,X2,Y2,Title);
  TextAt(X1+16,Y1+34,CL_BLACK,Tr(Prompt));
  DrawEditBox(X1+16,Y1+52,X2-16,Y1+72,T,Pos,True);
  DrawButton(X2-176,Y2-34,X2-104,Y2-12,'OK',True);
  DrawButton(X2-92,Y2-34,X2-20,Y2-12,'Cancel',False);
  ShowMouse;
  If WaitInput(K1,K2) Then Begin
   If K1=#13 Then Begin Ok:=True; Done:=True; End
   Else If K1=#27 Then Done:=True
   Else EditKey(T,Pos,Fresh,MaxLen,K1,K2);
  End Else Begin
   If InBox(Mouse.X,Mouse.Y,X2-176,Y2-34,X2-104,Y2-12) Then Begin Ok:=True; Done:=True; End
   Else If InBox(Mouse.X,Mouse.Y,X2-92,Y2-34,X2-20,Y2-12) Then Done:=True;
  End;
 End;
 If Ok Then S:=T;
 NeedRedraw:=True;
 InputDialog:=Ok;
End;

{ Formulaire de N champs (FormLbl/FormVal) }
Function FormDialog(Const Title: String; N: Integer): Boolean;
Var X1,Y1,X2,Y2,W,H,I,Cur,LW,Pos: Integer; K1,K2: Char; Done,Fresh,Ok: Boolean;
    Pp: Array[1..8] Of Integer; Tmp: String;
Begin
 LW:=0;
 For I:=1 To N Do If Length(FormLbl[I])>LW Then LW:=Length(FormLbl[I]);
 W:=LW*8+40*8 Div 2+60;
 If W<360 Then W:=360;
 H:=70+N*28+40;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 Cur:=1; Fresh:=True; Done:=False; Ok:=False;
 For I:=1 To N Do Pp[I]:=Length(FormVal[I])+1;
 While Not Done Do Begin
  DrawAll;
  HideMouse;
  DlgFrame(X1,Y1,X2,Y2,Title);
  For I:=1 To N Do Begin
   TextAt(X1+16,Y1+38+(I-1)*28,CL_BLACK,Tr(FormLbl[I]));
   DrawEditBox(X1+24+LW*8,Y1+32+(I-1)*28,X2-16,Y1+52+(I-1)*28,FormVal[I],Pp[I],I=Cur);
  End;
  DrawButton(X2-176,Y2-34,X2-104,Y2-12,'OK',True);
  DrawButton(X2-92,Y2-34,X2-20,Y2-12,'Cancel',False);
  ShowMouse;
  If WaitInput(K1,K2) Then Begin
   If K1=#27 Then Done:=True
   Else If K1=#13 Then Begin
    If Cur<N Then Begin Inc(Cur); Fresh:=True; End Else Begin Ok:=True; Done:=True; End;
   End Else If (K1=#9) Or ((K1=#0) And (K2=K_DOWN)) Then Begin
    If Cur<N Then Inc(Cur) Else Cur:=1;
    Fresh:=True;
   End Else If (K1=#0) And ((K2=K_UP) Or (K2=K_SHIFT_TAB)) Then Begin
    If Cur>1 Then Dec(Cur) Else Cur:=N;
    Fresh:=True;
   End Else Begin
    Pos:=Pp[Cur];
    Tmp:=FormVal[Cur];
    EditKey(Tmp,Pos,Fresh,38,K1,K2);
    FormVal[Cur]:=Copy(Tmp,1,40);
    Pp[Cur]:=Pos;
   End;
  End Else Begin
   If InBox(Mouse.X,Mouse.Y,X2-176,Y2-34,X2-104,Y2-12) Then Begin Ok:=True; Done:=True; End
   Else If InBox(Mouse.X,Mouse.Y,X2-92,Y2-34,X2-20,Y2-12) Then Done:=True
   Else For I:=1 To N Do
    If InBox(Mouse.X,Mouse.Y,X1+24+LW*8,Y1+32+(I-1)*28,X2-16,Y1+52+(I-1)*28) Then Begin
     Cur:=I; Fresh:=False;
    End;
  End;
 End;
 NeedRedraw:=True;
 FormDialog:=Ok;
End;

{ Liste de choix (ListItem[1..N]). Retourne l'index ou 0 }
Function ListDialog(Const Title: String; N: Integer; Sel0: Integer): Integer;
Var X1,Y1,X2,Y2,W,H,Top,I,Sel,Vis,LW,Idx: Integer; K1,K2: Char; Done: Boolean; Res: Integer;
Begin
 LW:=0;
 For I:=1 To N Do If Length(ListItem[I])>LW Then LW:=Length(ListItem[I]);
 W:=MaxI(LW*8+60,240);
 Vis:=MinI(N,14);
 H:=48+Vis*14+52;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 Sel:=Sel0; If (Sel<1) Or (Sel>N) Then Sel:=1;
 Top:=1;
 Done:=False; Res:=0;
 While Not Done Do Begin
  If Sel<Top Then Top:=Sel;
  If Sel>Top+Vis-1 Then Top:=Sel-Vis+1;
  DrawAll;
  HideMouse;
  DlgFrame(X1,Y1,X2,Y2,Title);
  FillBox(X1+14,Y1+30,X2-14,Y1+34+Vis*14,CL_WHITE);
  SunkenFrame(X1+14,Y1+30,X2-14,Y1+34+Vis*14);
  For I:=0 To Vis-1 Do Begin
   Idx:=Top+I;
   If Idx>N Then Break;
   If Idx=Sel Then Begin
    FillBox(X1+16,Y1+32+I*14,X2-16,Y1+32+I*14+13,CL_BLUE);
    TextAt(X1+20,Y1+35+I*14,CL_WHITE,ListItem[Idx]);
   End Else TextAt(X1+20,Y1+35+I*14,CL_BLACK,ListItem[Idx]);
  End;
  DrawButton(X2-176,Y2-34,X2-104,Y2-12,'OK',True);
  DrawButton(X2-92,Y2-34,X2-20,Y2-12,'Cancel',False);
  ShowMouse;
  If WaitInput(K1,K2) Then Begin
   If K1=#0 Then Begin
    Case K2 Of
     K_UP: If Sel>1 Then Dec(Sel);
     K_DOWN: If Sel<N Then Inc(Sel);
     K_PGUP: Sel:=MaxI(1,Sel-Vis);
     K_PGDN: Sel:=MinI(N,Sel+Vis);
     K_HOME: Sel:=1;
     K_END: Sel:=N;
    End;
   End Else If K1=#13 Then Begin Res:=Sel; Done:=True; End
   Else If K1=#27 Then Done:=True;
  End Else Begin
   If InBox(Mouse.X,Mouse.Y,X2-176,Y2-34,X2-104,Y2-12) Then Begin Res:=Sel; Done:=True; End
   Else If InBox(Mouse.X,Mouse.Y,X2-92,Y2-34,X2-20,Y2-12) Then Done:=True
   Else If InBox(Mouse.X,Mouse.Y,X1+16,Y1+32,X2-16,Y1+32+Vis*14) Then Begin
    Idx:=Top+(Mouse.Y-(Y1+32)) Div 14;
    If (Idx>=1) And (Idx<=N) Then Begin
     If Idx=Sel Then Begin Res:=Sel; Done:=True; End Else Sel:=Idx;
    End;
   End;
  End;
 End;
 NeedRedraw:=True;
 ListDialog:=Res;
End;

{ Palette de couleurs : retourne True si choisie (Col = 0..15 ou 255 = defaut) }
Function ColorDialog(Const Title: String; Var Col: Integer; AllowDefault: Boolean): Boolean;
Var X1,Y1,X2,Y2,I,Sel: Integer; K1,K2: Char; Done,Ok: Boolean;
Begin
 X1:=(SCR_W-300) Div 2; Y1:=170; X2:=X1+300; Y2:=Y1+150;
 Sel:=Col; If (Sel<0) Or (Sel>15) Then Sel:=0;
 Done:=False; Ok:=False;
 While Not Done Do Begin
  DrawAll;
  HideMouse;
  DlgFrame(X1,Y1,X2,Y2,Title);
  For I:=0 To 15 Do Begin
   FillBox(X1+16+(I Mod 8)*34,Y1+34+(I Div 8)*34,X1+16+(I Mod 8)*34+28,Y1+34+(I Div 8)*34+28,I);
   If I=Sel Then Begin
    Rect(X1+14+(I Mod 8)*34,Y1+32+(I Div 8)*34,X1+16+(I Mod 8)*34+30,Y1+34+(I Div 8)*34+30,CL_BLACK);
    Rect(X1+13+(I Mod 8)*34,Y1+31+(I Div 8)*34,X1+16+(I Mod 8)*34+31,Y1+34+(I Div 8)*34+31,CL_WHITE);
   End Else Rect(X1+16+(I Mod 8)*34,Y1+34+(I Div 8)*34,X1+16+(I Mod 8)*34+28,Y1+34+(I Div 8)*34+28,CL_DKGRAY);
  End;
  If AllowDefault Then DrawButton(X1+16,Y2-34,X1+96,Y2-12,'Default',False);
  DrawButton(X2-176,Y2-34,X2-104,Y2-12,'OK',True);
  DrawButton(X2-92,Y2-34,X2-20,Y2-12,'Cancel',False);
  ShowMouse;
  If WaitInput(K1,K2) Then Begin
   If K1=#0 Then Begin
    Case K2 Of
     K_LEFT: If Sel>0 Then Dec(Sel);
     K_RIGHT: If Sel<15 Then Inc(Sel);
     K_UP: If Sel>=8 Then Dec(Sel,8);
     K_DOWN: If Sel<8 Then Inc(Sel,8);
    End;
   End Else If K1=#13 Then Begin Col:=Sel; Ok:=True; Done:=True; End
   Else If K1=#27 Then Done:=True;
  End Else Begin
   If InBox(Mouse.X,Mouse.Y,X2-176,Y2-34,X2-104,Y2-12) Then Begin Col:=Sel; Ok:=True; Done:=True; End
   Else If InBox(Mouse.X,Mouse.Y,X2-92,Y2-34,X2-20,Y2-12) Then Done:=True
   Else If AllowDefault And InBox(Mouse.X,Mouse.Y,X1+16,Y2-34,X1+96,Y2-12) Then Begin Col:=CL_NONE; Ok:=True; Done:=True; End
   Else For I:=0 To 15 Do
    If InBox(Mouse.X,Mouse.Y,X1+16+(I Mod 8)*34,Y1+34+(I Div 8)*34,X1+16+(I Mod 8)*34+28,Y1+34+(I Div 8)*34+28) Then
     Sel:=I;
  End;
 End;
 NeedRedraw:=True;
 ColorDialog:=Ok;
End;

{ ---- Selecteur de fichier ---- }

Type
 TFEntry = Record
  Name : String[20];
  Dir  : Boolean;
 End;

Function FileExtOk(Const N: String): Boolean;
Var U: String; P: Integer;
Begin
 U:=UpStr(N);
 P:=Length(U);
 While (P>0) And (U[P]<>'.') Do Dec(P);
 If P=0 Then Begin FileExtOk:=False; Exit; End;
 U:=Copy(U,P,10);
 FileExtOk:=(U='.WKC') Or (U='.WK1');
End;

Function FileDialog(Const Title: String; Var FN: String; Save: Boolean): Boolean;
Var Ent: Array[1..80] Of TFEntry; N,I,J,Sel,Top,Vis,X1,Y1,X2,Y2,W,H,Pos,Idx: Integer;
    SR: SearchRec; Dir,T: String; K1,K2: Char; Done,Ok,Fresh: Boolean; Tmp: TFEntry;
    Cur: String;
 Procedure Scan;
 Var I,J: Integer;
 Begin
  N:=0;
  GetDir(0,Dir);
  FindFirst({$IFDEF FPC}'*'{$ELSE}'*.*'{$ENDIF},AnyFile,SR);
  While (DosError=0) And (N<80) Do Begin
   If (SR.Attr And Directory)<>0 Then Begin
    If SR.Name<>'.' Then Begin Inc(N); Ent[N].Name:=Copy(SR.Name,1,20); Ent[N].Dir:=True; End;
   End Else If FileExtOk(SR.Name) Then Begin Inc(N); Ent[N].Name:=Copy(SR.Name,1,20); Ent[N].Dir:=False; End;
   FindNext(SR);
  End;
  {$IFDEF FPC}FindClose(SR);{$ENDIF}
  For I:=1 To N-1 Do
   For J:=I+1 To N Do
    If (Ent[J].Dir And Not Ent[I].Dir) Or ((Ent[J].Dir=Ent[I].Dir) And (UpStr(Ent[J].Name)<UpStr(Ent[I].Name))) Then Begin
     Tmp:=Ent[I]; Ent[I]:=Ent[J]; Ent[J]:=Tmp;
    End;
  Sel:=1; Top:=1;
 End;
Begin
 W:=380; Vis:=10; H:=60+Vis*14+80;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 Scan;
 Cur:=FN; Pos:=Length(Cur)+1; Fresh:=True; Done:=False; Ok:=False;
 While Not Done Do Begin
  If Sel<Top Then Top:=Sel;
  If Sel>Top+Vis-1 Then Top:=Sel-Vis+1;
  DrawAll;
  HideMouse;
  DlgFrame(X1,Y1,X2,Y2,Title);
  TextAt(X1+14,Y1+30,CL_BLACK,Tr('File name:'));
  DrawEditBox(X1+100,Y1+26,X2-14,Y1+44,Cur,Pos,True);
  TextAt(X1+14,Y1+50,CL_DKGRAY,Copy(Dir,1,44));
  FillBox(X1+14,Y1+64,X2-14,Y1+68+Vis*14,CL_WHITE);
  SunkenFrame(X1+14,Y1+64,X2-14,Y1+68+Vis*14);
  For I:=0 To Vis-1 Do Begin
   Idx:=Top+I;
   If Idx>N Then Break;
   If Ent[Idx].Dir Then T:='['+Ent[Idx].Name+']' Else T:=Ent[Idx].Name;
   If Idx=Sel Then Begin
    FillBox(X1+16,Y1+66+I*14,X2-16,Y1+66+I*14+13,CL_BLUE);
    TextAt(X1+20,Y1+69+I*14,CL_WHITE,T);
   End Else TextAt(X1+20,Y1+69+I*14,CL_BLACK,T);
  End;
  TextAt(X1+14,Y2-60,CL_DKGRAY,Tr('Types: *.WKC (1-2-3 clone)  *.WK1'));
  DrawButton(X2-176,Y2-34,X2-104,Y2-12,'OK',True);
  DrawButton(X2-92,Y2-34,X2-20,Y2-12,'Cancel',False);
  ShowMouse;
  If WaitInput(K1,K2) Then Begin
   If K1=#0 Then Begin
    Case K2 Of
     K_UP,K_DOWN,K_PGUP,K_PGDN: Begin
      If (K2=K_UP) And (Sel>1) Then Dec(Sel);
      If (K2=K_DOWN) And (Sel<N) Then Inc(Sel);
      If K2=K_PGUP Then Sel:=MaxI(1,Sel-Vis);
      If K2=K_PGDN Then Sel:=MinI(N,Sel+Vis);
      If (Sel>=1) And (Sel<=N) Then Begin
       If Ent[Sel].Dir Then Cur:='' Else Cur:=Ent[Sel].Name;
       Pos:=Length(Cur)+1; Fresh:=False;
      End;
     End;
     Else EditKey(Cur,Pos,Fresh,60,K1,K2);
    End;
   End Else If K1=#13 Then Begin
    If Cur='' Then Begin
     If (Sel>=1) And (Sel<=N) Then Begin
      If Ent[Sel].Dir Then Begin
       {$I-} ChDir(Ent[Sel].Name); {$I+}
       If IOResult<>0 Then;
       Scan;
       Cur:=''; Pos:=1;
      End Else Begin FN:=Ent[Sel].Name; Ok:=True; Done:=True; End;
     End;
    End Else Begin FN:=Cur; Ok:=True; Done:=True; End;
   End Else If K1=#27 Then Done:=True
   Else EditKey(Cur,Pos,Fresh,60,K1,K2);
  End Else Begin
   If InBox(Mouse.X,Mouse.Y,X2-176,Y2-34,X2-104,Y2-12) Then Begin
    If Cur<>'' Then FN:=Cur Else If (Sel>=1) And (Sel<=N) And Not Ent[Sel].Dir Then FN:=Ent[Sel].Name;
    If FN<>'' Then Begin Ok:=True; Done:=True; End;
   End Else If InBox(Mouse.X,Mouse.Y,X2-92,Y2-34,X2-20,Y2-12) Then Done:=True
   Else If InBox(Mouse.X,Mouse.Y,X1+16,Y1+66,X2-16,Y1+66+Vis*14) Then Begin
    Idx:=Top+(Mouse.Y-(Y1+66)) Div 14;
    If (Idx>=1) And (Idx<=N) Then Begin
     If (Idx=Sel) Then Begin
      If Ent[Sel].Dir Then Begin
       {$I-} ChDir(Ent[Sel].Name); {$I+}
       If IOResult<>0 Then;
       Scan;
      End Else Begin FN:=Ent[Sel].Name; Ok:=True; Done:=True; End;
     End Else Begin
      Sel:=Idx;
      If Not Ent[Sel].Dir Then Begin Cur:=Ent[Sel].Name; Pos:=Length(Cur)+1; Fresh:=False; End;
     End;
    End;
   End;
  End;
 End;
 NeedRedraw:=True;
 FileDialog:=Ok;
End;

{ ---- A propos ---- }

Procedure AboutDialog;
Var X1,Y1,X2,Y2: Integer; K1,K2: Char; Done: Boolean;
Begin
 X1:=120; Y1:=110; X2:=520; Y2:=330;
 DrawAll;
 HideMouse;
 DlgFrame(X1,Y1,X2,Y2,'About 1-2-3');
 FillBox(X1+14,Y1+32,X2-14,Y1+72,14);
 Rect(X1+14,Y1+32,X2-14,Y1+72,CL_BLACK);
 FillBox(X1+22,Y1+40,X1+98,Y1+64,CL_BLACK);
 BoldAt(X1+30,Y1+48,CL_WHITE,Tr('Clone'));
 BoldAt(X1+112,Y1+44,CL_BLACK,'1-2-3');
 TextAt(X1+112,Y1+58,CL_BLACK,Tr('Spreadsheet for Windows'));
 TextAt(X1+16,Y1+84,CL_BLACK,Tr('Clone of the Lotus 1-2-3 spreadsheet'));
 TextAt(X1+16,Y1+100,CL_BLACK,'(c) 2026 Sylvain Maltais - Gladir.com');
 TextAt(X1+16,Y1+116,CL_BLACK,'https://www.gladir.com/office-0');
 TextAt(X1+16,Y1+140,CL_BLACK,Tr('Target: Turbo Pascal 7 / Free Pascal'));
 TextAt(X1+16,Y1+156,CL_BLACK,Tr('8 sheets, 256 columns, 8192 rows'));
 DrawButton(X2-100,Y2-34,X2-24,Y2-12,'OK',True);
 ShowMouse;
 Done:=False;
 While Not Done Do Begin
  If WaitInput(K1,K2) Then Begin
   If (K1=#13) Or (K1=#27) Or (K1=' ') Then Done:=True;
  End Else If InBox(Mouse.X,Mouse.Y,X2-100,Y2-34,X2-24,Y2-12) Then Done:=True;
 End;
 NeedRedraw:=True;
End;

{ ====================================================================== }
{                  FICHIERS : FORMAT NATIF (.WKC), WK1, IMPRESSION       }
{ ====================================================================== }

Procedure ClearWorkbook;
Var S,R,C,I: Integer; Sh: PSheet; Row: PRow;
Begin
 UndoClear;
 ClipClear;
 For S:=1 To MAX_SHEETS Do Begin
  Sh:=Sheets[S];
  If Sh=Nil Then Continue;
  For R:=0 To MAX_ROWS-1 Do Begin
   Row:=Sh^.Rows[R];
   If Row=Nil Then Continue;
   For C:=0 To MAX_COLS-1 Do CellDispose(Row^[C]);
   Dispose(Row);
   Sh^.Rows[R]:=Nil;
  End;
  Dispose(Sh);
  Sheets[S]:=Nil;
 End;
 For I:=1 To MAX_CHARTS Do
  If Charts[I]<>Nil Then Begin Dispose(Charts[I]); Charts[I]:=Nil; End;
 For I:=1 To MAX_PLACED Do Placed[I].Used:=False;
 NameCount:=0;
 CurChart:=0;
 ActSheet:=1;
 SheetPtr(1);
 CurR:=0; CurC:=0; ScrollR:=0; ScrollC:=0;
 CollapseSel;
 InputMode:=False;
 FileName:='';
 Modified:=False;
 Inc(CalcStamp);
End;

Function Esc(Const S: String): String;
Var I: Integer; R: String;
Begin
 R:='';
 For I:=1 To Length(S) Do
  Case S[I] Of
   '\': R:=R+'\\';
   #9: R:=R+'\t';
   #13: R:=R+'\r';
   #10: R:=R+'\n';
   Else R:=R+S[I];
  End;
 Esc:=R;
End;

Function Unesc(Const S: String): String;
Var I: Integer; R: String;
Begin
 R:='';
 I:=1;
 While I<=Length(S) Do Begin
  If (S[I]='\') And (I<Length(S)) Then Begin
   Inc(I);
   Case S[I] Of
    't': R:=R+#9;
    'r': R:=R+#13;
    'n': R:=R+#10;
    Else R:=R+S[I];
   End;
  End Else R:=R+S[I];
  Inc(I);
 End;
 Unesc:=R;
End;

Function NumStr(V: Double): String;
Var S: String;
Begin
 Str(V,S);
 NumStr:=TrimStr(S);
End;

Function B2I(B: Boolean): Integer;
Begin
 If B Then B2I:=1 Else B2I:=0;
End;

Function SaveWKC(Const FN: String): Boolean;
Var F: Text; S,R,C,I,K: Integer; Sh: PSheet; P: PCell; Kd: Integer; Tx,Pf: String; Ch: PChart; D: TDraw;
Begin
 SaveWKC:=False;
 {$I-}
 Assign(F,FN);
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Exit;
 WriteLn(F,'LOTUS123CLONE 1');
 WriteLn(F,'G ',B2I(AutoCalc),' ',B2I(ShowGrid),' ',B2I(ShowHead),' ',ActSheet,' ',CurR,' ',CurC);
 For S:=1 To MAX_SHEETS Do Begin
  Sh:=Sheets[S];
  If Sh=Nil Then Continue;
  For C:=0 To Sh^.MaxC Do If Sh^.ColW[C]<>DEF_COLW Then WriteLn(F,'W ',S,' ',C,' ',Sh^.ColW[C]);
  For R:=0 To Sh^.MaxR Do If Sh^.RowH[R]<>0 Then WriteLn(F,'H ',S,' ',R,' ',Sh^.RowH[R]);
  For R:=0 To Sh^.MaxR Do Begin
   If Sh^.Rows[R]=Nil Then Continue;
   For C:=0 To Sh^.MaxC Do Begin
    P:=Sh^.Rows[R]^[C];
    If P=Nil Then Continue;
    Kd:=P^.Kind;
    If Kd=CK_VALUE Then Tx:=NumStr(P^.Num) Else Tx:=Esc(PStrVal(P^.Txt));
    Pf:=P^.Pfx;
    If P^.Pfx=#0 Then Pf:='0';
    WriteLn(F,'C ',S,' ',R,' ',C,' ',Kd,' ',P^.Fmt,' ',P^.Dec,' ',P^.Align,' ',P^.Style,' ',
            P^.Fg,' ',P^.Bg,' ',Ord(P^.Pfx),#9,Tx);
   End;
  End;
 End;
 For I:=1 To NameCount Do
  WriteLn(F,'N ',Names[I].Sheet,' ',Names[I].R1,' ',Names[I].C1,' ',Names[I].R2,' ',Names[I].C2,#9,Names[I].Name);
 For I:=1 To MAX_CHARTS Do Begin
  Ch:=Charts[I];
  If Ch=Nil Then Continue;
  WriteLn(F,'K ',I,#9,Ch^.Name);
  WriteLn(F,'KT ',I,' ',Ch^.CType,' ',B2I(Ch^.ThreeD),' ',B2I(Ch^.ShowLeg),' ',B2I(Ch^.GridH),' ',
          B2I(Ch^.GridV),' ',B2I(Ch^.Markers),' ',B2I(Ch^.Frame),' ',Ch^.Bg,' ',Ch^.Depth,' ',B2I(Ch^.AutoY));
  WriteLn(F,'KY ',I,' ',NumStr(Ch^.YMin),' ',NumStr(Ch^.YMax));
  WriteLn(F,'KX ',I,#9,Esc(Ch^.XRng));
  For K:=1 To NSER Do Begin
   WriteLn(F,'KR ',I,' ',K,#9,Esc(Ch^.Rng[K]));
   WriteLn(F,'KL ',I,' ',K,#9,Esc(Ch^.Legend[K]));
   WriteLn(F,'KC ',I,' ',K,' ',Ch^.SCol[K]);
  End;
  WriteLn(F,'KH ',I,' 1',#9,Esc(Ch^.Title1));
  WriteLn(F,'KH ',I,' 2',#9,Esc(Ch^.Title2));
  WriteLn(F,'KH ',I,' 3',#9,Esc(Ch^.XTitle));
  WriteLn(F,'KH ',I,' 4',#9,Esc(Ch^.YTitle));
  For K:=1 To Ch^.NDraw Do Begin
   D:=Ch^.Draws[K];
   WriteLn(F,'KD ',I,' ',D.Kind,' ',D.X1,' ',D.Y1,' ',D.X2,' ',D.Y2,' ',D.Col,#9,Esc(D.Txt));
  End;
 End;
 For I:=1 To MAX_PLACED Do
  If Placed[I].Used Then
   WriteLn(F,'P ',Placed[I].Sheet,' ',Placed[I].Chart,' ',Placed[I].R1,' ',Placed[I].C1,' ',
           Placed[I].R2,' ',Placed[I].C2);
 WriteLn(F,'END');
 Close(F);
 SaveWKC:=IOResult=0;
End;

Function NextTok(Var S: String): String;
Var P: Integer; T: String;
Begin
 While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
 P:=Pos(' ',S);
 If P=0 Then Begin T:=S; S:=''; End Else Begin T:=Copy(S,1,P-1); Delete(S,1,P); End;
 NextTok:=T;
End;

Function TokInt(Var S: String): Integer;
Var V,Code: Integer;
Begin
 Val(NextTok(S),V,Code);
 If Code<>0 Then V:=0;
 TokInt:=V;
End;

Function LoadWKC(Const FN: String): Boolean;
Var F: Text; Line,Head,Tail,Cmd: String; P,I,S,R,C,Kd,Code: Integer; Sh: PSheet; Cell: PCell; V: Double;
    Ch: PChart; D: TDraw; N,K: Integer; Ok: Boolean;
Begin
 LoadWKC:=False;
 {$I-}
 Assign(F,FN);
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 ReadLn(F,Line);
 If Copy(Line,1,13)<>'LOTUS123CLONE' Then Begin Close(F); Exit; End;
 ClearWorkbook;
 While Not Eof(F) Do Begin
  ReadLn(F,Line);
  P:=Pos(#9,Line);
  If P>0 Then Begin Head:=Copy(Line,1,P-1); Tail:=Copy(Line,P+1,255); End
         Else Begin Head:=Line; Tail:=''; End;
  Cmd:=NextTok(Head);
  If Cmd='G' Then Begin
   AutoCalc:=TokInt(Head)<>0;
   ShowGrid:=TokInt(Head)<>0;
   ShowHead:=TokInt(Head)<>0;
   ActSheet:=TokInt(Head);
   If (ActSheet<1) Or (ActSheet>MAX_SHEETS) Then ActSheet:=1;
   CurR:=TokInt(Head); CurC:=TokInt(Head);
  End Else If Cmd='W' Then Begin
   S:=TokInt(Head); C:=TokInt(Head); K:=TokInt(Head);
   Sh:=SheetPtr(S);
   If (Sh<>Nil) And (C>=0) And (C<MAX_COLS) And (K>0) Then Sh^.ColW[C]:=K;
  End Else If Cmd='H' Then Begin
   S:=TokInt(Head); R:=TokInt(Head); K:=TokInt(Head);
   Sh:=SheetPtr(S);
   If (Sh<>Nil) And (R>=0) And (R<MAX_ROWS) Then Sh^.RowH[R]:=K;
  End Else If Cmd='C' Then Begin
   S:=TokInt(Head); R:=TokInt(Head); C:=TokInt(Head); Kd:=TokInt(Head);
   Sh:=SheetPtr(S);
   If Sh=Nil Then Continue;
   Cell:=CellNew(Sh,R,C);
   If Cell=Nil Then Continue;
   Cell^.Kind:=Kd;
   Cell^.Fmt:=TokInt(Head); Cell^.Dec:=TokInt(Head); Cell^.Align:=TokInt(Head);
   Cell^.Style:=TokInt(Head); Cell^.Fg:=TokInt(Head); Cell^.Bg:=TokInt(Head);
   Cell^.Pfx:=Chr(TokInt(Head));
   If Kd=CK_VALUE Then Begin
    Val(Tail,V,Code);
    If Code<>0 Then V:=0;
    Cell^.Num:=V;
   End Else If Kd<>CK_EMPTY Then Cell^.Txt:=NewPStr(Unesc(Tail));
  End Else If Cmd='N' Then Begin
   If NameCount<MAX_NAMES Then Begin
    Inc(NameCount);
    Names[NameCount].Sheet:=TokInt(Head);
    Names[NameCount].R1:=TokInt(Head); Names[NameCount].C1:=TokInt(Head);
    Names[NameCount].R2:=TokInt(Head); Names[NameCount].C2:=TokInt(Head);
    Names[NameCount].Name:=Copy(Tail,1,15);
   End;
  End Else If Cmd='K' Then Begin
   I:=TokInt(Head);
   If (I>=1) And (I<=MAX_CHARTS) Then Begin
    If Charts[I]=Nil Then New(Charts[I]);
    ChartDefaults(Charts[I],Copy(Tail,1,15));
    If CurChart=0 Then CurChart:=I;
   End;
  End Else If (Copy(Cmd,1,1)='K') And (Length(Cmd)=2) Then Begin
   I:=TokInt(Head);
   If (I<1) Or (I>MAX_CHARTS) Or (Charts[I]=Nil) Then Continue;
   Ch:=Charts[I];
   If Cmd='KT' Then Begin
    Ch^.CType:=TokInt(Head); Ch^.ThreeD:=TokInt(Head)<>0; Ch^.ShowLeg:=TokInt(Head)<>0;
    Ch^.GridH:=TokInt(Head)<>0; Ch^.GridV:=TokInt(Head)<>0; Ch^.Markers:=TokInt(Head)<>0;
    Ch^.Frame:=TokInt(Head)<>0; Ch^.Bg:=TokInt(Head); Ch^.Depth:=TokInt(Head);
    Ch^.AutoY:=TokInt(Head)<>0;
   End Else If Cmd='KY' Then Begin
    Val(NextTok(Head),V,Code); If Code=0 Then Ch^.YMin:=V;
    Val(NextTok(Head),V,Code); If Code=0 Then Ch^.YMax:=V;
   End Else If Cmd='KX' Then Ch^.XRng:=Copy(Unesc(Tail),1,30)
   Else If Cmd='KR' Then Begin
    K:=TokInt(Head);
    If (K>=1) And (K<=NSER) Then Ch^.Rng[K]:=Copy(Unesc(Tail),1,30);
   End Else If Cmd='KL' Then Begin
    K:=TokInt(Head);
    If (K>=1) And (K<=NSER) Then Ch^.Legend[K]:=Copy(Unesc(Tail),1,14);
   End Else If Cmd='KC' Then Begin
    K:=TokInt(Head);
    If (K>=1) And (K<=NSER) Then Ch^.SCol[K]:=TokInt(Head);
   End Else If Cmd='KH' Then Begin
    K:=TokInt(Head);
    Case K Of
     1: Ch^.Title1:=Copy(Unesc(Tail),1,40);
     2: Ch^.Title2:=Copy(Unesc(Tail),1,40);
     3: Ch^.XTitle:=Copy(Unesc(Tail),1,30);
     4: Ch^.YTitle:=Copy(Unesc(Tail),1,30);
    End;
   End Else If Cmd='KD' Then Begin
    If Ch^.NDraw<MAX_DRAW Then Begin
     Inc(Ch^.NDraw);
     D.Kind:=TokInt(Head); D.X1:=TokInt(Head); D.Y1:=TokInt(Head);
     D.X2:=TokInt(Head); D.Y2:=TokInt(Head); D.Col:=TokInt(Head);
     D.Txt:=Copy(Unesc(Tail),1,40);
     Ch^.Draws[Ch^.NDraw]:=D;
    End;
   End;
  End Else If Cmd='P' Then Begin
   For I:=1 To MAX_PLACED Do
    If Not Placed[I].Used Then Begin
     Placed[I].Used:=True;
     Placed[I].Sheet:=TokInt(Head); Placed[I].Chart:=TokInt(Head);
     Placed[I].R1:=TokInt(Head); Placed[I].C1:=TokInt(Head);
     Placed[I].R2:=TokInt(Head); Placed[I].C2:=TokInt(Head);
     Break;
    End;
  End;
 End;
 Close(F);
 CollapseSel;
 Recalc;
 LoadWKC:=True;
End;

{ ---- WK1 (Lotus 1-2-3 Release 2) : valeurs et etiquettes ---- }

Function WK1Fmt(P: PCell): Byte;
Var D: Byte;
Begin
 D:=P^.Dec And $0F;
 Case P^.Fmt Of
  FM_FIXED: WK1Fmt:=D;
  FM_SCI: WK1Fmt:=$10 Or D;
  FM_CURRENCY: WK1Fmt:=$20 Or D;
  FM_PERCENT: WK1Fmt:=$30 Or D;
  FM_COMMA: WK1Fmt:=$40 Or D;
  FM_PLUSMINUS: WK1Fmt:=$70;
  FM_DATE1: WK1Fmt:=$72;
  FM_DATE2: WK1Fmt:=$73;
  FM_DATE3: WK1Fmt:=$74;
  FM_TEXT: WK1Fmt:=$75;
  FM_HIDDEN: WK1Fmt:=$76;
  FM_DATE4: WK1Fmt:=$77;
  FM_TIME1: WK1Fmt:=$79;
  Else WK1Fmt:=$71;
 End;
End;

Procedure WK1ReadFmt(B: Byte; P: PCell);
Begin
 P^.Fmt:=FM_GENERAL;
 P^.Dec:=B And $0F;
 Case (B Shr 4) And 7 Of
  0: P^.Fmt:=FM_FIXED;
  1: P^.Fmt:=FM_SCI;
  2: P^.Fmt:=FM_CURRENCY;
  3: P^.Fmt:=FM_PERCENT;
  4: P^.Fmt:=FM_COMMA;
  7: Case B And $0F Of
      0: P^.Fmt:=FM_PLUSMINUS;
      2: P^.Fmt:=FM_DATE1;
      3: P^.Fmt:=FM_DATE2;
      4: P^.Fmt:=FM_DATE3;
      5: P^.Fmt:=FM_TEXT;
      6: P^.Fmt:=FM_HIDDEN;
      7: P^.Fmt:=FM_DATE4;
      9: P^.Fmt:=FM_TIME1;
     End;
 End;
 If P^.Dec=0 Then P^.Dec:=2;
End;

Function SaveWK1(Const FN: String): Boolean;
Var F: File; Sh: PSheet; R,C,L,I: Integer; P: PCell; Buf: Array[0..300] Of Byte; W: Word; V: TVal;
    S: String; Dv: Double; Iv: Integer; MaxR,MaxC: Integer;
 Procedure Rec(Op,Len: Word);
 Begin
  BlockWrite(F,Op,2);
  BlockWrite(F,Len,2);
 End;
 Procedure PutW(Ofs: Integer; V: Word);
 Begin Buf[Ofs]:=V And $FF; Buf[Ofs+1]:=V Shr 8; End;
Begin
 SaveWK1:=False;
 Sh:=SheetPtr(1);
 {$I-}
 Assign(F,FN);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Rec(0,2); W:=$0406; BlockWrite(F,W,2);
 Rec(6,8);
 W:=0; BlockWrite(F,W,2); BlockWrite(F,W,2);
 W:=Sh^.MaxC; BlockWrite(F,W,2);
 W:=Sh^.MaxR; BlockWrite(F,W,2);
 For C:=0 To Sh^.MaxC Do
  If Sh^.ColW[C]<>DEF_COLW Then Begin
   Rec(8,3); W:=C; BlockWrite(F,W,2); Buf[0]:=Sh^.ColW[C]; BlockWrite(F,Buf[0],1);
  End;
 For R:=0 To Sh^.MaxR Do Begin
  If Sh^.Rows[R]=Nil Then Continue;
  For C:=0 To Sh^.MaxC Do Begin
   P:=Sh^.Rows[R]^[C];
   If (P=Nil) Or (P^.Kind=CK_EMPTY) Then Continue;
   V:=CellVal(1,R,C);
   If P^.Kind=CK_LABEL Then Begin
    S:=PStrVal(P^.Txt);
    If P^.Pfx=#0 Then Buf[5]:=Ord('''') Else Buf[5]:=Ord(P^.Pfx);
    L:=Length(S); If L>200 Then L:=200;
    Buf[0]:=WK1Fmt(P); PutW(1,C); PutW(3,R);
    For I:=1 To L Do Buf[5+I]:=Ord(S[I]);
    Buf[6+L]:=0;
    Rec($0F,L+7);
    BlockWrite(F,Buf[0],L+7);
   End Else If (P^.Kind=CK_FORMULA) And (V.K<>0) Then Begin
    S:=V.S;
    If V.K=2 Then S:='ERR';
    Buf[5]:=Ord('''');
    L:=Length(S); If L>200 Then L:=200;
    Buf[0]:=WK1Fmt(P); PutW(1,C); PutW(3,R);
    For I:=1 To L Do Buf[5+I]:=Ord(S[I]);
    Buf[6+L]:=0;
    Rec($0F,L+7);
    BlockWrite(F,Buf[0],L+7);
   End Else Begin
    If P^.Kind=CK_VALUE Then Dv:=P^.Num Else Dv:=V.N;
    Buf[0]:=WK1Fmt(P); PutW(1,C); PutW(3,R);
    If (Dv=Int(Dv)) And (Abs(Dv)<32000) Then Begin
     Iv:=Round(Dv);
     PutW(5,Word(Iv));
     Rec($0D,7);
     BlockWrite(F,Buf[0],7);
    End Else Begin
     Move(Dv,Buf[5],8);
     Rec($0E,13);
     BlockWrite(F,Buf[0],13);
    End;
   End;
  End;
 End;
 Rec(1,0);
 Close(F);
 SaveWK1:=IOResult=0;
End;

Function LoadWK1(Const FN: String): Boolean;
Var F: File; Op,Len: Word; Buf: Array[0..2100] Of Byte; Got: Word; Sh: PSheet; Col,Row: Integer;
    P: PCell; Dv: Double; S: String; I: Integer; Iv: Integer; Sz: LongInt;
Begin
 LoadWK1:=False;
 {$I-}
 Assign(F,FN);
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 BlockRead(F,Op,2,Got);
 BlockRead(F,Len,2,Got);
 If (Op<>0) Or (Len<2) Or (Len>2000) Then Begin Close(F); Exit; End;
 BlockRead(F,Buf[0],Len,Got);
 ClearWorkbook;
 Sh:=SheetPtr(1);
 While Not Eof(F) Do Begin
  BlockRead(F,Op,2,Got);
  If Got<2 Then Break;
  BlockRead(F,Len,2,Got);
  If Got<2 Then Break;
  If Len>2000 Then Break;
  If Len>0 Then BlockRead(F,Buf[0],Len,Got);
  If Op=1 Then Break;
  Case Op Of
   $08: If Len>=3 Then Begin
    Col:=Buf[0]+Buf[1]*256;
    If (Col<MAX_COLS) And (Buf[2]>0) Then Sh^.ColW[Col]:=Buf[2];
   End;
   $0C,$0D,$0E,$0F,$10: If Len>=5 Then Begin
    Col:=Buf[1]+Buf[2]*256;
    Row:=Buf[3]+Buf[4]*256;
    If (Col<MAX_COLS) And (Row<MAX_ROWS) Then Begin
     P:=CellNew(Sh,Row,Col);
     If P<>Nil Then Begin
      CellFreeContent(P);
      WK1ReadFmt(Buf[0],P);
      Case Op Of
       $0D: Begin
        Move(Buf[5],Iv,2);
        P^.Kind:=CK_VALUE; P^.Num:=Iv;
       End;
       $0E,$10: Begin
        Move(Buf[5],Dv,8);
        P^.Kind:=CK_VALUE; P^.Num:=Dv;
       End;
       $0F: Begin
        S:='';
        I:=6;
        While (I<Len) And (Buf[I]<>0) And (Length(S)<250) Do Begin S:=S+Chr(Buf[I]); Inc(I); End;
        P^.Kind:=CK_LABEL;
        If (Buf[5]=Ord('''')) Or (Buf[5]=Ord('"')) Or (Buf[5]=Ord('^')) Or (Buf[5]=Ord('\')) Then P^.Pfx:=Chr(Buf[5])
        Else Begin P^.Pfx:=#0; S:=Chr(Buf[5])+S; End;
        P^.Txt:=NewPStr(S);
       End;
      End;
     End;
    End;
   End;
  End;
 End;
 Close(F);
 CollapseSel;
 Recalc;
 LoadWK1:=True;
End;

Function HasExt(Const FN,Ext: String): Boolean;
Var U: String;
Begin
 U:=UpStr(FN);
 HasExt:=(Length(U)>=Length(Ext)) And (Copy(U,Length(U)-Length(Ext)+1,Length(Ext))=Ext);
End;

Function SaveAny(Const FN: String): Boolean;
Begin
 If HasExt(FN,'.WK1') Then SaveAny:=SaveWK1(FN) Else SaveAny:=SaveWKC(FN);
End;

Function LoadAny(Const FN: String): Boolean;
Begin
 If HasExt(FN,'.WK1') Then LoadAny:=LoadWK1(FN) Else LoadAny:=LoadWKC(FN);
End;

{ ---- Impression vers un fichier texte ---- }

Function PrintToFile(Const FN: String): Boolean;
Var F: Text; Sh: PSheet; R1,C1,R2,C2,R,C,W: Integer; P: PCell; Txt,Line: String; Al: Integer; Rep: Boolean;
Begin
 PrintToFile:=False;
 Sh:=CurSheet;
 If SelIsSingle Then Begin R1:=0; C1:=0; R2:=Sh^.MaxR; C2:=Sh^.MaxC; End
 Else Begin R1:=SelR1; C1:=SelC1; R2:=SelR2; C2:=SelC2; End;
 {$I-}
 Assign(F,FN);
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Exit;
 For R:=R1 To R2 Do Begin
  Line:='';
  For C:=C1 To C2 Do Begin
   W:=Sh^.ColW[C];
   P:=CellAt(Sh,R,C);
   CellDisplay(Sh,P,C,W*CHAR_W,Txt,Al,Rep);
   If Rep And (Txt<>'') Then Txt:=RepStr(Txt[1],W);
   If Length(Txt)>W Then Txt:=Copy(Txt,1,W);
   Case Al Of
    AL_RIGHT: Txt:=RepStr(' ',W-Length(Txt))+Txt;
    AL_CENTER: Txt:=RepStr(' ',(W-Length(Txt)) Div 2)+Txt;
   End;
   Line:=Line+PadR(Txt,W);
  End;
  While (Line<>'') And (Line[Length(Line)]=' ') Do Delete(Line,Length(Line),1);
  WriteLn(F,Line);
 End;
 Close(F);
 PrintToFile:=IOResult=0;
End;

{ ====================================================================== }
{                   NAVIGATION ET EDITION DE LA FEUILLE                  }
{ ====================================================================== }

Var
 SelMode : Boolean;      { F8 : extension de la selection }

Procedure EnsureVisible;
Var Sh: PSheet; Guard: Integer;
Begin
 Sh:=CurSheet;
 If CurR<ScrollR Then ScrollR:=CurR;
 If CurC<ScrollC Then ScrollC:=CurC;
 Guard:=0;
 While (CurR>LastVisRow) And (ScrollR<CurR) And (Guard<MAX_ROWS) Do Begin Inc(ScrollR); Inc(Guard); End;
 Guard:=0;
 While (CurC>LastVisCol) And (ScrollC<CurC) And (Guard<MAX_COLS) Do Begin Inc(ScrollC); Inc(Guard); End;
End;

Procedure SetCursor(R,C: Integer; Extend: Boolean);
Begin
 If R<0 Then R:=0;
 If R>=MAX_ROWS Then R:=MAX_ROWS-1;
 If C<0 Then C:=0;
 If C>=MAX_COLS Then C:=MAX_COLS-1;
 CurR:=R; CurC:=C;
 If Extend Then NormSel Else CollapseSel;
 EnsureVisible;
End;

Procedure ShowStatus(Const S: String);
Begin
 StatusMsg:=S;
End;

Procedure AfterEdit;
Begin
 Modified:=True;
 If AutoCalc Then Recalc;
End;

Procedure StartInput(Const Init: String; Edit: Boolean);
Begin
 InputMode:=True;
 InputBuf:=Init;
 InputPos:=Length(Init)+1;
 InputEdit:=Edit;
 ParseFail:=False;
End;

Procedure CancelInput;
Begin
 InputMode:=False;
 InputBuf:='';
 ParseFail:=False;
End;

Function CommitInput: Boolean;
Var V: TVal; S: String; Sh: PSheet;
Begin
 CommitInput:=True;
 If Not InputMode Then Exit;
 S:=InputBuf;
 ParseFail:=False;
 If (S<>'') And IsValueStart(S[1]) Then Begin
  V:=EvalText(S,ActSheet);
  If ParseFail And (Not StrToNum(S,V.N)) Then Begin
   StatusMsg:='Invalid formula';
   InputEdit:=True;
   CommitInput:=False;
   Exit;
  End;
 End;
 Sh:=CurSheet;
 UndoPush(ActSheet,CurR,CurC,CurR,CurC);
 SetCellContent(Sh,CurR,CurC,S);
 InputMode:=False;
 InputBuf:='';
 ParseFail:=False;
 AfterEdit;
End;

Procedure EditCurrent;
Var P: PCell;
Begin
 P:=CellAt(CurSheet,CurR,CurC);
 StartInput(CellEditText(P),True);
End;

{ ---- Utilitaires de commandes ---- }

Function AskNumber(Const Title,Prompt: String; Var V: LongInt; Lo,Hi: LongInt): Boolean;
Var S: String; Code: Integer; N: LongInt;
Begin
 AskNumber:=False;
 S:=IntToStr(V);
 If Not InputDialog(Title,Prompt,S,10) Then Exit;
 Val(TrimStr(S),N,Code);
 If (Code<>0) Or (N<Lo) Or (N>Hi) Then Begin
  MessageBox(Title,Tx('Enter a number from ','Entrez un nombre de ')+IntToStr(Lo)+Tx(' to ',' a ')+IntToStr(Hi));
  Exit;
 End;
 V:=N;
 AskNumber:=True;
End;

Function NextChartName: String;
Var N: Integer;
Begin
 N:=1;
 While FindChart('GRAPH'+IntToStr(N))<>0 Do Inc(N);
 NextChartName:='GRAPH'+IntToStr(N);
End;

Var
 ChIdx : Array[1..MAX_CHARTS] Of Integer;

Function ChartList: Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To MAX_CHARTS Do
  If Charts[I]<>Nil Then Begin Inc(N); ListItem[N]:=Charts[I]^.Name; ChIdx[N]:=I; End;
 ChartList:=N;
End;

Function PickChart(Const Title: String): Integer;
Var N,K,I: Integer;
Begin
 PickChart:=0;
 N:=ChartList;
 If N=0 Then Begin MessageBox(Title,'There are no named graphs.'); Exit; End;
 K:=1;
 For I:=1 To N Do If ChIdx[I]=CurChart Then K:=I;
 K:=ListDialog(Title,N,K);
 If K>0 Then PickChart:=ChIdx[K];
End;

Function ValidName(Const S: String): Boolean;
Var I: Integer; SSrc: String; SPos,A,B,R,C: Integer; A1,A2,Cell: Boolean;
Begin
 ValidName:=False;
 If (S='') Or (Length(S)>15) Or Not IsLetter(S[1]) Then Exit;
 For I:=1 To Length(S) Do
  If Not (IsLetter(S[I]) Or IsDigit(S[I]) Or (S[I]='_')) Then Exit;
 SSrc:=FSrc; SPos:=FPos;
 FSrc:=S; FPos:=1;
 Cell:=TryCellRef(A,R,C,A1,A2) And (FPos>Length(FSrc));
 FSrc:=SSrc; FPos:=SPos;
 ValidName:=Not Cell;
End;

Procedure GoToRange(Const S: String);
Var Sh,R1,C1,R2,C2: Integer;
Begin
 If Not ParseRangeText(S,Sh,R1,C1,R2,C2) Then Begin
  MessageBox('Go To','Invalid cell or range address.');
  Exit;
 End;
 If (Sh>=1) And (Sh<=MAX_SHEETS) Then Begin ActSheet:=Sh; SheetPtr(Sh); End;
 AncR:=R2; AncC:=C2; CurR:=R1; CurC:=C1;
 NormSel;
 EnsureVisible;
End;

Procedure FindInSheet;
Var Sh: PSheet; R,C,Start,N,Cnt: LongInt; P: PCell; T,U: String; Found: Boolean; Idx: LongInt; Cols: LongInt;
Begin
 If Not InputDialog('Find','Find text:',FindText,40) Then Exit;
 If FindText='' Then Exit;
 U:=UpStr(FindText);
 Sh:=CurSheet;
 Cols:=Sh^.MaxC+1;
 Start:=LongInt(CurR)*Cols+CurC+1;
 N:=LongInt(Sh^.MaxR+1)*Cols;
 Found:=False;
 For Cnt:=0 To N-1 Do Begin
  Idx:=(Start+Cnt) Mod N;
  R:=Idx Div Cols; C:=Idx Mod Cols;
  P:=CellAt(Sh,R,C);
  If (P=Nil) Or (P^.Kind=CK_EMPTY) Then Continue;
  T:=PStrVal(P^.Txt);
  If P^.Kind=CK_VALUE Then T:=GeneralStr(P^.Num,15);
  If P^.IsStr Then T:=T+' '+PStrVal(P^.Res);
  If Pos(U,UpStr(T))>0 Then Begin
   SetCursor(R,C,False);
   Found:=True;
   Break;
  End;
 End;
 If Not Found Then MessageBox('Find','Text not found.');
End;

Procedure AutoSum;
Var Sh: PSheet; R,C,R1,C1: Integer; P: PCell; S: String; Done: Boolean;
 Function IsNumCell(Rr,Cc: Integer): Boolean;
 Var Q: PCell;
 Begin
  Q:=CellAt(Sh,Rr,Cc);
  IsNumCell:=(Q<>Nil) And ((Q^.Kind=CK_VALUE) Or ((Q^.Kind=CK_FORMULA) And Not Q^.IsStr));
 End;
Begin
 Sh:=CurSheet;
 UndoPush(ActSheet,SelR1,SelC1,MinI(SelR2+1,MAX_ROWS-1),SelC2);
 If Not SelIsSingle Then Begin
  If SelR2+1>=MAX_ROWS Then Exit;
  For C:=SelC1 To SelC2 Do
   SetCellContent(Sh,SelR2+1,C,'@SUM('+CellName(SelR1,C)+'..'+CellName(SelR2,C)+')');
  AfterEdit;
  Exit;
 End;
 R:=CurR-1; C:=CurC;
 If (R>=0) And IsNumCell(R,C) Then Begin
  R1:=R;
  While (R1>0) And IsNumCell(R1-1,C) Do Dec(R1);
  SetCellContent(Sh,CurR,CurC,'@SUM('+CellName(R1,C)+'..'+CellName(R,C)+')');
 End Else If (CurC>0) And IsNumCell(CurR,CurC-1) Then Begin
  C1:=CurC-1;
  While (C1>0) And IsNumCell(CurR,C1-1) Do Dec(C1);
  SetCellContent(Sh,CurR,CurC,'@SUM('+CellName(CurR,C1)+'..'+CellName(CurR,CurC-1)+')');
 End Else Begin
  MessageBox('SUM','No numbers found above or to the left.');
  Exit;
 End;
 AfterEdit;
End;

Procedure DoSortDialog;
Var K: Integer; S: String; U: String; C: Integer;
Begin
 If SelIsSingle Then Begin MessageBox('Sort','Select the range to sort first.'); Exit; End;
 FormLbl[1]:='Sort key column:'; FormVal[1]:=ColName(SelC1);
 FormLbl[2]:='Order (A/D):'; FormVal[2]:=Tx('A','C');
 If Not FormDialog('Sort',2) Then Exit;
 U:=UpStr(TrimStr(FormVal[1]));
 C:=-1;
 If (Length(U)=1) And IsLetter(U[1]) Then C:=Ord(U[1])-65
 Else If (Length(U)=2) And IsLetter(U[1]) And IsLetter(U[2]) Then C:=(Ord(U[1])-64)*26+Ord(U[2])-65;
 If (C<SelC1) Or (C>SelC2) Then Begin
  MessageBox('Sort','The key column must be inside the selected range.');
  Exit;
 End;
 SortSelection(C,UpStr(Copy(TrimStr(FormVal[2]),1,1))<>'D');
End;

Procedure DoFillDialog;
Var Start,Step,Stop: Double; Code: Integer;
Begin
 FormLbl[1]:='Start:'; FormVal[1]:='1';
 FormLbl[2]:='Step:'; FormVal[2]:='1';
 FormLbl[3]:='Stop:'; FormVal[3]:='8191';
 If Not FormDialog('Data Fill',3) Then Exit;
 If (Not StrToNum(FormVal[1],Start)) Or (Not StrToNum(FormVal[2],Step)) Or (Not StrToNum(FormVal[3],Stop)) Then Begin
  MessageBox('Data Fill','Please enter numbers.');
  Exit;
 End;
 FillSelection(Start,Step,Stop);
End;

Procedure DoHelp;
Begin
 If French Then
  Begin
   MessageBox('1-2-3 Help',
    'F1 Aide  F2 Edition  F5 Aller a  F9 Recalcul  F10 ou / Menu|'+
    'Ctrl+N/O/S/P  Nouveau Ouvrir Enreg. Imprimer|'+
    'Ctrl+C/X/V Copier Couper Coller  Ctrl+Z Annuler|'+
    'Ctrl+B/U Gras Souligne  F8 Etendre la selection');
   MessageBox('1-2-3 Help',
    'Ctrl+PgUp/PgDn Changer de feuille  Fin+fleche Saut|'+
    '@SUM(A1..A9)  +A1*B1  @IF(A1>0,"o","n")');
  End Else
  MessageBox('1-2-3 Help',
   'F1 Help  F2 Edit  F5 Go To  F9 Recalc  F10 or / Menu|'+
   'Ctrl+N/O/S/P  New Open Save Print|'+
   'Ctrl+C/X/V Copy Cut Paste  Ctrl+Z Undo|'+
   'Ctrl+B/U Bold Underline  F8 Extend selection|'+
   'Ctrl+PgUp/PgDn Change sheet  End+arrow Jump|'+
   '@SUM(A1..A9)  +A1*B1  @IF(A1>0,"y","n")');
End;

Procedure PlaceChart(ChI: Integer);
Var I,R1,C1,R2,C2: Integer;
Begin
 If SelIsSingle Then Begin
  R1:=CurR; C1:=CurC; R2:=MinI(CurR+13,MAX_ROWS-1); C2:=MinI(CurC+5,MAX_COLS-1);
 End Else Begin R1:=SelR1; C1:=SelC1; R2:=SelR2; C2:=SelC2; End;
 For I:=1 To MAX_PLACED Do
  If Not Placed[I].Used Then Begin
   Placed[I].Used:=True; Placed[I].Sheet:=ActSheet; Placed[I].Chart:=ChI;
   Placed[I].R1:=R1; Placed[I].C1:=C1; Placed[I].R2:=R2; Placed[I].C2:=C2;
   Modified:=True;
   Exit;
  End;
 MessageBox('Graph','Too many graphs placed in the worksheet.');
End;

Function CreateChartFromSel(Const Nm: String): Integer;
Var I: Integer;
Begin
 I:=NewChart(Nm);
 If I=0 Then Begin
  MessageBox('Graph','Too many named graphs.');
  CreateChartFromSel:=0;
  Exit;
 End;
 ChartFromSelection(Charts[I]);
 CurChart:=I;
 CreateChartFromSel:=I;
End;

Procedure EnterGraphWindow;
Begin
 AppMode:=1;
 DrawTool:=DT_NONE;
 MenuOpen:=0;
End;

Procedure DoRanges;
Var Ch: PChart; I,Sh,R1,C1,R2,C2: Integer; Ok: Boolean;
Begin
 Ch:=CurCh;
 If Ch=Nil Then Exit;
 FormLbl[1]:='X range:'; FormVal[1]:=Ch^.XRng;
 For I:=1 To NSER Do Begin FormLbl[I+1]:=Tx('Range ','Plage ')+Chr(64+I)+':'; FormVal[I+1]:=Ch^.Rng[I]; End;
 If Not FormDialog('Chart Ranges',7) Then Exit;
 Ok:=True;
 For I:=1 To 7 Do
  If (TrimStr(FormVal[I])<>'') And Not ParseRangeText(FormVal[I],Sh,R1,C1,R2,C2) Then Ok:=False;
 If Not Ok Then Begin MessageBox('Chart Ranges','One of the ranges is invalid.'); Exit; End;
 Ch^.XRng:=TrimStr(FormVal[1]);
 For I:=1 To NSER Do Ch^.Rng[I]:=TrimStr(FormVal[I+1]);
End;

Procedure DoHeadings;
Var Ch: PChart;
Begin
 Ch:=CurCh;
 If Ch=Nil Then Exit;
 FormLbl[1]:='Title:'; FormVal[1]:=Ch^.Title1;
 FormLbl[2]:='Subtitle:'; FormVal[2]:=Ch^.Title2;
 FormLbl[3]:='X axis title:'; FormVal[3]:=Ch^.XTitle;
 FormLbl[4]:='Y axis title:'; FormVal[4]:=Ch^.YTitle;
 If Not FormDialog('Chart Headings',4) Then Exit;
 Ch^.Title1:=Copy(FormVal[1],1,40); Ch^.Title2:=Copy(FormVal[2],1,40);
 Ch^.XTitle:=Copy(FormVal[3],1,30); Ch^.YTitle:=Copy(FormVal[4],1,30);
End;

Procedure DoLegendText;
Var Ch: PChart; I: Integer;
Begin
 Ch:=CurCh;
 If Ch=Nil Then Exit;
 For I:=1 To NSER Do Begin FormLbl[I]:=Tx('Series ','Serie ')+Chr(64+I)+':'; FormVal[I]:=Ch^.Legend[I]; End;
 If Not FormDialog('Legend Text',6) Then Exit;
 For I:=1 To NSER Do Ch^.Legend[I]:=Copy(FormVal[I],1,14);
 Ch^.ShowLeg:=True;
End;

Procedure DoAxis;
Var Ch: PChart; V1,V2: Double;
Begin
 Ch:=CurCh;
 If Ch=Nil Then Exit;
 FormLbl[1]:='Y minimum:'; If Ch^.AutoY Then FormVal[1]:='' Else FormVal[1]:=GeneralStr(Ch^.YMin,12);
 FormLbl[2]:='Y maximum:'; If Ch^.AutoY Then FormVal[2]:='' Else FormVal[2]:=GeneralStr(Ch^.YMax,12);
 If Not FormDialog('Axis Scale (blank = automatic)',2) Then Exit;
 If (TrimStr(FormVal[1])='') Or (TrimStr(FormVal[2])='') Then Begin Ch^.AutoY:=True; Exit; End;
 If StrToNum(FormVal[1],V1) And StrToNum(FormVal[2],V2) And (V2>V1) Then Begin
  Ch^.AutoY:=False; Ch^.YMin:=V1; Ch^.YMax:=V2;
 End Else MessageBox('Axis Scale','Enter two numbers with maximum > minimum.');
End;

Procedure FlipSeries;
Var Ch: PChart; I,N: Integer; T: String[30]; L: String[14];
Begin
 Ch:=CurCh;
 If Ch=Nil Then Exit;
 N:=0;
 For I:=1 To NSER Do If TrimStr(Ch^.Rng[I])<>'' Then N:=I;
 For I:=1 To N Div 2 Do Begin
  T:=Ch^.Rng[I]; Ch^.Rng[I]:=Ch^.Rng[N+1-I]; Ch^.Rng[N+1-I]:=T;
  L:=Ch^.Legend[I]; Ch^.Legend[I]:=Ch^.Legend[N+1-I]; Ch^.Legend[N+1-I]:=L;
 End;
End;

{ ====================================================================== }
{                       EXECUTION DES COMMANDES                          }
{ ====================================================================== }

Function ConfirmSaveFirst: Boolean;
Var R: Integer;
Begin
 ConfirmSaveFirst:=True;
 If Not Modified Then Exit;
 R:=ConfirmDialog('1-2-3','Save changes to the current file?');
 If R=0 Then Begin ConfirmSaveFirst:=False; Exit; End;
 If R=1 Then Begin
  ExecCmd(CM_SAVE);
  If Modified Then ConfirmSaveFirst:=False;
 End;
End;

Function FileExists(Const FN: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F,FN);
 Reset(F);
 {$I+}
 If IOResult=0 Then Begin Close(F); FileExists:=True; End Else FileExists:=False;
End;

Procedure DoSaveAs;
Var FN: String; I: Integer; HasDot: Boolean;
Begin
 FN:=FileName;
 If FN='' Then FN:='UNTITLED.WKC';
 If Not FileDialog('Save As',FN,True) Then Exit;
 HasDot:=False;
 For I:=1 To Length(FN) Do If FN[I]='.' Then HasDot:=True;
 If Not HasDot Then FN:=FN+'.WKC';
 If FileExists(FN) And (UpStr(FN)<>UpStr(FileName)) Then
  If ConfirmDialog('Save As',FN+Tx(' already exists. Replace it?',' existe deja. Le remplacer ?'))<>1 Then Exit;
 If SaveAny(FN) Then Begin
  FileName:=FN;
  Modified:=False;
  ShowStatus('Saved');
 End Else MessageBox('Save As',Tx('Cannot write the file ','Impossible d''ecrire le fichier ')+FN);
End;

Procedure DoOpen;
Var FN: String;
Begin
 If Not ConfirmSaveFirst Then Exit;
 FN:='';
 If Not FileDialog('Open File',FN,False) Then Exit;
 If Not FileExists(FN) Then Begin MessageBox('Open File',Tx('File not found: ','Fichier introuvable : ')+FN); Exit; End;
 If LoadAny(FN) Then Begin
  FileName:=FN;
  Modified:=False;
  AppMode:=0;
  EnsureVisible;
 End Else Begin
  MessageBox('Open File',Tx('Cannot read ','Impossible de lire ')+FN+'|'+'(not a 1-2-3 clone or WK1 file)');
  ClearWorkbook;
 End;
End;

Procedure DoPrint;
Var FN: String;
Begin
 FN:='LOTUS.PRN';
 If Not InputDialog('Print','Print the range to this text file:',FN,40) Then Exit;
 If PrintToFile(FN) Then MessageBox('Print',Tx('Printed to ','Imprime dans ')+FN) Else MessageBox('Print',Tx('Cannot write ','Impossible d''ecrire ')+FN);
End;

Procedure ApplyFormat(F: Integer);
Var D: Integer;
Begin
 D:=2;
 If F In [FM_GENERAL,FM_DATE1,FM_DATE2,FM_DATE3,FM_DATE4,FM_TIME1,FM_TEXT,FM_HIDDEN,FM_PLUSMINUS] Then D:=2;
 SetAttr(AT_FORMAT,F,D);
 AfterEdit;
End;

Procedure DoNameCreate;
Var S: String; I: Integer;
Begin
 S:='';
 If Not InputDialog('Range Name Create','Name for the selected range:',S,15) Then Exit;
 S:=UpStr(TrimStr(S));
 If Not ValidName(S) Then Begin MessageBox('Range Name','Invalid name.'); Exit; End;
 I:=FindName(S);
 If I=0 Then Begin
  If NameCount>=MAX_NAMES Then Begin MessageBox('Range Name','Too many names.'); Exit; End;
  Inc(NameCount); I:=NameCount;
 End;
 Names[I].Name:=S; Names[I].Sheet:=ActSheet;
 Names[I].R1:=SelR1; Names[I].C1:=SelC1; Names[I].R2:=SelR2; Names[I].C2:=SelC2;
 Modified:=True;
 Recalc;
End;

Procedure DoNameDelete;
Var I,K: Integer;
Begin
 If NameCount=0 Then Begin MessageBox('Range Name','There are no range names.'); Exit; End;
 For I:=1 To NameCount Do
  ListItem[I]:=Names[I].Name+'  '+RangeText(Names[I].Sheet,Names[I].R1,Names[I].C1,Names[I].R2,Names[I].C2);
 K:=ListDialog('Delete Range Name',NameCount,1);
 If K=0 Then Exit;
 For I:=K To NameCount-1 Do Names[I]:=Names[I+1];
 Dec(NameCount);
 Modified:=True;
 Recalc;
End;

Procedure DoTranspose;
Var S: String; Sh,R1,C1,R2,C2: Integer;
Begin
 S:=CellName(CurR,CurC);
 If Not InputDialog('Transpose','Copy the range transposed to (top-left cell):',S,20) Then Exit;
 If Not ParseRangeText(S,Sh,R1,C1,R2,C2) Then Begin MessageBox('Transpose','Invalid cell address.'); Exit; End;
 TransposeTo(R1,C1);
End;

Procedure DoColWidth;
Var V: LongInt; C: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 V:=Sh^.ColW[CurC];
 If Not AskNumber('Column Width','Width (characters, 1-240):',V,1,240) Then Exit;
 For C:=SelC1 To SelC2 Do Sh^.ColW[C]:=V;
 Modified:=True;
End;

Procedure DoRowHeight;
Var V: LongInt; R: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 V:=RowPx(Sh,CurR);
 If Not AskNumber('Row Height','Height (pixels, 10-120):',V,10,120) Then Exit;
 For R:=SelR1 To SelR2 Do If V=ROW_H Then Sh^.RowH[R]:=0 Else Sh^.RowH[R]:=V;
 Modified:=True;
End;

Procedure DoDefColWidth;
Var V: LongInt; C: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 V:=DEF_COLW;
 If Not AskNumber('Default Column Width','Width (characters, 1-240):',V,1,240) Then Exit;
 For C:=0 To MAX_COLS-1 Do Sh^.ColW[C]:=V;
 Modified:=True;
End;

Procedure DoChooseColor(What: Integer);
Var Col: Integer; Ttl: String;
Begin
 Col:=0;
 If What=AT_FG Then Ttl:='Text Color' Else Ttl:='Background Color';
 If ColorDialog(Ttl,Col,True) Then Begin SetAttr(What,Col,0); Modified:=True; End;
End;

Procedure ChangeSheet(D: Integer);
Begin
 ActSheet:=ActSheet+D;
 If ActSheet>MAX_SHEETS Then ActSheet:=1;
 If ActSheet<1 Then ActSheet:=MAX_SHEETS;
 SheetPtr(ActSheet);
 If InputMode Then CancelInput;
 EnsureVisible;
End;

Procedure ExecCmd(Cmd: Integer);
Var Ch: PChart; I,K,N: Integer; S: String; CCol: Integer; NL: LongInt;
Begin
 If (Cmd>=CM_FMT_BASE) And (Cmd<=CM_FMT_BASE+FM_HIDDEN) Then Begin
  ApplyFormat(Cmd-CM_FMT_BASE);
  Exit;
 End;
 If (Cmd>=CM_GT_BASE+1) And (Cmd<=CM_GT_BASE+7) Then Begin
  Ch:=CurCh;
  If Ch<>Nil Then Ch^.CType:=Cmd-CM_GT_BASE;
  Exit;
 End;
 If (Cmd>CM_GS_SERCOL) And (Cmd<=CM_GS_SERCOL+NSER) Then Begin
  Ch:=CurCh;
  If Ch<>Nil Then Begin
   CCol:=Ch^.SCol[Cmd-CM_GS_SERCOL];
   If ColorDialog(Tx('Series ','Serie ')+IntToStr(Cmd-CM_GS_SERCOL)+Tx(' Color',' : couleur'),CCol,False) Then Ch^.SCol[Cmd-CM_GS_SERCOL]:=CCol;
  End;
  Exit;
 End;
 Ch:=CurCh;
 If InputMode And (AppMode=0) Then Begin
  If Not CommitInput Then Exit;
 End;
 Case Cmd Of
  CM_NEW: Begin
   If ConfirmSaveFirst Then Begin ClearWorkbook; AppMode:=0; End;
  End;
  CM_OPEN: DoOpen;
  CM_SAVE: Begin
   If FileName='' Then DoSaveAs
   Else If SaveAny(FileName) Then Begin Modified:=False; ShowStatus('Saved'); End
   Else MessageBox('Save',Tx('Cannot write the file ','Impossible d''ecrire le fichier ')+FileName);
  End;
  CM_SAVEAS: DoSaveAs;
  CM_PRINT: DoPrint;
  CM_EXIT: If ConfirmSaveFirst Then Quit:=True;
  CM_UNDO: Begin UndoPop; Modified:=True; End;
  CM_CUT: If Not DoCopy(True) Then MessageBox('Cut','The range is too large for the clipboard.');
  CM_COPY: If Not DoCopy(False) Then MessageBox('Copy','The range is too large for the clipboard.');
  CM_PASTE: DoPaste;
  CM_CLEAR: DoClear(False);
  CM_CLEARALL: DoClear(True);
  CM_FIND: FindInSheet;
  CM_GOTO: Begin
   S:=SheetLetter(ActSheet)+':'+CellName(CurR,CurC);
   If InputDialog('Go To','Enter a cell address or range name:',S,30) Then GoToRange(S);
  End;
  CM_SELALL: Begin
   AncR:=0; AncC:=0; CurR:=CurSheet^.MaxR; CurC:=CurSheet^.MaxC; NormSel;
  End;
  CM_INSROW: InsertRows(SelR1,SelR2-SelR1+1);
  CM_INSCOL: InsertCols(SelC1,SelC2-SelC1+1);
  CM_DELROW: Begin DeleteRows(SelR1,SelR2-SelR1+1); CollapseSel; End;
  CM_DELCOL: Begin DeleteCols(SelC1,SelC2-SelC1+1); CollapseSel; End;
  CM_COLW: DoColWidth;
  CM_ROWH: DoRowHeight;
  CM_DEFCOLW: DoDefColWidth;
  CM_AUTOCALC: Begin AutoCalc:=Not AutoCalc; If AutoCalc Then Recalc; End;
  CM_GRIDLINES: ShowGrid:=Not ShowGrid;
  CM_HEADINGS: ShowHead:=Not ShowHead;
  CM_DECIMALS: Begin
   NL:=2;
   If AskNumber('Decimal Places','Number of decimal places (0-15):',NL,0,15) Then Begin
    SetAttr(AT_DEC,NL,0);
    AfterEdit;
   End;
  End;
  CM_NAMECREATE: DoNameCreate;
  CM_NAMEDEL: DoNameDelete;
  CM_NAMERESET: Begin NameCount:=0; Recalc; End;
  CM_TRANSPOSE: DoTranspose;
  CM_GNEW: Begin
   S:=NextChartName;
   If InputDialog('Graph New','Name for the new graph:',S,15) Then Begin
    S:=UpStr(TrimStr(S));
    If (S='') Or (FindChart(S)<>0) Then MessageBox('Graph New','That name is empty or already used.')
    Else If CreateChartFromSel(S)<>0 Then EnterGraphWindow;
   End;
  End;
  CM_CHARTWIZ: Begin
   If CreateChartFromSel(NextChartName)<>0 Then EnterGraphWindow;
  End;
  CM_GVIEW: Begin
   I:=PickChart('Graph View');
   If I>0 Then Begin CurChart:=I; EnterGraphWindow; End;
  End;
  CM_GUSE: Begin
   I:=PickChart('Graph Name Use');
   If I>0 Then CurChart:=I;
  End;
  CM_GADD: Begin
   I:=PickChart('Add Graph to Sheet');
   If I>0 Then PlaceChart(I);
  End;
  CM_GCREATE: Begin
   If Ch=Nil Then Begin
    MessageBox('Graph Name','There is no current graph.');
   End Else Begin
    S:=Ch^.Name;
    If InputDialog('Graph Name Create','Name for the current graph:',S,15) Then Begin
     S:=UpStr(TrimStr(S));
     If (S<>'') And ((FindChart(S)=0) Or (FindChart(S)=CurChart)) Then Ch^.Name:=S
     Else MessageBox('Graph Name','That name is empty or already used.');
    End;
   End;
  End;
  CM_GDELETE: Begin
   I:=PickChart('Graph Name Delete');
   If I>0 Then DeleteChart(I);
  End;
  CM_GREFRESH,CM_GT_REFRESH: Recalc;
  CM_GGOTO: Begin
   N:=0;
   For I:=1 To MAX_PLACED Do
    If Placed[I].Used Then Begin
     Inc(N);
     ListItem[N]:=Charts[Placed[I].Chart]^.Name+Tx(' at ',' en ')+RangeText(Placed[I].Sheet,Placed[I].R1,Placed[I].C1,Placed[I].R2,Placed[I].C2);
     ChIdx[N]:=I;
    End;
   If N=0 Then MessageBox('Graph Go To','No graph is placed in the worksheet.')
   Else Begin
    K:=ListDialog('Graph Go To',MinI(N,MAX_CHARTS),1);
    If K>0 Then Begin
     I:=ChIdx[K];
     ActSheet:=Placed[I].Sheet;
     SetCursor(Placed[I].R1,Placed[I].C1,False);
    End;
   End;
  End;
  CM_FILL: DoFillDialog;
  CM_SORT: DoSortDialog;
  CM_SORTASC,CM_SORTDESC: Begin
   If SelIsSingle Then MessageBox('Sort','Select the range to sort first.')
   Else SortSelection(SelC1,Cmd=CM_SORTASC);
  End;
  CM_BOLD: Begin SetAttr(AT_STYLE,ST_BOLD,0); Modified:=True; End;
  CM_ITALIC: Begin SetAttr(AT_STYLE,ST_ITALIC,0); Modified:=True; End;
  CM_UNDERLINE: Begin SetAttr(AT_STYLE,ST_UNDER,0); Modified:=True; End;
  CM_NORMALSTYLE: Begin SetAttr(AT_STYLE,0,0); Modified:=True; End;
  CM_TEXTCOLOR: DoChooseColor(AT_FG);
  CM_BGCOLOR: DoChooseColor(AT_BG);
  CM_ALIGN_GEN: SetAttr(AT_ALIGN,AL_GENERAL,0);
  CM_ALIGN_L: SetAttr(AT_ALIGN,AL_LEFT,0);
  CM_ALIGN_C: SetAttr(AT_ALIGN,AL_CENTER,0);
  CM_ALIGN_R: SetAttr(AT_ALIGN,AL_RIGHT,0);
  CM_CURRENCY: ApplyFormat(FM_CURRENCY);
  CM_COMMA: ApplyFormat(FM_COMMA);
  CM_PERCENT: ApplyFormat(FM_PERCENT);
  CM_SUM: AutoSum;
  CM_RECALC: Recalc;
  CM_ICONS: ShowTools:=Not ShowTools;
  CM_NEXTSHEET: ChangeSheet(1);
  CM_PREVSHEET: ChangeSheet(-1);
  CM_HELP: DoHelp;
  CM_ABOUT: AboutDialog;
  { fenetre graphique }
  CM_GW_CLOSE: Begin AppMode:=0; DrawTool:=DT_NONE; End;
  CM_GW_UNDO,CM_GW_DELOBJ: If (Ch<>Nil) And (Ch^.NDraw>0) Then Dec(Ch^.NDraw);
  CM_GW_CLEARDRAW: If Ch<>Nil Then Ch^.NDraw:=0;
  CM_G3D: If Ch<>Nil Then Ch^.ThreeD:=Not Ch^.ThreeD;
  CM_GRANGES: DoRanges;
  CM_GHEADINGS: DoHeadings;
  CM_GLEGEND: If Ch<>Nil Then Ch^.ShowLeg:=Not Ch^.ShowLeg;
  CM_GLEGTEXT: DoLegendText;
  CM_GFRAME: If Ch<>Nil Then Ch^.Frame:=Not Ch^.Frame;
  CM_GMARKERS: If Ch<>Nil Then Ch^.Markers:=Not Ch^.Markers;
  CM_GGRID_NONE: If Ch<>Nil Then Begin Ch^.GridH:=False; Ch^.GridV:=False; End;
  CM_GGRID_H: If Ch<>Nil Then Begin Ch^.GridH:=True; Ch^.GridV:=False; End;
  CM_GGRID_V: If Ch<>Nil Then Begin Ch^.GridH:=False; Ch^.GridV:=True; End;
  CM_GGRID_BOTH: If Ch<>Nil Then Begin Ch^.GridH:=True; Ch^.GridV:=True; End;
  CM_GAXIS: DoAxis;
  CM_GD_SELECT: DrawTool:=DT_NONE;
  CM_GD_LINE: DrawTool:=DT_LINE;
  CM_GD_ARROW: DrawTool:=DT_ARROW;
  CM_GD_RECT: DrawTool:=DT_RECT;
  CM_GD_ELLIPSE: DrawTool:=DT_ELLIPSE;
  CM_GD_TEXT: DrawTool:=DT_TEXT;
  CM_GR_FLIP: FlipSeries;
  CM_GR_DEEPER: If Ch<>Nil Then Begin
   If Ch^.Depth=0 Then Ch^.Depth:=14;
   Ch^.Depth:=MinI(Ch^.Depth+4,40);
   Ch^.ThreeD:=True;
  End;
  CM_GR_SHALLOWER: If Ch<>Nil Then Begin
   If Ch^.Depth=0 Then Ch^.Depth:=14;
   Ch^.Depth:=MaxI(Ch^.Depth-4,6);
  End;
  CM_GS_BG: If Ch<>Nil Then Begin
   CCol:=Ch^.Bg;
   If ColorDialog('Background Color',CCol,False) Then Ch^.Bg:=CCol;
  End;
 End;
 NeedRedraw:=True;
End;

{ ====================================================================== }
{                       BOUCLE DE MENU                                   }
{ ====================================================================== }

Function FirstSel(M: Integer): Integer;
Var I: Integer;
Begin
 FirstSel:=0;
 For I:=1 To MenuCount(M) Do
  If ItemEnabled(MenuItem(M,I)) Then Begin FirstSel:=I; Exit; End;
End;

Function StepSel(M,Cur,Dir: Integer): Integer;
Var I,N,Guard: Integer;
Begin
 N:=MenuCount(M);
 I:=Cur;
 Guard:=0;
 Repeat
  I:=I+Dir;
  If I>N Then I:=1;
  If I<1 Then I:=N;
  Inc(Guard);
 Until ItemEnabled(MenuItem(M,I)) Or (Guard>N+1);
 StepSel:=I;
End;

Function HotItem(M: Integer; Ch: Char): Integer;
Var I: Integer; It: TMI;
Begin
 HotItem:=0;
 Ch:=UpCase(Ch);
 For I:=1 To MenuCount(M) Do Begin
  It:=MenuItem(M,I);
  If ItemEnabled(It) And (ItemHot(It.L)=Ch) Then Begin HotItem:=I; Exit; End;
 End;
End;

Procedure MenuLoop;
Var Done: Boolean; Cmd,B,I,X,Y,W,H,Ix: Integer; K1,K2: Char; It: TMI; Id: Integer;
    OM,OH,OS,OSH: Integer; Changed: Boolean; Hit: Integer;

 Procedure Activate;
 Var Itm: TMI;
 Begin
  If SubOpen>0 Then Begin
   If SubHi=0 Then Exit;
   Itm:=MenuItem(SubOpen,SubHi);
   If ItemEnabled(Itm) Then Begin Cmd:=Itm.C; Done:=True; End;
  End Else If MenuHi>0 Then Begin
   Itm:=MenuItem(MenuIdOf(MenuOpen),MenuHi);
   If Itm.S>0 Then Begin SubOpen:=Itm.S; SubHi:=FirstSel(SubOpen); End
   Else If ItemEnabled(Itm) Then Begin Cmd:=Itm.C; Done:=True; End;
  End;
 End;

 Procedure OpenBar(Bi: Integer);
 Begin
  MenuOpen:=Bi;
  MenuHi:=FirstSel(MenuIdOf(Bi));
  SubOpen:=0; SubHi:=0;
 End;

Begin
 MenuActive:=True;
 Done:=False; Cmd:=0;
 If MenuOpen=0 Then OpenBar(1);
 If (MenuHi=0) And (SubOpen=0) Then MenuHi:=FirstSel(MenuIdOf(MenuOpen));
 DrawAll;
 While Not Done Do Begin
  OM:=MenuOpen; OH:=MenuHi; OS:=SubOpen; OSH:=SubHi;
  If KeyPressed Then Begin
   K1:=ReadKey;
   If K1=#0 Then Begin
    K2:=ReadKey;
    Case K2 Of
     K_LEFT: Begin
      If SubOpen>0 Then Begin SubOpen:=0; SubHi:=0; End
      Else Begin
       If MenuOpen>1 Then OpenBar(MenuOpen-1) Else OpenBar(10);
      End;
     End;
     K_RIGHT: Begin
      If (SubOpen=0) And (MenuHi>0) And (MenuItem(MenuIdOf(MenuOpen),MenuHi).S>0) Then Activate
      Else If SubOpen=0 Then Begin
       If MenuOpen<10 Then OpenBar(MenuOpen+1) Else OpenBar(1);
      End;
     End;
     K_UP: Begin
      If SubOpen>0 Then SubHi:=StepSel(SubOpen,SubHi,-1)
      Else MenuHi:=StepSel(MenuIdOf(MenuOpen),MenuHi,-1);
     End;
     K_DOWN: Begin
      If SubOpen>0 Then SubHi:=StepSel(SubOpen,SubHi,1)
      Else MenuHi:=StepSel(MenuIdOf(MenuOpen),MenuHi,1);
     End;
     K_HOME: If SubOpen>0 Then SubHi:=FirstSel(SubOpen) Else MenuHi:=FirstSel(MenuIdOf(MenuOpen));
     K_F10: Done:=True;
     Else Begin
      Ix:=BarFromAlt(K2);
      If Ix>0 Then OpenBar(Ix);
     End;
    End;
   End Else Begin
    Case K1 Of
     #27: Begin
      If SubOpen>0 Then Begin SubOpen:=0; SubHi:=0; End Else Done:=True;
     End;
     #13,' ': Activate;
     Else Begin
      If K1>' ' Then Begin
       If SubOpen>0 Then Begin
        Ix:=HotItem(SubOpen,K1);
        If Ix>0 Then Begin SubHi:=Ix; Activate; End;
       End Else Begin
        Ix:=HotItem(MenuIdOf(MenuOpen),K1);
        If Ix>0 Then Begin MenuHi:=Ix; Activate; End;
       End;
      End;
     End;
    End;
   End;
  End Else Begin
   UpdateMouse;
   B:=BarHit(Mouse.X,Mouse.Y);
   If (Mouse.Y>=MENU_Y) And (Mouse.Y<MENU_Y+MENU_H) Then Begin
    If (B>0) And (B<>MenuOpen) Then OpenBar(B);
   End Else Begin
    Hit:=0;
    If SubOpen>0 Then Begin
     SubGeom(X,Y,W,H);
     Hit:=PopupItemAt(SubOpen,X,Y,W,H,Mouse.X,Mouse.Y);
     If Hit>0 Then SubHi:=Hit;
    End;
    If Hit=0 Then Begin
     TopGeom(X,Y,W,H);
     Ix:=PopupItemAt(MenuIdOf(MenuOpen),X,Y,W,H,Mouse.X,Mouse.Y);
     If (Ix>0) And ((Ix<>MenuHi) Or (SubOpen>0)) And (Mouse.X>=X) And (Mouse.X<=X+W) Then Begin
      It:=MenuItem(MenuIdOf(MenuOpen),Ix);
      If (Ix<>MenuHi) Then Begin
       MenuHi:=Ix;
       If It.S>0 Then Begin SubOpen:=It.S; SubHi:=0; End Else Begin SubOpen:=0; SubHi:=0; End;
      End;
     End;
    End;
   End;
   If LeftPressed Then Begin
    If (Mouse.Y>=MENU_Y) And (Mouse.Y<MENU_Y+MENU_H) Then Begin
     If (B=0) Or (B=MenuOpen) Then Done:=True;
    End Else Begin
     Hit:=0;
     If SubOpen>0 Then Begin
      SubGeom(X,Y,W,H);
      Hit:=PopupItemAt(SubOpen,X,Y,W,H,Mouse.X,Mouse.Y);
      If Hit>0 Then Begin SubHi:=Hit; Activate; End;
     End;
     If (Hit=0) Then Begin
      TopGeom(X,Y,W,H);
      Ix:=PopupItemAt(MenuIdOf(MenuOpen),X,Y,W,H,Mouse.X,Mouse.Y);
      If Ix>0 Then Begin
       MenuHi:=Ix;
       Activate;
      End Else If Not ((SubOpen>0) And (Hit>0)) Then Done:=True;
     End;
    End;
   End;
   Delay(2);
  End;
  If Not Done Then
   If (OM<>MenuOpen) Or (OH<>MenuHi) Or (OS<>SubOpen) Or (OSH<>SubHi) Then DrawAll;
 End;
 MenuActive:=False;
 MenuOpen:=0; MenuHi:=0; SubOpen:=0; SubHi:=0;
 DrawAll;
 If Cmd<>0 Then ExecCmd(Cmd);
 NeedRedraw:=True;
End;

Procedure OpenMenuBar(B: Integer);
Begin
 If B<1 Then B:=1;
 MenuOpen:=B;
 MenuHi:=FirstSel(MenuIdOf(B));
 SubOpen:=0; SubHi:=0;
 If InputMode And (AppMode=0) Then Begin
  If Not CommitInput Then Begin MenuOpen:=0; Exit; End;
 End;
 MenuLoop;
End;

{ ====================================================================== }
{                       CLAVIER ET SOURIS (FEUILLE)                      }
{ ====================================================================== }

Var
 LastClkT   : LongInt;
 LastClkR   : Integer;
 LastClkC   : Integer;
 DragMode   : Integer;     { 0 aucun, 1 cellules, 2 lignes, 3 colonnes, 4 barre V, 5 barre H }

Function NowTicks: LongInt;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 NowTicks:=((LongInt(H)*60+M)*60+S)*100+S100;
End;

Function CellFilled(R,C: Integer): Boolean;
Var P: PCell;
Begin
 P:=CellAt(CurSheet,R,C);
 CellFilled:=(P<>Nil) And (P^.Kind<>CK_EMPTY);
End;

Procedure EndJump(DR,DC: Integer);
Var R,C,NR,NC,Guard: Integer; Cur: Boolean;
Begin
 R:=CurR; C:=CurC;
 Cur:=CellFilled(R,C);
 Guard:=0;
 NR:=R+DR; NC:=C+DC;
 If Cur And (NR>=0) And (NR<MAX_ROWS) And (NC>=0) And (NC<MAX_COLS) And CellFilled(NR,NC) Then Begin
  While (Guard<MAX_ROWS) And (R+DR>=0) And (R+DR<MAX_ROWS) And (C+DC>=0) And (C+DC<MAX_COLS)
        And CellFilled(R+DR,C+DC) Do Begin
   R:=R+DR; C:=C+DC; Inc(Guard);
  End;
 End Else Begin
  While (R+DR>=0) And (R+DR<MAX_ROWS) And (C+DC>=0) And (C+DC<MAX_COLS) And (Guard<MAX_ROWS) Do Begin
   R:=R+DR; C:=C+DC; Inc(Guard);
   If CellFilled(R,C) Then Break;
  End;
 End;
 SetCursor(R,C,SelMode);
End;

Procedure MoveBy(DR,DC: Integer);
Begin
 If EndMode Then Begin
  EndJump(DR,DC);
  EndMode:=False;
 End Else SetCursor(CurR+DR,CurC+DC,SelMode);
End;

Procedure PageMove(Dir: Integer);
Var N: Integer;
Begin
 N:=LastVisRow-ScrollR;
 If N<1 Then N:=1;
 ScrollR:=MaxI(0,MinI(MAX_ROWS-1,ScrollR+Dir*N));
 SetCursor(CurR+Dir*N,CurC,SelMode);
End;

Procedure ScreenMove(Dir: Integer);
Var N: Integer;
Begin
 N:=LastVisCol-ScrollC;
 If N<1 Then N:=1;
 ScrollC:=MaxI(0,MinI(MAX_COLS-1,ScrollC+Dir*N));
 SetCursor(CurR,CurC+Dir*N,SelMode);
End;

Procedure HandleInputKey(K1,K2: Char);
Begin
 If K1=#0 Then Begin
  Case K2 Of
   K_LEFT: If InputEdit Then Begin If InputPos>1 Then Dec(InputPos); End
           Else If CommitInput Then MoveBy(0,-1);
   K_RIGHT: If InputEdit Then Begin If InputPos<=Length(InputBuf) Then Inc(InputPos); End
            Else If CommitInput Then MoveBy(0,1);
   K_UP: If CommitInput Then MoveBy(-1,0);
   K_DOWN: If CommitInput Then MoveBy(1,0);
   K_HOME: If InputEdit Then InputPos:=1 Else If CommitInput Then SetCursor(0,0,False);
   K_END: InputPos:=Length(InputBuf)+1;
   K_PGUP: If CommitInput Then PageMove(-1);
   K_PGDN: If CommitInput Then PageMove(1);
   K_DEL: If InputPos<=Length(InputBuf) Then Delete(InputBuf,InputPos,1);
   K_INS: InsertMode:=Not InsertMode;
   K_F2: InputEdit:=True;
   K_F10: If CommitInput Then OpenMenuBar(1);
   K_SHIFT_TAB: If CommitInput Then MoveBy(0,-1);
  End;
 End Else Begin
  Case K1 Of
   #27: CancelInput;
   #13: CommitInput;
   #9: If CommitInput Then MoveBy(0,1);
   #8: If InputPos>1 Then Begin Delete(InputBuf,InputPos-1,1); Dec(InputPos); End;
   Else If (K1>=' ') And (Length(InputBuf)<240) Then Begin
    If InsertMode And (InputPos<=Length(InputBuf)) Then InputBuf[InputPos]:=K1
    Else Insert(K1,InputBuf,InputPos);
    Inc(InputPos);
   End;
  End;
 End;
End;

Procedure HandleKeyGraph(K1,K2: Char);
Var Ch: PChart; I: Integer;
Begin
 Ch:=CurCh;
 If K1=#0 Then Begin
  Case K2 Of
   K_F10: OpenMenuBar(1);
   K_F1: DoHelp;
   K_DEL: ExecCmd(CM_GW_DELOBJ);
   #107: ExecCmd(CM_EXIT);
   K_PGDN,K_PGUP: Begin
    I:=CurChart;
    Repeat
     If K2=K_PGDN Then Inc(I) Else Dec(I);
     If I>MAX_CHARTS Then I:=1;
     If I<1 Then I:=MAX_CHARTS;
    Until (Charts[I]<>Nil) Or (I=CurChart);
    CurChart:=I;
   End;
   Else Begin
    I:=BarFromAlt(K2);
    If I>0 Then OpenMenuBar(I);
   End;
  End;
 End Else Begin
  Case K1 Of
   #27: ExecCmd(CM_GW_CLOSE);
   '/': OpenMenuBar(1);
   #19: ExecCmd(CM_SAVE);
   #2,#14,#15,#16: ;
  End;
 End;
End;

Procedure HandleKey(K1,K2: Char);
Var I: Integer;
Begin
 If AppMode=1 Then Begin HandleKeyGraph(K1,K2); Exit; End;
 StatusMsg:='';
 If InputMode Then Begin HandleInputKey(K1,K2); Exit; End;
 If K1=#0 Then Begin
  Case K2 Of
   K_UP: MoveBy(-1,0);
   K_DOWN: MoveBy(1,0);
   K_LEFT: MoveBy(0,-1);
   K_RIGHT: MoveBy(0,1);
   K_HOME: SetCursor(0,0,SelMode);
   K_END: EndMode:=True;
   K_CTRL_HOME: SetCursor(0,0,False);
   K_CTRL_END: SetCursor(CurSheet^.MaxR,CurSheet^.MaxC,SelMode);
   K_PGUP: PageMove(-1);
   K_PGDN: PageMove(1);
   K_CTRL_PGUP: ChangeSheet(1);
   K_CTRL_PGDN: ChangeSheet(-1);
   K_CTRL_LEFT,K_SHIFT_TAB: ScreenMove(-1);
   K_CTRL_RIGHT: ScreenMove(1);
   K_DEL: ExecCmd(CM_CLEAR);
   K_INS: InsertMode:=Not InsertMode;
   K_F1: DoHelp;
   K_F2: EditCurrent;
   K_F5: ExecCmd(CM_GOTO);
   #66: Begin SelMode:=Not SelMode; If Not SelMode Then CollapseSel; End;
   K_F9: ExecCmd(CM_RECALC);
   K_F10: OpenMenuBar(1);
   #107: ExecCmd(CM_EXIT);
   Else Begin
    I:=BarFromAlt(K2);
    If I>0 Then OpenMenuBar(I);
   End;
  End;
  If K2<>K_END Then EndMode:=False;
 End Else Begin
  Case K1 Of
   #27: Begin If SelMode Or Not SelIsSingle Then Begin SelMode:=False; CollapseSel; End; EndMode:=False; End;
   #9: ScreenMove(1);
   #1: ExecCmd(CM_SELALL);
   #14: ExecCmd(CM_NEW);
   #15: ExecCmd(CM_OPEN);
   #19: ExecCmd(CM_SAVE);
   #16: ExecCmd(CM_PRINT);
   #24: ExecCmd(CM_CUT);
   #3: ExecCmd(CM_COPY);
   #22: ExecCmd(CM_PASTE);
   #26: ExecCmd(CM_UNDO);
   #2: ExecCmd(CM_BOLD);
   #21: ExecCmd(CM_UNDERLINE);
   #6: ExecCmd(CM_FIND);
   '/': OpenMenuBar(1);
   #13,#8: ;
   Else If K1>=' ' Then Begin
    StartInput(K1,False);
    SelMode:=False;
    If Not SelIsSingle Then CollapseSel;
   End;
  End;
  EndMode:=False;
 End;
End;

{ ---- Souris : feuille ---- }

Procedure ClickCell(R,C: Integer);
Var T: LongInt;
Begin
 If InputMode Then Begin If Not CommitInput Then Exit; End;
 T:=NowTicks;
 If (R=LastClkR) And (C=LastClkC) And (T-LastClkT<60) And (T-LastClkT>=0) Then Begin
  SetCursor(R,C,False);
  EditCurrent;
  LastClkT:=0;
  DragMode:=0;
  Exit;
 End;
 LastClkT:=T; LastClkR:=R; LastClkC:=C;
 SetCursor(R,C,False);
 DragMode:=1;
End;

Procedure ScrollTo(Vert: Boolean);
Var TH,V: LongInt;
Begin
 If Vert Then Begin
  TH:=HSB_Y-17-(GRID_TOP+16)-12;
  V:=(Mouse.Y-(GRID_TOP+16)-6)*(MAX_ROWS-1) Div TH;
  If V<0 Then V:=0;
  If V>MAX_ROWS-1 Then V:=MAX_ROWS-1;
  ScrollR:=V;
  If CurR<ScrollR Then SetCursor(ScrollR,CurC,False);
  If CurR>LastVisRow Then SetCursor(LastVisRow,CurC,False);
 End Else Begin
  TH:=GRID_RIGHT-15-16-12;
  V:=(Mouse.X-16-6)*(MAX_COLS-1) Div TH;
  If V<0 Then V:=0;
  If V>MAX_COLS-1 Then V:=MAX_COLS-1;
  ScrollC:=V;
  If CurC<ScrollC Then SetCursor(CurR,ScrollC,False);
  If CurC>LastVisCol Then SetCursor(CurR,LastVisCol,False);
 End;
End;

Procedure HandleMouseSheet;
Var R,C,B,I: Integer; Sh: PSheet;
Begin
 Sh:=CurSheet;
 If LeftPressed Then Begin
  DragMode:=0;
  If Mouse.Y<TITLE_H Then Exit;
  If (Mouse.Y>=MENU_Y) And (Mouse.Y<MENU_Y+MENU_H) Then Begin
   B:=BarHit(Mouse.X,Mouse.Y);
   If B>0 Then OpenMenuBar(B);
   Exit;
  End;
  If (Mouse.Y>=TOOL_Y) And (Mouse.Y<TOOL_Y+TOOL_H) Then Begin
   I:=ToolHit(Mouse.X,Mouse.Y);
   If I>0 Then Begin
    If CmdEnabled(ToolCmd(I)) Then ExecCmd(ToolCmd(I));
    NeedRedraw:=True;
   End;
   Exit;
  End;
  If (Mouse.Y>=EDIT_Y) And (Mouse.Y<EDIT_Y+EDIT_H) Then Begin
   If InBox(Mouse.X,Mouse.Y,106,EDIT_Y+3,120,EDIT_Y+EDIT_H-4) And InputMode Then CancelInput
   Else If InBox(Mouse.X,Mouse.Y,124,EDIT_Y+3,138,EDIT_Y+EDIT_H-4) And InputMode Then CommitInput
   Else If (Mouse.X>=146) And (Mouse.X<=SCR_W-92) And Not InputMode Then EditCurrent;
   NeedRedraw:=True;
   Exit;
  End;
  If (Mouse.Y>=HDR_Y) And (Mouse.Y<GRID_TOP) And ShowHead Then Begin
   If Mouse.X<RH_W Then Begin ChangeSheet(1); NeedRedraw:=True; Exit; End;
   C:=GridHitCol(Mouse.X);
   If C>=0 Then Begin
    If InputMode Then If Not CommitInput Then Exit;
    CurC:=C; AncC:=C; AncR:=CurR;
    SelR1:=0; SelR2:=MAX_ROWS-1; SelC1:=C; SelC2:=C;
    DragMode:=3;
    NeedRedraw:=True;
   End;
   Exit;
  End;
  If (Mouse.X>GRID_RIGHT) Or (Mouse.Y>=HSB_Y) Then Begin
   { barres de defilement }
   If (Mouse.X>GRID_RIGHT) And (Mouse.Y>=GRID_TOP) And (Mouse.Y<HSB_Y) Then Begin
    If Mouse.Y<GRID_TOP+16 Then Begin If ScrollR>0 Then Dec(ScrollR); End
    Else If Mouse.Y>=HSB_Y-16 Then Begin If ScrollR<MAX_ROWS-1 Then Inc(ScrollR); End
    Else Begin
     I:=GRID_TOP+16+(LongInt(ScrollR)*(HSB_Y-17-(GRID_TOP+16)-12)) Div (MAX_ROWS-1);
     If (Mouse.Y>=I) And (Mouse.Y<=I+11) Then DragMode:=4
     Else If Mouse.Y<I Then ScrollR:=MaxI(0,ScrollR-(LastVisRow-ScrollR))
     Else ScrollR:=MinI(MAX_ROWS-1,ScrollR+(LastVisRow-ScrollR));
    End;
    If (CurR<ScrollR) Then SetCursor(ScrollR,CurC,False);
    If (CurR>LastVisRow) Then SetCursor(LastVisRow,CurC,False);
   End Else If (Mouse.Y>=HSB_Y) And (Mouse.X<=GRID_RIGHT) Then Begin
    If Mouse.X<16 Then Begin If ScrollC>0 Then Dec(ScrollC); End
    Else If Mouse.X>GRID_RIGHT-16 Then Begin If ScrollC<MAX_COLS-1 Then Inc(ScrollC); End
    Else Begin
     I:=16+(LongInt(ScrollC)*(GRID_RIGHT-15-16-12)) Div (MAX_COLS-1);
     If (Mouse.X>=I) And (Mouse.X<=I+11) Then DragMode:=5
     Else If Mouse.X<I Then ScrollC:=MaxI(0,ScrollC-(LastVisCol-ScrollC))
     Else ScrollC:=MinI(MAX_COLS-1,ScrollC+(LastVisCol-ScrollC));
    End;
    If (CurC<ScrollC) Then SetCursor(CurR,ScrollC,False);
    If (CurC>LastVisCol) Then SetCursor(CurR,LastVisCol,False);
   End;
   NeedRedraw:=True;
   Exit;
  End;
  If (Mouse.X<RH_W) And ShowHead And (Mouse.Y>=GRID_TOP) Then Begin
   R:=GridHitRow(Mouse.Y);
   If R>=0 Then Begin
    If InputMode Then If Not CommitInput Then Exit;
    CurR:=R; AncR:=R; AncC:=CurC;
    SelR1:=R; SelR2:=R; SelC1:=0; SelC2:=MAX_COLS-1;
    DragMode:=2;
    NeedRedraw:=True;
   End;
   Exit;
  End;
  R:=GridHitRow(Mouse.Y); C:=GridHitCol(Mouse.X);
  If (R>=0) And (C>=0) Then Begin
   ClickCell(R,C);
   NeedRedraw:=True;
  End;
  Exit;
 End;
 If LeftDown Then Begin
  Case DragMode Of
   1: Begin
    R:=GridHitRow(Mouse.Y); C:=GridHitCol(Mouse.X);
    If Mouse.X>GRID_RIGHT-4 Then C:=CurC+1;
    If Mouse.X<GX0 Then C:=CurC-1;
    If Mouse.Y>GRID_BOTTOM-4 Then R:=CurR+1;
    If Mouse.Y<GY0 Then R:=CurR-1;
    If (R>=0) And (C>=0) And ((R<>CurR) Or (C<>CurC)) Then Begin
     If R>=MAX_ROWS Then R:=MAX_ROWS-1;
     If C>=MAX_COLS Then C:=MAX_COLS-1;
     CurR:=R; CurC:=C; NormSel; EnsureVisible;
     NeedRedraw:=True;
    End;
   End;
   2: Begin
    R:=GridHitRow(Mouse.Y);
    If R>=0 Then Begin
     If R<AncR Then Begin SelR1:=R; SelR2:=AncR; End Else Begin SelR1:=AncR; SelR2:=R; End;
     CurR:=R;
     NeedRedraw:=True;
    End;
   End;
   3: Begin
    C:=GridHitCol(Mouse.X);
    If C>=0 Then Begin
     If C<AncC Then Begin SelC1:=C; SelC2:=AncC; End Else Begin SelC1:=AncC; SelC2:=C; End;
     CurC:=C;
     NeedRedraw:=True;
    End;
   End;
   4: Begin ScrollTo(True); NeedRedraw:=True; End;
   5: Begin ScrollTo(False); NeedRedraw:=True; End;
  End;
 End Else DragMode:=0;
End;

{ ---- Souris : fenetre graphique ---- }

Procedure RubberBand(Tool,X1,Y1,X2,Y2: Integer);
Begin
 SetWriteMode(XORPut);
 SetColor(CL_WHITE);
 Case Tool Of
  DT_LINE,DT_ARROW: Line(X1,Y1,X2,Y2);
  DT_RECT: Rectangle(X1,Y1,X2,Y2);
  DT_ELLIPSE: Ellipse((X1+X2) Div 2,(Y1+Y2) Div 2,0,360,Abs(X2-X1) Div 2,Abs(Y2-Y1) Div 2);
 End;
 SetWriteMode(NormalPut);
End;

Procedure AddDrawObject(Tool,X1,Y1,X2,Y2: Integer; Const Txt: String);
Var Ch: PChart;
Begin
 Ch:=CurCh;
 If Ch=Nil Then Exit;
 If Ch^.NDraw>=MAX_DRAW Then Begin MessageBox('Draw','Too many objects on this graph.'); Exit; End;
 Inc(Ch^.NDraw);
 Ch^.Draws[Ch^.NDraw].Kind:=Tool;
 Ch^.Draws[Ch^.NDraw].X1:=X1; Ch^.Draws[Ch^.NDraw].Y1:=Y1;
 Ch^.Draws[Ch^.NDraw].X2:=X2; Ch^.Draws[Ch^.NDraw].Y2:=Y2;
 Ch^.Draws[Ch^.NDraw].Col:=0;
 Ch^.Draws[Ch^.NDraw].Txt:=Copy(Txt,1,40);
 Modified:=True;
End;

Procedure HandleMouseGraph;
Var B,I,X0,Y0,X1,Y1,PX,PY: Integer; S: String;
Begin
 If Not LeftPressed Then Exit;
 If (Mouse.Y>=MENU_Y) And (Mouse.Y<MENU_Y+MENU_H) Then Begin
  B:=BarHit(Mouse.X,Mouse.Y);
  If B>0 Then OpenMenuBar(B);
  Exit;
 End;
 If (Mouse.Y>=TOOL_Y) And (Mouse.Y<TOOL_Y+TOOL_H) Then Begin
  I:=ToolHit(Mouse.X,Mouse.Y);
  If I>0 Then Begin
   If CmdEnabled(ToolCmd(I)) Then ExecCmd(ToolCmd(I));
   NeedRedraw:=True;
  End;
  Exit;
 End;
 If (DrawTool=DT_NONE) Or (CurCh=Nil) Then Exit;
 If Not InBox(Mouse.X,Mouse.Y,GP_X1,GP_Y1,GP_X2,GP_Y2) Then Exit;
 X0:=Mouse.X; Y0:=Mouse.Y;
 If DrawTool=DT_TEXT Then Begin
  S:='';
  If InputDialog('Draw Text','Text to place on the graph:',S,40) And (S<>'') Then AddDrawObject(DT_TEXT,X0,Y0,X0,Y0,S);
  NeedRedraw:=True;
  Exit;
 End;
 X1:=X0; Y1:=Y0;
 HideMouse;
 RubberBand(DrawTool,X0,Y0,X1,Y1);
 While LeftDown Do Begin
  UpdateMouse;
  PX:=Mouse.X; PY:=Mouse.Y;
  If PX<GP_X1 Then PX:=GP_X1; If PX>GP_X2 Then PX:=GP_X2;
  If PY<GP_Y1 Then PY:=GP_Y1; If PY>GP_Y2 Then PY:=GP_Y2;
  If (PX<>X1) Or (PY<>Y1) Then Begin
   RubberBand(DrawTool,X0,Y0,X1,Y1);
   X1:=PX; Y1:=PY;
   RubberBand(DrawTool,X0,Y0,X1,Y1);
  End;
  Delay(2);
 End;
 RubberBand(DrawTool,X0,Y0,X1,Y1);
 ShowMouse;
 If (Abs(X1-X0)>2) Or (Abs(Y1-Y0)>2) Then AddDrawObject(DrawTool,X0,Y0,X1,Y1,'');
 NeedRedraw:=True;
End;

Procedure HandleMouse;
Begin
 If AppMode=0 Then HandleMouseSheet Else HandleMouseGraph;
End;

{ ====================================================================== }
{                       BOUCLE PRINCIPALE                                }
{ ====================================================================== }

Procedure MainLoop;
Var K1,K2: Char;
Begin
 NeedRedraw:=True;
 Repeat
  If NeedRedraw Then Begin
   DrawAll;
   NeedRedraw:=False;
  End;
  UpdateMouse;
  If KeyPressed Then Begin
   K1:=ReadKey;
   K2:=#0;
   If K1=#0 Then K2:=ReadKey;
   HandleKey(K1,K2);
   NeedRedraw:=True;
  End;
  HandleMouse;
  Delay(2);
 Until Quit;
End;

Function HelpRequested: Boolean;
Var I: Integer; A: String;
Begin
 HelpRequested:=False;
 For I:=1 To ParamCount Do Begin
  A:=UpStr(ParamStr(I));
  If (A='/?') Or (A='-H') Or (A='--HELP') Then HelpRequested:=True;
 End;
End;

Procedure ShowCommandLineHelp;
Var T: Text;
Begin
 Assign(T,'');
 Rewrite(T);
 If UpStr(Copy(GetEnv('LANGUAGE'),1,2))='EN' Then Begin
  WriteLn(T,'LOTUS123 - Clone of the Lotus 1-2-3 spreadsheet.');
  WriteLn(T);
  WriteLn(T,'Usage: LOTUS123 [workbook] [/?]');
  WriteLn(T);
  WriteLn(T,'  workbook   .WKC (native format) or .WK1 file to open at startup.');
  WriteLn(T,'  /?         Show this help and exit.');
  WriteLn(T);
  WriteLn(T,'Language: French by default; set the environment variable LANGUAGE=EN for English.');
  WriteLn(T,'Menus: mouse, F10 or /, Alt+letter (the underlined letter of each menu).');
  WriteLn(T,'Formulas: +A1*B1  @SUM(A1..A9)  @IF(A1>0,"yes","no")');
  WriteLn(T,'Graph > New creates a chart; Graph > Add to Sheet places it in the worksheet.');
 End Else Begin
  WriteLn(T,'LOTUS123 - Clone du tableur Lotus 1-2-3.');
  WriteLn(T);
  WriteLn(T,'Utilisation : LOTUS123 [classeur] [/?]');
  WriteLn(T);
  WriteLn(T,'  classeur   Fichier .WKC (format natif) ou .WK1 a ouvrir au demarrage.');
  WriteLn(T,'  /?         Affiche cette aide et quitte.');
  WriteLn(T);
  WriteLn(T,'Langue : francais par defaut ; definir la variable d''environnement LANGUAGE=EN pour l''anglais.');
  WriteLn(T,'Menus : souris, F10 ou /, Alt+lettre (la lettre soulignee de chaque menu).');
  WriteLn(T,'Formules : +A1*B1  @SUM(A1..A9)  @IF(A1>0,"oui","non")');
  WriteLn(T,'Graph > New cree un graphique ; Graph > Add to Sheet le place dans la feuille.');
 End;
 Close(T);
End;

Procedure InitProgram;
Var I: Integer;
Begin
 For I:=1 To MAX_SHEETS Do Sheets[I]:=Nil;
 For I:=1 To MAX_CHARTS Do Charts[I]:=Nil;
 For I:=1 To MAX_PLACED Do Placed[I].Used:=False;
 ChD:=Nil;
 NameCount:=0;
 CurChart:=0;
 ActSheet:=1;
 SheetPtr(1);
 CurR:=0; CurC:=0; ScrollR:=0; ScrollC:=0;
 CollapseSel;
 FileName:='';
 Modified:=False;
 CalcStamp:=1;
 AutoCalc:=True; ShowGrid:=True; ShowHead:=True; ShowTools:=True;
 CircFound:=False; ParseFail:=False;
 FDepth:=0; DepthHit:=False;
 InputMode:=False; InputBuf:=''; InputPos:=1; InputEdit:=False;
 InsertMode:=False; EndMode:=False; SelMode:=False;
 StatusMsg:='';
 Dragging:=False; DragMode:=0;
 AppMode:=0; Quit:=False;
 MenuOpen:=0; MenuHi:=0; SubOpen:=0; SubHi:=0; MenuActive:=False;
 ClipN:=0; ClipRows:=0; ClipCols:=0; ClipCut:=False;
 UndoTop:=Nil; UndoCount:=0;
 DrawTool:=DT_NONE; GObjSel:=0; OffX:=0; OffY:=0;
 FindText:='';
 Mouse.X:=0; Mouse.Y:=0; Mouse.B:=0; LastB:=0;
 LastClkT:=0; LastClkR:=-1; LastClkC:=-1;
 NeedRedraw:=True;
 Randomize;
 French:=UpStr(Copy(GetEnv('LANGUAGE'),1,2))<>'EN';
End;

BEGIN
 If HelpRequested Then Begin ShowCommandLineHelp; Halt(0); End;
 InitializeGraphics;
 If MouseDriverFound Then ShowMouse;
 InitProgram;
 If ParamCount>=1 Then Begin
  If (ParamStr(1)<>'') And (ParamStr(1)[1]<>'/') And (ParamStr(1)[1]<>'-') Then Begin
   If FileExists(ParamStr(1)) Then Begin
    If LoadAny(ParamStr(1)) Then FileName:=ParamStr(1)
    Else MessageBox('Open File','Cannot read '+ParamStr(1));
   End Else MessageBox('Open File','File not found: '+ParamStr(1));
  End;
 End;
 MainLoop;
 CloseGraph;
END.
