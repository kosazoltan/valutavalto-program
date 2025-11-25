unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons,  dateUtils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)

    Hovalasz    : TPanel;
    EVCombo     : TComboBox;
    HOCombo     : TComboBox;
    HoOkeGomb   : TBitBtn;
    HoMegsemGomb: TBitBtn;
    Label1      : TLabel;
    Shape1      : TShape;
    RecQuery    : TIBQuery;
    RecDbase    : TIBDatabase;
    RecTranz    : TIBTransaction;

  
    procedure FormActivate(Sender: TObject);
    procedure EvComboChange(Sender: TObject);
    procedure HoOkeGombClick(Sender: TObject);
    procedure HoMegsemGOMBClick(Sender: TObject);
    procedure RecParancs(_ukaz: string);

    function Nulele(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _HONEV: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                'NOVEMBER','DECEMBER');

  _tolstring,_igstring,_pcs: string;
  _sorveg: string =  chr(13)+chr(10);
  _aktev,_aktho,_kertev,_kertho,_lastday: word;
  _y: byte;


function hovalasztorutin: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
              function hovalasztorutin: integer; stdcall;
// =============================================================================

begin
  form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;

// =============================================================================
                 procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := 330;
  Left := 460;
  Repaint;

  Evcombo.Items.clear;
  Hocombo.Items.clear;

  _aktev := yearof(date);
  _aktho := monthof(date);

  Evcombo.Items.Add(inttostr(_aktev-1));
  Evcombo.items.Add(inttostr(_aktev));
  Evcombo.ItemIndex := 1;

  _y := 1;
  while _y<=12 do
    begin
      Hocombo.Items.Add(_honev[_y]);
      inc(_y);
    end;
  Hocombo.ItemIndex :=  _aktho-1;
  with Hovalasz do
    begin
      top := 0;
      left := 0;
      visible := true;
      repaint;
    end;  

  ActiveControl := Hookegomb;
end;

// =============================================================================
             procedure TForm2.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := HookeGomb;
end;

// =============================================================================
           procedure TForm2.HOOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kertev := _aktev + (evcombo.itemindex) - 1;
  _kertho := 1 + (Hocombo.Itemindex);
  _lastday:= daysinamonth(_kertev,_kertho);
  _tolstring := inttostr(_kertev)+'.'+nulele(_kertho)+'.01';
  _igstring  := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+inttostr(_lastday);

  _pcs := 'DELETE FROM IDOSZAK';
  RecParancs(_pcs);

  _pcs := 'INSERT INTO IDOSZAK (STARTDATE,ENDDATE)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _tolstring +  chr(39) + ',';
  _pcs := _pcs + chr(39) + _igstring + chr(39) + ')';
  RecParancs(_pcs);
  Modalresult := 1;
end;

// =============================================================================
           procedure TForm2.HOMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM IDOSZAK';
  RecParancs(_pcs);
  Modalresult := -1;
end;

// =============================================================================
            function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
             procedure TForm2.Recparancs(_ukaz: string);
// =============================================================================

begin
  recdbase.connected := true;
  if rectranz.InTransaction then rectranz.Commit;
  Rectranz.StartTransaction;

  with RecQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Rectranz.Commit;
  Recdbase.close;
end;

end.
