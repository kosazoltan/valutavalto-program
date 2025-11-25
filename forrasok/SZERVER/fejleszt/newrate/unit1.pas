unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, jpeg, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    DNEMPANEL: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel24: TPanel;
    Panel25: TPanel;
    Panel26: TPanel;
    Panel27: TPanel;
    Panel28: TPanel;
    Panel29: TPanel;
    Panel30: TPanel;
    Panel31: TPanel;
    Panel32: TPanel;
    Panel33: TPanel;
    Panel34: TPanel;
    Image2: TImage;
    Label1: TLabel;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    Image8: TImage;
    Image9: TImage;
    Image10: TImage;
    Image11: TImage;
    Image12: TImage;
    Image13: TImage;
    Image14: TImage;
    Image15: TImage;
    Image16: TImage;
    Image17: TImage;
    Image18: TImage;
    Image19: TImage;
    Image20: TImage;
    Image21: TImage;
    Image22: TImage;
    Image23: TImage;
    Image24: TImage;
    Image25: TImage;
    Image26: TImage;
    Image27: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    AKTDNEVPANEL: TPanel;
    IM1: TImage;
    Panel1: TPanel;

    procedure BitBtn1Click(Sender: TObject);
    procedure IM1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DNEMPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormActivate(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _dnem: array[1..26] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');

  _dnev: array[1..26] of string = ('AUSZTRÁL DOLLÁR','BOSNYÁK MÁRKA','BOLGÁR LEVA',
         'BRAZIL REÁL','KANADAI DOLLÁR','SVÁJCI FRANK','KINAI JÜAN','CSEH KORONA',
         'DÁN KORONA','EURÓ','ANGOL FONT','HORVÁT KUNA','IZRAELI SHAKEL',
         'JAPÁN YEN','MEXIKÓI PESO','NORVÉG KORONA','ÚJ-ZÉLANDI DOLLÁR',
         'LENGYEL ZLOTY','ROMÁN LEI','SZERB DINÁR','OROSZ RUBEL','SVÉD KORONA',
         'THAI BATH','TÖRÖK LÍRA','UKRÁN HRIVNYA','AMERIKAI DOLLÁR');

   _xx,_lastxx: byte;
   _aktdnev : string;


implementation

{$R *.dfm}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
 Application.terminate;
end;



procedure TForm1.IM1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  _xx := TImage(sender).Tag;
  if _xx=_lastxx then exit;

  _lastxx := _xx;

  _aktdnev := _dnev[_xx];
  AKTDNEVPANEL.CAPTION := _aktdnev;
  AktdnevPanel.repaint;

end;

procedure TForm1.DNEMPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  _xx := 0;
  _lastxx := 0;
  AktdnevPanel.caption := '';
  AktDnevPanel.repaint;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  _lastxx := 0;
  Left := 0;
end;

end.
