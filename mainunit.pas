{
This is simple and probably not so efficient version of Game of Life. It works but it MAY or MAY NOT work correctly (mostly it does work as expected :) )

You can generate world using predefined settings (World Width/World Height/Cell Width/Cell Height).
Just click CREATE THE WORLD button. It will create basic empty world since chance to be alive is set to 0.

To create randomly placed live cells set Chance to be alive to bigger value (e.g 45).

Now You can start simulations by sliding Simulation speed to right  or You can make just one step using button labeled '>>'
You can also manually add living cell by clicking on world grid. If there is dead cell it will rise from grave, otherwise You will kill living cell.

Have fun ;)
 Tomek
}
unit mainunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Buttons, ExtCtrls;

type

  TCellStates = (csAlive, csDead);

  TCell = class
    private
      FCellState: TCellStates;
      FPrevCellState: TCellStates;
      FCRect: TRect;
    public
      property CellState: TCellStates read FCellState write FCellState;
      property PrevCellState: TCellStates read FPrevCellState write FPrevCellState;
      property CRect: TRect read FCRect write FCRect;


  end;

  type

    TWorld = array of array of TCell;
    TWorldType = (wtEmpty, wtRandom);
  type
  { TForm1 }

  TForm1 = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    edBirthChance: TEdit;
    edCellHeight: TEdit;
    Edit1: TEdit;
    edWorldSeed: TEdit;
    edWorldWidth: TEdit;
    edWorldHeight: TEdit;
    edCellWidth: TEdit;
    gbWorldSettings: TGroupBox;
    gbCellSettings: TGroupBox;
    gbGeneration: TGroupBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    lbSimulationSpeed: TLabel;
    Label6: TLabel;
    dgLoadWorld: TOpenDialog;
    pbScene: TPaintBox;
    dgSaveWorld: TSaveDialog;
    sbSystemInfo: TStatusBar;
    sbWorldContainer: TScrollBox;
    btnGenSeed: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    btnSaveWorld: TSpeedButton;
    btnLoadWorld: TSpeedButton;
    SpeedButton3: TSpeedButton;
    tbWorldSpeed: TTrackBar;
    tbBirthChance: TTrackBar;
    tbtnSimulationONOFF: TToggleBox;
    tWorldClock: TTimer;

    procedure btnGenSeedClick(Sender: TObject);
    procedure btnLoadWorldClick(Sender: TObject);
    procedure btnSaveWorldClick(Sender: TObject);
    procedure edBirthChanceChange(Sender: TObject);
    procedure edCellHeightChange(Sender: TObject);
    procedure edCellHeightExit(Sender: TObject);
    procedure edCellWidthChange(Sender: TObject);
    procedure edWorldHeightChange(Sender: TObject);
    procedure edWorldHeightExit(Sender: TObject);
    procedure edWorldWidthChange(Sender: TObject);
    procedure edWorldWidthExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbSceneMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbSceneMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbSceneMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure tbBirthChanceChange(Sender: TObject);
    procedure tbWorldSpeedChange(Sender: TObject);
    procedure tbtnSimulationONOFFChange(Sender: TObject);
    procedure tWorldClockTimer(Sender: TObject);
  private

    procedure DrawWorld(Sender: TObject);
    procedure PrepareWorldCanvas;
    procedure SetWorldDims(AWorld: TWorld);
    procedure GenerateWorld(AWorld: TWorld; AWorldWidth, AWorldHeight, ACellWidth,
                            ACellHeight: Integer; AWorldType: TWorldType; ABirthChance: integer=0);
    procedure FreeWorld(AWorld: TWorld; AWorldWidth, AWorldHeight: integer);
    procedure ShiftCellState(ACell: TCell);
    procedure SetWorldState(AWorld: TWorld; AState: TCellStates; AWorldWidth, AWorldHeight: integer);

    function GetNeighboursCount(AWorld: TWorld; ARow, ACol, AWorldWidth,
      AWorldHeight: integer): integer;
    function CellState2String(ACell: TCell): string;
    function String2CellState(AString: string): TCellStates;
    function GetCellColor(ACell: TCell):TColor;
    function SetCellColorMOD(ABaseColor: TColor; ANeighborsCount: Integer): TColor;
    function DarkenColor(AColor: TColor; APercent: UInt8): TColor;
    procedure Split(const Delimiter: Char; Input: string;
      const Strings: TStrings);

  public

  end;

