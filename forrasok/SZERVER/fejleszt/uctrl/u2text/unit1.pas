unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls;

type
  TForm1 = class(TForm)
    startgomb: TBitBtn;
    BitBtn2: TBitBtn;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    Label1: TLabel;
    Shape1: TShape;

    procedure BitBtn2Click(Sender: TObject);
    procedure startgombClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function FileKuldes: integer;

    function drim(_s: string): string;
  


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _maildir: string = 'c:\valuta\mail';
  _iras: Textfile;

  _pcs,_ufile,_jfile,_un,_elozo,_anyja,_leany,_szulhely,_szulido,_allamp: string;
  _lakcim,_okmtip,_azonosito,_irszam,_varos,_utca,_tarthely,_mm: string;
  _penztar,_telep,_lcimcard,_umailPath,_jMailpath,_okirat,_fotev,_kepvis: string;
  _orszag,_mbbeo,_iso,_kepbeo,_mbneve: string;
  _remotedir,_remotefile,_localPath: string;
  _sorveg: string = chr(13)+chr(10);

  _kulfoldi,_mbnum,_kozszer,_usz,_ok1,_ok2: integer;

function copyfiletoftprutin: integer; stdcall; external 'c:\valuta\bin\copy2ftp.dll' name 'copyfiletoftprutin';

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.startgombClick(Sender: TObject);
begin
  Startgomb.Enabled := false;
  if not directoryexists(_maildir) then createDir(_maildir);

  _pcs := 'SELECT * FROM PENZTAR';
  valdbase.Connected := true;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _penztar := trim(FieldByNAme('PENZTARKOD').asString);
      Close;
    end;
  Valdbase.close;

  _ufile := 'U' + _penztar + '.TXT';
  _jfile := 'J' + _penztar + '.TXT';

  _uMailPath := _maildir + '\' + _uFile;
  _jMailPath := _maildir + '\' + _jFile;

  assignfile(_iras,_umailpath);
  rewrite(_iras);

  Valdbase.Connected := true;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM UGYFEL');
      Open;
    end;

  while not valquery.Eof do
    begin
      with ValQuery do
        begin
          _usz := FieldByNAme('UGYFELSZAM').asInteger;
          _un  := drim(FieldByNAme('NEV').AsString);
          _elozo := drim(FieldByNAme('ELOZONEV').AsString);
          _anyja := drim(FieldByNAme('ANYJANEVE').AsString);
          _leany := drim(FieldByNAme('LEANYKORI').AsString);
          _szulhely := drim(FieldByNAme('SZULETESIHELY').AsString);
          _szulido := drim(FieldByNAme('SZULETESIIDO').AsString);
          _allamp := drim(FieldByNAme('ALLAMPOLGAR').AsString);
          _lakcim := drim(FieldByNAme('LAKCIM').AsString);
          _OKMTIP := dRIM(FieldByNAme('OKMANYTIPUS').AsString);
          _azonosito := drim(FieldByNAme('AZONOSITO').ASSTRING);
          _tarthely := drim(FieldByNAme('TARTOZKODASIHELY').AsString);
          _lcimcard := drim(FieldByNAme('LAKCIMKARTYA').AsString);
          _KULFOLDI := FieldByNAme('KULFOLDI').ASiNTEGER;
          _kozszer := FieldByNAme('KOZSZEREPLO').asInteger;
          _irszam := drim(FieldByNAme('IRSZAM').AsString);
          _varos := drim(FieldByNAme('VAROS').AsString);
          _utca := drim(FieldByNAme('UTCA').AsString);
          _iso := drim(FieldByNAme('ISO').AsString);
        end;

      _mm := inttostr(_usz)+','+_un+','+_elozo+','+_anyja+','+_leany+',';
      _mm := _mm + _szulhely+','+_szulido+','+_allamp+','+_lakcim+',';
      _mm:= _mm+_okmtip+','+_azonosito+','+_tarthely+','+_lcimcard+',';
      _mm:=_mm+inttostr(_kulfoldi)+','+inttostr(_kozszer)+','+_irszam+',';
      _mm:=_mm+_varos+','+_utca+','+_iso;

      writeLn(_iras,_mm);
      Valquery.next;
    end;
  valquery.close;
  Valdbase.close;
  closefile(_iras);

  // --------------------------------

  assignfile(_iras,_jmailpath);
  rewrite(_iras);

  Valdbase.Connected := true;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM JOGISZEMELY');
      Open;
    end;

  while not valquery.Eof do
    begin
      with ValQuery do
        begin
          _usz := FieldByNAme('UGYFELSZAM').asInteger;
          _un  := drim(FieldByNAme('JOGISZEMELYNEV').AsString);
          _telep:= drim(FieldByNAme('TELEPHELYCIM').ASSTRING);
          _okirat := drim(FieldByname('OKIRATSZAM').AsString);
          _Fotev := drim(FieldByNAme('FOTEVEKENYSEG').AsString);
          _kepvis := drim(FieldByNAme('KEPVISELONEV').AsString);
          _mbnum := FieldByNAme('MEGBIZOTTSZAMA').asInteger;
          _mbNeve := drim(FieldByNAme('MEGBIZOTTNEVE').AsString);
          _MBBEO := drim(Fieldbyname('MEGBIZOTTBEOSZTASA').asString);
          _kepbeo := drim(FieldByNAme('KEPVISBEO').asString);
          _iso := drim(FieldByNAme('ISO').AsString);
          _orszag := drim(FieldByNAme('ORSZAG').AsString);
          _kulfoldi := FieldByNAme('KULFOLDI').asInteger;
        end;

      _mm:=inttostr(_usz)+','+_un+','+_telep+','+_okirat+','+_fotev+',';
      _mm:= _mm+_kepvis+','+inttostr(_mbnum)+','+_mbneve+','+_mbbeo+',';
      _mm:=_mm+_kepbeo+','+_iso+','+_orszag+','+inttostr(_kulfoldi);
      writeLn(_iras,_mm);
      Valquery.next;
    end;
  valquery.close;
  Valdbase.close;
  closefile(_iras);

  // --------------------------------

  _remotedir  := 'PENZTARAK';
  _remotefile := _ufile;
  _localpath  := 'MAIL\'+_uFile;
  _ok1 := FileKuldes;

  _remotedir  := 'PENZTARAK';
  _remotefile := _jfile;
  _localpath  := 'MAIL\'+_jFile;       
  _ok2 := FileKuldes;

  if (_ok2+_ok1)=2 then Showmessage('A két file sikeresen beküldve')
  else showmessage('Nem sikerült beküldeni a 2 file-t');

end;


// =============================================================================
                      function TForm1.Filekuldes: integer;
// =============================================================================


begin

  _pcs := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (LOCALPATH,REMOTEFILE,REMOTEDIR)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_localpath+chr(39)+',';
  _pcs := _pcs + chr(39) + _remotefile + chr(39) + ',';
  _pcs := _pcs + chr(39) + _remotedir + chr(39) + ')';
  ValutaParancs(_pcs);
  result := copyfiletoftprutin;
end;


procedure TForm1.ValutaParancs(_ukaz: string);

begin
  Valdbase.connected := true;
  if valtranz.InTransaction then valtranz.Commit;
  Valtranz.StartTransaction;
  with Valquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Valtranz.commit;
  valdbase.close;
end;


function TForm1.drim(_s: string): string;

var _y,_ws,_asc: byte;

begin
  result := '';
  _s := trim(_s);
  _ws := length(_s);
  if _ws=0 then exit;

  _y := 1;
  while _y<=_ws do
    begin
      _asc := ord(_s[_y]);
      if ((_asc>47) AND (_asc<58)) or (_asc>64) or (_asc=32) then result := result + chr(_asc);
      inc(_y);
    end;
end;


end.
