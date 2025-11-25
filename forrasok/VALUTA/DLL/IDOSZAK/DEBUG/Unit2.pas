unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DateUtils, StrUtils,
  IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  THONAPKEROFORM = class(TForm)

         Panel1: TPanel;

        EvCombo: TComboBox;
        HoCombo: TComboBox;
     IgNapCombo: TComboBox;
    TolNapCombo: TComboBox;

        Label1: TLabel;
        Label2: TLabel;
        Label3: TLabel;

       IdszOkeGomb: TBitBtn;
    IdszCancelGomb: TBitBtn;
    Shape1: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    MAINAPGOMB: TBitBtn;

    function Nulele(_b: byte): string;
    procedure FormActivate(Sender: TObject);
    procedure HoComboChange(Sender: TObject);
    procedure IdszCancelGOMBClick(Sender: TObject);
    procedure IdszOkeGombClick(Sender: TObject);
    procedure IgNapComboChange(Sender: TObject);
    procedure NapComboTolto;
    procedure Adatrogzites;
    procedure TolnapComboChange(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure FormCreate(Sender: TObject);
    procedure IDSZOKEGOMBEnter(Sender: TObject);
    procedure IDSZOKEGOMBExit(Sender: TObject);
    procedure IDSZOKEGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MAINAPGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HonapKeroForm: THonapKeroForm;
  _utolsoNap: word;

  _width,_height,_left,_top: word;
  _mostev,_mostho,_mostnap: word;
  _kertev,_kertho,_kertnap,_tolnap,_ignap: word;

  _honapnev: array[1..12] of string = (
             'JANUÁR',
             'FEBRUÁR',
             'MÁRCIUS',
             'ÁPRILIS',
             'MÁJUS',
             'JUNIUS',
             'JULIUS',
             'AUGUSZTUS',
             'SZEPTEMBER',
             'OKTÓBER',
             'NOVEMBER',
             'DECEMBER');
             
   _tolstring,_igstring,_pcs: string;
   _sorveg: string = chr(13)+chr(10);

function idoszakrutin: integer; stdcall;


implementation

{$R *.dfm}

function idoszakrutin: integer; stdcall; 

begin
  HonapkeroForm := THonapkeroForm.Create(Nil);
  result := HonapkeroForm.ShowModal;
  HonapkeroForm.Free;
end;  


// =============================================================================
             procedure THonapKeroForm.FormActivate(Sender: TObject);
// =============================================================================

var
     i: integer;

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top    := round((_height-768)/2);
  _left   := round((_width-540)/2);

  Width   := 540;
  Height  := 160;
  Top     := _top+80;
  Left    := _left;

  _mostev := yearof(date);
  _mostho := monthof(date);
  _mostnap:= dayof(date);

  _kertev := _mostev;
  _kertho := _mostho;

  EvCombo.Clear;
  HoCombo.Clear;
  TolNapCombo.Clear;
   IgNapCombo.Clear;

  For i := -2 to 0 do EvCombo.Items.Add(inttostr(_mostEv+i));
  For i := 1 to 12 do HoCombo.Items.Add(_honapNev[i]);

  Evcombo.ItemIndex := 2;
  Hocombo.ItemIndex := _mostho-1;
  NapComboTolto;

  ActiveControl := IdszOkeGomb;
end;

// =============================================================================
        procedure THonapKeroForm.IdszCancelGombClick(Sender: TObject);
// =============================================================================

begin
  _tolstring := '';
  _igstring := '';
  ModalResult := 2;
end;

// =============================================================================
            procedure THonapKeroForm.HoComboChange(Sender: TObject);
// =============================================================================

begin
  _kertHo := 1+(Hocombo.ItemIndex);
  _kertev := (_mostev-2)+(Evcombo.ItemIndex);
  Napcombotolto;
end;

// =============================================================================
           procedure THonapKeroForm.IdszOkeGombClick(Sender: TObject);
// =============================================================================

begin
      _kertHo := 1+(Hocombo.ItemIndex);
      _kertev := (_mostev-2)+(Evcombo.ItemIndex);
      _tolnap := 1+(tolnapcombo.ItemIndex);
       _ignap := _tolnap+(ignapcombo.ItemIndex);

   _tolstring := inttostr(_kertev)+'.'+Nulele(_kertho)+'.'+Nulele(_tolnap);
    _igstring := leftstr(_tolstring,8)+Nulele(_ignap);

    Adatrogzites;

  ModalResult := 1;
end;

procedure THonapKeroForm.AdatRogzites;

begin
  _pcs := 'DELETE FROM IDOSZAK';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO IDOSZAK (KERTEV,KERTHO,TOLNAP,IGNAP,TOLSTRING,IGSTRING)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_kertev) + ',';
  _pcs := _pcs + inttostr(_kertho) + ',';
  _pcs := _pcs + inttostr(_tolnap) + ',';
  _pcs := _pcs + inttostr(_ignap) + ',';
  _pcs := _pcs + chr(39) + _tolstring + chr(39) + ',';
  _pcs := _pcs + chr(39) + _igstring + chr(39) + ')';
  ValutaParancs(_pcs);
end;

procedure THonapKeroForm.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := True;
  if valutatranz.InTransaction then valutatranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;    



end;

// =============================================================================
                procedure THonapKeroForm.NapComboTolto;
// =============================================================================

var i: integer;

begin
  _utolsonap := DaysInAMonth(_kertev,_kertho);
  TolnapCombo.clear;
  IgnapCombo.Clear;

  for i := 1 to _utolsonap do
    begin
      Tolnapcombo.Items.Add(inttostr(i));
      IgnapCombo.Items.add(inttostr(i));
    end;

  TolnapCombo.ItemIndex := 0;
  IgnapCombo.ItemIndex := (_utolsonap-1);
  ActiveControl := IdszOkeGomb;
end;

// =============================================================================
         procedure THonapKeroForm.TolNapComboChange(Sender: TObject);
// =============================================================================

var i: integer;
begin
  _tolnap := Tolnapcombo.ItemIndex+1;

  ignapcombo.Clear;
  for i := _tolnap to _utolsonap do ignapcombo.Items.Add(inttostr(i));

  Ignapcombo.ItemIndex := (_utolsonap-_tolnap);
  Activecontrol := IdszOkeGomb;
end;

// =============================================================================
         procedure THonapKeroForm.IgnapComboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := IdszOkeGomb;
end;


// =============================================================================
             procedure THONAPKEROFORM.FormCreate(Sender: TObject);
// =============================================================================

begin
  Width := 540;
 Height := 160;
    Top := _top + 280;
   Left := _left + 240;
end;

procedure THONAPKEROFORM.IDSZOKEGOMBEnter(Sender: TObject);
begin
  with Tbitbtn(sender).Font do
    begin
     // Size := 10;
      style := [fsBold];
    end;
end;

procedure THONAPKEROFORM.IDSZOKEGOMBExit(Sender: TObject);
begin
  with Tbitbtn(sender).Font do
    begin
    //  Size := 8;
      style := [];
    end;
end;


function THonapKeroForm.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


procedure THONAPKEROFORM.IDSZOKEGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitBtn(sender);
end;

procedure THONAPKEROFORM.MAINAPGOMBClick(Sender: TObject);
begin
  _kertev := _mostev;
  _kertho := _mostho;
  _kertnap := _mostnap;
  _tolnap := _kertnap;
  _ignap  := _kertnap;
  _tolstring := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_kertnap);
  _igstring := _tolstring;

  Adatrogzites;

  ModalResult := 1;
  
end;

end.