var
  Form1: TForm1;
  SimRunning: Boolean;

  WorldSpeed: integer;
  prevWorldSpeed: integer;

  WorldGenSeed: integer;
  World: TWorld;
  OldWorld: TWorld; //for calculations;

  WorldWidth, WorldHeight, CellWidth, CellHeight: integer;
  scale,oldWWidth,oldWHeight:integer;
     MouseIsDown: Boolean;
implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.Split (const Delimiter: Char; Input: string; const Strings: TStrings);
begin
   Assert(Assigned(Strings)) ;
   Strings.Clear;
   Strings.Delimiter := Delimiter;
   Strings.StrictDelimiter:=true;
   Strings.DelimitedText := Input;
end;

procedure TForm1.tbWorldSpeedChange(Sender: TObject);
begin
 if Length(World)>0 then begin
  WorldSpeed := tbWorldSpeed.position;
  tWorldClock.Interval:=WorldSpeed;
  lbSimulationSpeed.Caption := 'Simulation speed: ('+IntToStr(WorldSpeed)+')';
  if tbtnSimulationOnOff.Checked then
  begin
  prevWorldSpeed := WorldSpeed;
  end;

 if tbWorldSpeed.Position = 0 then tWorldClock.Enabled := false else tWorldClock.Enabled := True;
 if tWorldClock.Enabled then tbtnSimulationOnOff.Caption := 'ON' else tbtnSimulationOnOff.Caption := 'OFF' ;
end;
end;

procedure TForm1.tbtnSimulationONOFFChange(Sender: TObject);
begin
if Length(World)>0 then begin
  if tbtnSimulationONOFF.Checked then
  Begin
  tbtnSimulationONOFF.Caption := 'ON';
  SimRunning := true;
  WorldSpeed := prevWorldSpeed;
  tbWorldSpeed.Position := WorldSpeed;
  tWorldClock.Interval := WorldSpeed;
  tWorldClock.Enabled := true;
  //
  WorldWidth := StrToInt(edWorldWidth.text);
  WorldHeight := StrToInt(edWorldHeight.text);

  //
  end
  else
  Begin
    tbtnSimulationONOFF.Caption := 'OFF';

    SimRunning := False;
    prevWorldSpeed := WorldSpeed;
     WorldSpeed := 0;
     tbWorldSpeed.Position := 0;
  tWorldClock.Interval := WorldSpeed;
  tWorldClock.Enabled := False;
  end;
 end;
end;

procedure TForm1.tWorldClockTimer(Sender: TObject);
var
  ins,cY, cX, ns, sHeight, sWidth: Integer;
  bit, Bitmap:TBitmap;
  Dest, Source: TRect;
begin
  // Edit1.text:=IntToStr(Length(World))+' <CURR - OLD> '+inttostr(length(oldworld));
  // SetWorldState(OldWorld,csDead,WorldWidth,WorldHeight);

     SetWorldState(OldWorld,csDead,WorldWidth,WorldHeight);
  //Crude WAY!
  For cY:=0 to WorldHeight-1 do
 begin
   For cX:=0 to WorldWidth-1 do
   begin
 if World[cx,cy].CellState=csAlive then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if (ns=2) or (ns=3) then OldWorld[cx,cy].CellState:=csAlive;
     end;
   if World[cx,cy].CellState=csAlive then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if (ns<2) or (ns>3) {(ns=0) or (ns=1) or (ns=5)or (ns=6)or (ns=7)or (ns=8)}  then OldWorld[cx,cy].CellState:=csDead;
     end;

   if World[cx,cy].CellState=csDead then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if ns=3 then oldWorld[cx,cy].CellState:=csAlive;
     end;

   end;
 end;
 SetWorldState(World,csDead,WorldWidth,WorldHeight);
 For cY:=0 to WorldHeight-1 do begin
  For cX:=0 to WorldWidth-1 do begin
    world[cx,cy].CellState:=Oldworld[cx,cy].CellState;
    end;
  end;





 pbScene.OnPaint:=@DrawWorld;
 pbScene.Refresh;




