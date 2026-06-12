unit Unit14;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, UNIT1;

type
  THOVAMASOLJAK = class(TForm)
    Label1: TLabel;
    C1: TPanel;
    C49: TPanel;
    C7: TPanel;
    C13: TPanel;
    C19: TPanel;
    C25: TPanel;
    C31: TPanel;
    C37: TPanel;
    C43: TPanel;
    C50: TPanel;
    C3: TPanel;
    C40: TPanel;
    C53: TPanel;
    C54: TPanel;
    C2: TPanel;
    C9: TPanel;
    C5: TPanel;
    C4: TPanel;
    C15: TPanel;
    C11: TPanel;
    C16: TPanel;
    C10: TPanel;
    C14: TPanel;
    C23: TPanel;
    C17: TPanel;
    C20: TPanel;
    C27: TPanel;
    C26: TPanel;
    C21: TPanel;
    C8: TPanel;
    C38: TPanel;
    C39: TPanel;
    C22: TPanel;
    C32: TPanel;
    C33: TPanel;
    C24: TPanel;
    C44: TPanel;
    C47: TPanel;
    C45: TPanel;
    C30: TPanel;
    C41: TPanel;
    C34: TPanel;
    C12: TPanel;
    C6: TPanel;
    C36: TPanel;
    C51: TPanel;
    C18: TPanel;
    C28: TPanel;
    C52: TPanel;
    C29: TPanel;
    C35: TPanel;
    C46: TPanel;
    C42: TPanel;
    C48: TPanel;
    ListBox1: TListBox;
    BitBtn1: TBitBtn;

    procedure FormActivate(Sender: TObject);
   
    procedure BitBtn1Click(Sender: TObject);
    procedure CsopTombTolto;
    procedure C1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    function ScanMarkLista(_nn: integer):boolean;
    procedure C1Click(Sender: TObject);
   

    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HOVAMASOLJAK: THOVAMASOLJAK;
  _aktpanel : TPanel;
  _utolsotag: Integer;
  _csp: array[1..54] of TPanel;
  _aktcsoportnev: string;
  _ss,_oo: integer;
  _cErtek,_cfuggveny: string;
  _cBetu,_cHatter: Tcolor;

implementation

{$R *.dfm}

// =============================================================================
         procedure THOVAMASOLJAK.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 0;
  Left := 0;
  Height := 729;
  Width := 1366;

  Listbox1.Items.Clear;
  Listbox1.clear;
  csoptombtolto;
end;

// =============================================================================
                 procedure THOVAMASOLJAK.Csoptombtolto;
// =============================================================================

var _csopdb: integer;

begin
  _csp[1]  := c1;
  _csp[2]  := c2;
  _csp[3]  := c3;
  _csp[4]  := c4;
  _csp[5]  := c5;
  _csp[6]  := c6;
  _csp[7]  := c7;
  _csp[8]  := c8;
  _csp[9]  := c9;
  _csp[10] := c10;
  _csp[11] := c11;
  _csp[12] := c12;
  _csp[13] := c13;
  _csp[14] := c14;
  _csp[15] := c15;
  _csp[16] := c16;
  _csp[17] := c17;
  _csp[18] := c18;
  _csp[19] := c19;
  _csp[20] := c20;
  _csp[21] := c21;
  _csp[22] := c22;
  _csp[23] := c23;
  _csp[24] := c24;
  _csp[25] := c25;
  _csp[26] := c26;
  _csp[27] := c27;
  _csp[28] := c28;
  _csp[29] := c29;
  _csp[30] := c30;
  _csp[31] := c31;
  _csp[32] := c32;
  _csp[33] := c33;
  _csp[34] := c34;
  _csp[35] := c35;
  _csp[36] := c36;
  _csp[37] := c37;
  _csp[38] := c38;
  _csp[39] := c39;
  _csp[40] := c40;
  _csp[41] := c41;
  _csp[42] := c42;
  _csp[43] := c43;
  _csp[44] := c44;
  _csp[45] := c45;
  _csp[46] := c46;
  _csp[47] := c47;
  _csp[48] := c48;
  _csp[49] := c49;
  _csp[50] := c50;
  _csp[51] := c51;
  _csp[52] := c52;
  _csp[53] := c53;
  _csp[54] := c54;

  _qq := 1;
  while _qq<=54 do
    begin
      _csopdb := _csoportTagDarab[_qq];
      _aktpanel := _csp[_qq];
      _aktcsoportnev := uppercase(_csoportnevek[_qq]);
      _aktpanel.Caption := _aktcsoportnev;

      If ScanMarkLista(_qq) then
         begin
           _aktpanel.Cursor := crNoDrop;
           _aktpanel.Color := $FFB1FF;
           inc(_QQ);
           continue;
         end;

      if _csopdb>0 then
        begin
          _aktpanel.color := $B0FFFF;
          _aktpanel.Cursor := crHandPoint;
        end else
        begin
          _aktpanel.color := clScrollBar;
          _aktpanel.Cursor := crNoDrop;
        end;
      inc(_qq);
    end;
end;

// =============================================================================
            procedure THOVAMASOLJAK.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  ModalResult := -1;
end;

// =============================================================================
    procedure THOVAMASOLJAK.C1MouseMove(Sender: TObject; Shift: TShiftState;
                                                               X, Y: Integer);
// =============================================================================

begin
  _aktcsoport := TPanel(sender).tag;

  if _aktcsoport=_utolsoTag then exit;
  _utolsotag := _aktcsoport;

  _aktcsoportDarab := _csoportTagDarab[_aktcsoport];
  if _aktcsoportDarab=0 then
     begin
        Listbox1.Color := clScrollbar;
        Listbox1.Items.clear;
        Listbox1.clear;
        exit;
      end;

  ListBox1.Items.Clear;
  ListBox1.Clear;
  Listbox1.Color := $B0FFFF;

  _qq := 1;
  while _qq<=_aktcsoportDarab do
    begin
      _aktiroda := _csoporttagok[_aktcsoport,_qq];
      _xx := Form1.ScanIroda(_aktiroda);
      _aktirodaNev := _ptarnev[_xx];
      _aktirodacim := _ptarcim[_xx];
      ListBox1.Items.add(_aktirodanev+'/'+_aktirodacim);
      inc(_qq);
    end;
end;

// =============================================================================
          function THovaMasoljak.ScanMarkLista(_nn: integer):boolean;
// =============================================================================

var _y: integer;

begin
  Result := False;
  _y := 1;

  while _y<= _markdb do
    begin
      if _nn=_marklista[_y] then
        begin
          result := true;
          break;
        end;
       inc(_y);
     end;
end;

// =============================================================================
             procedure THOVAMASOLJAK.C1Click(Sender: TObject);
// =============================================================================

var _cs: integer;

begin
  _cs := TPanel(sender).tag;
  ModalResult := _cs;
end;

end.
