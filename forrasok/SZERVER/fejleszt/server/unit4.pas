unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, DBTables, idGlobal, StrUtils, Buttons;

type
  TATTEKINTES = class(TForm)

    Panel1: TPanel;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    Shape1: TShape;


    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Displayselect;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATTEKINTES: TATTEKINTES;
  _aktUzletszam: integer;
  _quit: boolean;

implementation

uses Unit1, Unit9, Unit18, Unit17, Unit28, Unit23, Unit24, Unit25, Unit27,
  Unit26, Unit29, Unit22, Unit30;

{$R *.dfm}


// ===================================================================
           procedure TATTEKINTES.Button1Click(Sender: TObject);
// ===================================================================

begin
  Modalresult := 2;
end;

// ================================================================
        procedure TATTEKINTES.FormActivate(Sender: TObject);
// ================================================================

var _idszOke,_dh: integer;

begin
  Top := _top+120;
  Left := _left+140;
  Height := 530;
  Width := 750;
  
  _quit := false;
  _idszOke := IdoszakBeform.ShowModal;

  if _idszOke<>1 then
    begin
      ModalResult := 2;
      Exit;
    end;

  _dh := strtoint(midstr(_tolstring,6,2));
  _idoszaklabel := leftstr(_tolstring,4)+' '+ _honapnev[_dh] +' '+midstr(_tolstring,9,10)+' - '+midstr(_igstring,9,10);

  AdatLegyujtes.ShowModal;

  _kellexcel := False;
  while True do
    begin
      _aktUzletszam := Getuzletszam.Showmodal;
      if _aktUzletszam<0 then
        begin
          // -1=best, -2=pannon, -3=east  -4=ZALOG
          _cbsors := abs(_aktuzletszam);
          dec(_cbsors);
          if _cbSors<3 then _displayFocim := _subdir[_cbsors]+' CHANGE ADATAI'
          else _displayfocim := 'EXPRESSZ ÉKSZERHÁZ ADATAI';
          _displaytipus := 4;
        end;

      _aktUzletszam := _aktuzletszam-3;
      if _aktuzletszam=-2 then
        begin
          ModalResult := 1;
          break;
        end;

      if _aktuzletszam=-1 then
        begin
          _displayFocim := 'EXCLUSIVE CHANGE ÖSSZESÍTETT ADATAI';
          _displaytipus := 1;
        end;
      if _aktuzletszam=0 then
        begin
          _displayTipus := 2;
          _displayFocim := _aktkorzetnev + ' régió adatai';

        end;
      if _aktuzletszam>0 then
        begin
          _displayFocim := _aktPenztarNev + ' pénztár adatai';
          _displayTipus := 3;
        end;
      Displayselect;
    end;
  ModalResult := 1;
end;

// ===================================================
        procedure Tattekintes.Displayselect;
// ===================================================


var _delem: integer;

begin
  while true do
    begin

      _delem := Adatmenu.ShowModal;
      case _delem of

        1: ForgalomDisplay.ShowModal;
        2: KeszletDisplay.ShowModal;
        3: Wunidisplay.ShowModal;
        4: PenztarKozottiDisplay.ShowModal;
        5: BankForgalomdisplay.ShowModal;
        6: TrbDisplay.Showmodal;
        7: StornoDisp.ShowModal;
        8: Break;

       end;
    end;
end;


end.