end;

procedure TForm1.DrawWorld(Sender: TObject);
var
  ins,wRow,wCol, sWidth, sHeight:integer;
  cellColor: TColor;
  bit, Bitmap: TBitmap;
  Dest, Source: TRect;
begin
 pbScene.Canvas.pen.style:=psClear;
 pbScene.Canvas.Brush.Color:=rgbtocolor(23,23,23);
 pbScene.Canvas.Rectangle(0,0,pbScene.Width,pbscene.Height);
   for wCol := 0 to WorldHeight-1 do begin
  for wRow := 0 to WorldWidth-1 do begin

  if (World[wRow,wCol].PrevCellState <> World[wRow,wCol].CellState) or (World[wRow,wCol].CellState=csAlive) then begin
      cellColor := SetCellColorMOD(RGBToColor(255,150,30),GetNeighboursCount(World,wRow,wCol,WorldWidth,WorldHeight));// toso GetCellColor(World[wRow,wCol]);

     if World[wRow,wCol].CellState=csAlive then begin
      pbScene.Canvas.Brush.Color :=cellColor; // BIG FRAME RATE DROP :P RGBToColor(Random(256),Random(256),Random(256));
      pbScene.Canvas.Rectangle(World[wRow,wCol].CRect);
      end;
     end;
  end;

 end;




end;

procedure TForm1.PrepareWorldCanvas;
begin
  pbScene.Width := CellWidth*WorldWidth;
  pbScene.Height := CellHeight*WorldHeight;
end;

procedure TForm1.SetWorldDims(AWorld: TWorld);
begin
  SetLength(AWorld,WorldWidth,WorldHeight);

end;

procedure TForm1.GenerateWorld(AWorld: TWorld; AWorldWidth, AWorldHeight,
  ACellWidth, ACellHeight: Integer;AWorldType: TWorldType; ABirthChance: integer=0);
var
  wRow,wCol: integer;
  tmpRect: TRect;
begin
// setting CRect

// ---
  Case AWorldType of
  wtEmpty: Begin
                for wCol := 0 to AWorldHeight-1 do
                begin
                    for wRow := 0 to AWorldWidth-1 do
                    Begin
                    tmpRect := TRect.Create(wRow*ACellWidth-1,wCol*ACellHeight-1,wRow*ACellWidth+ACellWidth+1,wCol*ACellHeight+ACellHeight+1);

                    AWorld[wRow,wCol] := TCell.Create;
                    AWorld[wRow,wCol].CellState := csDead;
                    AWorld[wRow,wCol].PrevCellState := AWorld[wRow,wCol].CellState;
                    AWorld[wRow,wCol].CRect := TRect.Create(tmpRect);
                  //  AWorld[wRow,wCol].CRect.Inflate(1,1);

                    end;
                end;
           end;
  wtRandom:Begin
                for wCol := 0 to AWorldHeight-1 do
                    begin
                             for wRow := 0 to AWorldWidth-1 do
                                 Begin
                                 tmpRect := TRect.Create(wRow*ACellWidth,wCol*ACellHeight,wRow*ACellWidth+ACellWidth, wCol*ACellHeight+ACellHeight);
                                 AWorld[wRow,wCol] := TCell.Create;
                                 if (Random(100)+1)<ABirthChance then
                                 AWorld[wRow,wCol].CellState := csAlive else AWorld[wRow,wCol].CellState := csDead;
                                 AWorld[wRow,wCol].PrevCellState := AWorld[wRow,wCol].CellState;
                                 AWorld[wRow,wCol].CRect := TRect.Create(tmpRect);
                      //           AWorld[wRow,wCol].CRect.Inflate(1,1);

                                 end;
                             end;


                    end;
end;

end;

procedure TForm1.FreeWorld(AWorld: TWorld; AWorldWidth, AWorldHeight: integer);
var
  wRow,wCol:integer;
begin

     if Length(AWorld)>0 then begin
        For wCol := 0 to AWorldHeight-1 do begin
            For wRow := 0 to AWorldWidth-1 do begin
            AWorld[wRow,wCol].Free;
            end;
        end;
     end;
end;

