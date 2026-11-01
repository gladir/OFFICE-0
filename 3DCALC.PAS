{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @abstract(Target: Turbo Pascal 7, Free Pascal
  @description: Clone de l'application 3D-CALC+
}

Program _3DCALC;

{$IFNDEF FPC}
 {$N+,E+}
 {$M 32768,0,400000}
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
 VERSION_TEXT = '3.31';
 SCR_W        = 640;
 SCR_H        = 480;
 MENU_H       = 18;
 FKEY_H       = 74;
 FKEY_Y       = SCR_H - FKEY_H;

 NSHEET   = 3;
 MAXPAGE  = 12;
 MAXCOL   = 255;
 MAXROW   = 2047;
 MAXPT    = 100;
 MAXSER   = 6;
 MAXKEYS  = 200;

 ROW_H     = 13;
 TB_H      = 16;      { hauteur barre de titre }
 INFO_H    = 17;      { ligne d'information }
 HDR_H     = 13;      { en-tete des colonnes }
 ROWHDR_W  = 32;
 SB_W      = 16;      { largeur des barres de defilement }
 DEFCOLW   = 72;

 INK   = 0;
 PAPER = 15;

 { Codes de touches : caractere = ord ; etendue = 256 + code }
 K_ESC    = 27;
 K_ENTER  = 13;
 K_BKSP   = 8;
 K_TAB    = 9;
 K_UP     = 328;
 K_DOWN   = 336;
 K_LEFT   = 331;
 K_RIGHT  = 333;
 K_HOME   = 327;
 K_END    = 335;
 K_PGUP   = 329;
 K_PGDN   = 337;
 K_INS    = 338;
 K_DEL    = 339;
 K_F1     = 315;      { F1..F10 : 315..324 }
 K_SF1    = 340;      { Shift F1..F10 : 340..349 }
 K_CF1    = 350;      { Ctrl F1..F10 : 350..359 }
 K_CLEFT  = 371;
 K_CRIGHT = 372;
 K_CHOME  = 375;
 K_CEND   = 373;
 K_ALT1   = 376;
 K_STAB   = 271;

 { Types de cellules }
 CK_EMPTY   = 0;
 CK_NUM     = 1;
 CK_TEXT    = 2;
 CK_FORMULA = 3;

 { Types de graphiques }
 CH_LINE = 1;
 CH_BAR  = 2;
 CH_AREA = 3;
 CH_PIE  = 4;
 CH_HIST = 5;
 CH_CUM  = 6;
 CH_SCAT = 7;
 CH_REPORT = 8;
 CH_FUNC = 9;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TMacro = Array[1..MAXKEYS] Of Word;
 PMacro = ^TMacro;
 PStr = ^String;
 PCell = ^TCell;
 TCell = Record
  Kind,Fmt,Align,Attr : Byte;   { Fmt : 0 = precision globale, sinon precision+1 }
  Busy,Err       : Boolean;
  Gen            : LongInt;
  Num            : Double;
  Src,Res        : PStr;
 End;
 PRowArr = ^TRowArr;
 TRowArr = Array[0..MAXCOL] Of PCell;
 PPage = ^TPage;
 TPage = Array[0..MAXROW] Of PRowArr;

 TSheet = Record
  Pg        : Array[0..MAXPAGE] Of PPage;
  ColW      : Array[0..MAXCOL] Of Byte;
  ColP      : Array[0..MAXCOL] Of ShortInt;   { precision de colonne, -1 = globale }
  SMac      : Array[0..25] Of PMacro;
  SMacLen   : Array[0..25] Of Integer;
  FileName  : String[79];
  Named     : Boolean;
  Modified  : Boolean;
  CurP,CurC,CurR : Integer;
  TopR,LeftC     : Integer;
  BlockOn   : Boolean;
  BP,BC1,BR1,BC2,BR2 : Integer;
  AnchC,AnchR : Integer;
  WX,WY,WW,WH : Integer;
  SvX,SvY,SvW,SvH : Integer;
  IsOpen    : Boolean;
  Full      : Boolean;
 End;

 TVal = Record
  K : Byte;                { 0 nombre, 1 texte, 2 erreur }
  N : Double;
  S : String[80];
 End;

 TAgg = Record
  Sum,Min,Max,SS,SNeg,SPos : Double;
  Cnt,Ne,NNeg,NPos,NPos0   : LongInt;
 End;

 TEvent = Record
  Kind : Byte;             { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Key  : Word;
  X,Y,B: LongInt;
 End;

 TRange = Record
  P1,C1,R1,P2,C2,R2 : Integer;
 End;

 TDArr = Array[1..MAXROW+1] Of Double;
 PDArr = ^TDArr;
 TChartD = Array[1..MAXSER,1..MAXPT] Of Double;
 PChartD = ^TChartD;
 TLblArr = Array[1..MAXPT] Of String[12];
 PLblArr = ^TLblArr;

 PTxtArr = ^TTxtArr;
 TTxtArr = Array[1..200] Of String[78];
 PRepArr = ^TRepArr;
 TRepArr = Array[1..40] Of String[64];

 TSerOpt = Record
  Style,Width,Marker : Integer;
 End;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 Sh        : Array[1..NSHEET] Of TSheet;
 CurS      : Integer;                  { feuille active }
 ZOrder    : Array[1..NSHEET] Of Integer;  { dernier = dessus }
 EvalGen   : LongInt;
 AutoCalc,ShowForm,GridOn,DrawCurve : Boolean;
 GenDec    : Integer;                  { precision globale }
 AngleMode : Integer;                  { 0 degres, 1 radians, 2 grades }
 LinkPages,SyncC,SyncR,SyncP,AlertErr : Boolean;
 OutFmt    : Integer;                  { 1 Degas, 2 IMG, 3 PCX, 4 imprimante }
 GraphDir  : String[60];
 DefColWid : Integer;
 Quit      : Boolean;
 NeedDraw  : Boolean;

 { Entree }
 Editing   : Boolean;
 EditBuf   : String;
 EditPos   : Integer;
 EditNew   : Boolean;

 { Souris }
 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;

 { Formules }
 FS        : String;
 FP        : Integer;
 FPg,FRw,FCl,FSh : Integer;
 FSyn,FDry : Boolean;
 Depth     : Integer;

 { Presse-papiers cellule }
 ClipKind  : Byte;
 ClipNum   : Double;
 ClipStr   : String;
 ClipFmt,ClipAlign : Byte;

 { Menus }
 MenuOpen  : Integer;
 MenuHi    : Integer;

 { Macros }
 DeskMac   : Array[1..10] Of PMacro;
 DeskLen   : Array[1..10] Of Integer;
 Recording : Boolean;
 RecBuf    : PMacro;
 RecLen    : Integer;
 PlayBuf   : PMacro;
 PlayLen,PlayPos : Integer;

 { Graphiques }
 GrX       : String[40];
 GrR       : Array[1..MAXSER] Of String[40];
 GrOpt     : Array[1..MAXSER] Of TSerOpt;
 ChartOn   : Boolean;
 ChKind    : Integer;
 ChTitle   : String[40];
 ChXT,ChYT : String[50];
 ChNS,ChNP : Integer;
 ChData    : PChartD;
 ChXs      : PChartD;                  { x des nuages de points (serie 1) }
 ChLbl     : PLblArr;
 ChReg     : Boolean;
 ChSlope,ChIcpt : Double;
 ChX1,ChY1,ChX2,ChY2 : Integer;      { fenetre du graphique }
 ChRep     : PRepArr;
 ChRepN    : Integer;
 BlockHide,TxtASCII,TxtReformat : Boolean;
 ChGrid,ChAuto,ChD3 : Boolean;
 ChYMin,ChYMax : Double;
 EditOrig  : String;
 TxtOn,TxtFocus,TxtIns : Boolean;
 TxtL      : PTxtArr;
 TxtN,TxtCX,TxtCY,TxtTopL : Integer;
 TxtName   : String[79];

 { Divers }
 StatBuf   : PDArr;
 StatBuf2  : PDArr;
 LastFind  : String[40];
 LastRepeat: String[80];
 Dragging  : Integer;                  { 0 aucun,1 titre,2 taille,3 selection,4 curseur graphique }
 DragDX,DragDY : Integer;
 OutName   : String[79];
 LastClickT: LongInt;
 LastClickS: Integer;

{ ====================================================================== }
{                  GRAPHIQUE / SOURIS (squelette)                        }
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

{ ====================================================================== }
{                       UTILITAIRES GENERAUX                             }
{ ====================================================================== }

Function IntStr(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 IntStr:=S;
End;

Function Upper(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 Upper:=S;
End;

Function Lower(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do
  If S[I] In ['A'..'Z'] Then S[I]:=Chr(Ord(S[I])+32);
 Lower:=S;
End;

Function TrimStr(S: String): String;
Begin
 While (Length(S)>0) And (S[1]=' ') Do Delete(S,1,1);
 While (Length(S)>0) And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
 TrimStr:=S;
End;

Function Min2(A,B: LongInt): LongInt;
Begin
 If A<B Then Min2:=A Else Min2:=B;
End;

Function Max2(A,B: LongInt): LongInt;
Begin
 If A>B Then Max2:=A Else Max2:=B;
End;

Function AllocStr(Const S: String): PStr;
Var P: PStr;
Begin
 GetMem(P,Length(S)+1);
 Move(S,P^,Length(S)+1);
 AllocStr:=P;
End;

Procedure FreeStr(Var P: PStr);
Begin
 If P<>Nil Then FreeMem(P,Length(P^)+1);
 P:=Nil;
End;

Function ColName(C: Integer): String;
Begin
 If C<26 Then ColName:=Chr(65+C)
        Else ColName:=Chr(65+(C Div 26)-1)+Chr(65+(C Mod 26));
End;

Function FormatNum(X: Double; Dec: Integer): String;
Var S: String;
Begin
 If Abs(X)>=1E15 Then Begin
  Str(X:14,S);
  FormatNum:=TrimStr(S);
  Exit;
 End;
 If Dec>=0 Then Begin
  Str(X:0:Dec,S);
 End Else Begin
  Str(X:0:4,S);
  If Pos('.',S)>0 Then Begin
   While S[Length(S)]='0' Do Delete(S,Length(S),1);
   If S[Length(S)]='.' Then Delete(S,Length(S),1);
  End;
  If ((S='0') Or (S='-0')) And (X<>0) Then Begin
   Str(X:12,S);
   S:=TrimStr(S);
  End;
 End;
 If S='-0' Then S:='0';
 FormatNum:=S;
End;

Function NumToStr(X: Double): String;
Var S: String;
Begin
 If Abs(X)>=1E15 Then Begin Str(X:20,S);NumToStr:=TrimStr(S);Exit;End;
 Str(X:0:10,S);
 If Pos('.',S)>0 Then Begin
  While S[Length(S)]='0' Do Delete(S,Length(S),1);
  If S[Length(S)]='.' Then Delete(S,Length(S),1);
 End;
 If (S='-0') Or (S='') Then S:='0';
 NumToStr:=S;
End;

Function RealOf(Const S: String; Var X: Double): Boolean;
Var I,Code: Integer; T: String;
Begin
 RealOf:=False;
 T:=TrimStr(S);
 If T='' Then Exit;
 If Not (T[1] In ['0'..'9','-','+','.']) Then Exit;
 For I:=1 To Length(T) Do
  If Not (T[I] In ['0'..'9','-','+','.','E','e']) Then Exit;
 If T[1]='.' Then T:='0'+T;
 If (Length(T)>1) And (T[1]='-') And (T[2]='.') Then Insert('0',T,2);
 If T[Length(T)]='.' Then T:=T+'0';
 Val(T,X,Code);
 RealOf:=(Code=0);
End;

Function FileExists(Const N: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F,N);
 Reset(F,1);
 {$I+}
 If IOResult=0 Then Begin
  Close(F);
  FileExists:=True;
 End Else FileExists:=False;
End;

Function ShortName(Const N: String): String;
Var I: Integer; S: String;
Begin
 S:=N;
 I:=Length(S);
 While (I>0) And (S[I]<>'\') And (S[I]<>'/') And (S[I]<>':') Do Dec(I);
 ShortName:=Copy(S,I+1,255);
End;

{ ====================================================================== }
{                         STOCKAGE DES CELLULES                          }
{ ====================================================================== }

Function GetCell(S,P,C,R: Integer): PCell;
Var Rw: PRowArr;
Begin
 GetCell:=Nil;
 If (P<0) Or (P>MAXPAGE) Or (C<0) Or (C>MAXCOL) Or (R<0) Or (R>MAXROW) Then Exit;
 If Sh[S].Pg[P]=Nil Then Exit;
 Rw:=Sh[S].Pg[P]^[R];
 If Rw=Nil Then Exit;
 GetCell:=Rw^[C];
End;

Function MakeCell(S,P,C,R: Integer): PCell;
Var Rw: PRowArr; Cl: PCell;
Begin
 MakeCell:=Nil;
 If (P<0) Or (P>MAXPAGE) Or (C<0) Or (C>MAXCOL) Or (R<0) Or (R>MAXROW) Then Exit;
 If Sh[S].Pg[P]=Nil Then Begin
  New(Sh[S].Pg[P]);
  FillChar(Sh[S].Pg[P]^,SizeOf(TPage),0);
 End;
 Rw:=Sh[S].Pg[P]^[R];
 If Rw=Nil Then Begin
  New(Rw);
  FillChar(Rw^,SizeOf(TRowArr),0);
  Sh[S].Pg[P]^[R]:=Rw;
 End;
 Cl:=Rw^[C];
 If Cl=Nil Then Begin
  New(Cl);
  FillChar(Cl^,SizeOf(TCell),0);
  Rw^[C]:=Cl;
 End;
 MakeCell:=Cl;
End;

Procedure FreeCellData(Cl: PCell);
Begin
 FreeStr(Cl^.Src);
 FreeStr(Cl^.Res);
End;

Procedure KillCell(S,P,C,R: Integer);
Var Cl: PCell;
Begin
 Cl:=GetCell(S,P,C,R);
 If Cl=Nil Then Exit;
 FreeCellData(Cl);
 Dispose(Cl);
 Sh[S].Pg[P]^[R]^[C]:=Nil;
End;

Procedure KillRow(S,P,R: Integer);
Var C: Integer; Rw: PRowArr;
Begin
 If (Sh[S].Pg[P]=Nil) Or (R<0) Or (R>MAXROW) Then Exit;
 Rw:=Sh[S].Pg[P]^[R];
 If Rw=Nil Then Exit;
 For C:=0 To MAXCOL Do
  If Rw^[C]<>Nil Then Begin
   FreeCellData(Rw^[C]);
   Dispose(Rw^[C]);
  End;
 Dispose(Rw);
 Sh[S].Pg[P]^[R]:=Nil;
End;

Procedure KillPage(S,P: Integer);
Var R: Integer;
Begin
 If Sh[S].Pg[P]=Nil Then Exit;
 For R:=0 To MAXROW Do KillRow(S,P,R);
 Dispose(Sh[S].Pg[P]);
 Sh[S].Pg[P]:=Nil;
End;

Procedure Invalidate;
Begin
 If AutoCalc Then Inc(EvalGen);
End;

Procedure Touch;
Begin
 Sh[CurS].Modified:=True;
 Invalidate;
End;

Procedure ResetSheet(S: Integer);
Var P,C: Integer;
Begin
 For P:=0 To MAXPAGE Do KillPage(S,P);
 For C:=0 To MAXCOL Do Begin Sh[S].ColW[C]:=DefColWid;Sh[S].ColP[C]:=-1;End;
 Sh[S].FileName:='NONAME.3DD';
 Sh[S].Named:=False;
 Sh[S].Modified:=False;
 Sh[S].CurP:=0;Sh[S].CurC:=0;Sh[S].CurR:=0;
 Sh[S].TopR:=0;Sh[S].LeftC:=0;
 Sh[S].BlockOn:=False;
 Inc(EvalGen);
End;

{ ====================================================================== }
{                       MOTEUR DE FORMULES                               }
{ ====================================================================== }

Var
 CorA,CorB : PDArr;
 CapSlot,CapN1,CapN2 : Integer;
 LastRg    : TRange;
 RfHasPg,RfAbsP,RfAbsC,RfAbsR : Boolean;

Procedure Expr(Var V: TVal); Forward;
Procedure EvalCell(S,P,C,R: Integer; Var V: TVal); Forward;
Function CellSource(S,P,C,R: Integer): String; Forward;

Function Pk: Char;
Begin
 If FP<=Length(FS) Then Pk:=FS[FP] Else Pk:=#0;
End;

Procedure SkipSp;
Begin
 While (FP<=Length(FS)) And (FS[FP]=' ') Do Inc(FP);
End;

Function ToNum(Const V: TVal): Double;
Var X: Double;
Begin
 If V.K=0 Then ToNum:=V.N
 Else If (V.K=1) And RealOf(V.S,X) Then ToNum:=X
 Else ToNum:=0;
End;

Function ToStr(Const V: TVal): String;
Begin
 If V.K=1 Then ToStr:=V.S Else ToStr:=FormatNum(V.N,-1);
End;

{ Reference : [$][page][$]colonne[$]ligne ; la page est facultative }
Function TryRef(DefP: Integer; Var P,C,R: Integer): Boolean;
Var Save,N,L1,L2,Nd: Integer;
Begin
 TryRef:=False;
 Save:=FP;
 P:=DefP;
 RfHasPg:=False;RfAbsP:=False;RfAbsC:=False;RfAbsR:=False;
 If Pk='$' Then Begin RfAbsP:=True;Inc(FP);End;
 If Pk In ['0'..'9'] Then Begin
  N:=0;Nd:=0;
  While (Pk In ['0'..'9']) And (Nd<4) Do Begin
   N:=N*10+Ord(Pk)-48;Inc(Nd);Inc(FP);
  End;
  If Pk='!' Then Inc(FP);
  If Pk='$' Then Begin RfAbsC:=True;Inc(FP);End;
  P:=N;RfHasPg:=True;
  If P>MAXPAGE Then Begin FP:=Save;Exit;End;
 End Else Begin
  If RfAbsP Then Begin RfAbsC:=True;RfAbsP:=False;End;
 End;
 If Not (UpCase(Pk) In ['A'..'Z']) Then Begin FP:=Save;Exit;End;
 L1:=Ord(UpCase(Pk))-65;
 Inc(FP);
 If UpCase(Pk) In ['A'..'Z'] Then Begin
  L2:=Ord(UpCase(Pk))-65;
  Inc(FP);
  C:=(L1+1)*26+L2;
 End Else C:=L1;
 If Pk='$' Then Begin RfAbsR:=True;Inc(FP);End;
 If Not (Pk In ['0'..'9']) Then Begin FP:=Save;Exit;End;
 R:=0;
 N:=0;
 While Pk In ['0'..'9'] Do Begin
  If N<5 Then R:=R*10+Ord(Pk)-48;
  Inc(N);
  Inc(FP);
 End;
 If (UpCase(Pk) In ['A'..'Z','_']) Or (Pk='(') Then Begin FP:=Save;Exit;End;
 If (C>MAXCOL) Or (R>MAXROW) Then Begin FP:=Save;Exit;End;
 TryRef:=True;
End;

Procedure AggAdd(Var Ag: TAgg; X: Double);
Begin
 Ag.Sum:=Ag.Sum+X;
 Ag.SS:=Ag.SS+X*X;
 Inc(Ag.Cnt);
 If X<Ag.Min Then Ag.Min:=X;
 If X>Ag.Max Then Ag.Max:=X;
 If X<0 Then Begin Ag.SNeg:=Ag.SNeg+X;Inc(Ag.NNeg);End
 Else Begin Ag.SPos:=Ag.SPos+X;Inc(Ag.NPos);Inc(Ag.NPos0);End;
 If X>0 Then Begin End;
End;

Procedure AggInit(Var Ag: TAgg);
Begin
 FillChar(Ag,SizeOf(Ag),0);
 Ag.Min:=1E300;Ag.Max:=-1E300;
End;

Function TryRange(Var Ag: TAgg): Boolean;
Var Save,P1,C1,R1,P2,C2,R2,P,C,R,T,Slot: Integer; V: TVal; Cl: PCell; Rw: PRowArr;
Begin
 TryRange:=False;
 Save:=FP;
 If Not TryRef(FPg,P1,C1,R1) Then Exit;
 SkipSp;
 If Pk<>':' Then Begin FP:=Save;Exit;End;
 Inc(FP);
 SkipSp;
 If Not TryRef(P1,P2,C2,R2) Then Begin FP:=Save;Exit;End;
 TryRange:=True;
 If P1>P2 Then Begin T:=P1;P1:=P2;P2:=T;End;
 If C1>C2 Then Begin T:=C1;C1:=C2;C2:=T;End;
 If R1>R2 Then Begin T:=R1;R1:=R2;R2:=T;End;
 LastRg.P1:=P1;LastRg.C1:=C1;LastRg.R1:=R1;LastRg.P2:=P2;LastRg.C2:=C2;LastRg.R2:=R2;
 If FDry Then Exit;
 Slot:=CapSlot;CapSlot:=0;
 For P:=P1 To P2 Do Begin
  If Sh[FSh].Pg[P]=Nil Then Continue;
  For R:=R1 To R2 Do Begin
   Rw:=Sh[FSh].Pg[P]^[R];
   If Rw=Nil Then Continue;
   For C:=C1 To C2 Do Begin
    Cl:=Rw^[C];
    If Cl=Nil Then Continue;
    If Cl^.Kind<>CK_EMPTY Then Inc(Ag.Ne);
    V.K:=3;
    If Cl^.Kind=CK_NUM Then Begin V.K:=0;V.N:=Cl^.Num;End
    Else If Cl^.Kind=CK_FORMULA Then EvalCell(FSh,P,C,R,V);
    If V.K=0 Then Begin
     AggAdd(Ag,V.N);
     If Slot=1 Then Begin If CapN1<MAXROW+1 Then Begin Inc(CapN1);CorA^[CapN1]:=V.N;End;End
     Else If Slot=2 Then Begin If CapN2<MAXROW+1 Then Begin Inc(CapN2);CorB^[CapN2]:=V.N;End;End;
    End;
   End;
  End;
 End;
End;

Function Fact(N: Integer): Double;
Var I: Integer; X: Double;
Begin
 X:=1;
 For I:=2 To N Do X:=X*I;
 Fact:=X;
End;

Function PowerOf(X,Y: Double; Var Ok: Boolean): Double;
Begin
 Ok:=True;
 PowerOf:=0;
 If Y=0 Then Begin PowerOf:=1;Exit;End;
 If X=0 Then Begin
  If Y<0 Then Ok:=False;
  Exit;
 End;
 If (X<0) And (Y<>Int(Y)) Then Begin Ok:=False;Exit;End;
 If Abs(Y*Ln(Abs(X)))>600 Then Begin Ok:=False;Exit;End;
 If X<0 Then Begin
  If Odd(Round(Y)) Then PowerOf:=-Exp(Y*Ln(-X)) Else PowerOf:=Exp(Y*Ln(-X));
 End Else PowerOf:=Exp(Y*Ln(X));
End;

Function CmpStr(Const A,B: String): Integer;
Var UA,UB: String;
Begin
 UA:=Upper(A);UB:=Upper(B);
 If UA<UB Then CmpStr:=-1 Else If UA>UB Then CmpStr:=1 Else CmpStr:=0;
End;

Function ToRad(X: Double): Double;
Begin
 Case AngleMode Of
  0: ToRad:=X*Pi/180;
  2: ToRad:=X*Pi/200;
  Else ToRad:=X;
 End;
End;

Function FromRad(X: Double): Double;
Begin
 Case AngleMode Of
  0: FromRad:=X*180/Pi;
  2: FromRad:=X*200/Pi;
  Else FromRad:=X;
 End;
End;

Function JDN(Y,M,D: LongInt): LongInt;
Var A,YY,MM: LongInt;
Begin
 A:=(14-M) Div 12;
 YY:=Y+4800-A;
 MM:=M+12*A-3;
 JDN:=D+(153*MM+2) Div 5+365*YY+YY Div 4-YY Div 100+YY Div 400-32045;
End;

Procedure FromJDN(J: LongInt; Var Y,M,D: LongInt);
Var A,B,C,Dd,E,Mm: LongInt;
Begin
 A:=J+32044;
 B:=(4*A+3) Div 146097;
 C:=A-146097*B Div 4;
 Dd:=(4*C+3) Div 1461;
 E:=C-1461*Dd Div 4;
 Mm:=(5*E+2) Div 153;
 D:=E-(153*Mm+2) Div 5+1;
 M:=Mm+3-12*(Mm Div 10);
 Y:=100*B+Dd-4800+Mm Div 10;
End;

Function Pad2(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 If Length(S)<2 Then S:='0'+S;
 Pad2:=S;
End;

Const
 MonthNames : Array[1..12] Of String[9] = ('January','February','March','April','May','June','July','August','September','October','November','December');
 DayNames   : Array[0..6] Of String[9] = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');

Function HighUsed(S: Integer; What: Integer): Integer;
Var P,R,C,MaxP,MaxR,MaxC: Integer; Rw: PRowArr;
Begin
 MaxP:=0;MaxR:=0;MaxC:=0;
 For P:=0 To MAXPAGE Do Begin
  If Sh[S].Pg[P]=Nil Then Continue;
  For R:=0 To MAXROW Do Begin
   Rw:=Sh[S].Pg[P]^[R];
   If Rw=Nil Then Continue;
   For C:=0 To MAXCOL Do
    If Rw^[C]<>Nil Then Begin
     If P>MaxP Then MaxP:=P;
     If R>MaxR Then MaxR:=R;
     If C>MaxC Then MaxC:=C;
    End;
  End;
 End;
 Case What Of
  1: HighUsed:=MaxC;
  2: HighUsed:=MaxR;
  Else HighUsed:=MaxP;
 End;
End;

Function MatchWild(Const Pat,S: String): Boolean;
{ ? = un caractere quelconque, * = le reste est ignore }
Var I: Integer; P,T: String;
Begin
 MatchWild:=False;
 P:=Upper(Pat);T:=Upper(S);
 For I:=1 To Length(P) Do Begin
  If P[I]='*' Then Begin MatchWild:=True;Exit;End;
  If I>Length(T) Then Exit;
  If (P[I]<>'?') And (P[I]<>T[I]) Then Exit;
 End;
 MatchWild:=(Length(P)=Length(T));
End;

Function KnownFunc(Const Nm: String): Boolean;
Var K: String;
Begin
 K:='|'+Nm+'|';
 KnownFunc:=
  (Pos(K,'|SUM|AVG|MIN|MAX|COUNT|COUNTNEG|COUNTPOS|COUNTPOS0|COUNTS|STD|STDS|VAR|VARS|SUMNEG|SUMPOS|COR|')>0) Or
  (Pos(K,'|ABS|ACOS|ASIN|ATAN|COS|EXP|FACT|INT|LN|LOG|MOD|RND|ROUND|SGN|SIN|SQR|TAN|')>0) Or
  (Pos(K,'|CTERM|DDB|FV|NPV|PMT|PV|RATE|SLN|SYD|TERM|')>0) Or
  (Pos(K,'|CHR|CODE|EXACT|FIND|LEFT|LEN|LOWER|MID|PROPER|REPEAT|REPLACE|RIGHT|STR|TRIM|UPPER|VAL|')>0) Or
  (Pos(K,'|DATE|DAY|DAY$|DATE$|MONTH|MONTH$|YEAR|NOW|HOUR|MINUTE|SECOND|TIME|TIME$|')>0) Or
  (Pos(K,'|IF|ISNUMBER|ISSTRING|HEX$|HEX|CELL|SYS|FROW|FCOL|FPAGE|HLOOKUP|VLOOKUP|C|K|R|P|')>0);
End;

Procedure CallFunc(Const Nm: String; Var V: TVal);
Var A: Array[1..6] Of TVal; Rgs: Array[1..6] Of TRange; IsRg: Array[1..6] Of Boolean;
    NA,I,K: Integer; Ag: TAgg; T: TVal; X,Y,Z,W: Double; AErr,Ok: Boolean; SV: String;
    Cl: PCell; P,C,R: Integer; DY,DM,DD,DW,TH,TM,TS,TS100: Word;
Begin
 V.K:=0;V.N:=0;V.S:='';
 AggInit(Ag);
 NA:=0;
 AErr:=False;
 For I:=1 To 6 Do Begin A[I].K:=0;A[I].N:=0;A[I].S:='';IsRg[I]:=False;End;
 CapN1:=0;CapN2:=0;
 Inc(FP);
 SkipSp;
 If Pk<>')' Then Repeat
  Inc(NA);
  I:=NA;
  If I>6 Then I:=6;
  SkipSp;
  CapSlot:=0;
  If Nm='COR' Then CapSlot:=NA
  Else If (Nm='NPV') And (NA=2) Then CapSlot:=1;
  If (Pk=',') Or (Pk=')') Then Begin
   A[I].K:=0;A[I].N:=0;
  End Else If TryRange(Ag) Then Begin
   A[I].K:=0;A[I].N:=Ag.Sum;
   IsRg[I]:=True;Rgs[I]:=LastRg;
  End Else Begin
   If Nm='CELL' Then Begin
    If TryRef(FPg,P,C,R) Then Begin
     V.K:=1;V.S:=Copy(CellSource(FSh,P,C,R),1,80);
     SkipSp;
     If Pk=')' Then Inc(FP) Else FSyn:=True;
     Exit;
    End;
   End;
   Expr(T);
   If NA<=6 Then A[I]:=T;
   If T.K=0 Then AggAdd(Ag,T.N)
   Else If T.K=2 Then AErr:=True;
  End;
  CapSlot:=0;
  SkipSp;
  If Pk=',' Then Inc(FP) Else Break;
 Until FSyn;
 SkipSp;
 If Pk<>')' Then Begin FSyn:=True;Exit;End;
 Inc(FP);
 If NA>6 Then NA:=6;
 If FDry Then Begin
  If Not KnownFunc(Nm) Then FSyn:=True;
  Exit;
 End;
 If AErr And (Nm<>'IF') And (Nm<>'ISNUMBER') And (Nm<>'ISSTRING') Then Begin V.K:=2;Exit;End;
 X:=ToNum(A[1]);Y:=ToNum(A[2]);Z:=ToNum(A[3]);W:=ToNum(A[4]);
 If Nm='SUM' Then V.N:=Ag.Sum
 Else If Nm='AVG' Then Begin If Ag.Cnt=0 Then V.K:=2 Else V.N:=Ag.Sum/Ag.Cnt;End
 Else If Nm='MIN' Then Begin If Ag.Cnt=0 Then V.N:=0 Else V.N:=Ag.Min;End
 Else If Nm='MAX' Then Begin If Ag.Cnt=0 Then V.N:=0 Else V.N:=Ag.Max;End
 Else If Nm='COUNT' Then V.N:=Ag.Cnt
 Else If Nm='COUNTNEG' Then V.N:=Ag.NNeg
 Else If Nm='COUNTPOS' Then V.N:=Ag.NPos-0
 Else If Nm='COUNTPOS0' Then V.N:=Ag.NPos0
 Else If Nm='COUNTS' Then V.N:=Ag.Ne
 Else If Nm='SUMNEG' Then V.N:=Ag.SNeg
 Else If Nm='SUMPOS' Then V.N:=Ag.SPos
 Else If (Nm='STD') Or (Nm='VAR') Then Begin
  If Ag.Cnt<1 Then V.K:=2 Else Begin
   X:=Ag.SS/Ag.Cnt-Sqr(Ag.Sum/Ag.Cnt);
   If X<0 Then X:=0;
   If Nm='VAR' Then V.N:=X Else V.N:=Sqrt(X);
  End;
 End
 Else If (Nm='STDS') Or (Nm='VARS') Then Begin
  If Ag.Cnt<2 Then V.K:=2 Else Begin
   X:=(Ag.SS-Ag.Sum*Ag.Sum/Ag.Cnt)/(Ag.Cnt-1);
   If X<0 Then X:=0;
   If Nm='VARS' Then V.N:=X Else V.N:=Sqrt(X);
  End;
 End
 Else If Nm='COR' Then Begin
  K:=Min2(CapN1,CapN2);
  If K<2 Then V.K:=2 Else Begin
   X:=0;Y:=0;Z:=0;W:=0;
   For I:=1 To K Do Begin X:=X+CorA^[I];Y:=Y+CorB^[I];End;
   X:=X/K;Y:=Y/K;
   Ag.Sum:=0;Ag.SS:=0;Ag.SNeg:=0;
   For I:=1 To K Do Begin
    Ag.Sum:=Ag.Sum+(CorA^[I]-X)*(CorB^[I]-Y);
    Ag.SS:=Ag.SS+Sqr(CorA^[I]-X);
    Ag.SNeg:=Ag.SNeg+Sqr(CorB^[I]-Y);
   End;
   If (Ag.SS<=0) Or (Ag.SNeg<=0) Then V.K:=2 Else V.N:=Ag.Sum/Sqrt(Ag.SS*Ag.SNeg);
  End;
 End
 Else If Nm='ABS' Then V.N:=Abs(X)
 Else If Nm='ACOS' Then Begin
  If Abs(X)>1 Then V.K:=2 Else If X=1 Then V.N:=0 Else If X=-1 Then V.N:=FromRad(Pi)
  Else V.N:=FromRad(Pi/2-ArcTan(X/Sqrt(1-X*X)));
 End
 Else If Nm='ASIN' Then Begin
  If Abs(X)>1 Then V.K:=2 Else If X=1 Then V.N:=FromRad(Pi/2) Else If X=-1 Then V.N:=-FromRad(Pi/2)
  Else V.N:=FromRad(ArcTan(X/Sqrt(1-X*X)));
 End
 Else If Nm='ATAN' Then V.N:=FromRad(ArcTan(X))
 Else If Nm='COS' Then V.N:=Cos(ToRad(X))
 Else If Nm='SIN' Then V.N:=Sin(ToRad(X))
 Else If Nm='TAN' Then Begin
  If Abs(Cos(ToRad(X)))<1E-12 Then V.K:=2 Else V.N:=Sin(ToRad(X))/Cos(ToRad(X));
 End
 Else If Nm='EXP' Then Begin If X>600 Then V.K:=2 Else V.N:=Exp(X);End
 Else If Nm='FACT' Then Begin If (X<0) Or (X>170) Then V.K:=2 Else V.N:=Fact(Round(X));End
 Else If Nm='INT' Then Begin If Abs(X)>1E15 Then V.N:=X Else V.N:=Int(X);End
 Else If Nm='LN' Then Begin If X<=0 Then V.K:=2 Else V.N:=Ln(X);End
 Else If Nm='LOG' Then Begin If X<=0 Then V.K:=2 Else V.N:=Ln(X)/Ln(10);End
 Else If Nm='MOD' Then Begin
  If NA<2 Then Y:=1;
  If Y=0 Then V.K:=2 Else V.N:=X-Int(X/Y)*Y;
 End
 Else If Nm='RND' Then Begin If NA=0 Then V.N:=Random Else V.N:=Random*X;End
 Else If Nm='ROUND' Then Begin
  K:=0;
  If NA>=2 Then K:=Round(Y);
  If (K<0) Or (K>8) Then K:=0;
  If Abs(X)>1E9 Then V.N:=X Else Begin
   Y:=1;
   For I:=1 To K Do Y:=Y*10;
   If X>=0 Then V.N:=Int(X*Y+0.5)/Y Else V.N:=-Int(-X*Y+0.5)/Y;
  End;
 End
 Else If Nm='SGN' Then Begin If X>0 Then V.N:=1 Else If X<0 Then V.N:=-1;End
 Else If Nm='SQR' Then Begin If X<0 Then V.K:=2 Else V.N:=Sqrt(X);End
 Else If Nm='PMT' Then Begin
  If (Y=0) Or (Z<=0) Then V.K:=2 Else Begin
   W:=PowerOf(1+Y,-Z,Ok);
   V.N:=X*Y/(1-W);
  End;
 End
 Else If Nm='FV' Then Begin
  If Y=0 Then V.N:=X*Z Else Begin W:=PowerOf(1+Y,Z,Ok);V.N:=X*(W-1)/Y;End;
 End
 Else If Nm='PV' Then Begin
  If Y=0 Then V.N:=X*Z Else Begin W:=PowerOf(1+Y,-Z,Ok);V.N:=X*(1-W)/Y;End;
 End
 Else If Nm='SLN' Then Begin If Z=0 Then V.K:=2 Else V.N:=(X-Y)/Z;End
 Else If Nm='SYD' Then Begin
  If Z<=0 Then V.K:=2 Else V.N:=(X-Y)*(Z-W+1)*2/(Z*(Z+1));
 End
 Else If Nm='DDB' Then Begin
  Ag.Sum:=X;V.N:=0;
  For I:=1 To Round(W) Do Begin
   V.N:=Ag.Sum*2/Z;
   If Ag.Sum-V.N<Y Then V.N:=Ag.Sum-Y;
   If V.N<0 Then V.N:=0;
   Ag.Sum:=Ag.Sum-V.N;
  End;
 End
 Else If Nm='NPV' Then Begin
  V.N:=0;
  For I:=1 To CapN1 Do Begin
   W:=PowerOf(1+X,I,Ok);
   V.N:=V.N+CorA^[I]/W;
  End;
 End
 Else If Nm='RATE' Then Begin
  If (Y<=0) Or (Z<=0) Then V.K:=2 Else V.N:=PowerOf(X/Y,1/Z,Ok)-1;
 End
 Else If Nm='TERM' Then Begin
  If (X=0) Or (1+Z*Y/X<=0) Or (Y<=-1) Then V.K:=2 Else V.N:=Ln(1+Z*Y/X)/Ln(1+Y);
 End
 Else If Nm='CTERM' Then Begin
  If (Z<=0) Or (Y<=0) Or (X<=-1) Then V.K:=2 Else V.N:=Ln(Y/Z)/Ln(1+X);
 End
 Else If Nm='CHR' Then Begin V.K:=1;V.S:=Chr(Round(X) And $FF);End
 Else If Nm='CODE' Then Begin If A[1].S='' Then V.N:=0 Else V.N:=Ord(A[1].S[1]);End
 Else If Nm='EXACT' Then Begin If ToStr(A[1])=ToStr(A[2]) Then V.N:=1;End
 Else If Nm='FIND' Then Begin
  K:=1;
  If NA>=3 Then K:=Round(Z);
  If K<1 Then K:=1;
  SV:=Copy(ToStr(A[2]),K,255);
  V.N:=Pos(Upper(ToStr(A[1])),Upper(SV));
  If V.N>0 Then V.N:=V.N+K-1;
 End
 Else If Nm='LEFT' Then Begin V.K:=1;V.S:=Copy(ToStr(A[1]),1,Max2(0,Round(Y)));End
 Else If Nm='LEN' Then V.N:=Length(ToStr(A[1]))
 Else If Nm='LOWER' Then Begin V.K:=1;V.S:=Lower(ToStr(A[1]));End
 Else If Nm='MID' Then Begin V.K:=1;V.S:=Copy(ToStr(A[1]),Max2(1,Round(Y)),Max2(0,Round(Z)));End
 Else If Nm='PROPER' Then Begin
  V.K:=1;V.S:=Lower(ToStr(A[1]));
  Ok:=True;
  For I:=1 To Length(V.S) Do Begin
   If Ok And (V.S[I] In ['a'..'z']) Then V.S[I]:=UpCase(V.S[I]);
   Ok:=Not (UpCase(V.S[I]) In ['A'..'Z']);
  End;
 End
 Else If Nm='REPEAT' Then Begin
  V.K:=1;V.S:='';SV:=ToStr(A[1]);
  For I:=1 To Round(Y) Do If Length(V.S)+Length(SV)<=80 Then V.S:=V.S+SV;
 End
 Else If Nm='REPLACE' Then Begin
  SV:=ToStr(A[1]);
  K:=Round(Y);
  If K<1 Then K:=1;
  Delete(SV,K,Max2(0,Round(Z)));
  Insert(ToStr(A[4]),SV,K);
  V.K:=1;V.S:=Copy(SV,1,80);
 End
 Else If Nm='RIGHT' Then Begin
  V.K:=1;SV:=ToStr(A[1]);
  K:=Max2(0,Round(Y));
  If K>Length(SV) Then K:=Length(SV);
  V.S:=Copy(SV,Length(SV)-K+1,K);
 End
 Else If Nm='STR' Then Begin
  V.K:=1;
  If NA>=2 Then V.S:=FormatNum(X,Round(Y)) Else V.S:=FormatNum(X,-1);
 End
 Else If Nm='TRIM' Then Begin
  SV:=TrimStr(ToStr(A[1]));
  While Pos('  ',SV)>0 Do Delete(SV,Pos('  ',SV),1);
  V.K:=1;V.S:=SV;
 End
 Else If Nm='UPPER' Then Begin V.K:=1;V.S:=Upper(ToStr(A[1]));End
 Else If Nm='VAL' Then Begin If RealOf(ToStr(A[1]),X) Then V.N:=X Else V.N:=0;End
 Else If Nm='DATE' Then Begin
  K:=Round(X);
  If K<100 Then K:=K+1900;
  V.N:=JDN(K,Round(Y),Round(Z))-2415020;
 End
 Else If (Nm='DAY') Or (Nm='MONTH') Or (Nm='YEAR') Then Begin
  FromJDN(Trunc(X)+2415020,Ag.Cnt,Ag.NNeg,Ag.NPos);
  If Nm='DAY' Then V.N:=Ag.NPos Else If Nm='MONTH' Then V.N:=Ag.NNeg Else V.N:=Ag.Cnt;
 End
 Else If Nm='DATE$' Then Begin
  FromJDN(Trunc(X)+2415020,Ag.Cnt,Ag.NNeg,Ag.NPos);
  V.K:=1;V.S:=Pad2(Ag.NPos)+'/'+Pad2(Ag.NNeg)+'/'+Pad2(Ag.Cnt Mod 100);
 End
 Else If Nm='DAY$' Then Begin V.K:=1;V.S:=DayNames[(Trunc(X)+2415020+1) Mod 7];End
 Else If Nm='MONTH$' Then Begin
  FromJDN(Trunc(X)+2415020,Ag.Cnt,Ag.NNeg,Ag.NPos);
  V.K:=1;V.S:=MonthNames[Ag.NNeg];
 End
 Else If Nm='NOW' Then Begin
  GetDate(DY,DM,DD,DW);
  GetTime(TH,TM,TS,TS100);
  V.N:=JDN(DY,DM,DD)-2415020+(TH*3600.0+TM*60+TS)/86400;
 End
 Else If Nm='TIME' Then V.N:=(X*3600+Y*60+Z)/86400
 Else If Nm='HOUR' Then V.N:=Int(Frac(X)*24+1E-9)
 Else If Nm='MINUTE' Then V.N:=Int(Frac(Frac(X)*24+1E-9)*60+1E-9)
 Else If Nm='SECOND' Then V.N:=Int(Frac(Frac(Frac(X)*24+1E-9)*60+1E-9)*60+1E-6)
 Else If Nm='TIME$' Then Begin
  Y:=Frac(X)*86400;
  V.K:=1;V.S:=Pad2(Trunc(Y) Div 3600)+':'+Pad2((Trunc(Y) Mod 3600) Div 60)+':'+Pad2(Trunc(Y) Mod 60);
 End
 Else If Nm='IF' Then Begin
  If ToNum(A[1])<>0 Then V:=A[2] Else V:=A[3];
 End
 Else If Nm='ISNUMBER' Then Begin If A[1].K=0 Then V.N:=1;End
 Else If Nm='ISSTRING' Then Begin If A[1].K=1 Then V.N:=1;End
 Else If Nm='HEX$' Then Begin
  V.K:=1;V.S:='';
  K:=Round(X);
  If K=0 Then V.S:='0';
  While K>0 Do Begin V.S:=Copy('0123456789ABCDEF',(K And 15)+1,1)+V.S;K:=K Shr 4;End;
 End
 Else If Nm='HEX' Then Begin
  SV:=Upper(ToStr(A[1]));V.N:=0;
  For I:=1 To Length(SV) Do Begin
   K:=Pos(SV[I],'0123456789ABCDEF');
   If K=0 Then V.K:=2 Else V.N:=V.N*16+K-1;
  End;
 End
 Else If Nm='SYS' Then V.N:=0
 Else If (Nm='FROW') Or (Nm='FCOL') Or (Nm='FPAGE') Or (Nm='VLOOKUP') Or (Nm='HLOOKUP') Then Begin
  If Not IsRg[2] Then V.K:=2 Else Begin
   V.N:=-1;
   If (Nm='VLOOKUP') Or (Nm='HLOOKUP') Then V.N:=0;
   SV:=ToStr(A[1]);
   For P:=Rgs[2].P1 To Rgs[2].P2 Do
    For R:=Rgs[2].R1 To Rgs[2].R2 Do
     For C:=Rgs[2].C1 To Rgs[2].C2 Do Begin
      If ((Nm='VLOOKUP') And (C<>Rgs[2].C1)) Or ((Nm='HLOOKUP') And (R<>Rgs[2].R1)) Then Continue;
      EvalCell(FSh,P,C,R,T);
      If MatchWild(SV,ToStr(T)) And (T.K<>2) Then Begin
       If Nm='FROW' Then Begin V.N:=R;End
       Else If Nm='FCOL' Then Begin V.N:=C;End
       Else If Nm='FPAGE' Then Begin V.N:=P;End
       Else Begin
        If Nm='VLOOKUP' Then EvalCell(FSh,P,C+Round(Y),R,V) Else EvalCell(FSh,P,C,R+Round(Y),V);
       End;
       Exit;
      End;
     End;
  End;
 End
 Else If Nm='K' Then Begin
  If NA>=2 Then EvalCell(FSh,Round(X),Round(Y),FRw,V) Else EvalCell(FSh,FPg,Round(X),FRw,V);
 End
 Else If Nm='R' Then Begin
  If NA>=2 Then EvalCell(FSh,Round(X),FCl,Round(Y),V) Else EvalCell(FSh,FPg,FCl,Round(X),V);
 End
 Else If Nm='C' Then Begin
  If NA>=3 Then EvalCell(FSh,Round(X),Round(Y),Round(Z),V) Else EvalCell(FSh,FPg,Round(X),Round(Y),V);
 End
 Else If Nm='P' Then EvalCell(FSh,Round(X),FCl,FRw,V)
 Else FSyn:=True;
End;

Procedure NumberToken(Var V: TVal);
Var T: String; X: Double; Code: Integer;
Begin
 T:='';
 While Pk In ['0'..'9','.'] Do Begin T:=T+Pk;Inc(FP);End;
 If (UpCase(Pk)='E') And (FP<Length(FS)) And ((FS[FP+1] In ['0'..'9']) Or ((FS[FP+1] In ['+','-']) And (FP+1<Length(FS)) And (FS[FP+2] In ['0'..'9']))) Then Begin
  T:=T+'E';Inc(FP);
  If Pk In ['+','-'] Then Begin T:=T+Pk;Inc(FP);End;
  While Pk In ['0'..'9'] Do Begin T:=T+Pk;Inc(FP);End;
 End;
 If T[1]='.' Then T:='0'+T;
 If T[Length(T)]='.' Then T:=T+'0';
 Val(T,X,Code);
 If Code<>0 Then FSyn:=True Else V.N:=X;
End;

Procedure Primary(Var V: TVal);
Var P,C,R,Save: Integer; Nm: String; Q: Char;
Begin
 V.K:=0;V.N:=0;V.S:='';
 SkipSp;
 If Pk='(' Then Begin
  Inc(FP);
  Expr(V);
  SkipSp;
  If Pk=')' Then Inc(FP) Else FSyn:=True;
 End
 Else If (Pk='"') Or (Pk='''') Then Begin
  Q:=Pk;
  Inc(FP);
  V.K:=1;
  While (FP<=Length(FS)) And (FS[FP]<>Q) Do Begin
   If Length(V.S)<80 Then V.S:=V.S+FS[FP];
   Inc(FP);
  End;
  If Pk=Q Then Inc(FP) Else FSyn:=True;
 End
 Else If (Pk In ['0'..'9','.','$']) Or (UpCase(Pk) In ['A'..'Z','_']) Then Begin
  Save:=FP;
  If (Pk<>'.') And TryRef(FPg,P,C,R) Then Begin
   If Not FDry Then EvalCell(FSh,P,C,R,V);
  End Else Begin
   FP:=Save;
   If Pk In ['0'..'9','.'] Then NumberToken(V)
   Else If UpCase(Pk) In ['A'..'Z','_'] Then Begin
    Nm:='';
    While UpCase(Pk) In ['A'..'Z','0'..'9','_','$'] Do Begin Nm:=Nm+UpCase(Pk);Inc(FP);End;
    SkipSp;
    If Pk='(' Then CallFunc(Nm,V)
    Else If Nm='PI' Then V.N:=Pi
    Else If Nm='TRUE' Then V.N:=1
    Else If Nm='FALSE' Then V.N:=0
    Else If (Nm='COL') Or (Nm='COLUMN') Then V.N:=FCl
    Else If Nm='ROW' Then V.N:=FRw
    Else If Nm='PAGE' Then V.N:=FPg
    Else If Nm='KHIGH' Then Begin If Not FDry Then V.N:=HighUsed(FSh,1);End
    Else If Nm='RHIGH' Then Begin If Not FDry Then V.N:=HighUsed(FSh,2);End
    Else If Nm='PHIGH' Then Begin If Not FDry Then V.N:=HighUsed(FSh,3);End
    Else If (Length(Nm)<=2) And (Nm[1] In ['A'..'Z']) And ((Length(Nm)=1) Or (Nm[2] In ['A'..'Z'])) Then Begin
     { lettres seules : numero de colonne }
     If Length(Nm)=1 Then V.N:=Ord(Nm[1])-65 Else V.N:=(Ord(Nm[1])-64)*26+Ord(Nm[2])-65;
    End
    Else FSyn:=True;
   End Else FSyn:=True;
  End;
 End
 Else FSyn:=True;
End;

Procedure Binary(Prec: Integer; Var V: TVal); Forward;

Procedure Unary(Var V: TVal);
Begin
 SkipSp;
 If Pk='-' Then Begin
  Inc(FP);
  Binary(6,V);
  If V.K=0 Then V.N:=-V.N Else V.K:=2;
 End Else If Pk='+' Then Begin
  Inc(FP);
  Unary(V);
 End Else Primary(V);
End;

Function IsWordAt(Const W: String): Boolean;
Var N: Integer; C: Char;
Begin
 IsWordAt:=False;
 N:=Length(W);
 If UpCase(Copy(FS,FP,N))<>W Then Exit;
 If FP+N<=Length(FS) Then Begin
  C:=UpCase(FS[FP+N]);
  If C In ['A'..'Z','0'..'9','_','('] Then Exit;
 End;
 IsWordAt:=True;
End;

Procedure Binary(Prec: Integer; Var V: TVal);
Var Op,OP2,L,I: Integer; R: TVal; X,Y: Double; Ok: Boolean; C: Char;
Begin
 Unary(V);
 Repeat
  SkipSp;
  C:=Pk;
  Op:=0;L:=1;
  Case C Of
   '=': Op:=1;
   '<': Begin
         Op:=2;
         If (FP<Length(FS)) And (FS[FP+1]='>') Then Begin Op:=3;L:=2;End
         Else If (FP<Length(FS)) And (FS[FP+1]='=') Then Begin Op:=5;L:=2;End;
        End;
   '>': Begin
         Op:=4;
         If (FP<Length(FS)) And (FS[FP+1]='=') Then Begin Op:=6;L:=2;End;
        End;
   '&': Op:=7;
   '+': Op:=8;
   '-': Op:=9;
   '*': Op:=10;
   '/': Op:=11;
   '^': Op:=12;
   'A','a': If IsWordAt('AND') Then Begin Op:=13;L:=3;End;
   'O','o': If IsWordAt('OR') Then Begin Op:=14;L:=2;End;
  End;
  If Op=0 Then Break;
  Case Op Of
   14: OP2:=1;
   13: OP2:=2;
   1..6: OP2:=3;
   7..9: OP2:=4;
   10,11: OP2:=5;
   Else OP2:=6;
  End;
  If OP2<Prec Then Break;
  Inc(FP,L);
  Binary(OP2+1,R);
  If (V.K=2) Or (R.K=2) Then V.K:=2
  Else Case Op Of
   1..6: Begin
          If (V.K=1) And (R.K=1) Then I:=CmpStr(V.S,R.S)
          Else Begin
           X:=ToNum(V);Y:=ToNum(R);
           If X<Y Then I:=-1 Else If X>Y Then I:=1 Else I:=0;
          End;
          V.K:=0;V.S:='';V.N:=0;
          Case Op Of
           1: If I=0 Then V.N:=1;
           2: If I<0 Then V.N:=1;
           3: If I<>0 Then V.N:=1;
           4: If I>0 Then V.N:=1;
           5: If I<=0 Then V.N:=1;
           6: If I>=0 Then V.N:=1;
          End;
         End;
   7: Begin
       V.S:=Copy(ToStr(V)+ToStr(R),1,80);
       V.K:=1;
      End;
   8: Begin
       If (V.K=1) Or (R.K=1) Then Begin
        V.S:=Copy(ToStr(V)+ToStr(R),1,80);
        V.K:=1;
       End Else V.N:=V.N+R.N;
      End;
   9: V.N:=ToNum(V)-ToNum(R);
   10: V.N:=ToNum(V)*ToNum(R);
   11: Begin
        Y:=ToNum(R);
        If Y=0 Then V.K:=2 Else V.N:=ToNum(V)/Y;
       End;
   12: Begin
        V.N:=PowerOf(ToNum(V),ToNum(R),Ok);
        If Not Ok Then V.K:=2;
       End;
   13: Begin
        If (ToNum(V)<>0) And (ToNum(R)<>0) Then X:=1 Else X:=0;
        V.K:=0;V.N:=X;
       End;
   14: Begin
        If (ToNum(V)<>0) Or (ToNum(R)<>0) Then X:=1 Else X:=0;
        V.K:=0;V.N:=X;
       End;
  End;
  If (V.K<>2) And (Op>=9) Then Begin V.K:=0;V.S:='';End;
  If (V.K=0) And (Abs(V.N)>1E300) Then V.K:=2;
 Until False;
End;

Procedure Expr(Var V: TVal);
Begin
 Binary(1,V);
End;

{ Evalue une chaine de formule. Retourne False si erreur de syntaxe }
Function EvalString(S,P,C,R: Integer; Const Src: String; Dry: Boolean; Var V: TVal): Boolean;
Var SaveS: String; SaveP,SavePg,SaveR,SaveC,SaveSh: Integer; SaveSyn,SaveDry: Boolean;
Begin
 SaveS:=FS;SaveP:=FP;SavePg:=FPg;SaveR:=FRw;SaveC:=FCl;SaveSh:=FSh;SaveSyn:=FSyn;SaveDry:=FDry;
 FS:=Src;FP:=1;FPg:=P;FRw:=R;FCl:=C;FSh:=S;FSyn:=False;FDry:=Dry;
 Expr(V);
 SkipSp;
 If FP<=Length(FS) Then FSyn:=True;
 EvalString:=Not FSyn;
 FS:=SaveS;FP:=SaveP;FPg:=SavePg;FRw:=SaveR;FCl:=SaveC;FSh:=SaveSh;FSyn:=SaveSyn;FDry:=SaveDry;
End;

Procedure EvalCell(S,P,C,R: Integer; Var V: TVal);
Var Cl: PCell; Ok: Boolean;
Begin
 V.K:=0;V.N:=0;V.S:='';
 If FDry Then Exit;
 Cl:=GetCell(S,P,C,R);
 If Cl=Nil Then Exit;
 Case Cl^.Kind Of
  CK_NUM: V.N:=Cl^.Num;
  CK_TEXT: Begin V.K:=1;If Cl^.Src<>Nil Then V.S:=Copy(Cl^.Src^,1,80);End;
  CK_FORMULA: Begin
   If Cl^.Gen<>EvalGen Then Begin
    If Cl^.Busy Or (Depth>={$IFDEF FPC}400{$ELSE}14{$ENDIF}) Then Begin
     V.K:=2;
     Exit;
    End;
    Cl^.Busy:=True;
    Inc(Depth);
    Ok:=EvalString(S,P,C,R,Cl^.Src^,False,V);
    Dec(Depth);
    Cl^.Busy:=False;
    If Not Ok Then V.K:=2;
    Cl^.Err:=(V.K=2);
    FreeStr(Cl^.Res);
    If V.K=1 Then Cl^.Res:=AllocStr(V.S);
    Cl^.Num:=V.N;
    Cl^.Gen:=EvalGen;
   End Else Begin
    If Cl^.Err Then V.K:=2
    Else If Cl^.Res<>Nil Then Begin V.K:=1;V.S:=Copy(Cl^.Res^,1,80);End
    Else V.N:=Cl^.Num;
   End;
  End;
 End;
End;

{ Evalue toutes les formules d'une feuille dans l'ordre naturel }
Procedure RecalcSheet(S: Integer);
Var P,R,C: Integer; Rw: PRowArr; V: TVal; Cl: PCell;
Begin
 For P:=0 To MAXPAGE Do Begin
  If Sh[S].Pg[P]=Nil Then Continue;
  For R:=0 To MAXROW Do Begin
   Rw:=Sh[S].Pg[P]^[R];
   If Rw=Nil Then Continue;
   For C:=0 To MAXCOL Do Begin
    Cl:=Rw^[C];
    If (Cl<>Nil) And (Cl^.Kind=CK_FORMULA) And (Cl^.Gen<>EvalGen) Then EvalCell(S,P,C,R,V);
   End;
  End;
 End;
End;

Function ColPrec(S,P,C: Integer; Cl: PCell): Integer;
Begin
 ColPrec:=GenDec;
 If Sh[S].ColP[C]>=0 Then ColPrec:=Sh[S].ColP[C];
 If (Cl<>Nil) And (Cl^.Fmt>0) Then ColPrec:=Cl^.Fmt-1;
End;

{ Texte affiche pour une cellule }
Function CellText(S,P,C,R: Integer; Var IsNum: Boolean): String;
Var Cl: PCell; V: TVal; Dec: Integer;
Begin
 IsNum:=False;
 CellText:='';
 Cl:=GetCell(S,P,C,R);
 If Cl=Nil Then Exit;
 If (Cl^.Attr And 1)<>0 Then Exit;
 Dec:=ColPrec(S,P,C,Cl);
 Case Cl^.Kind Of
  CK_NUM: Begin IsNum:=True;CellText:=FormatNum(Cl^.Num,Dec);End;
  CK_TEXT: If Cl^.Src<>Nil Then CellText:=Cl^.Src^;
  CK_FORMULA: Begin
   EvalCell(S,P,C,R,V);
   If V.K=2 Then CellText:='**ERR***'
   Else If V.K=1 Then CellText:=V.S
   Else Begin IsNum:=True;CellText:=FormatNum(V.N,Dec);End;
  End;
 End;
End;

Function CellNum(S,P,C,R: Integer; Var Ok: Boolean): Double;
Var V: TVal; Cl: PCell;
Begin
 EvalCell(S,P,C,R,V);
 Cl:=GetCell(S,P,C,R);
 Ok:=(V.K=0) And (Cl<>Nil) And (Cl^.Kind<>CK_EMPTY);
 CellNum:=V.N;
End;

{ Contenu litteral de la cellule (ligne d'edition et fichiers) }
Function CellSource(S,P,C,R: Integer): String;
Var Cl: PCell;
Begin
 CellSource:='';
 Cl:=GetCell(S,P,C,R);
 If Cl=Nil Then Exit;
 Case Cl^.Kind Of
  CK_NUM: CellSource:=NumToStr(Cl^.Num);
  CK_TEXT: If Cl^.Src<>Nil Then CellSource:='"'+Cl^.Src^+'"';
  CK_FORMULA: CellSource:=Cl^.Src^;
 End;
End;

Function NormFormula(Const S: String): String;
Var I: Integer; Q: Char; T: String;
Begin
 T:=S;Q:=#0;
 For I:=1 To Length(T) Do Begin
  If (T[I]='"') Or (T[I]='''') Then Begin
   If Q=#0 Then Q:=T[I] Else If Q=T[I] Then Q:=#0;
  End;
  If Q=#0 Then T[I]:=UpCase(T[I]);
 End;
 NormFormula:=T;
End;

Function LettersOnly(Const T: String): Boolean;
Var I: Integer;
Begin
 LettersOnly:=False;
 For I:=1 To Length(T) Do
  If Not (UpCase(T[I]) In ['A'..'Z',' ','.',',',':',';','-']) Then Exit;
 LettersOnly:=True;
End;

{ Enregistre une entree utilisateur dans une cellule }
Procedure SetEntry(S,P,C,R: Integer; Const Txt: String);
Var Cl: PCell; X: Double; T: String; V: TVal; Q: Char;
Begin
 Cl:=GetCell(S,P,C,R);
 If (Cl<>Nil) And ((Cl^.Attr And 2)<>0) Then Exit;
 T:=TrimStr(Txt);
 If T='' Then Begin
  KillCell(S,P,C,R);
  Invalidate;
  Sh[S].Modified:=True;
  Exit;
 End;
 If Cl=Nil Then Cl:=MakeCell(S,P,C,R);
 If Cl=Nil Then Exit;
 FreeCellData(Cl);
 Cl^.Err:=False;Cl^.Busy:=False;Cl^.Gen:=0;
 If (T[1]='"') Or (T[1]='''') Then Begin
  Q:=T[1];
  Delete(T,1,1);
  If (Length(T)>0) And (T[Length(T)]=Q) Then Delete(T,Length(T),1);
  Cl^.Kind:=CK_TEXT;
  Cl^.Src:=AllocStr(T);
 End Else If RealOf(T,X) Then Begin
  Cl^.Kind:=CK_NUM;
  Cl^.Num:=X;
 End Else If (Not LettersOnly(T)) And EvalString(S,P,C,R,T,True,V) Then Begin
  Cl^.Kind:=CK_FORMULA;
  Cl^.Src:=AllocStr(NormFormula(T));
 End Else Begin
  Cl^.Kind:=CK_TEXT;
  Cl^.Src:=AllocStr(T);
 End;
 Invalidate;
 Sh[S].Modified:=True;
End;

Procedure SetNumber(S,P,C,R: Integer; X: Double; Fmt: Byte);
Var Cl: PCell;
Begin
 Cl:=MakeCell(S,P,C,R);
 If Cl=Nil Then Exit;
 FreeCellData(Cl);
 Cl^.Kind:=CK_NUM;Cl^.Num:=X;Cl^.Fmt:=Fmt;Cl^.Gen:=0;
 Invalidate;
 Sh[S].Modified:=True;
End;

Procedure SetLabel(S,P,C,R: Integer; Const T: String);
Var Cl: PCell;
Begin
 If T='' Then Begin KillCell(S,P,C,R);Exit;End;
 Cl:=MakeCell(S,P,C,R);
 If Cl=Nil Then Exit;
 FreeCellData(Cl);
 Cl^.Kind:=CK_TEXT;Cl^.Src:=AllocStr(T);Cl^.Gen:=0;
 Invalidate;
 Sh[S].Modified:=True;
End;

{ Analyse d'une plage de type "1B2:3B9" ou "A0:B9" ou "A0" }
Function ParseRange(Const T: String; DefP: Integer; Var Rg: TRange): Boolean;
Var SaveS: String; SaveP: Integer; X: Integer;
Begin
 ParseRange:=False;
 SaveS:=FS;SaveP:=FP;
 FS:=Upper(TrimStr(T));FP:=1;
 If TryRef(DefP,Rg.P1,Rg.C1,Rg.R1) Then Begin
  SkipSp;
  If Pk=':' Then Begin
   Inc(FP);SkipSp;
   If TryRef(Rg.P1,Rg.P2,Rg.C2,Rg.R2) Then ParseRange:=True;
  End Else Begin
   Rg.P2:=Rg.P1;Rg.C2:=Rg.C1;Rg.R2:=Rg.R1;
   ParseRange:=True;
  End;
  SkipSp;
  If FP<=Length(FS) Then ParseRange:=False;
 End;
 FS:=SaveS;FP:=SaveP;
 If ParseRange Then Begin
  If Rg.P1>Rg.P2 Then Begin X:=Rg.P1;Rg.P1:=Rg.P2;Rg.P2:=X;End;
  If Rg.C1>Rg.C2 Then Begin X:=Rg.C1;Rg.C1:=Rg.C2;Rg.C2:=X;End;
  If Rg.R1>Rg.R2 Then Begin X:=Rg.R1;Rg.R1:=Rg.R2;Rg.R2:=X;End;
 End;
End;

Function CellAddr(P,C,R: Integer): String;
Begin
 CellAddr:=IntStr(P)+ColName(C)+IntStr(R);
End;

Function RangeStr(Const Rg: TRange): String;
Var S: String;
Begin
 S:='';
 If (Rg.P1<>0) Or (Rg.P2<>0) Then S:=IntStr(Rg.P1);
 S:=S+ColName(Rg.C1)+IntStr(Rg.R1);
 If (Rg.C1<>Rg.C2) Or (Rg.R1<>Rg.R2) Or (Rg.P1<>Rg.P2) Then Begin
  S:=S+':';
  If Rg.P1<>Rg.P2 Then S:=S+IntStr(Rg.P2);
  S:=S+ColName(Rg.C2)+IntStr(Rg.R2);
 End;
 RangeStr:=S;
End;

{ ====================================================================== }
{                   EVENEMENTS (clavier / souris / macros)               }
{ ====================================================================== }

Procedure DrawAll; Forward;

Function AltLetter(K: Word): Integer;
Const
 RowQ : String[10] = 'QWERTYUIOP';
 RowA : String[9] = 'ASDFGHJKL';
 RowZ : String[7] = 'ZXCVBNM';
Var Sc: Integer;
Begin
 AltLetter:=-1;
 If K<256 Then Exit;
 Sc:=K-256;
 Case Sc Of
  16..25: AltLetter:=Ord(RowQ[Sc-15])-65;
  30..38: AltLetter:=Ord(RowA[Sc-29])-65;
  44..50: AltLetter:=Ord(RowZ[Sc-43])-65;
 End;
End;

Procedure PollEvent(Var E: TEvent);
Var Ch: Char; K: Word; L: Integer;
Begin
 E.Kind:=0;E.Key:=0;E.X:=MX;E.Y:=MY;E.B:=MB;
 If (PlayLen>0) And (PlayPos<PlayLen) Then Begin
  Inc(PlayPos);
  E.Kind:=1;
  E.Key:=PlayBuf^[PlayPos];
  If PlayPos>=PlayLen Then Begin PlayLen:=0;PlayPos:=0;End;
  Exit;
 End;
 If KeyPressed Then Begin
  Ch:=ReadKey;
  If Ch=#0 Then K:=256+Ord(ReadKey) Else K:=Ord(Ch);
  If (PlayLen=0) And Not Recording Then Begin
   L:=AltLetter(K);
   If (L>=0) And (Sh[CurS].SMac[L]<>Nil) Then Begin
    Move(Sh[CurS].SMac[L]^,PlayBuf^,Sh[CurS].SMacLen[L]*2);
    PlayLen:=Sh[CurS].SMacLen[L];PlayPos:=0;
    Exit;
   End;
   If (K>=360) And (K<=369) And (DeskMac[K-359]<>Nil) Then Begin
    Move(DeskMac[K-359]^,PlayBuf^,DeskLen[K-359]*2);
    PlayLen:=DeskLen[K-359];PlayPos:=0;
    Exit;
   End;
  End;
  If Recording And (RecLen<MAXKEYS) Then Begin
   Inc(RecLen);
   RecBuf^[RecLen]:=K;
  End;
  E.Kind:=1;E.Key:=K;
  Exit;
 End;
 PrevMX:=MX;PrevMY:=MY;LastB:=MB;
 GetMouseState(MX,MY,MB);
 E.X:=MX;E.Y:=MY;E.B:=MB;
 If ((MB And 1)<>0) And ((LastB And 1)=0) Then E.Kind:=2
 Else If ((MB And 1)=0) And ((LastB And 1)<>0) Then E.Kind:=3
 Else If (MX<>PrevMX) Or (MY<>PrevMY) Then E.Kind:=4
 Else Delay(4);
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES                            }
{ ====================================================================== }

Const
 PatChecker : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);
 PatStripe  : FillPatternType = ($FF,$00,$FF,$00,$FF,$00,$FF,$00);
 PatTrack   : FillPatternType = ($88,$22,$88,$22,$88,$22,$88,$22);
 PatGraph   : Array[1..6] Of FillPatternType = (
  ($80,$00,$08,$00,$80,$00,$08,$00),
  ($88,$22,$88,$22,$88,$22,$88,$22),
  ($AA,$55,$AA,$55,$AA,$55,$AA,$55),
  ($77,$DD,$77,$DD,$77,$DD,$77,$DD),
  ($88,$44,$22,$11,$88,$44,$22,$11),
  ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF));
 LinePat : Array[0..5] Of Word = ($FFFF,$F0F0,$AAAA,$E4E4,$FC30,$EEEE);

Procedure Box(X1,Y1,X2,Y2,C: Integer);
Begin
 SetFillStyle(SolidFill,C);
 Bar(X1,Y1,X2,Y2);
End;

Procedure Frame(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
End;

{ Le BGI peint les bits a 1 avec la couleur et les bits a 0 avec la couleur 0 (noir) :
  on inverse donc le motif et on le peint en blanc pour obtenir noir sur blanc }
Procedure SetPat(Const Pat: FillPatternType);
Var Q: FillPatternType; I: Integer;
Begin
 For I:=1 To 8 Do Q[I]:=Not Pat[I];
 SetFillPattern(Q,PAPER);
End;

Procedure PatBar(X1,Y1,X2,Y2: Integer; Const Pat: FillPatternType);
Begin
 SetPat(Pat);
 Bar(X1,Y1,X2,Y2);
End;

Procedure PText(X,Y: Integer; Const S: String);
Begin
 SetColor(INK);
 OutTextXY(X,Y,S);
End;

Procedure BText(X,Y: Integer; Const S: String);
Begin
 SetColor(INK);
 OutTextXY(X,Y,S);
 OutTextXY(X+1,Y,S);
End;

Procedure WText(X,Y: Integer; Const S: String);
Begin
 SetColor(PAPER);
 OutTextXY(X,Y,S);
End;

Procedure GreyText(X,Y: Integer; Const S: String);
Var I,J,W: Integer;
Begin
 PText(X,Y,S);
 W:=Length(S)*8;
 For J:=0 To 7 Do
  For I:=0 To W-1 Do
   If Odd(I+J) Then
    If GetPixel(X+I,Y+J)=INK Then PutPixel(X+I,Y+J,PAPER);
End;

Function TextW(Const S: String): Integer;
Begin
 TextW:=Length(S)*8;
End;

Procedure SmallBox(X,Y: Integer);
Begin
 { petite case de fermeture GEM }
 Box(X,Y,X+TB_H-1,Y+TB_H-1,PAPER);
 Frame(X,Y,X+TB_H-1,Y+TB_H-1);
 Frame(X+4,Y+4,X+TB_H-5,Y+TB_H-5);
End;

Procedure ArrowBox(X1,Y1,X2,Y2,Dir: Integer);
{ Dir : 1 haut, 2 bas, 3 gauche, 4 droite }
Var Pt: Array[1..3] Of PointType; CX,CY: Integer;
Begin
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 CX:=(X1+X2) Div 2;CY:=(Y1+Y2) Div 2;
 Case Dir Of
  1: Begin Pt[1].X:=CX;Pt[1].Y:=CY-3;Pt[2].X:=CX-4;Pt[2].Y:=CY+3;Pt[3].X:=CX+4;Pt[3].Y:=CY+3;End;
  2: Begin Pt[1].X:=CX;Pt[1].Y:=CY+3;Pt[2].X:=CX-4;Pt[2].Y:=CY-3;Pt[3].X:=CX+4;Pt[3].Y:=CY-3;End;
  3: Begin Pt[1].X:=CX-3;Pt[1].Y:=CY;Pt[2].X:=CX+3;Pt[2].Y:=CY-4;Pt[3].X:=CX+3;Pt[3].Y:=CY+4;End;
  4: Begin Pt[1].X:=CX+3;Pt[1].Y:=CY;Pt[2].X:=CX-3;Pt[2].Y:=CY-4;Pt[3].X:=CX-3;Pt[3].Y:=CY+4;End;
 End;
 SetFillStyle(SolidFill,INK);
 SetColor(INK);
 FillPoly(3,Pt);
End;

Procedure Button(X1,Y1,X2,Y2: Integer; Const S: String; Hot,Enabled: Boolean);
Var TX: Integer;
Begin
 If Hot Then Begin
  Box(X1,Y1,X2,Y2,INK);
  Frame(X1-1,Y1-1,X2+1,Y2+1);
 End Else Begin
  Box(X1,Y1,X2,Y2,PAPER);
  Frame(X1,Y1,X2,Y2);
 End;
 TX:=(X1+X2+1-TextW(S)) Div 2;
 If Not Enabled Then GreyText(TX,(Y1+Y2-6) Div 2,S)
 Else If Hot Then WText(TX,(Y1+Y2-6) Div 2,S)
 Else PText(TX,(Y1+Y2-6) Div 2,S);
End;

Procedure DlgBox(X1,Y1,X2,Y2: Integer; Const Title: String; OkBox: Boolean);
Begin
 Box(X1+4,Y1+4,X2+4,Y2+4,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 Frame(X1+1,Y1+1,X2-1,Y2-1);
 Box(X1+2,Y1+2,X2-2,Y1+TB_H,PAPER);
 SetColor(INK);
 Line(X1+1,Y1+TB_H+1,X2-1,Y1+TB_H+1);
 SmallBox(X1+2,Y1+2);
 BText((X1+X2-TextW(Title)) Div 2,Y1+6,Title);
 If OkBox Then Begin
  Frame(X2-30,Y1+3,X2-4,Y1+TB_H);
  PText(X2-26,Y1+7,'OK');
 End;
End;

{ ====================================================================== }
{                      BOITES DE DIALOGUE                                }
{ ====================================================================== }

Var
 FormLbl : Array[1..12] Of String[24];
 FormVal : Array[1..12] Of String[70];
 FormFW  : Integer;
 LstItem : Array[1..120] Of String[36];
 LstN    : Integer;

Procedure MsgBox(Const Title,Txt: String);
Var Lines: Array[1..14] Of String[60]; N,I,W,X1,Y1,X2,Y2,P: Integer; S: String; E: TEvent; Done: Boolean;
Begin
 N:=0;S:=Txt;
 While (S<>'') And (N<14) Do Begin
  P:=Pos('|',S);
  Inc(N);
  If P=0 Then Begin Lines[N]:=Copy(S,1,60);S:='';End
  Else Begin Lines[N]:=Copy(Copy(S,1,P-1),1,60);Delete(S,1,P);End;
 End;
 W:=TextW(Title)+80;
 For I:=1 To N Do If TextW(Lines[I])+32>W Then W:=TextW(Lines[I])+32;
 If W<200 Then W:=200;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;
 Y1:=(SCR_H-(N*12+TB_H+40)) Div 2;Y2:=Y1+N*12+TB_H+40;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,Title,True);
 For I:=1 To N Do PText(X1+16,Y1+TB_H+14+(I-1)*12,Lines[I]);
 Button((X1+X2) Div 2-30,Y2-26,(X1+X2) Div 2+30,Y2-8,'OK',True,True);
 ShowMouse;
 Done:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ENTER) Or (E.Key=K_ESC) Or (E.Key=32) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Or InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
      Or InBox(E.X,E.Y,(X1+X2) Div 2-30,Y2-26,(X1+X2) Div 2+30,Y2-8) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Function ConfirmBox(Const Txt: String): Boolean;
Var X1,Y1,X2,Y2,W: Integer; E: TEvent; Done: Boolean;
Begin
 W:=TextW(Txt)+40;
 If W<260 Then W:=260;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=190;Y2:=Y1+90;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,'3D-CALC+',False);
 PText(X1+20,Y1+TB_H+14,Txt);
 Button(X1+20,Y2-30,X1+90,Y2-10,'YES',True,True);
 Button(X2-90,Y2-30,X2-20,Y2-10,'NO',False,True);
 ShowMouse;
 Done:=False;ConfirmBox:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If UpCase(Chr(E.Key And $FF))='Y' Then Begin ConfirmBox:=True;Done:=True;End;
   If (E.Key=K_ENTER) Then Begin ConfirmBox:=True;Done:=True;End;
   If (UpCase(Chr(E.Key And $FF))='N') Or (E.Key=K_ESC) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+20,Y2-30,X1+90,Y2-10) Then Begin ConfirmBox:=True;Done:=True;End;
   If InBox(E.X,E.Y,X2-90,Y2-30,X2-20,Y2-10) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Function FormBox(Const Title: String; N: Integer): Boolean;
Var LW,W,H,X1,Y1,X2,Y2,I,F,FX,FY,FW: Integer; E: TEvent; Done,Ok,Fresh,Redraw: Boolean; Ch: Char;
    Blink: LongInt;
Begin
 LW:=0;
 For I:=1 To N Do If Length(FormLbl[I])>LW Then LW:=Length(FormLbl[I]);
 LW:=LW*8+8;
 FW:=FormFW*8+8;
 W:=LW+FW+32;
 If W<TextW(Title)+80 Then W:=TextW(Title)+80;
 If W>620 Then Begin W:=620;FW:=W-LW-32;End;
 H:=TB_H+N*22+56;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-20;Y2:=Y1+H;
 F:=1;Fresh:=True;Done:=False;Ok:=False;Redraw:=True;Blink:=0;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   For I:=1 To N Do Begin
    PText(X1+14,Y1+TB_H+16+(I-1)*22,FormLbl[I]);
    FX:=X1+14+LW;FY:=Y1+TB_H+12+(I-1)*22;
    Box(FX,FY,FX+FW,FY+14,PAPER);
    Frame(FX,FY,FX+FW,FY+14);
    If (I=F) And Fresh Then Begin
     Box(FX+1,FY+1,FX+8*Length(FormVal[I])+3,FY+13,INK);
     WText(FX+3,FY+4,Copy(FormVal[I],1,FormFW));
    End Else Begin
     PText(FX+3,FY+4,Copy(FormVal[I],1,FormFW));
     If I=F Then PText(FX+3+8*Length(Copy(FormVal[I],1,FormFW)),FY+4,'_');
    End;
   End;
   Button(X1+14,Y2-28,X1+84,Y2-8,'OK',True,True);
   Button(X2-84,Y2-28,X2-14,Y2-8,'Cancel',False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Ok:=True;Done:=True;End;
    K_ESC: Done:=True;
    K_TAB,K_DOWN: Begin If F<N Then Inc(F) Else F:=1;Fresh:=True;Redraw:=True;End;
    K_STAB,K_UP: Begin If F>1 Then Dec(F) Else F:=N;Fresh:=True;Redraw:=True;End;
    K_BKSP: Begin
             If Fresh Then FormVal[F]:='' Else If Length(FormVal[F])>0 Then Dec(FormVal[F][0]);
             Fresh:=False;Redraw:=True;
            End;
    K_DEL: Begin FormVal[F]:='';Fresh:=False;Redraw:=True;End;
    32..255: Begin
              Ch:=Chr(E.Key);
              If Fresh Then FormVal[F]:='';
              Fresh:=False;
              If Length(FormVal[F])<FormFW Then FormVal[F]:=FormVal[F]+Ch;
              Redraw:=True;
             End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True
   Else If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H) Or InBox(E.X,E.Y,X1+14,Y2-28,X1+84,Y2-8) Then Begin Ok:=True;Done:=True;End
   Else If InBox(E.X,E.Y,X2-84,Y2-28,X2-14,Y2-8) Then Done:=True
   Else For I:=1 To N Do
    If InBox(E.X,E.Y,X1+14+LW,Y1+TB_H+12+(I-1)*22,X1+14+LW+FW,Y1+TB_H+26+(I-1)*22) Then Begin
     F:=I;Fresh:=False;Redraw:=True;
    End;
  End;
 Until Done;
 FormBox:=Ok;
 NeedDraw:=True;
End;

Function InputBox(Const Title,Prompt: String; Var S: String; MaxLen: Integer): Boolean;
Begin
 FormLbl[1]:=Copy(Prompt,1,24);
 FormVal[1]:=Copy(S,1,70);
 FormFW:=MaxLen;
 If FormFW>40 Then FormFW:=40;
 If FormBox(Title,1) Then Begin
  S:=FormVal[1];
  InputBox:=True;
 End Else InputBox:=False;
End;

{ Boite de selection dans une liste : LstItem[1..LstN]. Retourne 0 si annule }
Function ChooseBox(Const Title: String; Start: Integer): Integer;
Var X1,Y1,X2,Y2,W,H,I,Top,Sel,VisN: Integer; E: TEvent; Done,Redraw: Boolean; Res: Integer;
Begin
 W:=TextW(Title)+80;
 For I:=1 To LstN Do If TextW(LstItem[I])+60>W Then W:=TextW(LstItem[I])+60;
 If W<260 Then W:=260;
 VisN:=LstN;
 If VisN>16 Then VisN:=16;
 If VisN<3 Then VisN:=3;
 H:=TB_H+VisN*12+50;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-10;Y2:=Y1+H;
 Sel:=Start;If Sel<1 Then Sel:=1;If Sel>LstN Then Sel:=LstN;
 Top:=1;
 Done:=False;Res:=0;Redraw:=True;
 Repeat
  If Sel<Top Then Top:=Sel;
  If Sel>=Top+VisN Then Top:=Sel-VisN+1;
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   Box(X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12+2,PAPER);
   Frame(X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12+2);
   For I:=Top To Top+VisN-1 Do
    If I<=LstN Then Begin
     If I=Sel Then Begin
      Box(X1+11,Y1+TB_H+9+(I-Top)*12,X2-29,Y1+TB_H+20+(I-Top)*12,INK);
      WText(X1+14,Y1+TB_H+11+(I-Top)*12,LstItem[I]);
     End Else PText(X1+14,Y1+TB_H+11+(I-Top)*12,LstItem[I]);
    End;
   ArrowBox(X2-26,Y1+TB_H+8,X2-10,Y1+TB_H+24,1);
   ArrowBox(X2-26,Y1+TB_H+8+VisN*12-14,X2-10,Y1+TB_H+8+VisN*12+2,2);
   Button(X1+14,Y2-26,X1+84,Y2-8,'OK',True,True);
   Button(X2-84,Y2-26,X2-14,Y2-8,'Cancel',False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Res:=Sel;Done:=True;End;
    K_ESC: Done:=True;
    K_UP: If Sel>1 Then Begin Dec(Sel);Redraw:=True;End;
    K_DOWN: If Sel<LstN Then Begin Inc(Sel);Redraw:=True;End;
    K_PGUP: Begin Sel:=Max2(1,Sel-VisN);Redraw:=True;End;
    K_PGDN: Begin Sel:=Min2(LstN,Sel+VisN);Redraw:=True;End;
    K_HOME: Begin Sel:=1;Redraw:=True;End;
    K_END: Begin Sel:=LstN;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Or InBox(E.X,E.Y,X2-84,Y2-26,X2-14,Y2-8) Then Done:=True
   Else If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H) Or InBox(E.X,E.Y,X1+14,Y2-26,X1+84,Y2-8) Then Begin Res:=Sel;Done:=True;End
   Else If InBox(E.X,E.Y,X2-26,Y1+TB_H+8,X2-10,Y1+TB_H+24) Then Begin If Sel>1 Then Dec(Sel);Redraw:=True;End
   Else If InBox(E.X,E.Y,X2-26,Y1+TB_H+8+VisN*12-14,X2-10,Y1+TB_H+8+VisN*12+2) Then Begin If Sel<LstN Then Inc(Sel);Redraw:=True;End
   Else If InBox(E.X,E.Y,X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12) Then Begin
    I:=Top+((E.Y-(Y1+TB_H+9)) Div 12);
    If (I>=1) And (I<=LstN) Then Begin
     If I=Sel Then Begin Res:=Sel;Done:=True;End;
     Sel:=I;Redraw:=True;
    End;
   End;
  End;
 Until Done;
 ChooseBox:=Res;
 NeedDraw:=True;
End;

{ Selecteur de fichier : liste les fichiers correspondant au masque }
Procedure ScanFiles(Const Mask: String);
Var SR: SearchRec; I: Integer; Dup: Boolean;
Begin
 FindFirst(Mask,AnyFile-Directory,SR);
 While (DosError=0) And (LstN<119) Do Begin
  Dup:=False;
  For I:=1 To LstN Do If LstItem[I]=Copy(SR.Name,1,36) Then Dup:=True;
  If Not Dup Then Begin
   Inc(LstN);
   LstItem[LstN]:=Copy(SR.Name,1,36);
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
End;

Function FileSelect(Const Title,Mask: String; Var Name: String): Boolean;
Var I,Sel: Integer; S: String;
Begin
 LstN:=0;
 ScanFiles(Mask);
 If Lower(Mask)<>Mask Then ScanFiles(Lower(Mask));
 Inc(LstN);
 LstItem[LstN]:='[ Type a name... ]';
 FileSelect:=False;
 S:=Name;
 Sel:=1;
 For I:=1 To LstN-1 Do If Upper(LstItem[I])=Upper(ShortName(S)) Then Sel:=I;
 I:=ChooseBox(Title+' ('+Mask+')',Sel);
 If I=0 Then Exit;
 If I<LstN Then Begin
  Name:=LstItem[I];
  FileSelect:=True;
 End Else Begin
  If InputBox(Title,'File name',S,36) Then Begin
   Name:=S;
   FileSelect:=(S<>'');
  End;
 End;
End;

{ ====================================================================== }
{                         MENUS (donnees)                                }
{ ====================================================================== }

Const
 NMENU = 10;
 MTitle : Array[1..NMENU] Of String[8] = ('Desk','File','Window','Block','Stat','Graph','Text','Macro','Options','?');

Function MCount(M: Integer): Integer;
Begin
 Case M Of
  1: MCount:=3;
  2: MCount:=16;
  3: MCount:=12;
  4: MCount:=16;
  5: MCount:=7;
  6: MCount:=5;
  7: MCount:=10;
  8: MCount:=9;
  9: MCount:=14;
  10: MCount:=1;
  Else MCount:=0;
 End;
End;

{ '-' = separateur, '=' prefixe = titre de section ; '|' separe le raccourci }
Function MLabel(M,I: Integer): String;
Begin
 MLabel:='';
 Case M Of
  1: Case I Of
      1: MLabel:='About 3D-CALC+';
      2: MLabel:='-';
      3: MLabel:='Free memory';
     End;
  2: Case I Of
      1: MLabel:='Spreadsheet 1|Alt1';
      2: MLabel:='Spreadsheet 2|Alt2';
      3: MLabel:='Spreadsheet 3|Alt3';
      4: MLabel:='=files';
      5: MLabel:='Read file|^L';
      6: MLabel:='Save|^S';
      7: MLabel:='Save as|^X';
      8: MLabel:='-';
      9: MLabel:='Append file';
      10: MLabel:='Merge file';
      11: MLabel:='-';
      12: MLabel:='Read Lotus123 file';
      13: MLabel:='Import ASCII file';
      14: MLabel:='Export ASCII file';
      15: MLabel:='-';
      16: MLabel:='Quit 3D-CALC|^Q';
     End;
  3: Case I Of
      1: MLabel:='Open window|F1';
      2: MLabel:='Sort';
      3: MLabel:='Find|ShF7';
      4: MLabel:='Goto cell|^F7';
      5: MLabel:='Define column|ShF8';
      6: MLabel:='Calculate window|F8';
      7: MLabel:='-';
      8: MLabel:='Print data|^O';
      9: MLabel:='Clear data|^G';
      10: MLabel:='Command line|^F';
      11: MLabel:='-';
      12: MLabel:='Output window';
     End;
  4: Case I Of
      1: MLabel:='Define block|^D';
      2: MLabel:='Set begin block|^B';
      3: MLabel:='Set end block|^E';
      4: MLabel:='-';
      5: MLabel:='Move block|^M';
      6: MLabel:='Copy block|^N';
      7: MLabel:='Copy block to text';
      8: MLabel:='-';
      9: MLabel:='Cut block|^C';
      10: MLabel:='Paste block|^P';
      11: MLabel:='Write block|^W';
      12: MLabel:='Read block|^R';
      13: MLabel:='-';
      14: MLabel:='Set block values|^Y';
      15: MLabel:='Hide block|^H';
      16: MLabel:='Clear block|^K';
     End;
  5: Case I Of
      1: MLabel:='Averages and percentiles';
      2: MLabel:='Histogram';
      3: MLabel:='Cumulative distribution';
      4: MLabel:='-';
      5: MLabel:='Scatter diagram';
      6: MLabel:='Draw curve';
      7: MLabel:='Regression and correlation';
     End;
  6: Case I Of
      1: MLabel:='Bar graph';
      2: MLabel:='Line graph';
      3: MLabel:='Pie chart';
      4: MLabel:='Multiple range graph';
      5: MLabel:='Function graph';
     End;
  7: Case I Of
      1: MLabel:='Open window|^T';
      2: MLabel:='Read text|^I';
      3: MLabel:='Save text';
      4: MLabel:='Save as';
      5: MLabel:='ASCII';
      6: MLabel:='Format';
      7: MLabel:='Print text|^U';
      8: MLabel:='Reformat';
      9: MLabel:='Program|^Z';
      10: MLabel:='Clear|^V';
     End;
  8: Case I Of
      1: MLabel:='Start recording';
      2: MLabel:='Stop recording';
      3: MLabel:='-';
      4: MLabel:='Delete macro';
      5: MLabel:='-';
      6: MLabel:='List active macros';
      7: MLabel:='-';
      8: MLabel:='Save desk macros';
      9: MLabel:='Load desk macros';
     End;
  9: Case I Of
      1: MLabel:='Settings';
      2: MLabel:='-';
      3: MLabel:='Link pages';
      4: MLabel:='Column synchronization';
      5: MLabel:='Row synchronization';
      6: MLabel:='Page synchronization';
      7: MLabel:='Window grid';
      8: MLabel:='-';
      9: MLabel:='Output format';
      10: MLabel:='Paths';
      11: MLabel:='Graph options';
      12: MLabel:='Cell font';
      13: MLabel:='-';
      14: MLabel:='Save options';
     End;
  10: Case I Of
      1: MLabel:='Help';
     End;
 End;
End;

Function MChecked(M,I: Integer): Boolean;
Begin
 MChecked:=False;
 If (M=2) And (I>=1) And (I<=3) Then MChecked:=(CurS=I);
 If (M=5) And (I=6) Then MChecked:=DrawCurve;
 If (M=4) And (I=15) Then MChecked:=BlockHide;
 If (M=7) And (I=5) Then MChecked:=TxtASCII;
 If (M=7) And (I=8) Then MChecked:=TxtReformat;
 If (M=9) And (I=3) Then MChecked:=LinkPages;
 If (M=9) And (I=4) Then MChecked:=SyncC;
 If (M=9) And (I=5) Then MChecked:=SyncR;
 If (M=9) And (I=6) Then MChecked:=SyncP;
 If (M=9) And (I=7) Then MChecked:=GridOn;
End;

Function MEnabled(M,I: Integer): Boolean;
Begin
 MEnabled:=True;
 If (M=8) And (I=1) Then MEnabled:=Not Recording;
 If (M=8) And (I=2) Then MEnabled:=Recording;
 If (M=2) And (I=4) Then MEnabled:=False;
End;

Function MIsTitle(M,I: Integer): Boolean;
Var S: String;
Begin
 S:=MLabel(M,I);
 MIsTitle:=(S<>'') And (S[1]='=');
End;

Function MSep(M,I: Integer): Boolean;
Begin
 MSep:=(MLabel(M,I)='-');
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=24;
 For I:=1 To M-1 Do X:=X+Length(MTitle[I])*8+16;
 MenuX:=X;
End;

Function ItemH(M,I: Integer): Integer;
Begin
 If MSep(M,I) Then ItemH:=8 Else ItemH:=16;
End;

Procedure DropRect(M: Integer; Var X1,Y1,X2,Y2: Integer);
Var I,W,L: Integer; S,Sc: String; P: Integer;
Begin
 W:=0;Y2:=MENU_H+2;
 For I:=1 To MCount(M) Do Begin
  S:=MLabel(M,I);
  P:=Pos('|',S);
  If P>0 Then L:=(P-1)*8+24+(Length(S)-P)*8 Else L:=Length(S)*8;
  If L>W Then W:=L;
  Y2:=Y2+ItemH(M,I);
 End;
 X1:=MenuX(M)-8;
 X2:=X1+W+32;
 If X2>SCR_W-4 Then Begin X1:=X1-(X2-(SCR_W-4));X2:=SCR_W-4;End;
 Y1:=MENU_H;
End;

Function ItemY(M,I: Integer): Integer;
Var K,Y: Integer;
Begin
 Y:=MENU_H+2;
 For K:=1 To I-1 Do Y:=Y+ItemH(M,K);
 ItemY:=Y;
End;

Function DropHit(M: Integer; X,Y: LongInt): Integer;
Var X1,Y1,X2,Y2,I: Integer;
Begin
 DropHit:=0;
 DropRect(M,X1,Y1,X2,Y2);
 If Not InBox(X,Y,X1,Y1,X2,Y2) Then Exit;
 For I:=1 To MCount(M) Do
  If (Y>=ItemY(M,I)) And (Y<ItemY(M,I)+ItemH(M,I)) Then DropHit:=I;
End;

Function TitleHit(X,Y: LongInt): Integer;
Var M: Integer;
Begin
 TitleHit:=0;
 If (Y<0) Or (Y>=MENU_H) Then Exit;
 For M:=1 To NMENU Do
  If (X>=MenuX(M)-8) And (X<=MenuX(M)+Length(MTitle[M])*8+7) Then TitleHit:=M;
End;

Procedure DrawMenuBar;
Var M: Integer;
Begin
 Box(0,0,SCR_W-1,MENU_H-1,PAPER);
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Line(0,MENU_H-1,SCR_W-1,MENU_H-1);
 For M:=1 To NMENU Do Begin
  If M=MenuOpen Then Begin
   Box(MenuX(M)-8,0,MenuX(M)+Length(MTitle[M])*8+7,MENU_H-2,INK);
   WText(MenuX(M),5,MTitle[M]);
  End Else If (M=1) And False Then Begin
  End Else PText(MenuX(M),5,MTitle[M]);
 End;
End;

Procedure DrawDropDown;
Var X1,Y1,X2,Y2,I,Y,P: Integer; S,Sc,Lb: String; Hi: Boolean;
Begin
 If MenuOpen=0 Then Exit;
 DropRect(MenuOpen,X1,Y1,X2,Y2);
 Box(X1+3,Y1+3,X2+3,Y2+3,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 For I:=1 To MCount(MenuOpen) Do Begin
  S:=MLabel(MenuOpen,I);
  Y:=ItemY(MenuOpen,I);
  If S='-' Then Begin
   SetLineStyle(UserBitLn,$AAAA,1);
   SetColor(INK);
   Line(X1+2,Y+3,X2-2,Y+3);
   SetLineStyle(SolidLn,0,1);
  End Else If S[1]='=' Then Begin
   SetLineStyle(UserBitLn,$AAAA,1);
   SetColor(INK);
   Line(X1+2,Y+7,X2-2,Y+7);
   SetLineStyle(SolidLn,0,1);
   Box((X1+X2) Div 2-24,Y+2,(X1+X2) Div 2+24,Y+13,PAPER);
   GreyText((X1+X2) Div 2-20,Y+4,Copy(S,2,10));
  End Else Begin
   P:=Pos('|',S);
   If P>0 Then Begin Lb:=Copy(S,1,P-1);Sc:=Copy(S,P+1,20);End Else Begin Lb:=S;Sc:='';End;
   Hi:=(I=MenuHi) And MEnabled(MenuOpen,I);
   If Hi Then Box(X1+1,Y,X2-1,Y+15,INK);
   If MChecked(MenuOpen,I) Then Begin
    If Hi Then WText(X1+4,Y+4,#251) Else PText(X1+4,Y+4,#251);
   End;
   If Not MEnabled(MenuOpen,I) Then Begin
    GreyText(X1+24,Y+4,Lb);
    If Sc<>'' Then GreyText(X2-8-Length(Sc)*8,Y+4,Sc);
   End Else If Hi Then Begin
    WText(X1+24,Y+4,Lb);
    If Sc<>'' Then WText(X2-8-Length(Sc)*8,Y+4,Sc);
   End Else Begin
    PText(X1+24,Y+4,Lb);
    If Sc<>'' Then PText(X2-8-Length(Sc)*8,Y+4,Sc);
   End;
  End;
 End;
End;

{ ====================================================================== }
{                       BUREAU, ICONES, TOUCHES F                        }
{ ====================================================================== }

Procedure DrawDesktop;
Begin
 PatBar(0,MENU_H,SCR_W-1,FKEY_Y-1,PatChecker);
End;

Function IconX(I: Integer): Integer;
Begin
 IconX:=16;
End;

Function IconY(I: Integer): Integer;
Begin
 IconY:=MENU_H+14+(I-1)*66;
End;

Procedure DrawIcon(I: Integer);
Var X,Y,K,TX: Integer; S: String;
Begin
 X:=IconX(I);Y:=IconY(I);
 Box(X,Y,X+39,Y+31,PAPER);
 Frame(X,Y,X+39,Y+31);
 Box(X+1,Y+1,X+38,Y+5,INK);
 SetColor(INK);
 For K:=1 To 3 Do Line(X+K*10,Y+5,X+K*10,Y+31);
 For K:=1 To 4 Do Line(X,Y+5+K*5,X+39,Y+5+K*5);
 S:=ShortName(Sh[I].FileName);
 If Length(S)>12 Then S:=Copy(S,1,12);
 TX:=X+20-Length(S)*4;
 If TX<2 Then TX:=2;
 If I=CurS Then Begin
  Box(TX-2,Y+34,TX+Length(S)*8+1,Y+44,INK);
  WText(TX,Y+36,S);
 End Else Begin
  Box(TX-2,Y+34,TX+Length(S)*8+1,Y+44,PAPER);
  PText(TX,Y+36,S);
 End;
End;

Const
 FKTxt : Array[1..10,0..3] Of String[10] = (
  ('F1','OPEN','CLOSE','AC ON/OFF'),
  ('F2 PAGE','INSERT','DELETE','CLEAR'),
  ('F3 ROW','INSERT','DELETE','CLEAR'),
  ('F4 COL.','INSERT','DELETE','CLEAR'),
  ('F5','PASTE','CUT CELL',''),
  ('F6','CALC','',''),
  ('F7','REPEAT','SEARCH','GO TO'),
  ('F8','CALC','DEF.COL.',''),
  ('F9','PAGE -','',''),
  ('F10','PAGE +','',''));
 FK_X0 = 6;
 FK_LW = 44;
 FK_CW = 58;

Procedure SmallText(X,Y: Integer; Const S: String);
Var I: Integer;
Begin
 SetColor(INK);
 For I:=1 To Length(S) Do OutTextXY(X+(I-1)*6,Y,S[I]);
End;

Procedure DrawFKeys;
Var I,J,X,Y: Integer;
Begin
 Box(0,FKEY_Y,SCR_W-1,SCR_H-1,PAPER);
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(FK_X0-1,FKEY_Y+1,FK_X0+FK_LW+FK_CW*10,SCR_H-3);
 Line(FK_X0-1,FKEY_Y+1,SCR_W-1,FKEY_Y+1);
 For I:=0 To 10 Do Line(FK_X0+FK_LW+(I-1)*FK_CW+FK_CW-FK_CW,FKEY_Y+1,FK_X0+FK_LW+(I-1)*FK_CW+FK_CW-FK_CW,SCR_H-3);
 Line(FK_X0+FK_LW,FKEY_Y+1,FK_X0+FK_LW,SCR_H-3);
 For I:=1 To 10 Do Begin
  X:=FK_X0+FK_LW+(I-1)*FK_CW;
  Line(X,FKEY_Y+1,X,SCR_H-3);
  For J:=0 To 3 Do
   If FKTxt[I,J]<>'' Then SmallText(X+4,FKEY_Y+8+J*16,FKTxt[I,J]);
 End;
 SmallText(FK_X0+FK_LW-36,FKEY_Y+8+2*16,'SHIFT');
 SmallText(FK_X0+FK_LW-30,FKEY_Y+8+3*16,'CTRL');
 If Recording Then Begin
  Box(FK_X0+2,FKEY_Y+6,FK_X0+30,FKEY_Y+16,INK);
  WText(FK_X0+4,FKEY_Y+8,'REC');
 End;
 If Not AutoCalc Then PText(FK_X0+2,FKEY_Y+8,'MAN');
End;

{ Hit-test touches F : retourne numero 1..10 et rangee 1..3 }
Function FKeyHit(X,Y: LongInt; Var Row: Integer): Integer;
Begin
 FKeyHit:=0;Row:=0;
 If (Y<FKEY_Y+14) Or (Y>SCR_H-4) Then Exit;
 If (X<FK_X0+FK_LW) Or (X>=FK_X0+FK_LW+FK_CW*10) Then Exit;
 Row:=(Y-(FKEY_Y+14)) Div 16+1;
 If Row>3 Then Row:=3;
 FKeyHit:=(X-FK_X0-FK_LW) Div FK_CW+1;
End;

{ ====================================================================== }
{                        FENETRE FEUILLE DE CALCUL                       }
{ ====================================================================== }

Function RowsVisible(I: Integer): Integer;
Begin
 RowsVisible:=(Sh[I].WH-(TB_H+INFO_H+HDR_H+2)-SB_W-1) Div ROW_H;
 If RowsVisible<1 Then RowsVisible:=1;
End;

Procedure GridRect(I: Integer; Var X1,Y1,X2,Y2: Integer);
Begin
 X1:=Sh[I].WX+1+ROWHDR_W;
 Y1:=Sh[I].WY+TB_H+INFO_H+HDR_H+2;
 X2:=Sh[I].WX+Sh[I].WW-SB_W-1;
 Y2:=Sh[I].WY+Sh[I].WH-SB_W-1;
End;

Function FullTitle(I: Integer): String;
Var S: String;
Begin
 S:=Sh[I].FileName;
 If Sh[I].Named Then S:=FExpand(S);
 If Sh[I].Modified Then S:=S+' *';
 If Length(S)>60 Then S:=Copy(S,Length(S)-59,60);
 FullTitle:=S;
End;

Procedure DrawTitleBar(X1,Y1,X2: Integer; Const T: String; Active,HasFull: Boolean);
Begin
 Box(X1,Y1,X2,Y1+TB_H,PAPER);
 If Active Then PatBar(X1+TB_H+1,Y1+1,X2-TB_H-1,Y1+TB_H-1,PatStripe);
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y1+TB_H);
 SmallBox(X1,Y1);
 If HasFull Then Begin
  Box(X2-TB_H,Y1,X2,Y1+TB_H,PAPER);
  Frame(X2-TB_H,Y1,X2,Y1+TB_H);
  Frame(X2-TB_H+3,Y1+3,X2-3,Y1+TB_H-3);
  Frame(X2-TB_H+5,Y1+5,X2-5,Y1+TB_H-5);
 End;
 Box((X1+X2-TextW(T)) Div 2-4,Y1+1,(X1+X2+TextW(T)) Div 2+4,Y1+TB_H-1,PAPER);
 BText((X1+X2-TextW(T)) Div 2,Y1+5,T);
End;

Procedure DrawScrollV(X1,Y1,X2,Y2,Pos,Range: Integer);
{ barre verticale entre Y1..Y2 (boites haut/bas incluses) }
Var TY1,TY2,TH,TP: Integer;
Begin
 ArrowBox(X1,Y1,X2,Y1+SB_W-1,1);
 ArrowBox(X1,Y2-SB_W+1,X2,Y2,2);
 TY1:=Y1+SB_W;TY2:=Y2-SB_W;
 If TY2>TY1 Then Begin
  PatBar(X1,TY1,X2,TY2,PatTrack);
  Frame(X1,TY1-1,X2,TY2+1);
  If Range<1 Then Range:=1;
  TH:=16;
  If TY2-TY1<TH+2 Then TH:=TY2-TY1-1;
  TP:=TY1+(LongInt(Pos)*(TY2-TY1-TH)) Div Range;
  If TP<TY1 Then TP:=TY1;
  If TP+TH>TY2 Then TP:=TY2-TH;
  Box(X1,TP,X2,TP+TH,PAPER);
  Frame(X1,TP,X2,TP+TH);
 End;
End;

Procedure DrawScrollH(X1,Y1,X2,Y2,Pos,Range: Integer);
Var TX1,TX2,TW,TP: Integer;
Begin
 ArrowBox(X1,Y1,X1+SB_W-1,Y2,3);
 ArrowBox(X2-SB_W+1,Y1,X2,Y2,4);
 TX1:=X1+SB_W;TX2:=X2-SB_W;
 If TX2>TX1 Then Begin
  PatBar(TX1,Y1,TX2,Y2,PatTrack);
  Frame(TX1-1,Y1,TX2+1,Y2);
  If Range<1 Then Range:=1;
  TW:=16;
  If TX2-TX1<TW+2 Then TW:=TX2-TX1-1;
  TP:=TX1+(LongInt(Pos)*(TX2-TX1-TW)) Div Range;
  If TP<TX1 Then TP:=TX1;
  If TP+TW>TX2 Then TP:=TX2-TW;
  Box(TP,Y1,TP+TW,Y2,PAPER);
  Frame(TP,Y1,TP+TW,Y2);
 End;
End;

Function InBlock(I,P,C,R: Integer): Boolean;
Begin
 InBlock:=False;
 With Sh[I] Do
  If BlockOn And (P=BP) Then
   InBlock:=(C>=BC1) And (C<=BC2) And (R>=BR1) And (R<=BR2);
End;

Procedure DrawCellAt(I,C,R,X,Y,W,SpillW: Integer);
{ coordonnees relatives a la zone de grille }
Var T: String; IsNum,Inv: Boolean; Cl: PCell; Al,Fit,TX,L: Integer;
Begin
 Inv:=(C=Sh[I].CurC) And (R=Sh[I].CurR);
 T:=CellText(I,Sh[I].CurP,C,R,IsNum);
 Cl:=GetCell(I,Sh[I].CurP,C,R);
 If Inv Then Box(X+1,Y+1,X+W-1,Y+ROW_H-1,INK)
 Else If (Not BlockHide) And InBlock(I,Sh[I].CurP,C,R) Then PatBar(X+1,Y+1,X+W-1,Y+ROW_H-1,PatTrack);
 If T='' Then Exit;
 Al:=0;
 If Cl<>Nil Then Al:=Cl^.Align;
 If Al=0 Then If IsNum Then Al:=2 Else Al:=1;
 If Inv Or InBlock(I,Sh[I].CurP,C,R) Then SpillW:=W;
 Fit:=(W-3) Div 8;
 If (Al=1) And (Not IsNum) And (Not GridOn) Then Fit:=60;
 If (Al=1) And (Not IsNum) And GridOn Then Fit:=(SpillW-3) Div 8;
 If Length(T)>Fit Then Begin
  If IsNum Then Begin
   T:='';
   For L:=1 To Fit Do T:=T+'*';
  End Else T:=Copy(T,1,Fit);
 End;
 Case Al Of
  1: TX:=X+3;
  2: TX:=X+W-2-Length(T)*8;
  Else TX:=X+(W-Length(T)*8) Div 2;
 End;
 If Inv Then WText(TX,Y+3,T) Else PText(TX,Y+3,T);
End;

Procedure DrawSheetWin(I: Integer);
Var GX1,GY1,GX2,GY2,X,Y,C,R,VR,W,Sp,K,LX,Act: Integer; Active: Boolean; S,Ps,Cs,Rs,Ed: String;
    IsNum: Boolean; Pgs,Cws,Rws,IX: Integer; Cl: PCell;
Begin
 Active:=(I=CurS);
 With Sh[I] Do Begin
  Box(WX,WY,WX+WW,WY+WH,PAPER);
  Frame(WX,WY,WX+WW,WY+WH);
  DrawTitleBar(WX,WY,WX+WW,FullTitle(I),Active,True);
  { ligne d'information }
  Ps:=IntStr(CurP);Cs:=ColName(CurC);Rs:=IntStr(CurR)+':';
  IX:=WX+4;
  Pgs:=Length(Ps)*8+8;Cws:=Length(Cs)*8+8;Rws:=Length(Rs)*8+8;
  Frame(IX,WY+TB_H+2,IX+Pgs,WY+TB_H+INFO_H-1);
  PText(IX+4,WY+TB_H+6,Ps);
  IX:=IX+Pgs+4;
  Frame(IX,WY+TB_H+2,IX+Cws,WY+TB_H+INFO_H-1);
  PText(IX+4,WY+TB_H+6,Cs);
  IX:=IX+Cws+4;
  PText(IX+4,WY+TB_H+6,Rs);
  IX:=IX+Rws+4;
  If Active And Editing Then Begin
   Ed:=EditBuf;
   PText(IX,WY+TB_H+6,Copy(Ed,1,(WX+WW-SB_W-IX) Div 8));
   If EditPos<=(WX+WW-SB_W-IX) Div 8 Then Begin
    SetColor(INK);
    Line(IX+(EditPos-1)*8,WY+TB_H+3,IX+(EditPos-1)*8,WY+TB_H+INFO_H-2);
   End;
  End Else Begin
   S:=CellSource(I,CurP,CurC,CurR);
   PText(IX,WY+TB_H+6,Copy(S,1,(WX+WW-SB_W-IX) Div 8));
  End;
  SetColor(INK);
  Line(WX,WY+TB_H+INFO_H,WX+WW,WY+TB_H+INFO_H);
  GridRect(I,GX1,GY1,GX2,GY2);
  VR:=RowsVisible(I);
  { en-tete des colonnes }
  Box(WX+1,WY+TB_H+INFO_H+1,WX+WW-SB_W,GY1-1,PAPER);
  SetColor(INK);
  Line(WX,GY1-1,WX+WW,GY1-1);
  Line(GX1-1,WY+TB_H+INFO_H,GX1-1,GY2);
  { colonnes }
  SetViewPort(GX1,WY+TB_H+INFO_H+1,GX2,GY2,True);
  X:=0;C:=LeftC;
  While (C<=MAXCOL) And (X<=GX2-GX1) Do Begin
   W:=ColW[C];
   Cs:=ColName(C);
   If (C=CurC) And Active Then Begin
    Box(X+1,0,X+W-1,HDR_H-1,INK);
    SetColor(PAPER);
    OutTextXY(X+(W-Length(Cs)*8) Div 2,3,Cs);
    OutTextXY(X+(W-Length(Cs)*8) Div 2+1,3,Cs);
   End Else BText(X+(W-Length(Cs)*8) Div 2,3,Cs);
   SetColor(INK);
   Line(X+W-1,0,X+W-1,HDR_H);
   X:=X+W;
   Inc(C);
  End;
  SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
  { lignes + cellules }
  SetViewPort(WX+1,GY1,GX2,GY2,True);
  For R:=TopR To TopR+VR-1 Do Begin
   If R>MAXROW Then Break;
   Y:=(R-TopR)*ROW_H;
   S:=IntStr(R);
   If (R=CurR) And Active Then Begin
    Box(0,Y+1,ROWHDR_W-1,Y+ROW_H-1,INK);
    SetColor(PAPER);
    OutTextXY(ROWHDR_W-3-Length(S)*8,Y+3,S);
   End Else PText(ROWHDR_W-3-Length(S)*8,Y+3,S);
  End;
  SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
  SetViewPort(GX1,GY1,GX2,GY2,True);
  If GridOn Then Begin
   SetColor(INK);
   SetLineStyle(UserBitLn,$AAAA,1);
   For R:=0 To VR Do Line(0,R*ROW_H+ROW_H-1,GX2-GX1,R*ROW_H+ROW_H-1);
   X:=0;C:=LeftC;
   While (C<=MAXCOL) And (X<=GX2-GX1) Do Begin
    X:=X+ColW[C];
    Line(X-1,0,X-1,GY2-GY1);
    Inc(C);
   End;
   SetLineStyle(SolidLn,0,1);
  End;
  For R:=TopR To TopR+VR-1 Do Begin
   If R>MAXROW Then Break;
   Y:=(R-TopR)*ROW_H;
   X:=0;C:=LeftC;
   While (C<=MAXCOL) And (X<=GX2-GX1) Do Begin
    W:=ColW[C];
    { largeur disponible pour deborder sur les cellules vides suivantes }
    Sp:=W;K:=C+1;
    While (K<=MAXCOL) And (X+Sp<GX2-GX1+200) And (GetCell(I,CurP,K,R)=Nil) And (Sp<600) Do Begin
     Sp:=Sp+ColW[K];Inc(K);
    End;
    DrawCellAt(I,C,R,X,Y,W,Sp);
    X:=X+W;
    Inc(C);
   End;
  End;
  SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
  { barres de defilement }
  DrawScrollV(WX+WW-SB_W,WY+TB_H+1,WX+WW,WY+WH-SB_W-1,TopR,MAXROW);
  DrawScrollH(WX+1,WY+WH-SB_W,WX+WW-SB_W-1,WY+WH,LeftC,MAXCOL);
  Box(WX+WW-SB_W,WY+WH-SB_W,WX+WW,WY+WH,PAPER);
  Frame(WX+WW-SB_W,WY+WH-SB_W,WX+WW,WY+WH);
  Frame(WX+WW-SB_W+4,WY+WH-SB_W+4,WX+WW-4,WY+WH-4);
  Box(WX+WW-SB_W+7,WY+WH-SB_W+7,WX+WW-3,WY+WH-3,INK);
 End;
End;

{ ====================================================================== }
{                              GRAPHIQUES                                }
{ ====================================================================== }

Function Flr(X: Double): Double;
Begin
 If (X<0) And (Frac(X)<>0) Then Flr:=Int(X)-1 Else Flr:=Int(X);
End;

Function Ceil(X: Double): Double;
Begin
 If (X>0) And (Frac(X)<>0) Then Ceil:=Int(X)+1 Else Ceil:=Int(X);
End;

Procedure NiceScale(Mn,Mx: Double; Var Lo,Hi,Step: Double);
Var Rg,Mag,F: Double;
Begin
 If Mx<=Mn Then Mx:=Mn+1;
 Rg:=(Mx-Mn)/6;
 Mag:=Exp(Ln(10)*Flr(Ln(Rg)/Ln(10)));
 F:=Rg/Mag;
 If F<1.5 Then Step:=Mag
 Else If F<3 Then Step:=2*Mag
 Else If F<7 Then Step:=5*Mag
 Else Step:=10*Mag;
 Lo:=Flr(Mn/Step)*Step;
 Hi:=Ceil(Mx/Step)*Step;
 If Hi<=Lo Then Hi:=Lo+Step;
End;

Procedure VText(X,Y: Integer; Const S: String);
{ texte vertical (de bas en haut) : dessine puis fait pivoter }
Var I,J,W: Integer;
Begin
 W:=Length(S)*8;
 Box(0,0,W+2,9,PAPER);
 SetColor(INK);
 OutTextXY(0,0,S);
 OutTextXY(1,0,S);
 For I:=0 To W+1 Do
  For J:=0 To 8 Do
   If GetPixel(I,J)=INK Then PutPixel(X+J,Y-I,INK) Else PutPixel(X+J,Y-I,PAPER);
End;

Procedure Marker(X,Y,M: Integer);
Begin
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Case M Of
  0: Rectangle(X-3,Y-3,X+3,Y+3);
  1: Begin Line(X-3,Y,X+3,Y);Line(X,Y-3,X,Y+3);Line(X-3,Y-3,X+3,Y+3);Line(X-3,Y+3,X+3,Y-3);End;
  2: Begin Line(X-3,Y,X+3,Y);Line(X,Y-3,X,Y+3);End;
  3: Begin Line(X-3,Y-3,X+3,Y+3);Line(X-3,Y+3,X+3,Y-3);End;
  4: Begin Line(X,Y-4,X+4,Y);Line(X+4,Y,X,Y+4);Line(X,Y+4,X-4,Y);Line(X-4,Y,X,Y-4);End;
  Else PutPixel(X,Y,INK);
 End;
End;

Procedure SetSerLine(S: Integer);
Var W: Integer;
Begin
 SetColor(INK);
 W:=1;
 If GrOpt[S].Width>1 Then W:=3;
 SetLineStyle(UserBitLn,LinePat[GrOpt[S].Style Mod 6],W);
End;

Procedure DrawChart;
Var PX1,PY1,PX2,PY2,I,J,K,X,Y,PX,PY,NB,BW,CW: Integer;
    Mn,Mx,Lo,Hi,St,V,XMn,XMx,XLo,XHi,XSt,Tot,A1,A2: Double; S: String; LY: Integer;
    CX,CY,RR: Integer;
Begin
 If Not ChartOn Then Exit;
 Box(ChX1,ChY1,ChX2,ChY2,PAPER);
 Frame(ChX1,ChY1,ChX2,ChY2);
 DrawTitleBar(ChX1,ChY1,ChX2,ChTitle,True,True);
 DrawScrollV(ChX2-SB_W,ChY1+TB_H+1,ChX2,ChY2-SB_W-1,0,10);
 DrawScrollH(ChX1+1,ChY2-SB_W,ChX2-SB_W-1,ChY2,0,10);
 Box(ChX2-SB_W,ChY2-SB_W,ChX2,ChY2,PAPER);
 Frame(ChX2-SB_W,ChY2-SB_W,ChX2,ChY2);
 If ChKind=CH_REPORT Then Begin
  For I:=1 To ChRepN Do PText(ChX1+14,ChY1+TB_H+8+(I-1)*11,ChRep^[I]);
  Exit;
 End;
 PX1:=ChX1+62;PY1:=ChY1+TB_H+16;PX2:=ChX2-SB_W-18;PY2:=ChY2-SB_W-36;
 If ChKind=CH_PIE Then Begin
  Tot:=0;
  For I:=1 To ChNP Do Tot:=Tot+Abs(ChData^[1,I]);
  If Tot=0 Then Tot:=1;
  CX:=(PX1+PX2) Div 2;CY:=(PY1+PY2) Div 2;
  RR:=(PY2-PY1) Div 2-6;
  If RR>(PX2-PX1) Div 2-70 Then RR:=(PX2-PX1) Div 2-70;
  A1:=0;
  For I:=1 To ChNP Do Begin
   A2:=A1+Abs(ChData^[1,I])/Tot*360;
   If A2-A1>0.5 Then Begin
    SetPat(PatGraph[((I-1) Mod 6)+1]);
    SetColor(INK);
    SetLineStyle(SolidLn,0,1);
    PieSlice(CX,CY,Round(A1),Round(A2),RR);
    V:=(A1+A2)/2*Pi/180;
    X:=CX+Round((RR+14)*Cos(V));
    Y:=CY-Round((RR+14)*Sin(V));
    S:=ChLbl^[I]+' '+FormatNum(Abs(ChData^[1,I])/Tot*100,1)+'%';
    If X<CX Then X:=X-Length(S)*8;
    PText(X,Y-4,S);
   End;
   A1:=A2;
  End;
  SetLineStyle(SolidLn,0,1);
  Exit;
 End;
 { echelles }
 Mn:=1E300;Mx:=-1E300;
 If (ChKind=CH_SCAT) Or (ChKind=CH_FUNC) Then Begin
  XMn:=1E300;XMx:=-1E300;
  For I:=1 To ChNP Do Begin
   If ChXs^[1,I]<XMn Then XMn:=ChXs^[1,I];
   If ChXs^[1,I]>XMx Then XMx:=ChXs^[1,I];
   If ChData^[1,I]<Mn Then Mn:=ChData^[1,I];
   If ChData^[1,I]>Mx Then Mx:=ChData^[1,I];
  End;
  NiceScale(XMn,XMx,XLo,XHi,XSt);
 End Else Begin
  For K:=1 To ChNS Do
   For I:=1 To ChNP Do Begin
    If ChData^[K,I]<Mn Then Mn:=ChData^[K,I];
    If ChData^[K,I]>Mx Then Mx:=ChData^[K,I];
   End;
  If (ChKind=CH_BAR) Or (ChKind=CH_AREA) Or (ChKind=CH_HIST) Then Begin
   If Mn>0 Then Mn:=0;
   If Mx<0 Then Mx:=0;
  End;
  If ChKind=CH_CUM Then Begin Mn:=0;Mx:=100;End;
 End;
 If Mn>Mx Then Begin Mn:=0;Mx:=1;End;
 NiceScale(Mn,Mx,Lo,Hi,St);
 If (Not ChAuto) And (ChYMax>ChYMin) And (ChKind<>CH_HIST) And (ChKind<>CH_CUM) And (ChKind<>CH_SCAT) Then Begin
  Lo:=ChYMin;Hi:=ChYMax;St:=(Hi-Lo)/5;
 End;
 { grille et etiquettes Y }
 V:=Lo;
 SetColor(INK);
 While V<=Hi+St/2 Do Begin
  Y:=PY2-Round((V-Lo)/(Hi-Lo)*(PY2-PY1));
  If ChGrid Then Begin
   SetLineStyle(UserBitLn,$AAAA,1);
   Line(PX1,Y,PX2,Y);
   SetLineStyle(SolidLn,0,1);
  End;
  S:=FormatNum(V,-1);
  If Length(S)>7 Then S:=Copy(S,1,7);
  PText(PX1-6-Length(S)*8,Y-3,S);
  V:=V+St;
 End;
 SetColor(INK);
 Line(PX1,PY1,PX1,PY2);
 Line(PX1,PY2,PX2,PY2);
 If (ChKind=CH_SCAT) Or (ChKind=CH_FUNC) Then Begin
  V:=XLo;
  While V<=XHi+XSt/2 Do Begin
   X:=PX1+Round((V-XLo)/(XHi-XLo)*(PX2-PX1));
   If ChGrid Then Begin
    SetLineStyle(UserBitLn,$AAAA,1);
    Line(X,PY1,X,PY2);
    SetLineStyle(SolidLn,0,1);
   End;
   S:=FormatNum(V,-1);
   If Length(S)>6 Then S:=Copy(S,1,6);
   PText(X-Length(S)*4,PY2+6,S);
   V:=V+XSt;
  End;
  PX:=0;PY:=0;
  For I:=1 To ChNP Do Begin
   X:=PX1+Round((ChXs^[1,I]-XLo)/(XHi-XLo)*(PX2-PX1));
   Y:=PY2-Round((ChData^[1,I]-Lo)/(Hi-Lo)*(PY2-PY1));
   If ChKind=CH_SCAT Then Marker(X,Y,GrOpt[1].Marker)
   Else Begin
    SetSerLine(1);
    If I>1 Then Line(PX,PY,X,Y);
    SetLineStyle(SolidLn,0,1);
   End;
   PX:=X;PY:=Y;
  End;
  If ChReg And DrawCurve Then Begin
   SetColor(INK);
   SetLineStyle(SolidLn,0,3);
   X:=PX1+Round((XMn-XLo)/(XHi-XLo)*(PX2-PX1));
   Y:=PY2-Round(((ChIcpt+ChSlope*XMn)-Lo)/(Hi-Lo)*(PY2-PY1));
   PX:=PX1+Round((XMx-XLo)/(XHi-XLo)*(PX2-PX1));
   PY:=PY2-Round(((ChIcpt+ChSlope*XMx)-Lo)/(Hi-Lo)*(PY2-PY1));
   Line(X,Y,PX,PY);
   SetLineStyle(SolidLn,0,1);
  End;
 End Else If (ChKind=CH_HIST) Then Begin
  CW:=(PX2-PX1) Div Max2(1,ChNP);
  For I:=1 To ChNP Do Begin
   X:=PX1+(I-1)*CW;
   Y:=PY2-Round((ChData^[1,I]-Lo)/(Hi-Lo)*(PY2-PY1));
   If ChData^[1,I]>0 Then Begin
    PatBar(X+1,Y,X+CW-1,PY2-1,PatGraph[3]);
    Frame(X+1,Y,X+CW-1,PY2);
   End;
   S:=ChLbl^[I];
   If (ChNP<=12) Or (I Mod 2=1) Then PText(X+CW Div 2-Length(S)*4,PY2+6,S);
  End;
 End Else If ChKind=CH_CUM Then Begin
  XMn:=ChXs^[1,1];XMx:=ChXs^[1,ChNP];
  If XMx<=XMn Then XMx:=XMn+1;
  NiceScale(XMn,XMx,XLo,XHi,XSt);
  V:=XLo;
  While V<=XHi+XSt/2 Do Begin
   X:=PX1+Round((V-XLo)/(XHi-XLo)*(PX2-PX1));
   If ChGrid Then Begin
    SetLineStyle(UserBitLn,$AAAA,1);
    Line(X,PY1,X,PY2);
    SetLineStyle(SolidLn,0,1);
   End;
   S:=FormatNum(V,-1);
   If Length(S)>6 Then S:=Copy(S,1,6);
   PText(X-Length(S)*4,PY2+6,S);
   V:=V+XSt;
  End;
  SetColor(INK);
  SetLineStyle(SolidLn,0,3);
  PX:=PX1+Round((ChXs^[1,1]-XLo)/(XHi-XLo)*(PX2-PX1));
  PY:=PY2;
  For I:=1 To ChNP Do Begin
   X:=PX1+Round((ChXs^[1,I]-XLo)/(XHi-XLo)*(PX2-PX1));
   Y:=PY2-Round((ChData^[1,I]-Lo)/(Hi-Lo)*(PY2-PY1));
   Line(PX,PY,X,PY);
   Line(X,PY,X,Y);
   PX:=X;PY:=Y;
  End;
  SetLineStyle(SolidLn,0,1);
 End Else Begin
  { courbes, barres, aires }
  If ChKind=CH_BAR Then CW:=(PX2-PX1) Div Max2(1,ChNP)
  Else If ChNP>1 Then CW:=(PX2-PX1) Div (ChNP-1) Else CW:=PX2-PX1;
  For I:=1 To ChNP Do Begin
   If ChKind=CH_BAR Then X:=PX1+(I-1)*CW+CW Div 2 Else X:=PX1+(I-1)*CW;
   S:=ChLbl^[I];
   If Length(S)>8 Then S:=Copy(S,1,8);
   If (ChNP<=14) Or (I Mod (ChNP Div 12+1)=1) Then Begin
    Line(X,PY2,X,PY2+3);
    PText(X-Length(S)*4,PY2+6,S);
   End;
  End;
  If ChKind=CH_BAR Then Begin
   BW:=(CW-6) Div Max2(1,ChNS);
   If BW<2 Then BW:=2;
   For K:=1 To ChNS Do
    For I:=1 To ChNP Do Begin
     X:=PX1+(I-1)*CW+3+(K-1)*BW;
     Y:=PY2-Round((ChData^[K,I]-Lo)/(Hi-Lo)*(PY2-PY1));
     J:=PY2-Round((0-Lo)/(Hi-Lo)*(PY2-PY1));
     If Y<J Then Begin
      PatBar(X,Y,X+BW-1,J,PatGraph[((K-1) Mod 6)+1]);
      Frame(X,Y,X+BW-1,J);
     End Else If Y>J Then Begin
      PatBar(X,J,X+BW-1,Y,PatGraph[((K-1) Mod 6)+1]);
      Frame(X,J,X+BW-1,Y);
     End;
    End;
  End Else Begin
   For K:=1 To ChNS Do Begin
    PX:=0;PY:=0;
    For I:=1 To ChNP Do Begin
     X:=PX1+(I-1)*CW;
     Y:=PY2-Round((ChData^[K,I]-Lo)/(Hi-Lo)*(PY2-PY1));
     If ChKind=CH_AREA Then Begin
      SetPat(PatGraph[((K-1) Mod 6)+1]);
      If I>1 Then Begin
       SetColor(INK);
       SetLineStyle(SolidLn,0,1);
       J:=PY2-Round((0-Lo)/(Hi-Lo)*(PY2-PY1));
       Line(X,Y,X,J);
      End;
     End;
     SetSerLine(K);
     If I>1 Then Line(PX,PY,X,Y);
     SetLineStyle(SolidLn,0,1);
     Marker(X,Y,GrOpt[K].Marker);
     PX:=X;PY:=Y;
    End;
   End;
  End;
 End;
 { titres des axes }
 If ChXT<>'' Then BText((PX1+PX2) Div 2-Length(ChXT)*4,ChY2-SB_W-14,ChXT);
 If ChYT<>'' Then VText(ChX1+16,(PY1+PY2) Div 2+Length(ChYT)*4,ChYT);
 { legende }
 If (ChNS>1) And (ChKind<>CH_SCAT) And (ChKind<>CH_HIST) And (ChKind<>CH_CUM) And (ChKind<>CH_FUNC) Then Begin
  For K:=1 To ChNS Do Begin
   If ChKind=CH_BAR Then Begin
    PatBar(PX1+6+(K-1)*50,PY1-12,PX1+22+(K-1)*50,PY1-4,PatGraph[((K-1) Mod 6)+1]);
    Frame(PX1+6+(K-1)*50,PY1-12,PX1+22+(K-1)*50,PY1-4);
   End Else Begin
    SetSerLine(K);
    Line(PX1+6+(K-1)*50,PY1-8,PX1+22+(K-1)*50,PY1-8);
    SetLineStyle(SolidLn,0,1);
   End;
   PText(PX1+26+(K-1)*50,PY1-12,IntStr(K));
  End;
 End;
 SetLineStyle(SolidLn,0,1);
End;


{ ====================================================================== }
{                          FENETRE DE TEXTE                              }
{ ====================================================================== }

Const
 TX1 = 90;
 TY1 = 40;
 TX2 = 590;
 TY2 = 380;

Function TextRows: Integer;
Begin
 TextRows:=(TY2-TY1-TB_H-SB_W-6) Div 10;
End;

Function TextCols: Integer;
Begin
 TextCols:=(TX2-TX1-SB_W-8) Div 8;
End;

Procedure DrawTextWin;
Var I,N: Integer; T: String;
Begin
 If Not TxtOn Then Exit;
 Box(TX1,TY1,TX2,TY2,PAPER);
 Frame(TX1,TY1,TX2,TY2);
 T:='TEXT';
 If TxtName<>'' Then T:=ShortName(TxtName);
 DrawTitleBar(TX1,TY1,TX2,T,TxtFocus,True);
 DrawScrollV(TX2-SB_W,TY1+TB_H+1,TX2,TY2-SB_W-1,TxtTopL,Max2(1,TxtN));
 DrawScrollH(TX1+1,TY2-SB_W,TX2-SB_W-1,TY2,0,10);
 Box(TX2-SB_W,TY2-SB_W,TX2,TY2,PAPER);
 Frame(TX2-SB_W,TY2-SB_W,TX2,TY2);
 N:=TextRows;
 For I:=1 To N Do
  If TxtTopL+I-1<=TxtN Then PText(TX1+4,TY1+TB_H+4+(I-1)*10,Copy(TxtL^[TxtTopL+I-1],1,TextCols));
 If TxtFocus Then Begin
  SetColor(INK);
  If TxtIns Then Line(TX1+4+TxtCX*8,TY1+TB_H+4+(TxtCY-TxtTopL)*10,TX1+4+TxtCX*8,TY1+TB_H+13+(TxtCY-TxtTopL)*10)
  Else Line(TX1+4+TxtCX*8,TY1+TB_H+13+(TxtCY-TxtTopL)*10,TX1+4+TxtCX*8+7,TY1+TB_H+13+(TxtCY-TxtTopL)*10);
 End;
End;

{ ====================================================================== }
{                              DESSIN GLOBAL                             }
{ ====================================================================== }

Procedure DrawAll;
Var K: Integer;
Begin
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 DrawDesktop;
 For K:=1 To NSHEET Do DrawIcon(K);
 For K:=1 To NSHEET Do
  If Sh[ZOrder[K]].IsOpen Then DrawSheetWin(ZOrder[K]);
 DrawTextWin;
 DrawChart;
 DrawFKeys;
 DrawMenuBar;
 DrawDropDown;
 ShowMouse;
 NeedDraw:=False;
End;

{ ====================================================================== }
{                  OPERATIONS SUR LES FEUILLES                           }
{ ====================================================================== }

Var
 TmpRowIdx   : Array[0..MAXROW] Of Integer;
 TmpRowPtr   : Array[0..MAXROW] Of PRowArr;
 AdjP,AdjC1,AdjR1,AdjC2,AdjR2,AdjDC,AdjDR,AdjFP : Integer;
 ClipC,ClipR,ClipP : Integer;
 BlkTmp      : String[79];
 DummyD      : Double;

Function Tick: LongInt;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Tick:=((LongInt(H)*60+M)*60+S)*100+S100;
End;

Function EnsureRow(S,P,R: Integer): PRowArr;
Var Rw: PRowArr;
Begin
 EnsureRow:=Nil;
 If (P<0) Or (P>MAXPAGE) Or (R<0) Or (R>MAXROW) Then Exit;
 If Sh[S].Pg[P]=Nil Then Begin
  New(Sh[S].Pg[P]);
  FillChar(Sh[S].Pg[P]^,SizeOf(TPage),0);
 End;
 Rw:=Sh[S].Pg[P]^[R];
 If Rw=Nil Then Begin
  New(Rw);
  FillChar(Rw^,SizeOf(TRowArr),0);
  Sh[S].Pg[P]^[R]:=Rw;
 End;
 EnsureRow:=Rw;
End;

Procedure UsedRange(S,P: Integer; Var MaxR,MaxC: Integer);
Var R,C: Integer; Rw: PRowArr;
Begin
 MaxR:=-1;MaxC:=-1;
 If Sh[S].Pg[P]=Nil Then Exit;
 For R:=0 To MAXROW Do Begin
  Rw:=Sh[S].Pg[P]^[R];
  If Rw=Nil Then Continue;
  For C:=0 To MAXCOL Do
   If Rw^[C]<>Nil Then Begin
    If R>MaxR Then MaxR:=R;
    If C>MaxC Then MaxC:=C;
   End;
 End;
End;

Procedure EnsureVisible(I: Integer);
Var VR,GX1,GY1,GX2,GY2,W,C: Integer;
Begin
 With Sh[I] Do Begin
  VR:=RowsVisible(I);
  If CurR<TopR Then TopR:=CurR;
  If CurR>=TopR+VR Then TopR:=CurR-VR+1;
  If TopR<0 Then TopR:=0;
  GridRect(I,GX1,GY1,GX2,GY2);
  If CurC<LeftC Then LeftC:=CurC;
  Repeat
   W:=0;
   For C:=LeftC To CurC Do W:=W+ColW[C];
   If (W>GX2-GX1+1) And (LeftC<CurC) Then Inc(LeftC) Else Break;
  Until False;
 End;
End;

Procedure SyncWindows;
Begin
 { les fenetres d'une meme feuille partagent l'etat : une seule fenetre par feuille ici }
End;

Procedure GoCell(P,C,R: Integer);
Begin
 With Sh[CurS] Do Begin
  If P<0 Then P:=0;If P>MAXPAGE Then P:=MAXPAGE;
  If C<0 Then C:=0;If C>MAXCOL Then C:=MAXCOL;
  If R<0 Then R:=0;If R>MAXROW Then R:=MAXROW;
  CurP:=P;CurC:=C;CurR:=R;
 End;
 EnsureVisible(CurS);
 NeedDraw:=True;
End;

Procedure BringToFront(I: Integer);
Var K,J: Integer;
Begin
 J:=1;
 For K:=1 To NSHEET Do If ZOrder[K]=I Then J:=K;
 For K:=J To NSHEET-1 Do ZOrder[K]:=ZOrder[K+1];
 ZOrder[NSHEET]:=I;
End;

Procedure OpenSheet(I: Integer);
Begin
 Sh[I].IsOpen:=True;
 CurS:=I;
 BringToFront(I);
 TxtFocus:=False;
 NeedDraw:=True;
End;

Procedure SelectSheet(I: Integer);
Begin
 CurS:=I;
 If Sh[I].IsOpen Then BringToFront(I);
 Editing:=False;
 NeedDraw:=True;
End;

Procedure CloseSheetWin(I: Integer);
Var K: Integer;
Begin
 Sh[I].IsOpen:=False;
 Editing:=False;
 For K:=NSHEET DownTo 1 Do
  If Sh[ZOrder[K]].IsOpen Then Begin CurS:=ZOrder[K];Break;End;
 NeedDraw:=True;
End;

Procedure ToggleFull(I: Integer);
Begin
 With Sh[I] Do Begin
  If Full Then Begin
   WX:=SvX;WY:=SvY;WW:=SvW;WH:=SvH;Full:=False;
  End Else Begin
   SvX:=WX;SvY:=WY;SvW:=WW;SvH:=WH;
   WX:=0;WY:=MENU_H;WW:=SCR_W-1;WH:=FKEY_Y-MENU_H-1;Full:=True;
  End;
 End;
 EnsureVisible(I);
 NeedDraw:=True;
End;

{ ---- Adaptation des adresses dans les formules ---- }

{ Mode 0 : copie (adresses relatives decalees de AdjDC,AdjDR)
  Mode 1 : deplacement de bloc (adresses dans le bloc decalees)
  Mode 2 : insertion/suppression de ligne (AdjR1, AdjDR=+1/-1)
  Mode 3 : insertion/suppression de colonne (AdjC1, AdjDC=+1/-1) }
Function RewriteRefs(Const Src: String; Mode: Integer): String;
Var Out,SaveS: String; SaveP,Start,P,C,R: Integer; Q: Char; HasPg,AP,AC,AR: Boolean;
Begin
 SaveS:=FS;SaveP:=FP;
 FS:=Src;FP:=1;Out:='';Q:=#0;
 While FP<=Length(FS) Do Begin
  If (FS[FP]='"') Or (FS[FP]='''') Then Begin
   If Q=#0 Then Q:=FS[FP] Else If Q=FS[FP] Then Q:=#0;
   Out:=Out+FS[FP];Inc(FP);
  End
  Else If Q<>#0 Then Begin Out:=Out+FS[FP];Inc(FP);End
  Else If (UpCase(FS[FP]) In ['A'..'Z','0'..'9','$']) And
          ((FP=1) Or Not (UpCase(FS[FP-1]) In ['A'..'Z','0'..'9','_','.'])) Then Begin
   Start:=FP;
   If TryRef(AdjFP,P,C,R) Then Begin
    HasPg:=RfHasPg;AP:=RfAbsP;AC:=RfAbsC;AR:=RfAbsR;
    Case Mode Of
     0: Begin
         If Not AC Then C:=C+AdjDC;
         If Not AR Then R:=R+AdjDR;
        End;
     1: If (P=AdjP) And (C>=AdjC1) And (C<=AdjC2) And (R>=AdjR1) And (R<=AdjR2) Then Begin
         C:=C+AdjDC;R:=R+AdjDR;
        End;
     2: If (AdjP<0) Or (P=AdjP) Then Begin
         If (AdjDR>0) And (R>=AdjR1) Then R:=R+1
         Else If (AdjDR<0) And (R>AdjR1) Then R:=R-1;
        End;
     3: Begin
         If (AdjDC>0) And (C>=AdjC1) Then C:=C+1
         Else If (AdjDC<0) And (C>AdjC1) Then C:=C-1;
        End;
    End;
    If C<0 Then C:=0;If C>MAXCOL Then C:=MAXCOL;
    If R<0 Then R:=0;If R>MAXROW Then R:=MAXROW;
    If HasPg Then Begin
     If AP Then Out:=Out+'$';
     Out:=Out+IntStr(P);
    End;
    If AC Then Out:=Out+'$';
    Out:=Out+ColName(C);
    If AR Then Out:=Out+'$';
    Out:=Out+IntStr(R);
   End Else Begin
    Out:=Out+FS[FP];Inc(FP);
   End;
  End Else Begin Out:=Out+FS[FP];Inc(FP);End;
 End;
 FS:=SaveS;FP:=SaveP;
 RewriteRefs:=Out;
End;

Procedure AdjustAll(S,Mode: Integer);
Var P,R,C: Integer; Rw: PRowArr; Cl: PCell; T: String;
Begin
 For P:=0 To MAXPAGE Do Begin
  If Sh[S].Pg[P]=Nil Then Continue;
  For R:=0 To MAXROW Do Begin
   Rw:=Sh[S].Pg[P]^[R];
   If Rw=Nil Then Continue;
   For C:=0 To MAXCOL Do Begin
    Cl:=Rw^[C];
    If (Cl<>Nil) And (Cl^.Kind=CK_FORMULA) And (Cl^.Src<>Nil) Then Begin
     AdjFP:=P;
     T:=RewriteRefs(Cl^.Src^,Mode);
     If T<>Cl^.Src^ Then Begin FreeStr(Cl^.Src);Cl^.Src:=AllocStr(T);End;
    End;
   End;
  End;
 End;
 Inc(EvalGen);
End;

Procedure CopyCellTo(S,P1,C1,R1,P2,C2,R2: Integer; Shift: Boolean);
Var Sc,Dc: PCell;
Begin
 If (P1=P2) And (C1=C2) And (R1=R2) Then Exit;
 If (P2<0) Or (P2>MAXPAGE) Or (C2<0) Or (C2>MAXCOL) Or (R2<0) Or (R2>MAXROW) Then Exit;
 Sc:=GetCell(S,P1,C1,R1);
 If Sc=Nil Then Begin KillCell(S,P2,C2,R2);Exit;End;
 Dc:=MakeCell(S,P2,C2,R2);
 If Dc=Nil Then Exit;
 FreeCellData(Dc);
 Dc^.Kind:=Sc^.Kind;Dc^.Fmt:=Sc^.Fmt;Dc^.Align:=Sc^.Align;Dc^.Attr:=Sc^.Attr;Dc^.Num:=Sc^.Num;
 Dc^.Gen:=0;Dc^.Busy:=False;Dc^.Err:=False;
 If Sc^.Src<>Nil Then Begin
  If (Sc^.Kind=CK_FORMULA) And Shift Then Begin
   AdjDC:=C2-C1;AdjDR:=R2-R1;AdjFP:=P1;
   Dc^.Src:=AllocStr(RewriteRefs(Sc^.Src^,0));
  End Else Dc^.Src:=AllocStr(Sc^.Src^);
 End;
End;

Function GetBlock(Var P,C1,R1,C2,R2: Integer): Boolean;
Begin
 GetBlock:=Sh[CurS].BlockOn;
 With Sh[CurS] Do
  If BlockOn Then Begin
   P:=BP;C1:=BC1;R1:=BR1;C2:=BC2;R2:=BR2;
  End Else Begin
   P:=CurP;C1:=CurC;R1:=CurR;C2:=CurC;R2:=CurR;
  End;
End;

Procedure SetBlock(P,C1,R1,C2,R2: Integer);
Begin
 With Sh[CurS] Do Begin
  BlockOn:=True;BP:=P;
  BC1:=Min2(C1,C2);BC2:=Max2(C1,C2);BR1:=Min2(R1,R2);BR2:=Max2(R1,R2);
 End;
 NeedDraw:=True;
End;

Function BlockRangeStr: String;
Var Rg: TRange;
Begin
 With Sh[CurS] Do Begin
  Rg.P1:=BP;Rg.P2:=BP;Rg.C1:=BC1;Rg.C2:=BC2;Rg.R1:=BR1;Rg.R2:=BR2;
 End;
 BlockRangeStr:=RangeStr(Rg);
End;

Function NextTok(Var S: String): String;
Var P: Integer;
Begin
 While (Length(S)>0) And (S[1]=' ') Do Delete(S,1,1);
 P:=Pos(' ',S);
 If P=0 Then Begin NextTok:=S;S:='';End
 Else Begin NextTok:=Copy(S,1,P-1);Delete(S,1,P);End;
End;

Function ToInt(Const S: String): Integer;
Var V: LongInt; Code: Integer;
Begin
 Val(TrimStr(S),V,Code);
 If Code<>0 Then V:=0;
 ToInt:=V;
End;

Procedure CopyBlock(P,C1,R1,C2,R2,DP,DC,DR: Integer; Move: Boolean);
Var C,R,Dc0,Dr0,RS,CS,RE,CE,RStep,CStep: Integer;
Begin
 Dc0:=DC-C1;Dr0:=DR-R1;
 If Dr0>0 Then Begin RS:=R2;RE:=R1;RStep:=-1;End Else Begin RS:=R1;RE:=R2;RStep:=1;End;
 If Dc0>0 Then Begin CS:=C2;CE:=C1;CStep:=-1;End Else Begin CS:=C1;CE:=C2;CStep:=1;End;
 R:=RS;
 Repeat
  C:=CS;
  Repeat
   CopyCellTo(CurS,P,C,R,DP,C+Dc0,R+Dr0,Not Move);
   If C=CE Then Break;
   C:=C+CStep;
  Until False;
  If R=RE Then Break;
  R:=R+RStep;
 Until False;
 If Move Then Begin
  For R:=R1 To R2 Do
   For C:=C1 To C2 Do
    If Not ((P=DP) And (C>=C1+Dc0) And (C<=C2+Dc0) And (R>=R1+Dr0) And (R<=R2+Dr0)) Then KillCell(CurS,P,C,R);
  AdjP:=P;AdjC1:=C1;AdjR1:=R1;AdjC2:=C2;AdjR2:=R2;AdjDC:=Dc0;AdjDR:=Dr0;
  AdjustAll(CurS,1);
 End;
 Invalidate;
 Sh[CurS].Modified:=True;
End;

Procedure ClearBlock(P,C1,R1,C2,R2: Integer);
Var C,R: Integer; Cl: PCell;
Begin
 For R:=R1 To R2 Do
  For C:=C1 To C2 Do Begin
   Cl:=GetCell(CurS,P,C,R);
   If (Cl<>Nil) And ((Cl^.Attr And 2)=0) Then KillCell(CurS,P,C,R);
  End;
 Invalidate;
 Sh[CurS].Modified:=True;
End;

{ ---- insertion / suppression de lignes, colonnes, pages ---- }

Procedure RowShift(S,P,R: Integer; Ins: Boolean);
Var K: Integer;
Begin
 If Sh[S].Pg[P]=Nil Then Exit;
 If Ins Then Begin
  KillRow(S,P,MAXROW);
  For K:=MAXROW DownTo R+1 Do Sh[S].Pg[P]^[K]:=Sh[S].Pg[P]^[K-1];
  Sh[S].Pg[P]^[R]:=Nil;
 End Else Begin
  KillRow(S,P,R);
  For K:=R To MAXROW-1 Do Sh[S].Pg[P]^[K]:=Sh[S].Pg[P]^[K+1];
  Sh[S].Pg[P]^[MAXROW]:=Nil;
 End;
End;

Procedure InsDelRow(P,R: Integer; Ins: Boolean);
Var K: Integer;
Begin
 If LinkPages Then Begin
  For K:=0 To MAXPAGE Do RowShift(CurS,K,R,Ins);
  AdjP:=-1;
 End Else Begin
  RowShift(CurS,P,R,Ins);
  AdjP:=P;
 End;
 AdjR1:=R;
 If Ins Then AdjDR:=1 Else AdjDR:=-1;
 AdjustAll(CurS,2);
 Touch;
End;

Procedure InsDelCol(C: Integer; Ins: Boolean);
Var P,R,K: Integer; Rw: PRowArr;
Begin
 For P:=0 To MAXPAGE Do Begin
  If Sh[CurS].Pg[P]=Nil Then Continue;
  For R:=0 To MAXROW Do Begin
   Rw:=Sh[CurS].Pg[P]^[R];
   If Rw=Nil Then Continue;
   If Ins Then Begin
    KillCell(CurS,P,MAXCOL,R);
    For K:=MAXCOL DownTo C+1 Do Rw^[K]:=Rw^[K-1];
    Rw^[C]:=Nil;
   End Else Begin
    KillCell(CurS,P,C,R);
    For K:=C To MAXCOL-1 Do Rw^[K]:=Rw^[K+1];
    Rw^[MAXCOL]:=Nil;
   End;
  End;
 End;
 If Ins Then Begin
  For K:=MAXCOL DownTo C+1 Do Begin Sh[CurS].ColW[K]:=Sh[CurS].ColW[K-1];Sh[CurS].ColP[K]:=Sh[CurS].ColP[K-1];End;
 End Else Begin
  For K:=C To MAXCOL-1 Do Begin Sh[CurS].ColW[K]:=Sh[CurS].ColW[K+1];Sh[CurS].ColP[K]:=Sh[CurS].ColP[K+1];End;
 End;
 AdjC1:=C;
 If Ins Then AdjDC:=1 Else AdjDC:=-1;
 AdjustAll(CurS,3);
 Touch;
End;

Procedure InsertPage(P: Integer);
Var K: Integer;
Begin
 KillPage(CurS,MAXPAGE);
 For K:=MAXPAGE DownTo P+1 Do Sh[CurS].Pg[K]:=Sh[CurS].Pg[K-1];
 Sh[CurS].Pg[P]:=Nil;
 Touch;
End;

Procedure DeletePage(P: Integer);
Var K: Integer;
Begin
 KillPage(CurS,P);
 For K:=P To MAXPAGE-1 Do Sh[CurS].Pg[K]:=Sh[CurS].Pg[K+1];
 Sh[CurS].Pg[MAXPAGE]:=Nil;
 Touch;
End;

Procedure RenumberPages(Dir: Integer);
Var K: Integer; T: PPage;
Begin
 If Dir>0 Then Begin
  T:=Sh[CurS].Pg[MAXPAGE];
  For K:=MAXPAGE DownTo 1 Do Sh[CurS].Pg[K]:=Sh[CurS].Pg[K-1];
  Sh[CurS].Pg[0]:=T;
 End Else Begin
  T:=Sh[CurS].Pg[0];
  For K:=0 To MAXPAGE-1 Do Sh[CurS].Pg[K]:=Sh[CurS].Pg[K+1];
  Sh[CurS].Pg[MAXPAGE]:=T;
 End;
 Touch;
End;

Procedure ClearPage(P: Integer);
Begin
 KillPage(CurS,P);
 Touch;
End;

Procedure ClearRow(P,R: Integer);
Begin
 ClearBlock(P,0,R,MAXCOL,R);
End;

Procedure ClearCol(P,C: Integer);
Begin
 ClearBlock(P,C,0,C,MAXROW);
End;

{ ---- tri de lignes ---- }

Function RowKeyLess(P,C,Ra,Rb: Integer; Desc: Boolean): Boolean;
Var Va,Vb: TVal; Ca,Cb: PCell; R: Boolean;
Begin
 Ca:=GetCell(CurS,P,C,Ra);Cb:=GetCell(CurS,P,C,Rb);
 If (Ca=Nil) Or (Cb=Nil) Then Begin
  RowKeyLess:=(Cb=Nil) And (Ca<>Nil);
  Exit;
 End;
 EvalCell(CurS,P,C,Ra,Va);EvalCell(CurS,P,C,Rb,Vb);
 If (Va.K=0) And (Vb.K=0) Then R:=Va.N<Vb.N
 Else If (Va.K=1) And (Vb.K=1) Then R:=CmpStr(Va.S,Vb.S)<0
 Else R:=(Va.K=0);
 If Desc Then Begin
  If (Va.K=0) And (Vb.K=0) Then R:=Va.N>Vb.N
  Else If (Va.K=1) And (Vb.K=1) Then R:=CmpStr(Va.S,Vb.S)>0;
 End;
 RowKeyLess:=R;
End;

Procedure SortRows(P,KeyC,R1,R2: Integer; Desc: Boolean);
Var N,I,J,T,Pg: Integer;
Begin
 N:=R2-R1+1;
 If N<2 Then Exit;
 RecalcSheet(CurS);
 For I:=0 To N-1 Do TmpRowIdx[I]:=R1+I;
 For I:=1 To N-1 Do Begin
  T:=TmpRowIdx[I];
  J:=I-1;
  While (J>=0) And RowKeyLess(P,KeyC,T,TmpRowIdx[J],Desc) Do Begin
   TmpRowIdx[J+1]:=TmpRowIdx[J];
   Dec(J);
  End;
  TmpRowIdx[J+1]:=T;
 End;
 For Pg:=0 To MAXPAGE Do Begin
  If Sh[CurS].Pg[Pg]=Nil Then Continue;
  If (Pg<>P) And Not LinkPages Then Continue;
  For I:=0 To N-1 Do TmpRowPtr[I]:=Sh[CurS].Pg[Pg]^[TmpRowIdx[I]];
  For I:=0 To N-1 Do Sh[CurS].Pg[Pg]^[R1+I]:=TmpRowPtr[I];
 End;
 Touch;
End;

{ ---- transposition de blocs non necessaire ; remplissage ---- }

Procedure SetBlockContents(P,C1,R1,C2,R2: Integer; Const Txt: String);
Var C,R: Integer; T: String;
Begin
 For R:=R1 To R2 Do
  For C:=C1 To C2 Do Begin
   T:=Txt;
   If (C<>C1) Or (R<>R1) Then Begin
    AdjDC:=C-C1;AdjDR:=R-R1;AdjFP:=P;
    T:=RewriteRefs(Txt,0);
   End;
   SetEntry(CurS,P,C,R,T);
  End;
End;

Procedure SetBlockPrecision(P,C1,R1,C2,R2,Prec: Integer);
Var C,R: Integer; Cl: PCell;
Begin
 For R:=R1 To R2 Do
  For C:=C1 To C2 Do Begin
   Cl:=GetCell(CurS,P,C,R);
   If Cl=Nil Then Cl:=MakeCell(CurS,P,C,R);
   If Cl<>Nil Then Begin
    If Prec<0 Then Cl^.Fmt:=0 Else Cl^.Fmt:=Prec+1;
   End;
  End;
 Sh[CurS].Modified:=True;
End;

Procedure SetBlockAttr(P,C1,R1,C2,R2,Attr: Integer);
Var C,R: Integer; Cl: PCell;
Begin
 For R:=R1 To R2 Do
  For C:=C1 To C2 Do Begin
   Cl:=GetCell(CurS,P,C,R);
   If (Cl=Nil) And (Attr<>0) Then Cl:=MakeCell(CurS,P,C,R);
   If Cl<>Nil Then Cl^.Attr:=Attr;
  End;
 Sh[CurS].Modified:=True;
End;

Procedure SetBlockValues(P,C1,R1,C2,R2: Integer);
Var C,R: Integer; Cl: PCell; V: TVal;
Begin
 RecalcSheet(CurS);
 For R:=R1 To R2 Do
  For C:=C1 To C2 Do Begin
   Cl:=GetCell(CurS,P,C,R);
   If (Cl<>Nil) And (Cl^.Kind=CK_FORMULA) Then Begin
    EvalCell(CurS,P,C,R,V);
    FreeCellData(Cl);
    If V.K=0 Then Begin Cl^.Kind:=CK_NUM;Cl^.Num:=V.N;End
    Else If V.K=1 Then Begin Cl^.Kind:=CK_TEXT;Cl^.Src:=AllocStr(V.S);End
    Else Begin Cl^.Kind:=CK_TEXT;Cl^.Src:=AllocStr('**ERR***');End;
    Cl^.Gen:=0;
   End;
  End;
 Touch;
End;

{ ====================================================================== }
{                        ENTREE / EDITION                                }
{ ====================================================================== }

Procedure StartEdit(Fresh: Boolean; Ch: Char);
Begin
 With Sh[CurS] Do Begin
  Editing:=True;
  EditOrig:=CellSource(CurS,CurP,CurC,CurR);
  If Fresh Then Begin
   EditBuf:='';
   If Ch<>#0 Then EditBuf:=Ch;
  End Else EditBuf:=EditOrig;
  EditPos:=Length(EditBuf)+1;
 End;
 NeedDraw:=True;
End;

Procedure CommitEdit;
Begin
 With Sh[CurS] Do SetEntry(CurS,CurP,CurC,CurR,EditBuf);
 LastRepeat:=Copy(EditBuf,1,80);
 Editing:=False;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                      ENTREES / SORTIES FICHIERS                        }
{ ====================================================================== }

Function AddExt(Const N,Ext: String): String;
Var S: String;
Begin
 S:=N;
 If Pos('.',ShortName(S))=0 Then S:=S+'.'+Ext;
 AddExt:=S;
End;

Procedure PutW(Var F: File; W: Integer);
Var B: Array[0..1] Of Byte;
Begin
 B[0]:=(W Shr 8) And $FF;
 B[1]:=W And $FF;
 BlockWrite(F,B,2);
End;

Function GetW(Var F: File; Var Ok: Boolean): Integer;
Var B: Array[0..1] Of Byte; N: Word; V: LongInt;
Begin
 BlockRead(F,B,2,N);
 If N<2 Then Begin Ok:=False;GetW:=-1;Exit;End;
 V:=LongInt(B[0])*256+B[1];
 If V>32767 Then V:=V-65536;
 GetW:=V;
End;

{ Ecrit les cellules d'une zone au format 3D-CALC ; ShiftC,ShiftR decalent les adresses et les formules }
Procedure WriteCells(Var F: File; S,P1,P2,C1,C2,R1,R2,PDest,ShiftC,ShiftR: Integer);
Var P,R,C,L,Z: Integer; Cl: PCell; T: String; Rw: PRowArr; B: Byte;
Begin
 For P:=P1 To P2 Do Begin
  If Sh[S].Pg[P]=Nil Then Continue;
  For R:=R1 To R2 Do Begin
   Rw:=Sh[S].Pg[P]^[R];
   If Rw=Nil Then Continue;
   For C:=C1 To C2 Do Begin
    Cl:=Rw^[C];
    If (Cl=Nil) Or (Cl^.Kind=CK_EMPTY) Then Continue;
    T:=CellSource(S,P,C,R);
    If (Cl^.Kind=CK_FORMULA) And ((ShiftC<>0) Or (ShiftR<>0)) Then Begin
     AdjDC:=ShiftC;AdjDR:=ShiftR;AdjFP:=P;
     T:=RewriteRefs(T,0);
    End;
    PutW(F,P-P1+PDest);PutW(F,R+ShiftR);PutW(F,C+ShiftC);
    L:=Length(T)+1;
    PutW(F,L);
    BlockWrite(F,T[1],Length(T));
    B:=0;BlockWrite(F,B,1);
    If Cl^.Fmt=0 Then PutW(F,-1) Else PutW(F,Cl^.Fmt-1);
    B:=Cl^.Attr;BlockWrite(F,B,1);
   End;
  End;
 End;
End;

Function SaveSheet(S: Integer; Const Name: String): Boolean;
Var F: File;
Begin
 SaveSheet:=False;
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 PutW(F,5912);
 WriteCells(F,S,0,MAXPAGE,0,MAXCOL,0,MAXROW,0,0,0);
 PutW(F,-1);
 Close(F);
 SaveSheet:=True;
End;

{ Lit des cellules ; PDest = page ajoutee, ShiftC/ShiftR = decalage }
Function ReadCells(Var F: File; S,PDest,ShiftC,ShiftR: Integer): Boolean;
Var Ok: Boolean; P,R,C,L,Prec,I: Integer; Buf: Array[0..511] Of Char; T: String; At: Byte; N: Word; Cl: PCell;
Begin
 ReadCells:=False;
 Ok:=True;
 If GetW(F,Ok)<>5912 Then Exit;
 ReadCells:=True;
 While Ok Do Begin
  P:=GetW(F,Ok);
  If (Not Ok) Or (P<0) Then Break;
  R:=GetW(F,Ok);C:=GetW(F,Ok);L:=GetW(F,Ok);
  If (Not Ok) Or (L<1) Or (L>500) Or (R<0) Or (C<0) Or (C>MAXCOL) Or (R>MAXROW) Or (P>MAXPAGE) Then Break;
  BlockRead(F,Buf,L,N);
  If N<L Then Break;
  Prec:=GetW(F,Ok);
  BlockRead(F,At,1,N);
  If (Not Ok) Or (N<1) Then Break;
  T:='';
  I:=0;
  While (I<L) And (Buf[I]<>#0) And (Length(T)<250) Do Begin T:=T+Buf[I];Inc(I);End;
  P:=P+PDest;C:=C+ShiftC;R:=R+ShiftR;
  If (P>MAXPAGE) Or (C>MAXCOL) Or (R>MAXROW) Then Continue;
  If (T<>'') And ((ShiftC<>0) Or (ShiftR<>0)) And Not (T[1] In ['"','''']) And Not RealOf(T,DummyD) Then Begin
   AdjDC:=ShiftC;AdjDR:=ShiftR;AdjFP:=P;
   T:=RewriteRefs(T,0);
  End;
  Cl:=GetCell(S,P,C,R);
  If Cl<>Nil Then Cl^.Attr:=0;
  SetEntry(S,P,C,R,T);
  Cl:=GetCell(S,P,C,R);
  If Cl<>Nil Then Begin
   If Prec<0 Then Cl^.Fmt:=0 Else Cl^.Fmt:=Prec+1;
   Cl^.Attr:=At;
  End;
 End;
End;

{ Mode 0 : lecture ; 1 : append ; 2 : merge }
Function LoadSheet(S: Integer; Const Name: String; Mode: Integer): Boolean;
Var F: File; MR,MC,Off,P: Integer;
Begin
 LoadSheet:=False;
 {$I-}
 Assign(F,Name);
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Off:=0;
 If Mode=0 Then ResetSheet(S)
 Else If Mode=1 Then Begin
  For P:=0 To MAXPAGE Do Begin
   UsedRange(S,P,MR,MC);
   If MR+1>Off Then Off:=MR+1;
  End;
 End;
 LoadSheet:=ReadCells(F,S,0,0,Off);
 Close(F);
 Invalidate;
 Inc(EvalGen);
End;

Procedure WriteBlockFile(Const Name: String; P,C1,R1,C2,R2: Integer);
Var F: File;
Begin
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Begin MsgBox('3D-CALC+','Cannot write '+Name);Exit;End;
 PutW(F,5912);
 WriteCells(F,CurS,P,P,C1,C2,R1,R2,0,-C1,-R1);
 PutW(F,-1);
 Close(F);
End;

Function ReadBlockFile(Const Name: String): Boolean;
Var F: File;
Begin
 ReadBlockFile:=False;
 {$I-}
 Assign(F,Name);
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 ReadBlockFile:=ReadCells(F,CurS,Sh[CurS].CurP,Sh[CurS].CurC,Sh[CurS].CurR);
 Close(F);
 Touch;
End;

Function ReadWord(Var F: File): Word;
Var B: Array[0..1] Of Byte; N: Word;
Begin
 BlockRead(F,B,2,N);
 If N<2 Then ReadWord:=$FFFF Else ReadWord:=B[0]+B[1]*256;
End;

{ Lecture d'un classeur Lotus 1-2-3 (WKS/WK1) dans la page courante }
Function LoadWK1(S: Integer; Const Name: String): Boolean;
Var F: File; Op,Len,Col,Row,I: Word; Buf: Array[0..300] Of Byte; N: Word; Lbl: String;
    Nb: Array[0..7] Of Byte; Pg: Integer; Dbl: Double; SI: Integer;
Begin
 LoadWK1:=False;
 {$I-}
 Assign(F,Name);
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Pg:=Sh[S].CurP;
 Op:=ReadWord(F);
 If Op<>0 Then Begin Close(F);Exit;End;
 Len:=ReadWord(F);
 If Len>300 Then Begin Close(F);Exit;End;
 BlockRead(F,Buf,Len,N);
 While Not Eof(F) Do Begin
  Op:=ReadWord(F);Len:=ReadWord(F);
  If Op=$FFFF Then Break;
  If Len>300 Then Begin Seek(F,FilePos(F)+Len);Continue;End;
  BlockRead(F,Buf,Len,N);
  If N<Len Then Break;
  Col:=Buf[1]+Buf[2]*256;Row:=Buf[3]+Buf[4]*256;
  If (Col>MAXCOL) Or (Row>MAXROW) Then Continue;
  Case Op Of
   $0D: Begin
         I:=Buf[5]+Buf[6]*256;
         SI:=I;
         SetNumber(S,Pg,Col,Row,SI,0);
        End;
   $0E,$10: Begin
         Move(Buf[5],Nb,8);
         Move(Nb,Dbl,8);
         SetNumber(S,Pg,Col,Row,Dbl,0);
        End;
   $0F: Begin
         Lbl:='';
         I:=6;
         While (I<Len) And (Buf[I]<>0) And (Length(Lbl)<80) Do Begin Lbl:=Lbl+Chr(Buf[I]);Inc(I);End;
         SetLabel(S,Pg,Col,Row,Lbl);
        End;
  End;
 End;
 Close(F);
 Inc(EvalGen);
 LoadWK1:=True;
End;

{ Decoupe une ligne ASCII delimitee par des virgules ; texte entre apostrophes ou guillemets }
Function NextField(Var Ln: String; Var IsText: Boolean): String;
Var I: Integer; Q: Char; F: String;
Begin
 F:='';IsText:=False;
 While (Length(Ln)>0) And (Ln[1]=' ') Do Delete(Ln,1,1);
 If (Length(Ln)>0) And ((Ln[1]='"') Or (Ln[1]='''')) Then Begin
  Q:=Ln[1];IsText:=True;
  Delete(Ln,1,1);
  I:=Pos(Q,Ln);
  If I=0 Then Begin F:=Ln;Ln:='';End Else Begin F:=Copy(Ln,1,I-1);Delete(Ln,1,I);End;
  If (Length(Ln)>0) And (Ln[1]=',') Then Delete(Ln,1,1);
 End Else Begin
  I:=Pos(',',Ln);
  If I=0 Then I:=Pos(#9,Ln);
  If I=0 Then Begin F:=Ln;Ln:='';End Else Begin F:=Copy(Ln,1,I-1);Delete(Ln,1,I);End;
  F:=TrimStr(F);
 End;
 NextField:=F;
End;

Function ImportASCII(S: Integer; Const Name: String): Boolean;
Var F: Text; Ln,Fld: String; R,C,Pg: Integer; IsText: Boolean; X: Double;
Begin
 ImportASCII:=False;
 {$I-}
 Assign(F,Name);
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 Pg:=Sh[S].CurP;
 R:=Sh[S].CurR;
 While (Not Eof(F)) And (R<=MAXROW) Do Begin
  ReadLn(F,Ln);
  C:=Sh[S].CurC;
  While (Ln<>'') And (C<=MAXCOL) Do Begin
   Fld:=NextField(Ln,IsText);
   If IsText Then SetLabel(S,Pg,C,R,Fld)
   Else If RealOf(Fld,X) Then SetNumber(S,Pg,C,R,X,0)
   Else If Fld<>'' Then SetLabel(S,Pg,C,R,Fld);
   Inc(C);
  End;
  Inc(R);
 End;
 Close(F);
 Touch;
 ImportASCII:=True;
End;

Function ExportASCII(S: Integer; Const Name: String): Boolean;
Var F: Text; R,C,MR,MC,Pg: Integer; Ln,T: String; Cl: PCell; IsNum: Boolean;
Begin
 ExportASCII:=False;
 Pg:=Sh[S].CurP;
 UsedRange(S,Pg,MR,MC);
 {$I-}
 Assign(F,Name);
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Exit;
 For R:=0 To MR Do Begin
  Ln:='';
  For C:=0 To MC Do Begin
   T:=CellText(S,Pg,C,R,IsNum);
   If Not IsNum Then T:='"'+T+'"';
   Ln:=Ln+T;
   If C<MC Then Ln:=Ln+',';
  End;
  WriteLn(F,Ln);
 End;
 Close(F);
 ExportASCII:=True;
End;

{ ---- sortie fenetre : PCX, IMG, DEGAS ---- }

Function PixelBit(X,Y: Integer): Integer;
Begin
 If (X<0) Or (Y<0) Or (X>=SCR_W) Or (Y>=SCR_H) Then Begin PixelBit:=1;Exit;End;
 If GetPixel(X,Y)=INK Then PixelBit:=0 Else PixelBit:=1;
End;

Function SavePCX(Const Name: String; X1,Y1,X2,Y2: Integer): Boolean;
Var F: File; Hdr: Array[0..127] Of Byte; W,H,BPL,Y,X,K,Run: Integer; Line: Array[0..127] Of Byte; Cur: Byte;
    Out: Array[0..511] Of Byte; N: Integer;
Begin
 SavePCX:=False;
 W:=X2-X1+1;H:=Y2-Y1+1;
 BPL:=(W+7) Div 8;
 If Odd(BPL) Then Inc(BPL);
 If BPL>128 Then Exit;
 FillChar(Hdr,128,0);
 Hdr[0]:=10;Hdr[1]:=5;Hdr[2]:=1;Hdr[3]:=1;
 Hdr[8]:=(W-1) And $FF;Hdr[9]:=(W-1) Shr 8;
 Hdr[10]:=(H-1) And $FF;Hdr[11]:=(H-1) Shr 8;
 Hdr[12]:=96;Hdr[14]:=96;
 Hdr[16]:=0;Hdr[17]:=0;Hdr[18]:=0;Hdr[19]:=255;Hdr[20]:=255;Hdr[21]:=255;
 Hdr[65]:=1;Hdr[66]:=BPL And $FF;Hdr[67]:=BPL Shr 8;Hdr[68]:=1;
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 BlockWrite(F,Hdr,128);
 HideMouse;
 For Y:=Y1 To Y2 Do Begin
  FillChar(Line,SizeOf(Line),0);
  For X:=0 To BPL*8-1 Do
   If (X>=W) Or (PixelBit(X1+X,Y)=1) Then Line[X Shr 3]:=Line[X Shr 3] Or ($80 Shr (X And 7));
  N:=0;K:=0;
  While K<BPL Do Begin
   Cur:=Line[K];Run:=1;
   While (K+Run<BPL) And (Line[K+Run]=Cur) And (Run<63) Do Inc(Run);
   If (Run>1) Or (Cur>=$C0) Then Begin Out[N]:=$C0+Run;Inc(N);End;
   Out[N]:=Cur;Inc(N);
   K:=K+Run;
  End;
  BlockWrite(F,Out,N);
 End;
 ShowMouse;
 Close(F);
 SavePCX:=True;
End;

Function SaveIMG(Const Name: String; X1,Y1,X2,Y2: Integer): Boolean;
Var F: File; W,H,BPL,Y,X,K: Integer; Hd: Array[0..15] Of Byte; Line: Array[0..127] Of Byte; B: Byte;
    Hdw: Array[0..7] Of Word;
Begin
 SaveIMG:=False;
 W:=X2-X1+1;H:=Y2-Y1+1;
 BPL:=(W+7) Div 8;
 If BPL>127 Then Exit;
 Hdw[0]:=1;Hdw[1]:=8;Hdw[2]:=1;Hdw[3]:=2;Hdw[4]:=85;Hdw[5]:=85;Hdw[6]:=W;Hdw[7]:=H;
 For K:=0 To 7 Do Begin Hd[K*2]:=Hdw[K] Shr 8;Hd[K*2+1]:=Hdw[K] And $FF;End;
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 BlockWrite(F,Hd,16);
 HideMouse;
 For Y:=Y1 To Y2 Do Begin
  FillChar(Line,SizeOf(Line),0);
  For X:=0 To W-1 Do
   If PixelBit(X1+X,Y)=0 Then Line[X Shr 3]:=Line[X Shr 3] Or ($80 Shr (X And 7));
  B:=$80;BlockWrite(F,B,1);
  B:=BPL;BlockWrite(F,B,1);
  BlockWrite(F,Line,BPL);
 End;
 ShowMouse;
 Close(F);
 SaveIMG:=True;
End;

{ Degas PI3 : 640x400 monochrome (32034 octets) }
Function SaveDegas(Const Name: String; X1,Y1,X2,Y2: Integer): Boolean;
Var F: File; Y,X: Integer; Hd: Array[0..33] Of Byte; Line: Array[0..79] Of Byte;
Begin
 SaveDegas:=False;
 FillChar(Hd,SizeOf(Hd),0);
 Hd[0]:=0;Hd[1]:=2;
 Hd[2]:=$07;Hd[3]:=$77;
 {$I-}
 Assign(F,Name);
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 BlockWrite(F,Hd,34);
 HideMouse;
 For Y:=0 To 399 Do Begin
  FillChar(Line,SizeOf(Line),0);
  For X:=0 To 639 Do
   If (X1+X<=X2) And (Y1+Y<=Y2) Then Begin
    If PixelBit(X1+X,Y1+Y)=0 Then Line[X Shr 3]:=Line[X Shr 3] Or ($80 Shr (X And 7));
   End;
  BlockWrite(F,Line,80);
 End;
 ShowMouse;
 Close(F);
 SaveDegas:=True;
End;

{ ====================================================================== }
{                    STATISTIQUES ET GRAPHIQUES                          }
{ ====================================================================== }

Type
 PBArr = ^TBArr;
 TBArr = Array[1..MAXROW+1] Of Boolean;

Var
 VarN1,VarD1,VarN2,VarD2 : String[30];
 GFm       : Array[1..5,1..10] Of String[40];
 GXR,GYR,GDR : String[30];
 FlagBuf   : PBArr;
 FlagBuf2  : PBArr;
 LastRepTitle : String[40];

Procedure SortArr(A: PDArr; N: Integer);
Var Gap,I,J: Integer; T: Double;
Begin
 Gap:=N Div 2;
 While Gap>0 Do Begin
  For I:=Gap+1 To N Do Begin
   T:=A^[I];J:=I;
   While (J>Gap) And (A^[J-Gap]>T) Do Begin A^[J]:=A^[J-Gap];J:=J-Gap;End;
   A^[J]:=T;
  End;
  Gap:=Gap Div 2;
 End;
End;

Function Percentile(A: PDArr; N: Integer; Pc: Double): Double;
Var Pos1,Fr: Double; K: Integer;
Begin
 If N=0 Then Begin Percentile:=0;Exit;End;
 Pos1:=Pc/100*(N-1)+1;
 K:=Trunc(Pos1);
 Fr:=Pos1-K;
 If K>=N Then Percentile:=A^[N] Else Percentile:=A^[K]+Fr*(A^[K+1]-A^[K]);
End;

{ Lit toutes les cellules d'une plage : valeurs numeriques + indicateur }
Function ReadRangeAll(Const T: String; A: PDArr; Fl: PBArr; Var N: Integer): Boolean;
Var Rg: TRange; P,C,R: Integer; Ok: Boolean;
Begin
 ReadRangeAll:=False;N:=0;
 If Not ParseRange(T,Sh[CurS].CurP,Rg) Then Exit;
 RecalcSheet(CurS);
 For P:=Rg.P1 To Rg.P2 Do
  For R:=Rg.R1 To Rg.R2 Do
   For C:=Rg.C1 To Rg.C2 Do Begin
    If N>=MAXROW+1 Then Break;
    Inc(N);
    A^[N]:=CellNum(CurS,P,C,R,Ok);
    Fl^[N]:=Ok;
   End;
 ReadRangeAll:=True;
End;

Function ReadRangeNums(Const T: String; A: PDArr; Var N: Integer): Boolean;
Var K,M: Integer;
Begin
 ReadRangeNums:=False;
 If Not ReadRangeAll(T,A,FlagBuf,M) Then Exit;
 N:=0;
 For K:=1 To M Do If FlagBuf^[K] Then Begin Inc(N);A^[N]:=A^[K];End;
 ReadRangeNums:=True;
End;

Function NameOf(Const Addr: String): String;
Var Rg: TRange; IsNum: Boolean;
Begin
 NameOf:=Addr;
 If ParseRange(Addr,Sh[CurS].CurP,Rg) Then
  NameOf:=Copy(CellText(CurS,Rg.P1,Rg.C1,Rg.R1,IsNum),1,40);
End;

{ ---- fenetres de rapport ---- }

Procedure ChartDefaults(Kind: Integer; Const Title: String);
Begin
 ChKind:=Kind;ChTitle:=Title;ChXT:='';ChYT:='';ChReg:=False;
 ChartOn:=True;
 ChGrid:=GridOn;ChAuto:=True;ChD3:=False;
 ChX1:=70;ChY1:=MENU_H+22;ChX2:=SCR_W-12;ChY2:=FKEY_Y-14;
 If Kind=CH_REPORT Then Begin ChX1:=110;ChX2:=SCR_W-30;ChY1:=MENU_H+14;ChY2:=FKEY_Y-24;End;
 NeedDraw:=True;
End;

Procedure RepBegin(Const Title: String);
Begin
 ChRepN:=0;
 ChartDefaults(CH_REPORT,Title);
End;

Procedure RepAdd(Const S: String);
Begin
 If ChRepN<40 Then Begin
  Inc(ChRepN);
  ChRep^[ChRepN]:=Copy(S,1,64);
 End;
End;

Function PadTo(Const S: String; N: Integer): String;
Var T: String;
Begin
 T:=S;
 While Length(T)<N Do T:=T+' ';
 PadTo:=T;
End;

Function Fmt4(X: Double): String;
Begin
 Fmt4:=FormatNum(X,4);
End;

Function AskVar(Two: Boolean): Boolean;
Var N: Integer;
Begin
 AskVar:=False;
 If Sh[CurS].BlockOn And (GXR<>'') And (VarD1='') Then VarD1:=GXR;
 If Sh[CurS].BlockOn And (VarD1='') Then Begin
  VarD1:=BlockRangeStr;
 End;
 FormLbl[1]:='Name (cell)';FormVal[1]:=VarN1;
 FormLbl[2]:='Data range';FormVal[2]:=VarD1;
 N:=2;
 If Two Then Begin
  If (VarD2='') And (GYR<>'') Then VarD2:=GYR;
  FormLbl[3]:='Name Y (cell)';FormVal[3]:=VarN2;
  FormLbl[4]:='Data Y range';FormVal[4]:=VarD2;
  N:=4;
 End;
 FormFW:=20;
 If Not FormBox('Define variable',N) Then Exit;
 VarN1:=FormVal[1];VarD1:=FormVal[2];
 If Two Then Begin VarN2:=FormVal[3];VarD2:=FormVal[4];End;
 AskVar:=True;
End;

Procedure StatAverages;
Var N,I,K,Cl,BestC,Cnt: Integer; Sm,Sq,M,Mn,Mx,G,H,Dv,V3,V4,Sd,Vr,Md,W: Double; Neg: Boolean;
    Cts: Array[1..20] Of Integer;
Begin
 If Not AskVar(False) Then Exit;
 If Not ReadRangeNums(VarD1,StatBuf,N) Or (N<2) Then Begin MsgBox('3D-CALC+','The data range holds less than 2 numbers.');Exit;End;
 SortArr(StatBuf,N);
 Sm:=0;Sq:=0;G:=0;H:=0;Neg:=False;
 For I:=1 To N Do Begin
  Sm:=Sm+StatBuf^[I];
  If StatBuf^[I]<=0 Then Neg:=True Else Begin G:=G+Ln(StatBuf^[I]);H:=H+1/StatBuf^[I];End;
 End;
 M:=Sm/N;
 Dv:=0;V3:=0;V4:=0;
 For I:=1 To N Do Begin
  Dv:=Dv+Abs(StatBuf^[I]-M);
  Sq:=Sq+Sqr(StatBuf^[I]-M);
  V3:=V3+Sqr(StatBuf^[I]-M)*(StatBuf^[I]-M);
  V4:=V4+Sqr(Sqr(StatBuf^[I]-M));
 End;
 Vr:=Sq/(N-1);Sd:=Sqrt(Vr);
 Mn:=StatBuf^[1];Mx:=StatBuf^[N];
 { mode sur donnees groupees }
 For I:=1 To 20 Do Cts[I]:=0;
 W:=(Mx-Mn)/20;
 If W=0 Then W:=1;
 For I:=1 To N Do Begin
  Cl:=Trunc((StatBuf^[I]-Mn)/W)+1;
  If Cl>20 Then Cl:=20;
  Inc(Cts[Cl]);
 End;
 BestC:=1;
 For I:=2 To 20 Do If Cts[I]>Cts[BestC] Then BestC:=I;
 RepBegin('AVERAGES AND PERCENTILES');
 RepAdd('Variable : '+NameOf(VarN1));
 RepAdd('');
 RepAdd(PadTo('Number of cases',32)+IntStr(N));
 RepAdd(PadTo('Range',32)+Fmt4(Mn)+' - '+Fmt4(Mx));
 RepAdd(PadTo('Arithmetic mean',32)+Fmt4(M));
 If Neg Then Begin
  RepAdd(PadTo('Geometric mean',32)+'n/a');
  RepAdd(PadTo('Harmonic mean',32)+'n/a');
 End Else Begin
  RepAdd(PadTo('Geometric mean',32)+Fmt4(Exp(G/N)));
  RepAdd(PadTo('Harmonic mean',32)+Fmt4(N/H));
 End;
 Md:=Percentile(StatBuf,N,50);
 RepAdd(PadTo('Median',32)+Fmt4(Md));
 RepAdd(PadTo('Mode (grouped data)',32)+Fmt4(Mn+(BestC-0.5)*W));
 RepAdd(PadTo('Mean absolute deviation',32)+Fmt4(Dv/N));
 RepAdd(PadTo('Variance',32)+Fmt4(Vr));
 RepAdd(PadTo('Standard deviation',32)+Fmt4(Sd));
 RepAdd(PadTo('Standard error of the mean',32)+Fmt4(Sd/Sqrt(N)));
 If Sq>0 Then Begin
  RepAdd(PadTo('Coefficient of kurtosis',32)+Fmt4((V4/N)/Sqr(Sq/N)-3));
  RepAdd(PadTo('Skewness coefficient',32)+Fmt4((V3/N)/(Sqrt(Sq/N)*(Sq/N))));
 End;
 RepAdd('');
 RepAdd('Percentiles');
 For I:=1 To 7 Do Begin
  Case I Of
   1: K:=5;2: K:=10;3: K:=25;4: K:=50;5: K:=75;6: K:=90;Else K:=95;
  End;
  RepAdd(PadTo('  '+IntStr(K)+'%',32)+Fmt4(Percentile(StatBuf,N,K)));
 End;
End;

Procedure StatHistogram;
Var N,I,K,Cl: Integer; Mn,Mx,W: Double;
Begin
 If Not AskVar(False) Then Exit;
 If Not ReadRangeNums(VarD1,StatBuf,N) Or (N<2) Then Begin MsgBox('3D-CALC+','The data range holds less than 2 numbers.');Exit;End;
 K:=Round(1+3.3*Ln(N)/Ln(10));
 If K<4 Then K:=4;
 If K>MAXPT Then K:=MAXPT;
 Mn:=StatBuf^[1];Mx:=StatBuf^[1];
 For I:=2 To N Do Begin
  If StatBuf^[I]<Mn Then Mn:=StatBuf^[I];
  If StatBuf^[I]>Mx Then Mx:=StatBuf^[I];
 End;
 If Mx=Mn Then Mx:=Mn+1;
 W:=(Mx-Mn)/K;
 FillChar(ChData^,SizeOf(TChartD),0);
 For I:=1 To N Do Begin
  Cl:=Trunc((StatBuf^[I]-Mn)/W)+1;
  If Cl>K Then Cl:=K;
  ChData^[1,Cl]:=ChData^[1,Cl]+1;
 End;
 For I:=1 To K Do Begin
  ChXs^[1,I]:=Mn+(I-1)*W;
  ChLbl^[I]:=Copy(FormatNum(Mn+(I-1)*W+W/2,2),1,12);
 End;
 ChartDefaults(CH_HIST,'HISTOGRAM');
 ChNS:=1;ChNP:=K;
 ChXT:=NameOf(VarN1);
 ChYT:='FREQUENCY';
End;

Procedure StatCumulative;
Var N,I: Integer;
Begin
 If Not AskVar(False) Then Exit;
 If Not ReadRangeNums(VarD1,StatBuf,N) Or (N<2) Then Begin MsgBox('3D-CALC+','The data range holds less than 2 numbers.');Exit;End;
 If N>MAXPT Then N:=MAXPT;
 SortArr(StatBuf,N);
 For I:=1 To N Do Begin
  ChXs^[1,I]:=StatBuf^[I];
  ChData^[1,I]:=I/N*100;
  ChLbl^[I]:='';
 End;
 ChartDefaults(CH_CUM,'CUMULATIVE DISTRIBUTION');
 ChNS:=1;ChNP:=N;
 ChXT:=NameOf(VarN1);
 ChYT:='CUMULATIVE %';
End;

{ Collecte les paires X,Y valides ; calcule la regression }
Function Pairs(Var N: Integer): Boolean;
Var NX,NY,I,K: Integer;
Begin
 Pairs:=False;N:=0;
 If Not ReadRangeAll(VarD1,StatBuf,FlagBuf,NX) Then Exit;
 If Not ReadRangeAll(VarD2,StatBuf2,FlagBuf2,NY) Then Exit;
 K:=Min2(NX,NY);
 For I:=1 To K Do
  If FlagBuf^[I] And FlagBuf2^[I] Then Begin
   Inc(N);
   StatBuf^[N]:=StatBuf^[I];StatBuf2^[N]:=StatBuf2^[I];
  End;
 Pairs:=(N>=3);
End;

Procedure StatScatter;
Var N,I: Integer; Sx,Sy,Sxy,Sxx,D: Double;
Begin
 If Not AskVar(True) Then Exit;
 If Not Pairs(N) Then Begin MsgBox('3D-CALC+','Not enough data pairs.');Exit;End;
 Sx:=0;Sy:=0;Sxy:=0;Sxx:=0;
 For I:=1 To N Do Begin
  Sx:=Sx+StatBuf^[I];Sy:=Sy+StatBuf2^[I];Sxy:=Sxy+StatBuf^[I]*StatBuf2^[I];Sxx:=Sxx+Sqr(StatBuf^[I]);
 End;
 D:=N*Sxx-Sx*Sx;
 If N>MAXPT Then N:=MAXPT;
 For I:=1 To N Do Begin ChXs^[1,I]:=StatBuf^[I];ChData^[1,I]:=StatBuf2^[I];End;
 ChartDefaults(CH_SCAT,'SCATTER DIAGRAM');
 ChNS:=1;ChNP:=N;
 ChReg:=(D<>0);
 If D<>0 Then Begin ChSlope:=(N*Sxy-Sx*Sy)/D;ChIcpt:=(Sy-ChSlope*Sx)/N;End;
 ChXT:=NameOf(VarN1);
 ChYT:=NameOf(VarN2);
End;

Procedure StatRegression;
Var N,I: Integer; Sx,Sy,Sxy,Sxx,Syy,D,B,A,R,Mx,My,Sest,Tot,Unx,Ex,Yest,T: Double;
Begin
 If Not AskVar(True) Then Exit;
 If Not Pairs(N) Then Begin MsgBox('3D-CALC+','Not enough data pairs.');Exit;End;
 Sx:=0;Sy:=0;Sxy:=0;Sxx:=0;Syy:=0;
 For I:=1 To N Do Begin
  Sx:=Sx+StatBuf^[I];Sy:=Sy+StatBuf2^[I];Sxy:=Sxy+StatBuf^[I]*StatBuf2^[I];
  Sxx:=Sxx+Sqr(StatBuf^[I]);Syy:=Syy+Sqr(StatBuf2^[I]);
 End;
 D:=N*Sxx-Sx*Sx;
 If (D=0) Or (N*Syy-Sy*Sy<=0) Then Begin MsgBox('3D-CALC+','Cannot compute the regression.');Exit;End;
 B:=(N*Sxy-Sx*Sy)/D;A:=(Sy-B*Sx)/N;
 R:=(N*Sxy-Sx*Sy)/Sqrt(D*(N*Syy-Sy*Sy));
 Mx:=Sx/N;My:=Sy/N;
 Tot:=0;Unx:=0;Ex:=0;
 For I:=1 To N Do Begin
  Yest:=A+B*StatBuf^[I];
  Tot:=Tot+Sqr(StatBuf2^[I]-My);
  Unx:=Unx+Sqr(StatBuf2^[I]-Yest);
  Ex:=Ex+Sqr(Yest-My);
 End;
 Sest:=Sqrt(Unx/N);
 RepBegin('REGRESSION AND CORRELATION');
 RepAdd('X : '+NameOf(VarN1));
 RepAdd('Y : '+NameOf(VarN2));
 RepAdd('');
 RepAdd(PadTo('Mean of X',36)+Fmt4(Mx));
 RepAdd(PadTo('Mean of Y',36)+Fmt4(My));
 RepAdd(PadTo('Variance of X',36)+Fmt4((Sxx-Sx*Sx/N)/(N-1)));
 RepAdd(PadTo('Variance of Y',36)+Fmt4((Syy-Sy*Sy/N)/(N-1)));
 RepAdd('');
 RepAdd(PadTo('Number of cases',36)+IntStr(N));
 RepAdd(PadTo('Coefficient of determination',36)+Fmt4(R*R));
 RepAdd(PadTo('Correlation coefficient',36)+Fmt4(R));
 If Abs(R)<1 Then T:=R*Sqrt((N-2)/(1-R*R)) Else T:=0;
 RepAdd(PadTo('t-value',36)+Fmt4(T));
 RepAdd(PadTo('Degrees of freedom',36)+IntStr(N-2));
 RepAdd('');
 RepAdd('Regression line : Y = '+Fmt4(A)+' + '+Fmt4(B)+' X');
 RepAdd(PadTo('Standard error of estimate',36)+Fmt4(Sest));
 RepAdd(PadTo('Total variation',36)+Fmt4(Tot));
 RepAdd(PadTo('Unexplained variation',36)+Fmt4(Unx));
 RepAdd(PadTo('Explained variation',36)+Fmt4(Ex));
End;

{ ---- graphiques : formulaires ---- }

Function YN(Const S: String): Boolean;
Begin
 YN:=(S<>'') And (UpCase(S[1])='Y');
End;

Function ValOf(Const S: String; Def: Double): Double;
Var X: Double;
Begin
 If RealOf(S,X) Then ValOf:=X Else ValOf:=Def;
End;

Procedure ApplyGraphOpts(F: Integer; G,A,Mn,Mx,D3: Integer);
Begin
 ChGrid:=YN(FormVal[G]);
 ChAuto:=YN(FormVal[A]);
 ChYMin:=ValOf(FormVal[Mn],0);
 ChYMax:=ValOf(FormVal[Mx],1);
 ChD3:=YN(FormVal[D3]);
End;

Procedure GraphSimple(Kind: Integer);
Var N,I,K,M: Integer; Rg: TRange; T,Ttl: String; IsNum: Boolean;
Begin
 K:=Kind;
 If GFm[K,4]='' Then Begin
  GFm[K,4]:='Y';GFm[K,5]:='Y';GFm[K,6]:='0';GFm[K,7]:='100';GFm[K,8]:='N';
 End;
 If GXR<>'' Then GFm[K,2]:=GXR;
 If GDR<>'' Then GFm[K,3]:=GDR;
 FormLbl[1]:='Graph title';FormVal[1]:=GFm[K,1];
 FormLbl[2]:='Label range';FormVal[2]:=GFm[K,2];
 FormLbl[3]:='Data range';FormVal[3]:=GFm[K,3];
 FormLbl[4]:='Grid (Y/N)';FormVal[4]:=GFm[K,4];
 FormLbl[5]:='Automatic Y';FormVal[5]:=GFm[K,5];
 FormLbl[6]:='Y minimum';FormVal[6]:=GFm[K,6];
 FormLbl[7]:='Y maximum';FormVal[7]:=GFm[K,7];
 FormLbl[8]:='3D (Y/N)';FormVal[8]:=GFm[K,8];
 FormFW:=22;
 Case Kind Of
  1: T:='BAR GRAPH';
  2: T:='LINE GRAPH';
  Else T:='PIE CHART';
 End;
 If Not FormBox(T,8) Then Exit;
 For I:=1 To 8 Do GFm[K,I]:=FormVal[I];
 If Not ReadRangeNums(GFm[K,3],StatBuf,N) Or (N<1) Then Begin MsgBox('3D-CALC+','Invalid data range.');Exit;End;
 If N>MAXPT Then N:=MAXPT;
 FillChar(ChData^,SizeOf(TChartD),0);
 For I:=1 To N Do Begin ChData^[1,I]:=StatBuf^[I];ChLbl^[I]:=IntStr(I-1);End;
 If ParseRange(GFm[K,2],Sh[CurS].CurP,Rg) Then Begin
  M:=Min2(MAXPT,(Rg.R2-Rg.R1+1)*(Rg.C2-Rg.C1+1));
  For I:=0 To M-1 Do
   ChLbl^[I+1]:=Copy(CellText(CurS,Rg.P1,Rg.C1+I Mod (Rg.C2-Rg.C1+1),Rg.R1+I Div (Rg.C2-Rg.C1+1),IsNum),1,12);
 End;
 Ttl:=NameOf(GFm[K,1]);
 If Ttl='' Then Begin
  Case Kind Of 1: Ttl:='BAR GRAPH';2: Ttl:='LINE GRAPH';Else Ttl:='PIE CHART';End;
 End;
 Case Kind Of
  1: ChartDefaults(CH_BAR,Ttl);
  2: ChartDefaults(CH_LINE,Ttl);
  Else ChartDefaults(CH_PIE,Ttl);
 End;
 ApplyGraphOpts(Kind,4,5,6,7,8);
 ChNS:=1;ChNP:=N;
End;

Procedure GraphMultiple;
Var K,I,J,NR,NC,NYL: Integer; Rg,Ry,Rx: TRange; IsNum,Ok: Boolean; ByRow: Boolean; X: Double;
Begin
 K:=4;
 If GFm[K,1]='' Then Begin GFm[K,5]:='B';GFm[K,6]:='Y';GFm[K,7]:='Y';GFm[K,8]:='0';GFm[K,9]:='100';GFm[K,10]:='N';End;
 If GXR<>'' Then GFm[K,2]:=GXR;
 If GYR<>'' Then GFm[K,3]:=GYR;
 If GDR<>'' Then GFm[K,4]:=GDR;
 FormLbl[1]:='Graph title';FormLbl[2]:='X label range';FormLbl[3]:='Y label range';FormLbl[4]:='Data range';
 FormLbl[5]:='Type (B/L)';FormLbl[6]:='Grid (Y/N)';FormLbl[7]:='Automatic Y';FormLbl[8]:='Y minimum';
 FormLbl[9]:='Y maximum';FormLbl[10]:='3D (Y/N)';
 For I:=1 To 10 Do FormVal[I]:=GFm[K,I];
 FormFW:=22;
 If Not FormBox('MULTIPLE RANGE GRAPH',10) Then Exit;
 For I:=1 To 10 Do GFm[K,I]:=FormVal[I];
 RecalcSheet(CurS);
 If Not ParseRange(GFm[K,4],Sh[CurS].CurP,Rg) Then Begin MsgBox('3D-CALC+','Invalid data range.');Exit;End;
 NR:=Rg.R2-Rg.R1+1;NC:=Rg.C2-Rg.C1+1;
 NYL:=0;
 If ParseRange(GFm[K,3],Sh[CurS].CurP,Ry) Then NYL:=(Ry.R2-Ry.R1+1)*(Ry.C2-Ry.C1+1);
 ByRow:=Not ((NYL=NC) And (NYL<>NR));
 FillChar(ChData^,SizeOf(TChartD),0);
 If ByRow Then Begin ChNS:=Min2(NR,MAXSER);ChNP:=Min2(NC,MAXPT);End
 Else Begin ChNS:=Min2(NC,MAXSER);ChNP:=Min2(NR,MAXPT);End;
 For I:=1 To ChNS Do
  For J:=1 To ChNP Do Begin
   If ByRow Then X:=CellNum(CurS,Rg.P1,Rg.C1+J-1,Rg.R1+I-1,Ok)
   Else X:=CellNum(CurS,Rg.P1,Rg.C1+I-1,Rg.R1+J-1,Ok);
   ChData^[I,J]:=X;
  End;
 For J:=1 To MAXPT Do ChLbl^[J]:=IntStr(J-1);
 If ParseRange(GFm[K,2],Sh[CurS].CurP,Rx) Then
  For J:=0 To Min2(MAXPT,(Rx.R2-Rx.R1+1)*(Rx.C2-Rx.C1+1))-1 Do
   ChLbl^[J+1]:=Copy(CellText(CurS,Rx.P1,Rx.C1+J Mod (Rx.C2-Rx.C1+1),Rx.R1+J Div (Rx.C2-Rx.C1+1),IsNum),1,12);
 If UpCase(GFm[K,5][1])='L' Then ChartDefaults(CH_LINE,NameOf(GFm[K,1]))
 Else ChartDefaults(CH_BAR,NameOf(GFm[K,1]));
 ApplyGraphOpts(K,6,7,8,9,10);
End;

Procedure GraphFunction;
Var K,I,N: Integer; Rx,Ry: TRange; Mn,Mx,X,Lo,Hi: Double; Orig: String; Ok: Boolean; V: TVal;
Begin
 K:=5;
 If GFm[K,1]='' Then Begin GFm[K,4]:='-180';GFm[K,5]:='180';GFm[K,6]:='Y';GFm[K,7]:='0';GFm[K,8]:='1';End;
 FormLbl[1]:='X cell address';FormLbl[2]:='Y1 cell address';FormLbl[3]:='Title (cell)';
 FormLbl[4]:='MIN X';FormLbl[5]:='MAX X';FormLbl[6]:='Automatic Y';FormLbl[7]:='Y minimum';FormLbl[8]:='Y maximum';
 For I:=1 To 8 Do FormVal[I]:=GFm[K,I];
 FormFW:=22;
 If Not FormBox('FUNCTION GRAPH',8) Then Exit;
 For I:=1 To 8 Do GFm[K,I]:=FormVal[I];
 If Not (ParseRange(GFm[K,1],Sh[CurS].CurP,Rx) And ParseRange(GFm[K,2],Sh[CurS].CurP,Ry)) Then Begin
  MsgBox('3D-CALC+','Invalid cell address.');Exit;
 End;
 Mn:=ValOf(GFm[K,4],-1);Mx:=ValOf(GFm[K,5],1);
 If Mx<=Mn Then Begin MsgBox('3D-CALC+','MAX X must exceed MIN X.');Exit;End;
 Orig:=CellSource(CurS,Rx.P1,Rx.C1,Rx.R1);
 N:=80;
 FillChar(ChData^,SizeOf(TChartD),0);
 For I:=1 To N Do Begin
  X:=Mn+(Mx-Mn)*(I-1)/(N-1);
  SetNumber(CurS,Rx.P1,Rx.C1,Rx.R1,X,0);
  Inc(EvalGen);
  EvalCell(CurS,Ry.P1,Ry.C1,Ry.R1,V);
  ChXs^[1,I]:=X;
  If V.K=0 Then ChData^[1,I]:=V.N Else ChData^[1,I]:=0;
 End;
 SetEntry(CurS,Rx.P1,Rx.C1,Rx.R1,Orig);
 Inc(EvalGen);
 ChartDefaults(CH_FUNC,NameOf(GFm[K,3]));
 ChNS:=1;ChNP:=N;
 ChXT:=GFm[K,1];ChYT:=GFm[K,2];
 ChGrid:=True;
 ChAuto:=YN(FormVal[6]);
 ChYMin:=ValOf(FormVal[7],0);ChYMax:=ValOf(FormVal[8],1);
 ChD3:=False;
End;

{ ====================================================================== }
{                              MACROS                                    }
{ ====================================================================== }

Procedure StartRecording;
Begin
 If RecBuf=Nil Then GetMem(RecBuf,MAXKEYS*2);
 RecLen:=0;
 Recording:=True;
 NeedDraw:=True;
End;

Function AskMacroKey(Const Title: String; Var IsDesk: Boolean; Var Idx: Integer): Boolean;
Var S: String; K: Integer;
Begin
 AskMacroKey:=False;
 S:='';
 If Not InputBox(Title,'Key (F1-F10, A-Z)',S,4) Then Exit;
 S:=Upper(TrimStr(S));
 If S='' Then Exit;
 If (S[1]='F') And (Length(S)>1) Then Begin
  K:=ToInt(Copy(S,2,3));
  If (K<1) Or (K>10) Then Exit;
  IsDesk:=True;Idx:=K;
 End Else If (S[1]>='A') And (S[1]<='Z') Then Begin
  IsDesk:=False;Idx:=Ord(S[1])-65;
 End Else Exit;
 AskMacroKey:=True;
End;

Procedure StopRecording;
Var IsDesk: Boolean; Idx: Integer;
Begin
 Recording:=False;
 NeedDraw:=True;
 If RecLen=0 Then Begin MsgBox('Macro','Nothing recorded.');Exit;End;
 If Not AskMacroKey('End recording',IsDesk,Idx) Then Exit;
 If IsDesk Then Begin
  If DeskMac[Idx]=Nil Then GetMem(DeskMac[Idx],MAXKEYS*2);
  Move(RecBuf^,DeskMac[Idx]^,RecLen*2);
  DeskLen[Idx]:=RecLen;
 End Else Begin
  If Sh[CurS].SMac[Idx]=Nil Then GetMem(Sh[CurS].SMac[Idx],MAXKEYS*2);
  Move(RecBuf^,Sh[CurS].SMac[Idx]^,RecLen*2);
  Sh[CurS].SMacLen[Idx]:=RecLen;
 End;
End;

Procedure DeleteMacro;
Var IsDesk: Boolean; Idx: Integer;
Begin
 If Not AskMacroKey('Delete macro',IsDesk,Idx) Then Exit;
 If IsDesk Then Begin
  If DeskMac[Idx]<>Nil Then Begin FreeMem(DeskMac[Idx],MAXKEYS*2);DeskMac[Idx]:=Nil;DeskLen[Idx]:=0;End;
 End Else Begin
  If Sh[CurS].SMac[Idx]<>Nil Then Begin FreeMem(Sh[CurS].SMac[Idx],MAXKEYS*2);Sh[CurS].SMac[Idx]:=Nil;Sh[CurS].SMacLen[Idx]:=0;End;
 End;
End;

Procedure ListMacros;
Var L: Integer;
Begin
 LstN:=0;
 For L:=1 To 10 Do
  If DeskMac[L]<>Nil Then Begin
   Inc(LstN);
   LstItem[LstN]:='Desk   Alt+F'+IntStr(L)+'   '+IntStr(DeskLen[L])+' keys';
  End;
 For L:=0 To 25 Do
  If Sh[CurS].SMac[L]<>Nil Then Begin
   Inc(LstN);
   LstItem[LstN]:='Sheet'+IntStr(CurS)+' Alt+'+Chr(65+L)+'    '+IntStr(Sh[CurS].SMacLen[L])+' keys';
  End;
 If LstN=0 Then Begin MsgBox('Active macros','No macro defined.');Exit;End;
 ChooseBox('Active macros',1);
End;

Procedure SaveMacros;
Var F: Text; L,K: Integer;
Begin
 {$I-}
 Assign(F,'3D-CALC.MAC');
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin MsgBox('Macro','Cannot write 3D-CALC.MAC');Exit;End;
 For L:=1 To 10 Do
  If DeskMac[L]<>Nil Then Begin
   Write(F,'D ',L,' ',DeskLen[L]);
   For K:=1 To DeskLen[L] Do Write(F,' ',DeskMac[L]^[K]);
   WriteLn(F);
  End;
 For L:=0 To 25 Do
  If Sh[CurS].SMac[L]<>Nil Then Begin
   Write(F,'S ',L,' ',Sh[CurS].SMacLen[L]);
   For K:=1 To Sh[CurS].SMacLen[L] Do Write(F,' ',Sh[CurS].SMac[L]^[K]);
   WriteLn(F);
  End;
 Close(F);
 MsgBox('Macro','Macros saved in 3D-CALC.MAC');
End;

Procedure LoadMacros(Quiet: Boolean);
Var F: Text; L,N,K: Integer; V: Word; Kd: Char;
Begin
 {$I-}
 Assign(F,'3D-CALC.MAC');
 Reset(F);
 {$I+}
 If IOResult<>0 Then Begin
  If Not Quiet Then MsgBox('Macro','3D-CALC.MAC not found.');
  Exit;
 End;
 While Not Eof(F) Do Begin
  {$I-}
  Read(F,Kd,L,N);
  {$I+}
  If (IOResult<>0) Or (N<1) Or (N>MAXKEYS) Then Begin ReadLn(F);Continue;End;
  If (Kd='D') And (L>=1) And (L<=10) Then Begin
   If DeskMac[L]=Nil Then GetMem(DeskMac[L],MAXKEYS*2);
   For K:=1 To N Do Begin Read(F,V);DeskMac[L]^[K]:=V;End;
   DeskLen[L]:=N;
  End Else If (Kd='S') And (L>=0) And (L<=25) Then Begin
   If Sh[CurS].SMac[L]=Nil Then GetMem(Sh[CurS].SMac[L],MAXKEYS*2);
   For K:=1 To N Do Begin Read(F,V);Sh[CurS].SMac[L]^[K]:=V;End;
   Sh[CurS].SMacLen[L]:=N;
  End;
  ReadLn(F);
 End;
 Close(F);
 If Not Quiet Then MsgBox('Macro','Macros loaded.');
End;

{ ====================================================================== }
{                  INTERPRETE (ligne de commande / programmes)           }
{ ====================================================================== }

Var
 TmpRg : TRange;
 ProgP,ProgC,ProgR : Integer;
 ProgOut : String;
 ProgHalt : Boolean;
 ConLines : Array[1..36] Of String[78];
 ConN : Integer;

Function SplitStmt(Var S: String): String;
{ extrait la prochaine instruction (separateur ;) }
Var I,Lv: Integer; Q: Char;
Begin
 I:=1;Lv:=0;Q:=#0;
 While I<=Length(S) Do Begin
  If (S[I]='"') Or (S[I]='''') Then Begin
   If Q=#0 Then Q:=S[I] Else If Q=S[I] Then Q:=#0;
  End Else If Q=#0 Then Begin
   If S[I]='(' Then Inc(Lv) Else If S[I]=')' Then Dec(Lv)
   Else If (S[I]=';') And (Lv=0) Then Break;
  End;
  Inc(I);
 End;
 SplitStmt:=TrimStr(Copy(S,1,I-1));
 Delete(S,1,I);
End;

Function EvalExpr(Const T: String; Var V: TVal): Boolean;
Begin
 EvalExpr:=EvalString(CurS,ProgP,ProgC,ProgR,Upper(T),False,V);
End;

Function ValText(Const V: TVal): String;
Begin
 If V.K=2 Then ValText:='**ERR***'
 Else If V.K=1 Then ValText:=V.S
 Else ValText:=FormatNum(V.N,GenDec);
End;

Procedure ProgPrint(Const S: String);
Begin
 If ProgOut<>'' Then ProgOut:=ProgOut+'  ';
 ProgOut:=Copy(ProgOut+S,1,200);
End;

Procedure ExecStmt(St: String; Depth0: Integer);
Var U,Tg,Ex,Body,Rest,Var1: String; P,I,Lv,Fr,To1,V1: Integer; V: TVal; IsFormula: Boolean; X: Double;
    Rg: TRange; T2: String; Rf: TRange;
Begin
 St:=TrimStr(St);
 If (St='') Or (St[1]='''') Or (Upper(Copy(St,1,3))='REM') Then Exit;
 U:=Upper(St);
 If U='HALT' Then Begin ProgHalt:=True;Exit;End;
 If (U='CLEAR') Or (U='CLS') Then Begin ConN:=0;ProgOut:='';Exit;End;
 If Copy(U,1,4)='FOR ' Then Begin
  { for var=a to b do stmts; next }
  P:=Pos(' DO ',U);
  If P=0 Then Begin ProgPrint('SYNTAX ERROR');Exit;End;
  Ex:=Copy(St,5,P-5);
  Body:=Copy(St,P+4,200);
  I:=Pos('=',Ex);
  If I=0 Then Begin ProgPrint('SYNTAX ERROR');Exit;End;
  Var1:=Upper(TrimStr(Copy(Ex,1,I-1)));
  Ex:=Copy(Ex,I+1,100);
  I:=Pos(' TO ',Upper(Ex));
  If I=0 Then Begin ProgPrint('SYNTAX ERROR');Exit;End;
  If Not EvalExpr(Copy(Ex,1,I-1),V) Then Exit;
  Fr:=Round(V.N);
  If Not EvalExpr(Copy(Ex,I+4,50),V) Then Exit;
  To1:=Round(V.N);
  Lv:=Pos('NEXT',Upper(Body));
  If Lv>0 Then Body:=Copy(Body,1,Lv-1);
  For V1:=Fr To To1 Do Begin
   If ProgHalt Then Break;
   If Var1='ROW' Then ProgR:=V1 Else If (Var1='COL') Or (Var1='COLUMN') Then ProgC:=V1 Else If Var1='PAGE' Then ProgP:=V1;
   Rest:=Body;
   While Rest<>'' Do Begin
    T2:=SplitStmt(Rest);
    ExecStmt(T2,Depth0+1);
   End;
  End;
  Exit;
 End;
 If Copy(U,1,6)='PRINT(' Then Begin
  Ex:=Copy(St,7,Length(St)-7);
  If EvalExpr(Ex,V) Then ProgPrint(ValText(V)) Else ProgPrint('SYNTAX ERROR');
  Exit;
 End;
 { affectation : cible = expression ou cible := formule }
 IsFormula:=False;
 P:=Pos(':=',St);
 If P>0 Then Begin IsFormula:=True;Tg:=TrimStr(Copy(St,1,P-1));Ex:=TrimStr(Copy(St,P+2,200));End
 Else Begin
  P:=Pos('=',St);
  If (P>0) And (Pos('(',St)<>0) And (Pos('(',St)<P) And (Pos(')',St)>P) Then P:=0;
  If P>0 Then Begin Tg:=TrimStr(Copy(St,1,P-1));Ex:=TrimStr(Copy(St,P+1,200));End;
 End;
 If P=0 Then Begin
  { expression seule }
  If EvalExpr(St,V) Then ProgPrint(ValText(V)) Else ProgPrint('SYNTAX ERROR');
  Exit;
 End;
 Tg:=Upper(Tg);
 If Tg='ROW' Then Begin If EvalExpr(Ex,V) Then ProgR:=Round(V.N);Exit;End;
 If (Tg='COL') Or (Tg='COLUMN') Then Begin If EvalExpr(Ex,V) Then ProgC:=Round(V.N);Exit;End;
 If Tg='PAGE' Then Begin If EvalExpr(Ex,V) Then ProgP:=Round(V.N);Exit;End;
 Rf.P1:=ProgP;Rf.C1:=ProgC;Rf.R1:=ProgR;
 If (Copy(Tg,1,2)='K(') Then Begin
  If EvalExpr(Copy(Tg,3,Length(Tg)-3),V) Then Rf.C1:=Round(V.N) Else Exit;
 End Else If (Copy(Tg,1,2)='R(') Then Begin
  If EvalExpr(Copy(Tg,3,Length(Tg)-3),V) Then Rf.R1:=Round(V.N) Else Exit;
 End Else If Not ParseRange(Tg,ProgP,Rg) Then Begin ProgPrint('SYNTAX ERROR');Exit;End
 Else Begin Rf.P1:=Rg.P1;Rf.C1:=Rg.C1;Rf.R1:=Rg.R1;End;
 If (Rf.C1<0) Or (Rf.C1>MAXCOL) Or (Rf.R1<0) Or (Rf.R1>MAXROW) Then Exit;
 If IsFormula Then SetEntry(CurS,Rf.P1,Rf.C1,Rf.R1,Ex)
 Else Begin
  If EvalExpr(Ex,V) Then Begin
   If V.K=1 Then SetLabel(CurS,Rf.P1,Rf.C1,Rf.R1,V.S)
   Else If V.K=0 Then SetNumber(CurS,Rf.P1,Rf.C1,Rf.R1,V.N,0)
   Else ProgPrint('**ERR***');
  End Else ProgPrint('SYNTAX ERROR');
 End;
End;

Procedure ExecLine(Const L: String);
Var Rest,S: String;
Begin
 Rest:=L;
 While (Rest<>'') And Not ProgHalt Do Begin
  S:=SplitStmt(Rest);
  ExecStmt(S,0);
 End;
End;

Procedure ConAdd(Const S: String);
Var I: Integer;
Begin
 If ConN>=35 Then Begin
  For I:=1 To 34 Do ConLines[I]:=ConLines[I+1];
  ConN:=34;
 End;
 Inc(ConN);
 ConLines[ConN]:=Copy(S,1,78);
End;

Procedure CommandLine;
Var E: TEvent; Ln: String; Done: Boolean; I: Integer; K: Word;
    Procedure DrawCon;
    Var J: Integer;
    Begin
     HideMouse;
     Box(0,0,SCR_W-1,SCR_H-1,PAPER);
     For J:=1 To ConN Do PText(4,4+(J-1)*12,ConLines[J]);
     PText(4,4+ConN*12,'. '+Ln);
     SetColor(INK);
     Line(4+(2+Length(Ln))*8,4+ConN*12+9,4+(3+Length(Ln))*8,4+ConN*12+9);
     ShowMouse;
    End;
Begin
 ConN:=0;Ln:='';Done:=False;ProgHalt:=False;
 ProgP:=Sh[CurS].CurP;ProgC:=Sh[CurS].CurC;ProgR:=Sh[CurS].CurR;
 ConAdd('3D-CALC+ command line - type HALT to return');
 DrawCon;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   K:=E.Key;
   If K=K_ENTER Then Begin
    ConAdd('. '+Ln);
    ProgOut:='';
    ExecLine(Ln);
    If ProgOut<>'' Then ConAdd('   '+ProgOut);
    If ProgHalt Then Done:=True;
    Ln:='';
   End Else If K=K_BKSP Then Begin
    If Length(Ln)>0 Then Dec(Ln[0]);
   End Else If (K>=32) And (K<=255) And (Length(Ln)<70) Then Ln:=Ln+Chr(K);
   DrawCon;
  End;
 Until Done;
 ProgHalt:=False;
 Touch;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                         FENETRE DE TEXTE                               }
{ ====================================================================== }

Procedure TxtInit;
Var I: Integer;
Begin
 If TxtL=Nil Then New(TxtL);
 For I:=1 To 200 Do TxtL^[I]:='';
 TxtN:=1;TxtCX:=0;TxtCY:=1;TxtTopL:=1;TxtName:='';
End;

Procedure TxtOpen;
Begin
 TxtOn:=True;TxtFocus:=True;
 NeedDraw:=True;
End;

Procedure TxtScroll;
Var N: Integer;
Begin
 N:=TextRows;
 If TxtCY<TxtTopL Then TxtTopL:=TxtCY;
 If TxtCY>=TxtTopL+N Then TxtTopL:=TxtCY-N+1;
 If TxtTopL<1 Then TxtTopL:=1;
End;

Procedure TxtKey(K: Word);
Var L: String; I: Integer;
Begin
 L:=TxtL^[TxtCY];
 If TxtCX>Length(L) Then TxtCX:=Length(L);
 Case K Of
  K_UP: If TxtCY>1 Then Dec(TxtCY);
  K_DOWN: If TxtCY<TxtN Then Inc(TxtCY);
  K_LEFT: If TxtCX>0 Then Dec(TxtCX) Else If TxtCY>1 Then Begin Dec(TxtCY);TxtCX:=Length(TxtL^[TxtCY]);End;
  K_RIGHT: If TxtCX<Length(L) Then Inc(TxtCX) Else If TxtCY<TxtN Then Begin Inc(TxtCY);TxtCX:=0;End;
  K_HOME: TxtCX:=0;
  K_END: TxtCX:=Length(L);
  K_PGUP: TxtCY:=Max2(1,TxtCY-TextRows);
  K_PGDN: TxtCY:=Min2(TxtN,TxtCY+TextRows);
  K_INS: TxtIns:=Not TxtIns;
  K_CLEFT: Begin While (TxtCX>0) And (L[TxtCX]=' ') Do Dec(TxtCX);While (TxtCX>0) And (L[TxtCX]<>' ') Do Dec(TxtCX);End;
  K_CRIGHT: Begin While (TxtCX<Length(L)) And (L[TxtCX+1]<>' ') Do Inc(TxtCX);While (TxtCX<Length(L)) And (L[TxtCX+1]=' ') Do Inc(TxtCX);End;
  K_BKSP: If TxtCX>0 Then Begin
           Delete(L,TxtCX,1);Dec(TxtCX);TxtL^[TxtCY]:=L;
          End Else If TxtCY>1 Then Begin
           TxtCX:=Length(TxtL^[TxtCY-1]);
           If TxtCX+Length(L)<=78 Then Begin
            TxtL^[TxtCY-1]:=TxtL^[TxtCY-1]+L;
            For I:=TxtCY To TxtN-1 Do TxtL^[I]:=TxtL^[I+1];
            TxtL^[TxtN]:='';Dec(TxtN);Dec(TxtCY);
           End;
          End;
  K_DEL: If TxtCX<Length(L) Then Begin Delete(L,TxtCX+1,1);TxtL^[TxtCY]:=L;End
         Else If TxtCY<TxtN Then Begin
          If Length(L)+Length(TxtL^[TxtCY+1])<=78 Then Begin
           TxtL^[TxtCY]:=L+TxtL^[TxtCY+1];
           For I:=TxtCY+1 To TxtN-1 Do TxtL^[I]:=TxtL^[I+1];
           TxtL^[TxtN]:='';Dec(TxtN);
          End;
         End;
  342: Begin
        For I:=TxtCY To TxtN-1 Do TxtL^[I]:=TxtL^[I+1];
        TxtL^[TxtN]:='';
        If TxtN>1 Then Dec(TxtN);
        If TxtCY>TxtN Then TxtCY:=TxtN;
       End;
  K_ENTER: If TxtN<200 Then Begin
            For I:=TxtN DownTo TxtCY+1 Do TxtL^[I+1]:=TxtL^[I];
            TxtL^[TxtCY+1]:=Copy(L,TxtCX+1,78);
            TxtL^[TxtCY]:=Copy(L,1,TxtCX);
            Inc(TxtN);Inc(TxtCY);TxtCX:=0;
           End;
  K_TAB: Begin
          I:=4-(TxtCX Mod 4);
          While (I>0) And (Length(TxtL^[TxtCY])<78) Do Begin Insert(' ',TxtL^[TxtCY],TxtCX+1);Inc(TxtCX);Dec(I);End;
         End;
  32..255: If Length(L)<78 Then Begin
            If TxtIns Or (TxtCX>=Length(L)) Then Insert(Chr(K),L,TxtCX+1) Else L[TxtCX+1]:=Chr(K);
            TxtL^[TxtCY]:=L;Inc(TxtCX);
           End;
 End;
 TxtScroll;
 NeedDraw:=True;
End;

Procedure TxtRead(Const Name: String);
Var F: Text; Ln: String;
Begin
 {$I-}
 Assign(F,Name);
 Reset(F);
 {$I+}
 If IOResult<>0 Then Begin MsgBox('Text','Cannot read '+Name);Exit;End;
 TxtInit;
 TxtN:=0;
 While (Not Eof(F)) And (TxtN<200) Do Begin
  ReadLn(F,Ln);
  Inc(TxtN);
  TxtL^[TxtN]:=Copy(Ln,1,78);
 End;
 Close(F);
 If TxtN=0 Then TxtN:=1;
 TxtName:=Name;
 TxtOpen;
End;

Procedure TxtSave(Const Name: String);
Var F: Text; I: Integer;
Begin
 {$I-}
 Assign(F,Name);
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin MsgBox('Text','Cannot write '+Name);Exit;End;
 For I:=1 To TxtN Do WriteLn(F,TxtL^[I]);
 Close(F);
 TxtName:=Name;
End;

{ Remplace les formules @expression d'une ligne par leur resultat }
Function MergeLine(Const L: String): String;
Var Out,Ex: String; I,Lv: Integer; V: TVal; Q: Char;
Begin
 Out:='';I:=1;
 While I<=Length(L) Do Begin
  If L[I]='@' Then Begin
   Inc(I);Ex:='';Lv:=0;Q:=#0;
   While I<=Length(L) Do Begin
    If (L[I]='"') Or (L[I]='''') Then Begin
     If Q=#0 Then Q:=L[I] Else If Q=L[I] Then Q:=#0;
    End Else If Q=#0 Then Begin
     If L[I]='(' Then Inc(Lv) Else If L[I]=')' Then Dec(Lv);
     If (L[I]=' ') And (Lv<=0) Then Break;
    End;
    Ex:=Ex+L[I];Inc(I);
   End;
   If EvalExpr(Ex,V) Then Out:=Out+ValText(V) Else Out:=Out+'?';
  End Else Begin Out:=Out+L[I];Inc(I);End;
 End;
 MergeLine:=Out;
End;

Procedure TxtPrint;
Var P1,P2,C1,C2,R1,R2,P,C,R,I,N: Integer; Sel: String; V: TVal; Dest: String; F: Text; Open: Boolean; Ln: String;
Begin
 FormLbl[1]:='Page from';FormVal[1]:=IntStr(Sh[CurS].CurP);
 FormLbl[2]:='Page to';FormVal[2]:=IntStr(Sh[CurS].CurP);
 FormLbl[3]:='Column from';FormVal[3]:='A';
 FormLbl[4]:='Column to';FormVal[4]:='A';
 FormLbl[5]:='Row from';FormVal[5]:='0';
 FormLbl[6]:='Row to';FormVal[6]:='0';
 FormLbl[7]:='Select';FormVal[7]:='';
 FormLbl[8]:='Output S/D/P';FormVal[8]:='S';
 FormFW:=20;
 If Not FormBox('PRINT TEXT',8) Then Exit;
 P1:=ToInt(FormVal[1]);P2:=ToInt(FormVal[2]);
 R1:=ToInt(FormVal[5]);R2:=ToInt(FormVal[6]);
 If ParseRange(FormVal[3]+'0',0,TmpRg) Then C1:=TmpRg.C1 Else C1:=0;
 If ParseRange(FormVal[4]+'0',0,TmpRg) Then C2:=TmpRg.C1 Else C2:=0;
 Sel:=FormVal[7];Dest:=Upper(FormVal[8]);
 RecalcSheet(CurS);
 Open:=False;
 If (Dest<>'') And (Dest[1]<>'S') Then Begin
  {$I-}
  If Dest[1]='P' Then Assign(F,'PRN') Else Assign(F,'PRINT.TXT');
  Rewrite(F);
  {$I+}
  If IOResult=0 Then Open:=True Else Begin MsgBox('Print','Cannot open output.');Exit;End;
 End;
 If Not Open Then RepBegin('PRINT TEXT');
 N:=0;
 For P:=P1 To P2 Do For R:=R1 To R2 Do For C:=C1 To C2 Do Begin
  ProgP:=P;ProgC:=C;ProgR:=R;
  If Sel<>'' Then Begin
   If Not EvalExpr(Sel,V) Then Continue;
   If ToNum(V)=0 Then Continue;
  End;
  Inc(N);
  For I:=1 To TxtN Do Begin
   Ln:=MergeLine(TxtL^[I]);
   If Open Then WriteLn(F,Ln) Else RepAdd(Ln);
  End;
  If Open Then WriteLn(F,#12) Else RepAdd('');
 End;
 If Open Then Close(F);
End;

Procedure TxtProgram;
Var I: Integer;
Begin
 ProgHalt:=False;ProgOut:='';
 ProgP:=Sh[CurS].CurP;ProgC:=Sh[CurS].CurC;ProgR:=Sh[CurS].CurR;
 RepBegin('PROGRAM OUTPUT');
 For I:=1 To TxtN Do Begin
  If ProgHalt Then Break;
  ProgOut:='';
  ExecLine(TxtL^[I]);
  If ProgOut<>'' Then RepAdd(ProgOut);
 End;
 ProgHalt:=False;
 Touch;
End;

Procedure CopyBlockToText;
Var P,C1,R1,C2,R2,C,R: Integer; Ln,T: String; IsNum: Boolean;
Begin
 If Not Sh[CurS].BlockOn Then Begin MsgBox('3D-CALC+','Define a block first.');Exit;End;
 GetBlock(P,C1,R1,C2,R2);
 If Not TxtOn Then TxtOpen;
 RecalcSheet(CurS);
 For R:=R1 To R2 Do Begin
  Ln:='';
  For C:=C1 To C2 Do Begin
   T:=CellText(CurS,P,C,R,IsNum);
   While Length(T)<Sh[CurS].ColW[C] Div 8 Do If IsNum Then T:=' '+T Else T:=T+' ';
   Ln:=Ln+T+' ';
  End;
  If TxtN<200 Then Begin
   Inc(TxtN);
   TxtL^[TxtN]:=Copy(Ln,1,78);
  End;
 End;
End;

{ ====================================================================== }
{                   COMMANDES DES MENUS                                  }
{ ====================================================================== }

Var
 BegC,BegR,BegP : Integer;
 BegSet   : Boolean;
 FindStr  : String[40];
 ClipHas  : Boolean;
 ClipSrc  : String[250];
 ClipKind2: Byte;
 RepeatCmd: Integer;
 RepeatT  : LongInt;
 DirSep   : String[1];

Function ChangeExt(Const N,Ext: String): String;
Var I: Integer; S: String;
Begin
 S:=N;
 I:=Length(S);
 While (I>0) And (S[I]<>'.') And (S[I]<>'\') And (S[I]<>'/') Do Dec(I);
 If (I>0) And (S[I]='.') Then S:=Copy(S,1,I-1);
 ChangeExt:=S+'.'+Ext;
End;

Function ColFromStr(Const S: String; Var C: Integer): Boolean;
Var T: String;
Begin
 ColFromStr:=False;
 T:=Upper(TrimStr(S));
 If T='' Then Exit;
 If T[1] In ['0'..'9'] Then Begin
  C:=ToInt(T);
  ColFromStr:=(C>=0) And (C<=MAXCOL);
  Exit;
 End;
 If Not ParseRange(T+'0',0,TmpRg) Then Exit;
 C:=TmpRg.C1;
 ColFromStr:=True;
End;

Procedure AboutBox;
Var X1,Y1,X2,Y2: Integer; E: TEvent; Done: Boolean;
Begin
 X1:=200;Y1:=70;X2:=440;Y2:=330;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,'INFO',True);
 Frame(X1+16,Y1+TB_H+14,X2-16,Y1+TB_H+100);
 SetTextStyle(DefaultFont,HorizDir,2);
 SetColor(INK);
 OutTextXY(X1+30,Y1+TB_H+28,'3D-CALC +');
 SetTextStyle(DefaultFont,HorizDir,1);
 PText(X1+20,Y1+TB_H+118,'THE 3-DIMENSIONAL');
 PText(X1+20,Y1+TB_H+130,'SPREADSHEET');
 PText(X1+20,Y1+TB_H+142,'Version '+VERSION_TEXT);
 PText(X1+20,Y1+TB_H+168,'Original program by');
 PText(X1+20,Y1+TB_H+180,'FRANK SCHOONJANS');
 PText(X1+20,Y1+TB_H+204,'Pascal clone by');
 PText(X1+20,Y1+TB_H+216,'Sylvain Maltais');
 ShowMouse;
 Done:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Done:=True
  Else If E.Kind=2 Then
   If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H) Or InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True;
 Until Done;
 NeedDraw:=True;
End;

Procedure HelpBox;
Var K: Integer;
Begin
 LstN:=10;
 LstItem[1]:='Cell addressing';
 LstItem[2]:='Entering data';
 LstItem[3]:='Function keys';
 LstItem[4]:='Mathematical functions';
 LstItem[5]:='Statistical functions';
 LstItem[6]:='String functions';
 LstItem[7]:='Date and time functions';
 LstItem[8]:='Operators';
 LstItem[9]:='Blocks';
 LstItem[10]:='Macros';
 K:=ChooseBox('HELP',1);
 Case K Of
  1: MsgBox('Cell addressing','[page]column row : 0A0, B12, 1BA12|$ before page/column/row = absolute: $A$2|Range : A2:A9 or 1B1:8B1 (3D)|K(c) column, R(l) row, C(p,c,l) cell, P(p) page');
  2: MsgBox('Entering data','Type a value, text between quotes or a formula.|Return/Tab/arrows store and move, Ctrl+Enter stores only.|Esc clears the cell.|Formulas need no = sign: SUM(A2:A9)');
  3: MsgBox('Function keys','F1 open window  Sh-F1 close  Ct-F1 autocalc|F2/F3/F4 insert page/row/column (Shift delete, Ctrl clear)|F5 paste cell  Sh-F5 load cell  F6 formula->result|F7 repeat find  Sh-F7 find  Ct-F7 goto|F8 calculate  Sh-F8 define column|F9/F10 page - / +  (Shift = renumber)');
  4: MsgBox('Mathematical','ABS ACOS ASIN ATAN COS EXP FACT INT LN LOG MOD|RND ROUND SGN SIN SQR TAN  (angle unit: Settings)|PMT FV PV NPV SLN SYD DDB RATE TERM CTERM');
  5: MsgBox('Statistical','AVG COR COUNT COUNTNEG COUNTPOS COUNTPOS0 COUNTS|MAX MIN STD STDS VAR VARS SUM SUMNEG SUMPOS|FROW FCOL FPAGE HLOOKUP VLOOKUP');
  6: MsgBox('String','CHR CODE EXACT FIND LEFT LEN LOWER MID PROPER|REPEAT REPLACE RIGHT STR TRIM UPPER VAL');
  7: MsgBox('Date and time','DATE DAY MONTH YEAR DATE$ DAY$ MONTH$ NOW|TIME HOUR MINUTE SECOND TIME$');
  8: MsgBox('Operators','^  -(neg)  * /  + -|= <> < > <= >=   AND   OR|Constants: TRUE FALSE PI  Variables: COL ROW PAGE KHIGH RHIGH PHIGH');
  9: MsgBox('Blocks','Drag the mouse over cells or use Define block (^D).|^B/^E begin/end, ^M move, ^N copy, ^C cut, ^P paste|^W write, ^R read, ^Y values, ^K clear');
  10: MsgBox('Macros','Macro|Start recording ... Stop recording, then give a key:|F1-F10 desk macro, A-Z spreadsheet macro. Run with Alt+key.');
 End;
End;

Procedure RunFreeMem;
Var L: LongInt;
Begin
 {$IFDEF FPC}
 L:=GetFPCHeapStatus.CurrHeapFree;
 {$ELSE}
 L:=MemAvail;
 {$ENDIF}
 MsgBox('Free memory','Free memory : '+IntStr(L Div 1024)+' Kb');
End;

{ ---- fichiers ---- }

Function PickFile(Const Title,Mask: String; Var Name: String; Save: Boolean): Boolean;
Begin
 PickFile:=False;
 If Save Then Begin
  If Not InputBox(Title,'File name',Name,40) Then Exit;
  PickFile:=(Name<>'');
 End Else PickFile:=FileSelect(Title,Mask,Name);
End;

Procedure AfterRead;
Begin
 With Sh[CurS] Do Begin
  CurP:=0;CurC:=0;CurR:=0;TopR:=0;LeftC:=0;BlockOn:=False;Modified:=False;
 End;
 If Not Sh[CurS].IsOpen Then OpenSheet(CurS);
 If (Sh[CurS].SMac[0]<>Nil) And (PlayLen=0) Then Begin
  Move(Sh[CurS].SMac[0]^,PlayBuf^,Sh[CurS].SMacLen[0]*2);
  PlayLen:=Sh[CurS].SMacLen[0];PlayPos:=0;
 End;
 NeedDraw:=True;
End;

Procedure FileReadCmd(Mode: Integer);
Var Name: String;
Begin
 Name:=Sh[CurS].FileName;
 If Mode=0 Then Name:='';
 If Not PickFile('Read file','*.3DD',Name,False) Then Exit;
 Name:=AddExt(Name,'3DD');
 If Not FileExists(Name) Then Begin MsgBox('3D-CALC+','File not found : '+Name);Exit;End;
 If Not LoadSheet(CurS,Name,Mode) Then Begin MsgBox('3D-CALC+','Not a valid 3D-CALC file.');Exit;End;
 If Mode=0 Then Begin
  Sh[CurS].FileName:=Name;Sh[CurS].Named:=True;
  AfterRead;
 End Else Sh[CurS].Modified:=True;
 NeedDraw:=True;
End;

Procedure FileSaveAs;
Var Name: String;
Begin
 Name:=Sh[CurS].FileName;
 If Not PickFile('Save as','*.3DD',Name,True) Then Exit;
 Name:=AddExt(Name,'3DD');
 If SaveSheet(CurS,Name) Then Begin
  Sh[CurS].FileName:=Name;Sh[CurS].Named:=True;Sh[CurS].Modified:=False;
 End Else MsgBox('3D-CALC+','Cannot write '+Name);
 NeedDraw:=True;
End;

Procedure FileSave;
Begin
 If Not Sh[CurS].Named Then Begin FileSaveAs;Exit;End;
 If SaveSheet(CurS,Sh[CurS].FileName) Then Sh[CurS].Modified:=False
 Else MsgBox('3D-CALC+','Cannot write '+Sh[CurS].FileName);
 NeedDraw:=True;
End;

Procedure FileLotus;
Var Name: String;
Begin
 Name:='';
 If Not FileSelect('Read Lotus123 file','*.WK1',Name) Then Exit;
 If Not LoadWK1(CurS,Name) Then MsgBox('3D-CALC+','Not a valid WKS/WK1 file.')
 Else Sh[CurS].Modified:=True;
 NeedDraw:=True;
End;

Procedure FileImport;
Var Name: String;
Begin
 Name:='';
 If Not FileSelect('Import ASCII file','*.*',Name) Then Exit;
 If Not ImportASCII(CurS,Name) Then MsgBox('3D-CALC+','Cannot read '+Name);
 NeedDraw:=True;
End;

Procedure FileExport;
Var Name: String;
Begin
 Name:=ChangeExt(ShortName(Sh[CurS].FileName),'ASC');
 If Not InputBox('Export ASCII file','File name',Name,40) Then Exit;
 If Not ExportASCII(CurS,Name) Then MsgBox('3D-CALC+','Cannot write '+Name)
 Else MsgBox('3D-CALC+','Data exported to '+Name);
End;

Procedure QuitCmd;
Var K: Integer; Mod1: Boolean;
Begin
 Mod1:=False;
 For K:=1 To NSHEET Do If Sh[K].Modified Then Mod1:=True;
 If Mod1 Then Begin
  If Not ConfirmBox('Unsaved data. Quit anyway ?') Then Exit;
 End;
 Quit:=True;
End;

{ ---- commandes du menu Window ---- }

Procedure CmdGoto;
Var C: Integer;
Begin
 With Sh[CurS] Do Begin
  FormLbl[1]:='Page';FormVal[1]:=IntStr(CurP);
  FormLbl[2]:='Column';FormVal[2]:=ColName(CurC);
  FormLbl[3]:='Row';FormVal[3]:=IntStr(CurR);
 End;
 FormFW:=10;
 If Not FormBox('GOTO CELL',3) Then Exit;
 If Not ColFromStr(FormVal[2],C) Then C:=Sh[CurS].CurC;
 GoCell(ToInt(FormVal[1]),C,ToInt(FormVal[3]));
End;

Function CellMatches(P,C,R: Integer): Boolean;
Var T: String; IsNum: Boolean;
Begin
 CellMatches:=False;
 If GetCell(CurS,P,C,R)=Nil Then Exit;
 T:=CellText(CurS,P,C,R,IsNum);
 CellMatches:=MatchWild(FindStr,T);
End;

Procedure FindNext;
Var P,R,C,SP,SR,SC: Integer; Found: Boolean;
Begin
 If FindStr='' Then Exit;
 RecalcSheet(CurS);
 SP:=Sh[CurS].CurP;SR:=Sh[CurS].CurR;SC:=Sh[CurS].CurC;
 Found:=False;
 For P:=SP To MAXPAGE Do Begin
  If Sh[CurS].Pg[P]=Nil Then Continue;
  For R:=0 To MAXROW Do Begin
   If (P=SP) And (R<SR) Then Continue;
   If Sh[CurS].Pg[P]^[R]=Nil Then Continue;
   For C:=0 To MAXCOL Do Begin
    If (P=SP) And (R=SR) And (C<=SC) Then Continue;
    If CellMatches(P,C,R) Then Begin
     GoCell(P,C,R);Found:=True;Break;
    End;
   End;
   If Found Then Break;
  End;
  If Found Then Break;
 End;
 If Not Found Then MsgBox('Find','String not found.');
End;

Procedure CmdFind(Specify: Boolean);
Var S: String;
Begin
 If Specify Or (FindStr='') Then Begin
  S:=FindStr;
  If Not InputBox('FIND','Search for',S,30) Then Exit;
  FindStr:=Upper(S);
 End;
 FindNext;
End;

Procedure CmdDefColumn;
Var C1,C2,C,W,Pr: Integer;
Begin
 FormLbl[1]:='First column';FormVal[1]:=ColName(Sh[CurS].CurC);
 FormLbl[2]:='Last column';FormVal[2]:=ColName(Sh[CurS].CurC);
 FormLbl[3]:='Width (chars)';FormVal[3]:=IntStr((Sh[CurS].ColW[Sh[CurS].CurC]-6) Div 8);
 FormLbl[4]:='Precision';FormVal[4]:='';
 FormFW:=10;
 If Not FormBox('DEFINE COLUMN',4) Then Exit;
 If Not ColFromStr(FormVal[1],C1) Then Exit;
 If Not ColFromStr(FormVal[2],C2) Then C2:=C1;
 If C2<C1 Then Begin C:=C1;C1:=C2;C2:=C;End;
 For C:=C1 To C2 Do Begin
  If FormVal[3]<>'' Then Begin
   W:=ToInt(FormVal[3]);
   If (W>=1) And (W<=60) Then Sh[CurS].ColW[C]:=W*8+6;
  End;
  If FormVal[4]<>'' Then Begin
   Pr:=ToInt(FormVal[4]);
   If (Pr>=0) And (Pr<=9) Then Sh[CurS].ColP[C]:=Pr Else Sh[CurS].ColP[C]:=-1;
  End;
 End;
 EnsureVisible(CurS);
 Sh[CurS].Modified:=True;
End;

Procedure CmdSort;
Var C,R1,R2,MR,MC: Integer;
Begin
 UsedRange(CurS,Sh[CurS].CurP,MR,MC);
 FormLbl[1]:='Sort on column';FormVal[1]:=ColName(Sh[CurS].CurC);
 FormLbl[2]:='First row';FormVal[2]:='0';
 FormLbl[3]:='Last row';FormVal[3]:=IntStr(Max2(0,MR));
 FormLbl[4]:='Order (A/D)';FormVal[4]:='A';
 If Sh[CurS].BlockOn Then Begin
  FormVal[2]:=IntStr(Sh[CurS].BR1);FormVal[3]:=IntStr(Sh[CurS].BR2);
 End;
 FormFW:=10;
 If Not FormBox('SORT',4) Then Exit;
 If Not ColFromStr(FormVal[1],C) Then Exit;
 R1:=ToInt(FormVal[2]);R2:=ToInt(FormVal[3]);
 SortRows(Sh[CurS].CurP,C,R1,R2,UpCase(FormVal[4][1])='D');
End;

Procedure CmdCalc;
Begin
 Inc(EvalGen);
 RecalcSheet(CurS);
 NeedDraw:=True;
End;

Procedure CmdPrint;
Var P1,P2,C1,C2,R1,R2,P,C,R,MR,MC: Integer; Dest: String; F: Text; Open: Boolean; Ln,T: String; IsNum: Boolean;
Begin
 UsedRange(CurS,Sh[CurS].CurP,MR,MC);
 FormLbl[1]:='Page from';FormVal[1]:=IntStr(Sh[CurS].CurP);
 FormLbl[2]:='Page to';FormVal[2]:=IntStr(Sh[CurS].CurP);
 FormLbl[3]:='Column from';FormVal[3]:='A';
 FormLbl[4]:='Column to';FormVal[4]:=ColName(Max2(0,MC));
 FormLbl[5]:='Row from';FormVal[5]:='0';
 FormLbl[6]:='Row to';FormVal[6]:=IntStr(Max2(0,MR));
 FormLbl[7]:='Output S/D/P';FormVal[7]:='S';
 FormFW:=12;
 If Not FormBox('PRINT DATA',7) Then Exit;
 P1:=ToInt(FormVal[1]);P2:=ToInt(FormVal[2]);
 If Not ColFromStr(FormVal[3],C1) Then C1:=0;
 If Not ColFromStr(FormVal[4],C2) Then C2:=C1;
 R1:=ToInt(FormVal[5]);R2:=ToInt(FormVal[6]);
 Dest:=Upper(FormVal[7]);
 RecalcSheet(CurS);
 Open:=False;
 If (Dest<>'') And (Dest[1]<>'S') Then Begin
  {$I-}
  If Dest[1]='P' Then Assign(F,'PRN') Else Assign(F,'PRINT.TXT');
  Rewrite(F);
  {$I+}
  If IOResult<>0 Then Begin
   {$I-}
   Assign(F,'PRINT.TXT');Rewrite(F);
   {$I+}
   If IOResult<>0 Then Begin MsgBox('Print','Cannot open output.');Exit;End;
  End;
  Open:=True;
 End;
 If Not Open Then RepBegin('PRINT DATA');
 For P:=P1 To P2 Do
  For R:=R1 To R2 Do Begin
   Ln:='';
   For C:=C1 To C2 Do Begin
    T:=CellText(CurS,P,C,R,IsNum);
    While Length(T)<(Sh[CurS].ColW[C]-6) Div 8 Do If IsNum Then T:=' '+T Else T:=T+' ';
    Ln:=Ln+Copy(T,1,(Sh[CurS].ColW[C]-6) Div 8)+' ';
   End;
   If Open Then WriteLn(F,Ln) Else RepAdd(Ln);
  End;
 If Open Then Close(F);
End;

Procedure CmdClearData;
Var L: Integer;
Begin
 If Not ConfirmBox('Clear the entire spreadsheet ?') Then Exit;
 ResetSheet(CurS);
 For L:=0 To 25 Do
  If Sh[CurS].SMac[L]<>Nil Then Begin FreeMem(Sh[CurS].SMac[L],MAXKEYS*2);Sh[CurS].SMac[L]:=Nil;End;
 NeedDraw:=True;
End;

Procedure OutputWindow;
Var X1,Y1,X2,Y2,N: Integer; Ext,Nm,Dir: String; Ok: Boolean;
Begin
 DrawAll;
 If ChartOn Then Begin X1:=ChX1;Y1:=ChY1;X2:=ChX2;Y2:=ChY2;End
 Else If TxtOn And TxtFocus Then Begin X1:=TX1;Y1:=TY1;X2:=TX2;Y2:=TY2;End
 Else If Sh[CurS].IsOpen Then Begin X1:=Sh[CurS].WX;Y1:=Sh[CurS].WY;X2:=Sh[CurS].WX+Sh[CurS].WW;Y2:=Sh[CurS].WY+Sh[CurS].WH;End
 Else Begin MsgBox('Output window','No window open.');Exit;End;
 Case OutFmt Of
  1: Ext:='PI3';
  2: Ext:='IMG';
  Else Ext:='PCX';
 End;
 Dir:=GraphDir;
 {$I-}
 MkDir(Dir);
 If IOResult<>0 Then ;
 {$I+}
 If OutFmt=4 Then Nm:='PRINTER.PCX' Else Begin
  N:=1;
  Repeat
   Nm:=Dir+DirSep+'GRAPH'+Pad2(N)+'.'+Ext;
   Inc(N);
  Until (Not FileExists(Nm)) Or (N>99);
 End;
 Case OutFmt Of
  1: Ok:=SaveDegas(Nm,X1,Y1,X2,Y2);
  2: Ok:=SaveIMG(Nm,X1,Y1,X2,Y2);
  Else Ok:=SavePCX(Nm,X1,Y1,X2,Y2);
 End;
 If Ok Then MsgBox('Output window','Window saved in '+Nm) Else MsgBox('Output window','Cannot write '+Nm);
End;

{ ---- commandes du menu Block ---- }

Procedure CmdDefineBlock;
Var Rg: TRange; P,C1,R1,C2,R2,I,At,Pr: Integer; S: String; Cl: PCell;
Begin
 GetBlock(P,C1,R1,C2,R2);
 Rg.P1:=P;Rg.P2:=P;Rg.C1:=C1;Rg.C2:=C2;Rg.R1:=R1;Rg.R2:=R2;
 FormLbl[1]:='Block';FormVal[1]:=RangeStr(Rg);
 FormLbl[2]:='Set precision';FormVal[2]:='';
 FormLbl[3]:='Set attributes';FormVal[3]:='';
 FormLbl[4]:='Set contents';FormVal[4]:='';
 FormLbl[5]:='Graph info X/Y/D';FormVal[5]:='';
 FormFW:=24;
 If Not FormBox('DEFINE BLOCK',5) Then Exit;
 If Not ParseRange(FormVal[1],Sh[CurS].CurP,Rg) Then Begin MsgBox('3D-CALC+','Invalid block.');Exit;End;
 SetBlock(Rg.P1,Rg.C1,Rg.R1,Rg.C2,Rg.R2);
 P:=Rg.P1;C1:=Rg.C1;R1:=Rg.R1;C2:=Rg.C2;R2:=Rg.R2;
 If FormVal[2]<>'' Then Begin
  If UpCase(FormVal[2][1])='G' Then Pr:=-1 Else Pr:=ToInt(FormVal[2]);
  SetBlockPrecision(P,C1,R1,C2,R2,Pr);
 End;
 If FormVal[3]<>'' Then Begin
  At:=0;S:=Upper(FormVal[3]);
  If Pos('H',S)>0 Then At:=At Or 1;
  If Pos('P',S)>0 Then At:=At Or 2;
  If Pos('I',S)>0 Then At:=At Or 8;
  SetBlockAttr(P,C1,R1,C2,R2,At);
 End;
 If FormVal[4]<>'' Then SetBlockContents(P,C1,R1,C2,R2,FormVal[4]);
 If FormVal[5]<>'' Then Begin
  S:=RangeStr(Rg);
  Case UpCase(FormVal[5][1]) Of
   'X': GXR:=S;
   'Y': GYR:=S;
   'D': GDR:=S;
  End;
 End;
 Touch;
End;

Procedure CmdBlockOp(Op: Integer);
{ 1 move, 2 copy, 3 cut, 4 paste, 5 write, 6 read, 7 values, 8 clear }
Var P,C1,R1,C2,R2: Integer; Name: String;
Begin
 If (Op<>4) And (Op<>6) And Not Sh[CurS].BlockOn Then Begin
  MsgBox('3D-CALC+','No block defined.|Use Define block or drag the mouse.');Exit;
 End;
 GetBlock(P,C1,R1,C2,R2);
 Case Op Of
  1: Begin CopyBlock(P,C1,R1,C2,R2,Sh[CurS].CurP,Sh[CurS].CurC,Sh[CurS].CurR,True);
           SetBlock(Sh[CurS].CurP,Sh[CurS].CurC,Sh[CurS].CurR,Sh[CurS].CurC+C2-C1,Sh[CurS].CurR+R2-R1);End;
  2: CopyBlock(P,C1,R1,C2,R2,Sh[CurS].CurP,Sh[CurS].CurC,Sh[CurS].CurR,False);
  3: Begin WriteBlockFile('BLOCK.3DB',P,C1,R1,C2,R2);ClearBlock(P,C1,R1,C2,R2);End;
  4: Begin If Not ReadBlockFile('BLOCK.3DB') Then MsgBox('3D-CALC+','Nothing to paste.');End;
  5: Begin
      Name:='BLOCK.3DB';
      If InputBox('Write block','File name',Name,40) Then WriteBlockFile(AddExt(Name,'3DB'),P,C1,R1,C2,R2);
     End;
  6: Begin
      Name:='';
      If FileSelect('Read block','*.3DB',Name) Then
       If Not ReadBlockFile(Name) Then MsgBox('3D-CALC+','Not a 3D-CALC block file.');
     End;
  7: SetBlockValues(P,C1,R1,C2,R2);
  8: ClearBlock(P,C1,R1,C2,R2);
 End;
 NeedDraw:=True;
End;

{ ---- Options ---- }

Procedure SettingsBox;
Var OldW,I,C: Integer;
Begin
 FormLbl[1]:='Autocalc (Y/N)';If AutoCalc Then FormVal[1]:='Y' Else FormVal[1]:='N';
 FormLbl[2]:='Alert error (Y/N)';If AlertErr Then FormVal[2]:='Y' Else FormVal[2]:='N';
 FormLbl[3]:='Angle (R/D/G)';
 Case AngleMode Of 0: FormVal[3]:='D';1: FormVal[3]:='R';Else FormVal[3]:='G';End;
 FormLbl[4]:='Global width';FormVal[4]:=IntStr((DefColWid-6) Div 8);
 FormLbl[5]:='Global precision';FormVal[5]:=IntStr(GenDec);
 FormFW:=10;
 If Not FormBox('SETTINGS',5) Then Exit;
 AutoCalc:=YN(FormVal[1]);
 AlertErr:=YN(FormVal[2]);
 Case UpCase(FormVal[3][1]) Of 'R': AngleMode:=1;'G': AngleMode:=2;Else AngleMode:=0;End;
 OldW:=DefColWid;
 I:=ToInt(FormVal[4]);
 If (I>=1) And (I<=60) Then DefColWid:=I*8+6;
 For I:=1 To NSHEET Do
  For C:=0 To MAXCOL Do If Sh[I].ColW[C]=OldW Then Sh[I].ColW[C]:=DefColWid;
 I:=ToInt(FormVal[5]);
 If (I>=0) And (I<=9) Then GenDec:=I;
 Inc(EvalGen);
 NeedDraw:=True;
End;

Procedure OutputFormatBox;
Const Nm: Array[1..4] Of String[14] = ('DEGAS','IMG','PCX','SYSTEM PRINTER');
Var X1,Y1,X2,Y2,I: Integer; E: TEvent; Done,Redraw: Boolean;
Begin
 X1:=228;Y1:=130;X2:=420;Y2:=290;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,'WINDOW OUTPUT',True);
   For I:=1 To 4 Do
    Button(X1+16,Y1+TB_H+14+(I-1)*30,X2-16,Y1+TB_H+34+(I-1)*30,Nm[I],OutFmt=I,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_UP: If OutFmt>1 Then Begin Dec(OutFmt);Redraw:=True;End;
    K_DOWN: If OutFmt<4 Then Begin Inc(OutFmt);Redraw:=True;End;
    K_ENTER,K_ESC: Done:=True;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H) Or InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True;
   For I:=1 To 4 Do
    If InBox(E.X,E.Y,X1+16,Y1+TB_H+14+(I-1)*30,X2-16,Y1+TB_H+34+(I-1)*30) Then Begin OutFmt:=I;Redraw:=True;End;
  End;
 Until Done;
 NeedDraw:=True;
End;

Procedure PathsBox;
Begin
 FormLbl[1]:='Graph folder';FormVal[1]:=GraphDir;
 FormFW:=30;
 If FormBox('PATHS',1) Then Begin
  If FormVal[1]<>'' Then GraphDir:=FormVal[1];
 End;
End;

Procedure GraphOptionsBox;
Var X1,Y1,X2,Y2,I,Y: Integer; E: TEvent; Done,Redraw: Boolean;
Begin
 X1:=108;Y1:=118;X2:=530;Y2:=300;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,'GRAPH OPTIONS',True);
   BText(X1+14,Y1+TB_H+8,'RANGE');
   BText(X1+78,Y1+TB_H+8,'LINE STYLE');
   BText(X1+198,Y1+TB_H+8,'WIDTH');
   BText(X1+262,Y1+TB_H+8,'MARKER');
   BText(X1+322,Y1+TB_H+8,'FILL PATTERN');
   For I:=1 To MAXSER Do Begin
    Y:=Y1+TB_H+28+(I-1)*20;
    PText(X1+28,Y+4,IntStr(I));
    ArrowBox(X1+66,Y,X1+78,Y+16,3);
    ArrowBox(X1+166,Y,X1+178,Y+16,4);
    Frame(X1+66,Y,X1+178,Y+16);
    SetColor(INK);
    SetLineStyle(UserBitLn,LinePat[GrOpt[I].Style],1);
    Line(X1+84,Y+8,X1+160,Y+8);
    SetLineStyle(SolidLn,0,1);
    Box(X1+194,Y,X1+222,Y+16,PAPER);
    Frame(X1+194,Y,X1+222,Y+16);
    PText(X1+200,Y+4,IntStr(GrOpt[I].Width)+'_');
    Box(X1+250,Y,X1+282,Y+16,PAPER);
    Frame(X1+250,Y,X1+282,Y+16);
    Marker(X1+266,Y+8,GrOpt[I].Marker);
    PatBar(X1+330,Y1+TB_H+28+(I-1)*20,X1+400,Y1+TB_H+28+(I-1)*20+19,PatGraph[I]);
   End;
   Frame(X1+330,Y1+TB_H+28,X1+400,Y1+TB_H+28+6*20-1);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ENTER) Or (E.Key=K_ESC) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H) Or InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True;
   For I:=1 To MAXSER Do Begin
    Y:=Y1+TB_H+28+(I-1)*20;
    If InBox(E.X,E.Y,X1+66,Y,X1+78,Y+16) Then Begin GrOpt[I].Style:=(GrOpt[I].Style+5) Mod 6;Redraw:=True;End;
    If InBox(E.X,E.Y,X1+166,Y,X1+178,Y+16) Then Begin GrOpt[I].Style:=(GrOpt[I].Style+1) Mod 6;Redraw:=True;End;
    If InBox(E.X,E.Y,X1+194,Y,X1+222,Y+16) Then Begin GrOpt[I].Width:=(GrOpt[I].Width Mod 3)+1;Redraw:=True;End;
    If InBox(E.X,E.Y,X1+250,Y,X1+282,Y+16) Then Begin GrOpt[I].Marker:=(GrOpt[I].Marker+1) Mod 6;Redraw:=True;End;
   End;
  End;
 Until Done;
 NeedDraw:=True;
End;

Procedure SaveOptions;
Var F: Text;
Begin
 {$I-}
 Assign(F,'3D-CALC.OPT');
 Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin MsgBox('Options','Cannot write 3D-CALC.OPT');Exit;End;
 WriteLn(F,'AUTOCALC ',Ord(AutoCalc));
 WriteLn(F,'ALERT ',Ord(AlertErr));
 WriteLn(F,'ANGLE ',AngleMode);
 WriteLn(F,'WIDTH ',DefColWid);
 WriteLn(F,'PRECISION ',GenDec);
 WriteLn(F,'GRID ',Ord(GridOn));
 WriteLn(F,'LINK ',Ord(LinkPages));
 WriteLn(F,'OUTPUT ',OutFmt);
 WriteLn(F,'GRAPHS ',GraphDir);
 Close(F);
 MsgBox('Options','Options saved in 3D-CALC.OPT');
End;

Procedure LoadOptions;
Var F: Text; K,V: String; N: Integer; Ln: String;
Begin
 {$I-}
 Assign(F,'3D-CALC.OPT');
 Reset(F);
 {$I+}
 If IOResult<>0 Then Exit;
 While Not Eof(F) Do Begin
  ReadLn(F,Ln);
  K:=NextTok(Ln);V:=TrimStr(Ln);N:=ToInt(V);
  If K='AUTOCALC' Then AutoCalc:=(N<>0)
  Else If K='ALERT' Then AlertErr:=(N<>0)
  Else If K='ANGLE' Then AngleMode:=N
  Else If (K='WIDTH') And (N>=14) And (N<=300) Then DefColWid:=N
  Else If (K='PRECISION') And (N>=0) And (N<=9) Then GenDec:=N
  Else If K='GRID' Then GridOn:=(N<>0)
  Else If K='LINK' Then LinkPages:=(N<>0)
  Else If (K='OUTPUT') And (N>=1) And (N<=4) Then OutFmt:=N
  Else If (K='GRAPHS') And (V<>'') Then GraphDir:=V;
 End;
 Close(F);
End;

{ ---- touches de fonction ---- }

Procedure TransformCell;
Begin
 With Sh[CurS] Do SetBlockValues(CurP,CurC,CurR,CurC,CurR);
End;

Procedure CellLoad;
Begin
 With Sh[CurS] Do Begin
  ClipSrc:=Copy(CellSource(CurS,CurP,CurC,CurR),1,250);
  ClipP:=CurP;ClipC:=CurC;ClipR:=CurR;
  ClipHas:=True;
 End;
End;

Procedure CellPaste;
Var T: String;
Begin
 If Not ClipHas Then Exit;
 With Sh[CurS] Do Begin
  T:=ClipSrc;
  If (T<>'') And Not (T[1] In ['"','''']) And Not RealOf(T,DummyD) Then Begin
   AdjDC:=CurC-ClipC;AdjDR:=CurR-ClipR;AdjFP:=ClipP;
   T:=RewriteRefs(T,0);
  End;
  SetEntry(CurS,CurP,CurC,CurR,T);
 End;
 Touch;
End;

Procedure RemoveWindow;
Begin
 If ChartOn Then ChartOn:=False
 Else If TxtOn And TxtFocus Then Begin TxtOn:=False;TxtFocus:=False;End
 Else If Sh[CurS].IsOpen Then CloseSheetWin(CurS);
 NeedDraw:=True;
End;

Procedure FKeyAction(N,Md: Integer);
Begin
 Editing:=False;
 With Sh[CurS] Do
  Case N Of
   1: Case Md Of
       0: OpenSheet(CurS);
       1: RemoveWindow;
       2: Begin AutoCalc:=Not AutoCalc;If AutoCalc Then Begin Inc(EvalGen);End;End;
      End;
   2: Case Md Of 0: InsertPage(CurP);1: DeletePage(CurP);2: ClearPage(CurP);End;
   3: Case Md Of 0: InsDelRow(CurP,CurR,True);1: InsDelRow(CurP,CurR,False);2: ClearRow(CurP,CurR);End;
   4: Case Md Of 0: InsDelCol(CurC,True);1: InsDelCol(CurC,False);2: ClearCol(CurP,CurC);End;
   5: Case Md Of 0: CellPaste;1: CellLoad;End;
   6: If Md=0 Then TransformCell;
   7: Case Md Of 0: CmdFind(False);1: CmdFind(True);2: CmdGoto;End;
   8: Case Md Of 0: CmdCalc;1: CmdDefColumn;End;
   9: If Md=0 Then GoCell(CurP-1,CurC,CurR) Else Begin RenumberPages(-1);End;
   10: If Md=0 Then GoCell(CurP+1,CurC,CurR) Else Begin RenumberPages(1);End;
  End;
 NeedDraw:=True;
End;

{ ---- distribution des commandes de menu ---- }

Procedure DoMenu(M,I: Integer);
Var P,C1,R1,C2,R2: Integer; Name: String;
Begin
 NeedDraw:=True;
 Case M Of
  1: Case I Of 1: AboutBox;3: RunFreeMem;End;
  2: Case I Of
      1,2,3: SelectSheet(I);
      5: FileReadCmd(0);
      6: FileSave;
      7: FileSaveAs;
      9: FileReadCmd(1);
      10: FileReadCmd(2);
      12: FileLotus;
      13: FileImport;
      14: FileExport;
      16: QuitCmd;
     End;
  3: Case I Of
      1: OpenSheet(CurS);
      2: CmdSort;
      3: CmdFind(True);
      4: CmdGoto;
      5: CmdDefColumn;
      6: CmdCalc;
      8: CmdPrint;
      9: CmdClearData;
      10: CommandLine;
      12: OutputWindow;
     End;
  4: Case I Of
      1: CmdDefineBlock;
      2: Begin BegP:=Sh[CurS].CurP;BegC:=Sh[CurS].CurC;BegR:=Sh[CurS].CurR;BegSet:=True;
               If Sh[CurS].BlockOn Then SetBlock(BegP,BegC,BegR,Sh[CurS].BC2,Sh[CurS].BR2) Else SetBlock(BegP,BegC,BegR,BegC,BegR);End;
      3: Begin If BegSet And (BegP=Sh[CurS].CurP) Then SetBlock(BegP,BegC,BegR,Sh[CurS].CurC,Sh[CurS].CurR)
               Else SetBlock(Sh[CurS].CurP,Sh[CurS].CurC,Sh[CurS].CurR,Sh[CurS].CurC,Sh[CurS].CurR);End;
      5: CmdBlockOp(1);
      6: CmdBlockOp(2);
      7: CopyBlockToText;
      9: CmdBlockOp(3);
      10: CmdBlockOp(4);
      11: CmdBlockOp(5);
      12: CmdBlockOp(6);
      14: CmdBlockOp(7);
      15: BlockHide:=Not BlockHide;
      16: CmdBlockOp(8);
     End;
  5: Case I Of
      1: StatAverages;
      2: StatHistogram;
      3: StatCumulative;
      5: StatScatter;
      6: DrawCurve:=Not DrawCurve;
      7: StatRegression;
     End;
  6: Case I Of
      1: GraphSimple(1);
      2: GraphSimple(2);
      3: GraphSimple(3);
      4: GraphMultiple;
      5: GraphFunction;
     End;
  7: Case I Of
      1: TxtOpen;
      2: Begin Name:='';If FileSelect('Read text','*.3DT',Name) Then TxtRead(Name);End;
      3: Begin If TxtName='' Then Begin Name:='TEXT.3DT';If InputBox('Save text','File name',Name,40) Then TxtSave(Name);End Else TxtSave(TxtName);End;
      4: Begin Name:=TxtName;If Name='' Then Name:='TEXT.3DT';If InputBox('Save text as','File name',Name,40) Then TxtSave(Name);End;
      5: TxtASCII:=Not TxtASCII;
      6: MsgBox('Text','Format : left margin 0, text width 78.');
      7: TxtPrint;
      8: TxtReformat:=Not TxtReformat;
      9: TxtProgram;
      10: Begin TxtInit;NeedDraw:=True;End;
     End;
  8: Case I Of
      1: StartRecording;
      2: StopRecording;
      4: DeleteMacro;
      6: ListMacros;
      8: SaveMacros;
      9: LoadMacros(False);
     End;
  9: Case I Of
      1: SettingsBox;
      3: LinkPages:=Not LinkPages;
      4: SyncC:=Not SyncC;
      5: SyncR:=Not SyncR;
      6: SyncP:=Not SyncP;
      7: GridOn:=Not GridOn;
      9: OutputFormatBox;
      10: PathsBox;
      11: GraphOptionsBox;
      12: MsgBox('Cell font','System font 8x8 is used in this version.');
      14: SaveOptions;
     End;
  10: HelpBox;
 End;
End;

{ ====================================================================== }
{                       MENUS DEROULANTS (boucle)                        }
{ ====================================================================== }

Function NextItem(M,From,Dir: Integer): Integer;
Var I,N: Integer;
Begin
 N:=MCount(M);
 I:=From;
 Repeat
  I:=I+Dir;
  If I<1 Then I:=N;
  If I>N Then I:=1;
  If (Not MSep(M,I)) And Not MIsTitle(M,I) And MEnabled(M,I) Then Begin NextItem:=I;Exit;End;
 Until I=From;
 NextItem:=From;
End;

Procedure RunMenu(StartM: Integer; ByMouse: Boolean);
Var M,Hi,H,T: Integer; E: TEvent; Done,Pick,Redraw: Boolean;
Begin
 M:=StartM;Hi:=0;
 If Not ByMouse Then Hi:=NextItem(M,0,1);
 MenuOpen:=M;MenuHi:=Hi;
 DrawAll;
 Done:=False;Pick:=False;
 Repeat
  PollEvent(E);
  Redraw:=False;
  Case E.Kind Of
   4,2: Begin
         T:=TitleHit(E.X,E.Y);
         If (T>0) And (T<>M) Then Begin M:=T;Hi:=0;Redraw:=True;End
         Else Begin
          H:=DropHit(M,E.X,E.Y);
          If (H<>0) And (MSep(M,H) Or MIsTitle(M,H) Or Not MEnabled(M,H)) Then H:=0;
          If H<>Hi Then Begin Hi:=H;Redraw:=True;End;
         End;
         If E.Kind=2 Then Begin
          If DropHit(M,E.X,E.Y)=0 Then Begin
           If TitleHit(E.X,E.Y)=0 Then Done:=True;
          End Else If Hi<>0 Then Begin Pick:=True;Done:=True;End;
         End;
        End;
   3: Begin
       H:=DropHit(M,E.X,E.Y);
       If (H<>0) And (Hi=H) Then Begin Pick:=True;Done:=True;End;
      End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_LEFT: Begin Dec(M);If M<1 Then M:=NMENU;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_RIGHT: Begin Inc(M);If M>NMENU Then M:=1;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_UP: Begin Hi:=NextItem(M,Hi,-1);Redraw:=True;End;
       K_DOWN: Begin Hi:=NextItem(M,Hi,1);Redraw:=True;End;
       K_ENTER: If Hi<>0 Then Begin Pick:=True;Done:=True;End;
      End;
  End;
  If Redraw Then Begin MenuOpen:=M;MenuHi:=Hi;DrawAll;End;
 Until Done;
 MenuOpen:=0;MenuHi:=0;
 DrawAll;
 If Pick And (Hi>0) Then DoMenu(M,Hi);
End;

{ ====================================================================== }
{                          CLAVIER                                       }
{ ====================================================================== }

Procedure MoveCursor(DC,DR: Integer);
Begin
 With Sh[CurS] Do GoCell(CurP,CurC+DC,CurR+DR);
End;

Function LastUsedCol: Integer;
Var MR,MC: Integer;
Begin
 UsedRange(CurS,Sh[CurS].CurP,MR,MC);
 If MC<0 Then MC:=0;
 LastUsedCol:=MC;
End;

Procedure SheetKey(K: Word); Forward;

Procedure EditKey(K: Word);
Var L: String;
Begin
 With Sh[CurS] Do Begin
  Case K Of
   K_ENTER: Begin CommitEdit;GoCell(CurP,0,CurR+1);End;
   10: CommitEdit;
   K_TAB,K_RIGHT: Begin CommitEdit;MoveCursor(1,0);End;
   K_STAB,K_LEFT: Begin CommitEdit;MoveCursor(-1,0);End;
   K_UP: Begin CommitEdit;MoveCursor(0,-1);End;
   K_DOWN: Begin CommitEdit;MoveCursor(0,1);End;
   K_PGUP: Begin CommitEdit;MoveCursor(0,-RowsVisible(CurS));End;
   K_PGDN: Begin CommitEdit;MoveCursor(0,RowsVisible(CurS));End;
   K_ESC: Begin EditBuf:='';EditPos:=1;End;
   26: Begin EditBuf:=EditOrig;EditPos:=Length(EditBuf)+1;End;
   K_BKSP: If EditPos>1 Then Begin Delete(EditBuf,EditPos-1,1);Dec(EditPos);End;
   K_DEL: If EditPos<=Length(EditBuf) Then Delete(EditBuf,EditPos,1);
   K_HOME: EditPos:=1;
   K_END: EditPos:=Length(EditBuf)+1;
   K_CLEFT: If EditPos>1 Then Dec(EditPos);
   K_CRIGHT: If EditPos<=Length(EditBuf) Then Inc(EditPos);
   K_F1..324,K_SF1..349,K_CF1..359: Begin CommitEdit;SheetKey(K);End;
   32..255: If Length(EditBuf)<200 Then Begin
             Insert(Chr(K),EditBuf,EditPos);Inc(EditPos);
            End;
  End;
 End;
 NeedDraw:=True;
End;

Function ShortcutKey(K: Word): Boolean;
Begin
 ShortcutKey:=True;
 Case K Of
  12: FileReadCmd(0);
  19: FileSave;
  24: FileSaveAs;
  17: QuitCmd;
  15: CmdPrint;
  7: CmdClearData;
  6: CommandLine;
  4: CmdDefineBlock;
  2: DoMenu(4,2);
  5: DoMenu(4,3);
  14: CmdBlockOp(2);
  3: CmdBlockOp(1+2);
  16: CmdBlockOp(4);
  23: CmdBlockOp(5);
  18: CmdBlockOp(6);
  25: CmdBlockOp(7);
  11: CmdBlockOp(8);
  20: TxtOpen;
  21: TxtPrint;
  22: Begin TxtInit;NeedDraw:=True;End;
  26: TxtProgram;
  K_ALT1,K_ALT1+1,K_ALT1+2: SelectSheet(K-K_ALT1+1);
  389,390: RunMenu(2,False);
  Else ShortcutKey:=False;
 End;
End;

Procedure SheetKey(K: Word);
Begin
 With Sh[CurS] Do
  Case K Of
   K_UP: MoveCursor(0,-1);
   K_DOWN: MoveCursor(0,1);
   K_LEFT: MoveCursor(-1,0);
   K_RIGHT: MoveCursor(1,0);
   K_TAB: MoveCursor(1,0);
   K_STAB: MoveCursor(-1,0);
   K_PGUP: MoveCursor(0,-RowsVisible(CurS));
   K_PGDN: MoveCursor(0,RowsVisible(CurS));
   K_HOME: GoCell(CurP,0,CurR);
   K_END: GoCell(CurP,LastUsedCol,CurR);
   K_CHOME: GoCell(CurP,0,0);
   K_CEND: GoCell(CurP,LastUsedCol,CurR);
   K_CLEFT: MoveCursor(-1,0);
   K_CRIGHT: MoveCursor(1,0);
   K_ENTER: GoCell(CurP,0,CurR+1);
   10: ;
   K_ESC: StartEdit(True,#0);
   K_DEL: Begin ClearBlock(CurP,CurC,CurR,CurC,CurR);NeedDraw:=True;End;
   K_INS: ;
   K_F1..324: FKeyAction(K-K_F1+1,0);
   K_SF1..349: FKeyAction(K-K_SF1+1,1);
   K_CF1..359: FKeyAction(K-K_CF1+1,2);
   33..126: StartEdit(True,Chr(K));
   32: StartEdit(True,' ');
  End;
End;

Procedure HandleKey(K: Word);
Begin
 If Editing Then Begin EditKey(K);Exit;End;
 If TxtOn And TxtFocus Then Begin
  If (K=K_SF1) Then Begin RemoveWindow;Exit;End;
  If (K<32) And (K<>K_ENTER) And (K<>K_BKSP) And (K<>K_TAB) And ShortcutKey(K) Then Exit;
  If (K>=K_ALT1) And (K<=K_ALT1+2) Then Begin ShortcutKey(K);Exit;End;
  TxtKey(K);
  Exit;
 End;
 If ShortcutKey(K) Then Exit;
 SheetKey(K);
End;

{ ====================================================================== }
{                              SOURIS                                    }
{ ====================================================================== }

Var RepeatSh : Integer;
    DrgP,DrgC,DrgR : Integer;

Function ColAtX(I,X: Integer): Integer;
Var GX1,GY1,GX2,GY2,X0,C: Integer;
Begin
 GridRect(I,GX1,GY1,GX2,GY2);
 X0:=GX1;C:=Sh[I].LeftC;
 While (C<MAXCOL) And (X0+Sh[I].ColW[C]<=X) Do Begin X0:=X0+Sh[I].ColW[C];Inc(C);End;
 ColAtX:=C;
End;

Function RowAtY(I,Y: Integer): Integer;
Var GX1,GY1,GX2,GY2,R: Integer;
Begin
 GridRect(I,GX1,GY1,GX2,GY2);
 R:=Sh[I].TopR+(Y-GY1) Div ROW_H;
 If R<0 Then R:=0;
 If R>MAXROW Then R:=MAXROW;
 RowAtY:=R;
End;

Procedure ScrollStep(I,Cmd: Integer);
Begin
 With Sh[I] Do
  Case Cmd Of
   1: If TopR>0 Then Dec(TopR);
   2: If TopR<MAXROW Then Inc(TopR);
   3: If LeftC>0 Then Dec(LeftC);
   4: If LeftC<MAXCOL Then Inc(LeftC);
  End;
 NeedDraw:=True;
End;

Function SheetAt(X,Y: Integer): Integer;
Var K: Integer;
Begin
 SheetAt:=0;
 For K:=NSHEET DownTo 1 Do
  If Sh[ZOrder[K]].IsOpen Then
   If InBox(X,Y,Sh[ZOrder[K]].WX,Sh[ZOrder[K]].WY,Sh[ZOrder[K]].WX+Sh[ZOrder[K]].WW,Sh[ZOrder[K]].WY+Sh[ZOrder[K]].WH) Then Begin
    SheetAt:=ZOrder[K];Exit;
   End;
End;

Procedure SheetMouseDown(I,X,Y: Integer);
Var GX1,GY1,GX2,GY2,VY1,VY2,TY1,TY2,TP,C,R,Dbl: Integer; WasEdit: Boolean; T: LongInt;
Begin
 WasEdit:=Editing And (I=CurS);
 If Editing Then CommitEdit;
 If I<>CurS Then SelectSheet(I) Else BringToFront(I);
 TxtFocus:=False;
 GridRect(I,GX1,GY1,GX2,GY2);
 T:=Tick;
 With Sh[I] Do Begin
  If Y<=WY+TB_H Then Begin
   If X<=WX+TB_H Then CloseSheetWin(I)
   Else If X>=WX+WW-TB_H Then ToggleFull(I)
   Else Begin
    If (LastClickS=I) And (Abs(T-LastClickT)<45) Then ToggleFull(I)
    Else Begin Dragging:=1;DragDX:=X-WX;DragDY:=Y-WY;End;
    LastClickS:=I;LastClickT:=T;
   End;
  End
  Else If Y<=WY+TB_H+INFO_H Then Begin StartEdit(False,#0);End
  Else If (X>=WX+WW-SB_W) And (Y>WY+TB_H) And (Y<WY+WH-SB_W) Then Begin
   VY1:=WY+TB_H+1;VY2:=WY+WH-SB_W-1;
   TY1:=VY1+SB_W;TY2:=VY2-SB_W;
   TP:=TY1+(LongInt(TopR)*(TY2-TY1-16)) Div MAXROW;
   If Y<VY1+SB_W Then Begin ScrollStep(I,1);RepeatCmd:=1;RepeatSh:=I;RepeatT:=T+30;End
   Else If Y>VY2-SB_W Then Begin ScrollStep(I,2);RepeatCmd:=2;RepeatSh:=I;RepeatT:=T+30;End
   Else If Y<TP Then Begin TopR:=Max2(0,TopR-RowsVisible(I));NeedDraw:=True;End
   Else If Y>TP+16 Then Begin TopR:=Min2(MAXROW,TopR+RowsVisible(I));NeedDraw:=True;End
   Else Begin Dragging:=5;RepeatSh:=I;End;
  End
  Else If (Y>=WY+WH-SB_W) And (X<WX+WW-SB_W) Then Begin
   If X<WX+1+SB_W Then Begin ScrollStep(I,3);RepeatCmd:=3;RepeatSh:=I;RepeatT:=T+30;End
   Else If X>WX+WW-2*SB_W Then Begin ScrollStep(I,4);RepeatCmd:=4;RepeatSh:=I;RepeatT:=T+30;End
   Else Begin
    TY1:=WX+1+SB_W;TY2:=WX+WW-SB_W-1-SB_W;
    TP:=TY1+(LongInt(LeftC)*(TY2-TY1-16)) Div MAXCOL;
    If X<TP Then Begin LeftC:=Max2(0,LeftC-5);NeedDraw:=True;End
    Else If X>TP+16 Then Begin LeftC:=Min2(MAXCOL,LeftC+5);NeedDraw:=True;End
    Else Begin Dragging:=6;RepeatSh:=I;End;
   End;
  End
  Else If (X>=WX+WW-SB_W) And (Y>=WY+WH-SB_W) Then Begin Dragging:=2;End
  Else If InBox(X,Y,GX1,GY1,GX2,GY2) Then Begin
   C:=ColAtX(I,X);R:=RowAtY(I,Y);
   CurC:=C;CurR:=R;
   DrgP:=CurP;DrgC:=C;DrgR:=R;
   Dragging:=3;
   NeedDraw:=True;
  End
  Else If (Y>=GY1-HDR_H-1) And (Y<GY1) And (X>=GX1) Then Begin CurC:=ColAtX(I,X);EnsureVisible(I);NeedDraw:=True;End
  Else If (X<GX1) And (Y>=GY1) Then Begin CurR:=RowAtY(I,Y);EnsureVisible(I);NeedDraw:=True;End;
 End;
End;

Procedure MouseDown(X,Y: Integer);
Var T,N,Row,I: Integer; Tk: LongInt;
Begin
 T:=TitleHit(X,Y);
 If T>0 Then Begin
  If Editing Then CommitEdit;
  RunMenu(T,True);
  Exit;
 End;
 N:=FKeyHit(X,Y,Row);
 If N>0 Then Begin FKeyAction(N,Row-1);Exit;End;
 If ChartOn And InBox(X,Y,ChX1,ChY1,ChX2,ChY2) Then Begin
  If InBox(X,Y,ChX1,ChY1,ChX1+TB_H,ChY1+TB_H) Then ChartOn:=False;
  NeedDraw:=True;
  Exit;
 End;
 If TxtOn And InBox(X,Y,TX1,TY1,TX2,TY2) Then Begin
  If Editing Then CommitEdit;
  If InBox(X,Y,TX1,TY1,TX1+TB_H,TY1+TB_H) Then Begin TxtOn:=False;TxtFocus:=False;End
  Else Begin
   TxtFocus:=True;
   If (Y>TY1+TB_H) And (X<TX2-SB_W) And (Y<TY2-SB_W) Then Begin
    TxtCY:=TxtTopL+(Y-TY1-TB_H-4) Div 10;
    If TxtCY<1 Then TxtCY:=1;
    If TxtCY>TxtN Then TxtCY:=TxtN;
    TxtCX:=(X-TX1-4) Div 8;
    If TxtCX<0 Then TxtCX:=0;
    If TxtCX>Length(TxtL^[TxtCY]) Then TxtCX:=Length(TxtL^[TxtCY]);
   End;
  End;
  NeedDraw:=True;
  Exit;
 End;
 I:=SheetAt(X,Y);
 If I>0 Then Begin SheetMouseDown(I,X,Y);Exit;End;
 For I:=1 To NSHEET Do
  If InBox(X,Y,IconX(I)-4,IconY(I)-2,IconX(I)+46,IconY(I)+46) Then Begin
   Tk:=Tick;
   If (LastClickS=I+10) And (Abs(Tk-LastClickT)<45) Then OpenSheet(I) Else SelectSheet(I);
   LastClickS:=I+10;LastClickT:=Tk;
   Exit;
  End;
End;

Procedure MouseMove(X,Y: Integer);
Var I,C,R,GX1,GY1,GX2,GY2,TY1,TY2: Integer;
Begin
 If Dragging=0 Then Exit;
 I:=CurS;
 With Sh[I] Do
  Case Dragging Of
   1: Begin
       WX:=X-DragDX;WY:=Y-DragDY;
       If WY<MENU_H Then WY:=MENU_H;
       If WY>FKEY_Y-40 Then WY:=FKEY_Y-40;
       If WX<-WW+60 Then WX:=-WW+60;
       If WX>SCR_W-60 Then WX:=SCR_W-60;
       Full:=False;
       NeedDraw:=True;
      End;
   2: Begin
       WW:=X-WX;WH:=Y-WY;
       If WW<200 Then WW:=200;
       If WH<110 Then WH:=110;
       If WX+WW>SCR_W-1 Then WW:=SCR_W-1-WX;
       If WY+WH>FKEY_Y-1 Then WH:=FKEY_Y-1-WY;
       Full:=False;
       EnsureVisible(I);
       NeedDraw:=True;
      End;
   3: Begin
       GridRect(I,GX1,GY1,GX2,GY2);
       If Y>GY2 Then ScrollStep(I,2) Else If Y<GY1 Then ScrollStep(I,1);
       If X>GX2 Then ScrollStep(I,4) Else If X<GX1 Then ScrollStep(I,3);
       C:=ColAtX(I,Max2(GX1,Min2(X,GX2)));R:=RowAtY(I,Max2(GY1,Min2(Y,GY2)));
       If (C<>DrgC) Or (R<>DrgR) Then SetBlock(DrgP,DrgC,DrgR,C,R);
      End;
   5: Begin
       TY1:=WY+TB_H+1+SB_W;TY2:=WY+WH-SB_W-1-SB_W;
       TopR:=Max2(0,Min2(MAXROW,LongInt(Y-TY1-8)*MAXROW Div Max2(1,TY2-TY1-16)));
       NeedDraw:=True;
      End;
   6: Begin
       TY1:=WX+1+SB_W;TY2:=WX+WW-SB_W-1-SB_W;
       LeftC:=Max2(0,Min2(MAXCOL,LongInt(X-TY1-8)*MAXCOL Div Max2(1,TY2-TY1-16)));
       NeedDraw:=True;
      End;
  End;
End;

Procedure MouseUp;
Begin
 RepeatCmd:=0;
 If Dragging=3 Then Begin
  Dragging:=0;
  If Sh[CurS].BlockOn And ((Sh[CurS].BC1<>Sh[CurS].BC2) Or (Sh[CurS].BR1<>Sh[CurS].BR2)) Then Begin
   If (Sh[CurS].BC1<=DrgC) And (Sh[CurS].BC2>=DrgC) Then CmdDefineBlock;
  End;
 End;
 Dragging:=0;
End;

{ ====================================================================== }
{                          INITIALISATION                                }
{ ====================================================================== }

Procedure InitData;
Var I,K: Integer;
Begin
 CurS:=1;
 For I:=1 To NSHEET Do ZOrder[I]:=I;
 EvalGen:=1;
 AutoCalc:=True;ShowForm:=False;GridOn:=True;DrawCurve:=True;
 GenDec:=2;DefColWid:=78;AngleMode:=0;
 LinkPages:=False;SyncC:=False;SyncR:=False;SyncP:=False;AlertErr:=True;
 OutFmt:=3;GraphDir:='GRAPHS';
 {$IFDEF FPC}
 DirSep:=DirectorySeparator;
 {$ELSE}
 DirSep:='\';
 {$ENDIF}
 Quit:=False;NeedDraw:=True;Editing:=False;
 FillChar(Sh,SizeOf(Sh),0);
 For I:=1 To NSHEET Do Begin
  ResetSheet(I);
  Sh[I].WX:=84+(I-1)*20;Sh[I].WY:=MENU_H+8+(I-1)*22;
  Sh[I].WW:=520-(I-1)*20;Sh[I].WH:=330;
  Sh[I].IsOpen:=(I=1);
 End;
 For I:=1 To 10 Do Begin DeskMac[I]:=Nil;DeskLen[I]:=0;End;
 Recording:=False;RecBuf:=Nil;RecLen:=0;PlayLen:=0;PlayPos:=0;
 GetMem(PlayBuf,MAXKEYS*2);
 New(ChData);New(ChXs);New(ChLbl);New(StatBuf);New(StatBuf2);New(FlagBuf);New(FlagBuf2);
 New(CorA);New(CorB);New(ChRep);
 FillChar(ChData^,SizeOf(TChartD),0);FillChar(ChXs^,SizeOf(TChartD),0);
 TxtL:=Nil;TxtInit;TxtOn:=False;TxtFocus:=False;TxtIns:=True;
 TxtASCII:=False;TxtReformat:=False;BlockHide:=False;
 ChartOn:=False;ChRepN:=0;
 For I:=1 To MAXSER Do Begin GrOpt[I].Style:=I-1;GrOpt[I].Width:=1;GrOpt[I].Marker:=I-1;End;
 For I:=1 To 5 Do For K:=1 To 10 Do GFm[I,K]:='';
 GXR:='';GYR:='';GDR:='';VarN1:='';VarD1:='';VarN2:='';VarD2:='';
 FindStr:='';ClipHas:=False;BegSet:=False;
 MenuOpen:=0;MenuHi:=0;Dragging:=0;RepeatCmd:=0;LastClickS:=0;LastClickT:=0;
 MX:=0;MY:=0;MB:=0;LastB:=0;
 ConN:=0;ProgHalt:=False;
End;

Procedure ShowHelpLine;
Var H: Text;
Begin
 Assign(H,'');Rewrite(H);
 WriteLn(H,'3DCALC - Clone graphique du tableur 3D-CALC+ (Atari ST).');
 WriteLn(H);
 WriteLn(H,'Utilisation : 3DCALC [fichier.3DD] [/?]');
 WriteLn(H);
 WriteLn(H,'  fichier.3DD  Feuille de calcul a ouvrir dans le tableur 1.');
 WriteLn(H,'  /?           Affiche cette aide.');
 WriteLn(H);
 WriteLn(H,'Menus a la souris ; F12 ouvre le menu File au clavier.');
 Close(H);
End;

Procedure LoadCommandLine;
Var Name: String;
Begin
 Name:='';
 If ParamCount>=1 Then Name:=ParamStr(1)
 Else If FileExists('AUTO3D.3DD') Then Name:='AUTO3D.3DD';
 If Name='' Then Exit;
 Name:=AddExt(Name,'3DD');
 If FileExists(Name) Then Begin
  If LoadSheet(1,Name,0) Then Begin
   Sh[1].FileName:=Name;Sh[1].Named:=True;
   Sh[1].Modified:=False;
  End;
 End;
End;

Procedure MainLoop;
Var E: TEvent;
Begin
 Repeat
  If NeedDraw Then DrawAll;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y);
   3: MouseUp;
   4: MouseMove(E.X,E.Y);
  End;
  If (RepeatCmd<>0) And ((MB And 1)<>0) Then
   If Tick-RepeatT>8 Then Begin
    ScrollStep(RepeatSh,RepeatCmd);
    RepeatT:=Tick;
   End;
 Until Quit;
End;

BEGIN
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h') Or (ParamStr(1)='--help')) Then Begin
  ShowHelpLine;
  Halt(0);
 End;
 InitData;
 LoadOptions;
 InitializeGraphics;
 If MouseDriverFound Then ShowMouse;
 LoadMacros(True);
 LoadCommandLine;
 MainLoop;
 CloseGraph;
END.
