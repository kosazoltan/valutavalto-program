unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, jpeg, IBDatabase, DB,
  IBCustomDataSet, IBQuery, ComCtrls;

type
  TForm2 = class(TForm)
    Shape1: TShape;
    Panel1: TPanel;
    LEFTPANEL: TPanel;
    Image1: TImage;
    Label1: TLabel;
    RIGHTPANEL: TPanel;
    Image2: TImage;
    FOCIM: TLabel;
    DOCUCIM: TLabel;
    BitBtn1: TBitBtn;
    ELOTAKARO: TPanel;
    KOVTAKARO: TPanel;
    DOCQUERY: TIBQuery;
    DOCDBASE: TIBDatabase;
    DOCTRANZ: TIBTransaction;
    KILEPO: TTimer;
    ScrollBox1: TScrollBox;
    IMAGEPANEL: TPanel;
    DOCIMAGE: TImage;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure Getalapadatok;
    procedure DocKijelzo;
    PROCEDURE sETtAKAROK;
 
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _HEIGHT,_WIDTH: WORD;
  _docdarab,_docss,_szeles,_magas: word;
  _dirs,_minta,_ugyfeltipus,_jpgnev,_focim,_jpgPath: string;

  _doc: array[1..99] of string;
  
  _ugyfelszam: integer;
  _srec: TSearchrec;

function ReadMWord(f: TFileStream): word;
procedure GetJPGSize(const sFile: string; var wWidth, wHeight: word);
function docdisprutin: integer; stdcall;

implementation

{$R *.dfm}

function docdisprutin: integer; stdcall;

begin
  form2 := Tform2.Create(Nil);
  result := form2.showmodal;
  form2.free;
end;  


procedure TForm2.Button1Click(Sender: TObject);
begin
  mODALRESULT := 1;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  top     := trunc((_height-768)/2);
  Left    := trunc((_width-1024)/2);
  Height  := 768;
  Width   := 1024;

  GetAlapadatok;  // _ugyfeltipus,_ugyfelszam
  _dirs := inttostr(_ugyfelszam);
  if _ugyfeltipus='W' then _dirs := 'W' + _dirs;

  _minta := 'c:\valuta\scans\'+_dirs+'\*.jpg';
  _docdarab := 0;
  if FindFirst(_minta,faAnyFile,_srec) = 0 then
    begin
      repeat
        _jpgnev := _srec.Name;
        inc(_docdarab);
        _doc[_docDarab] := _jpgnev;
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  if _docdarab=0 then
    begin
      Kilepo.enabled := True;
      exit;
    end;
  _focim := 'AZ ÜGYFÉLNEK ' + inttostr(_docdarab)+' DOKUMENTUMA VAN ELMENTVE';
  FOCIM.caption := _focim;
  Focim.repaint;

  _docss := 1;
  DocKijelzo;
end;

procedure TForm2.DocKijelzo;

begin
  Docucim.caption := inttostr(_docss)+'. DOKUMENTUM';
  Docucim.repaint;
  Settakarok;
  _jpgPath := 'c:\valuta\scans\'+_dirs+'\'+_doc[_docss];
  GetJpgSize(_jpgPath,_szeles,_magas);
  ImagePanel.Width := _szeles;
  Imagepanel.Height := _magas;

  DocImage.Picture.LoadFromFile(_jpgPath);
  Docimage.Visible := true;
  docimage.repaint;
end;

procedure TForm2.SetTakarok;

begin
  with Elotakaro do
    begin
      Top := 664;
      Left := 344;
      Visible := true;
      repaint;
    end;

  with Kovtakaro do
    begin
      Top := 664;
      Left := 520;
      Visible := true;
      repaint;
    end;

  if _docss>1 then Elotakaro.visible := False;
  if _docss<_docdarab then Kovtakaro.visible := False;
end;


procedure TForm2.BitBtn1Click(Sender: TObject);
begin
  mODALRESULT := 1;
end;

procedure TForm2.Image1Click(Sender: TObject);
begin
  dec(_docss);
  Dockijelzo;
end;

procedure TForm2.Image2Click(Sender: TObject);
begin
  inc(_docss);
  Dockijelzo;
end;

procedure TForm2.GetAlapAdatok;

begin
  docdbase.connected := true;
  with DocQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _ugyfelszam := FieldbyNAme('UGYFELSZAM').asInteger;
      _ugyfeltipus := FieldByNAme('UGYFELTIPUS').asString;
      Close;
    end;
  docdbase.close;
end;      

procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := FALSE;
  Modalresult := 1;
end;


procedure GetJPGSize(const sFile: string; var wWidth, wHeight: word);
const
  ValidSig : array[0..1] of byte = ($FF, $D8);
  Parameterless = [$01, $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7];
var
  Sig: array[0..1] of byte;
  f: TFileStream;
  x: integer;
  Seg: byte;
  Dummy: array[0..15] of byte;
  Len: word;
  ReadLen: LongInt;
begin
  FillChar(Sig, SizeOf(Sig), #0);
  f := TFileStream.Create(sFile, fmOpenRead);
  try
    ReadLen := f.Read(Sig[0], SizeOf(Sig));
    for x := Low(Sig) to High(Sig) do
      if Sig[x] <> ValidSig[x] then
        ReadLen := 0;
      if ReadLen > 0 then
      begin
        ReadLen := f.Read(Seg, 1);
        while (Seg = $FF) and (ReadLen > 0) do
        begin
          ReadLen := f.Read(Seg, 1);
          if Seg <> $FF then
          begin
            if (Seg = $C0) or (Seg = $C1) then
            begin
              ReadLen := f.Read(Dummy[0], 3);  // don't need these bytes 
              wHeight := ReadMWord(f);
              wWidth := ReadMWord(f);
            end
            else
            begin
              if not (Seg in Parameterless) then
              begin
                Len := ReadMWord(f);
                f.Seek(Len - 2, 1);
                f.Read(Seg, 1);
              end
              else
                Seg := $FF;  // Fake it to keep looping. 
            end;
          end;
        end;
      end;
    finally
    f.Free;
  end;
end;


function ReadMWord(f: TFileStream): word;

type
  TMotorolaWord = record
  case byte of
  0: (Value: word);
  1: (Byte1, Byte2: byte);
end;

var
  MW: TMotorolaWord;
begin
  // It would probably be better to just read these two bytes in normally and
  // then do a small ASM routine to swap them. But we aren't talking about
  // reading entire files, so I doubt the performance gain would be worth the trouble.
  f.Read(MW.Byte2, SizeOf(Byte));
  f.Read(MW.Byte1, SizeOf(Byte));
  Result := MW.Value;
end;



end.