function TForm1.GetCellColor(ACell: TCell): TColor;
begin
   Case ACell.CellState of

        csAlive         :  Result := RGBToColor(146, 196, 39);
        csDead          :  Result := RGBToColor(120, 120, 120);
  end;

end;

function TForm1.DarkenColor(AColor: TColor; APercent: UInt8): TColor;
var
  R, G, B: UInt8;
begin
  RedGreenBlue(AColor, R, G, B);

  R := Round(R * (100 - APercent) / 100);
  G := Round(G * (100 - APercent) / 100);
  B := Round(B * (100 - APercent) / 100);

  Result := RGBToColor(R, G, B);

end;

function TForm1.SetCellColorMOD(ABaseColor: TColor; ANeighborsCount: Integer): TColor;
begin
  Result := DarkenColor(ABaseColor, ANeighborsCount * 10);
end;


{function TForm1.SetCellColorMOD(ACell: TCell; ANeighbours: integer): TColor;
begin
    Case ANeighbours of
               0          : Result:=RGBToColor(255,255, 50);
               1          : Result:=RGBToColor(255,225, 50);
               2          : Result:=RGBToColor(255,200, 50);
               3          : Result:=RGBToColor(255,175, 50);
               4          : Result:=RGBToColor(255,150, 50);
               5          : Result:=RGBToColor(255,125, 50);
               6          : Result:=RGBToColor(255,100, 50);
               7          : Result:=RGBToColor(255, 75, 50);
               8          : Result:=RGBToColor(255, 50, 50);

    end;

end;  }



procedure TForm1.ShiftCellState(ACell: TCell);
begin
  Case ACell.CellState of

       csDead          : ACell.CellState := csAlive;
       csAlive         : ACell.CellState := csDead;
  end;

end;

procedure TForm1.SetWorldState(AWorld: TWorld; AState: TCellStates;
  AWorldWidth, AWorldHeight: integer);
var
  wRow, wCol: integer;
begin
if Length(AWorld) > 0 then Begin
  for wCol:=0 to AWorldHeight-1 do Begin
      for wRow:=0 to AWorldWidth-1 do Begin
      AWorld[wRow,wCol].CellState:=AState;
      end;
  end;
end;

end;

function TForm1.GetNeighboursCount(AWorld: TWorld; ARow, ACol, AWorldWidth,
  AWorldHeight: integer): integer;
var
  NC:integer;
begin
nc:=0;

     if (ACol-1>=0) and ((AWorld[ARow,ACol-1].CellState=csAlive) or (AWorld[ARow,ACol-1].CellState=csAlive))then NC:=NC+1 else nc:=nc;
     if (ACol+1<=AWorldHeight-1) and ((AWorld[ARow,ACol+1].CellState=csAlive) or (AWorld[ARow,ACol+1].CellState=csAlive))then NC:=NC+1 else nc:=nc;
     if (ARow-1>=0) and ((AWorld[ARow-1,ACol].CellState=csAlive) or (AWorld[ARow-1,ACol].CellState=csAlive)) then NC:=NC+1 else nc:=nc;
     if (ARow+1<=AWorldWidth-1) and ((AWorld[ARow+1,ACol].CellState=csAlive) or (AWorld[ARow+1,ACol].CellState=csAlive))then NC:=NC+1 else nc:=nc;

     if ((ARow-1>=0) and (ACol-1>=0)) and ((AWorld[ARow-1,ACol-1].CellState=csAlive) or (AWorld[ARow-1,ACol-1].CellState=csAlive))then NC:=NC+1 else nc:=nc;
     if ((ARow-1>=0) and (ACol+1<=AWorldHeight-1)) and ((AWorld[ARow-1,ACol+1].CellState=csAlive) or (AWorld[ARow-1,ACol+1].CellState=csAlive))then NC:=NC+1 else nc:=nc;
     if ((ARow+1<=AWorldWidth-1) and (ACol-1>=0)) and ((AWorld[ARow+1,ACol-1].CellState=csAlive) or (AWorld[ARow+1,ACol-1].CellState=csAlive))then NC:=NC+1 else nc:=nc;
     if ((ARow+1<=AWorldWidth-1) and (ACol+1<=AWorldHeight-1)) and ((AWorld[ARow+1,ACol+1].CellState=csAlive) or (AWorld[ARow+1,ACol+1].CellState=csAlive))then NC:=NC+1 else nc:=nc;

