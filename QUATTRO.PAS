{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application QUATTRO
}

{$IFNDEF FPC}
 {$N+,E+}
 {$M 49152,0,655360}
{$ENDIF}

Program QUATTRO;

Uses {$IFDEF FPC}
      DOS,Crt,PtcGraph,PtcCrt,PtcMouse
     {$ELSE}
      DOS,Crt,Graph
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
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 SCR_W      = 640;
 SCR_H      = 480;
 MAX_ROWS   = 8192;
 MAX_COLS   = 256;
 MAX_WIN    = 5;
 MAX_NAMES  = 40;
 MAX_ARGS   = 8;
 MB_LEFT    = 1;
 MB_RIGHT   = 2;

 ROW_H      = 17;
 HDR_H      = 14;
 GRID_L     = 32;
 GRID_R     = 631;
 GRID_BOT   = 445;
 HSB_Y      = 447;
 STAT_Y     = 462;

 { Couleurs VGA }
 CL_BLACK   = 0;
 CL_BLUE    = 1;
 CL_GREEN   = 2;
 CL_CYAN    = 3;
 CL_RED     = 4;
 CL_MAGENTA = 5;
 CL_BROWN   = 6;
 CL_LGRAY   = 7;
 CL_DGRAY   = 8;
 CL_LBLUE   = 9;
 CL_LGREEN  = 10;
 CL_LCYAN   = 11;
 CL_LRED    = 12;
 CL_LMAG    = 13;
 CL_YELLOW  = 14;
 CL_WHITE   = 15;

 { Types de cellules }
 CK_EMPTY   = 0;
 CK_LABEL   = 1;
 CK_NUM     = 2;
 CK_FORMULA = 3;

 { Formats numeriques }
 FM_GEN     = 0;
 FM_FIXED   = 1;
 FM_SCI     = 2;
 FM_CURR    = 3;
 FM_COMMA   = 4;
 FM_PLUS    = 5;
 FM_PCT     = 6;
 FM_DATE    = 7;
 FM_TEXT    = 8;
 FM_HIDDEN  = 9;
 FM_TIME    = 10;

 { Alignements }
 AL_DEF     = 0;
 AL_LEFT    = 1;
 AL_RIGHT   = 2;
 AL_CENTER  = 3;
 AL_REPEAT  = 4;

 { Codes de touches (extended = 256 + code) }
 KEY_ENTER  = 13;
 KEY_ESC    = 27;
 KEY_BS     = 8;
 KEY_TAB    = 9;
 KEY_UP     = 256+72;
 KEY_DOWN   = 256+80;
 KEY_LEFT   = 256+75;
 KEY_RIGHT  = 256+77;
 KEY_HOME   = 256+71;
 KEY_END    = 256+79;
 KEY_PGUP   = 256+73;
 KEY_PGDN   = 256+81;
 KEY_INS    = 256+82;
 KEY_DEL    = 256+83;
 KEY_F1     = 256+59;
 KEY_F2     = 256+60;
 KEY_F4     = 256+62;
 KEY_F5     = 256+63;
 KEY_F6     = 256+64;
 KEY_F7     = 256+65;
 KEY_F9     = 256+67;
 KEY_F10    = 256+68;
 KEY_SHTAB  = 256+15;
 KEY_SHF7   = 256+90;
 KEY_CLEFT  = 256+115;
 KEY_CRIGHT = 256+116;
 KEY_CEND   = 256+117;
 KEY_CPGDN  = 256+118;
 KEY_CHOME  = 256+119;
 KEY_CPGUP  = 256+132;
 KEY_ALTF5  = 256+108;
 KEY_ALT_F  = 256+33;
 KEY_ALT_E  = 256+18;
 KEY_ALT_S  = 256+31;
 KEY_ALT_G  = 256+34;
 KEY_ALT_I  = 256+23;
 KEY_ALT_B  = 256+48;
 KEY_ALT_O  = 256+24;
 KEY_ALT_D  = 256+32;
 KEY_ALT_N  = 256+49;
 KEY_CTRL_S = 19;
 KEY_CTRL_Q = 17;
 KEY_CTRL_C = 3;

 { Identifiants des fonctions @ }
 F_SUM=1;  F_AVG=2;  F_MIN=3;  F_MAX=4;  F_COUNT=5; F_STD=6; F_VAR=7;
 F_ABS=10; F_INT=11; F_ROUND=12; F_SQRT=13; F_EXP=14; F_LN=15; F_LOG=16;
 F_SIN=17; F_COS=18; F_TAN=19; F_ASIN=20; F_ACOS=21; F_ATAN=22; F_ATAN2=23;
 F_PI=24;  F_MOD=25; F_RAND=26; F_SIGN=27;
 F_IF=30;  F_TRUE=31; F_FALSE=32; F_NA=33; F_ERR=34; F_ISNUM=35; F_ISSTR=36;
 F_ISERR=37; F_ISNA=38;
 F_LEN=40; F_LEFT=41; F_RIGHT=42; F_MID=43; F_UPPER=44; F_LOWER=45;
 F_PROPER=46; F_TRIM=47; F_STRING=48; F_VALUE=49; F_REPEAT=50; F_CHAR=51;
 F_CODE=52;
 F_NOW=60; F_TODAY=61; F_DATE=62; F_YEAR=63; F_MONTH=64; F_DAY=65;
 F_HOUR=66; F_MINUTE=67; F_SECOND=68; F_TIME=69;
 F_CHOOSE=70; F_VLOOKUP=71; F_HLOOKUP=72; F_INDEX=73; F_ROWS=74; F_COLS=75;
 F_PMT=80; F_PV=81; F_FV=82; F_NPV=83;

 FN_COUNT = 107;

 {$IFDEF FPC}
 EV_CAP   = 250;
 MAX_SNAP = 60000;
 {$ELSE}
 EV_CAP   = 18;
 MAX_SNAP = 1800;
 {$ENDIF}

 MAXLST   = 1200;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 PStr = ^String;
 PCell = ^TCell;
 TCell = Record
  Kind, Fmt, Dec, Al, Fnt, Prot, Calc, ResK, ErrC: Byte;
  Num: Double;
  Txt, Res: PStr;
 End;
 PRowArr = ^TRowArr;
 TRowArr = Array[0..MAX_COLS-1] Of PCell;
 PRowTab = ^TRowTab;
 TRowTab = Array[0..MAX_ROWS-1] Of PRowArr;

 TRange = Record
  R1, C1, R2, C2: Integer;
 End;

 TStyle = Record
  Fmt, Dec, Al, Fnt, Prot, Used: Byte;
 End;

 TName = Record
  Nm: String[15];
  R: TRange;
 End;

 TGraph = Record
  GType: Byte;
  Ser: Array[0..6] Of TRange;
  SerOn: Array[0..6] Of Boolean;
  T1, T2, TX, TY: String[40];
  Grid: Boolean;
 End;

 PSheet = ^TSheet;
 TSheet = Record
  Name: String[150];
  Titled, Modified: Boolean;
  Rows: PRowTab;
  ColW: Array[0..MAX_COLS-1] Of Byte;
  ColSty: Array[0..MAX_COLS-1] Of TStyle;
  CurR, CurC, TopR, LeftC: Integer;
  SelOn: Boolean;
  SelMode: Byte;
  AnchR, AnchC: Integer;
  LockR, LockC: Integer;
  NameCnt: Integer;
  Names: Array[1..MAX_NAMES] Of TName;
  PrintR: TRange;
  PrintOn: Boolean;
  Hdr, Ftr: String[60];
  Gr: TGraph;
  SortR: TRange;
  SortOn: Boolean;
  SortKey: Integer;
  SortDesc: Boolean;
  DbR, CrR, OuR: TRange;
  DbOn, CrOn, OuOn: Boolean;
  UndoRows: PRowTab;
  UndoW: Array[0..MAX_COLS-1] Of Byte;
  UndoSty: Array[0..MAX_COLS-1] Of TStyle;
  HasUndo: Boolean;
 End;

 TVal = Record
  K: Byte;            { 0 nombre, 1 texte, 2 erreur }
  E: Byte;            { code d'erreur : 1 ERR, 2 NA }
  N: Double;
  S: String[120];
 End;

 TAgg = Record
  Cnt, CntAll: LongInt;
  Sum, SumSq, Mn, Mx: Double;
  Err: Byte;
 End;

 TFnDef = Record
  Nm: String[11];
  Id: Byte;
 End;

 TSnap = Record
  Dr, Dc: Integer;
  Cell: TCell;
 End;
 PSnapArr = ^TSnapArr;
 TSnapArr = Array[0..0] Of TSnap;

 TPend = Array[0..4095] Of Integer;
 PPend = ^TPend;
 PLstArr = ^TLstArr;
 TLstArr = Array[1..MAXLST] Of PStr;

Const
 FnTab: Array[1..FN_COUNT] Of TFnDef = (
  (Nm:'SUM';Id:1),(Nm:'SOMME';Id:1),(Nm:'AVG';Id:2),(Nm:'MOYENNE';Id:2),
  (Nm:'MIN';Id:3),(Nm:'MAX';Id:4),(Nm:'COUNT';Id:5),(Nm:'NB';Id:5),
  (Nm:'STD';Id:6),(Nm:'ECARTYPE';Id:6),(Nm:'VAR';Id:7),(Nm:'ABS';Id:10),
  (Nm:'INT';Id:11),(Nm:'ENT';Id:11),(Nm:'ROUND';Id:12),(Nm:'ARRONDI';Id:12),
  (Nm:'SQRT';Id:13),(Nm:'RACINE';Id:13),(Nm:'EXP';Id:14),(Nm:'LN';Id:15),
  (Nm:'LOG';Id:16),(Nm:'SIN';Id:17),(Nm:'COS';Id:18),(Nm:'TAN';Id:19),
  (Nm:'ASIN';Id:20),(Nm:'ACOS';Id:21),(Nm:'ATAN';Id:22),(Nm:'ATAN2';Id:23),
  (Nm:'PI';Id:24),(Nm:'MOD';Id:25),(Nm:'RAND';Id:26),(Nm:'ALEA';Id:26),
  (Nm:'SIGN';Id:27),(Nm:'SIGNE';Id:27),
  (Nm:'IF';Id:30),(Nm:'SI';Id:30),(Nm:'TRUE';Id:31),(Nm:'VRAI';Id:31),
  (Nm:'FALSE';Id:32),(Nm:'FAUX';Id:32),(Nm:'NA';Id:33),(Nm:'ERR';Id:34),
  (Nm:'ISNUMBER';Id:35),(Nm:'ISSTRING';Id:36),(Nm:'ISERR';Id:37),
  (Nm:'ISNA';Id:38),
  (Nm:'LEN';Id:40),(Nm:'NBCAR';Id:40),(Nm:'LEFT';Id:41),(Nm:'GAUCHE';Id:41),
  (Nm:'RIGHT';Id:42),(Nm:'DROITE';Id:42),(Nm:'MID';Id:43),(Nm:'STXT';Id:43),
  (Nm:'UPPER';Id:44),(Nm:'MAJUSCULE';Id:44),(Nm:'LOWER';Id:45),
  (Nm:'MINUSCULE';Id:45),(Nm:'PROPER';Id:46),(Nm:'NOMPROPRE';Id:46),
  (Nm:'TRIM';Id:47),(Nm:'SUPPRESPACE';Id:47),(Nm:'STRING';Id:48),
  (Nm:'CHAINE';Id:48),(Nm:'VALUE';Id:49),(Nm:'VALEUR';Id:49),
  (Nm:'REPEAT';Id:50),(Nm:'REPETE';Id:50),(Nm:'CHAR';Id:51),(Nm:'CODE';Id:52),
  (Nm:'NOW';Id:60),(Nm:'MAINTENANT';Id:60),(Nm:'TODAY';Id:61),
  (Nm:'AUJOURDHUI';Id:61),(Nm:'DATE';Id:62),(Nm:'YEAR';Id:63),
  (Nm:'ANNEE';Id:63),(Nm:'MONTH';Id:64),(Nm:'MOIS';Id:64),(Nm:'DAY';Id:65),
  (Nm:'JOUR';Id:65),(Nm:'HOUR';Id:66),(Nm:'HEURE';Id:66),(Nm:'MINUTE';Id:67),
  (Nm:'SECOND';Id:68),(Nm:'SECONDE';Id:68),(Nm:'TIME';Id:69),(Nm:'TEMPS';Id:69),
  (Nm:'CHOOSE';Id:70),(Nm:'CHOISIR';Id:70),(Nm:'VLOOKUP';Id:71),
  (Nm:'RECHERCHEV';Id:71),(Nm:'HLOOKUP';Id:72),(Nm:'RECHERCHEH';Id:72),
  (Nm:'INDEX';Id:73),(Nm:'ROWS';Id:74),(Nm:'LIGNES';Id:74),(Nm:'COLS';Id:75),
  (Nm:'COLONNES';Id:75),(Nm:'PMT';Id:80),(Nm:'VPM';Id:80),(Nm:'PV';Id:81),
  (Nm:'VA';Id:81),(Nm:'FV';Id:82),(Nm:'VC';Id:82),(Nm:'NPV';Id:83),
  (Nm:'VAN';Id:83));

 MonthAbbr: Array[1..12] Of String[3] =
  ('JAN','F'#144'V','MAR','AVR','MAI','JUN','JUL','AO'#150,'SEP','OCT','NOV','D'#144'C');

{ ====================================================================== }
{                           VARIABLES GLOBALES                           }
{ ====================================================================== }

Var
 Win       : Array[1..MAX_WIN] Of PSheet;
 NWin      : Integer;
 CurWin    : Integer;
 Sh        : PSheet;          { feuille courante }

 { Parametres par defaut }
 DefColW   : Integer;
 DefFmt    : Integer;
 DefDec    : Integer;
 CurrSym   : String[4];
 DecSep    : Char;
 ShowBar   : Boolean;
 ShowGrid  : Boolean;
 BarSet    : Integer;
 AutoCalc  : Boolean;
 DataDir   : String;
 SqzEmpty  : Boolean;
 SqzValue  : Boolean;
 SqzVerA   : Boolean;
 PrintDest : Integer;
 PageW     : Integer;
 PageH     : Integer;

 { Evaluation }
 EvS       : String;
 EvP       : Integer;
 EvBad     : Boolean;
 EvDepth   : Integer;
 CircFlag  : Boolean;
 Deferred  : Boolean;
 DeferR    : Integer;
 DeferC    : Integer;
 NeedCalc  : Boolean;

 { Reecriture de references }
 RW_Mode   : Integer;
 RW_DR     : Integer;
 RW_DC     : Integer;
 RW_Rng    : TRange;
 RW_At     : Integer;
 RW_N      : Integer;

 { Presentation }
 YInp, YHdr, YGrid : Integer;
 NVC, NVR  : Integer;
 VC        : Array[0..63] Of Integer;
 VX        : Array[0..63] Of Integer;
 VR        : Array[0..63] Of Integer;
 VY        : Array[0..63] Of Integer;

 { Souris }
 MsX, MsY, MsBtn, LastBtn : LongInt;
 MsSaved   : Boolean;
 MsSaveBuf : Pointer;
 MsSaveX, MsSaveY : LongInt;
 MsSaveSz  : Word;
 EdgeDown, EdgeUp : Boolean;

 { Etat de saisie }
 Editing   : Boolean;
 EdMode    : Integer;        { 0 nouvelle saisie, 1 edition (F2) }
 EdTxt     : String;
 EdPos     : Integer;
 EndMode   : Boolean;
 PromptOn  : Boolean;
 PromptTitle : String;
 PromptTxt : String;
 PromptPos : Integer;
 ModeStr   : String[8];
 StatHelp  : String;
 MenuTop   : Integer;
 QuitFlag  : Boolean;
 LastMin   : Word;
 SearchStr : String;
 SrchR, SrchC : Integer;

 Lst       : PLstArr;
 LstN      : Integer;
 PrintFile : Text;
 PrintOpen : Boolean;

{ ====================================================================== }
{                          UTILITAIRES DE BASE                           }
{ ====================================================================== }

Function IntStr(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 IntStr:=S;
End;

Function UpStr(Const S: String): String;
Var I: Integer; T: String;
Begin
 T:=S;
 For I:=1 To Length(T) Do T[I]:=UpCase(T[I]);
 UpStr:=T;
End;

Function Rep(Ch: Char; N: Integer): String;
Var S: String; I: Integer;
Begin
 S:='';
 If N>250 Then N:=250;
 For I:=1 To N Do S:=S+Ch;
 Rep:=S;
End;

Function TrimStr(Const S: String): String;
Var A, B: Integer;
Begin
 A:=1; B:=Length(S);
 While (A<=B) And (S[A]=' ') Do Inc(A);
 While (B>=A) And (S[B]=' ') Do Dec(B);
 TrimStr:=Copy(S,A,B-A+1);
End;

Function BaseName(Const S: String): String;
Var I: Integer;
Begin
 I:=Length(S);
 While (I>0) And (S[I]<>'\') And (S[I]<>'/') And (S[I]<>':') Do Dec(I);
 BaseName:=Copy(S,I+1,255);
End;

Function ExtOf(Const S: String): String;
Var I: Integer; B: String;
Begin
 B:=BaseName(S);
 I:=Length(B);
 While (I>0) And (B[I]<>'.') Do Dec(I);
 If I=0 Then ExtOf:='' Else ExtOf:=UpStr(Copy(B,I,10));
End;

Function IsAlphaCh(C: Char): Boolean;
Begin
 IsAlphaCh:=C In ['A'..'Z','a'..'z'];
End;

Function IsDigitCh(C: Char): Boolean;
Begin
 IsDigitCh:=C In ['0'..'9'];
End;

Function MinI(A, B: Integer): Integer;
Begin
 If A<B Then MinI:=A Else MinI:=B;
End;

Function MaxI(A, B: Integer): Integer;
Begin
 If A>B Then MaxI:=A Else MaxI:=B;
End;

Function ColName(C: Integer): String;
Begin
 If C<26 Then ColName:=Chr(65+C)
         Else ColName:=Chr(64+(C Div 26))+Chr(65+(C Mod 26));
End;

Function CellName(R, C: Integer): String;
Begin
 CellName:=ColName(C)+IntStr(R+1);
End;

Function RangeStr(Const G: TRange): String;
Begin
 If (G.R1=G.R2) And (G.C1=G.C2) Then RangeStr:=CellName(G.R1,G.C1)
  Else RangeStr:=CellName(G.R1,G.C1)+'..'+CellName(G.R2,G.C2);
End;

Procedure SetRange(Var G: TRange; R1, C1, R2, C2: Integer);
Begin
 G.R1:=R1; G.C1:=C1; G.R2:=R2; G.C2:=C2;
End;

Procedure NormRange(Var G: TRange);
Var T: Integer;
Begin
 If G.R1>G.R2 Then Begin T:=G.R1; G.R1:=G.R2; G.R2:=T; End;
 If G.C1>G.C2 Then Begin T:=G.C1; G.C1:=G.C2; G.C2:=T; End;
End;

Function SameStr(Const A, B: String): Boolean;
Begin
 SameStr:=UpStr(A)=UpStr(B);
End;

Procedure SetStr(Var P: PStr; Const S: String);
Begin
 If P<>Nil Then Begin FreeMem(P,Length(P^)+1); P:=Nil; End;
 If S<>'' Then Begin
  GetMem(P,Length(S)+1);
  Move(S[0],P^[0],Length(S)+1);
 End;
End;

Function GetStr(P: PStr): String;
Begin
 If P=Nil Then GetStr:='' Else GetStr:=P^;
End;

{ ====================================================================== }
{                       DATES (serie Lotus / Excel)                      }
{ ====================================================================== }

Function DateToSerial(Y, M, D: LongInt): LongInt;
Var Era, Yoe, Doy, Doe, Days, S: LongInt;
Begin
 If M<=2 Then Dec(Y);
 If Y>=0 Then Era:=Y Div 400 Else Era:=(Y-399) Div 400;
 Yoe:=Y-Era*400;
 If M>2 Then Doy:=(153*(M-3)+2) Div 5+D-1
        Else Doy:=(153*(M+9)+2) Div 5+D-1;
 Doe:=Yoe*365+Yoe Div 4-Yoe Div 100+Doy;
 Days:=Era*146097+Doe-719468;
 S:=Days+25569;
 If S<61 Then Dec(S);
 DateToSerial:=S;
End;

Procedure SerialToDate(N: LongInt; Var Y, M, D: LongInt);
Var Z, Era, Doe, Yoe, Doy, Mp, S: LongInt;
Begin
 S:=N;
 If S<61 Then Inc(S);
 Z:=S-25569+719468;
 If Z>=0 Then Era:=Z Div 146097 Else Era:=(Z-146096) Div 146097;
 Doe:=Z-Era*146097;
 Yoe:=(Doe-Doe Div 1460+Doe Div 36524-Doe Div 146096) Div 365;
 Y:=Yoe+Era*400;
 Doy:=Doe-(365*Yoe+Yoe Div 4-Yoe Div 100);
 Mp:=(5*Doy+2) Div 153;
 D:=Doy-(153*Mp+2) Div 5+1;
 If Mp<10 Then M:=Mp+3 Else M:=Mp-9;
 If M<=2 Then Inc(Y);
End;

Function NowSerial: Double;
Var Y, M, D, Dw, H, Mi, S, S100: Word;
Begin
 GetDate(Y,M,D,Dw);
 GetTime(H,Mi,S,S100);
 NowSerial:=DateToSerial(Y,M,D)+(H*3600.0+Mi*60.0+S)/86400.0;
End;

{ ====================================================================== }
{                         FORMATAGE DES NOMBRES                          }
{ ====================================================================== }

Function SciStr(X: Double; D: Integer): String;
Var A, M: Double; E: Integer; Ms, Es, Sg: String;
Begin
 If X=0 Then Begin
  Str(0.0:0:D,Ms);
  SciStr:=Ms+'E+00';
  Exit;
 End;
 A:=Abs(X);
 E:=0; M:=A;
 While M>=10 Do Begin M:=M/10; Inc(E); End;
 While M<1 Do Begin M:=M*10; Dec(E); End;
 Str(M:0:D,Ms);
 If Copy(Ms,1,2)='10' Then Begin
  M:=M/10; Inc(E);
  Str(M:0:D,Ms);
 End;
 If E<0 Then Begin Sg:='-'; E:=-E; End Else Sg:='+';
 Es:=IntStr(E);
 If Length(Es)<2 Then Es:='0'+Es;
 If X<0 Then Ms:='-'+Ms;
 SciStr:=Ms+'E'+Sg+Es;
End;

Function TrimZeros(Const S: String): String;
Var T: String;
Begin
 T:=S;
 If Pos('.',T)>0 Then Begin
  While (Length(T)>0) And (T[Length(T)]='0') Do Delete(T,Length(T),1);
  If (Length(T)>0) And (T[Length(T)]='.') Then Delete(T,Length(T),1);
 End;
 If (T='') Or (T='-') Or (T='-0') Then T:='0';
 TrimZeros:=T;
End;

Function FixStr(X: Double; D: Integer): String;
Var S: String; I: Integer; Z: Boolean;
Begin
 If Abs(X)>=1E15 Then Begin FixStr:=SciStr(X,2); Exit; End;
 Str(X:0:D,S);
 If (Length(S)>0) And (S[1]='-') Then Begin
  Z:=True;
  For I:=2 To Length(S) Do If (S[I]<>'0') And (S[I]<>'.') Then Z:=False;
  If Z Then Delete(S,1,1);
 End;
 FixStr:=S;
End;

Function GenStr(X: Double; MaxLen: Integer): String;
Var A: Double; S: String; D, Dd0, ID: Integer;
Begin
 If X=0 Then Begin GenStr:='0'; Exit; End;
 A:=Abs(X);
 If (A>=1E15) Or (A<1E-5) Then Begin
  For D:=6 Downto 0 Do Begin
   S:=SciStr(X,D);
   If (MaxLen<=0) Or (Length(S)<=MaxLen) Then Begin GenStr:=S; Exit; End;
  End;
  GenStr:='';
  Exit;
 End;
 ID:=1;
 If A>=1 Then Begin
  ID:=Length(IntStr(Trunc(A)));
 End;
 Dd0:=14-ID;
 If Dd0>10 Then Dd0:=10;
 If Dd0<0 Then Dd0:=0;
 For D:=Dd0 Downto 0 Do Begin
  S:=FixStr(X,D);
  If D>0 Then S:=TrimZeros(S);
  If (MaxLen<=0) Or (Length(S)<=MaxLen) Then Begin GenStr:=S; Exit; End;
 End;
 For D:=5 Downto 0 Do Begin
  S:=SciStr(X,D);
  If (MaxLen<=0) Or (Length(S)<=MaxLen) Then Begin GenStr:=S; Exit; End;
 End;
 GenStr:='';
End;

Function ThouStr(Const S: String): String;
Var T, R: String; I, P, N: Integer; Neg: Boolean; Ip, Fp: String;
Begin
 T:=S; Neg:=False;
 If (T<>'') And (T[1]='-') Then Begin Neg:=True; Delete(T,1,1); End;
 P:=Pos('.',T);
 If P>0 Then Begin Ip:=Copy(T,1,P-1); Fp:=Copy(T,P,255); End
        Else Begin Ip:=T; Fp:=''; End;
 R:=''; N:=0;
 For I:=Length(Ip) Downto 1 Do Begin
  R:=Ip[I]+R;
  Inc(N);
  If (N Mod 3=0) And (I>1) Then Begin
   If DecSep=',' Then R:=' '+R Else R:=','+R;
  End;
 End;
 If Neg Then R:='-'+R;
 ThouStr:=R+Fp;
End;

Function Localize(Const S: String): String;
Var T: String; I: Integer;
Begin
 T:=S;
 If DecSep<>'.' Then
  For I:=1 To Length(T) Do If T[I]='.' Then T[I]:=DecSep;
 Localize:=T;
End;

Function Pad2(N: LongInt): String;
Var S: String;
Begin
 S:=IntStr(N);
 If Length(S)<2 Then S:='0'+S;
 Pad2:=S;
End;

Function DateFmtStr(X: Double; Dc: Integer): String;
Var Y, M, D: LongInt; N: LongInt;
Begin
 If (X<1) Or (X>2958465) Then Begin DateFmtStr:='ERR'; Exit; End;
 N:=Trunc(X);
 SerialToDate(N,Y,M,D);
 Case Dc Of
  2: DateFmtStr:=Pad2(D)+'-'+MonthAbbr[M];
  3: DateFmtStr:=MonthAbbr[M]+'-'+Pad2(Y Mod 100);
  4: DateFmtStr:=Pad2(D)+'/'+Pad2(M)+'/'+Pad2(Y Mod 100);
  5: DateFmtStr:=Pad2(D)+'/'+Pad2(M);
  Else DateFmtStr:=Pad2(D)+'-'+MonthAbbr[M]+'-'+Pad2(Y Mod 100);
 End;
End;

Function TimeFmtStr(X: Double; Tc: Integer): String;
Var F: Double; Sec, H, Mi, S: LongInt; Ap: String; H12: LongInt;
Begin
 F:=X-Int(X);
 If F<0 Then F:=F+1;
 Sec:=Round(F*86400.0);
 If Sec>=86400 Then Sec:=Sec-86400;
 H:=Sec Div 3600; Mi:=(Sec Div 60) Mod 60; S:=Sec Mod 60;
 H12:=H Mod 12; If H12=0 Then H12:=12;
 If H<12 Then Ap:=' AM' Else Ap:=' PM';
 Case Tc Of
  1: TimeFmtStr:=Pad2(H12)+':'+Pad2(Mi)+':'+Pad2(S)+Ap;
  2: TimeFmtStr:=Pad2(H12)+':'+Pad2(Mi)+Ap;
  4: TimeFmtStr:=Pad2(H)+':'+Pad2(Mi);
  Else TimeFmtStr:=Pad2(H)+':'+Pad2(Mi)+':'+Pad2(S);
 End;
End;

{ Formate un nombre selon (Fmt,Dec) pour une cellule de Cap caracteres. }
Function FormatNum(X: Double; Fmt, Dec, Cap: Integer): String;
Var S: String; N, I: Integer; A: Double;
Begin
 Case Fmt Of
  FM_FIXED: S:=Localize(FixStr(X,Dec));
  FM_SCI:   S:=Localize(SciStr(X,Dec));
  FM_CURR:  Begin
             S:=ThouStr(FixStr(Abs(X),Dec));
             S:=CurrSym+S;
             If X<0 Then S:='('+S+')';
             S:=Localize(S);
            End;
  FM_COMMA: Begin
             S:=ThouStr(FixStr(Abs(X),Dec));
             If X<0 Then S:='('+S+')';
             S:=Localize(S);
            End;
  FM_PLUS:  Begin
             A:=Abs(X);
             If A>200 Then N:=200 Else N:=Round(A);
             If X=0 Then S:='.'
              Else If X>0 Then S:=Rep('+',N)
              Else S:=Rep('-',N);
            End;
  FM_PCT:   S:=Localize(FixStr(X*100,Dec))+'%';
  FM_DATE:  S:=DateFmtStr(X,Dec);
  FM_TIME:  S:=TimeFmtStr(X,Dec);
  FM_HIDDEN: S:='';
  Else      Begin
             S:=GenStr(X,Cap);
             If S<>'' Then S:=Localize(S);
            End;
 End;
 If (Cap>0) And ((S='') Or (Length(S)>Cap)) And (Fmt<>FM_HIDDEN) Then Begin
  If (Fmt=FM_PLUS) And (S<>'') Then S:=Copy(S,1,Cap)
   Else S:=Rep('*',Cap);
 End;
 FormatNum:=S;
End;

{ ====================================================================== }
{                       STOCKAGE DES FEUILLES / CELLULES                 }
{ ====================================================================== }

Procedure FreeCellData(P: PCell);
Begin
 SetStr(P^.Txt,'');
 SetStr(P^.Res,'');
End;

Procedure FreeRowTab(T: PRowTab);
Var R, C: Integer; RA: PRowArr;
Begin
 If T=Nil Then Exit;
 For R:=0 To MAX_ROWS-1 Do Begin
  RA:=T^[R];
  If RA<>Nil Then Begin
   For C:=0 To MAX_COLS-1 Do
    If RA^[C]<>Nil Then Begin
     FreeCellData(RA^[C]);
     Dispose(RA^[C]);
    End;
   FreeMem(RA,SizeOf(TRowArr));
  End;
 End;
 FreeMem(T,SizeOf(TRowTab));
End;

Function CloneRowTab(T: PRowTab): PRowTab;
Var N: PRowTab; R, C: Integer; RA, NR: PRowArr; NC: PCell;
Begin
 GetMem(N,SizeOf(TRowTab));
 FillChar(N^,SizeOf(TRowTab),0);
 For R:=0 To MAX_ROWS-1 Do Begin
  RA:=T^[R];
  If RA<>Nil Then Begin
   GetMem(NR,SizeOf(TRowArr));
   FillChar(NR^,SizeOf(TRowArr),0);
   For C:=0 To MAX_COLS-1 Do
    If RA^[C]<>Nil Then Begin
     New(NC);
     NC^:=RA^[C]^;
     NC^.Txt:=Nil; NC^.Res:=Nil;
     SetStr(NC^.Txt,GetStr(RA^[C]^.Txt));
     SetStr(NC^.Res,GetStr(RA^[C]^.Res));
     NR^[C]:=NC;
    End;
   N^[R]:=NR;
  End;
 End;
 CloneRowTab:=N;
End;

Function NewSheet(Const Nm: String): PSheet;
Var S: PSheet; I: Integer;
Begin
 New(S);
 FillChar(S^,SizeOf(TSheet),0);
 GetMem(S^.Rows,SizeOf(TRowTab));
 FillChar(S^.Rows^,SizeOf(TRowTab),0);
 For I:=0 To MAX_COLS-1 Do S^.ColW[I]:=DefColW;
 S^.Name:=Nm;
 S^.Titled:=False;
 S^.Gr.GType:=1;
 S^.Gr.Grid:=True;
 NewSheet:=S;
End;

Procedure FreeSheet(S: PSheet);
Begin
 FreeRowTab(S^.Rows);
 If S^.UndoRows<>Nil Then FreeRowTab(S^.UndoRows);
 Dispose(S);
End;

Function FindCell(S: PSheet; R, C: Integer): PCell;
Begin
 FindCell:=Nil;
 If (R<0) Or (R>=MAX_ROWS) Or (C<0) Or (C>=MAX_COLS) Then Exit;
 If S^.Rows^[R]=Nil Then Exit;
 FindCell:=S^.Rows^[R]^[C];
End;

Procedure ApplyDefStyle(S: PSheet; P: PCell; C: Integer);
Begin
 If S^.ColSty[C].Used<>0 Then Begin
  P^.Fmt:=S^.ColSty[C].Fmt; P^.Dec:=S^.ColSty[C].Dec;
  P^.Al:=S^.ColSty[C].Al;   P^.Fnt:=S^.ColSty[C].Fnt;
  P^.Prot:=S^.ColSty[C].Prot;
 End Else Begin
  P^.Fmt:=DefFmt; P^.Dec:=DefDec; P^.Al:=0; P^.Fnt:=0; P^.Prot:=0;
 End;
End;

Function MakeCell(S: PSheet; R, C: Integer): PCell;
Var RA: PRowArr; P: PCell;
Begin
 MakeCell:=Nil;
 If (R<0) Or (R>=MAX_ROWS) Or (C<0) Or (C>=MAX_COLS) Then Exit;
 RA:=S^.Rows^[R];
 If RA=Nil Then Begin
  GetMem(RA,SizeOf(TRowArr));
  FillChar(RA^,SizeOf(TRowArr),0);
  S^.Rows^[R]:=RA;
 End;
 P:=RA^[C];
 If P=Nil Then Begin
  New(P);
  FillChar(P^,SizeOf(TCell),0);
  ApplyDefStyle(S,P,C);
  RA^[C]:=P;
 End;
 MakeCell:=P;
End;

Procedure ResetCellContent(P: PCell);
Begin
 FreeCellData(P);
 P^.Kind:=CK_EMPTY; P^.Num:=0; P^.Calc:=0; P^.ResK:=0; P^.ErrC:=0;
End;

Procedure ClearCellContent(S: PSheet; R, C: Integer);
Var P: PCell;
Begin
 P:=FindCell(S,R,C);
 If P<>Nil Then ResetCellContent(P);
End;

{ Supprime completement la cellule (contenu et style). }
Procedure KillCell(S: PSheet; R, C: Integer);
Var P: PCell;
Begin
 P:=FindCell(S,R,C);
 If P<>Nil Then Begin
  FreeCellData(P);
  Dispose(P);
  S^.Rows^[R]^[C]:=Nil;
 End;
End;

Procedure SetLabel(P: PCell; Const T: String; Al: Byte);
Begin
 ResetCellContent(P);
 P^.Kind:=CK_LABEL;
 SetStr(P^.Txt,T);
 P^.Al:=Al;
End;

Procedure SetNumber(P: PCell; X: Double);
Begin
 ResetCellContent(P);
 P^.Kind:=CK_NUM;
 P^.Num:=X;
End;

Procedure SetFormula(P: PCell; Const T: String);
Begin
 ResetCellContent(P);
 P^.Kind:=CK_FORMULA;
 SetStr(P^.Txt,T);
 P^.Calc:=0;
End;

Procedure SaveUndo(S: PSheet);
Begin
 If S^.UndoRows<>Nil Then FreeRowTab(S^.UndoRows);
 S^.UndoRows:=CloneRowTab(S^.Rows);
 Move(S^.ColW,S^.UndoW,SizeOf(S^.ColW));
 Move(S^.ColSty,S^.UndoSty,SizeOf(S^.ColSty));
 S^.HasUndo:=True;
End;

Function UsedRows(S: PSheet): Integer;
Var R: Integer;
Begin
 R:=MAX_ROWS-1;
 While (R>=0) And (S^.Rows^[R]=Nil) Do Dec(R);
 UsedRows:=R;
End;

Function UsedCols(S: PSheet): Integer;
Var R, C, M: Integer;
Begin
 M:=-1;
 For R:=0 To MAX_ROWS-1 Do
  If S^.Rows^[R]<>Nil Then Begin
   C:=MAX_COLS-1;
   While (C>M) And (S^.Rows^[R]^[C]=Nil) Do Dec(C);
   If C>M Then M:=C;
  End;
 UsedCols:=M;
End;

Function ColPx(C: Integer): Integer;
Begin
 If Sh^.ColW[C]=0 Then ColPx:=0 Else ColPx:=Sh^.ColW[C]*7+1;
End;

{ ====================================================================== }
{                     NOMS, REFERENCES ET BLOCS                          }
{ ====================================================================== }

{ Analyse une reference de cellule a partir de S[P]. }
Function ScanRef(Const S: String; Var P: Integer; Var R, C: Integer;
                 Var AR, AC: Boolean): Boolean;
Var Q, L, V, N, D: Integer;
Begin
 ScanRef:=False;
 Q:=P; AC:=False; AR:=False;
 If (Q<=Length(S)) And (S[Q]='$') Then Begin AC:=True; Inc(Q); End;
 L:=0; V:=0;
 While (Q<=Length(S)) And IsAlphaCh(S[Q]) And (L<2) Do Begin
  V:=V*26+(Ord(UpCase(S[Q]))-64);
  Inc(L); Inc(Q);
 End;
 If L=0 Then Exit;
 If (Q<=Length(S)) And IsAlphaCh(S[Q]) Then Exit;
 If (Q<=Length(S)) And (S[Q]='$') Then Begin AR:=True; Inc(Q); End;
 N:=0; D:=0;
 While (Q<=Length(S)) And IsDigitCh(S[Q]) And (D<5) Do Begin
  N:=N*10+(Ord(S[Q])-48);
  Inc(D); Inc(Q);
 End;
 If D=0 Then Exit;
 If Q<=Length(S) Then
  If IsAlphaCh(S[Q]) Or IsDigitCh(S[Q]) Or (S[Q]='_') Or (S[Q]='(') Then Exit;
 If (V<1) Or (V>MAX_COLS) Or (N<1) Or (N>MAX_ROWS) Then Exit;
 C:=V-1; R:=N-1; P:=Q;
 ScanRef:=True;
End;

Function FindName(Const Nm: String; Var G: TRange): Boolean;
Var I: Integer; U: String;
Begin
 FindName:=False;
 U:=UpStr(Nm);
 For I:=1 To Sh^.NameCnt Do
  If UpStr(Sh^.Names[I].Nm)=U Then Begin
   G:=Sh^.Names[I].R;
   FindName:=True;
   Exit;
  End;
End;

{ Convertit un texte (cellule, bloc A1..B2, A1:B2 ou nom) en bloc. }
Function ParseRangeStr(Const T: String; Var G: TRange): Boolean;
Var S: String; P, R, C, R2, C2, K: Integer; A1, A2: Boolean; Ok: Boolean;
Begin
 ParseRangeStr:=False;
 S:=TrimStr(T);
 If S='' Then Exit;
 P:=1;
 If ScanRef(S,P,R,C,A1,A2) Then Begin
  If P>Length(S) Then Begin
   SetRange(G,R,C,R,C);
   ParseRangeStr:=True;
   Exit;
  End;
  If (Copy(S,P,2)='..') Then Inc(P,2)
  Else If S[P]=':' Then Inc(P)
  Else Exit;
  K:=P;
  Ok:=ScanRef(S,K,R2,C2,A1,A2);
  If Ok And (K>Length(S)) Then Begin
   SetRange(G,R,C,R2,C2);
   NormRange(G);
   ParseRangeStr:=True;
  End;
  Exit;
 End;
 If FindName(S,G) Then ParseRangeStr:=True;
End;

Function NumToStrPlain(X: Double): String;
Var S: String;
Begin
 S:=GenStr(X,0);
 If S='' Then S:='0';
 NumToStrPlain:=S;
End;

{ ====================================================================== }
{               REECRITURE DES REFERENCES DANS LES FORMULES              }
{ ====================================================================== }
{ Modes : 1 copie (decalage relatif), 2 deplacement, 3 insertion lignes,  }
{ 4 insertion colonnes, 5 suppression lignes, 6 suppression colonnes.    }

Function AdjustPoint(Var R, C: Integer; AR, AC: Boolean): Boolean;
{ Retourne False si la reference est supprimee. }
Begin
 AdjustPoint:=True;
 Case RW_Mode Of
  1: Begin
      If Not AR Then R:=R+RW_DR;
      If Not AC Then C:=C+RW_DC;
      If (R<0) Or (R>=MAX_ROWS) Or (C<0) Or (C>=MAX_COLS) Then AdjustPoint:=False;
     End;
  2: If (R>=RW_Rng.R1) And (R<=RW_Rng.R2) And
        (C>=RW_Rng.C1) And (C<=RW_Rng.C2) Then Begin
      R:=R+RW_DR; C:=C+RW_DC;
     End;
  3: If R>=RW_At Then Begin R:=R+RW_N; If R>=MAX_ROWS Then AdjustPoint:=False; End;
  4: If C>=RW_At Then Begin C:=C+RW_N; If C>=MAX_COLS Then AdjustPoint:=False; End;
  5: Begin
      If (R>=RW_At) And (R<RW_At+RW_N) Then AdjustPoint:=False
       Else If R>=RW_At+RW_N Then R:=R-RW_N;
     End;
  6: Begin
      If (C>=RW_At) And (C<RW_At+RW_N) Then AdjustPoint:=False
       Else If C>=RW_At+RW_N Then C:=C-RW_N;
     End;
 End;
End;

{ Ajuste un bloc (extremites traitees ensemble pour les suppressions). }
Function AdjustPair(Var R1, C1, R2, C2: Integer; AR1, AC1, AR2, AC2: Boolean): Boolean;
Begin
 AdjustPair:=True;
 If RW_Mode=5 Then Begin
  If (R1>=RW_At) And (R2<RW_At+RW_N) And (R1<RW_At+RW_N) Then Begin AdjustPair:=False; Exit; End;
  If (R1>=RW_At) And (R1<RW_At+RW_N) Then R1:=RW_At Else If R1>=RW_At+RW_N Then R1:=R1-RW_N;
  If (R2>=RW_At) And (R2<RW_At+RW_N) Then R2:=RW_At-1 Else If R2>=RW_At+RW_N Then R2:=R2-RW_N;
  If R2<R1 Then AdjustPair:=False;
  Exit;
 End;
 If RW_Mode=6 Then Begin
  If (C1>=RW_At) And (C2<RW_At+RW_N) And (C1<RW_At+RW_N) Then Begin AdjustPair:=False; Exit; End;
  If (C1>=RW_At) And (C1<RW_At+RW_N) Then C1:=RW_At Else If C1>=RW_At+RW_N Then C1:=C1-RW_N;
  If (C2>=RW_At) And (C2<RW_At+RW_N) Then C2:=RW_At-1 Else If C2>=RW_At+RW_N Then C2:=C2-RW_N;
  If C2<C1 Then AdjustPair:=False;
  Exit;
 End;
 If Not AdjustPoint(R1,C1,AR1,AC1) Then AdjustPair:=False;
 If Not AdjustPoint(R2,C2,AR2,AC2) Then AdjustPair:=False;
End;

Function RefText(R, C: Integer; AR, AC: Boolean): String;
Var S: String;
Begin
 S:='';
 If AC Then S:='$';
 S:=S+ColName(C);
 If AR Then S:=S+'$';
 RefText:=S+IntStr(R+1);
End;

Function RewriteRefs(Const Src: String): String;
Var I, P, P2, R, C, R2, C2: Integer; A1, A2, B1, B2, InStr, Ok, Pair: Boolean;
    Out: String; Ch: Char; Prev: Char;
Begin
 Out:=''; I:=1; InStr:=False;
 While I<=Length(Src) Do Begin
  Ch:=Src[I];
  If Ch='"' Then Begin
   InStr:=Not InStr;
   Out:=Out+Ch; Inc(I);
  End Else If InStr Then Begin
   Out:=Out+Ch; Inc(I);
  End Else If (Ch='$') Or IsAlphaCh(Ch) Then Begin
   If I>1 Then Prev:=Src[I-1] Else Prev:=' ';
   P:=I;
   If (Not (IsAlphaCh(Prev) Or IsDigitCh(Prev) Or (Prev='_') Or (Prev='@')
      Or (Prev='.'))) And ScanRef(Src,P,R,C,A1,A2) Then Begin
    Pair:=False;
    P2:=P;
    If Copy(Src,P2,2)='..' Then Inc(P2,2)
    Else If (P2<=Length(Src)) And (Src[P2]=':') Then Inc(P2)
    Else P2:=0;
    If P2>0 Then Begin
     Ok:=ScanRef(Src,P2,R2,C2,B1,B2);
     If Ok Then Pair:=True;
    End;
    If Pair Then Begin
     If AdjustPair(R,C,R2,C2,A2,A1,B2,B1) Then
      Out:=Out+RefText(R,C,A2,A1)+'..'+RefText(R2,C2,B2,B1)
     Else Out:=Out+'@ERR';
     I:=P2;
    End Else Begin
     If AdjustPoint(R,C,A2,A1) Then Out:=Out+RefText(R,C,A2,A1)
      Else Out:=Out+'@ERR';
     I:=P;
    End;
   End Else Begin
    { identificateur ordinaire : copier tel quel }
    Out:=Out+Ch; Inc(I);
    While (I<=Length(Src)) And (IsAlphaCh(Src[I]) Or IsDigitCh(Src[I]) Or (Src[I]='_')) Do Begin
     Out:=Out+Src[I]; Inc(I);
    End;
   End;
  End Else Begin
   If IsDigitCh(Ch) Then Begin
    { nombre : copier en bloc pour ne pas confondre avec une reference }
    While (I<=Length(Src)) And (IsDigitCh(Src[I]) Or
          ((Src[I]='.') And Not ((I<Length(Src)) And (Src[I+1]='.')))) Do Begin
     Out:=Out+Src[I]; Inc(I);
    End;
   End Else Begin
    Out:=Out+Ch; Inc(I);
   End;
  End;
 End;
 RewriteRefs:=Out;
End;

{ ====================================================================== }
{                     EVALUATION DES FORMULES (@FONCTIONS)               }
{ ====================================================================== }

Var
 PendR, PendC : PPend;
 SyntaxBad    : Boolean;

Procedure VNum(Var V: TVal; X: Double);
Begin
 V.K:=0; V.E:=0; V.N:=X; V.S:='';
End;

Procedure VStr(Var V: TVal; Const S: String);
Begin
 V.K:=1; V.E:=0; V.N:=0; V.S:=S;
End;

Procedure VErr(Var V: TVal; Code: Byte);
Begin
 V.K:=2; V.E:=Code; V.N:=0; V.S:='';
End;

Function NumOf(Const V: TVal): Double;
Begin
 If V.K=0 Then NumOf:=V.N Else NumOf:=0;
End;

Function StrOf(Const V: TVal): String;
Begin
 If V.K=1 Then StrOf:=V.S
  Else If V.K=0 Then StrOf:=NumToStrPlain(V.N)
  Else StrOf:='ERR';
End;

Function SafeMul(A, B: Double; Var Ok: Boolean): Double;
Var L: Double;
Begin
 Ok:=True; SafeMul:=0;
 If (A=0) Or (B=0) Then Exit;
 L:=Ln(Abs(A))+Ln(Abs(B));
 If L>700 Then Begin Ok:=False; Exit; End;
 If L<-700 Then Exit;
 SafeMul:=A*B;
End;

Function SafeDiv(A, B: Double; Var Ok: Boolean): Double;
Var L: Double;
Begin
 Ok:=True; SafeDiv:=0;
 If B=0 Then Begin Ok:=False; Exit; End;
 If A=0 Then Exit;
 L:=Ln(Abs(A))-Ln(Abs(B));
 If L>700 Then Begin Ok:=False; Exit; End;
 If L<-700 Then Exit;
 SafeDiv:=A/B;
End;

Function SafePow(A, B: Double; Var Ok: Boolean): Double;
Var E: Double; Neg: Boolean;
Begin
 Ok:=True; SafePow:=0;
 If A=0 Then Begin
  If B>0 Then Exit;
  If B=0 Then Begin SafePow:=1; Exit; End;
  Ok:=False; Exit;
 End;
 Neg:=False;
 If A<0 Then Begin
  If Frac(B)<>0 Then Begin Ok:=False; Exit; End;
  If Abs(B)<1E9 Then Neg:=Odd(Round(B));
 End;
 E:=B*Ln(Abs(A));
 If E>700 Then Begin Ok:=False; Exit; End;
 If E<-700 Then Exit;
 If Neg Then SafePow:=-Exp(E) Else SafePow:=Exp(E);
End;

Function ArcTan2(Y, X: Double): Double;
Begin
 If X>0 Then ArcTan2:=ArcTan(Y/X)
 Else If X<0 Then Begin
  If Y>=0 Then ArcTan2:=ArcTan(Y/X)+Pi Else ArcTan2:=ArcTan(Y/X)-Pi;
 End Else Begin
  If Y>0 Then ArcTan2:=Pi/2 Else If Y<0 Then ArcTan2:=-Pi/2 Else ArcTan2:=0;
 End;
End;

Function TryNumber(Const S: String; Var X: Double): Boolean;
Var T, U: String; I, Dots, Digs, Code: Integer; Pct, Ok: Boolean; Ch: Char;
Begin
 TryNumber:=False;
 T:=TrimStr(S);
 If T='' Then Exit;
 Pct:=False;
 If T[Length(T)]='%' Then Begin Pct:=True; Delete(T,Length(T),1); End;
 If T='' Then Exit;
 U:=''; Dots:=0; Digs:=0; Ok:=True; I:=1;
 If (T[1]='+') Or (T[1]='-') Then Begin U:=T[1]; Inc(I); End;
 While (I<=Length(T)) And Ok Do Begin
  Ch:=T[I];
  If IsDigitCh(Ch) Then Begin U:=U+Ch; Inc(Digs); End
  Else If (Ch='.') Or ((Ch=',') And (DecSep=',')) Then Begin
   Inc(Dots);
   If Dots>1 Then Ok:=False Else U:=U+'.';
  End Else If (UpCase(Ch)='E') And (Digs>0) And (I<Length(T)) Then Begin
   U:=U+'E'; Inc(I);
   If (T[I]='+') Or (T[I]='-') Then Begin U:=U+T[I]; Inc(I); End;
   If I>Length(T) Then Ok:=False;
   While (I<=Length(T)) And Ok Do Begin
    If IsDigitCh(T[I]) Then Begin U:=U+T[I]; Inc(I); End Else Ok:=False;
   End;
   Dec(I);
  End Else Ok:=False;
  Inc(I);
 End;
 If (Not Ok) Or (Digs=0) Then Exit;
 If U[1]='.' Then U:='0'+U
  Else If (Length(U)>1) And ((U[1]='+') Or (U[1]='-')) And (U[2]='.') Then Insert('0',U,2);
 If Pos('.E',U)>0 Then Insert('0',U,Pos('.E',U)+1);
 If U[Length(U)]='.' Then U:=U+'0';
 Val(U,X,Code);
 If Code<>0 Then Exit;
 If Pct Then X:=X/100;
 TryNumber:=True;
End;

Procedure EvalFormula(Const Src: String; Var V: TVal); Forward;
Procedure ParseOr(Var V: TVal); Forward;

Procedure EnsureCalc(P: PCell; R, C: Integer);
Var V: TVal;
Begin
 If P^.Calc=2 Then Exit;
 If P^.Calc=1 Then Begin
  P^.ResK:=2; P^.ErrC:=1; CircFlag:=True;
  Exit;
 End;
 If Deferred Then Begin P^.ResK:=2; P^.ErrC:=1; Exit; End;
 If EvDepth>=EV_CAP Then Begin
  Deferred:=True; DeferR:=R; DeferC:=C;
  P^.ResK:=2; P^.ErrC:=1;
  Exit;
 End;
 P^.Calc:=1;
 Inc(EvDepth);
 EvalFormula(GetStr(P^.Txt),V);
 Dec(EvDepth);
 If Deferred Then Begin P^.Calc:=0; Exit; End;
 If V.K=2 Then Begin P^.ResK:=2; P^.ErrC:=V.E; End
 Else If V.K=1 Then Begin P^.ResK:=1; P^.ErrC:=0; SetStr(P^.Res,V.S); End
 Else Begin P^.ResK:=0; P^.ErrC:=0; P^.Num:=V.N; End;
 P^.Calc:=2;
End;

Procedure CellVal(R, C: Integer; Var V: TVal);
Var P: PCell;
Begin
 VNum(V,0);
 P:=FindCell(Sh,R,C);
 If P=Nil Then Exit;
 Case P^.Kind Of
  CK_LABEL: VStr(V,GetStr(P^.Txt));
  CK_NUM:   VNum(V,P^.Num);
  CK_FORMULA: Begin
   EnsureCalc(P,R,C);
   Case P^.ResK Of
    0: VNum(V,P^.Num);
    1: VStr(V,GetStr(P^.Res));
    Else VErr(V,P^.ErrC);
   End;
  End;
 End;
End;

Procedure SkipWs;
Begin
 While (EvP<=Length(EvS)) And (EvS[EvP]=' ') Do Inc(EvP);
End;

Function PeekC: Char;
Begin
 SkipWs;
 If EvP<=Length(EvS) Then PeekC:=EvS[EvP] Else PeekC:=#0;
End;

Function PeekWord(Const W: String): Boolean;
Begin
 SkipWs;
 PeekWord:=UpStr(Copy(EvS,EvP,Length(W)))=W;
End;

Procedure ParseNumLit(Var V: TVal);
Var S: String; X: Double; Code: Integer;
Begin
 S:='';
 While (EvP<=Length(EvS)) And (IsDigitCh(EvS[EvP]) Or
       ((EvS[EvP]='.') And Not ((EvP<Length(EvS)) And (EvS[EvP+1]='.')))) Do Begin
  S:=S+EvS[EvP]; Inc(EvP);
 End;
 If (EvP<Length(EvS)) And (UpCase(EvS[EvP])='E') Then Begin
  If IsDigitCh(EvS[EvP+1]) Or (((EvS[EvP+1]='+') Or (EvS[EvP+1]='-')) And
     (EvP+1<Length(EvS)) And IsDigitCh(EvS[EvP+2])) Then Begin
   S:=S+'E'; Inc(EvP);
   If (EvS[EvP]='+') Or (EvS[EvP]='-') Then Begin S:=S+EvS[EvP]; Inc(EvP); End;
   While (EvP<=Length(EvS)) And IsDigitCh(EvS[EvP]) Do Begin
    S:=S+EvS[EvP]; Inc(EvP);
   End;
  End;
 End;
 If S='' Then Begin EvBad:=True; VErr(V,1); Exit; End;
 If S[1]='.' Then S:='0'+S;
 If Pos('.E',S)>0 Then Insert('0',S,Pos('.E',S)+1);
 If S[Length(S)]='.' Then S:=S+'0';
 Val(S,X,Code);
 If Code<>0 Then Begin EvBad:=True; VErr(V,1); End
  Else VNum(V,X);
End;

Procedure ParseStrLit(Var V: TVal);
Var S: String; Done: Boolean;
Begin
 Inc(EvP);
 S:=''; Done:=False;
 While (EvP<=Length(EvS)) And Not Done Do Begin
  If EvS[EvP]='"' Then Done:=True Else S:=S+EvS[EvP];
  Inc(EvP);
 End;
 If Not Done Then EvBad:=True;
 VStr(V,S);
End;

Procedure ParseRefOrName(Var V: TVal);
Var P, R, C: Integer; A1, A2: Boolean; Nm: String; G: TRange;
Begin
 P:=EvP;
 If ScanRef(EvS,P,R,C,A1,A2) Then Begin
  EvP:=P;
  CellVal(R,C,V);
  Exit;
 End;
 Nm:='';
 While (EvP<=Length(EvS)) And (IsAlphaCh(EvS[EvP]) Or IsDigitCh(EvS[EvP])
       Or (EvS[EvP]='_')) Do Begin
  Nm:=Nm+EvS[EvP]; Inc(EvP);
 End;
 If (Nm<>'') And FindName(Nm,G) Then CellVal(G.R1,G.C1,V)
  Else Begin EvBad:=True; VErr(V,1); End;
End;

Procedure AggAdd(Var A: TAgg; X: Double);
Begin
 Inc(A.Cnt); Inc(A.CntAll);
 A.Sum:=A.Sum+X;
 If Abs(X)<1E100 Then A.SumSq:=A.SumSq+X*X;
 If A.Cnt=1 Then Begin A.Mn:=X; A.Mx:=X; End
  Else Begin
   If X<A.Mn Then A.Mn:=X;
   If X>A.Mx Then A.Mx:=X;
  End;
End;

Procedure AggRange(Var A: TAgg; Const G: TRange);
Var R, C: Integer; P: PCell;
Begin
 For R:=G.R1 To G.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=G.C1 To G.C2 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If P<>Nil Then Begin
     Case P^.Kind Of
      CK_NUM: AggAdd(A,P^.Num);
      CK_LABEL: Inc(A.CntAll);
      CK_FORMULA: Begin
       EnsureCalc(P,R,C);
       Case P^.ResK Of
        0: AggAdd(A,P^.Num);
        1: Inc(A.CntAll);
        Else A.Err:=P^.ErrC;
       End;
      End;
     End;
    End;
   End;
End;

Procedure ParseOneArg(Var V: TVal; Var G: TRange; Var IsR: Boolean);
Var P, K, R, C, R2, C2: Integer; A1, A2, B1, B2: Boolean; Nm: String; Ch: Char;
Begin
 IsR:=False;
 SkipWs;
 P:=EvP;
 If ScanRef(EvS,P,R,C,A1,A2) Then Begin
  K:=0;
  If Copy(EvS,P,2)='..' Then K:=P+2
  Else If (P<=Length(EvS)) And (EvS[P]=':') Then K:=P+1;
  If K>0 Then Begin
   If ScanRef(EvS,K,R2,C2,B1,B2) Then Begin
    SetRange(G,R,C,R2,C2);
    NormRange(G);
    IsR:=True;
    EvP:=K;
    VNum(V,0);
    Exit;
   End;
   EvBad:=True; VErr(V,1);
   Exit;
  End;
 End Else Begin
  K:=EvP; Nm:='';
  While (K<=Length(EvS)) And (IsAlphaCh(EvS[K]) Or IsDigitCh(EvS[K]) Or (EvS[K]='_')) Do Begin
   Nm:=Nm+EvS[K]; Inc(K);
  End;
  If (Nm<>'') And FindName(Nm,G) Then Begin
   While (K<=Length(EvS)) And (EvS[K]=' ') Do Inc(K);
   If K<=Length(EvS) Then Ch:=EvS[K] Else Ch:=#0;
   If (Ch=',') Or (Ch=')') Or (Ch=';') Then Begin
    IsR:=True;
    EvP:=K;
    VNum(V,0);
    Exit;
   End;
  End;
 End;
 ParseOr(V);
End;

Function FuncId(Const Nm: String): Integer;
Var I: Integer; U: String;
Begin
 FuncId:=0;
 U:=UpStr(Nm);
 For I:=1 To FN_COUNT Do
  If FnTab[I].Nm=U Then Begin FuncId:=FnTab[I].Id; Exit; End;
End;

Function FuncNoParen(Id: Integer): Boolean;
Begin
 FuncNoParen:=Id In [F_PI,F_RAND,F_NOW,F_TODAY,F_TRUE,F_FALSE,F_NA,F_ERR];
End;

Function ProperStr(Const S: String): String;
Var T: String; I: Integer; Nw: Boolean;
Begin
 T:=S; Nw:=True;
 For I:=1 To Length(T) Do Begin
  If IsAlphaCh(T[I]) Or (T[I]>=#128) Then Begin
   If Nw Then T[I]:=UpCase(T[I])
    Else If (T[I]>='A') And (T[I]<='Z') Then T[I]:=Chr(Ord(T[I])+32);
   Nw:=False;
  End Else Nw:=True;
 End;
 ProperStr:=T;
End;

Function LowerStr(Const S: String): String;
Var T: String; I: Integer;
Begin
 T:=S;
 For I:=1 To Length(T) Do
  If (T[I]>='A') And (T[I]<='Z') Then T[I]:=Chr(Ord(T[I])+32);
 LowerStr:=T;
End;

Procedure ParseFunc(Var V: TVal);
Var
 Nm: String; Id, I, N, Rr, Cc: Integer; HasP, IsAgg, Fnd: Boolean;
 ArgV: Array[1..MAX_ARGS] Of TVal;
 ArgG: Array[1..MAX_ARGS] Of TRange;
 ArgR: Array[1..MAX_ARGS] Of Boolean;
 Acc: TAgg; Tmp: TVal; G: TRange; IsR: Boolean; Ch: Char;
 X, Y, Z, Pw: Double; S, S2: String; Ok: Boolean; L1, L2, L3: LongInt;
 Cp: PCell;

 Function AN(K: Integer): Double;
 Begin
  If (K<=N) And (K<=MAX_ARGS) And Not ArgR[K] Then AN:=NumOf(ArgV[K]) Else AN:=0;
 End;

 Function AS_(K: Integer): String;
 Begin
  If (K<=N) And (K<=MAX_ARGS) And Not ArgR[K] Then AS_:=StrOf(ArgV[K]) Else AS_:='';
 End;

 Function AI(K: Integer): LongInt;
 Var T: Double;
 Begin
  T:=AN(K);
  If T>2000000000.0 Then T:=2000000000.0;
  If T<-2000000000.0 Then T:=-2000000000.0;
  AI:=Round(T);
 End;

Begin
 Inc(EvP);
 Nm:='';
 While (EvP<=Length(EvS)) And (IsAlphaCh(EvS[EvP]) Or IsDigitCh(EvS[EvP]) Or
       (EvS[EvP]='_') Or (EvS[EvP]='.')) Do Begin
  Nm:=Nm+EvS[EvP]; Inc(EvP);
 End;
 Id:=FuncId(Nm);
 If Id=0 Then Begin EvBad:=True; VErr(V,1); Exit; End;
 HasP:=False;
 If PeekC='(' Then Begin HasP:=True; Inc(EvP); End;
 If (Not HasP) And (Not FuncNoParen(Id)) Then Begin EvBad:=True; VErr(V,1); Exit; End;
 IsAgg:=Id In [F_SUM,F_AVG,F_MIN,F_MAX,F_COUNT,F_STD,F_VAR];
 FillChar(Acc,SizeOf(Acc),0);
 N:=0;
 If HasP Then Begin
  If PeekC=')' Then Inc(EvP)
  Else Begin
   Repeat
    Inc(N);
    If IsAgg Then Begin
     ParseOneArg(Tmp,G,IsR);
     If IsR Then AggRange(Acc,G)
      Else Begin
       If Tmp.K=2 Then Acc.Err:=Tmp.E
        Else If Tmp.K=0 Then AggAdd(Acc,Tmp.N)
        Else Inc(Acc.CntAll);
      End;
    End Else Begin
     If N<=MAX_ARGS Then Begin
      ParseOneArg(ArgV[N],ArgG[N],ArgR[N]);
     End Else Begin
      ParseOneArg(Tmp,G,IsR);
     End;
    End;
    Ch:=PeekC;
    If (Ch=',') Or (Ch=';') Then Inc(EvP);
   Until ((Ch<>',') And (Ch<>';')) Or EvBad;
   If PeekC=')' Then Inc(EvP) Else EvBad:=True;
  End;
 End;
 If EvBad Then Begin VErr(V,1); Exit; End;
 If N>MAX_ARGS Then N:=MAX_ARGS;

 If IsAgg Then Begin
  If Acc.Err<>0 Then Begin VErr(V,Acc.Err); Exit; End;
  Case Id Of
   F_SUM:   VNum(V,Acc.Sum);
   F_COUNT: VNum(V,Acc.CntAll);
   F_AVG:   If Acc.Cnt=0 Then VErr(V,1) Else VNum(V,Acc.Sum/Acc.Cnt);
   F_MIN:   If Acc.Cnt=0 Then VNum(V,0) Else VNum(V,Acc.Mn);
   F_MAX:   If Acc.Cnt=0 Then VNum(V,0) Else VNum(V,Acc.Mx);
   F_STD,F_VAR: Begin
    If Acc.Cnt=0 Then VErr(V,1)
    Else Begin
     X:=Acc.SumSq/Acc.Cnt-(Acc.Sum/Acc.Cnt)*(Acc.Sum/Acc.Cnt);
     If X<0 Then X:=0;
     If Id=F_STD Then VNum(V,Sqrt(X)) Else VNum(V,X);
    End;
   End;
  End;
  Exit;
 End;

 { propagation des erreurs }
 If Not (Id In [F_IF,F_ISNUM,F_ISSTR,F_ISERR,F_ISNA,F_CHOOSE]) Then
  For I:=1 To N Do
   If (Not ArgR[I]) And (ArgV[I].K=2) Then Begin V:=ArgV[I]; Exit; End;

 Case Id Of
  F_ABS:   VNum(V,Abs(AN(1)));
  F_INT:   Begin
            X:=AN(1); Y:=Int(X);
            If (X<0) And (Y<>X) Then Y:=Y-1;
            VNum(V,Y);
           End;
  F_ROUND: Begin
            X:=AN(1); L1:=AI(2);
            If L1>15 Then L1:=15;
            If L1<-15 Then L1:=-15;
            Pw:=1;
            For I:=1 To Abs(L1) Do Pw:=Pw*10;
            If L1<0 Then Pw:=1/Pw;
            If Abs(X)*Pw>=1E15 Then VNum(V,X)
            Else Begin
             If X<0 Then Y:=-Int(-X*Pw+0.5)/Pw Else Y:=Int(X*Pw+0.5)/Pw;
             VNum(V,Y);
            End;
           End;
  F_SQRT:  If AN(1)<0 Then VErr(V,1) Else VNum(V,Sqrt(AN(1)));
  F_EXP:   If AN(1)>700 Then VErr(V,1) Else VNum(V,Exp(AN(1)));
  F_LN:    If AN(1)<=0 Then VErr(V,1) Else VNum(V,Ln(AN(1)));
  F_LOG:   If AN(1)<=0 Then VErr(V,1) Else VNum(V,Ln(AN(1))/Ln(10));
  F_SIN:   If Abs(AN(1))>1E9 Then VErr(V,1) Else VNum(V,Sin(AN(1)));
  F_COS:   If Abs(AN(1))>1E9 Then VErr(V,1) Else VNum(V,Cos(AN(1)));
  F_TAN:   Begin
            X:=AN(1);
            If (Abs(X)>1E9) Or (Abs(Cos(X))<1E-12) Then VErr(V,1) Else VNum(V,Sin(X)/Cos(X));
           End;
  F_ASIN:  Begin
            X:=AN(1);
            If Abs(X)>1 Then VErr(V,1)
            Else If Abs(X)=1 Then VNum(V,X*Pi/2)
            Else VNum(V,ArcTan(X/Sqrt(1-X*X)));
           End;
  F_ACOS:  Begin
            X:=AN(1);
            If Abs(X)>1 Then VErr(V,1)
            Else If Abs(X)=1 Then VNum(V,(1-X)*Pi/2)
            Else VNum(V,Pi/2-ArcTan(X/Sqrt(1-X*X)));
           End;
  F_ATAN:  VNum(V,ArcTan(AN(1)));
  F_ATAN2: VNum(V,ArcTan2(AN(2),AN(1)));
  F_PI:    VNum(V,Pi);
  F_MOD:   Begin
            X:=AN(1); Y:=AN(2);
            If Y=0 Then VErr(V,1)
            Else Begin
             Ok:=True;
             Z:=SafeDiv(X,Y,Ok);
             If (Not Ok) Or (Abs(Z)>1E14) Then VErr(V,1)
              Else VNum(V,X-Y*Int(Z));
            End;
           End;
  F_RAND:  VNum(V,Random);
  F_SIGN:  Begin
            X:=AN(1);
            If X>0 Then VNum(V,1) Else If X<0 Then VNum(V,-1) Else VNum(V,0);
           End;
  F_IF:    Begin
            If (N>=1) And (AN(1)<>0) Then Begin
             If (N>=2) And Not ArgR[2] Then V:=ArgV[2] Else VNum(V,0);
            End Else Begin
             If (N>=3) And Not ArgR[3] Then V:=ArgV[3] Else VNum(V,0);
            End;
           End;
  F_TRUE:  VNum(V,1);
  F_FALSE: VNum(V,0);
  F_NA:    VErr(V,2);
  F_ERR:   VErr(V,1);
  F_ISNUM: If (N>=1) And Not ArgR[1] And (ArgV[1].K=0) Then VNum(V,1) Else VNum(V,0);
  F_ISSTR: If (N>=1) And Not ArgR[1] And (ArgV[1].K=1) Then VNum(V,1) Else VNum(V,0);
  F_ISERR: If (N>=1) And Not ArgR[1] And (ArgV[1].K=2) And (ArgV[1].E=1) Then VNum(V,1) Else VNum(V,0);
  F_ISNA:  If (N>=1) And Not ArgR[1] And (ArgV[1].K=2) And (ArgV[1].E=2) Then VNum(V,1) Else VNum(V,0);
  F_LEN:   VNum(V,Length(AS_(1)));
  F_LEFT:  Begin L1:=AI(2); If L1<0 Then L1:=0; VStr(V,Copy(AS_(1),1,L1)); End;
  F_RIGHT: Begin
            S:=AS_(1); L1:=AI(2); If L1<0 Then L1:=0;
            If L1>Length(S) Then L1:=Length(S);
            VStr(V,Copy(S,Length(S)-L1+1,L1));
           End;
  F_MID:   Begin
            L1:=AI(2); L2:=AI(3);
            If (L1<0) Or (L2<0) Then VErr(V,1) Else VStr(V,Copy(AS_(1),L1+1,L2));
           End;
  F_UPPER: VStr(V,UpStr(AS_(1)));
  F_LOWER: VStr(V,LowerStr(AS_(1)));
  F_PROPER: VStr(V,ProperStr(AS_(1)));
  F_TRIM:  VStr(V,TrimStr(AS_(1)));
  F_STRING: Begin
             L1:=AI(2);
             If L1<0 Then L1:=0;
             If L1>15 Then L1:=15;
             VStr(V,FixStr(AN(1),L1));
            End;
  F_VALUE: Begin
            If TryNumber(AS_(1),X) Then VNum(V,X) Else VErr(V,1);
           End;
  F_REPEAT: Begin
             S:=AS_(1); L1:=AI(2); S2:='';
             If L1<0 Then L1:=0;
             If (L1*Length(S))>120 Then L1:=120 Div MaxI(1,Length(S));
             For I:=1 To L1 Do S2:=S2+S;
             VStr(V,S2);
            End;
  F_CHAR:  Begin L1:=AI(1); If (L1<1) Or (L1>255) Then VErr(V,1) Else VStr(V,Chr(L1)); End;
  F_CODE:  Begin S:=AS_(1); If S='' Then VErr(V,1) Else VNum(V,Ord(S[1])); End;
  F_NOW:   VNum(V,NowSerial);
  F_TODAY: VNum(V,Int(NowSerial));
  F_DATE:  Begin
            L1:=AI(1); L2:=AI(2); L3:=AI(3);
            If L1<200 Then L1:=L1+1900;
            If (L2<1) Or (L2>12) Or (L3<1) Or (L3>31) Or (L1>9999) Then VErr(V,1)
             Else VNum(V,DateToSerial(L1,L2,L3));
           End;
  F_YEAR,F_MONTH,F_DAY: Begin
            X:=AN(1);
            If (X<1) Or (X>2958465) Then VErr(V,1)
            Else Begin
             SerialToDate(Trunc(X),L1,L2,L3);
             If Id=F_YEAR Then VNum(V,L1) Else If Id=F_MONTH Then VNum(V,L2) Else VNum(V,L3);
            End;
           End;
  F_HOUR,F_MINUTE,F_SECOND: Begin
            X:=AN(1); X:=X-Int(X);
            L1:=Round(X*86400.0);
            If L1>=86400 Then L1:=L1-86400;
            If Id=F_HOUR Then VNum(V,L1 Div 3600)
            Else If Id=F_MINUTE Then VNum(V,(L1 Div 60) Mod 60)
            Else VNum(V,L1 Mod 60);
           End;
  F_TIME:  VNum(V,(AN(1)*3600.0+AN(2)*60.0+AN(3))/86400.0);
  F_CHOOSE: Begin
             L1:=AI(1);
             If (L1<0) Or (L1+2>N) Or ArgR[L1+2] Then VErr(V,1) Else V:=ArgV[L1+2];
            End;
  F_VLOOKUP,F_HLOOKUP: Begin
             If (N<3) Or Not ArgR[2] Then VErr(V,1)
             Else Begin
              G:=ArgG[2]; L1:=AI(3);
              Fnd:=False; Rr:=-1; Cc:=-1;
              If Id=F_VLOOKUP Then Begin
               If (L1<0) Or (G.C1+L1>G.C2) Then VErr(V,1)
               Else Begin
                For I:=G.R1 To G.R2 Do Begin
                 CellVal(I,G.C1,Tmp);
                 If (ArgV[1].K=1) Then Begin
                  If (Tmp.K=1) And (UpStr(Tmp.S)=UpStr(ArgV[1].S)) Then Begin Rr:=I; Fnd:=True; End;
                 End Else If Tmp.K=0 Then Begin
                  If Tmp.N<=ArgV[1].N Then Begin Rr:=I; Fnd:=True; End;
                 End;
                End;
                If Fnd Then CellVal(Rr,G.C1+L1,V) Else VErr(V,2);
               End;
              End Else Begin
               If (L1<0) Or (G.R1+L1>G.R2) Then VErr(V,1)
               Else Begin
                For I:=G.C1 To G.C2 Do Begin
                 CellVal(G.R1,I,Tmp);
                 If (ArgV[1].K=1) Then Begin
                  If (Tmp.K=1) And (UpStr(Tmp.S)=UpStr(ArgV[1].S)) Then Begin Cc:=I; Fnd:=True; End;
                 End Else If Tmp.K=0 Then Begin
                  If Tmp.N<=ArgV[1].N Then Begin Cc:=I; Fnd:=True; End;
                 End;
                End;
                If Fnd Then CellVal(G.R1+L1,Cc,V) Else VErr(V,2);
               End;
              End;
             End;
            End;
  F_INDEX: Begin
            If (N<3) Or Not ArgR[1] Then VErr(V,1)
            Else Begin
             G:=ArgG[1]; L1:=AI(2); L2:=AI(3);
             If (L1<0) Or (L2<0) Or (G.C1+L1>G.C2) Or (G.R1+L2>G.R2) Then VErr(V,1)
              Else CellVal(G.R1+L2,G.C1+L1,V);
            End;
           End;
  F_ROWS:  If (N>=1) And ArgR[1] Then VNum(V,ArgG[1].R2-ArgG[1].R1+1) Else VNum(V,1);
  F_COLS:  If (N>=1) And ArgR[1] Then VNum(V,ArgG[1].C2-ArgG[1].C1+1) Else VNum(V,1);
  F_PMT:   Begin
            X:=AN(1); Y:=AN(2); Z:=AN(3);
            If Z<=0 Then VErr(V,1)
            Else If Y=0 Then VNum(V,X/Z)
            Else Begin
             Ok:=True;
             Pw:=SafePow(1+Y,-Z,Ok);
             If (Not Ok) Or (Pw=1) Then VErr(V,1)
              Else VNum(V,X*Y/(1-Pw));
            End;
           End;
  F_PV:    Begin
            X:=AN(1); Y:=AN(2); Z:=AN(3);
            If Y=0 Then VNum(V,X*Z)
            Else Begin
             Ok:=True;
             Pw:=SafePow(1+Y,-Z,Ok);
             If Not Ok Then VErr(V,1) Else VNum(V,X*(1-Pw)/Y);
            End;
           End;
  F_FV:    Begin
            X:=AN(1); Y:=AN(2); Z:=AN(3);
            If Y=0 Then VNum(V,X*Z)
            Else Begin
             Ok:=True;
             Pw:=SafePow(1+Y,Z,Ok);
             If Not Ok Then VErr(V,1) Else VNum(V,X*(Pw-1)/Y);
            End;
           End;
  F_NPV:   Begin
            If (N<2) Or Not ArgR[2] Then VErr(V,1)
            Else Begin
             X:=0; Y:=AN(1); L1:=0;
             G:=ArgG[2];
             Ok:=True;
             For Rr:=G.R1 To G.R2 Do
              For Cc:=G.C1 To G.C2 Do Begin
               CellVal(Rr,Cc,Tmp);
               If Tmp.K=0 Then Begin
                Inc(L1);
                Pw:=SafePow(1+Y,L1,Ok);
                If Ok And (Pw<>0) Then X:=X+Tmp.N/Pw;
               End;
              End;
             If Ok Then VNum(V,X) Else VErr(V,1);
            End;
           End;
  Else VErr(V,1);
 End;
End;

Procedure ParsePrimary(Var V: TVal);
Var C: Char;
Begin
 C:=PeekC;
 Case C Of
  '0'..'9','.': ParseNumLit(V);
  '"':          ParseStrLit(V);
  '(':          Begin
                 Inc(EvP);
                 ParseOr(V);
                 If PeekC=')' Then Inc(EvP) Else EvBad:=True;
                End;
  '@':          ParseFunc(V);
  '$','A'..'Z','a'..'z','_': ParseRefOrName(V);
  Else          Begin EvBad:=True; VErr(V,1); End;
 End;
End;

Procedure ParseUnary(Var V: TVal);
Var C: Char;
Begin
 C:=PeekC;
 If C='-' Then Begin
  Inc(EvP);
  ParseUnary(V);
  If V.K=0 Then V.N:=-V.N Else If V.K=1 Then VNum(V,0);
 End Else If C='+' Then Begin
  Inc(EvP);
  ParseUnary(V);
 End Else ParsePrimary(V);
End;

Procedure ParsePow(Var V: TVal);
Var W: TVal; Ok: Boolean; X: Double;
Begin
 ParseUnary(V);
 While (PeekC='^') And Not EvBad Do Begin
  Inc(EvP);
  ParseUnary(W);
  If V.K=2 Then Begin End
  Else If W.K=2 Then V:=W
  Else Begin
   Ok:=True;
   X:=SafePow(NumOf(V),NumOf(W),Ok);
   If Ok Then VNum(V,X) Else VErr(V,1);
  End;
 End;
End;

Procedure ParseMul(Var V: TVal);
Var W: TVal; Op: Char; Ok: Boolean; X: Double;
Begin
 ParsePow(V);
 Op:=PeekC;
 While ((Op='*') Or (Op='/')) And Not EvBad Do Begin
  Inc(EvP);
  ParsePow(W);
  If V.K=2 Then Begin End
  Else If W.K=2 Then V:=W
  Else Begin
   Ok:=True;
   If Op='*' Then X:=SafeMul(NumOf(V),NumOf(W),Ok)
             Else X:=SafeDiv(NumOf(V),NumOf(W),Ok);
   If Ok Then VNum(V,X) Else VErr(V,1);
  End;
  Op:=PeekC;
 End;
End;

Procedure ParseAdd(Var V: TVal);
Var W: TVal; Op: Char;
Begin
 ParseMul(V);
 Op:=PeekC;
 While ((Op='+') Or (Op='-') Or (Op='&')) And Not EvBad Do Begin
  Inc(EvP);
  ParseMul(W);
  If V.K=2 Then Begin End
  Else If W.K=2 Then V:=W
  Else If Op='&' Then VStr(V,StrOf(V)+StrOf(W))
  Else If Op='+' Then VNum(V,NumOf(V)+NumOf(W))
  Else VNum(V,NumOf(V)-NumOf(W));
  Op:=PeekC;
 End;
End;

Procedure ParseCmp(Var V: TVal);
Var W: TVal; Op: String; Cm: Integer; B: Boolean; A, B2: String; C: Char;
Begin
 ParseAdd(V);
 C:=PeekC;
 While ((C='<') Or (C='>') Or (C='=')) And Not EvBad Do Begin
  Op:=C; Inc(EvP);
  If (EvP<=Length(EvS)) And (EvS[EvP] In ['=','>']) And
     (((Op='<') And (EvS[EvP] In ['=','>'])) Or ((Op='>') And (EvS[EvP]='='))) Then Begin
   Op:=Op+EvS[EvP]; Inc(EvP);
  End;
  ParseAdd(W);
  If V.K=2 Then Begin End
  Else If W.K=2 Then V:=W
  Else Begin
   If (V.K=1) And (W.K=1) Then Begin
    A:=UpStr(V.S); B2:=UpStr(W.S);
    If A<B2 Then Cm:=-1 Else If A>B2 Then Cm:=1 Else Cm:=0;
   End Else If V.K<>W.K Then Begin
    If V.K=0 Then Cm:=-1 Else Cm:=1;
   End Else Begin
    If V.N<W.N Then Cm:=-1 Else If V.N>W.N Then Cm:=1 Else Cm:=0;
   End;
   B:=False;
   If Op='=' Then B:=Cm=0
   Else If Op='<>' Then B:=Cm<>0
   Else If Op='<' Then B:=Cm<0
   Else If Op='>' Then B:=Cm>0
   Else If Op='<=' Then B:=Cm<=0
   Else If Op='>=' Then B:=Cm>=0;
   If B Then VNum(V,1) Else VNum(V,0);
  End;
  C:=PeekC;
 End;
End;

Procedure ParseNot(Var V: TVal);
Begin
 If PeekWord('#NOT#') Then Begin
  Inc(EvP,5);
  ParseNot(V);
  If V.K<>2 Then Begin
   If NumOf(V)=0 Then VNum(V,1) Else VNum(V,0);
  End;
 End Else ParseCmp(V);
End;

Procedure ParseAnd(Var V: TVal);
Var W: TVal;
Begin
 ParseNot(V);
 While PeekWord('#AND#') And Not EvBad Do Begin
  Inc(EvP,5);
  ParseNot(W);
  If V.K=2 Then Begin End
  Else If W.K=2 Then V:=W
  Else If (NumOf(V)<>0) And (NumOf(W)<>0) Then VNum(V,1) Else VNum(V,0);
 End;
End;

Procedure ParseOr(Var V: TVal);
Var W: TVal;
Begin
 ParseAnd(V);
 While PeekWord('#OR#') And Not EvBad Do Begin
  Inc(EvP,4);
  ParseAnd(W);
  If V.K=2 Then Begin End
  Else If W.K=2 Then V:=W
  Else If (NumOf(V)<>0) Or (NumOf(W)<>0) Then VNum(V,1) Else VNum(V,0);
 End;
End;

Procedure EvalFormula(Const Src: String; Var V: TVal);
Var S0: String; P0: Integer; B0: Boolean;
Begin
 S0:=EvS; P0:=EvP; B0:=EvBad;
 EvS:=Src; EvP:=1; EvBad:=False;
 ParseOr(V);
 SkipWs;
 If EvP<=Length(EvS) Then EvBad:=True;
 SyntaxBad:=EvBad;
 If EvBad Then VErr(V,1);
 EvS:=S0; EvP:=P0; EvBad:=B0;
End;

{ ====================================================================== }
{                              RECALCUL                                  }
{ ====================================================================== }

Procedure CalcTop(R0, C0: Integer);
Var Sp, Iter, R, C: Integer; P: PCell;
Begin
 PendR^[0]:=R0; PendC^[0]:=C0; Sp:=1; Iter:=0;
 While Sp>0 Do Begin
  Inc(Iter);
  R:=PendR^[Sp-1]; C:=PendC^[Sp-1];
  P:=FindCell(Sh,R,C);
  If (P=Nil) Or (P^.Kind<>CK_FORMULA) Or (P^.Calc=2) Then Dec(Sp)
  Else If Iter>30000 Then Begin
   P^.Calc:=2; P^.ResK:=2; P^.ErrC:=1; CircFlag:=True; Dec(Sp);
  End Else Begin
   Deferred:=False; EvDepth:=0;
   EnsureCalc(P,R,C);
   If Deferred Then Begin
    Deferred:=False;
    If Sp<4095 Then Begin
     PendR^[Sp]:=DeferR; PendC^[Sp]:=DeferC; Inc(Sp);
    End Else Begin
     P^.Calc:=2; P^.ResK:=2; P^.ErrC:=1; CircFlag:=True; Dec(Sp);
    End;
   End Else Dec(Sp);
  End;
 End;
 Deferred:=False; EvDepth:=0;
End;

Procedure RecalcAll;
Var R, C: Integer; P: PCell;
Begin
 CircFlag:=False; NeedCalc:=False;
 For R:=0 To MAX_ROWS-1 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=0 To MAX_COLS-1 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If (P<>Nil) And (P^.Kind=CK_FORMULA) Then P^.Calc:=0;
   End;
 For R:=0 To MAX_ROWS-1 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=0 To MAX_COLS-1 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If (P<>Nil) And (P^.Kind=CK_FORMULA) And (P^.Calc=0) Then CalcTop(R,C);
   End;
End;

Procedure Changed;
Begin
 Sh^.Modified:=True;
 If AutoCalc Then RecalcAll Else NeedCalc:=True;
End;

{ ====================================================================== }
{                       SAISIE DU CONTENU D'UNE CELLULE                  }
{ ====================================================================== }

{ Retourne False si la formule est invalide (la cellule n'est alors pas modifiee). }
Function CommitText(R, C: Integer; Const Txt: String): Boolean;
Var T: String; Ch: Char; X: Double; P: PCell; V: TVal; Al: Byte; IsFormula: Boolean;
Begin
 CommitText:=True;
 T:=Txt;
 If T='' Then Exit;
 Ch:=T[1];
 If (Ch='''') Or (Ch='"') Or (Ch='^') Or (Ch='\') Then Begin
  P:=MakeCell(Sh,R,C);
  If P=Nil Then Exit;
  Case Ch Of
   '''': Al:=AL_LEFT;
   '"':  Al:=AL_RIGHT;
   '^':  Al:=AL_CENTER;
   Else  Al:=AL_REPEAT;
  End;
  SetLabel(P,Copy(T,2,255),Al);
  Changed;
  Exit;
 End;
 If TryNumber(T,X) Then Begin
  P:=MakeCell(Sh,R,C);
  If P=Nil Then Exit;
  SetNumber(P,X);
  Changed;
  Exit;
 End;
 IsFormula:=Ch In ['+','-','(','@','.','$','#','=','0'..'9'];
 If IsFormula Then Begin
  If Ch='=' Then T:='+'+Copy(T,2,255);
  EvDepth:=0; Deferred:=False;
  EvalFormula(T,V);
  Deferred:=False;
  If SyntaxBad Then Begin
   If Ch In ['0'..'9','$'] Then IsFormula:=False
    Else Begin CommitText:=False; Exit; End;
  End;
 End;
 P:=MakeCell(Sh,R,C);
 If P=Nil Then Exit;
 If IsFormula Then SetFormula(P,T)
  Else Begin
   If (P^.Kind=CK_LABEL) Or (P^.Al=AL_REPEAT) Then SetLabel(P,T,P^.Al)
    Else SetLabel(P,T,P^.Al);
   If P^.Al=AL_REPEAT Then P^.Al:=AL_DEF;
  End;
 Changed;
End;

{ Texte brut d'une cellule tel qu'il serait saisi (pour F2 et la ligne de saisie). }
Function CellSource(P: PCell): String;
Var S: String;
Begin
 CellSource:='';
 If P=Nil Then Exit;
 Case P^.Kind Of
  CK_LABEL: Begin
             S:=GetStr(P^.Txt);
             Case P^.Al Of
              AL_RIGHT:  S:='"'+S;
              AL_CENTER: S:='^'+S;
              AL_REPEAT: S:='\'+S;
              Else       S:=''''+S;
             End;
             CellSource:=S;
            End;
  CK_NUM:   CellSource:=NumToStrPlain(P^.Num);
  CK_FORMULA: CellSource:=GetStr(P^.Txt);
 End;
End;

{ Texte affiche d'une cellule. Al recoit l'alignement effectif. }
Function CellDisplay(P: PCell; Cap: Integer; Var Al: Byte): String;
Var S: String; K: Byte;
Begin
 CellDisplay:='';
 Al:=AL_LEFT;
 If P=Nil Then Exit;
 If P^.Fmt=FM_HIDDEN Then Begin
  If P^.Kind=CK_NUM Then Al:=AL_RIGHT;
  Exit;
 End;
 Case P^.Kind Of
  CK_LABEL: Begin
             S:=GetStr(P^.Txt);
             Al:=AL_LEFT;
             If P^.Al<>AL_DEF Then Al:=P^.Al;
             If Al=AL_REPEAT Then Begin
              If S<>'' Then Begin
               S:=Rep(S[1],Cap);
               Al:=AL_LEFT;
              End;
             End;
             CellDisplay:=S;
            End;
  CK_NUM:   Begin
             Al:=AL_RIGHT;
             If (P^.Al<>AL_DEF) And (P^.Al<>AL_REPEAT) Then Al:=P^.Al;
             CellDisplay:=FormatNum(P^.Num,P^.Fmt,P^.Dec,Cap);
            End;
  CK_FORMULA: Begin
             K:=P^.ResK;
             If P^.Fmt=FM_TEXT Then Begin
              Al:=AL_LEFT;
              CellDisplay:=GetStr(P^.Txt);
              Exit;
             End;
             If K=0 Then Begin
              Al:=AL_RIGHT;
              If (P^.Al<>AL_DEF) And (P^.Al<>AL_REPEAT) Then Al:=P^.Al;
              CellDisplay:=FormatNum(P^.Num,P^.Fmt,P^.Dec,Cap);
             End Else If K=1 Then Begin
              Al:=AL_LEFT;
              If (P^.Al<>AL_DEF) And (P^.Al<>AL_REPEAT) Then Al:=P^.Al;
              CellDisplay:=GetStr(P^.Res);
             End Else Begin
              Al:=AL_RIGHT;
              If P^.ErrC=2 Then CellDisplay:='NA' Else CellDisplay:='ERR';
             End;
            End;
 End;
End;

{ ====================================================================== }
{                  IDENTIFIANTS DES MENUS ET DES COMMANDES               }
{ ====================================================================== }

Const
 M_FILE=1; M_EDIT=2; M_STYLE=3; M_GRAPH=4; M_PRINT=5; M_DB=6; M_TOOLS=7;
 M_DEF=8; M_WIN=9;
 M_FUTIL=10; M_SQZ=11; M_SQZE=12; M_SQZF=13; M_SQZV=14; M_WSPACE=15;
 M_EINS=16; M_EDEL=17; M_ENAMES=18; M_SALIGN=19; M_SFMT=20; M_SDATE=21;
 M_STIME=22; M_SPROT=23; M_SCW=24; M_SHIDE=25; M_SFONT=26; M_GTYPE=27;
 M_GSER=28; M_GTITLE=29; M_GGRID=30; M_GCLEAR=31; M_PDEST=32; M_SORT=33;
 M_SORTORD=34; M_QUERY=35; M_CALC=36; M_DBAR=37; M_DGRID=38; M_DSEP=39;
 M_LOCK=40;
 MAX_MENUS=48;
 MAX_ITEMS=260;
 MAX_LV=5;

 CM_NEW=1; CM_OPEN=2; CM_LOAD=3; CM_SAVE=4; CM_SAVEAS=5; CM_SAVEALL=6;
 CM_CLOSE=7; CM_CLOSEALL=8; CM_ERASE=9; CM_DIR=10; CM_DOS=11; CM_FM=12;
 CM_QUIT=13; CM_WS_SAVE=14; CM_WS_REST=15;
 CM_SQZE=16; CM_SQZE_Y=17; CM_SQZE_N=18; CM_SQZF=19; CM_SQZF_Y=20;
 CM_SQZF_N=21; CM_SQZV=22; CM_SQZV_A=23; CM_SQZV_B=24; CM_BACK=25;
 CM_UNDO=30; CM_COPY=31; CM_MOVE=32; CM_CLEAR=33; CM_INSROW=34; CM_INSCOL=35;
 CM_DELROW=36; CM_DELCOL=37; CM_VALUES=38; CM_TRANSP=39; CM_FILL=40;
 CM_FIND=41; CM_REPL=42; CM_NMCREATE=43; CM_NMDEL=44; CM_NMDELALL=45;
 CM_NMLIST=46;
 CM_AL_G=50; CM_AL_L=51; CM_AL_R=52; CM_AL_C=53;
 CM_FM_F=54; CM_FM_S=55; CM_FM_C=56; CM_FM_COMMA=57; CM_FM_G=58;
 CM_FM_PLUS=59; CM_FM_PCT=60; CM_FM_D1=61; CM_FM_TEXT=66; CM_FM_HID=67;
 CM_FM_T1=68;
 CM_PROT_Y=72; CM_PROT_N=73; CM_COLW=74; CM_CW_SET=75; CM_CW_RST=76;
 CM_HIDE=77; CM_UNHIDE=78; CM_FONT_N=79; CM_FONT_B=80; CM_FONT_U=81;
 CM_FONT_BU=82; CM_FIT=83;
 CM_GT_BAR=90; CM_GT_STK=91; CM_GT_LINE=92; CM_GT_XY=93; CM_GT_PIE=94;
 CM_GS_X=95; CM_GS_1=96; CM_GTT1=102; CM_GTT2=103; CM_GTTX=104; CM_GTTY=105;
 CM_GGRID_Y=106; CM_GGRID_N=107; CM_GCL_SER=108; CM_GCL_TIT=109;
 CM_GCL_ALL=110; CM_GVIEW=111; CM_GTYPE=112; CM_GGRID=113;
 CM_PBLOCK=120; CM_PDEST=121; CM_PD_PRN=122; CM_PD_FILE=123; CM_PD_SCR=124;
 CM_PHDR=125; CM_PFTR=126; CM_PWIDTH=127; CM_PHEIGHT=128; CM_PGO=129;
 CM_SORT_BLOCK=135; CM_SORT_KEY=136; CM_SORT_ORD=137; CM_SORT_ASC=138;
 CM_SORT_DESC=139; CM_SORT_GO=140; CM_Q_BLOCK=141; CM_Q_CRIT=142;
 CM_Q_OUT=143; CM_Q_FIND=144; CM_Q_EXTR=145; CM_Q_CLR=146; CM_QSORT=147;
 CM_RECALC=150; CM_CALC_MODE=151; CM_CALC_AUTO=152; CM_CALC_MAN=153;
 CM_STATS=154; CM_REGR=155;
 CM_DBAR=160; CM_DBAR_Y=161; CM_DBAR_N=162; CM_DGRID=163; CM_DGRID_Y=164;
 CM_DGRID_N=165; CM_DCOLW=166; CM_DCURR=167; CM_DSEP=168; CM_DSEP_P=169;
 CM_DSEP_V=170; CM_DSAVE=171; CM_DDEC=172;
 CM_NEXTWIN=180; CM_PREVWIN=181; CM_LOCK_H=182; CM_LOCK_V=183; CM_LOCK_B=184;
 CM_LOCK_N=185; CM_WIN1=190;
 CM_PGLEFT=200; CM_PGRIGHT=201; CM_PGUP=202; CM_PGDOWN=203; CM_BARSET=204;
 CM_TB_STYLE=205; CM_TB_ALIGN=206; CM_TB_FONT=207; CM_TB_INS=208;
 CM_TB_DEL=209; CM_TB_FMT=210; CM_SUM=211; CM_BOLD=212; CM_HELP=213;
 CM_GOTO=214; CM_EDITCELL=215;

Type
 TItem = Record
  Cap: String[34];
  Sc: String[8];
  Cmd: Integer;
  Sub: Integer;
  Sep: Boolean;
  HK: Char;
 End;
 TMenuDef = Record
  First, Cnt: Integer;
 End;

Var
 Itm      : Array[1..MAX_ITEMS] Of TItem;
 NItm     : Integer;
 MenuDef  : Array[1..MAX_MENUS] Of TMenuDef;
 CurBuild : Integer;
 WinBase  : Integer;

 { Barre d'outils }
 NBtn     : Integer;
 BtnX1, BtnX2 : Array[1..24] Of Integer;
 BtnCmd   : Array[1..24] Of Integer;
 BtnCap   : Array[1..24] Of String[10];
 BtnDown  : Integer;

{ ====================================================================== }
{                      PRIMITIVES GRAPHIQUES DE BASE                     }
{ ====================================================================== }

Procedure FillBox(X1, Y1, X2, Y2, Color: Integer);
Begin
 SetFillStyle(SolidFill,Color);
 Bar(X1,Y1,X2,Y2);
End;

Procedure HLine(X1, X2, Y, Color: Integer);
Begin
 SetColor(Color);
 Line(X1,Y,X2,Y);
End;

Procedure VLine(X, Y1, Y2, Color: Integer);
Begin
 SetColor(Color);
 Line(X,Y1,X,Y2);
End;

Procedure TextAt(X, Y: Integer; Const S: String; Color: Integer);
Begin
 SetColor(Color);
 OutTextXY(X,Y,S);
End;

Procedure Raised(X1, Y1, X2, Y2: Integer);
Begin
 HLine(X1,X2,Y1,CL_WHITE);
 VLine(X1,Y1,Y2,CL_WHITE);
 HLine(X1,X2,Y2,CL_DGRAY);
 VLine(X2,Y1,Y2,CL_DGRAY);
End;

Procedure Sunken(X1, Y1, X2, Y2: Integer);
Begin
 HLine(X1,X2,Y1,CL_DGRAY);
 VLine(X1,Y1,Y2,CL_DGRAY);
 HLine(X1,X2,Y2,CL_WHITE);
 VLine(X2,Y1,Y2,CL_WHITE);
End;

{ Largeur en pixels d'un texte avec marqueurs & }
Function StripAmp(Const S: String): String;
Var I: Integer; R: String;
Begin
 R:=''; I:=1;
 While I<=Length(S) Do Begin
  If (S[I]='&') And (I<Length(S)) Then Begin R:=R+S[I+1]; Inc(I,2); End
   Else Begin R:=R+S[I]; Inc(I); End;
 End;
 StripAmp:=R;
End;

Function HotKeyOf(Const S: String): Char;
Var I: Integer;
Begin
 HotKeyOf:=#0;
 For I:=1 To Length(S)-1 Do
  If S[I]='&' Then Begin HotKeyOf:=UpCase(S[I+1]); Exit; End;
End;

{ Dessine un texte dont la lettre apres & est coloree. Retourne la largeur. }
Function DrawHK(X, Y: Integer; Const S: String; Fg, Hk: Integer): Integer;
Var I, Cx: Integer;
Begin
 I:=1; Cx:=X;
 While I<=Length(S) Do Begin
  If (S[I]='&') And (I<Length(S)) Then Begin
   TextAt(Cx,Y,S[I+1],Hk);
   Inc(Cx,8); Inc(I,2);
  End Else Begin
   TextAt(Cx,Y,S[I],Fg);
   Inc(Cx,8); Inc(I);
  End;
 End;
 DrawHK:=Cx-X;
End;

{ ====================================================================== }
{                          CURSEUR SOURIS LOGICIEL                       }
{ ====================================================================== }

{$IFDEF FPC}
Procedure DrawSoftCursor(X, Y: LongInt);
Var X2, Y2: LongInt;
Begin
 X2:=X+11; Y2:=Y+17;
 If X2>SCR_W-1 Then X2:=SCR_W-1;
 If Y2>SCR_H-1 Then Y2:=SCR_H-1;
 MsSaveSz:=ImageSize(X,Y,X2,Y2);
 If MsSaveSz=0 Then Exit;
 GetMem(MsSaveBuf,MsSaveSz);
 GetImage(X,Y,X2,Y2,MsSaveBuf^);
 MsSaveX:=X; MsSaveY:=Y;
 MsSaved:=True;
 SetColor(CL_BLACK);
 Line(X,Y,X,Y+14);
 Line(X,Y,X+10,Y+10);
 Line(X+10,Y+10,X+6,Y+10);
 Line(X+6,Y+10,X+9,Y+15);
 Line(X+9,Y+15,X+7,Y+16);
 Line(X+7,Y+16,X+4,Y+11);
 Line(X+4,Y+11,X,Y+14);
 SetFillStyle(SolidFill,CL_WHITE);
 FloodFill(X+2,Y+4,CL_BLACK);
End;

Procedure EraseSoftCursor;
Begin
 If Not MsSaved Then Exit;
 PutImage(MsSaveX,MsSaveY,MsSaveBuf^,NormalPut);
 FreeMem(MsSaveBuf,MsSaveSz);
 MsSaved:=False;
End;
{$ELSE}
Procedure DrawSoftCursor(X, Y: LongInt); Begin End;
Procedure EraseSoftCursor; Begin End;
{$ENDIF}

{ ====================================================================== }
{                       DISPOSITION ET CELLULES VISIBLES                 }
{ ====================================================================== }

Procedure SetLayout;
Begin
 If ShowBar Then YInp:=42 Else YInp:=16;
 YHdr:=YInp+14;
 YGrid:=YHdr+14;
End;

Procedure CalcVisible;
Var C, R, X, Y, W: Integer; Stop: Boolean;
Begin
 SetLayout;
 NVC:=0; X:=GRID_L;
 If Sh^.LeftC<Sh^.LockC Then Sh^.LeftC:=Sh^.LockC;
 If Sh^.TopR<Sh^.LockR Then Sh^.TopR:=Sh^.LockR;
 For C:=0 To Sh^.LockC-1 Do Begin
  W:=ColPx(C);
  If (W>0) And (NVC<62) And (X+W-1<=GRID_R) Then Begin
   VC[NVC]:=C; VX[NVC]:=X; Inc(NVC); X:=X+W;
  End;
 End;
 C:=Sh^.LeftC; Stop:=False;
 While (C<MAX_COLS) And (Not Stop) And (NVC<62) Do Begin
  W:=ColPx(C);
  If W>0 Then Begin
   If X+W-1<=GRID_R Then Begin
    VC[NVC]:=C; VX[NVC]:=X; Inc(NVC); X:=X+W;
   End Else Stop:=True;
  End;
  Inc(C);
 End;
 NVR:=0; Y:=YGrid;
 For R:=0 To Sh^.LockR-1 Do
  If (NVR<62) And (Y+ROW_H-1<=GRID_BOT) Then Begin
   VR[NVR]:=R; VY[NVR]:=Y; Inc(NVR); Y:=Y+ROW_H;
  End;
 R:=Sh^.TopR;
 While (R<MAX_ROWS) And (NVR<62) And (Y+ROW_H-1<=GRID_BOT) Do Begin
  VR[NVR]:=R; VY[NVR]:=Y; Inc(NVR); Y:=Y+ROW_H;
  Inc(R);
 End;
End;

Procedure EnsureCursorVisible;
Var I: Integer; Found: Boolean;
Begin
 CalcVisible;
 If Sh^.CurC>=Sh^.LockC Then Begin
  If Sh^.CurC<Sh^.LeftC Then Sh^.LeftC:=Sh^.CurC;
  Repeat
   CalcVisible;
   Found:=False;
   For I:=0 To NVC-1 Do If VC[I]=Sh^.CurC Then Found:=True;
   If Not Found Then Begin
    If Sh^.LeftC<Sh^.CurC Then Inc(Sh^.LeftC) Else Found:=True;
   End;
  Until Found;
 End;
 If Sh^.CurR>=Sh^.LockR Then Begin
  If Sh^.CurR<Sh^.TopR Then Sh^.TopR:=Sh^.CurR;
  Repeat
   CalcVisible;
   Found:=False;
   For I:=0 To NVR-1 Do If VR[I]=Sh^.CurR Then Found:=True;
   If Not Found Then Begin
    If Sh^.TopR<Sh^.CurR Then Inc(Sh^.TopR) Else Found:=True;
   End;
  Until Found;
 End;
End;

Procedure GetSel(Var G: TRange);
Begin
 If Sh^.SelOn Then SetRange(G,Sh^.AnchR,Sh^.AnchC,Sh^.CurR,Sh^.CurC)
  Else SetRange(G,Sh^.CurR,Sh^.CurC,Sh^.CurR,Sh^.CurC);
 NormRange(G);
 If Sh^.SelOn Then Begin
  If (Sh^.SelMode And 1)<>0 Then Begin G.R1:=0; G.R2:=MAX_ROWS-1; End;
  If (Sh^.SelMode And 2)<>0 Then Begin G.C1:=0; G.C2:=MAX_COLS-1; End;
 End;
End;

{ Cellule sous le pointeur ; retourne False si hors de la grille. }
Function GridHit(MX, MY: LongInt; Var R, C: Integer): Boolean;
Var I: Integer;
Begin
 GridHit:=False;
 If (MX<GRID_L) Or (MX>GRID_R) Or (MY<YGrid) Or (MY>GRID_BOT) Then Exit;
 C:=-1; R:=-1;
 For I:=0 To NVC-1 Do
  If (MX>=VX[I]) And (MX<VX[I]+ColPx(VC[I])) Then C:=VC[I];
 For I:=0 To NVR-1 Do
  If (MY>=VY[I]) And (MY<VY[I]+ROW_H) Then R:=VR[I];
 GridHit:=(C>=0) And (R>=0);
End;

{ ====================================================================== }
{                        DESSIN DE L'ECRAN PRINCIPAL                     }
{ ====================================================================== }

Function TopMenuCap(M: Integer): String;
Begin
 Case M Of
  1: TopMenuCap:='&Fichier';
  2: TopMenuCap:='&Edition';
  3: TopMenuCap:='&Style';
  4: TopMenuCap:='&Graphique';
  5: TopMenuCap:='&Impression';
  6: TopMenuCap:='&Base';
  7: TopMenuCap:='&Outils';
  8: TopMenuCap:='&D'#130'faut';
  9: TopMenuCap:='Fe&n'#136'tres';
  Else TopMenuCap:='';
 End;
End;

Function TopMenuX(M: Integer): Integer;
Var I, X: Integer;
Begin
 X:=6;
 For I:=1 To M-1 Do X:=X+Length(StripAmp(TopMenuCap(I)))*8+8;
 TopMenuX:=X;
End;

Procedure DrawMenuBar;
Var I, X: Integer;
Begin
 FillBox(0,0,SCR_W-1,15,CL_LGRAY);
 For I:=1 To 9 Do Begin
  X:=TopMenuX(I);
  If MenuTop=I Then Begin
   FillBox(X-4,1,X+Length(StripAmp(TopMenuCap(I)))*8+3,14,CL_RED);
   DrawHK(X,4,TopMenuCap(I),CL_WHITE,CL_YELLOW);
  End Else DrawHK(X,4,TopMenuCap(I),CL_BLACK,CL_RED);
 End;
 TextAt(604,4,'?',CL_BLACK);
 TextAt(620,4,#24#25,CL_BLACK);
End;

Procedure LayoutToolbar;
Var X, I, W: Integer;
 Procedure AddB(Const Cap: String; Cmd, X1, X2: Integer);
 Begin
  Inc(NBtn);
  BtnCap[NBtn]:=Cap; BtnCmd[NBtn]:=Cmd; BtnX1[NBtn]:=X1; BtnX2[NBtn]:=X2;
 End;
 Procedure AddSeq(Const Cap: String; Cmd: Integer);
 Begin
  W:=Length(Cap)*8+6;
  AddB(Cap,Cmd,X,X+W-1);
  X:=X+W+2;
 End;
Begin
 NBtn:=0;
 AddB(#17,CM_PGLEFT,2,15);
 AddB(#16,CM_PGRIGHT,18,31);
 AddB(#30,CM_PGUP,34,47);
 AddB(#31,CM_PGDOWN,50,63);
 X:=72;
 If BarSet=1 Then Begin
  AddSeq('Efface',CM_CLEAR);
  AddSeq('Copie',CM_COPY);
  AddSeq('D'#130'place',CM_MOVE);
  AddSeq('Style',CM_TB_STYLE);
  AddSeq('Aligne',CM_TB_ALIGN);
  AddSeq('Fonte',CM_TB_FONT);
  AddSeq('Ins'#138're',CM_TB_INS);
  AddSeq('Supprime',CM_TB_DEL);
  AddSeq('Ajuste',CM_FIT);
 End Else Begin
  AddSeq('Somme',CM_SUM);
  AddSeq('Trie',CM_QSORT);
  AddSeq('Graphe',CM_GVIEW);
  AddSeq('Format',CM_TB_FMT);
  AddSeq('Largeur',CM_COLW);
  AddSeq('Gras',CM_BOLD);
  AddSeq('Aide',CM_HELP);
 End;
 AddB('Barre',CM_BARSET,584,630);
End;

Procedure DrawToolbar;
Var I, Tw: Integer;
Begin
 LayoutToolbar;
 FillBox(0,16,SCR_W-1,41,CL_LGRAY);
 For I:=1 To NBtn Do Begin
  FillBox(BtnX1[I],19,BtnX2[I],37,CL_LGRAY);
  If BtnDown=I Then Sunken(BtnX1[I],19,BtnX2[I],37) Else Raised(BtnX1[I],19,BtnX2[I],37);
  Tw:=Length(BtnCap[I])*8;
  TextAt(BtnX1[I]+((BtnX2[I]-BtnX1[I]+1-Tw) Div 2)+Ord(BtnDown=I),24+Ord(BtnDown=I),BtnCap[I],CL_BLACK);
 End;
End;

Function FmtCode(P: PCell): String;
Var S: String;
Begin
 S:='';
 If P<>Nil Then
  Case P^.Fmt Of
   FM_FIXED: S:='F'+IntStr(P^.Dec);
   FM_SCI:   S:='S'+IntStr(P^.Dec);
   FM_CURR:  S:='C'+IntStr(P^.Dec);
   FM_COMMA: S:=','+IntStr(P^.Dec);
   FM_PLUS:  S:='+';
   FM_PCT:   S:='P'+IntStr(P^.Dec);
   FM_DATE:  S:='D'+IntStr(P^.Dec);
   FM_TEXT:  S:='TX';
   FM_HIDDEN: S:='H';
   FM_TIME:  S:='T'+IntStr(P^.Dec);
  End;
 If (P<>Nil) And (P^.Prot<>0) Then Begin
  If S<>'' Then S:=S+',';
  S:=S+'PR';
 End;
 If S<>'' Then S:='('+S+') ';
 FmtCode:=S;
End;

Procedure DrawInputLine;
Var S: String; P: PCell; X: Integer;
Begin
 FillBox(0,YInp,SCR_W-1,YInp+13,CL_BLACK);
 If PromptOn Then Begin
  S:=PromptTitle+' ';
  TextAt(6,YInp+3,S,CL_LCYAN);
  X:=6+Length(S)*8;
  TextAt(X,YInp+3,PromptTxt,CL_WHITE);
  HLine(X+(PromptPos-1)*8,X+(PromptPos-1)*8+7,YInp+11,CL_WHITE);
  Exit;
 End;
 S:=CellName(Sh^.CurR,Sh^.CurC)+': ';
 TextAt(0,YInp+3,S,CL_WHITE);
 X:=Length(S)*8;
 If Editing Then Begin
  TextAt(X,YInp+3,EdTxt,CL_WHITE);
  HLine(X+(EdPos-1)*8,X+(EdPos-1)*8+7,YInp+11,CL_WHITE);
  Exit;
 End;
 P:=FindCell(Sh,Sh^.CurR,Sh^.CurC);
 S:=FmtCode(P);
 If Sh^.ColW[Sh^.CurC]<>DefColW Then S:=S+'[W'+IntStr(Sh^.ColW[Sh^.CurC])+'] ';
 S:=S+CellSource(P);
 If Length(S)>76 Then S:=Copy(S,1,76);
 TextAt(X,YInp+3,S,CL_WHITE);
End;

Procedure DrawHeaders;
Var I, X, Y, W, C, R: Integer; G: TRange; Hi: Boolean; S: String;
Begin
 GetSel(G);
 FillBox(0,YHdr,SCR_W-1,YHdr+13,CL_WHITE);
 FillBox(0,YHdr+2,7,YHdr+12,CL_LGREEN);
 Rectangle(0,YHdr+2,7,YHdr+12);
 FillBox(GRID_L,YHdr,GRID_R,YHdr+13,CL_WHITE);
 FillBox(0,YGrid,GRID_L-1,GRID_BOT+1,CL_WHITE);
 For I:=0 To NVC-1 Do Begin
  C:=VC[I]; X:=VX[I]; W:=ColPx(C);
  Hi:=(C>=G.C1) And (C<=G.C2);
  If Hi Then FillBox(X,YHdr,X+W-1,YHdr+13,CL_DGRAY)
   Else FillBox(X,YHdr,X+W-1,YHdr+13,CL_LGRAY);
  Raised(X,YHdr,X+W-1,YHdr+13);
  S:=ColName(C);
  If Hi Then TextAt(X+(W-Length(S)*8) Div 2,YHdr+3,S,CL_WHITE)
   Else TextAt(X+(W-Length(S)*8) Div 2,YHdr+3,S,CL_BLACK);
 End;
 For I:=0 To NVR-1 Do Begin
  R:=VR[I]; Y:=VY[I];
  Hi:=(R>=G.R1) And (R<=G.R2);
  If Hi Then FillBox(0,Y,GRID_L-2,Y+ROW_H-1,CL_DGRAY)
   Else FillBox(0,Y,GRID_L-2,Y+ROW_H-1,CL_LGRAY);
  Raised(0,Y,GRID_L-2,Y+ROW_H-1);
  S:=IntStr(R+1);
  If Hi Then TextAt(GRID_L-4-Length(S)*8,Y+5,S,CL_WHITE)
   Else TextAt(GRID_L-4-Length(S)*8,Y+5,S,CL_BLACK);
 End;
End;

Function CellIsBlank(R, C: Integer): Boolean;
Var P: PCell;
Begin
 P:=FindCell(Sh,R,C);
 CellIsBlank:=(P=Nil) Or (P^.Kind=CK_EMPTY);
End;

Procedure DrawGrid;
Var I, J, R, C, X, Y, W, Cap, Ext, K, L, Tx: Integer; G: TRange; P: PCell;
    S: String; Al: Byte; IsCur, InSel: Boolean; Fg: Integer;
Begin
 FillBox(GRID_L,YGrid,GRID_R,GRID_BOT+1,CL_WHITE);
 GetSel(G);
 For J:=0 To NVR-1 Do Begin
  R:=VR[J]; Y:=VY[J];
  For I:=0 To NVC-1 Do Begin
   C:=VC[I]; X:=VX[I]; W:=ColPx(C);
   IsCur:=(R=Sh^.CurR) And (C=Sh^.CurC);
   InSel:=Sh^.SelOn And (R>=G.R1) And (R<=G.R2) And (C>=G.C1) And (C<=G.C2);
   If IsCur Then FillBox(X,Y,X+W-1,Y+ROW_H-1,CL_DGRAY)
   Else If InSel Then FillBox(X,Y,X+W-1,Y+ROW_H-1,CL_LGRAY);
   If ShowGrid Then Begin
    HLine(X,X+W-1,Y+ROW_H-1,CL_LGRAY);
    VLine(X+W-1,Y,Y+ROW_H-1,CL_LGRAY);
   End;
  End;
  If Sh^.Rows^[R]<>Nil Then
   For I:=0 To NVC-1 Do Begin
    C:=VC[I]; X:=VX[I]; W:=ColPx(C);
    P:=Sh^.Rows^[R]^[C];
    If (P<>Nil) And (P^.Kind<>CK_EMPTY) Then Begin
     Cap:=W Div 8;
     S:=CellDisplay(P,Cap,Al);
     If S<>'' Then Begin
      IsCur:=(R=Sh^.CurR) And (C=Sh^.CurC);
      Ext:=W;
      If (Al=AL_LEFT) And (Not IsCur) And (Length(S)*8>W-2) Then Begin
       K:=I+1;
       While (K<NVC) And CellIsBlank(R,VC[K]) And (VX[K]=VX[K-1]+ColPx(VC[K-1])) Do Begin
        Ext:=Ext+ColPx(VC[K]); Inc(K);
       End;
      End;
      L:=Length(S);
      If L*8>Ext Then Begin L:=Ext Div 8; S:=Copy(S,1,L); End;
      Case Al Of
       AL_RIGHT:  Tx:=X+W-1-L*8;
       AL_CENTER: Tx:=X+(W-L*8) Div 2;
       Else       Tx:=X+2;
      End;
      If Tx<X Then Tx:=X;
      If IsCur Then Fg:=CL_WHITE Else Fg:=CL_BLACK;
      TextAt(Tx,Y+5,S,Fg);
      If (P^.Fnt And 1)<>0 Then TextAt(Tx+1,Y+5,S,Fg);
      If (P^.Fnt And 2)<>0 Then HLine(Tx,Tx+L*8-1,Y+ROW_H-3,Fg);
     End;
    End;
   End;
 End;
End;

Procedure DrawScrollBars;
Var X, Y: Integer;
Begin
 FillBox(0,HSB_Y,GRID_R,HSB_Y+13,CL_WHITE);
 HLine(0,GRID_R,HSB_Y+6,CL_LGREEN);
 HLine(0,GRID_R,HSB_Y+7,CL_LGREEN);
 X:=(Sh^.CurC*(GRID_R-12)) Div (MAX_COLS-1);
 FillBox(X,HSB_Y+1,X+8,HSB_Y+12,CL_LGREEN);
 Rectangle(X,HSB_Y+1,X+8,HSB_Y+12);
 FillBox(GRID_R+1,YHdr,SCR_W-1,HSB_Y+13,CL_WHITE);
 VLine(GRID_R+4,YHdr,HSB_Y+13,CL_LGREEN);
 VLine(GRID_R+5,YHdr,HSB_Y+13,CL_LGREEN);
 Y:=YHdr+(Sh^.CurR*(HSB_Y-YHdr-12)) Div (MAX_ROWS-1);
 FillBox(GRID_R+1,Y,SCR_W-1,Y+11,CL_LGREEN);
 Rectangle(GRID_R+1,Y,SCR_W-1,Y+11);
End;

Function TwoDig(N: Word): String;
Var S: String;
Begin
 S:=IntStr(N);
 If Length(S)<2 Then S:='0'+S;
 TwoDig:=S;
End;

Procedure DrawStatus;
Var Y, M, D, Dw, H, Mi, S, S100: Word; T: String;
Begin
 FillBox(0,STAT_Y,SCR_W-1,SCR_H-1,CL_BLACK);
 If StatHelp<>'' Then TextAt(0,STAT_Y+5,StatHelp,CL_WHITE)
 Else Begin
  T:=UpStr(BaseName(Sh^.Name));
  If Length(T)>12 Then T:=Copy(T,Length(T)-11,12);
  TextAt(0,STAT_Y+5,T,CL_WHITE);
  GetDate(Y,M,D,Dw);
  GetTime(H,Mi,S,S100);
  TextAt(104,STAT_Y+5,'['+IntStr(CurWin)+'] '+TwoDig(D)+'/'+TwoDig(M)+'/'+IntStr(Y)+
         ' '+TwoDig(H)+':'+TwoDig(Mi),CL_WHITE);
  LastMin:=Mi;
 End;
 If CircFlag Then TextAt(440,STAT_Y+5,'CIRC',CL_LRED)
  Else If NeedCalc Then TextAt(440,STAT_Y+5,'CALC',CL_YELLOW);
 If EndMode Then TextAt(500,STAT_Y+5,'FIN',CL_LCYAN);
 If Sh^.SelOn Then TextAt(540,STAT_Y+5,'SEL',CL_LCYAN);
 TextAt(584,STAT_Y+5,ModeStr,CL_WHITE);
End;

Procedure DrawAll;
Begin
 CalcVisible;
 DrawMenuBar;
 If ShowBar Then DrawToolbar;
 DrawInputLine;
 DrawHeaders;
 DrawGrid;
 DrawScrollBars;
 DrawStatus;
End;

Procedure BeginFrame;
Begin
 {$IFDEF FPC}
 EraseSoftCursor;
 {$ELSE}
 HideMouse;
 {$ENDIF}
 DrawAll;
End;

Procedure EndFrame;
Begin
 {$IFDEF FPC}
 DrawSoftCursor(MsX,MsY);
 {$ELSE}
 ShowMouse;
 {$ENDIF}
End;

Procedure Redraw;
Begin
 BeginFrame;
 EndFrame;
End;

Procedure MoveSoftCursor;
Begin
 {$IFDEF FPC}
 EraseSoftCursor;
 DrawSoftCursor(MsX,MsY);
 {$ENDIF}
End;

{ ====================================================================== }
{                           ENTREES (CLAVIER/SOURIS)                     }
{ ====================================================================== }

Function ReadKeyEx: Word;
Var Ch: Char;
Begin
 Ch:=ReadKey;
 If Ch=#0 Then Begin
  Ch:=ReadKey;
  ReadKeyEx:=256+Ord(Ch);
 End Else ReadKeyEx:=Ord(Ch);
End;

Function PollMouse: Boolean;
Var X, Y, B: LongInt;
Begin
 GetMouseState(X,Y,B);
 EdgeDown:=((B And MB_LEFT)<>0) And ((MsBtn And MB_LEFT)=0);
 EdgeUp:=((B And MB_LEFT)=0) And ((MsBtn And MB_LEFT)<>0);
 PollMouse:=(X<>MsX) Or (Y<>MsY) Or (B<>MsBtn);
 MsX:=X; MsY:=Y; MsBtn:=B;
End;

{ Attend un evenement : 1 = touche, 2 = souris. }
Function GetEvent(Var K: Word): Integer;
Var Ev: Integer; Ch: Char;
Begin
 Ev:=0;
 Repeat
  If KeyPressed Then Begin
   K:=ReadKeyEx;
   Ev:=1;
  End Else If PollMouse Then Ev:=2
  Else Delay(8);
 Until Ev<>0;
 GetEvent:=Ev;
End;

Procedure Beep;
Begin
 Sound(800);
 Delay(60);
 NoSound;
End;

{ ====================================================================== }
{                  EDITION DE TEXTE ET BOITES DE DIALOGUE                }
{ ====================================================================== }

Function EditKey(Var T: String; Var P: Integer; K: Word; MaxLen: Integer): Boolean;
Begin
 EditKey:=True;
 If (K>=32) And (K<=255) Then Begin
  If Length(T)<MaxLen Then Begin Insert(Chr(K),T,P); Inc(P); End;
 End Else
  Case K Of
   KEY_BS:    If P>1 Then Begin Delete(T,P-1,1); Dec(P); End;
   KEY_DEL:   If P<=Length(T) Then Delete(T,P,1);
   KEY_LEFT:  If P>1 Then Dec(P);
   KEY_RIGHT: If P<=Length(T) Then Inc(P);
   KEY_HOME:  P:=1;
   KEY_END:   P:=Length(T)+1;
   Else EditKey:=False;
  End;
End;

Function PromptStr(Const Title: String; Var S: String; MaxLen: Integer): Boolean;
Var K: Word; T: String; P: Integer; Res, Done, First: Boolean; Ev: Integer; OldMode: String[8];
Begin
 T:=S; P:=Length(T)+1; Done:=False; Res:=False; First:=True;
 OldMode:=ModeStr;
 PromptOn:=True; PromptTitle:=Title; ModeStr:='ENTREE';
 Repeat
  PromptTxt:=T; PromptPos:=P;
  Redraw;
  Ev:=GetEvent(K);
  If Ev=1 Then Begin
   If K=KEY_ENTER Then Begin Res:=True; Done:=True; End
   Else If K=KEY_ESC Then Done:=True
   Else Begin
    If First And (K>=32) And (K<=255) Then Begin T:=''; P:=1; End;
    If EditKey(T,P,K,MaxLen) Then First:=False;
   End;
  End;
 Until Done;
 PromptOn:=False; ModeStr:=OldMode;
 If Res Then S:=T;
 PromptStr:=Res;
End;

Procedure SelOrCursor(Var G: TRange);
Begin
 GetSel(G);
End;

Procedure MoveCurNav(K: Word); Forward;

{ Saisie d'un bloc avec possibilite de pointer au clavier / a la souris. }
Function PromptRange(Const Title: String; Var G: TRange): Boolean;
Var K: Word; T: String; P: Integer; Res, Done, Fresh, Typed, Anch, Drag, IsNav: Boolean; Ev: Integer;
    OR_, OC_, OT_, OL_, AR_, AC_: Integer; OS_: Boolean; OM_: Byte; R, C: Integer; G2: TRange;
    OldMode: String[8];
Begin
 OR_:=Sh^.CurR; OC_:=Sh^.CurC; OT_:=Sh^.TopR; OL_:=Sh^.LeftC;
 OS_:=Sh^.SelOn; OM_:=Sh^.SelMode; AR_:=Sh^.AnchR; AC_:=Sh^.AnchC;
 T:=RangeStr(G); P:=Length(T)+1;
 Done:=False; Res:=False; Fresh:=True; Typed:=False; Anch:=False; Drag:=False;
 OldMode:=ModeStr;
 PromptOn:=True; PromptTitle:=Title; ModeStr:='POINTE';
 Repeat
  PromptTxt:=T; PromptPos:=P;
  Redraw;
  Ev:=GetEvent(K);
  If Ev=2 Then Begin
   If EdgeDown And GridHit(MsX,MsY,R,C) Then Begin
    Sh^.CurR:=R; Sh^.CurC:=C; Sh^.AnchR:=R; Sh^.AnchC:=C; Sh^.SelOn:=True; Sh^.SelMode:=0;
    Drag:=True; Fresh:=True; Typed:=False; Anch:=True;
    GetSel(G2); T:=RangeStr(G2); P:=Length(T)+1;
   End Else If Drag And ((MsBtn And MB_LEFT)<>0) And GridHit(MsX,MsY,R,C) Then Begin
    Sh^.CurR:=R; Sh^.CurC:=C;
    GetSel(G2); T:=RangeStr(G2); P:=Length(T)+1;
   End;
   If (MsBtn And MB_LEFT)=0 Then Drag:=False;
  End Else Begin
   IsNav:=(K=KEY_UP) Or (K=KEY_DOWN) Or (K=KEY_LEFT) Or (K=KEY_RIGHT) Or
          (K=KEY_PGUP) Or (K=KEY_PGDN) Or (K=KEY_HOME) Or (K=KEY_TAB) Or (K=KEY_SHTAB);
   If K=KEY_ENTER Then Begin
    If ParseRangeStr(T,G2) Then Begin G:=G2; Res:=True; Done:=True; End
     Else Beep;
   End Else If K=KEY_ESC Then Done:=True
   Else If (K=Ord('.')) And (Not Typed) And (Not Anch) Then Begin
    Anch:=True; Sh^.AnchR:=Sh^.CurR; Sh^.AnchC:=Sh^.CurC; Sh^.SelOn:=True; Sh^.SelMode:=0;
    Fresh:=True;
    GetSel(G2); T:=RangeStr(G2); P:=Length(T)+1;
   End Else If IsNav And (Not Typed) Then Begin
    MoveCurNav(K);
    Fresh:=True;
    GetSel(G2); T:=RangeStr(G2); P:=Length(T)+1;
   End Else If (K=KEY_UP) Or (K=KEY_DOWN) Or (K=KEY_PGUP) Or (K=KEY_PGDN) Or (K=KEY_TAB) Or (K=KEY_SHTAB) Then Begin
   End Else Begin
    If Fresh And (K>=32) And (K<=255) Then Begin T:=''; P:=1; End;
    If EditKey(T,P,K,40) Then Begin
     Fresh:=False;
     If (K>=32) And (K<=255) Then Typed:=True;
    End;
   End;
  End;
 Until Done;
 PromptOn:=False; ModeStr:=OldMode;
 Sh^.CurR:=OR_; Sh^.CurC:=OC_; Sh^.TopR:=OT_; Sh^.LeftC:=OL_;
 Sh^.SelOn:=OS_; Sh^.SelMode:=OM_; Sh^.AnchR:=AR_; Sh^.AnchC:=AC_;
 PromptRange:=Res;
End;

Procedure DrawDialog(X1, Y1, X2, Y2: Integer; Const Title: String);
Begin
 FillBox(X1+5,Y1+5,X2+5,Y2+5,CL_BLACK);
 FillBox(X1,Y1,X2,Y2,CL_LGRAY);
 Raised(X1,Y1,X2,Y2);
 Raised(X1+3,Y1+3,X2-3,Y2-3);
 If Title<>'' Then Begin
  FillBox(X1+5,Y1+5,X2-5,Y1+19,CL_BLUE);
  TextAt(X1+((X2-X1)-Length(Title)*8) Div 2,Y1+8,Title,CL_WHITE);
 End;
End;

Procedure SplitLines(Const Msg: String; Var Ln: Array Of String; Var N: Integer; Var MaxL: Integer);
Var I: Integer; S: String;
Begin
 N:=0; MaxL:=0; S:='';
 For I:=1 To Length(Msg)+1 Do Begin
  If (I>Length(Msg)) Or (Msg[I]='|') Then Begin
   If N<=High(Ln) Then Begin Ln[N]:=S; Inc(N); If Length(S)>MaxL Then MaxL:=Length(S); End;
   S:='';
  End Else S:=S+Msg[I];
 End;
End;

Procedure MsgBox(Const Msg: String);
Var Ln: Array[0..9] Of String; N, MaxL, I, X1, Y1, X2, Y2, W, H: Integer; K: Word; Ev: Integer;
    Done: Boolean;
Begin
 SplitLines(Msg,Ln,N,MaxL);
 W:=MaxL*8+48; If W<200 Then W:=200;
 H:=44+N*14+36;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 Done:=False;
 Repeat
  BeginFrame;
  DrawDialog(X1,Y1,X2,Y2,'Quattro Pro');
  For I:=0 To N-1 Do TextAt(X1+24,Y1+30+I*14,Ln[I],CL_BLACK);
  FillBox((X1+X2) Div 2-24,Y2-30,(X1+X2) Div 2+24,Y2-12,CL_RED);
  TextAt((X1+X2) Div 2-8,Y2-25,'OK',CL_WHITE);
  EndFrame;
  Ev:=GetEvent(K);
  If Ev=1 Then Begin
   If (K=KEY_ENTER) Or (K=KEY_ESC) Or (K=32) Then Done:=True;
  End Else If EdgeDown Then Begin
   If (MsX>=(X1+X2) Div 2-24) And (MsX<=(X1+X2) Div 2+24) And (MsY>=Y2-30) And (MsY<=Y2-12) Then Done:=True;
  End;
 Until Done;
End;

Function AskYesNo(Const Msg: String): Boolean;
Var Ln: Array[0..9] Of String; N, MaxL, I, X1, Y1, X2, Y2, W, H, Cx: Integer; K: Word; Ev: Integer;
    Done, Res, Yes: Boolean;
Begin
 SplitLines(Msg,Ln,N,MaxL);
 W:=MaxL*8+48; If W<220 Then W:=220;
 H:=44+N*14+36;
 X1:=(SCR_W-W) Div 2; Y1:=(SCR_H-H) Div 2; X2:=X1+W; Y2:=Y1+H;
 Cx:=(X1+X2) Div 2;
 Done:=False; Res:=True; Yes:=True;
 Repeat
  BeginFrame;
  DrawDialog(X1,Y1,X2,Y2,'Quattro Pro');
  For I:=0 To N-1 Do TextAt(X1+24,Y1+30+I*14,Ln[I],CL_BLACK);
  If Yes Then FillBox(Cx-60,Y2-30,Cx-12,Y2-12,CL_RED) Else FillBox(Cx-60,Y2-30,Cx-12,Y2-12,CL_LGRAY);
  Raised(Cx-60,Y2-30,Cx-12,Y2-12);
  If Yes Then TextAt(Cx-48,Y2-25,'Oui',CL_WHITE) Else TextAt(Cx-48,Y2-25,'Oui',CL_BLACK);
  If Not Yes Then FillBox(Cx+12,Y2-30,Cx+60,Y2-12,CL_RED) Else FillBox(Cx+12,Y2-30,Cx+60,Y2-12,CL_LGRAY);
  Raised(Cx+12,Y2-30,Cx+60,Y2-12);
  If Not Yes Then TextAt(Cx+24,Y2-25,'Non',CL_WHITE) Else TextAt(Cx+24,Y2-25,'Non',CL_BLACK);
  EndFrame;
  Ev:=GetEvent(K);
  If Ev=1 Then Begin
   Case K Of
    KEY_ENTER: Begin Res:=Yes; Done:=True; End;
    KEY_ESC: Begin Res:=False; Done:=True; End;
    KEY_LEFT,KEY_RIGHT,KEY_TAB: Yes:=Not Yes;
    Ord('o'),Ord('O'),Ord('y'),Ord('Y'): Begin Res:=True; Done:=True; End;
    Ord('n'),Ord('N'): Begin Res:=False; Done:=True; End;
   End;
  End Else If EdgeDown Then Begin
   If (MsY>=Y2-30) And (MsY<=Y2-12) Then Begin
    If (MsX>=Cx-60) And (MsX<=Cx-12) Then Begin Res:=True; Done:=True; End;
    If (MsX>=Cx+12) And (MsX<=Cx+60) Then Begin Res:=False; Done:=True; End;
   End;
  End;
 Until Done;
 AskYesNo:=Res;
End;

{ ====================================================================== }
{                    LISTE DEFILANTE (aide, apercu, ...)                 }
{ ====================================================================== }

Procedure LstClear;
Var I: Integer;
Begin
 For I:=1 To LstN Do
  If Lst^[I]<>Nil Then Begin FreeMem(Lst^[I],Length(Lst^[I]^)+1); Lst^[I]:=Nil; End;
 LstN:=0;
End;

Procedure LstAdd(Const S: String);
Begin
 If LstN>=MAXLST Then Exit;
 Inc(LstN);
 Lst^[LstN]:=Nil;
 SetStr(Lst^[LstN],S);
 If Lst^[LstN]=Nil Then Begin GetMem(Lst^[LstN],1); Lst^[LstN]^[0]:=#0; End;
End;

Procedure ShowList(Const Title: String);
Var Top, I, Rows, X1, Y1, X2, Y2, Ev: Integer; K: Word; Done: Boolean; S: String;
Begin
 Rows:=20; Top:=1; Done:=False;
 X1:=20; Y1:=30; X2:=SCR_W-21; Y2:=Y1+Rows*14+60;
 Repeat
  BeginFrame;
  DrawDialog(X1,Y1,X2,Y2,Title);
  FillBox(X1+10,Y1+26,X2-10,Y1+26+Rows*14+2,CL_WHITE);
  Sunken(X1+10,Y1+26,X2-10,Y1+26+Rows*14+2);
  For I:=0 To Rows-1 Do
   If Top+I<=LstN Then Begin
    S:=Copy(GetStr(Lst^[Top+I]),1,70);
    TextAt(X1+14,Y1+30+I*14,S,CL_BLACK);
   End;
  TextAt(X1+14,Y2-24,'Haut/Bas, PgUp/PgDn : d'#130'filer   Echap : fermer',CL_BLACK);
  EndFrame;
  Ev:=GetEvent(K);
  If Ev=1 Then Begin
   Case K Of
    KEY_ESC,KEY_ENTER: Done:=True;
    KEY_UP: If Top>1 Then Dec(Top);
    KEY_DOWN: If Top<LstN-Rows+1 Then Inc(Top);
    KEY_PGUP: Begin Top:=Top-Rows; If Top<1 Then Top:=1; End;
    KEY_PGDN: Begin Top:=Top+Rows; If Top>LstN-Rows+1 Then Top:=LstN-Rows+1; If Top<1 Then Top:=1; End;
    KEY_HOME: Top:=1;
    KEY_END: Begin Top:=LstN-Rows+1; If Top<1 Then Top:=1; End;
   End;
  End Else If EdgeDown Then Begin
   If (MsX<X1) Or (MsX>X2) Or (MsY<Y1) Or (MsY>Y2) Then Done:=True;
  End;
 Until Done;
End;

{ ====================================================================== }
{                     DEFINITION DES MENUS DEROULANTS                    }
{ ====================================================================== }

Procedure BeginMenu(Id: Integer);
Begin
 CurBuild:=Id;
 MenuDef[Id].First:=NItm+1;
 MenuDef[Id].Cnt:=0;
End;

Procedure AddI(Const Cap: String; Cmd, Sub: Integer; Const Sc: String);
Begin
 Inc(NItm);
 Itm[NItm].Cap:=Cap;
 Itm[NItm].Sc:=Sc;
 Itm[NItm].Cmd:=Cmd;
 Itm[NItm].Sub:=Sub;
 Itm[NItm].Sep:=False;
 Itm[NItm].HK:=HotKeyOf(Cap);
 Inc(MenuDef[CurBuild].Cnt);
End;

Procedure AddSep;
Begin
 Inc(NItm);
 Itm[NItm].Cap:='';
 Itm[NItm].Sc:='';
 Itm[NItm].Cmd:=0;
 Itm[NItm].Sub:=0;
 Itm[NItm].Sep:=True;
 Itm[NItm].HK:=#0;
 Inc(MenuDef[CurBuild].Cnt);
End;

Procedure BuildMenus;
Var I: Integer;
Begin
 NItm:=0;
 BeginMenu(M_FILE);
 AddI('&Nouvelle feuille',CM_NEW,0,'');
 AddI('&Ouverture',CM_OPEN,0,'');
 AddI('&Chargement',CM_LOAD,0,'');
 AddSep;
 AddI('&Sauvegarde',CM_SAVE,0,'Ctrl-S');
 AddI('&Autre nom',CM_SAVEAS,0,'');
 AddI('Tout sau&vegarder',CM_SAVEALL,0,'');
 AddI('&Fermeture',CM_CLOSE,0,'');
 AddI('&Tout fermer',CM_CLOSEALL,0,'');
 AddI('&Effacement',CM_ERASE,0,'');
 AddSep;
 AddI('&R'#130'pertoire de donn'#130'es',CM_DIR,0,'');
 AddI('E&space de travail',0,M_WSPACE,'');
 AddI('&Utilitaires',0,M_FUTIL,'');
 AddI('&Quitter',CM_QUIT,0,'Ctrl-Q');

 BeginMenu(M_WSPACE);
 AddI('&Sauvegarde',CM_WS_SAVE,0,'');
 AddI('&Restauration',CM_WS_REST,0,'');

 BeginMenu(M_FUTIL);
 AddI('&Interpr'#130'teur DOS',CM_DOS,0,'');
 AddI('&Gestionnaire de fichiers',CM_FM,0,'');
 AddI('&SQZ! (compression)',0,M_SQZ,'');

 BeginMenu(M_SQZ);
 AddI('E&xclusion cellules vides',CM_SQZE,M_SQZE,'');
 AddI('&Stockage des formules',CM_SQZF,M_SQZF,'');
 AddI('&Version',CM_SQZV,M_SQZV,'');
 AddI('<= &retour',CM_BACK,0,'');
 BeginMenu(M_SQZE);
 AddI('&Oui',CM_SQZE_Y,0,'');
 AddI('&Non',CM_SQZE_N,0,'');
 BeginMenu(M_SQZF);
 AddI('&Avec valeur r'#130'sultante',CM_SQZF_Y,0,'');
 AddI('&Sans valeur',CM_SQZF_N,0,'');
 BeginMenu(M_SQZV);
 AddI('&A - SQZ!',CM_SQZV_A,0,'');
 AddI('&B - Normal',CM_SQZV_B,0,'');

 BeginMenu(M_EDIT);
 AddI('&Annule',CM_UNDO,0,'Alt-F5');
 AddSep;
 AddI('&Copie',CM_COPY,0,'Ctrl-C');
 AddI('&D'#130'place',CM_MOVE,0,'');
 AddI('&Efface',CM_CLEAR,0,'Suppr');
 AddI('&Ins'#138're',0,M_EINS,'');
 AddI('&Supprime',0,M_EDEL,'');
 AddSep;
 AddI('&Valeurs',CM_VALUES,0,'');
 AddI('&Transposition',CM_TRANSP,0,'');
 AddI('Rem&plissage',CM_FILL,0,'');
 AddSep;
 AddI('&Recherche',CM_FIND,0,'');
 AddI('Re&mplace',CM_REPL,0,'');
 AddSep;
 AddI('&Noms',0,M_ENAMES,'');
 BeginMenu(M_EINS);
 AddI('&Lignes',CM_INSROW,0,'');
 AddI('&Colonnes',CM_INSCOL,0,'');
 BeginMenu(M_EDEL);
 AddI('&Lignes',CM_DELROW,0,'');
 AddI('&Colonnes',CM_DELCOL,0,'');
 BeginMenu(M_ENAMES);
 AddI('&Cr'#130'er',CM_NMCREATE,0,'');
 AddI('&Supprimer',CM_NMDEL,0,'');
 AddI('&Tout supprimer',CM_NMDELALL,0,'');
 AddI('&Liste',CM_NMLIST,0,'');

 BeginMenu(M_STYLE);
 AddI('&Alignement',0,M_SALIGN,'');
 AddI('Format &num'#130'rique',0,M_SFMT,'');
 AddI('&Protection',0,M_SPROT,'');
 AddI('&Largeur colonne',CM_COLW,0,'');
 AddI('Largeur colonne en&semble',0,M_SCW,'');
 AddI('&Masquer colonne',0,M_SHIDE,'');
 AddI('&Fonte',0,M_SFONT,'');
 AddI('A&juste colonne',CM_FIT,0,'');
 BeginMenu(M_SALIGN);
 AddI('&G'#130'n'#130'ral',CM_AL_G,0,'');
 AddI('G&auche',CM_AL_L,0,'');
 AddI('&Droite',CM_AL_R,0,'');
 AddI('&Centr'#130,CM_AL_C,0,'');
 BeginMenu(M_SFMT);
 AddI('&Fixe',CM_FM_F,0,'');
 AddI('&Scientifique',CM_FM_S,0,'');
 AddI('&Mon'#130'taire',CM_FM_C,0,'');
 AddI('&Virgule',CM_FM_COMMA,0,'');
 AddI('&G'#130'n'#130'ral',CM_FM_G,0,'');
 AddI('&+/-',CM_FM_PLUS,0,'');
 AddI('&Pourcentage',CM_FM_PCT,0,'');
 AddI('&Date',0,M_SDATE,'');
 AddI('&Heure',0,M_STIME,'');
 AddI('&Texte',CM_FM_TEXT,0,'');
 AddI('M&asqu'#130,CM_FM_HID,0,'');
 BeginMenu(M_SDATE);
 AddI('&1 (JJ-MMM-AA)',CM_FM_D1,0,'');
 AddI('&2 (JJ-MMM)',CM_FM_D1+1,0,'');
 AddI('&3 (MMM-AA)',CM_FM_D1+2,0,'');
 AddI('&4 (JJ/MM/AA)',CM_FM_D1+3,0,'');
 AddI('&5 (JJ/MM)',CM_FM_D1+4,0,'');
 BeginMenu(M_STIME);
 AddI('&1 (HH:MM:SS AM/PM)',CM_FM_T1,0,'');
 AddI('&2 (HH:MM AM/PM)',CM_FM_T1+1,0,'');
 AddI('&3 (HH:MM:SS)',CM_FM_T1+2,0,'');
 AddI('&4 (HH:MM)',CM_FM_T1+3,0,'');
 BeginMenu(M_SPROT);
 AddI('&Prot'#130'g'#130,CM_PROT_Y,0,'');
 AddI('&Non prot'#130'g'#130,CM_PROT_N,0,'');
 BeginMenu(M_SCW);
 AddI('&D'#130'finir',CM_CW_SET,0,'');
 AddI('&R'#130'initialiser',CM_CW_RST,0,'');
 BeginMenu(M_SHIDE);
 AddI('&Masquer',CM_HIDE,0,'');
 AddI('&Afficher',CM_UNHIDE,0,'');
 BeginMenu(M_SFONT);
 AddI('&Normal',CM_FONT_N,0,'');
 AddI('&Gras',CM_FONT_B,0,'');
 AddI('&Soulign'#130,CM_FONT_U,0,'');
 AddI('G&ras soulign'#130,CM_FONT_BU,0,'');

 BeginMenu(M_GRAPH);
 AddI('&Type de graphique',CM_GTYPE,M_GTYPE,'');
 AddI('&S'#130'ries',0,M_GSER,'');
 AddI('T&itres',0,M_GTITLE,'');
 AddI('&Quadrillage',CM_GGRID,M_GGRID,'');
 AddI('&Effacer',0,M_GCLEAR,'');
 AddSep;
 AddI('&Afficher',CM_GVIEW,0,'F10');
 BeginMenu(M_GTYPE);
 AddI('&Barres',CM_GT_BAR,0,'');
 AddI('Barres &empil'#130'es',CM_GT_STK,0,'');
 AddI('&Lignes',CM_GT_LINE,0,'');
 AddI('&XY (nuage)',CM_GT_XY,0,'');
 AddI('&Secteurs',CM_GT_PIE,0,'');
 BeginMenu(M_GSER);
 AddI('&X (cat'#130'gories)',CM_GS_X,0,'');
 For I:=1 To 6 Do AddI('&'+IntStr(I)+' S'#130'rie '+IntStr(I),CM_GS_1+I-1,0,'');
 BeginMenu(M_GTITLE);
 AddI('&Titre 1',CM_GTT1,0,'');
 AddI('Titre &2',CM_GTT2,0,'');
 AddI('Axe &X',CM_GTTX,0,'');
 AddI('Axe &Y',CM_GTTY,0,'');
 BeginMenu(M_GGRID);
 AddI('&Oui',CM_GGRID_Y,0,'');
 AddI('&Non',CM_GGRID_N,0,'');
 BeginMenu(M_GCLEAR);
 AddI('&S'#130'ries',CM_GCL_SER,0,'');
 AddI('&Titres',CM_GCL_TIT,0,'');
 AddI('T&out',CM_GCL_ALL,0,'');

 BeginMenu(M_PRINT);
 AddI('&Bloc',CM_PBLOCK,0,'');
 AddI('&Destination',CM_PDEST,M_PDEST,'');
 AddI('&Ent'#136'te',CM_PHDR,0,'');
 AddI('&Pied de page',CM_PFTR,0,'');
 AddI('&Largeur de page',CM_PWIDTH,0,'');
 AddI('&Hauteur de page',CM_PHEIGHT,0,'');
 AddSep;
 AddI('&Aller',CM_PGO,0,'');
 BeginMenu(M_PDEST);
 AddI('&Imprimante',CM_PD_PRN,0,'');
 AddI('&Fichier',CM_PD_FILE,0,'');
 AddI(#130'&cran',CM_PD_SCR,0,'');

 BeginMenu(M_DB);
 AddI('&Tri',0,M_SORT,'');
 AddI('&Requ'#136'te',0,M_QUERY,'');
 BeginMenu(M_SORT);
 AddI('&Bloc',CM_SORT_BLOCK,0,'');
 AddI('&Cl'#130' 1',CM_SORT_KEY,0,'');
 AddI('&Ordre',CM_SORT_ORD,M_SORTORD,'');
 AddI('&Go',CM_SORT_GO,0,'');
 BeginMenu(M_SORTORD);
 AddI('&Croissant',CM_SORT_ASC,0,'');
 AddI('&D'#130'croissant',CM_SORT_DESC,0,'');
 BeginMenu(M_QUERY);
 AddI('&Bloc de base',CM_Q_BLOCK,0,'');
 AddI('&Crit'#138'res',CM_Q_CRIT,0,'');
 AddI('&Sortie',CM_Q_OUT,0,'');
 AddI('&Localise',CM_Q_FIND,0,'');
 AddI('&Extrait',CM_Q_EXTR,0,'');
 AddI('Eff&ace sortie',CM_Q_CLR,0,'');

 BeginMenu(M_TOOLS);
 AddI('&Recalcul',CM_RECALC,0,'F9');
 AddI('&Mode de calcul',CM_CALC_MODE,M_CALC,'');
 AddSep;
 AddI('&Statistiques',CM_STATS,0,'');
 AddI('R'#130'&gression',CM_REGR,0,'');
 BeginMenu(M_CALC);
 AddI('&Automatique',CM_CALC_AUTO,0,'');
 AddI('&Manuel',CM_CALC_MAN,0,'');

 BeginMenu(M_DEF);
 AddI('&Barre d''outils',CM_DBAR,M_DBAR,'');
 AddI('&Quadrillage',CM_DGRID,M_DGRID,'');
 AddI('&Largeur de colonne',CM_DCOLW,0,'');
 AddI('D'#130'&cimales',CM_DDEC,0,'');
 AddI('Mon'#130'&taire',CM_DCURR,0,'');
 AddI('&S'#130'parateur d'#130'cimal',CM_DSEP,M_DSEP,'');
 AddI('&R'#130'pertoire',CM_DIR,0,'');
 AddSep;
 AddI('&Mise '#133' jour',CM_DSAVE,0,'');
 BeginMenu(M_DBAR);
 AddI('&Oui',CM_DBAR_Y,0,'');
 AddI('&Non',CM_DBAR_N,0,'');
 BeginMenu(M_DGRID);
 AddI('&Oui',CM_DGRID_Y,0,'');
 AddI('&Non',CM_DGRID_N,0,'');
 BeginMenu(M_DSEP);
 AddI('&Point',CM_DSEP_P,0,'');
 AddI('&Virgule',CM_DSEP_V,0,'');

 BeginMenu(M_LOCK);
 AddI('&Horizontal',CM_LOCK_H,0,'');
 AddI('&Vertical',CM_LOCK_V,0,'');
 AddI('&Les deux',CM_LOCK_B,0,'');
 AddI('&Annuler',CM_LOCK_N,0,'');

 BeginMenu(M_WIN);
 AddI('&Suivante',CM_NEXTWIN,0,'F6');
 AddI('&Pr'#130'c'#130'dente',CM_PREVWIN,0,'');
 AddI('&Verrouillage titres',0,M_LOCK,'');
 AddSep;
 WinBase:=NItm;
 For I:=1 To MAX_WIN Do AddI('&'+IntStr(I),CM_WIN1+I-1,0,'');
 MenuDef[M_WIN].Cnt:=4;
End;

Procedure RefreshWinMenu;
Var I: Integer; S: String;
Begin
 For I:=1 To NWin Do Begin
  S:=UpStr(BaseName(Win[I]^.Name));
  If Length(S)>28 Then S:=Copy(S,Length(S)-27,28);
  Itm[WinBase+I].Cap:='&'+IntStr(I)+' '+S;
  Itm[WinBase+I].HK:=Chr(48+I);
 End;
 MenuDef[M_WIN].Cnt:=4+NWin;
End;

Function OuiNon(B: Boolean): String;
Begin
 If B Then OuiNon:='Oui' Else OuiNon:='Non';
End;

Function GraphTypeName(T: Integer): String;
Begin
 Case T Of
  1: GraphTypeName:='Barres';
  2: GraphTypeName:='Barres empil'#130'es';
  3: GraphTypeName:='Lignes';
  4: GraphTypeName:='XY';
  5: GraphTypeName:='Secteurs';
  Else GraphTypeName:='';
 End;
End;

Function ItemValue(Cmd: Integer): String;
Var S: String;
Begin
 S:='';
 Case Cmd Of
  CM_DIR:   Begin
             S:=DataDir;
             If Length(S)>18 Then S:='..'+Copy(S,Length(S)-15,16);
            End;
  CM_SQZE:  S:=OuiNon(SqzEmpty);
  CM_SQZF:  If SqzValue Then S:='Avec valeur r'#130'sultante' Else S:='Sans valeur';
  CM_SQZV:  If SqzVerA Then S:='A - SQZ!' Else S:='B - Normal';
  CM_GTYPE: S:=GraphTypeName(Sh^.Gr.GType);
  CM_GGRID: S:=OuiNon(Sh^.Gr.Grid);
  CM_GS_X..CM_GS_1+5: Begin
             If Sh^.Gr.SerOn[Cmd-CM_GS_X] Then S:=RangeStr(Sh^.Gr.Ser[Cmd-CM_GS_X]);
            End;
  CM_GTT1:  S:=Sh^.Gr.T1;
  CM_GTT2:  S:=Sh^.Gr.T2;
  CM_GTTX:  S:=Sh^.Gr.TX;
  CM_GTTY:  S:=Sh^.Gr.TY;
  CM_PBLOCK: If Sh^.PrintOn Then S:=RangeStr(Sh^.PrintR);
  CM_PDEST: Case PrintDest Of
             1: S:='Imprimante';
             2: S:='Fichier';
             Else S:=#130'cran';
            End;
  CM_PHDR:  S:=Sh^.Hdr;
  CM_PFTR:  S:=Sh^.Ftr;
  CM_PWIDTH: S:=IntStr(PageW);
  CM_PHEIGHT: S:=IntStr(PageH);
  CM_SORT_BLOCK: If Sh^.SortOn Then S:=RangeStr(Sh^.SortR);
  CM_SORT_KEY: S:=ColName(Sh^.SortKey);
  CM_SORT_ORD: If Sh^.SortDesc Then S:='D'#130'croissant' Else S:='Croissant';
  CM_Q_BLOCK: If Sh^.DbOn Then S:=RangeStr(Sh^.DbR);
  CM_Q_CRIT:  If Sh^.CrOn Then S:=RangeStr(Sh^.CrR);
  CM_Q_OUT:   If Sh^.OuOn Then S:=RangeStr(Sh^.OuR);
  CM_CALC_MODE: If AutoCalc Then S:='Automatique' Else S:='Manuel';
  CM_DBAR:  S:=OuiNon(ShowBar);
  CM_DGRID: S:=OuiNon(ShowGrid);
  CM_DCOLW: S:=IntStr(DefColW);
  CM_DDEC:  S:=IntStr(DefDec);
  CM_DCURR: S:=CurrSym;
  CM_DSEP:  If DecSep='.' Then S:='Point' Else S:='Virgule';
 End;
 ItemValue:=S;
End;

Function ItemHelp(Cmd: Integer): String;
Begin
 Case Cmd Of
  CM_NEW:   ItemHelp:='Cr'#130'er une nouvelle feuille de calcul';
  CM_OPEN:  ItemHelp:='Ouvrir un fichier dans une nouvelle fen'#136'tre';
  CM_LOAD:  ItemHelp:='Charger un fichier dans la fen'#136'tre courante';
  CM_SAVE:  ItemHelp:='Sauvegarder la feuille courante';
  CM_SAVEAS: ItemHelp:='Sauvegarder la feuille sous un autre nom';
  CM_SAVEALL: ItemHelp:='Sauvegarder toutes les feuilles ouvertes';
  CM_CLOSE: ItemHelp:='Fermer la fen'#136'tre courante';
  CM_CLOSEALL: ItemHelp:='Fermer toutes les fen'#136'tres';
  CM_ERASE: ItemHelp:='Effacer un fichier du disque';
  CM_DIR:   ItemHelp:='Changer le r'#130'pertoire de donn'#130'es';
  CM_QUIT:  ItemHelp:='Quitter Quattro Pro';
  CM_SQZE:  ItemHelp:='Exclure de la sauvegarde les cellules vides';
  CM_SQZF:  ItemHelp:='Choisir le mode de stockage des formules';
  CM_SQZV:  ItemHelp:='Choisir la version du format SQZ!';
  CM_UNDO:  ItemHelp:='Annuler la derni'#138're modification';
  CM_COPY:  ItemHelp:='Copier un bloc de cellules';
  CM_MOVE:  ItemHelp:='D'#130'placer un bloc de cellules';
  CM_CLEAR: ItemHelp:='Effacer le contenu d''un bloc';
  CM_VALUES: ItemHelp:='Convertir les formules en valeurs';
  CM_TRANSP: ItemHelp:='Copier un bloc en inversant lignes et colonnes';
  CM_FILL:  ItemHelp:='Remplir un bloc avec une suite de valeurs';
  CM_FIND:  ItemHelp:='Rechercher un texte ou une valeur';
  CM_REPL:  ItemHelp:='Remplacer un texte dans un bloc';
  CM_COLW:  ItemHelp:='Modifier la largeur de la colonne';
  CM_FIT:   ItemHelp:='Ajuster la largeur au contenu';
  CM_GTYPE: ItemHelp:='Choisir le type de graphique';
  CM_GVIEW: ItemHelp:='Afficher le graphique courant';
  CM_PBLOCK: ItemHelp:='D'#130'finir le bloc '#133' imprimer';
  CM_PGO:   ItemHelp:='Lancer l''impression';
  CM_SORT_GO: ItemHelp:='Trier le bloc selon la cl'#130' choisie';
  CM_Q_EXTR: ItemHelp:='Extraire les enregistrements qui satisfont aux crit'#138'res';
  CM_RECALC: ItemHelp:='Recalculer toutes les formules';
  CM_STATS: ItemHelp:='Statistiques sur le bloc s'#130'lectionn'#130;
  CM_REGR:  ItemHelp:='R'#130'gression lin'#130'aire simple';
  CM_DBAR:  ItemHelp:='Afficher ou masquer la barre d''outils';
  CM_DGRID: ItemHelp:='Afficher ou masquer le quadrillage';
  CM_DSAVE: ItemHelp:='Sauvegarder les valeurs par d'#130'faut';
  CM_NEXTWIN: ItemHelp:='Passer '#133' la fen'#136'tre suivante';
  Else ItemHelp:='';
 End;
End;

{ ====================================================================== }
{                      AFFICHAGE ET GESTION DES MENUS                    }
{ ====================================================================== }

Type
 TPop = Record
  Mn, Sel, X, Y, W, H, LabW, ShW: Integer;
 End;

Var
 Pop : Array[1..MAX_LV] Of TPop;
 PLv : Integer;

Procedure PopCalc(Var P: TPop);
Var I, J, LW, SW, VW, Tw: Integer; S: String;
Begin
 LW:=0; SW:=0; VW:=0; P.H:=12;
 For I:=1 To MenuDef[P.Mn].Cnt Do Begin
  J:=MenuDef[P.Mn].First+I-1;
  If Itm[J].Sep Then Inc(P.H,8)
  Else Begin
   Inc(P.H,14);
   Tw:=Length(StripAmp(Itm[J].Cap))*8; If Tw>LW Then LW:=Tw;
   Tw:=Length(Itm[J].Sc)*8; If Tw>SW Then SW:=Tw;
   S:=ItemValue(Itm[J].Cmd);
   Tw:=Length(S)*8; If Tw>VW Then VW:=Tw;
  End;
 End;
 P.LabW:=LW; P.ShW:=SW;
 P.W:=8+LW+16;
 If VW>0 Then P.W:=P.W+VW+8;
 If SW>0 Then P.W:=P.W+SW+16;
 P.W:=P.W+24;
End;

Function PopItemY(Var P: TPop; Idx: Integer): Integer;
Var I, Y: Integer;
Begin
 Y:=P.Y+6;
 For I:=1 To Idx-1 Do
  If Itm[MenuDef[P.Mn].First+I-1].Sep Then Inc(Y,8) Else Inc(Y,14);
 PopItemY:=Y;
End;

{ Retourne -1 si hors du menu, 0 si sur un separateur/marge, sinon l'index. }
Function PopHit(Var P: TPop; MX, MY: LongInt): Integer;
Var I, Y, H: Integer;
Begin
 PopHit:=-1;
 If (MX<P.X) Or (MX>P.X+P.W) Or (MY<P.Y) Or (MY>P.Y+P.H) Then Exit;
 PopHit:=0;
 For I:=1 To MenuDef[P.Mn].Cnt Do Begin
  Y:=PopItemY(P,I);
  If Itm[MenuDef[P.Mn].First+I-1].Sep Then H:=8 Else H:=14;
  If (MY>=Y) And (MY<Y+H) And Not Itm[MenuDef[P.Mn].First+I-1].Sep Then Begin
   PopHit:=I; Exit;
  End;
 End;
End;

Procedure PopDraw(Var P: TPop);
Var I, J, Y, Vx: Integer; S: String;
Begin
 FillBox(P.X+4,P.Y+4,P.X+P.W+4,P.Y+P.H+4,CL_DGRAY);
 FillBox(P.X,P.Y,P.X+P.W,P.Y+P.H,CL_LGRAY);
 SetColor(CL_BLACK);
 Rectangle(P.X,P.Y,P.X+P.W,P.Y+P.H);
 Raised(P.X+1,P.Y+1,P.X+P.W-1,P.Y+P.H-1);
 For I:=1 To MenuDef[P.Mn].Cnt Do Begin
  J:=MenuDef[P.Mn].First+I-1;
  Y:=PopItemY(P,I);
  If Itm[J].Sep Then Begin
   HLine(P.X+6,P.X+P.W-6,Y+3,CL_DGRAY);
   HLine(P.X+6,P.X+P.W-6,Y+4,CL_WHITE);
  End Else Begin
   If I=P.Sel Then Begin
    FillBox(P.X+6,Y,P.X+10+P.LabW,Y+13,CL_RED);
    DrawHK(P.X+8,Y+3,Itm[J].Cap,CL_WHITE,CL_YELLOW);
   End Else DrawHK(P.X+8,Y+3,Itm[J].Cap,CL_BLACK,CL_RED);
   Vx:=P.X+P.W-24;
   If P.ShW>0 Then Begin
    TextAt(Vx-Length(Itm[J].Sc)*8,Y+3,Itm[J].Sc,CL_BLACK);
    Vx:=Vx-P.ShW-16;
   End;
   S:=ItemValue(Itm[J].Cmd);
   If S<>'' Then TextAt(Vx-Length(S)*8,Y+3,S,CL_BLUE);
   If Itm[J].Sub>0 Then TextAt(P.X+P.W-18,Y+3,#16,CL_BLACK);
  End;
 End;
End;

Function FirstSel(Mn: Integer): Integer;
Var I: Integer;
Begin
 FirstSel:=1;
 For I:=MenuDef[Mn].Cnt DownTo 1 Do
  If Not Itm[MenuDef[Mn].First+I-1].Sep Then FirstSel:=I;
End;

Procedure PushPop(Mn, X, Y: Integer);
Begin
 If PLv>=MAX_LV Then Exit;
 Inc(PLv);
 Pop[PLv].Mn:=Mn;
 Pop[PLv].Sel:=FirstSel(Mn);
 PopCalc(Pop[PLv]);
 If X+Pop[PLv].W>SCR_W-6 Then X:=SCR_W-6-Pop[PLv].W;
 If Y+Pop[PLv].H>SCR_H-6 Then Y:=SCR_H-6-Pop[PLv].H;
 If X<0 Then X:=0;
 If Y<0 Then Y:=0;
 Pop[PLv].X:=X; Pop[PLv].Y:=Y;
End;

Function TopMenuAt(MX, MY: LongInt): Integer;
Var I, X: Integer;
Begin
 TopMenuAt:=0;
 If (MY<0) Or (MY>15) Then Exit;
 For I:=1 To 9 Do Begin
  X:=TopMenuX(I);
  If (MX>=X-4) And (MX<=X+Length(StripAmp(TopMenuCap(I)))*8+3) Then Begin
   TopMenuAt:=I; Exit;
  End;
 End;
End;

Function AltToMenu(K: Word): Integer;
Begin
 Case K Of
  KEY_ALT_F: AltToMenu:=1;
  KEY_ALT_E: AltToMenu:=2;
  KEY_ALT_S: AltToMenu:=3;
  KEY_ALT_G: AltToMenu:=4;
  KEY_ALT_I: AltToMenu:=5;
  KEY_ALT_B: AltToMenu:=6;
  KEY_ALT_O: AltToMenu:=7;
  KEY_ALT_D: AltToMenu:=8;
  KEY_ALT_N: AltToMenu:=9;
  Else AltToMenu:=0;
 End;
End;

{ Execute un menu : Top = menu de la barre (1..9) ou 0 pour un menu volant
  (Root, RX, RY).  Retourne la commande choisie, ou 0. }
Function RunMenu(Top, Root, RX, RY: Integer): Integer;
Var Done, Redo: Boolean; Res, I, L, J, M: Integer; K: Word; Ev: Integer;
    OldMode: String[8]; Ch: Char;

 Procedure OpenTop(T: Integer);
 Begin
  MenuTop:=T; PLv:=0;
  If T=M_WIN Then RefreshWinMenu;
  PushPop(T,TopMenuX(T)-4,16);
 End;

 Procedure Activate;
 Var Jx: Integer;
 Begin
  Jx:=MenuDef[Pop[PLv].Mn].First+Pop[PLv].Sel-1;
  If Itm[Jx].Sub>0 Then
   PushPop(Itm[Jx].Sub,Pop[PLv].X+20,PopItemY(Pop[PLv],Pop[PLv].Sel)+11)
  Else Begin Res:=Itm[Jx].Cmd; Done:=True; End;
 End;

 Procedure StepSel(D: Integer);
 Var N, T: Integer;
 Begin
  N:=MenuDef[Pop[PLv].Mn].Cnt;
  T:=Pop[PLv].Sel;
  Repeat
   T:=T+D;
   If T<1 Then T:=N;
   If T>N Then T:=1;
  Until Not Itm[MenuDef[Pop[PLv].Mn].First+T-1].Sep;
  Pop[PLv].Sel:=T;
 End;

Begin
 Done:=False; Res:=0; PLv:=0; Redo:=True;
 OldMode:=ModeStr; ModeStr:='MENU';
 If Top>0 Then OpenTop(Top) Else Begin MenuTop:=0; PushPop(Root,RX,RY); End;
 Repeat
  If Redo Then Begin
   J:=MenuDef[Pop[PLv].Mn].First+Pop[PLv].Sel-1;
   StatHelp:=ItemHelp(Itm[J].Cmd);
   BeginFrame;
   For I:=1 To PLv Do PopDraw(Pop[I]);
   EndFrame;
   Redo:=False;
  End;
  Ev:=GetEvent(K);
  If Ev=1 Then Begin
   Redo:=True;
   Case K Of
    KEY_ESC:   If PLv>1 Then Dec(PLv) Else Done:=True;
    KEY_UP:    StepSel(-1);
    KEY_DOWN:  StepSel(1);
    KEY_HOME:  Pop[PLv].Sel:=FirstSel(Pop[PLv].Mn);
    KEY_END:   Begin Pop[PLv].Sel:=MenuDef[Pop[PLv].Mn].Cnt; If Itm[MenuDef[Pop[PLv].Mn].First+Pop[PLv].Sel-1].Sep Then StepSel(-1); End;
    KEY_ENTER: Activate;
    KEY_RIGHT: Begin
                J:=MenuDef[Pop[PLv].Mn].First+Pop[PLv].Sel-1;
                If Itm[J].Sub>0 Then Activate
                Else If (Top>0) And (MenuTop>0) Then OpenTop(MenuTop Mod 9+1);
               End;
    KEY_LEFT:  Begin
                If PLv>1 Then Dec(PLv)
                Else If (Top>0) And (MenuTop>0) Then Begin
                 M:=MenuTop-1; If M<1 Then M:=9;
                 OpenTop(M);
                End;
               End;
    Else Begin
     M:=AltToMenu(K);
     If (M>0) And (Top>0) Then OpenTop(M)
     Else If (K>=32) And (K<=255) Then Begin
      Ch:=UpCase(Chr(K));
      L:=0;
      For I:=1 To MenuDef[Pop[PLv].Mn].Cnt Do Begin
       J:=MenuDef[Pop[PLv].Mn].First+I-1;
       If (Itm[J].HK=Ch) And (Not Itm[J].Sep) And (L=0) Then L:=I;
      End;
      If L>0 Then Begin Pop[PLv].Sel:=L; Activate; End;
     End;
    End;
   End;
  End Else Begin
   I:=PopHit(Pop[PLv],MsX,MsY);
   If (I>0) And (I<>Pop[PLv].Sel) And (Not EdgeDown) Then Begin Pop[PLv].Sel:=I; Redo:=True; End;
   If EdgeDown Then Begin
    Redo:=True;
    L:=0;
    For I:=PLv DownTo 1 Do
     If (L=0) And (PopHit(Pop[I],MsX,MsY)>=0) Then L:=I;
    If L>0 Then Begin
     PLv:=L;
     I:=PopHit(Pop[L],MsX,MsY);
     If I>0 Then Begin Pop[L].Sel:=I; Activate; End;
    End Else Begin
     M:=TopMenuAt(MsX,MsY);
     If (M>0) And (Top>0) And (M<>MenuTop) Then OpenTop(M)
      Else Done:=True;
    End;
   End;
   If Not Redo Then MoveSoftCursor;
  End;
 Until Done;
 MenuTop:=0; StatHelp:=''; ModeStr:=OldMode; PLv:=0;
 RunMenu:=Res;
End;

{ ====================================================================== }
{                           NAVIGATION                                   }
{ ====================================================================== }

Function NextCol(C, D: Integer): Integer;
Var N: Integer;
Begin
 N:=C+D;
 While (N>=0) And (N<MAX_COLS) And (Sh^.ColW[N]=0) Do N:=N+D;
 If (N<0) Or (N>=MAX_COLS) Then N:=C;
 NextCol:=N;
End;

Procedure SetCur(R, C: Integer);
Begin
 If R<0 Then R:=0;
 If R>=MAX_ROWS Then R:=MAX_ROWS-1;
 If C<0 Then C:=0;
 If C>=MAX_COLS Then C:=MAX_COLS-1;
 If Sh^.ColW[C]=0 Then Begin
  If NextCol(C,1)<>C Then C:=NextCol(C,1) Else C:=NextCol(C,-1);
 End;
 Sh^.CurR:=R; Sh^.CurC:=C;
 EnsureCursorVisible;
End;

Procedure JumpEnd(Dr, Dc: Integer);
Var R, C, NR, NC: Integer;

 Function Inside(Rr, Cc: Integer): Boolean;
 Begin
  Inside:=(Rr>=0) And (Rr<MAX_ROWS) And (Cc>=0) And (Cc<MAX_COLS);
 End;

Begin
 R:=Sh^.CurR; C:=Sh^.CurC;
 NR:=R+Dr; NC:=C+Dc;
 If Not Inside(NR,NC) Then Exit;
 If (Not CellIsBlank(R,C)) And (Not CellIsBlank(NR,NC)) Then Begin
  While Inside(R+Dr,C+Dc) And (Not CellIsBlank(R+Dr,C+Dc)) Do Begin
   R:=R+Dr; C:=C+Dc;
  End;
 End Else Begin
  R:=NR; C:=NC;
  While Inside(R,C) And CellIsBlank(R,C) Do Begin R:=R+Dr; C:=C+Dc; End;
  If Not Inside(R,C) Then Begin
   R:=R-Dr; C:=C-Dc;
  End;
 End;
 SetCur(R,C);
End;

Procedure MoveCurNav(K: Word);
Var N, Ur, Uc: Integer;
Begin
 CalcVisible;
 Case K Of
  KEY_UP:    If EndMode Then JumpEnd(-1,0) Else SetCur(Sh^.CurR-1,Sh^.CurC);
  KEY_DOWN:  If EndMode Then JumpEnd(1,0) Else SetCur(Sh^.CurR+1,Sh^.CurC);
  KEY_LEFT:  If EndMode Then JumpEnd(0,-1) Else SetCur(Sh^.CurR,NextCol(Sh^.CurC,-1));
  KEY_RIGHT: If EndMode Then JumpEnd(0,1) Else SetCur(Sh^.CurR,NextCol(Sh^.CurC,1));
  KEY_PGUP:  Begin
              N:=NVR-Sh^.LockR; If N<1 Then N:=1;
              Sh^.TopR:=Sh^.TopR-N; If Sh^.TopR<Sh^.LockR Then Sh^.TopR:=Sh^.LockR;
              SetCur(Sh^.CurR-N,Sh^.CurC);
             End;
  KEY_PGDN:  Begin
              N:=NVR-Sh^.LockR; If N<1 Then N:=1;
              If Sh^.TopR+N<MAX_ROWS-N Then Sh^.TopR:=Sh^.TopR+N;
              SetCur(Sh^.CurR+N,Sh^.CurC);
             End;
  KEY_TAB,KEY_CRIGHT: Begin
              N:=NVC-Sh^.LockC; If N<1 Then N:=1;
              If Sh^.LeftC+N<MAX_COLS-N Then Sh^.LeftC:=Sh^.LeftC+N;
              SetCur(Sh^.CurR,Sh^.CurC+N);
             End;
  KEY_SHTAB,KEY_CLEFT: Begin
              N:=NVC-Sh^.LockC; If N<1 Then N:=1;
              Sh^.LeftC:=Sh^.LeftC-N; If Sh^.LeftC<Sh^.LockC Then Sh^.LeftC:=Sh^.LockC;
              SetCur(Sh^.CurR,Sh^.CurC-N);
             End;
  KEY_HOME:  Begin
              If EndMode Then Begin
               Ur:=UsedRows(Sh); Uc:=UsedCols(Sh);
               If Ur<0 Then Ur:=0; If Uc<0 Then Uc:=0;
               SetCur(Ur,Uc);
              End Else Begin
               Sh^.TopR:=Sh^.LockR; Sh^.LeftC:=Sh^.LockC;
               SetCur(Sh^.LockR,Sh^.LockC);
              End;
             End;
  KEY_CHOME: Begin Sh^.TopR:=0; Sh^.LeftC:=0; SetCur(0,0); End;
  KEY_CEND:  Begin
              Ur:=UsedRows(Sh); Uc:=UsedCols(Sh);
              If Ur<0 Then Ur:=0; If Uc<0 Then Uc:=0;
              SetCur(Ur,Uc);
             End;
 End;
 EndMode:=False;
End;

{ ====================================================================== }
{                         GESTION DES FENETRES                           }
{ ====================================================================== }

Function UniqueName: String;
Var N, I: Integer; Used: Boolean; S: String;
Begin
 N:=1;
 Repeat
  S:='FEUIL'+IntStr(N)+'.WQ1';
  Used:=False;
  For I:=1 To NWin Do If UpStr(BaseName(Win[I]^.Name))=S Then Used:=True;
  If Used Then Inc(N);
 Until Not Used;
 UniqueName:=S;
End;

Procedure ResetEdit;
Begin
 Editing:=False; EndMode:=False; ModeStr:='PRET';
End;

Function NewWindow: Boolean;
Var Nm: String;
Begin
 NewWindow:=False;
 If NWin>=MAX_WIN Then Begin
  MsgBox('Nombre maximal de fen'#136'tres atteint ('+IntStr(MAX_WIN)+')');
  Exit;
 End;
 Nm:=UniqueName;
 Inc(NWin);
 Win[NWin]:=NewSheet(Nm);
 CurWin:=NWin; Sh:=Win[NWin];
 ResetEdit;
 NewWindow:=True;
End;

Procedure SwitchWin(I: Integer);
Begin
 If (I<1) Or (I>NWin) Then Exit;
 CurWin:=I; Sh:=Win[I];
 ResetEdit;
 If AutoCalc Then RecalcAll;
End;

Procedure CloseWin(I: Integer);
Var J: Integer;
Begin
 FreeSheet(Win[I]);
 For J:=I To NWin-1 Do Win[J]:=Win[J+1];
 Dec(NWin);
 If NWin=0 Then Begin
  NWin:=1;
  Win[1]:=NewSheet('FEUIL1.WQ1');
  CurWin:=1;
 End Else If CurWin>NWin Then CurWin:=NWin
 Else If (CurWin>I) Then Dec(CurWin);
 Sh:=Win[CurWin];
 ResetEdit;
 If AutoCalc Then RecalcAll;
End;

{ ====================================================================== }
{                          FICHIERS (WQ1 / CSV)                          }
{ ====================================================================== }

Const
 {$IFDEF FPC}
 PSEP = DirectorySeparator;
 {$ELSE}
 PSEP = '\';
 {$ENDIF}

Function FullPath(Const N: String): String;
Begin
 If (Pos('\',N)>0) Or (Pos('/',N)>0) Or (Pos(':',N)>0) Then FullPath:=N
  Else FullPath:=DataDir+N;
End;

Function FileThere(Const Fn: String): Boolean;
Var F: File; Old: Byte;
Begin
 Assign(F,Fn);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult=0 Then Begin Close(F); FileThere:=True; End
  Else FileThere:=False;
End;

Procedure ResetSheetData(S: PSheet);
Var I: Integer;
Begin
 FreeRowTab(S^.Rows);
 GetMem(S^.Rows,SizeOf(TRowTab));
 FillChar(S^.Rows^,SizeOf(TRowTab),0);
 For I:=0 To MAX_COLS-1 Do Begin S^.ColW[I]:=DefColW; S^.ColSty[I].Used:=0; End;
 S^.NameCnt:=0;
 S^.CurR:=0; S^.CurC:=0; S^.TopR:=0; S^.LeftC:=0; S^.SelOn:=False; S^.SelMode:=0;
 S^.LockR:=0; S^.LockC:=0;
 S^.Modified:=False;
End;

Function NextTok(Var L: String): String;
Var P: Integer;
Begin
 While (L<>'') And (L[1]=' ') Do Delete(L,1,1);
 P:=Pos(' ',L);
 If P=0 Then Begin NextTok:=L; L:=''; End
  Else Begin NextTok:=Copy(L,1,P-1); Delete(L,1,P); End;
End;

Function TokInt(Var L: String): LongInt;
Var S: String; V: LongInt; Code: Integer;
Begin
 S:=NextTok(L);
 Val(S,V,Code);
 If Code<>0 Then V:=0;
 TokInt:=V;
End;

Function SaveNative(Const Fn: String): Boolean;
Var F: Text; R, C, I: Integer; P: PCell; S: String; Skip: Boolean;
Begin
 SaveNative:=False;
 Assign(F,Fn);
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Exit;
 WriteLn(F,'QPCLONE 1');
 For C:=0 To MAX_COLS-1 Do Begin
  If Sh^.ColW[C]<>DefColW Then WriteLn(F,'W ',C,' ',Sh^.ColW[C]);
  If Sh^.ColSty[C].Used<>0 Then
   WriteLn(F,'S ',C,' ',Sh^.ColSty[C].Fmt,' ',Sh^.ColSty[C].Dec,' ',Sh^.ColSty[C].Al,' ',
           Sh^.ColSty[C].Fnt,' ',Sh^.ColSty[C].Prot);
 End;
 For I:=1 To Sh^.NameCnt Do
  WriteLn(F,'N ',Sh^.Names[I].Nm,' ',Sh^.Names[I].R.R1,' ',Sh^.Names[I].R.C1,' ',
          Sh^.Names[I].R.R2,' ',Sh^.Names[I].R.C2);
 WriteLn(F,'L ',Sh^.LockR,' ',Sh^.LockC);
 WriteLn(F,'GT ',Sh^.Gr.GType,' ',Ord(Sh^.Gr.Grid));
 For I:=0 To 6 Do
  If Sh^.Gr.SerOn[I] Then
   WriteLn(F,'GS ',I,' ',Sh^.Gr.Ser[I].R1,' ',Sh^.Gr.Ser[I].C1,' ',Sh^.Gr.Ser[I].R2,' ',Sh^.Gr.Ser[I].C2);
 WriteLn(F,'G1 ',Sh^.Gr.T1);
 WriteLn(F,'G2 ',Sh^.Gr.T2);
 WriteLn(F,'GX ',Sh^.Gr.TX);
 WriteLn(F,'GY ',Sh^.Gr.TY);
 If Sh^.PrintOn Then
  WriteLn(F,'PB ',Sh^.PrintR.R1,' ',Sh^.PrintR.C1,' ',Sh^.PrintR.R2,' ',Sh^.PrintR.C2);
 WriteLn(F,'PH ',Sh^.Hdr);
 WriteLn(F,'PF ',Sh^.Ftr);
 For R:=0 To MAX_ROWS-1 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=0 To MAX_COLS-1 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If P<>Nil Then Begin
     Skip:=False;
     If P^.Kind=CK_EMPTY Then Begin
      If SqzEmpty Then Skip:=True
      Else If (P^.Fmt=DefFmt) And (P^.Dec=DefDec) And (P^.Al=0) And (P^.Fnt=0) And (P^.Prot=0) Then Skip:=True;
     End;
     If Not Skip Then Begin
      Case P^.Kind Of
       CK_NUM: Begin Str(P^.Num:25,S); S:=TrimStr(S); End;
       CK_LABEL,CK_FORMULA: S:=GetStr(P^.Txt);
       Else S:='';
      End;
      WriteLn(F,'C ',R,' ',C,' ',P^.Kind,' ',P^.Fmt,' ',P^.Dec,' ',P^.Al,' ',P^.Fnt,' ',P^.Prot,' ',S);
     End;
    End;
   End;
 Close(F);
 SaveNative:=IOResult=0;
End;

Function CsvField(Const S: String; Delim: Char): String;
Begin
 If (Pos(Delim,S)>0) Or (Pos('"',S)>0) Then Begin
  CsvField:='"'+S+'"';
 End Else CsvField:=S;
End;

Function SaveCsv(Const Fn: String): Boolean;
Var F: Text; R, C, Mr, Mc: Integer; P: PCell; S, L: String; Delim: Char; Al: Byte;
Begin
 SaveCsv:=False;
 Assign(F,Fn);
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Exit;
 If DecSep=',' Then Delim:=';' Else Delim:=',';
 Mr:=UsedRows(Sh); Mc:=UsedCols(Sh);
 For R:=0 To Mr Do Begin
  L:='';
  For C:=0 To Mc Do Begin
   P:=FindCell(Sh,R,C);
   S:='';
   If P<>Nil Then Begin
    Case P^.Kind Of
     CK_LABEL: S:=GetStr(P^.Txt);
     CK_NUM:   S:=NumToStrPlain(P^.Num);
     CK_FORMULA: Begin
       Case P^.ResK Of
        0: S:=NumToStrPlain(P^.Num);
        1: S:=GetStr(P^.Res);
        Else S:='ERR';
       End;
      End;
    End;
   End;
   If C>0 Then L:=L+Delim;
   L:=L+CsvField(S,Delim);
  End;
  WriteLn(F,L);
 End;
 Close(F);
 SaveCsv:=IOResult=0;
End;

Function SaveFile(Const Fn: String): Boolean;
Var E: String;
Begin
 E:=ExtOf(Fn);
 If (E='.CSV') Or (E='.TXT') Then SaveFile:=SaveCsv(Fn) Else SaveFile:=SaveNative(Fn);
End;

Function LoadNative(Const Fn: String): Boolean;
Var F: Text; L, T, Rest: String; Cmd: String; R, C, I, K, Fm, Dc, Al, Fn2, Pr: LongInt;
    X: Double; Code: Integer; P: PCell; G: TRange;
Begin
 LoadNative:=False;
 Assign(F,Fn);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 ReadLn(F,L);
 If Copy(L,1,8)<>'QPCLONE ' Then Begin Close(F); Exit; End;
 ResetSheetData(Sh);
 While Not Eof(F) Do Begin
  ReadLn(F,L);
  Cmd:=NextTok(L);
  If Cmd='W' Then Begin
   C:=TokInt(L); K:=TokInt(L);
   If (C>=0) And (C<MAX_COLS) And (K>=0) And (K<=80) Then Sh^.ColW[C]:=K;
  End Else If Cmd='S' Then Begin
   C:=TokInt(L);
   If (C>=0) And (C<MAX_COLS) Then Begin
    Sh^.ColSty[C].Used:=1;
    Sh^.ColSty[C].Fmt:=TokInt(L); Sh^.ColSty[C].Dec:=TokInt(L);
    Sh^.ColSty[C].Al:=TokInt(L); Sh^.ColSty[C].Fnt:=TokInt(L);
    Sh^.ColSty[C].Prot:=TokInt(L);
   End;
  End Else If Cmd='N' Then Begin
   If Sh^.NameCnt<MAX_NAMES Then Begin
    Inc(Sh^.NameCnt);
    Sh^.Names[Sh^.NameCnt].Nm:=NextTok(L);
    Sh^.Names[Sh^.NameCnt].R.R1:=TokInt(L); Sh^.Names[Sh^.NameCnt].R.C1:=TokInt(L);
    Sh^.Names[Sh^.NameCnt].R.R2:=TokInt(L); Sh^.Names[Sh^.NameCnt].R.C2:=TokInt(L);
   End;
  End Else If Cmd='L' Then Begin
   Sh^.LockR:=TokInt(L); Sh^.LockC:=TokInt(L);
  End Else If Cmd='GT' Then Begin
   Sh^.Gr.GType:=TokInt(L); Sh^.Gr.Grid:=TokInt(L)<>0;
  End Else If Cmd='GS' Then Begin
   I:=TokInt(L);
   If (I>=0) And (I<=6) Then Begin
    Sh^.Gr.SerOn[I]:=True;
    Sh^.Gr.Ser[I].R1:=TokInt(L); Sh^.Gr.Ser[I].C1:=TokInt(L);
    Sh^.Gr.Ser[I].R2:=TokInt(L); Sh^.Gr.Ser[I].C2:=TokInt(L);
   End;
  End Else If Cmd='G1' Then Sh^.Gr.T1:=L
  Else If Cmd='G2' Then Sh^.Gr.T2:=L
  Else If Cmd='GX' Then Sh^.Gr.TX:=L
  Else If Cmd='GY' Then Sh^.Gr.TY:=L
  Else If Cmd='PB' Then Begin
   Sh^.PrintOn:=True;
   Sh^.PrintR.R1:=TokInt(L); Sh^.PrintR.C1:=TokInt(L);
   Sh^.PrintR.R2:=TokInt(L); Sh^.PrintR.C2:=TokInt(L);
  End Else If Cmd='PH' Then Sh^.Hdr:=L
  Else If Cmd='PF' Then Sh^.Ftr:=L
  Else If Cmd='C' Then Begin
   R:=TokInt(L); C:=TokInt(L); K:=TokInt(L);
   Fm:=TokInt(L); Dc:=TokInt(L); Al:=TokInt(L); Fn2:=TokInt(L); Pr:=TokInt(L);
   P:=MakeCell(Sh,R,C);
   If P<>Nil Then Begin
    P^.Fmt:=Fm; P^.Dec:=Dc; P^.Al:=Al; P^.Fnt:=Fn2; P^.Prot:=Pr;
    Case K Of
     CK_NUM: Begin
              Val(TrimStr(L),X,Code);
              If Code=0 Then Begin P^.Kind:=CK_NUM; P^.Num:=X; End;
             End;
     CK_LABEL: Begin P^.Kind:=CK_LABEL; SetStr(P^.Txt,L); End;
     CK_FORMULA: Begin P^.Kind:=CK_FORMULA; SetStr(P^.Txt,L); P^.Calc:=0; End;
    End;
   End;
  End;
 End;
 Close(F);
 LoadNative:=True;
End;

Function SplitCsvLine(Const L: String; Delim: Char; Var Fld: Array Of String): Integer;
Var I, N: Integer; S: String; InQ: Boolean; Ch: Char;
Begin
 N:=0; S:=''; InQ:=False;
 For I:=1 To Length(L) Do Begin
  Ch:=L[I];
  If Ch='"' Then InQ:=Not InQ
  Else If (Ch=Delim) And Not InQ Then Begin
   If N<=High(Fld) Then Begin Fld[N]:=S; Inc(N); End;
   S:='';
  End Else S:=S+Ch;
 End;
 If N<=High(Fld) Then Begin Fld[N]:=S; Inc(N); End;
 SplitCsvLine:=N;
End;

Function LoadCsv(Const Fn: String): Boolean;
Var F: Text; L: String; Fld: Array[0..63] Of String; N, I, R, C1, C2: Integer; Delim: Char;
    X: Double; P: PCell;
Begin
 LoadCsv:=False;
 Assign(F,Fn);
 {$I-}
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 ResetSheetData(Sh);
 R:=0;
 While (Not Eof(F)) And (R<MAX_ROWS) Do Begin
  ReadLn(F,L);
  C1:=0; C2:=0;
  For I:=1 To Length(L) Do Begin
   If L[I]=',' Then Inc(C1);
   If L[I]=';' Then Inc(C2);
  End;
  If C2>C1 Then Delim:=';' Else Delim:=',';
  N:=SplitCsvLine(L,Delim,Fld);
  For I:=0 To N-1 Do
   If Fld[I]<>'' Then Begin
    P:=MakeCell(Sh,R,I);
    If P<>Nil Then Begin
     If TryNumber(Fld[I],X) Then SetNumber(P,X) Else SetLabel(P,Fld[I],AL_DEF);
    End;
   End;
  Inc(R);
 End;
 Close(F);
 LoadCsv:=True;
End;

Function LoadFile(Const Fn: String): Boolean;
Var E: String;
Begin
 E:=ExtOf(Fn);
 If (E='.CSV') Or (E='.TXT') Then LoadFile:=LoadCsv(Fn) Else LoadFile:=LoadNative(Fn);
 If AutoCalc Then RecalcAll;
End;

{ ---------- Boite de selection de fichier ---------- }

Function ParentDir(Const D: String): String;
Var S: String; I: Integer;
Begin
 S:=D;
 If (Length(S)>1) And ((S[Length(S)]='\') Or (S[Length(S)]='/')) Then Delete(S,Length(S),1);
 I:=Length(S);
 While (I>0) And (S[I]<>'\') And (S[I]<>'/') Do Dec(I);
 If I<=1 Then ParentDir:=Copy(S,1,I) Else ParentDir:=Copy(S,1,I);
 If (I=0) Then ParentDir:=D;
End;

Procedure ScanDir(Const Dir: String);
Var SR: SearchRec; S: String; I, J: Integer; Tmp: String;
Begin
 LstClear;
 If ParentDir(Dir)<>Dir Then LstAdd('<..');
 {$IFDEF FPC}
 FindFirst(Dir+'*',AnyFile,SR);
 {$ELSE}
 FindFirst(Dir+'*.*',AnyFile,SR);
 {$ENDIF}
 While DosError=0 Do Begin
  If (SR.Name<>'.') And (SR.Name<>'..') Then Begin
   If (SR.Attr And Directory)<>0 Then LstAdd('<'+SR.Name) Else LstAdd(SR.Name);
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
 For I:=2 To LstN Do Begin
  Tmp:=GetStr(Lst^[I]);
  J:=I-1;
  While (J>=1) And (UpStr(GetStr(Lst^[J]))>UpStr(Tmp)) Do Begin
   SetStr(Lst^[J+1],GetStr(Lst^[J]));
   Dec(J);
  End;
  SetStr(Lst^[J+1],Tmp);
 End;
End;

Function FileDialog(Const Title: String; Var Res: String): Boolean;
Var Dir, Typed, S: String; Sel, Top, Rows, I, X1, Y1, X2, Y2, Ev, P: Integer; K: Word;
    Done, Ok: Boolean;
Begin
 Dir:=DataDir; Typed:=''; P:=1;
 ScanDir(Dir); Sel:=1; Top:=1; Rows:=13; Done:=False; Ok:=False;
 X1:=60; Y1:=40; X2:=SCR_W-61; Y2:=Y1+Rows*14+84;
 Repeat
  BeginFrame;
  DrawDialog(X1,Y1,X2,Y2,Title);
  TextAt(X1+14,Y1+26,Copy(Dir,1,62),CL_BLACK);
  FillBox(X1+10,Y1+40,X2-10,Y1+40+Rows*14+2,CL_WHITE);
  Sunken(X1+10,Y1+40,X2-10,Y1+40+Rows*14+2);
  For I:=0 To Rows-1 Do
   If Top+I<=LstN Then Begin
    S:=GetStr(Lst^[Top+I]);
    If (S<>'') And (S[1]='<') Then S:='['+Copy(S,2,60)+']';
    If Top+I=Sel Then Begin
     FillBox(X1+12,Y1+42+I*14,X2-12,Y1+42+I*14+13,CL_RED);
     TextAt(X1+16,Y1+45+I*14,S,CL_WHITE);
    End Else TextAt(X1+16,Y1+45+I*14,S,CL_BLACK);
   End;
  TextAt(X1+14,Y2-34,'Nom :',CL_BLACK);
  FillBox(X1+60,Y2-38,X2-14,Y2-22,CL_WHITE);
  Sunken(X1+60,Y2-38,X2-14,Y2-22);
  TextAt(X1+64,Y2-34,Typed,CL_BLACK);
  HLine(X1+64+(P-1)*8,X1+64+(P-1)*8+7,Y2-26,CL_BLACK);
  TextAt(X1+14,Y2-16,'Entr'#130'e : choisir   Echap : annuler',CL_BLACK);
  EndFrame;
  Ev:=GetEvent(K);
  If Ev=1 Then Begin
   Case K Of
    KEY_ESC: Done:=True;
    KEY_UP: If Sel>1 Then Dec(Sel);
    KEY_DOWN: If Sel<LstN Then Inc(Sel);
    KEY_PGUP: Begin Sel:=Sel-Rows; If Sel<1 Then Sel:=1; End;
    KEY_PGDN: Begin Sel:=Sel+Rows; If Sel>LstN Then Sel:=LstN; End;
    KEY_ENTER: Begin
     If Typed<>'' Then Begin
      Res:=FullPath(Typed);
      If Dir<>DataDir Then If (Pos('\',Typed)=0) And (Pos('/',Typed)=0) Then Res:=Dir+Typed;
      Ok:=True; Done:=True;
     End Else If (Sel>=1) And (Sel<=LstN) Then Begin
      S:=GetStr(Lst^[Sel]);
      If (S<>'') And (S[1]='<') Then Begin
       If S='<..' Then Dir:=ParentDir(Dir)
        Else Dir:=Dir+Copy(S,2,255)+PSEP;
       ScanDir(Dir); Sel:=1; Top:=1;
      End Else Begin Res:=Dir+S; Ok:=True; Done:=True; End;
     End;
    End;
    Else If EditKey(Typed,P,K,40) Then Begin End;
   End;
   If Sel<Top Then Top:=Sel;
   If Sel>Top+Rows-1 Then Top:=Sel-Rows+1;
   If Top<1 Then Top:=1;
  End Else If EdgeDown Then Begin
   If (MsX>=X1+12) And (MsX<=X2-12) And (MsY>=Y1+42) And (MsY<Y1+42+Rows*14) Then Begin
    I:=Top+(MsY-(Y1+42)) Div 14;
    If (I>=1) And (I<=LstN) Then Begin
     If I=Sel Then Begin
      S:=GetStr(Lst^[Sel]);
      If (S<>'') And (S[1]='<') Then Begin
       If S='<..' Then Dir:=ParentDir(Dir) Else Dir:=Dir+Copy(S,2,255)+PSEP;
       ScanDir(Dir); Sel:=1; Top:=1;
      End Else Begin Res:=Dir+S; Ok:=True; Done:=True; End;
     End Else Sel:=I;
    End;
   End Else If (MsX<X1) Or (MsX>X2) Or (MsY<Y1) Or (MsY>Y2) Then Done:=True;
  End;
 Until Done;
 LstClear;
 FileDialog:=Ok;
End;

{ Demande un nom de fichier (saisie directe ou liste). }
Function AskFileName(Const Title: String; Var Fn: String): Boolean;
Var S: String;
Begin
 S:=BaseName(Fn);
 If Not PromptStr(Title+' (F2=liste)',S,60) Then Begin AskFileName:=False; Exit; End;
 If S='' Then Begin
  AskFileName:=FileDialog(Title,Fn);
  Exit;
 End;
 If ExtOf(S)='' Then S:=S+'.WQ1';
 Fn:=FullPath(S);
 AskFileName:=True;
End;

Function SaveSheet(ForceAs: Boolean): Boolean;
Var Fn: String;
Begin
 SaveSheet:=False;
 Fn:=Sh^.Name;
 If ForceAs Or (Not Sh^.Titled) Then Begin
  If Not PromptStr('Sauvegarder sous :',Fn,60) Then Exit;
  If Fn='' Then Exit;
  If ExtOf(Fn)='' Then Fn:=Fn+'.WQ1';
  Fn:=FullPath(Fn);
  If FileThere(Fn) And (UpStr(Fn)<>UpStr(Sh^.Name)) Then
   If Not AskYesNo('Le fichier existe d'#130'j'#133'.|Le remplacer ?') Then Exit;
 End Else Fn:=FullPath(Fn);
 If SaveFile(Fn) Then Begin
  Sh^.Name:=Fn; Sh^.Titled:=True; Sh^.Modified:=False;
  SaveSheet:=True;
 End Else MsgBox('Erreur d'''#130'criture du fichier|'+Fn);
End;

Procedure OpenFileCmd(InNew: Boolean);
Var Fn: String;
Begin
 Fn:=DataDir+'*.WQ1';
 If Not FileDialog('Ouverture',Fn) Then Exit;
 If Not FileThere(Fn) Then Begin MsgBox('Fichier introuvable|'+Fn); Exit; End;
 If InNew Then Begin
  If Not NewWindow Then Exit;
 End Else If Sh^.Modified Then
  If Not AskYesNo('Perdre les modifications ?') Then Exit;
 If LoadFile(Fn) Then Begin
  Sh^.Name:=Fn; Sh^.Titled:=True; Sh^.Modified:=False;
 End Else Begin
  MsgBox('Impossible de lire le fichier|'+Fn);
  If InNew Then CloseWin(CurWin);
 End;
End;

Function AllSaved: Boolean;
Var I: Integer;
Begin
 AllSaved:=True;
 For I:=1 To NWin Do If Win[I]^.Modified Then AllSaved:=False;
End;

{ ---------- Fichier de configuration ---------- }

Procedure SaveIni;
Var F: Text;
Begin
 Assign(F,'QUATTRO.INI');
 {$I-}
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin MsgBox('Impossible d'''#130'crire QUATTRO.INI'); Exit; End;
 WriteLn(F,'DEFCOLW=',DefColW);
 WriteLn(F,'DEFDEC=',DefDec);
 WriteLn(F,'CURR=',CurrSym);
 WriteLn(F,'DECSEP=',DecSep);
 WriteLn(F,'BAR=',Ord(ShowBar));
 WriteLn(F,'GRID=',Ord(ShowGrid));
 WriteLn(F,'AUTOCALC=',Ord(AutoCalc));
 WriteLn(F,'PAGEW=',PageW);
 WriteLn(F,'PAGEH=',PageH);
 WriteLn(F,'DIR=',DataDir);
 Close(F);
 MsgBox('Param'#138'tres sauvegard'#130's dans QUATTRO.INI');
End;

Procedure LoadIni;
Var F: Text; L, K, V: String; N, Code, P: Integer;
Begin
 Assign(F,'QUATTRO.INI');
 {$I-}
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(F) Do Begin
  ReadLn(F,L);
  P:=Pos('=',L);
  If P>0 Then Begin
   K:=UpStr(Copy(L,1,P-1)); V:=Copy(L,P+1,255);
   Val(V,N,Code);
   If K='DEFCOLW' Then Begin If (Code=0) And (N>=1) And (N<=72) Then DefColW:=N; End
   Else If K='DEFDEC' Then Begin If (Code=0) And (N>=0) And (N<=15) Then DefDec:=N; End
   Else If K='CURR' Then CurrSym:=Copy(V,1,4)
   Else If K='DECSEP' Then Begin If V<>'' Then DecSep:=V[1]; End
   Else If K='BAR' Then ShowBar:=N<>0
   Else If K='GRID' Then ShowGrid:=N<>0
   Else If K='AUTOCALC' Then AutoCalc:=N<>0
   Else If K='PAGEW' Then Begin If (Code=0) And (N>=20) And (N<=250) Then PageW:=N; End
   Else If K='PAGEH' Then Begin If (Code=0) And (N>=10) And (N<=250) Then PageH:=N; End
   Else If K='DIR' Then Begin If V<>'' Then DataDir:=V; End;
  End;
 End;
 Close(F);
End;

{ ====================================================================== }
{                  OPERATIONS SUR LES BLOCS DE CELLULES                  }
{ ====================================================================== }

Procedure RewriteAllFormulas;
Var R, C, I: Integer; P: PCell; G: TRange; A1, A2: Boolean;
Begin
 For R:=0 To MAX_ROWS-1 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=0 To MAX_COLS-1 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If (P<>Nil) And (P^.Kind=CK_FORMULA) Then SetStr(P^.Txt,RewriteRefs(GetStr(P^.Txt)));
   End;
 If RW_Mode>=2 Then
  For I:=1 To Sh^.NameCnt Do Begin
   G:=Sh^.Names[I].R;
   If RW_Mode=2 Then Begin
    If (G.R1>=RW_Rng.R1) And (G.R2<=RW_Rng.R2) And (G.C1>=RW_Rng.C1) And (G.C2<=RW_Rng.C2) Then Begin
     G.R1:=G.R1+RW_DR; G.R2:=G.R2+RW_DR; G.C1:=G.C1+RW_DC; G.C2:=G.C2+RW_DC;
    End;
    Sh^.Names[I].R:=G;
   End Else If AdjustPair(G.R1,G.C1,G.R2,G.C2,False,False,False,False) Then Sh^.Names[I].R:=G
   Else Sh^.Names[I].R.R1:=0;
  End;
End;

Procedure FreeRowArr(RA: PRowArr);
Var C: Integer;
Begin
 For C:=0 To MAX_COLS-1 Do
  If RA^[C]<>Nil Then Begin FreeCellData(RA^[C]); Dispose(RA^[C]); End;
 FreeMem(RA,SizeOf(TRowArr));
End;

Procedure InsertRows(At, N: Integer);
Var R: Integer;
Begin
 If At+N>MAX_ROWS Then N:=MAX_ROWS-At;
 If N<=0 Then Exit;
 For R:=MAX_ROWS-N To MAX_ROWS-1 Do
  If Sh^.Rows^[R]<>Nil Then Begin FreeRowArr(Sh^.Rows^[R]); Sh^.Rows^[R]:=Nil; End;
 For R:=MAX_ROWS-1 DownTo At+N Do Sh^.Rows^[R]:=Sh^.Rows^[R-N];
 For R:=At To At+N-1 Do Sh^.Rows^[R]:=Nil;
 RW_Mode:=3; RW_At:=At; RW_N:=N;
 RewriteAllFormulas;
End;

Procedure DeleteRows(At, N: Integer);
Var R: Integer;
Begin
 If At+N>MAX_ROWS Then N:=MAX_ROWS-At;
 If N<=0 Then Exit;
 For R:=At To At+N-1 Do
  If Sh^.Rows^[R]<>Nil Then Begin FreeRowArr(Sh^.Rows^[R]); Sh^.Rows^[R]:=Nil; End;
 For R:=At To MAX_ROWS-1-N Do Sh^.Rows^[R]:=Sh^.Rows^[R+N];
 For R:=MAX_ROWS-N To MAX_ROWS-1 Do Sh^.Rows^[R]:=Nil;
 RW_Mode:=5; RW_At:=At; RW_N:=N;
 RewriteAllFormulas;
End;

Procedure InsertCols(At, N: Integer);
Var R, C: Integer; RA: PRowArr;
Begin
 If At+N>MAX_COLS Then N:=MAX_COLS-At;
 If N<=0 Then Exit;
 For R:=0 To MAX_ROWS-1 Do Begin
  RA:=Sh^.Rows^[R];
  If RA<>Nil Then Begin
   For C:=MAX_COLS-N To MAX_COLS-1 Do
    If RA^[C]<>Nil Then Begin FreeCellData(RA^[C]); Dispose(RA^[C]); RA^[C]:=Nil; End;
   For C:=MAX_COLS-1 DownTo At+N Do RA^[C]:=RA^[C-N];
   For C:=At To At+N-1 Do RA^[C]:=Nil;
  End;
 End;
 For C:=MAX_COLS-1 DownTo At+N Do Begin Sh^.ColW[C]:=Sh^.ColW[C-N]; Sh^.ColSty[C]:=Sh^.ColSty[C-N]; End;
 For C:=At To At+N-1 Do Begin Sh^.ColW[C]:=DefColW; Sh^.ColSty[C].Used:=0; End;
 RW_Mode:=4; RW_At:=At; RW_N:=N;
 RewriteAllFormulas;
End;

Procedure DeleteCols(At, N: Integer);
Var R, C: Integer; RA: PRowArr;
Begin
 If At+N>MAX_COLS Then N:=MAX_COLS-At;
 If N<=0 Then Exit;
 For R:=0 To MAX_ROWS-1 Do Begin
  RA:=Sh^.Rows^[R];
  If RA<>Nil Then Begin
   For C:=At To At+N-1 Do
    If RA^[C]<>Nil Then Begin FreeCellData(RA^[C]); Dispose(RA^[C]); RA^[C]:=Nil; End;
   For C:=At To MAX_COLS-1-N Do RA^[C]:=RA^[C+N];
   For C:=MAX_COLS-N To MAX_COLS-1 Do RA^[C]:=Nil;
  End;
 End;
 For C:=At To MAX_COLS-1-N Do Begin Sh^.ColW[C]:=Sh^.ColW[C+N]; Sh^.ColSty[C]:=Sh^.ColSty[C+N]; End;
 For C:=MAX_COLS-N To MAX_COLS-1 Do Begin Sh^.ColW[C]:=DefColW; Sh^.ColSty[C].Used:=0; End;
 RW_Mode:=6; RW_At:=At; RW_N:=N;
 RewriteAllFormulas;
End;

Procedure ClearRange(Const G: TRange);
Var R, C: Integer; P: PCell;
Begin
 For R:=G.R1 To G.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=G.C1 To G.C2 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If P<>Nil Then ResetCellContent(P);
   End;
End;

Procedure KillRange(Const G: TRange);
Var R, C: Integer;
Begin
 For R:=G.R1 To G.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=G.C1 To G.C2 Do KillCell(Sh,R,C);
End;

Procedure CopyCellInto(Dst: PCell; Const Src: TCell);
Var T, Rs: PStr;
Begin
 FreeCellData(Dst);
 Dst^:=Src;
 Dst^.Txt:=Nil; Dst^.Res:=Nil;
 SetStr(Dst^.Txt,GetStr(Src.Txt));
 SetStr(Dst^.Res,GetStr(Src.Res));
 Dst^.Calc:=0;
End;

Procedure DoCopyMove(Const Src, Dst: TRange; Move: Boolean);
Var Cnt, I: LongInt; R, C, Br, Bc, Nr, Nc, DR2, DC2, Sr, Sc: Integer; Snap: PSnapArr; P: PCell;
    Rr, Cc: Integer; Single: Boolean; Txt: String;
Begin
 Cnt:=0;
 For R:=Src.R1 To Src.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=Src.C1 To Src.C2 Do If Sh^.Rows^[R]^[C]<>Nil Then Inc(Cnt);
 If Cnt>MAX_SNAP Then Begin MsgBox('Bloc trop grand pour '#133'tre copi'#130); Exit; End;
 SaveUndo(Sh);
 Snap:=Nil;
 If Cnt>0 Then GetMem(Snap,Cnt*SizeOf(TSnap));
 I:=0;
 For R:=Src.R1 To Src.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=Src.C1 To Src.C2 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If P<>Nil Then Begin
     Snap^[I].Dr:=R-Src.R1; Snap^[I].Dc:=C-Src.C1;
     Snap^[I].Cell:=P^;
     Snap^[I].Cell.Txt:=Nil; Snap^[I].Cell.Res:=Nil;
     SetStr(Snap^[I].Cell.Txt,GetStr(P^.Txt));
     SetStr(Snap^[I].Cell.Res,GetStr(P^.Res));
     Inc(I);
    End;
   End;
 Single:=(Src.R1=Src.R2) And (Src.C1=Src.C2);
 If Single Then Begin DR2:=Dst.R2; DC2:=Dst.C2; End
  Else Begin DR2:=Dst.R1+(Src.R2-Src.R1); DC2:=Dst.C1+(Src.C2-Src.C1); End;
 If DR2>=MAX_ROWS Then DR2:=MAX_ROWS-1;
 If DC2>=MAX_COLS Then DC2:=MAX_COLS-1;
 If Move Then KillRange(Src);
 Rr:=Dst.R1; Cc:=Dst.C1;
 If Single Then Begin
  Sr:=Dst.R2-Dst.R1+1; Sc:=Dst.C2-Dst.C1+1;
 End Else Begin Sr:=1; Sc:=1; End;
 { efface la destination }
 Begin
  Nr:=Dst.R1; Nc:=Dst.C1;
  For R:=Nr To DR2 Do
   If Sh^.Rows^[R]<>Nil Then
    For C:=Nc To DC2 Do KillCell(Sh,R,C);
 End;
 For Br:=0 To Sr-1 Do
  For Bc:=0 To Sc-1 Do
   For I:=0 To Cnt-1 Do Begin
    Nr:=Dst.R1+Br+Snap^[I].Dr;
    Nc:=Dst.C1+Bc+Snap^[I].Dc;
    If (Nr<MAX_ROWS) And (Nc<MAX_COLS) And (Nr<=DR2) And (Nc<=DC2) Then Begin
     P:=MakeCell(Sh,Nr,Nc);
     If P<>Nil Then Begin
      CopyCellInto(P,Snap^[I].Cell);
      If (P^.Kind=CK_FORMULA) And (Not Move) Then Begin
       RW_Mode:=1; RW_DR:=Nr-(Src.R1+Snap^[I].Dr); RW_DC:=Nc-(Src.C1+Snap^[I].Dc);
       Txt:=RewriteRefs(GetStr(P^.Txt));
       RW_Mode:=0;
       SetStr(P^.Txt,Txt);
      End;
     End;
    End;
   End;
 For I:=0 To Cnt-1 Do FreeCellData(@Snap^[I].Cell);
 If Snap<>Nil Then FreeMem(Snap,Cnt*SizeOf(TSnap));
 If Move Then Begin
  RW_Mode:=2; RW_Rng:=Src; RW_DR:=Dst.R1-Src.R1; RW_DC:=Dst.C1-Src.C1;
  RewriteAllFormulas;
  RW_Mode:=0;
 End;
 Changed;
End;

{ Modifie le style d'un bloc.  What : 1 format, 2 alignement, 3 fonte, 4 protection. }
Procedure StyleRange(Const G: TRange; What, V1, V2: Integer);
Var R, C: Integer; P: PCell; Whole: Boolean; Cnt: LongInt;

 Procedure Apply(Q: PCell);
 Begin
  Case What Of
   1: Begin Q^.Fmt:=V1; Q^.Dec:=V2; End;
   2: Q^.Al:=V1;
   3: Q^.Fnt:=V1;
   4: Q^.Prot:=V1;
  End;
 End;

Begin
 Whole:=(G.R1=0) And (G.R2=MAX_ROWS-1);
 If Whole Then Begin
  For C:=G.C1 To G.C2 Do Begin
   If Sh^.ColSty[C].Used=0 Then Begin
    Sh^.ColSty[C].Used:=1; Sh^.ColSty[C].Fmt:=DefFmt; Sh^.ColSty[C].Dec:=DefDec;
    Sh^.ColSty[C].Al:=0; Sh^.ColSty[C].Fnt:=0; Sh^.ColSty[C].Prot:=0;
   End;
   Case What Of
    1: Begin Sh^.ColSty[C].Fmt:=V1; Sh^.ColSty[C].Dec:=V2; End;
    2: Sh^.ColSty[C].Al:=V1;
    3: Sh^.ColSty[C].Fnt:=V1;
    4: Sh^.ColSty[C].Prot:=V1;
   End;
  End;
  For R:=0 To MAX_ROWS-1 Do
   If Sh^.Rows^[R]<>Nil Then
    For C:=G.C1 To G.C2 Do Begin
     P:=Sh^.Rows^[R]^[C];
     If P<>Nil Then Apply(P);
    End;
  Exit;
 End;
 Cnt:=LongInt(G.R2-G.R1+1)*LongInt(G.C2-G.C1+1);
 {$IFDEF FPC}
 If Cnt>400000 Then Begin MsgBox('Bloc trop grand'); Exit; End;
 {$ELSE}
 If Cnt>2500 Then Begin MsgBox('Bloc trop grand'); Exit; End;
 {$ENDIF}
 For R:=G.R1 To G.R2 Do
  For C:=G.C1 To G.C2 Do Begin
   P:=MakeCell(Sh,R,C);
   If P<>Nil Then Apply(P);
  End;
End;

Procedure RangeAskStyle(What, V1, V2: Integer);
Var G: TRange;
Begin
 GetSel(G);
 SaveUndo(Sh);
 StyleRange(G,What,V1,V2);
 Sh^.Modified:=True;
End;

Function PromptInt(Const Title: String; Var N: LongInt; Lo, Hi: LongInt): Boolean;
Var S: String; V: LongInt; Code: Integer;
Begin
 PromptInt:=False;
 S:=IntStr(N);
 If Not PromptStr(Title,S,12) Then Exit;
 Val(TrimStr(S),V,Code);
 If (Code<>0) Or (V<Lo) Or (V>Hi) Then Begin
  MsgBox('Valeur invalide ('+IntStr(Lo)+' '#133' '+IntStr(Hi)+')');
  Exit;
 End;
 N:=V;
 PromptInt:=True;
End;

Procedure SetColWidth(Const G: TRange; W: Integer);
Var C: Integer;
Begin
 For C:=G.C1 To G.C2 Do Sh^.ColW[C]:=W;
End;

Procedure FitColumns(Const G: TRange);
Var C, R, Best, L, W: Integer; P: PCell; Al: Byte; S: String;
Begin
 For C:=G.C1 To G.C2 Do Begin
  Best:=1;
  For R:=0 To MAX_ROWS-1 Do
   If Sh^.Rows^[R]<>Nil Then Begin
    P:=Sh^.Rows^[R]^[C];
    If (P<>Nil) And (P^.Kind<>CK_EMPTY) Then Begin
     S:=CellDisplay(P,30,Al);
     If P^.Kind=CK_FORMULA Then Begin
      If (P^.ResK=0) And (P^.Fmt=FM_GEN) Then S:=Localize(GenStr(P^.Num,30));
     End;
     L:=Length(S)*8+6;
     W:=(L+5) Div 7;
     If W>Best Then Best:=W;
    End;
   End;
  If Best>72 Then Best:=72;
  If Sh^.ColW[C]>0 Then Sh^.ColW[C]:=Best;
 End;
End;

Procedure LockTitles(Mode: Integer);
Begin
 Case Mode Of
  1: Begin Sh^.LockR:=Sh^.CurR; End;
  2: Begin Sh^.LockC:=Sh^.CurC; End;
  3: Begin Sh^.LockR:=Sh^.CurR; Sh^.LockC:=Sh^.CurC; End;
  Else Begin Sh^.LockR:=0; Sh^.LockC:=0; End;
 End;
 Sh^.TopR:=Sh^.LockR; Sh^.LeftC:=Sh^.LockC;
 If Sh^.CurR<Sh^.LockR Then Sh^.CurR:=Sh^.LockR;
 If Sh^.CurC<Sh^.LockC Then Sh^.CurC:=Sh^.LockC;
End;

Procedure DoValues(Const G: TRange);
Var R, C: Integer; P: PCell; V: TVal;
Begin
 SaveUndo(Sh);
 For R:=G.R1 To G.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=G.C1 To G.C2 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If (P<>Nil) And (P^.Kind=CK_FORMULA) Then Begin
     EnsureCalc(P,R,C);
     Case P^.ResK Of
      0: SetNumber(P,P^.Num);
      1: SetLabel(P,GetStr(P^.Res),P^.Al);
      Else SetLabel(P,'ERR',AL_DEF);
     End;
    End;
   End;
 Changed;
End;

Procedure DoTranspose(Const Src, Dst: TRange);
Var Cnt, I: LongInt; R, C: Integer; Snap: PSnapArr; P, Q: PCell; DR2, DC2: Integer;
Begin
 Cnt:=0;
 For R:=Src.R1 To Src.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=Src.C1 To Src.C2 Do If Sh^.Rows^[R]^[C]<>Nil Then Inc(Cnt);
 If Cnt>MAX_SNAP Then Begin MsgBox('Bloc trop grand'); Exit; End;
 SaveUndo(Sh);
 Snap:=Nil;
 If Cnt>0 Then GetMem(Snap,Cnt*SizeOf(TSnap));
 I:=0;
 For R:=Src.R1 To Src.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=Src.C1 To Src.C2 Do Begin
    P:=Sh^.Rows^[R]^[C];
    If P<>Nil Then Begin
     Snap^[I].Dr:=R-Src.R1; Snap^[I].Dc:=C-Src.C1;
     If P^.Kind=CK_FORMULA Then EnsureCalc(P,R,C);
     Snap^[I].Cell:=P^;
     Snap^[I].Cell.Txt:=Nil; Snap^[I].Cell.Res:=Nil;
     If P^.Kind=CK_FORMULA Then Begin
      If P^.ResK=1 Then Begin
       Snap^[I].Cell.Kind:=CK_LABEL; SetStr(Snap^[I].Cell.Txt,GetStr(P^.Res));
      End Else Begin
       Snap^[I].Cell.Kind:=CK_NUM;
       If P^.ResK=0 Then Snap^[I].Cell.Num:=P^.Num Else Snap^[I].Cell.Num:=0;
      End;
     End Else SetStr(Snap^[I].Cell.Txt,GetStr(P^.Txt));
     Inc(I);
    End;
   End;
 DR2:=Dst.R1+(Src.C2-Src.C1); DC2:=Dst.C1+(Src.R2-Src.R1);
 If DR2>=MAX_ROWS Then DR2:=MAX_ROWS-1;
 If DC2>=MAX_COLS Then DC2:=MAX_COLS-1;
 For R:=Dst.R1 To DR2 Do
  If Sh^.Rows^[R]<>Nil Then For C:=Dst.C1 To DC2 Do KillCell(Sh,R,C);
 For I:=0 To Cnt-1 Do Begin
  R:=Dst.R1+Snap^[I].Dc; C:=Dst.C1+Snap^[I].Dr;
  If (R<MAX_ROWS) And (C<MAX_COLS) Then Begin
   Q:=MakeCell(Sh,R,C);
   If Q<>Nil Then CopyCellInto(Q,Snap^[I].Cell);
  End;
 End;
 For I:=0 To Cnt-1 Do FreeCellData(@Snap^[I].Cell);
 If Snap<>Nil Then FreeMem(Snap,Cnt*SizeOf(TSnap));
 Changed;
End;

Procedure DoFill(Const G: TRange; Start, Step, Stop: Double);
Var R, C: Integer; V: Double; P: PCell; Go: Boolean;
Begin
 SaveUndo(Sh);
 V:=Start;
 For C:=G.C1 To G.C2 Do
  For R:=G.R1 To G.R2 Do Begin
   If Step>=0 Then Go:=V<=Stop Else Go:=V>=Stop;
   If Go Then Begin
    P:=MakeCell(Sh,R,C);
    If P<>Nil Then SetNumber(P,V);
    V:=V+Step;
   End;
  End;
 Changed;
End;

Procedure CreateName(Const Nm: String; Const G: TRange);
Var I, K: Integer;
Begin
 K:=0;
 For I:=1 To Sh^.NameCnt Do If SameStr(Sh^.Names[I].Nm,Nm) Then K:=I;
 If K=0 Then Begin
  If Sh^.NameCnt>=MAX_NAMES Then Begin MsgBox('Trop de noms de blocs'); Exit; End;
  Inc(Sh^.NameCnt); K:=Sh^.NameCnt;
 End;
 Sh^.Names[K].Nm:=Copy(Nm,1,15);
 Sh^.Names[K].R:=G;
 Sh^.Modified:=True;
End;

Procedure DeleteName(Const Nm: String);
Var I, J: Integer;
Begin
 For I:=Sh^.NameCnt DownTo 1 Do
  If SameStr(Sh^.Names[I].Nm,Nm) Then Begin
   For J:=I To Sh^.NameCnt-1 Do Sh^.Names[J]:=Sh^.Names[J+1];
   Dec(Sh^.NameCnt);
   Sh^.Modified:=True;
  End;
End;

Function ValidName(Const S: String): Boolean;
Var I, P, R, C: Integer; A, B: Boolean;
Begin
 ValidName:=False;
 If (S='') Or (Length(S)>15) Then Exit;
 If Not (IsAlphaCh(S[1]) Or (S[1]='_')) Then Exit;
 For I:=1 To Length(S) Do
  If Not (IsAlphaCh(S[I]) Or IsDigitCh(S[I]) Or (S[I]='_')) Then Exit;
 P:=1;
 If ScanRef(S,P,R,C,A,B) Then Exit;
 ValidName:=True;
End;

Function FindNext(Const T: String; FromR, FromC: Integer; Var R, C: Integer): Boolean;
Var Rr, Cc, Mr, Mc: Integer; P: PCell; S, U: String; Al: Byte;
Begin
 FindNext:=False;
 U:=UpStr(T);
 Mr:=UsedRows(Sh); Mc:=UsedCols(Sh);
 Rr:=FromR; Cc:=FromC;
 Repeat
  Inc(Cc);
  If Cc>Mc Then Begin Cc:=0; Inc(Rr); End;
  If Rr>Mr Then Exit;
  P:=FindCell(Sh,Rr,Cc);
  If (P<>Nil) And (P^.Kind<>CK_EMPTY) Then Begin
   S:=UpStr(CellSource(P));
   If P^.Kind=CK_LABEL Then S:=UpStr(GetStr(P^.Txt));
   If Pos(U,S)>0 Then Begin R:=Rr; C:=Cc; FindNext:=True; Exit; End;
  End;
 Until False;
End;

Function DoReplace(Const G: TRange; Const Fnd, Rpl: String): Integer;
Var R, C, N, P: Integer; Q: PCell; S, S2, Rest, UF: String; Hit: Boolean;
Begin
 N:=0;
 UF:=UpStr(Fnd);
 If UF='' Then Begin DoReplace:=0; Exit; End;
 SaveUndo(Sh);
 For R:=G.R1 To G.R2 Do
  If Sh^.Rows^[R]<>Nil Then
   For C:=G.C1 To G.C2 Do Begin
    Q:=Sh^.Rows^[R]^[C];
    If (Q<>Nil) And ((Q^.Kind=CK_LABEL) Or (Q^.Kind=CK_FORMULA)) Then Begin
     S:=GetStr(Q^.Txt);
     Rest:=S; S2:=''; Hit:=False;
     Repeat
      P:=Pos(UF,UpStr(Rest));
      If P>0 Then Begin
       S2:=S2+Copy(Rest,1,P-1)+Rpl;
       Rest:=Copy(Rest,P+Length(Fnd),255);
       Hit:=True;
      End;
     Until P=0;
     If Hit Then Begin
      SetStr(Q^.Txt,S2+Rest);
      Inc(N);
     End;
    End;
   End;
 If N>0 Then Changed;
 DoReplace:=N;
End;

Procedure AutoSum;
Var G: TRange; R, C, R1, C1, Tr: Integer; P: PCell; Fm: String; Used: Boolean;

 Function Numeric(Rr, Cc: Integer): Boolean;
 Var Q: PCell;
 Begin
  Q:=FindCell(Sh,Rr,Cc);
  Numeric:=(Q<>Nil) And ((Q^.Kind=CK_NUM) Or (Q^.Kind=CK_FORMULA));
 End;

Begin
 GetSel(G);
 SaveUndo(Sh);
 If (G.R1<>G.R2) Or (G.C1<>G.C2) Then Begin
  { bloc : somme de chaque colonne dans la ligne sous le bloc }
  If G.R2+1>=MAX_ROWS Then Exit;
  For C:=G.C1 To G.C2 Do Begin
   P:=MakeCell(Sh,G.R2+1,C);
   If P<>Nil Then SetFormula(P,'@SUM('+CellName(G.R1,C)+'..'+CellName(G.R2,C)+')');
  End;
  Changed;
  Exit;
 End;
 R:=G.R1; C:=G.C1;
 R1:=R-1;
 While (R1>=0) And Numeric(R1,C) Do Dec(R1);
 If R1<R-1 Then Fm:='@SUM('+CellName(R1+1,C)+'..'+CellName(R-1,C)+')'
 Else Begin
  C1:=C-1;
  While (C1>=0) And Numeric(R,C1) Do Dec(C1);
  If C1<C-1 Then Fm:='@SUM('+CellName(R,C1+1)+'..'+CellName(R,C-1)+')'
  Else Begin MsgBox('Aucune valeur '#133' additionner'); Exit; End;
 End;
 P:=MakeCell(Sh,R,C);
 If P<>Nil Then SetFormula(P,Fm);
 Changed;
End;

{ ====================================================================== }
{                              GRAPHIQUES                                }
{ ====================================================================== }

Const
 MAXPT = 48;
 GCol: Array[1..6] Of Integer = (9,12,10,5,3,6);
 PieCol: Array[1..12] Of Integer = (9,12,10,14,13,11,1,4,2,6,5,3);

Var
 GV   : Array[1..6,1..MAXPT] Of Double;
 GN   : Array[0..6] Of Integer;
 GXV  : Array[1..MAXPT] Of Double;
 GLab : Array[1..MAXPT] Of String[8];

Function NiceStep(Range: Double): Double;
Var E: Integer; M, P: Double;
Begin
 If Range<=0 Then Begin NiceStep:=1; Exit; End;
 E:=0; M:=Range;
 While M>=10 Do Begin M:=M/10; Inc(E); End;
 While M<1 Do Begin M:=M*10; Dec(E); End;
 If M<1.5 Then P:=1 Else If M<3 Then P:=2 Else If M<7 Then P:=5 Else P:=10;
 While E>0 Do Begin P:=P*10; Dec(E); End;
 While E<0 Do Begin P:=P/10; Inc(E); End;
 NiceStep:=P;
End;

Function FloorD(X: Double): Double;
Var Y: Double;
Begin
 Y:=Int(X);
 If (X<0) And (Y<>X) Then Y:=Y-1;
 FloorD:=Y;
End;

Function CeilD(X: Double): Double;
Var Y: Double;
Begin
 Y:=Int(X);
 If (X>0) And (Y<>X) Then Y:=Y+1;
 CeilD:=Y;
End;

Procedure LoadSeries;
Var I, R, C, N: Integer; V: TVal; G: TRange; P: PCell; Al: Byte; S: String;
Begin
 EvDepth:=0; Deferred:=False;
 For I:=0 To 6 Do Begin
  GN[I]:=0;
  If Sh^.Gr.SerOn[I] Then Begin
   G:=Sh^.Gr.Ser[I]; N:=0;
   For R:=G.R1 To G.R2 Do
    For C:=G.C1 To G.C2 Do
     If N<MAXPT Then Begin
      Inc(N);
      If I=0 Then Begin
       P:=FindCell(Sh,R,C);
       S:=CellDisplay(P,8,Al);
       GLab[N]:=Copy(S,1,8);
       CellVal(R,C,V);
       If V.K=0 Then GXV[N]:=V.N Else GXV[N]:=N;
      End Else Begin
       CellVal(R,C,V);
       If V.K=0 Then GV[I,N]:=V.N Else GV[I,N]:=0;
      End;
     End;
   GN[I]:=N;
  End;
 End;
 Deferred:=False;
End;

Procedure ShowGraph;
Const PX1=96; PX2=600; PY1=64; PY2=372;
Var I, J, N, Ns, Gt, Cnt, K: Integer; YMin, YMax, XMin, XMax, Stp, V, Sum, Cum, A0, A1: Double;
    Y, Px, Py, X0, Gw, Bw, Bx, Ty: Integer; S: String; Ch: Char; Ev: Integer; Kk: Word;
    Pos_, Neg: Array[1..MAXPT] Of Double; OldX, OldY: Integer; Rad: Integer;

 Function MapY(Vv: Double): Integer;
 Begin
  MapY:=PY2-Round((Vv-YMin)/(YMax-YMin)*(PY2-PY1));
 End;
 Function MapX(Vv: Double): Integer;
 Begin
  MapX:=PX1+Round((Vv-XMin)/(XMax-XMin)*(PX2-PX1));
 End;

Begin
 LoadSeries;
 Ns:=0; N:=0;
 For I:=1 To 6 Do If GN[I]>0 Then Begin Inc(Ns); If GN[I]>N Then N:=GN[I]; End;
 If Ns=0 Then Begin
  MsgBox('Aucune s'#130'rie d'#130'finie.|Utilisez Graphique, S'#130'ries.');
  Exit;
 End;
 Gt:=Sh^.Gr.GType;
 {$IFNDEF FPC}HideMouse;{$ELSE}EraseSoftCursor;{$ENDIF}
 FillBox(0,0,SCR_W-1,SCR_H-1,CL_WHITE);
 If Sh^.Gr.T1<>'' Then TextAt((SCR_W-Length(Sh^.Gr.T1)*8) Div 2,14,Sh^.Gr.T1,CL_BLUE);
 If Sh^.Gr.T2<>'' Then TextAt((SCR_W-Length(Sh^.Gr.T2)*8) Div 2,30,Sh^.Gr.T2,CL_BLACK);
 If Gt=5 Then Begin
  { secteurs }
  Sum:=0;
  For I:=1 To GN[1] Do Sum:=Sum+Abs(GV[1,I]);
  If Sum=0 Then Sum:=1;
  Cum:=0; Rad:=130;
  For I:=1 To GN[1] Do Begin
   A0:=Cum/Sum*360; Cum:=Cum+Abs(GV[1,I]); A1:=Cum/Sum*360;
   SetFillStyle(SolidFill,PieCol[(I-1) Mod 12+1]);
   SetColor(CL_BLACK);
   If A1>A0 Then PieSlice(250,230,Round(A0),Round(A1),Rad);
   FillBox(440,70+I*16-16,452,70+I*16-6,PieCol[(I-1) Mod 12+1]);
   If (Sh^.Gr.SerOn[0]) And (I<=GN[0]) Then S:=GLab[I] Else S:='Part '+IntStr(I);
   TextAt(458,70+I*16-14,S+' '+FixStr(Abs(GV[1,I])/Sum*100,1)+'%',CL_BLACK);
  End;
 End Else Begin
  { echelle Y }
  YMin:=0; YMax:=0;
  If Gt=2 Then Begin
   For J:=1 To N Do Begin
    Pos_[J]:=0; Neg[J]:=0;
    For I:=1 To 6 Do If J<=GN[I] Then Begin
     If GV[I,J]>=0 Then Pos_[J]:=Pos_[J]+GV[I,J] Else Neg[J]:=Neg[J]+GV[I,J];
    End;
    If Pos_[J]>YMax Then YMax:=Pos_[J];
    If Neg[J]<YMin Then YMin:=Neg[J];
   End;
  End Else
   For I:=1 To 6 Do
    For J:=1 To GN[I] Do Begin
     If GV[I,J]>YMax Then YMax:=GV[I,J];
     If GV[I,J]<YMin Then YMin:=GV[I,J];
    End;
  If YMax=YMin Then YMax:=YMin+1;
  Stp:=NiceStep((YMax-YMin)/6);
  YMin:=FloorD(YMin/Stp)*Stp; YMax:=CeilD(YMax/Stp)*Stp;
  If YMax=YMin Then YMax:=YMin+Stp;
  XMin:=1; XMax:=N;
  If Gt=4 Then Begin
   XMin:=GXV[1]; XMax:=GXV[1];
   For J:=1 To GN[0] Do Begin
    If GXV[J]<XMin Then XMin:=GXV[J];
    If GXV[J]>XMax Then XMax:=GXV[J];
   End;
   If GN[0]=0 Then Begin XMin:=1; XMax:=N; End;
   If XMax=XMin Then XMax:=XMin+1;
   Stp:=NiceStep((XMax-XMin)/8);
   XMin:=FloorD(XMin/Stp)*Stp; XMax:=CeilD(XMax/Stp)*Stp;
  End;
  { grille et graduations Y }
  Stp:=NiceStep((YMax-YMin)/6);
  V:=YMin;
  While V<=YMax+Stp/2 Do Begin
   Y:=MapY(V);
   If Sh^.Gr.Grid Then HLine(PX1,PX2,Y,CL_LGRAY);
   S:=GenStr(V,10);
   TextAt(PX1-6-Length(S)*8,Y-3,S,CL_BLACK);
   HLine(PX1-4,PX1,Y,CL_BLACK);
   V:=V+Stp;
  End;
  VLine(PX1,PY1,PY2,CL_BLACK);
  If (YMin<0) Then HLine(PX1,PX2,MapY(0),CL_BLACK) Else HLine(PX1,PX2,PY2,CL_BLACK);
  If Sh^.Gr.TY<>'' Then TextAt(8,PY1-14,Sh^.Gr.TY,CL_BLACK);
  If Sh^.Gr.TX<>'' Then TextAt((SCR_W-Length(Sh^.Gr.TX)*8) Div 2,PY2+34,Sh^.Gr.TX,CL_BLACK);
  Case Gt Of
   1,2: Begin
    Gw:=(PX2-PX1) Div MaxI(N,1);
    If Gt=1 Then Bw:=(Gw*7 Div 10) Div MaxI(Ns,1) Else Bw:=Gw*7 Div 10;
    If Bw<1 Then Bw:=1;
    For J:=1 To N Do Begin
     X0:=PX1+(J-1)*Gw+(Gw-Bw*Ns*Ord(Gt=1)-Bw*Ord(Gt=2)) Div 2;
     If Gt=1 Then Begin
      K:=0;
      For I:=1 To 6 Do If GN[I]>0 Then Begin
       If J<=GN[I] Then Begin
        SetFillStyle(SolidFill,GCol[I]);
        Bx:=X0+K*Bw;
        Bar(Bx,MinI(MapY(GV[I,J]),MapY(0)),Bx+Bw-1,MaxI(MapY(GV[I,J]),MapY(0)));
        SetColor(CL_BLACK);
        Rectangle(Bx,MinI(MapY(GV[I,J]),MapY(0)),Bx+Bw-1,MaxI(MapY(GV[I,J]),MapY(0)));
       End;
       Inc(K);
      End;
     End Else Begin
      Cum:=0;
      For I:=1 To 6 Do If (GN[I]>0) And (J<=GN[I]) Then Begin
       SetFillStyle(SolidFill,GCol[I]);
       Bar(X0,MinI(MapY(Cum+GV[I,J]),MapY(Cum)),X0+Bw-1,MaxI(MapY(Cum+GV[I,J]),MapY(Cum)));
       SetColor(CL_BLACK);
       Rectangle(X0,MinI(MapY(Cum+GV[I,J]),MapY(Cum)),X0+Bw-1,MaxI(MapY(Cum+GV[I,J]),MapY(Cum)));
       Cum:=Cum+GV[I,J];
      End;
     End;
     If Sh^.Gr.SerOn[0] And (J<=GN[0]) Then S:=GLab[J] Else S:=IntStr(J);
     TextAt(PX1+(J-1)*Gw+(Gw-Length(S)*8) Div 2,PY2+8,Copy(S,1,Gw Div 8+1),CL_BLACK);
    End;
   End;
   3: Begin
    For J:=1 To N Do Begin
     If N>1 Then Px:=PX1+10+Round((J-1)/(N-1)*(PX2-PX1-20)) Else Px:=(PX1+PX2) Div 2;
     If Sh^.Gr.SerOn[0] And (J<=GN[0]) Then S:=GLab[J] Else S:=IntStr(J);
     TextAt(Px-Length(S)*4,PY2+8,Copy(S,1,8),CL_BLACK);
     VLine(Px,PY2,PY2+3,CL_BLACK);
    End;
    For I:=1 To 6 Do If GN[I]>0 Then Begin
     SetColor(GCol[I]);
     For J:=1 To GN[I] Do Begin
      If N>1 Then Px:=PX1+10+Round((J-1)/(N-1)*(PX2-PX1-20)) Else Px:=(PX1+PX2) Div 2;
      Py:=MapY(GV[I,J]);
      If J>1 Then Begin
       SetColor(GCol[I]);
       Line(OldX,OldY,Px,Py);
       Line(OldX,OldY+1,Px,Py+1);
      End;
      SetFillStyle(SolidFill,GCol[I]);
      Bar(Px-2,Py-2,Px+2,Py+2);
      OldX:=Px; OldY:=Py;
     End;
    End;
   End;
   4: Begin
    V:=XMin;
    Stp:=NiceStep((XMax-XMin)/8);
    While V<=XMax+Stp/2 Do Begin
     Px:=MapX(V);
     S:=GenStr(V,8);
     TextAt(Px-Length(S)*4,PY2+8,S,CL_BLACK);
     VLine(Px,PY2,PY2+3,CL_BLACK);
     If Sh^.Gr.Grid Then VLine(Px,PY1,PY2,CL_LGRAY);
     V:=V+Stp;
    End;
    For I:=1 To 6 Do If GN[I]>0 Then
     For J:=1 To GN[I] Do Begin
      If J<=GN[0] Then V:=GXV[J] Else V:=J;
      Px:=MapX(V); Py:=MapY(GV[I,J]);
      SetFillStyle(SolidFill,GCol[I]);
      SetColor(CL_BLACK);
      Bar(Px-3,Py-3,Px+3,Py+3);
      Rectangle(Px-3,Py-3,Px+3,Py+3);
     End;
   End;
  End;
  { legende }
  K:=0;
  For I:=1 To 6 Do If GN[I]>0 Then Begin
   FillBox(PX1+K*110,PY2+54,PX1+K*110+10,PY2+64,GCol[I]);
   Rectangle(PX1+K*110,PY2+54,PX1+K*110+10,PY2+64);
   TextAt(PX1+K*110+16,PY2+56,'S'#130'rie '+IntStr(I),CL_BLACK);
   Inc(K);
  End;
 End;
 TextAt(8,SCR_H-14,'Appuyez sur une touche ou cliquez pour revenir',CL_DGRAY);
 {$IFDEF FPC}DrawSoftCursor(MsX,MsY);{$ELSE}ShowMouse;{$ENDIF}
 Repeat
  Ev:=GetEvent(Kk);
  If Ev=2 Then Begin
   If EdgeDown Then Ev:=1 Else Begin MoveSoftCursor; Ev:=0; End;
  End;
 Until Ev=1;
End;

{ ====================================================================== }
{                              IMPRESSION                                }
{ ====================================================================== }

Procedure EmitLine(Const S: String);
Begin
 If PrintDest=3 Then LstAdd(S) Else WriteLn(PrintFile,S);
End;

Function PadAl(Const S: String; W: Integer; Al: Byte): String;
Var T: String; N: Integer;
Begin
 T:=Copy(S,1,W);
 N:=W-Length(T);
 Case Al Of
  AL_RIGHT:  PadAl:=Rep(' ',N)+T;
  AL_CENTER: PadAl:=Rep(' ',N Div 2)+T+Rep(' ',N-N Div 2);
  Else       PadAl:=T+Rep(' ',N);
 End;
End;

Procedure DoPrint;
Var G: TRange; R, C, Ln, PerPage, Page, Mr, Mc: Integer; L, Fn: String; P: PCell; Al: Byte; S: String;
    Ok: Boolean; V: TVal;
Begin
 If Sh^.PrintOn Then G:=Sh^.PrintR
 Else Begin
  Mr:=UsedRows(Sh); Mc:=UsedCols(Sh);
  If (Mr<0) Or (Mc<0) Then Begin MsgBox('Rien '#133' imprimer'); Exit; End;
  SetRange(G,0,0,Mr,Mc);
 End;
 If PrintDest=3 Then LstClear
 Else If PrintDest=2 Then Begin
  Fn:=BaseName(Sh^.Name);
  If Pos('.',Fn)>0 Then Fn:=Copy(Fn,1,Pos('.',Fn)-1);
  Fn:=Fn+'.PRN';
  If Not PromptStr('Fichier d''impression :',Fn,40) Then Exit;
  Assign(PrintFile,FullPath(Fn));
  {$I-}
  Rewrite(PrintFile);
  {$I+}
  If IOResult<>0 Then Begin MsgBox('Impossible de cr'#130'er le fichier'); Exit; End;
 End Else Begin
  Assign(PrintFile,'PRN');
  {$I-}
  Rewrite(PrintFile);
  {$I+}
  If IOResult<>0 Then Begin MsgBox('Imprimante non disponible'); Exit; End;
 End;
 PerPage:=PageH-6; If PerPage<5 Then PerPage:=5;
 Ln:=0; Page:=1;
 EvDepth:=0; Deferred:=False;
 For R:=G.R1 To G.R2 Do Begin
  If Ln=0 Then Begin
   If Sh^.Hdr<>'' Then EmitLine(Sh^.Hdr) Else EmitLine('');
   EmitLine('');
  End;
  L:='';
  For C:=G.C1 To G.C2 Do
   If Sh^.ColW[C]>0 Then Begin
    P:=FindCell(Sh,R,C);
    If (P<>Nil) And (P^.Kind=CK_FORMULA) Then EnsureCalc(P,R,C);
    S:=CellDisplay(P,Sh^.ColW[C]-1,Al);
    L:=L+PadAl(S,Sh^.ColW[C],Al);
   End;
  EmitLine(Copy(L,1,PageW));
  Inc(Ln);
  If (Ln>=PerPage) Or (R=G.R2) Then Begin
   While (Ln<PerPage) And (PrintDest<>3) And (R<>G.R2) Do Begin EmitLine(''); Inc(Ln); End;
   EmitLine('');
   S:=Sh^.Ftr;
   If S<>'' Then EmitLine(S+Rep(' ',MaxI(1,PageW-Length(S)-8))+'Page '+IntStr(Page));
   If (R<G.R2) And (PrintDest<>3) Then EmitLine(#12);
   Ln:=0; Inc(Page);
  End;
 End;
 Deferred:=False;
 If PrintDest=3 Then ShowList('Aper'#135'u avant impression')
 Else Begin
  Close(PrintFile);
  MsgBox('Impression termin'#130'e ('+IntStr(Page-1)+' page(s))');
 End;
End;

{ ====================================================================== }
{                       TRI ET REQUETES SUR BASE                         }
{ ====================================================================== }

Type
 TDArr = Array[0..4095] Of Double;
 PDArr = ^TDArr;
 TIArr = Array[0..4095] Of Integer;
 PIArr = ^TIArr;
 TPArr = Array[0..4095] Of PCell;
 PPArr = ^TPArr;
 TBArr = Array[0..4095] Of Byte;
 PBArr = ^TBArr;

Procedure DoSort;
Var N, I, J, R, C, T: Integer; Kn: PDArr; Kk: PBArr; Kp: PPArr; Pm: PIArr; Tmp: PPArr;
    G: TRange; P: PCell; V: TVal; Less, Swap: Boolean; S1, S2: String; Cm: Integer;

 Function Cmp(A, B: Integer): Integer;
 Var X: Integer;
 Begin
  If (Kk^[A]=0) And (Kk^[B]=0) Then X:=0
  Else If Kk^[A]=0 Then X:=2
  Else If Kk^[B]=0 Then X:=-2
  Else If Kk^[A]<>Kk^[B] Then Begin If Kk^[A]<Kk^[B] Then X:=-1 Else X:=1; End
  Else If Kk^[A]=1 Then Begin
   If Kn^[A]<Kn^[B] Then X:=-1 Else If Kn^[A]>Kn^[B] Then X:=1 Else X:=0;
  End Else Begin
   S1:=UpStr(Kp^[A]^.Txt^); S2:=UpStr(Kp^[B]^.Txt^);
   If S1<S2 Then X:=-1 Else If S1>S2 Then X:=1 Else X:=0;
  End;
  If Sh^.SortDesc And (Abs(X)=1) Then X:=-X;
  Cmp:=X;
 End;

Begin
 If Not Sh^.SortOn Then Begin MsgBox('D'#130'finissez d''abord le bloc '#133' trier'); Exit; End;
 G:=Sh^.SortR;
 If (Sh^.SortKey<G.C1) Or (Sh^.SortKey>G.C2) Then Begin
  MsgBox('La cl'#130' de tri est hors du bloc'); Exit;
 End;
 N:=G.R2-G.R1+1;
 If N>4096 Then Begin MsgBox('Bloc trop grand pour le tri (4096 lignes max)'); Exit; End;
 If N<2 Then Exit;
 SaveUndo(Sh);
 GetMem(Kn,SizeOf(TDArr)); GetMem(Kk,SizeOf(TBArr)); GetMem(Kp,SizeOf(TPArr));
 GetMem(Pm,SizeOf(TIArr)); GetMem(Tmp,SizeOf(TPArr));
 EvDepth:=0; Deferred:=False;
 For I:=0 To N-1 Do Begin
  Pm^[I]:=I;
  P:=FindCell(Sh,G.R1+I,Sh^.SortKey);
  Kk^[I]:=0; Kn^[I]:=0; Kp^[I]:=P;
  If P<>Nil Then Begin
   If P^.Kind=CK_FORMULA Then EnsureCalc(P,G.R1+I,Sh^.SortKey);
   If P^.Kind=CK_NUM Then Begin Kk^[I]:=1; Kn^[I]:=P^.Num; End
   Else If (P^.Kind=CK_FORMULA) And (P^.ResK=0) Then Begin Kk^[I]:=1; Kn^[I]:=P^.Num; End
   Else If (P^.Kind=CK_LABEL) And (P^.Txt<>Nil) Then Kk^[I]:=2;
  End;
 End;
 Deferred:=False;
 { tri par insertion (stable) }
 For I:=1 To N-1 Do Begin
  T:=Pm^[I]; J:=I-1;
  While (J>=0) And (Cmp(Pm^[J],T)>0) Do Begin Pm^[J+1]:=Pm^[J]; Dec(J); End;
  Pm^[J+1]:=T;
 End;
 For R:=G.R1 To G.R2 Do
  If Sh^.Rows^[R]=Nil Then Begin
   GetMem(Sh^.Rows^[R],SizeOf(TRowArr));
   FillChar(Sh^.Rows^[R]^,SizeOf(TRowArr),0);
  End;
 For C:=G.C1 To G.C2 Do Begin
  For I:=0 To N-1 Do Tmp^[I]:=Sh^.Rows^[G.R1+Pm^[I]]^[C];
  For I:=0 To N-1 Do Sh^.Rows^[G.R1+I]^[C]:=Tmp^[I];
 End;
 FreeMem(Kn,SizeOf(TDArr)); FreeMem(Kk,SizeOf(TBArr)); FreeMem(Kp,SizeOf(TPArr));
 FreeMem(Pm,SizeOf(TIArr)); FreeMem(Tmp,SizeOf(TPArr));
 Changed;
End;

Function CondTest(Const Cs: String; P: PCell): Boolean;
Var S, Op, Operand, Cv: String; X, Y: Double; Cm: Integer; IsNum, HasVal: Boolean; B: Boolean;
Begin
 S:=TrimStr(Cs);
 Op:='';
 If Copy(S,1,2)='<=' Then Op:='<=' Else If Copy(S,1,2)='>=' Then Op:='>='
 Else If Copy(S,1,2)='<>' Then Op:='<>' Else If Copy(S,1,1)='<' Then Op:='<'
 Else If Copy(S,1,1)='>' Then Op:='>' Else If Copy(S,1,1)='=' Then Op:='=';
 Operand:=TrimStr(Copy(S,Length(Op)+1,255));
 HasVal:=(P<>Nil) And (P^.Kind<>CK_EMPTY);
 IsNum:=TryNumber(Operand,X);
 If IsNum Then Begin
  If (Not HasVal) Then Begin CondTest:=False; Exit; End;
  If P^.Kind=CK_NUM Then Y:=P^.Num
  Else If (P^.Kind=CK_FORMULA) And (P^.ResK=0) Then Y:=P^.Num
  Else Begin CondTest:=(Op='<>'); Exit; End;
  If Y<X Then Cm:=-1 Else If Y>X Then Cm:=1 Else Cm:=0;
  If (Op='') Or (Op='=') Then B:=Cm=0
  Else If Op='<>' Then B:=Cm<>0 Else If Op='<' Then B:=Cm<0
  Else If Op='>' Then B:=Cm>0 Else If Op='<=' Then B:=Cm<=0 Else B:=Cm>=0;
  CondTest:=B;
  Exit;
 End;
 If HasVal Then Begin
  If P^.Kind=CK_LABEL Then Cv:=GetStr(P^.Txt)
  Else If (P^.Kind=CK_FORMULA) And (P^.ResK=1) Then Cv:=GetStr(P^.Res)
  Else Cv:=CellSource(P);
 End Else Cv:='';
 Cv:=UpStr(Cv); Operand:=UpStr(Operand);
 If Cv<Operand Then Cm:=-1 Else If Cv>Operand Then Cm:=1 Else Cm:=0;
 If Op='' Then B:=Copy(Cv,1,Length(Operand))=Operand
 Else If Op='=' Then B:=Cm=0 Else If Op='<>' Then B:=Cm<>0
 Else If Op='<' Then B:=Cm<0 Else If Op='>' Then B:=Cm>0
 Else If Op='<=' Then B:=Cm<=0 Else B:=Cm>=0;
 CondTest:=B;
End;

Function RecordMatches(R: Integer): Boolean;
Var Cr, Cc, Dc, Hc: Integer; AnyRow, RowOk, AnyCond: Boolean; P, H, Q: PCell; Nm: String;
Begin
 AnyRow:=False; AnyCond:=False;
 For Cr:=Sh^.CrR.R1+1 To Sh^.CrR.R2 Do Begin
  RowOk:=True;
  For Cc:=Sh^.CrR.C1 To Sh^.CrR.C2 Do Begin
   P:=FindCell(Sh,Cr,Cc);
   If (P<>Nil) And (P^.Kind<>CK_EMPTY) Then Begin
    AnyCond:=True;
    H:=FindCell(Sh,Sh^.CrR.R1,Cc);
    Nm:=UpStr(GetStr(H^.Txt));
    Dc:=-1;
    For Hc:=Sh^.DbR.C1 To Sh^.DbR.C2 Do Begin
     Q:=FindCell(Sh,Sh^.DbR.R1,Hc);
     If (Q<>Nil) And (UpStr(GetStr(Q^.Txt))=Nm) Then Dc:=Hc;
    End;
    If Dc<0 Then RowOk:=False
    Else If Not CondTest(CellSource(P),FindCell(Sh,R,Dc)) Then RowOk:=False;
   End;
  End;
  If RowOk And AnyCond Then AnyRow:=True;
  AnyCond:=AnyCond;
 End;
 If Not AnyCond Then AnyRow:=True;
 RecordMatches:=AnyRow;
End;

Function QueryReady: Boolean;
Begin
 QueryReady:=False;
 If (Not Sh^.DbOn) Or (Not Sh^.CrOn) Then Begin
  MsgBox('D'#130'finissez le bloc de base et les crit'#138'res'); Exit;
 End;
 QueryReady:=True;
End;

Procedure QueryFind;
Var R: Integer; Fnd: Boolean;
Begin
 If Not QueryReady Then Exit;
 EvDepth:=0; Deferred:=False;
 Fnd:=False;
 R:=Sh^.CurR+1;
 If R<=Sh^.DbR.R1 Then R:=Sh^.DbR.R1+1;
 While (R<=Sh^.DbR.R2) And Not Fnd Do Begin
  If RecordMatches(R) Then Fnd:=True Else Inc(R);
 End;
 Deferred:=False;
 If Fnd Then SetCur(R,Sh^.DbR.C1) Else MsgBox('Aucun autre enregistrement trouv'#130);
End;

Procedure QueryExtract;
Var R, C, Orow, N: Integer; P, Q: PCell;
Begin
 If Not QueryReady Then Exit;
 If Not Sh^.OuOn Then Begin MsgBox('D'#130'finissez le bloc de sortie'); Exit; End;
 SaveUndo(Sh);
 EvDepth:=0; Deferred:=False;
 Orow:=Sh^.OuR.R1; N:=0;
 For C:=Sh^.DbR.C1 To Sh^.DbR.C2 Do Begin
  P:=FindCell(Sh,Sh^.DbR.R1,C);
  If P<>Nil Then Begin
   Q:=MakeCell(Sh,Orow,Sh^.OuR.C1+C-Sh^.DbR.C1);
   If Q<>Nil Then CopyCellInto(Q,P^);
  End;
 End;
 Inc(Orow);
 For R:=Sh^.DbR.R1+1 To Sh^.DbR.R2 Do
  If (Orow<MAX_ROWS) And RecordMatches(R) Then Begin
   For C:=Sh^.DbR.C1 To Sh^.DbR.C2 Do Begin
    P:=FindCell(Sh,R,C);
    If (P<>Nil) And (Sh^.OuR.C1+C-Sh^.DbR.C1<MAX_COLS) Then Begin
     Q:=MakeCell(Sh,Orow,Sh^.OuR.C1+C-Sh^.DbR.C1);
     If Q<>Nil Then CopyCellInto(Q,P^);
    End;
   End;
   Inc(Orow); Inc(N);
  End;
 Deferred:=False;
 Changed;
 MsgBox(IntStr(N)+' enregistrement(s) extrait(s)');
End;

{ ====================================================================== }
{                     STATISTIQUES ET REGRESSION                         }
{ ====================================================================== }

Procedure GatherNums(Const G: TRange; Var A: TAgg);
Begin
 FillChar(A,SizeOf(A),0);
 EvDepth:=0; Deferred:=False;
 AggRange(A,G);
 Deferred:=False;
End;

Procedure DoStats;
Var G: TRange; A: TAgg; M, Vr: Double;
Begin
 GetSel(G);
 If Not PromptRange('Bloc '#133' analyser :',G) Then Exit;
 GatherNums(G,A);
 If A.Cnt=0 Then Begin MsgBox('Aucune valeur num'#130'rique dans le bloc'); Exit; End;
 M:=A.Sum/A.Cnt;
 Vr:=A.SumSq/A.Cnt-M*M; If Vr<0 Then Vr:=0;
 MsgBox('Statistiques du bloc '+RangeStr(G)+'|'+
        'Nombre de valeurs  : '+IntStr(A.Cnt)+'|'+
        'Somme              : '+GenStr(A.Sum,20)+'|'+
        'Moyenne            : '+GenStr(M,20)+'|'+
        'Minimum            : '+GenStr(A.Mn,20)+'|'+
        'Maximum            : '+GenStr(A.Mx,20)+'|'+
        'Variance           : '+GenStr(Vr,20)+'|'+
        'Ecart type         : '+GenStr(Sqrt(Vr),20));
End;

Procedure DoRegress;
Var Gx, Gy: TRange; Gz: TRange; N, I, R, C: Integer; Sx, Sy, Sxx, Sxy, Syy, B, A, R2, Dn: Double;
    Xv, Yv: Array[1..MAXPT] Of Double; Vx, Vy: TVal; Ox, Oy: Integer; P: PCell; Ok: Boolean;
 Procedure PutRow(Rw: Integer; Const Lb: String; X: Double);
 Begin
  P:=MakeCell(Sh,Oy+Rw,Ox);
  If P<>Nil Then SetLabel(P,Lb,AL_DEF);
  P:=MakeCell(Sh,Oy+Rw,Ox+1);
  If P<>Nil Then SetNumber(P,X);
 End;
Begin
 GetSel(Gx);
 If Not PromptRange('Variable ind'#130'pendante (X) :',Gx) Then Exit;
 SetRange(Gy,Sh^.CurR,Sh^.CurC,Sh^.CurR,Sh^.CurC);
 If Not PromptRange('Variable d'#130'pendante (Y) :',Gy) Then Exit;
 SetRange(Gz,Sh^.CurR,Sh^.CurC,Sh^.CurR,Sh^.CurC);
 If Not PromptRange('Sortie (premi'#138're cellule) :',Gz) Then Exit;
 Ox:=Gz.C1; Oy:=Gz.R1;
 If (Ox+1>=MAX_COLS) Or (Oy+4>=MAX_ROWS) Then Begin MsgBox('Sortie hors feuille'); Exit; End;
 N:=0; Sx:=0; Sy:=0; Sxx:=0; Sxy:=0; Syy:=0;
 EvDepth:=0; Deferred:=False;
 R:=Gx.R1; C:=Gx.C1;
 For I:=0 To MaxI(Gx.R2-Gx.R1,0)+MaxI(Gx.C2-Gx.C1,0) Do Begin
  If Gx.R2>Gx.R1 Then Begin R:=Gx.R1+I; C:=Gx.C1; End Else Begin R:=Gx.R1; C:=Gx.C1+I; End;
  Ok:=(R<=Gx.R2) And (C<=Gx.C2);
  If Ok Then Begin
   CellVal(R,C,Vx);
   If Gy.R2>Gy.R1 Then CellVal(Gy.R1+I,Gy.C1,Vy) Else CellVal(Gy.R1,Gy.C1+I,Vy);
   If (Vx.K=0) And (Vy.K=0) And (N<MAXPT) Then Begin
    Inc(N); Sx:=Sx+Vx.N; Sy:=Sy+Vy.N; Sxx:=Sxx+Vx.N*Vx.N; Sxy:=Sxy+Vx.N*Vy.N; Syy:=Syy+Vy.N*Vy.N;
   End;
  End;
 End;
 Deferred:=False;
 If N<2 Then Begin MsgBox('Pas assez de donn'#130'es'); Exit; End;
 Dn:=N*Sxx-Sx*Sx;
 If Dn=0 Then Begin MsgBox('R'#130'gression impossible (X constant)'); Exit; End;
 B:=(N*Sxy-Sx*Sy)/Dn;
 A:=(Sy-B*Sx)/N;
 If (N*Syy-Sy*Sy)=0 Then R2:=1
  Else R2:=(N*Sxy-Sx*Sy)*(N*Sxy-Sx*Sy)/(Dn*(N*Syy-Sy*Sy));
 SaveUndo(Sh);
 PutRow(0,'Observations',N);
 PutRow(1,'Pente',B);
 PutRow(2,'Ordonn'#130'e '#133' l''origine',A);
 PutRow(3,'R carr'#130,R2);
 Changed;
End;

Procedure ShowHelp;
Begin
 LstClear;
 LstAdd('QUATTRO - Clone de Quattro Pro (tableur)');
 LstAdd('');
 LstAdd('Menus : / ou Alt+lettre ; fl'#138'ches, Entr'#130'e, lettre rouge ; Echap');
 LstAdd('Souris : clic sur les menus, la barre d''outils et les cellules.');
 LstAdd('');
 LstAdd('Saisie  : tapez directement dans la cellule courante.');
 LstAdd('  Texte : lettres, ou pr'#130'fixe '' (gauche) " (droite) ^ (centr'#130') \ (r'#130'p'#130'ter)');
 LstAdd('  Valeur: nombre, ou formule : +A1*2   @SOMME(A1..A5)   (A1+B1)/2');
 LstAdd('  Entr'#130'e valide, fl'#138'ches valident et d'#130'placent, Echap annule.');
 LstAdd('');
 LstAdd('F2 Edition  F5 Aller '#133'  F6 Fen'#136'tre suivante  F7 Recherche suivante');
 LstAdd('F9 Recalcul  F10 Graphique  Alt+F5 Annuler  Suppr Efface le bloc');
 LstAdd('Fin + fl'#138'che : saut en fin de bloc    Origine : d'#130'but de feuille');
 LstAdd('Maj+F7 : d'#130'but/fin de s'#130'lection (puis fl'#138'ches). Ctrl+S Sauvegarde,');
 LstAdd('Ctrl+C Copie, Ctrl+Q Quitter, Tab/Maj+Tab : page droite/gauche.');
 LstAdd('');
 LstAdd('Fonctions : SOMME MOYENNE MIN MAX NB ECARTYPE VAR ABS ENT ARRONDI');
 LstAdd('  RACINE EXP LN LOG SIN COS TAN ATAN PI MOD ALEA SI VRAI FAUX');
 LstAdd('  GAUCHE DROITE STXT NBCAR MAJUSCULE MINUSCULE NOMPROPRE CHAINE VALEUR');
 LstAdd('  DATE ANNEE MOIS JOUR MAINTENANT AUJOURDHUI TEMPS HEURE MINUTE');
 LstAdd('  CHOISIR RECHERCHEV RECHERCHEH INDEX VPM VA VC VAN');
 LstAdd('  (les noms anglais SUM, AVG, IF, ... sont aussi accept'#130's)');
 LstAdd('Op'#130'rateurs : + - * / ^ & = <> < > <= >= #AND# #OR# #NOT#');
 LstAdd('Blocs : A1..B5 ou A1:B5, noms de blocs (Edition, Noms).');
 LstAdd('');
 LstAdd('Fichiers : *.WQ1 (format propre) et *.CSV / *.TXT (selon l''extension).');
 ShowList('Aide - Quattro');
 LstClear;
End;

{ ====================================================================== }
{                     EXECUTION DES COMMANDES DE MENU                    }
{ ====================================================================== }

Var
 PopAtX : Integer;

Procedure ClearSel;
Begin
 Sh^.SelOn:=False;
 Sh^.SelMode:=0;
End;

Function AskRange(Const Title: String; Var G: TRange): Boolean;
Begin
 GetSel(G);
 AskRange:=PromptRange(Title,G);
End;

Function AskCell(Const Title: String; Var G: TRange): Boolean;
Begin
 SetRange(G,Sh^.CurR,Sh^.CurC,Sh^.CurR,Sh^.CurC);
 AskCell:=PromptRange(Title,G);
End;

Procedure DoUndo;
Var T: PRowTab; W: Array[0..MAX_COLS-1] Of Byte; St: Array[0..MAX_COLS-1] Of TStyle;
Begin
 If (Not Sh^.HasUndo) Or (Sh^.UndoRows=Nil) Then Begin MsgBox('Rien '#133' annuler'); Exit; End;
 T:=Sh^.Rows; Sh^.Rows:=Sh^.UndoRows; Sh^.UndoRows:=T;
 Move(Sh^.ColW,W,SizeOf(W)); Move(Sh^.UndoW,Sh^.ColW,SizeOf(W)); Move(W,Sh^.UndoW,SizeOf(W));
 Move(Sh^.ColSty,St,SizeOf(St)); Move(Sh^.UndoSty,Sh^.ColSty,SizeOf(St)); Move(St,Sh^.UndoSty,SizeOf(St));
 Sh^.Modified:=True;
 RecalcAll;
End;

Procedure CloseCurrent;
Begin
 If Sh^.Modified Then
  If Not AskYesNo('La feuille '+BaseName(Sh^.Name)+' a '#130't'#130' modifi'#130'e.|Fermer sans sauvegarder ?') Then Exit;
 CloseWin(CurWin);
End;

Procedure DoFmtCmd(Fmt, Dec: Integer; AskDec: Boolean);
Var N: LongInt;
Begin
 N:=DefDec;
 If AskDec Then Begin
  If Not PromptInt('Nombre de d'#130'cimales (0-15) :',N,0,15) Then Exit;
 End Else N:=Dec;
 RangeAskStyle(1,Fmt,N);
End;

Procedure ExecCmd(Cmd: Integer);
Var G, G2: TRange; S, S2: String; N, W: LongInt; I, J, K: Integer; X, Y, Z: Double; Fn: String; P: PCell;
    F: Text; Cmd2: Integer; Old: Integer;
Begin
 Case Cmd Of
  CM_NEW:    NewWindow;
  CM_OPEN:   OpenFileCmd(True);
  CM_LOAD:   OpenFileCmd(False);
  CM_SAVE:   SaveSheet(False);
  CM_SAVEAS: SaveSheet(True);
  CM_SAVEALL: Begin
              Old:=CurWin;
              For I:=1 To NWin Do
               If Win[I]^.Modified Then Begin SwitchWin(I); SaveSheet(False); End;
              SwitchWin(Old);
             End;
  CM_CLOSE:  CloseCurrent;
  CM_CLOSEALL: Begin
              While NWin>1 Do Begin
               If Win[NWin]^.Modified Then Begin
                SwitchWin(NWin);
                If Not AskYesNo('Fermer '+BaseName(Sh^.Name)+' sans sauvegarder ?') Then Exit;
               End;
               CloseWin(NWin);
              End;
              CloseCurrent;
             End;
  CM_ERASE:  Begin
              Fn:=DataDir;
              If FileDialog('Effacement',Fn) Then
               If AskYesNo('Effacer le fichier ?|'+BaseName(Fn)) Then Begin
                Assign(F,Fn);
                {$I-}
                Erase(F);
                {$I+}
                If IOResult<>0 Then MsgBox('Impossible d''effacer le fichier');
               End;
             End;
  CM_DIR:    Begin
              S:=DataDir;
              If PromptStr('R'#130'pertoire de donn'#130'es :',S,60) Then Begin
               If (S<>'') And (S[Length(S)]<>'\') And (S[Length(S)]<>'/') Then S:=S+PSEP;
               {$I-}
               ChDir(S);
               {$I+}
               If IOResult<>0 Then MsgBox('R'#130'pertoire introuvable')
                Else DataDir:=S;
              End;
             End;
  CM_DOS:    Begin
              {$IFDEF FPC}
              MsgBox('L''interpr'#130'teur DOS n''est pas disponible|en mode graphique sous Free Pascal.');
              {$ELSE}
              HideMouse;
              RestoreCrtMode;
              WriteLn('Tapez EXIT pour revenir '#133' Quattro Pro.');
              SwapVectors;
              Exec(GetEnv('COMSPEC'),'');
              SwapVectors;
              SetGraphMode(GetGraphMode);
              ShowMouse;
              {$ENDIF}
             End;
  CM_FM:     Begin
              Fn:=DataDir;
              If FileDialog('Gestionnaire de fichiers',Fn) Then Begin
               S:=ExtOf(Fn);
               If (S='.WQ1') Or (S='.CSV') Or (S='.TXT') Then Begin
                If NewWindow Then Begin
                 If LoadFile(Fn) Then Begin Sh^.Name:=Fn; Sh^.Titled:=True; Sh^.Modified:=False; End
                  Else Begin MsgBox('Impossible de lire le fichier'); CloseWin(CurWin); End;
                End;
               End Else MsgBox('Fichier : '+BaseName(Fn)+'|Type non reconnu par Quattro Pro');
              End;
             End;
  CM_WS_SAVE: Begin
              Assign(F,DataDir+'QUATTRO.WSP');
              {$I-}
              Rewrite(F);
              {$I+}
              If IOResult=0 Then Begin
               For I:=1 To NWin Do WriteLn(F,Win[I]^.Name);
               Close(F);
               MsgBox('Espace de travail sauvegard'#130);
              End Else MsgBox('Impossible d''<'#130'crire l''espace de travail');
             End;
  CM_WS_REST: Begin
              Assign(F,DataDir+'QUATTRO.WSP');
              {$I-}
              Reset(F);
              {$I+}
              If IOResult<>0 Then MsgBox('Aucun espace de travail sauvegard'#130)
              Else Begin
               While Not Eof(F) Do Begin
                ReadLn(F,S);
                If (S<>'') And FileThere(S) And NewWindow Then Begin
                 If LoadFile(S) Then Begin Sh^.Name:=S; Sh^.Titled:=True; Sh^.Modified:=False; End
                  Else CloseWin(CurWin);
                End;
               End;
               Close(F);
              End;
             End;
  CM_SQZE_Y: SqzEmpty:=True;
  CM_SQZE_N: SqzEmpty:=False;
  CM_SQZF_Y: SqzValue:=True;
  CM_SQZF_N: SqzValue:=False;
  CM_SQZV_A: SqzVerA:=True;
  CM_SQZV_B: SqzVerA:=False;
  CM_QUIT:   Begin
              If AllSaved Then QuitFlag:=True
              Else If AskYesNo('Des feuilles ont '#130't'#130' modifi'#130'es.|Quitter sans sauvegarder ?') Then QuitFlag:=True;
             End;

  CM_UNDO:   DoUndo;
  CM_COPY,CM_MOVE: Begin
              If Cmd=CM_COPY Then S:='Bloc '#133' copier :' Else S:='Bloc '#133' d'#130'placer :';
              If Not AskRange(S,G) Then Exit;
              If Cmd=CM_COPY Then Begin
               If Not AskCell('Copier vers :',G2) Then Exit;
              End Else If Not AskCell('D'#130'placer vers :',G2) Then Exit;
              DoCopyMove(G,G2,Cmd=CM_MOVE);
             End;
  CM_CLEAR:  Begin
              GetSel(G);
              SaveUndo(Sh);
              ClearRange(G);
              Changed;
             End;
  CM_INSROW: Begin GetSel(G); SaveUndo(Sh); InsertRows(G.R1,G.R2-G.R1+1); Changed; End;
  CM_INSCOL: Begin GetSel(G); SaveUndo(Sh); InsertCols(G.C1,G.C2-G.C1+1); Changed; End;
  CM_DELROW: Begin GetSel(G); SaveUndo(Sh); DeleteRows(G.R1,G.R2-G.R1+1); ClearSel; Changed; End;
  CM_DELCOL: Begin GetSel(G); SaveUndo(Sh); DeleteCols(G.C1,G.C2-G.C1+1); ClearSel; Changed; End;
  CM_VALUES: Begin If AskRange('Bloc '#133' convertir :',G) Then DoValues(G); End;
  CM_TRANSP: Begin
              If Not AskRange('Bloc source :',G) Then Exit;
              If Not AskCell('Destination :',G2) Then Exit;
              DoTranspose(G,G2);
             End;
  CM_FILL:   Begin
              If Not AskRange('Bloc '#133' remplir :',G) Then Exit;
              S:='0';
              If Not PromptStr('Valeur de d'#130'part :',S,20) Then Exit;
              If Not TryNumber(S,X) Then Begin MsgBox('Valeur invalide'); Exit; End;
              S:='1';
              If Not PromptStr('Incr'#130'ment :',S,20) Then Exit;
              If Not TryNumber(S,Y) Then Begin MsgBox('Valeur invalide'); Exit; End;
              S:='8191';
              If Not PromptStr('Valeur d''arr'#136't :',S,20) Then Exit;
              If Not TryNumber(S,Z) Then Begin MsgBox('Valeur invalide'); Exit; End;
              DoFill(G,X,Y,Z);
             End;
  CM_FIND:   Begin
              S:=SearchStr;
              If Not PromptStr('Rechercher :',S,40) Then Exit;
              If S='' Then Exit;
              SearchStr:=S;
              SrchR:=Sh^.CurR; SrchC:=Sh^.CurC;
              If FindNext(SearchStr,SrchR,SrchC,I,J) Then SetCur(I,J)
               Else MsgBox('Texte introuvable');
             End;
  CM_REPL:   Begin
              If Not AskRange('Bloc '#133' traiter :',G) Then Exit;
              S:='';
              If Not PromptStr('Rechercher :',S,40) Then Exit;
              S2:='';
              If Not PromptStr('Remplacer par :',S2,40) Then Exit;
              N:=DoReplace(G,S,S2);
              If AutoCalc Then RecalcAll;
              MsgBox(IntStr(N)+' cellule(s) modifi'#130'e(s)');
             End;
  CM_NMCREATE: Begin
              S:='';
              If Not PromptStr('Nom du bloc :',S,15) Then Exit;
              If Not ValidName(S) Then Begin MsgBox('Nom invalide'); Exit; End;
              If Not AskRange('Bloc du nom '+UpStr(S)+' :',G) Then Exit;
              CreateName(S,G);
             End;
  CM_NMDEL:  Begin
              S:='';
              If PromptStr('Nom '#133' supprimer :',S,15) Then Begin DeleteName(S); If AutoCalc Then RecalcAll; End;
             End;
  CM_NMDELALL: If AskYesNo('Supprimer tous les noms de blocs ?') Then Begin Sh^.NameCnt:=0; If AutoCalc Then RecalcAll; End;
  CM_NMLIST: Begin
              LstClear;
              If Sh^.NameCnt=0 Then LstAdd('(aucun nom de bloc)');
              For I:=1 To Sh^.NameCnt Do
               LstAdd(Sh^.Names[I].Nm+Rep(' ',17-Length(Sh^.Names[I].Nm))+RangeStr(Sh^.Names[I].R));
              ShowList('Noms de blocs');
              LstClear;
             End;

  CM_AL_G..CM_AL_C: RangeAskStyle(2,Cmd-CM_AL_G,0);
  CM_FM_F:   DoFmtCmd(FM_FIXED,0,True);
  CM_FM_S:   DoFmtCmd(FM_SCI,0,True);
  CM_FM_C:   DoFmtCmd(FM_CURR,0,True);
  CM_FM_COMMA: DoFmtCmd(FM_COMMA,0,True);
  CM_FM_PCT: DoFmtCmd(FM_PCT,0,True);
  CM_FM_G:   DoFmtCmd(FM_GEN,0,False);
  CM_FM_PLUS: DoFmtCmd(FM_PLUS,0,False);
  CM_FM_D1..CM_FM_D1+4: DoFmtCmd(FM_DATE,Cmd-CM_FM_D1+1,False);
  CM_FM_TEXT: DoFmtCmd(FM_TEXT,0,False);
  CM_FM_HID: DoFmtCmd(FM_HIDDEN,0,False);
  CM_FM_T1..CM_FM_T1+3: DoFmtCmd(FM_TIME,Cmd-CM_FM_T1+1,False);
  CM_PROT_Y: RangeAskStyle(4,1,0);
  CM_PROT_N: RangeAskStyle(4,0,0);
  CM_COLW:   Begin
              GetSel(G);
              N:=Sh^.ColW[Sh^.CurC];
              If PromptInt('Largeur de colonne (1-72) :',N,1,72) Then Begin
               SetColWidth(G,N); Sh^.Modified:=True;
              End;
             End;
  CM_CW_SET: Begin
              If Not AskRange('Colonnes :',G) Then Exit;
              N:=Sh^.ColW[G.C1];
              If PromptInt('Largeur de colonne (1-72) :',N,1,72) Then Begin
               SetColWidth(G,N); Sh^.Modified:=True;
              End;
             End;
  CM_CW_RST: Begin
              If Not AskRange('Colonnes :',G) Then Exit;
              SetColWidth(G,DefColW); Sh^.Modified:=True;
             End;
  CM_HIDE:   Begin
              If Not AskRange('Colonnes '#133' masquer :',G) Then Exit;
              SetColWidth(G,0); Sh^.Modified:=True;
              SetCur(Sh^.CurR,Sh^.CurC);
             End;
  CM_UNHIDE: Begin
              SetRange(G,0,0,0,MAX_COLS-1);
              If Not PromptRange('Colonnes '#133' afficher :',G) Then Exit;
              For I:=G.C1 To G.C2 Do If Sh^.ColW[I]=0 Then Sh^.ColW[I]:=DefColW;
              Sh^.Modified:=True;
             End;
  CM_FONT_N: RangeAskStyle(3,0,0);
  CM_FONT_B: RangeAskStyle(3,1,0);
  CM_FONT_U: RangeAskStyle(3,2,0);
  CM_FONT_BU: RangeAskStyle(3,3,0);
  CM_BOLD:   Begin
              P:=FindCell(Sh,Sh^.CurR,Sh^.CurC);
              If (P<>Nil) And ((P^.Fnt And 1)<>0) Then RangeAskStyle(3,0,0) Else RangeAskStyle(3,1,0);
             End;
  CM_FIT:    Begin GetSel(G); FitColumns(G); Sh^.Modified:=True; End;

  CM_GT_BAR..CM_GT_PIE: Begin Sh^.Gr.GType:=Cmd-CM_GT_BAR+1; Sh^.Modified:=True; End;
  CM_GS_X..CM_GS_1+5: Begin
              I:=Cmd-CM_GS_X;
              If Sh^.Gr.SerOn[I] Then G:=Sh^.Gr.Ser[I] Else GetSel(G);
              If PromptRange('Bloc de la s'#130'rie :',G) Then Begin
               Sh^.Gr.Ser[I]:=G; Sh^.Gr.SerOn[I]:=True; Sh^.Modified:=True;
              End;
             End;
  CM_GTT1:   Begin S:=Sh^.Gr.T1; If PromptStr('Premier titre :',S,40) Then Sh^.Gr.T1:=S; End;
  CM_GTT2:   Begin S:=Sh^.Gr.T2; If PromptStr('Second titre :',S,40) Then Sh^.Gr.T2:=S; End;
  CM_GTTX:   Begin S:=Sh^.Gr.TX; If PromptStr('Titre de l''axe X :',S,40) Then Sh^.Gr.TX:=S; End;
  CM_GTTY:   Begin S:=Sh^.Gr.TY; If PromptStr('Titre de l''axe Y :',S,40) Then Sh^.Gr.TY:=S; End;
  CM_GGRID_Y: Sh^.Gr.Grid:=True;
  CM_GGRID_N: Sh^.Gr.Grid:=False;
  CM_GCL_SER: For I:=0 To 6 Do Sh^.Gr.SerOn[I]:=False;
  CM_GCL_TIT: Begin Sh^.Gr.T1:=''; Sh^.Gr.T2:=''; Sh^.Gr.TX:=''; Sh^.Gr.TY:=''; End;
  CM_GCL_ALL: Begin
              For I:=0 To 6 Do Sh^.Gr.SerOn[I]:=False;
              Sh^.Gr.T1:=''; Sh^.Gr.T2:=''; Sh^.Gr.TX:=''; Sh^.Gr.TY:='';
             End;
  CM_GVIEW:  ShowGraph;

  CM_PBLOCK: Begin
              If Sh^.PrintOn Then G:=Sh^.PrintR Else GetSel(G);
              If PromptRange('Bloc '#133' imprimer :',G) Then Begin Sh^.PrintR:=G; Sh^.PrintOn:=True; End;
             End;
  CM_PD_PRN: PrintDest:=1;
  CM_PD_FILE: PrintDest:=2;
  CM_PD_SCR: PrintDest:=3;
  CM_PHDR:   Begin S:=Sh^.Hdr; If PromptStr('Ent'#136'te :',S,60) Then Sh^.Hdr:=S; End;
  CM_PFTR:   Begin S:=Sh^.Ftr; If PromptStr('Pied de page :',S,60) Then Sh^.Ftr:=S; End;
  CM_PWIDTH: Begin N:=PageW; If PromptInt('Largeur de page (20-250) :',N,20,250) Then PageW:=N; End;
  CM_PHEIGHT: Begin N:=PageH; If PromptInt('Hauteur de page (10-250) :',N,10,250) Then PageH:=N; End;
  CM_PGO:    DoPrint;

  CM_SORT_BLOCK: Begin
              If Sh^.SortOn Then G:=Sh^.SortR Else GetSel(G);
              If PromptRange('Bloc '#133' trier :',G) Then Begin
               Sh^.SortR:=G; Sh^.SortOn:=True; Sh^.SortKey:=G.C1;
              End;
             End;
  CM_SORT_KEY: Begin
              SetRange(G,Sh^.CurR,Sh^.SortKey,Sh^.CurR,Sh^.SortKey);
              If Sh^.SortOn Then SetRange(G,Sh^.SortR.R1,Sh^.SortKey,Sh^.SortR.R1,Sh^.SortKey);
              If PromptRange('Cellule de la colonne cl'#130' :',G) Then Sh^.SortKey:=G.C1;
             End;
  CM_SORT_ASC: Sh^.SortDesc:=False;
  CM_SORT_DESC: Sh^.SortDesc:=True;
  CM_SORT_GO: DoSort;
  CM_QSORT:  Begin
              GetSel(G);
              If (G.R1=G.R2) Then Begin MsgBox('S'#130'lectionnez le bloc '#133' trier'); Exit; End;
              Sh^.SortR:=G; Sh^.SortOn:=True; Sh^.SortKey:=G.C1;
              DoSort;
             End;
  CM_Q_BLOCK: Begin
              If Sh^.DbOn Then G:=Sh^.DbR Else GetSel(G);
              If PromptRange('Bloc de base (avec noms de champs) :',G) Then Begin Sh^.DbR:=G; Sh^.DbOn:=True; End;
             End;
  CM_Q_CRIT: Begin
              If Sh^.CrOn Then G:=Sh^.CrR Else GetSel(G);
              If PromptRange('Bloc des crit'#138'res :',G) Then Begin Sh^.CrR:=G; Sh^.CrOn:=True; End;
             End;
  CM_Q_OUT:  Begin
              If Sh^.OuOn Then G:=Sh^.OuR Else GetSel(G);
              If PromptRange('Bloc de sortie :',G) Then Begin Sh^.OuR:=G; Sh^.OuOn:=True; End;
             End;
  CM_Q_FIND: QueryFind;
  CM_Q_EXTR: QueryExtract;
  CM_Q_CLR:  Begin
              If Not Sh^.OuOn Then Begin MsgBox('Aucun bloc de sortie d'#130'fini'); Exit; End;
              SaveUndo(Sh);
              G:=Sh^.OuR;
              If G.R2<=G.R1 Then G.R2:=MaxI(UsedRows(Sh),G.R1);
              ClearRange(G); Changed;
             End;

  CM_RECALC: RecalcAll;
  CM_CALC_AUTO: Begin AutoCalc:=True; RecalcAll; End;
  CM_CALC_MAN: AutoCalc:=False;
  CM_STATS:  DoStats;
  CM_REGR:   DoRegress;

  CM_DBAR_Y: ShowBar:=True;
  CM_DBAR_N: ShowBar:=False;
  CM_DGRID_Y: ShowGrid:=True;
  CM_DGRID_N: ShowGrid:=False;
  CM_DCOLW:  Begin
              N:=DefColW;
              If PromptInt('Largeur par d'#130'faut (1-72) :',N,1,72) Then Begin
               For I:=0 To MAX_COLS-1 Do If Sh^.ColW[I]=DefColW Then Sh^.ColW[I]:=N;
               DefColW:=N;
              End;
             End;
  CM_DDEC:   Begin N:=DefDec; If PromptInt('D'#130'cimales par d'#130'faut (0-15) :',N,0,15) Then DefDec:=N; End;
  CM_DCURR:  Begin S:=CurrSym; If PromptStr('Symbole mon'#130'taire :',S,4) Then CurrSym:=S; End;
  CM_DSEP_P: DecSep:='.';
  CM_DSEP_V: DecSep:=',';
  CM_DSAVE:  SaveIni;

  CM_NEXTWIN: If NWin>1 Then SwitchWin(CurWin Mod NWin+1);
  CM_PREVWIN: If NWin>1 Then Begin
               I:=CurWin-1; If I<1 Then I:=NWin;
               SwitchWin(I);
              End;
  CM_LOCK_H: Begin LockTitles(1); End;
  CM_LOCK_V: Begin LockTitles(2); End;
  CM_LOCK_B: Begin LockTitles(3); End;
  CM_LOCK_N: Begin LockTitles(0); End;
  CM_WIN1..CM_WIN1+MAX_WIN-1: SwitchWin(Cmd-CM_WIN1+1);

  CM_PGLEFT:  MoveCurNav(KEY_CLEFT);
  CM_PGRIGHT: MoveCurNav(KEY_CRIGHT);
  CM_PGUP:    MoveCurNav(KEY_PGUP);
  CM_PGDOWN:  MoveCurNav(KEY_PGDN);
  CM_BARSET:  BarSet:=3-BarSet;
  CM_TB_STYLE: Begin Cmd2:=RunMenu(0,M_STYLE,PopAtX,38); If Cmd2>0 Then ExecCmd(Cmd2); End;
  CM_TB_ALIGN: Begin Cmd2:=RunMenu(0,M_SALIGN,PopAtX,38); If Cmd2>0 Then ExecCmd(Cmd2); End;
  CM_TB_FONT:  Begin Cmd2:=RunMenu(0,M_SFONT,PopAtX,38); If Cmd2>0 Then ExecCmd(Cmd2); End;
  CM_TB_INS:   Begin Cmd2:=RunMenu(0,M_EINS,PopAtX,38); If Cmd2>0 Then ExecCmd(Cmd2); End;
  CM_TB_DEL:   Begin Cmd2:=RunMenu(0,M_EDEL,PopAtX,38); If Cmd2>0 Then ExecCmd(Cmd2); End;
  CM_TB_FMT:   Begin Cmd2:=RunMenu(0,M_SFMT,PopAtX,38); If Cmd2>0 Then ExecCmd(Cmd2); End;
  CM_SUM:     AutoSum;
  CM_HELP:    ShowHelp;
  CM_GOTO:    Begin
               S:='';
               If PromptStr('Aller '#133' la cellule :',S,20) Then Begin
                If ParseRangeStr(S,G) Then Begin ClearSel; SetCur(G.R1,G.C1); End
                 Else MsgBox('R'#130'f'#130'rence invalide');
               End;
              End;
 End;
 If Sh^.CurC>=MAX_COLS Then Sh^.CurC:=MAX_COLS-1;
 EnsureCursorVisible;
End;

{ ====================================================================== }
{                         SAISIE DANS LA CELLULE                         }
{ ====================================================================== }

Procedure UpdateEntryMode;
Var C: Char;
Begin
 If EdMode=1 Then ModeStr:='EDITE'
 Else Begin
  If EdTxt='' Then ModeStr:='ENTREE'
  Else Begin
   C:=EdTxt[1];
   If C In ['0'..'9','+','-','(','@','.','$','#'] Then ModeStr:='VALEUR' Else ModeStr:='ETIQ';
  End;
 End;
End;

Procedure StartEntry(Ch: Word);
Begin
 Editing:=True; EdMode:=0;
 EdTxt:=Chr(Ch); EdPos:=2;
 EndMode:=False;
 UpdateEntryMode;
End;

Procedure StartEdit;
Begin
 Editing:=True; EdMode:=1;
 EdTxt:=CellSource(FindCell(Sh,Sh^.CurR,Sh^.CurC));
 EdPos:=Length(EdTxt)+1;
 ModeStr:='EDITE';
End;

Function CommitEntry: Boolean;
Begin
 CommitEntry:=False;
 SaveUndo(Sh);
 If CommitText(Sh^.CurR,Sh^.CurC,EdTxt) Then Begin
  Editing:=False; ModeStr:='PRET';
  CommitEntry:=True;
 End Else Begin
  Beep;
  EdMode:=1; ModeStr:='ERREUR';
  MsgBox('Erreur dans la formule.|Corrigez-la ou appuyez sur Echap.');
  ModeStr:='EDITE';
 End;
End;

Procedure EntryKey(K: Word);
Begin
 Case K Of
  KEY_ENTER: CommitEntry;
  KEY_ESC:   Begin Editing:=False; ModeStr:='PRET'; End;
  KEY_F2:    Begin EdMode:=1; ModeStr:='EDITE'; End;
  KEY_UP:    If CommitEntry Then MoveCurNav(KEY_UP);
  KEY_DOWN:  If CommitEntry Then MoveCurNav(KEY_DOWN);
  KEY_PGUP,KEY_PGDN: If CommitEntry Then MoveCurNav(K);
  KEY_TAB:   If CommitEntry Then MoveCurNav(KEY_RIGHT);
  KEY_SHTAB: If CommitEntry Then MoveCurNav(KEY_LEFT);
  KEY_LEFT:  If EdMode=1 Then EditKey(EdTxt,EdPos,K,240)
              Else If CommitEntry Then MoveCurNav(KEY_LEFT);
  KEY_RIGHT: If EdMode=1 Then EditKey(EdTxt,EdPos,K,240)
              Else If CommitEntry Then MoveCurNav(KEY_RIGHT);
  Else Begin
   EditKey(EdTxt,EdPos,K,240);
   UpdateEntryMode;
  End;
 End;
End;

{ ====================================================================== }
{                     TRAITEMENT DU CLAVIER (MODE PRET)                  }
{ ====================================================================== }

Procedure OpenTopMenu(M: Integer);
Var Cmd: Integer;
Begin
 Cmd:=RunMenu(M,0,0,0);
 If Cmd>0 Then ExecCmd(Cmd);
End;

Procedure HandleKey(K: Word);
Var Cmd, M: Integer; G: TRange; R, C: Integer;
Begin
 If Editing Then Begin
  M:=AltToMenu(K);
  If M>0 Then Begin If CommitEntry Then OpenTopMenu(M); End
  Else EntryKey(K);
  Exit;
 End;
 M:=AltToMenu(K);
 If M>0 Then Begin OpenTopMenu(M); Exit; End;
 If (K>=32) And (K<=255) Then Begin
  If K=Ord('/') Then OpenTopMenu(1)
  Else If K=Ord('<') Then OpenTopMenu(1)
  Else StartEntry(K);
  Exit;
 End;
 Case K Of
  KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_PGUP,KEY_PGDN,KEY_HOME,KEY_TAB,
  KEY_SHTAB,KEY_CLEFT,KEY_CRIGHT,KEY_CHOME,KEY_CEND: MoveCurNav(K);
  KEY_END:   EndMode:=True;
  KEY_ESC:   Begin ClearSel; EndMode:=False; End;
  KEY_ENTER: ;
  KEY_F1:    ShowHelp;
  KEY_F2:    StartEdit;
  KEY_F5:    ExecCmd(CM_GOTO);
  KEY_F6:    ExecCmd(CM_NEXTWIN);
  KEY_F7:    Begin
              If SearchStr='' Then ExecCmd(CM_FIND)
              Else Begin
               SrchR:=Sh^.CurR; SrchC:=Sh^.CurC;
               If FindNext(SearchStr,SrchR,SrchC,R,C) Then SetCur(R,C)
                Else MsgBox('Texte introuvable');
              End;
             End;
  KEY_SHF7:  Begin
              If Sh^.SelOn Then ClearSel
               Else Begin Sh^.SelOn:=True; Sh^.SelMode:=0; Sh^.AnchR:=Sh^.CurR; Sh^.AnchC:=Sh^.CurC; End;
             End;
  KEY_F9:    RecalcAll;
  KEY_F10:   ExecCmd(CM_GVIEW);
  KEY_ALTF5: ExecCmd(CM_UNDO);
  KEY_DEL:   ExecCmd(CM_CLEAR);
  KEY_CTRL_S: ExecCmd(CM_SAVE);
  KEY_CTRL_Q: ExecCmd(CM_QUIT);
  KEY_CTRL_C: ExecCmd(CM_COPY);
 End;
End;

{ ====================================================================== }
{                       TRAITEMENT DE LA SOURIS                          }
{ ====================================================================== }

Var
 Dragging : Boolean;
 DragMode : Integer;      { 1 cellules, 2 colonnes, 3 lignes }

Function HandleMouse: Boolean;
Var R, C, M, I, B, Cmd, X: Integer; Chg: Boolean;
Begin
 Chg:=False;
 If EdgeDown Then Begin
  If MsY<=15 Then Begin
   M:=TopMenuAt(MsX,MsY);
   If M>0 Then Begin
    If (Not Editing) Or CommitEntry Then OpenTopMenu(M);
   End Else If (MsX>=600) And (MsX<616) Then ExecCmd(CM_HELP)
   Else If MsX>=616 Then ShowBar:=Not ShowBar;
   Chg:=True;
  End Else If ShowBar And (MsY>=16) And (MsY<=41) Then Begin
   B:=0;
   For I:=1 To NBtn Do
    If (MsX>=BtnX1[I]) And (MsX<=BtnX2[I]) And (MsY>=19) And (MsY<=37) Then B:=I;
   If B>0 Then Begin BtnDown:=B; Chg:=True; End;
  End Else If (MsY>=YHdr) And (MsY<YGrid) And (MsX>=GRID_L) And (MsX<=GRID_R) Then Begin
   For I:=0 To NVC-1 Do
    If (MsX>=VX[I]) And (MsX<VX[I]+ColPx(VC[I])) Then Begin
     If (Not Editing) Or CommitEntry Then Begin
      SetCur(Sh^.CurR,VC[I]);
      Sh^.SelOn:=True; Sh^.SelMode:=1; Sh^.AnchR:=0; Sh^.AnchC:=VC[I];
      Dragging:=True; DragMode:=2;
     End;
    End;
   Chg:=True;
  End Else If (MsX<GRID_L) And (MsY>=YGrid) And (MsY<=GRID_BOT) Then Begin
   For I:=0 To NVR-1 Do
    If (MsY>=VY[I]) And (MsY<VY[I]+ROW_H) Then Begin
     If (Not Editing) Or CommitEntry Then Begin
      SetCur(VR[I],Sh^.CurC);
      Sh^.SelOn:=True; Sh^.SelMode:=2; Sh^.AnchR:=VR[I]; Sh^.AnchC:=0;
      Dragging:=True; DragMode:=3;
     End;
    End;
   Chg:=True;
  End Else If (MsX<GRID_L) And (MsY>=YHdr) And (MsY<YGrid) Then Begin
   If (Not Editing) Or CommitEntry Then Begin
    Sh^.SelOn:=True; Sh^.SelMode:=3; Sh^.AnchR:=0; Sh^.AnchC:=0;
   End;
   Chg:=True;
  End Else If GridHit(MsX,MsY,R,C) Then Begin
   If (Not Editing) Or CommitEntry Then Begin
    ClearSel;
    SetCur(R,C);
    Sh^.AnchR:=R; Sh^.AnchC:=C;
    Dragging:=True; DragMode:=1; EndMode:=False;
   End;
   Chg:=True;
  End Else If (MsY>=HSB_Y) And (MsY<=HSB_Y+13) And (MsX<=GRID_R) Then Begin
   X:=(Sh^.CurC*(GRID_R-12)) Div (MAX_COLS-1);
   If MsX<X Then MoveCurNav(KEY_CLEFT) Else If MsX>X+8 Then MoveCurNav(KEY_CRIGHT);
   Chg:=True;
  End Else If (MsX>GRID_R) And (MsY>=YHdr) And (MsY<=HSB_Y+13) Then Begin
   X:=YHdr+(Sh^.CurR*(HSB_Y-YHdr-12)) Div (MAX_ROWS-1);
   If MsY<X Then MoveCurNav(KEY_PGUP) Else If MsY>X+11 Then MoveCurNav(KEY_PGDN);
   Chg:=True;
  End;
 End;
 If EdgeUp Then Begin
  If BtnDown>0 Then Begin
   B:=BtnDown; BtnDown:=0;
   If (MsX>=BtnX1[B]) And (MsX<=BtnX2[B]) And (MsY>=19) And (MsY<=37) Then Begin
    If (Not Editing) Or CommitEntry Then Begin
     PopAtX:=BtnX1[B];
     ExecCmd(BtnCmd[B]);
    End;
   End;
   Chg:=True;
  End;
  If Dragging Then Begin Dragging:=False; Chg:=True; End;
 End;
 If Dragging And ((MsBtn And MB_LEFT)<>0) And (Not EdgeDown) Then Begin
  If DragMode=1 Then Begin
   If GridHit(MsX,MsY,R,C) Then Begin
    If (R<>Sh^.CurR) Or (C<>Sh^.CurC) Then Begin
     If Not Sh^.SelOn Then Begin Sh^.SelOn:=True; Sh^.SelMode:=0; End;
     Sh^.CurR:=R; Sh^.CurC:=C;
     Chg:=True;
    End;
   End Else Begin
    If Not Sh^.SelOn Then Begin Sh^.SelOn:=True; Sh^.SelMode:=0; End;
    If MsY>GRID_BOT Then SetCur(Sh^.CurR+1,Sh^.CurC)
    Else If MsY<YGrid Then SetCur(Sh^.CurR-1,Sh^.CurC);
    If MsX>GRID_R Then SetCur(Sh^.CurR,NextCol(Sh^.CurC,1))
    Else If MsX<GRID_L Then SetCur(Sh^.CurR,NextCol(Sh^.CurC,-1));
    Chg:=True;
   End;
  End Else If DragMode=2 Then Begin
   For I:=0 To NVC-1 Do
    If (MsX>=VX[I]) And (MsX<VX[I]+ColPx(VC[I])) And (VC[I]<>Sh^.CurC) Then Begin
     Sh^.CurC:=VC[I]; Chg:=True;
    End;
  End Else If DragMode=3 Then Begin
   For I:=0 To NVR-1 Do
    If (MsY>=VY[I]) And (MsY<VY[I]+ROW_H) And (VR[I]<>Sh^.CurR) Then Begin
     Sh^.CurR:=VR[I]; Chg:=True;
    End;
  End;
 End;
 HandleMouse:=Chg;
End;

{ ====================================================================== }
{                          BOUCLE PRINCIPALE                             }
{ ====================================================================== }

Procedure MainLoop;
Var K: Word; Dirty: Boolean; Y, M, D, Dw, H, Mi, S, S100: Word; Moved: Boolean;
Begin
 ModeStr:='PRET';
 MsBtn:=0; LastBtn:=0; MsX:=SCR_W Div 2; MsY:=SCR_H Div 2;
 Dragging:=False; BtnDown:=0;
 EnsureCursorVisible;
 Redraw;
 While Not QuitFlag Do Begin
  Dirty:=False;
  If KeyPressed Then Begin
   K:=ReadKeyEx;
   HandleKey(K);
   Dirty:=True;
  End;
  Moved:=PollMouse;
  If Moved Then Begin
   If HandleMouse Then Dirty:=True
    Else If (MsBtn<>LastBtn) Then Dirty:=True
    Else MoveSoftCursor;
   LastBtn:=MsBtn;
  End;
  GetTime(H,Mi,S,S100);
  If Mi<>LastMin Then Dirty:=True;
  If Dirty Then Redraw Else Delay(12);
 End;
End;

{ ====================================================================== }
{                        PROGRAMME PRINCIPAL                             }
{ ====================================================================== }

Procedure InitApp;
Var S: String;
Begin
 GetMem(Lst,SizeOf(TLstArr));
 FillChar(Lst^,SizeOf(TLstArr),0);
 LstN:=0;
 GetMem(PendR,SizeOf(TPend));
 GetMem(PendC,SizeOf(TPend));
 GetDir(0,S);
 If (S<>'') And (S[Length(S)]<>'\') And (S[Length(S)]<>'/') Then S:=S+PSEP;
 DataDir:=S;
 DefColW:=9; DefFmt:=0; DefDec:=2; CurrSym:='$'; DecSep:='.';
 ShowBar:=True; ShowGrid:=False; BarSet:=1; AutoCalc:=True;
 SqzEmpty:=False; SqzValue:=True; SqzVerA:=True;
 PrintDest:=3; PageW:=80; PageH:=60;
 SearchStr:='';
 Editing:=False; EndMode:=False; PromptOn:=False; QuitFlag:=False;
 StatHelp:=''; MenuTop:=0; ModeStr:='PRET';
 LastMin:=99;
 MsSaved:=False;
 LoadIni;
 BuildMenus;
 NWin:=1; CurWin:=1;
 Win[1]:=NewSheet('FEUIL1.WQ1');
 Sh:=Win[1];
 Randomize;
End;

Procedure OpenCommandLine;
Var Fn: String;
Begin
 If ParamCount>=1 Then Begin
  Fn:=ParamStr(1);
  If ExtOf(Fn)='' Then Fn:=Fn+'.WQ1';
  Fn:=FullPath(Fn);
  If FileThere(Fn) Then Begin
   If LoadFile(Fn) Then Begin Sh^.Name:=Fn; Sh^.Titled:=True; Sh^.Modified:=False; End;
  End Else Sh^.Name:=Fn;
 End;
End;

BEGIN
 InitApp;
 InitializeGraphics;
 If MouseDriverFound Then ShowMouse;
 OpenCommandLine;
 MainLoop;
 {$IFDEF FPC}
 EraseSoftCursor;
 {$ELSE}
 HideMouse;
 {$ENDIF}
 CloseGraph;
END.
