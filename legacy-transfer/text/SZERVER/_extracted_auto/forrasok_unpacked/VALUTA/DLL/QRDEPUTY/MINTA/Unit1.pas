unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, DelphiZXingQRCode, ExtCtrls,
  StdCtrls, ComCtrls, Buttons;

type
  TForm1 = class(TForm)
    edtText: TEdit;
    PaintBox1: TPaintBox;
    CSUSZO: TTrackBar;
    SKALAPANEL: TPanel;
    HOSSZPANEL: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    BitBtn1: TBitBtn;

    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure edtTextChange(Sender: TObject);
    procedure edtQuietZoneChange(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

  private
    QRCodeBitmap: TBitmap;
  public
    procedure Frissit;
  end;


var
  Form1: TForm1;
  _zstring,_szoveg: string;
  _skala,_textlen: integer;


implementation

{$R *.dfm}




procedure TForm1.edtQuietZoneChange(Sender: TObject);
begin
  Frissit;
end;

procedure TForm1.edtTextChange(Sender: TObject);
begin
  Frissit;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  QRCodeBitmap := TBitmap.Create;
  Frissit;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  QRCodeBitmap.Free;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
var
  Scale: Double;
begin
  PaintBox1.Canvas.Brush.Color := clWhite;
  PaintBox1.Canvas.FillRect(Rect(0, 0, PaintBox1.Width, PaintBox1.Height));
  if ((QRCodeBitmap.Width > 0) and (QRCodeBitmap.Height > 0)) then
  begin
    if (PaintBox1.Width < PaintBox1.Height) then
    begin
      Scale := PaintBox1.Width / QRCodeBitmap.Width;
    end else
    begin
      Scale := PaintBox1.Height / QRCodeBitmap.Height;
    end;
    PaintBox1.Canvas.StretchDraw(Rect(0, 0, Trunc(Scale * QRCodeBitmap.Width), Trunc(Scale * QRCodeBitmap.Height)), QRCodeBitmap);
  end;
end;

procedure TForm1.Frissit;
var
  QRCode: TDelphiZXingQRCode;
  Row, Column: Integer;
begin
  QRCode := TDelphiZXingQRCode.Create;
  try
    _szoveg := Trim(edtText.Text);
    _textlen := length(_szoveg);
    HosszPanel.Caption := inttostr(_textlen);
    Hosszpanel.Repaint;

    QRCode.Data := _szoveg;

    QRCode.Encoding := TQrCodeEncoding(2);
  //  _zstring := trim(edtQuietZone.text);
  //  QRCode.QuietZone := StrToIntDef(edtQuietZone.Text, 4);
  //  QRCode.QuietZone := StrToIntDef(_zstring, 4);
    _SKALA := cSUSZO.Position;
    skalaPanel.Caption := inttostr(_skala);
    SkalaPanel.Repaint;

    QrCode.Quietzone := _skala;
    row := Qrcode.rows;
    Column := Qrcode.columns;
   //  QRCodeBitmap.SetSize(QrCode.Rows,QrCode.Columns);
    QrcodeBitmap.Height := Row;
    QrcodeBitmap.Width := Column;
    for Row := 0 to QRCode.Rows - 1 do
    begin
      for Column := 0 to QRCode.Columns - 1 do
      begin
        if (QRCode.IsBlack[Row, Column]) then
        begin
          QRCodeBitmap.Canvas.Pixels[Column, Row] := clBlack;
        end else
        begin
          QRCodeBitmap.Canvas.Pixels[Column, Row] := clWhite;
        end;
      end;
    end;
  finally
    QRCode.Free;
  end;
  PaintBox1.Repaint;
end;




procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  aPPlication.terminate;
end;

end.