result:=nc;

end;

function TForm1.CellState2String(ACell: TCell): string;
begin
   case ACell.CellState of
        csAlive: Result := 'csAlive';
        csDead: Result := 'csDead';
   end;


end;

function TForm1.String2CellState(AString: string): TCellStates;
begin
  case AString of
        'csAlive': Result := csAlive;
        'csDead'  : Result := csDead;
   end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
Randomize();
  lbSimulationSpeed.Caption := 'Simulation speed: ('+IntToStr(tbWorldSpeed.Position)+')';
  edBirthChance.Text := IntToStr(tbBirthChance.Position);
  WorldGenSeed := Random(9223372036854775807);
  edWorldSeed.Text := IntToStr(WorldGenSeed);
  tbWorldSpeed.Position := 0;
  WorldSpeed := 0;
  prevWorldSpeed := 0;
  tbtnSimulationOnOff.Checked := false;
  tbtnSimulationOnOff.Caption := 'OFF';
  tWorldClock.Enabled := false;
  tWorldClock.Interval := 0;
  CellWidth := StrToInt(edCellWidth.Text);
  CellHeight := StrToInt(edCellHeight.Text);
  WorldWidth := StrToInt(edWorldWidth.Text);
  WorldHeight := StrToInt(edWorldHeight.Text);
  pbScene.Width := CellWidth*WorldWidth;
  pbScene.Height := CellHeight*WorldHeight;
  oldWWidth := WorldWidth;
  oldWHeight := WorldHeight;
  scale:=StrToInt(Edit1.text);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeWorld(World,WorldWidth,WorldHeight);
  FreeWorld(OldWorld,WorldWidth,WorldHeight);

end;

procedure TForm1.pbSceneMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  mx,my:integer;

begin
  MouseIsDown:=true;
  if mouseisdown then begin
  mx := x div cellwidth;
  my := y div cellheight;
  ShiftCellState(World[mx,my]);
  end;
  pbScene.Invalidate;
end;

procedure TForm1.pbSceneMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  wRow,wCol, mx, my: integer;
begin
  wRow := x div CellWidth;
  wCol := y div CellHeight;
  if (wRow>0) and (wCol<WorldHeight) then
  Begin
  if Length(World) > 0 then begin
     sbSystemInfo.Panels.Items[0].Text:=IntToStr(GetNeighboursCount(World,wRow,wCol,WorldWidth,WorldHeight));
     sbSystemInfo.Panels.Items[1].Text:=CellState2String(World[wRow,wCol]);
     end;

  end;
   if mouseisdown then begin
   if (wRow>0) and (wCol<WorldHeight) then begin



  if World[wRow,wCol].CellState<>csAlive then begin
  mx := x div cellwidth;
  my := y div cellheight;
  ShiftCellState(World[mx,my]);


  end;
  end;

   end;
  pbScene.Invalidate;

end;

procedure TForm1.pbSceneMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
    MouseIsDown:=false;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  scale:=StrToInt(Edit1.text);
  if oldworld<>nil then FreeWorld(OldWorld,WorldWidth,WorldHeight);
  if oldworld<>nil then FreeWorld(World,oldWWidth,oldWHeight);

  WorldWidth := StrToInt(edWorldWidth.text);
  WorldHeight := StrToInt(edWorldHeight.text);
  CellWidth:= StrToInt(edCellWidth.text);
  CellHeight:= StrToInt(edCellHeight.text);



  PrepareWorldCanvas;  //set width and height

  SetLength(World,WorldWidth,WorldHeight);
  SetLength(OldWorld,WorldWidth,WorldHeight);

  GenerateWorld(OldWorld,WorldWidth,WorldHeight,CellWidth,CellHeight,wtEmpty);
  GenerateWorld(World,WorldWidth,WorldHeight,CellWidth,CellHeight,wtRandom,StrToInt(edBirthChance.text));

  oldWWidth := WorldWidth;
  oldWHeight := WorldHeight;
  pbScene.OnPaint := @DrawWorld;
  pbScene.Invalidate;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
var
  cY, cX, ns: Integer;
