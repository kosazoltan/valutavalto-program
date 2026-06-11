unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, unit1, ExtCtrls, Buttons,dateutils;

type
  THOBEKERO = class(TForm)
    H10: TPanel;
    H7: TPanel;
    H1: TPanel;
    H3: TPanel;
    H5: TPanel;
    H11: TPanel;
    H4: TPanel;
    H6: TPanel;
    H2: TPanel;
    H8: TPanel;
    H9: TPanel;
    H12: TPanel;
    ELOEVPANEL: TPanel;
    AKTEVPANEL: TPanel;
    DATUMPANEL: TPanel;
    MEGSEMGOMB: TBitBtn;
    DATUMOKEGOMB: TBitBtn;
    Shape1: TShape;
    procedure FormActivate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure DATUMOKEGOMBClick(Sender: TObject);
    procedure Hogombclear;
    procedure Evgombclear;
    procedure H1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ELOEVPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DATUMOKEGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure DATUMPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Shape1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure H1Click(Sender: TObject);
    procedure ELOEVPANELClick(Sender: TObject);
    procedure AKTEVPANELClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HOBEKERO: THOBEKERO;
  _hopanel: array[1..12] of tpanel;
  _aktev,_eloev,_aktho: word;
  _evhos: string;

implementation

{$R *.dfm}




procedure THOBEKERO.FormActivate(Sender: TObject);
begin
  top := _top + 72;
  left := _left +8;
  Height := 330;
  width := 436;

  _hopanel[1] := h1;
  _hopanel[2] := h2;
  _hopanel[3] := h3;
  _hopanel[4] := h4;
  _hopanel[5] := h5;
  _hopanel[6] := h6;
  _hopanel[7] := h7;
  _hopanel[8] := h8;
  _hopanel[9] := h9;
  _hopanel[10]:= h10;
  _hopanel[11]:= h11;
  _hopanel[12]:= h12;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _eloev := _aktev-1;

  ELOEVPANEL.caption := inttostr(_eloev);
  Aktevpanel.caption := inttostr(_aktev);

  _kertev := 0;
  _kertho := 0;



end;

procedure THOBEKERO.Button1Click(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure THobekero.Hogombclear;

var i: integer;

begin
  for i := 1 to 12 do _hopanel[i].color := clbtnFace;
end;

procedure THobekero.Evgombclear;

begin
   eloevpanel.Color := clBtnface;
  aktevpanel.Color := clBtnface;
end;



procedure THOBEKERO.MEGSEMGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure THOBEKERO.DATUMOKEGOMBClick(Sender: TObject);
begin
  if (_kertev>0) and (_kertho>0) then Modalresult := 1;
end;

procedure THOBEKERO.H1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  evgombclear;
  Hogombclear;
  TPanel(sender).Color := clyellow;
end;

procedure THOBEKERO.ELOEVPANELMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  Hogombclear;
  Evgombclear;
  Tpanel(sender).Color := clYellow;
end;

procedure THOBEKERO.DATUMOKEGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  hogombclear;
end;

procedure THOBEKERO.DATUMPANELMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  evgombclear;
  hogombclear;
end;

procedure THOBEKERO.Shape1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if _kertev=0 then evgombclear;
  if _kertho=0 then hogombclear;
end;

procedure THOBEKERO.H1Click(Sender: TObject);
begin
  
  _kertho := TPanel(sender).tag;
  _evhos := '';
  if _kertev>0 then _evhos := inttostr(_kertev)+' ';
  _evhos := _evhos + _hopanel[_kertho].caption;
  DatumPanel.Caption := _evhos;
  Datumpanel.Repaint;

end;

procedure THOBEKERO.ELOEVPANELClick(Sender: TObject);
begin
  _kertev := _eloev;
  _evhos := inttostr(_kertev)+' ';
  if _kertho>0 then _evhos := _evhos + _hopanel[_kertho].caption;
  DatumPanel.Caption := _evhos;
  Datumpanel.Repaint;


end;

procedure THOBEKERO.AKTEVPANELClick(Sender: TObject);
begin
  _kertev := _aktev;
  _evhos := inttostr(_kertev)+' ';
  if _kertho>0 then _evhos := _evhos + _hopanel[_kertho].caption;
  DatumPanel.Caption := _evhos;
  Datumpanel.Repaint;


end;

end.