begin
   SetWorldState(OldWorld,csDead,WorldWidth,WorldHeight);
  //Crude WAY!
  For cY:=0 to WorldHeight-1 do
 begin
   For cX:=0 to WorldWidth-1 do
   begin
   if World[cx,cy].CellState=csAlive then
     begin
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       if (ns=2) or (ns=3) then OldWorld[cx,cy].CellState:=csAlive;

     end;
   if World[cx,cy].CellState=csAlive then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if (ns<2) or (ns>3) {(ns=0) or (ns=1) or (ns=5)or (ns=6)or (ns=7)or (ns=8)}  then OldWorld[cx,cy].CellState:=csDead;
     end;

   if World[cx,cy].CellState=csDead then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if ns=3 then oldWorld[cx,cy].CellState:=csAlive;
     end;
   end;
 end;
 SetWorldState(World,csDead,WorldWidth,WorldHeight);
 For cY:=0 to WorldHeight-1 do begin
  For cX:=0 to WorldWidth-1 do begin
    world[cx,cy].CellState:=Oldworld[cx,cy].CellState;
    end;
  end;
 pbScene.OnPaint:=@DrawWorld;
 pbScene.Refresh;
  //END CRUDE WAY
end;

procedure TForm1.SpeedButton3Click(Sender: TObject);

  var
  cY, cX, ns: Integer;
begin
   SetWorldState(OldWorld,csDead,WorldWidth,WorldHeight);
  //Crude WAY!
  For cY:=0 to WorldHeight-1 do
 begin
   For cX:=0 to WorldWidth-1 do
   begin
   if World[cx,cy].CellState=csDead then
     begin
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       if (ns=2) or (ns=3) then OldWorld[cx,cy].CellState:=csAlive;

     end;
   if World[cx,cy].CellState=csDead then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if (ns<2) or (ns>3) {(ns=0) or (ns=1) or (ns=5)or (ns=6)or (ns=7)or (ns=8)}  then OldWorld[cx,cy].CellState:=csDead;
     end;

   if World[cx,cy].CellState=csAlive then
     begin
       World[cX,cY].PrevCellState := World[cX,cY].CellState;
       ns:=GetNeighboursCount(World,cX,cY,WorldWidth,WorldHeight);
       if ns=3 then oldWorld[cx,cy].CellState:=csAlive;
     end;
   end;
 end;
 SetWorldState(World,csDead,WorldWidth,WorldHeight);
 For cY:=0 to WorldHeight-1 do begin
  For cX:=0 to WorldWidth-1 do begin
    world[cx,cy].CellState:=Oldworld[cx,cy].CellState;
    end;
  end;
 pbScene.OnPaint:=@DrawWorld;
 pbScene.Refresh;
  //END CRUDE WAY
end;

procedure TForm1.edBirthChanceChange(Sender: TObject);
begin
  tbBirthChance.Position := StrToInt(edBirthChance.Text);
end;

procedure TForm1.edCellHeightChange(Sender: TObject);
begin
 {      if edCellHeight.text<>'' then
  CellHeight  :=  StrToInt(edCellHeight.text) }
end;
procedure TForm1.edCellHeightExit(Sender: TObject);
begin
 {        if edCellHeight.text<>'' then
  CellHeight  :=  StrToInt(edCellHeight.text) }
end;
procedure TForm1.edCellWidthChange(Sender: TObject);
begin
{     if edCellWidth.text<>'' then
  CellWidth  :=  StrToInt(edCellWidth.text)   }
end;
procedure TForm1.edWorldHeightChange(Sender: TObject);
begin
 {  if edWorldHeight.text<>'' then
  WorldHeight  :=  StrToInt(edWorldHeight.text)}
end;
procedure TForm1.edWorldHeightExit(Sender: TObject);
begin
 {    if edWorldHeight.text<>'' then
  WorldHeight  :=  StrToInt(edWorldHeight.text);}
end;
procedure TForm1.edWorldWidthChange(Sender: TObject);
begin
 { if edWorldWidth.text<>'' then
  WorldWidth  :=  StrToInt(edWorldWidth.text); }
end;
procedure TForm1.edWorldWidthExit(Sender: TObject);
begin
  { if edWorldWidth.text<>'' then
  WorldWidth  :=  StrToInt(edWorldWidth.text); }
end;

procedure TForm1.btnGenSeedClick(Sender: TObject);
begin
  Randomize();
  WorldGenSeed  :=  Random(9223372036854775807);
  edWorldSeed.Text  :=  IntToStr(WorldGenSeed);
end;

procedure TForm1.btnLoadWorldClick(Sender: TObject);
var
  WorldList: TStringList;
  wCol, wRow, i: Integer;
  SetList: TStringList;
  tmpCellState: TCellStates;
  tmpRect: TRect;
begin
  if dgLoadWorld.Execute then
    begin
      if World<>nil then FreeWorld(World,WorldWidth,WorldHeight);
      WorldList:=TStringList.Create;
      //Load World file into WorldList(TStringList)
      WorldList.LoadFromFile(dgLoadWorld.FileName);
      //Create helping StringList to parse line for WorldWidth and World Height //always saved in first line of file
      SetList:=TStringList.Create;
      //Delimit first line by ';' and add results to helping stringlist SetList
      Split(';',WorldList.Strings[0],SetList);
      //Set loaded values to WorldWidth and Height and put then in Edit Boxes
      WorldWidth:=StrToInt(SetList[0]);
      WorldHeight:=StrToInt(SetList[1]);
      edWorldWidth.Text:=IntToStr(WorldWidth);
      edWorldHeight.Text:=IntToStr(WorldHeight);
      //Prepare canvas with loaded values
      PrepareWorldCanvas;
      //Read info about cells and create them
      SetLength(World,WorldWidth,WorldHeight);

       SetLength(World,WorldWidth,WorldHeight);
       SetLength(OldWorld,WorldWidth,WorldHeight);
       GenerateWorld(OldWorld,WorldWidth,WorldHeight,CellWidth,CellHeight,wtEmpty);
      SetList.Free;


      For i := 1 to WorldList.Count-1 do
      Begin
          SetList := TStringList.Create; //reset helping list every step
          Split(';',WorldList.Strings[i],SetList);
          wRow:=StrToInt(SetList[0]);
          wCol:=StrToInt(SetList[1]);
          tmpCellState:=String2CellState(SetList[2]);
          tmpRect := TRect.Create(wRow*CellWidth,wCol*CellHeight,wRow*CellWidth+CellWidth,wCol*CellHeight+CellHeight);
          World[wRow,wCol]:=TCell.Create;
          World[wRow,wCol].CellState:=tmpCellState;
          World[wRow,wCol].PrevCellState:=tmpCellState;
          World[wRow,wCol].CRect:=TRect.Create(tmpRect);
          SetList.Free;
      end;

{       tmpRect := TRect.Create(wRow*ACellWidth-1,wCol*ACellHeight-1,wRow*ACellWidth+ACellWidth+1,wCol*ACellHeight+ACellHeight+1);

                    AWorld[wRow,wCol] := TCell.Create;
                    AWorld[wRow,wCol].CellState := csDead;
                    AWorld[wRow,wCol].PrevCellState := AWorld[wRow,wCol].CellState;
                    AWorld[wRow,wCol].CRect := TRect.Create(tmpRect);}






    end;
  WorldList.Free;
  oldWWidth := WorldWidth;
  oldWHeight := WorldHeight;
  pbScene.OnPaint:=@DrawWorld;
  pbScene.Invalidate;
end;

procedure TForm1.btnSaveWorldClick(Sender: TObject);
var
  WorldList: TStringList;
  wCol, wRow: Integer;
begin
  if dgSaveWorld.Execute then
    begin
      WorldList:=TStringList.Create;
      WorldList.Add(WorldWidth.ToString+';'+WorldHeight.ToString);
      For wCol:=0 to WorldHeight-1 do begin
          For wRow:=0 to WorldWidth-1 do begin
                WorldList.Add(wRow.toString+';'+wCol.toString+';'+CellState2String(World[wRow,wCol]));
          end;
      end;
      if dgSaveWorld.FileName<>'' then
      WorldList.SaveToFile(dgSaveWorld.FileName);
      WorldList.Free;
    end;
end;








procedure TForm1.tbBirthChanceChange(Sender: TObject);
begin
  edBirthChance.Text  :=  IntToStr(tbBirthChance.Position);
end;

end.


