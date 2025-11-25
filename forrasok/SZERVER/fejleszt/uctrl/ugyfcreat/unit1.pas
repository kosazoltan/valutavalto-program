unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBTable, IBCustomDataSet,
  IBQuery, ExtCtrls, strutils, ComCtrls;

type
  TForm1 = class(TForm)
    STARTGOMB: TBitBtn;
    ENDGOMB: TBitBtn;
    UQUERY: TIBQuery;
    UTABLA: TIBTable;
    UDBASE: TIBDatabase;
    UTRANZ: TIBTransaction;
    JTABLA: TIBTable;
    JQUERY: TIBQuery;
    JDBASE: TIBDatabase;
    JTRANZ: TIBTransaction;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Shape1: TShape;
    uzeno: TPanel;
    PTNUMPANEL: TPanel;
    Label4: TLabel;
    CSIK: TProgressBar;

    procedure ENDGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
    procedure MakeUgyfel(_tNev: string);
    procedure MakeJogi(_tnev: string);
    procedure Uparancs(_ukaz: string);
    procedure Jparancs(_ukaz: string);
    procedure MunkaMenet;

    function Getstring: string;
    function GetNum: integer;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _ptnums,_uTextPath,_jTextPath,_utablanev,_jTablanev,_pcs,_nev,_mondat: string;
  _elozo,_anyja,_leany,_szulhely,_szulido,_allamp,_lakcim,_okmtip,_azonosito: string;
  _tarthely,_lcimcard,_irszam,_varos,_utca,_okirat,_fotev,_telep,_kepvis: string;
  _orszag,_mbbeo,_kepvisbeo,_iso,_mbnev,_nums,_aktptnums,_minta,_akttxt: string;
  _sorveg: string = chr(13)+chr(10);
  _code,_ugyfnum,_mbnum: integer;
  _srec : Tsearchrec;
  _pts: array[1..180] of string;

  _ptnum,_kulf,_kozszerep,_asc,_wtxt: byte;
  _olvas: Textfile;
  _pp,_epp,_ptdb,_qq: word;

implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);
begin
  _minta := 'c:\receptor\mail\penztarak\u*.txt';
  _PTDB := 0;
  if Findfirst(_minta,faanyfile,_srec)=0 then
    begin
      repeat
        inc(_ptdb);
        PtnumPanel.Caption := inttostr(_ptdb);
        PtnumPanel.Repaint;
        _aktTxt := trim(_srec.name);
        _wtxt:= length(_akttxt);
        _aktptnums := midstr(_aktTxt,2,_wtxt-5);
        _ptS[_ptdb] := _aktptnums;
      until findnext(_srec)<>0;
      FindClose(_srec);
    end;
   if _ptdb=0 then
     begin
       Showmessage('NINCS EGYETLEN PÉNZTÁRTEXT SEM A PENZTARAK MAPPÁBAN');
       EXIT;
     end;
   uzeno.Caption := inttostr(_ptdb)+' darab pénztár-text-et találtam';
   uzeno.repaint;
   Csik.Max := _ptdb;
   StartGomb.Enabled := True;
end;


procedure TForm1.ENDGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;


procedure TForm1.STARTGOMBClick(Sender: TObject);
begin
  _qq := 1;
  while _qq<=_ptdb do
    begin
      Csik.Position := _qq;
      _ptnums := _pts[_qq];
      Munkamenet;
      inc(_qq);
    end;
  Showmessage('Készen vagyok');
end;


procedure TForm1.MunkaMenet;

begin
  _utextPath := 'c:\receptor\mail\penztarak\u'+_ptnums+'.txt';
  _jtextPath := 'c:\receptor\mail\penztarak\j'+_ptnums+'.txt';

  PtnumPanel.caption := _ptnums;
  PtnumPanel.repaint;

  if not fileExists(_utextPath) then
    begin
      Showmessage('Nincs ügyfél text');
      exit;
    end;

  if not fileExists(_jtextPath) then
    begin
      Showmessage('Nincs jogi text');
      exit;
    end;

  _utablanev := 'U' + _ptnums;

  Udbase.Connected := true;
  Utabla.close;
  Utabla.TableName := _utablanev;

  if not Utabla.Exists then MakeUgyfel(_uTablanev);

//  Udbase.Connected := true;
//  if utranz.InTransaction then Utranz.commit;
//  utranz.StartTransaction;

  _pcs := 'DELETE FROM ' + _utablanev;
  Uparancs(_pcs);

  Assignfile(_olvas,_uTextPath);
  reset(_olvas);

  while not eof(_olvas) do
    begin

      readln(_olvas,_mondat);
      _epp := length(_mondat);

      _pp := 1;
      _ugyfnum := GetNum;
      _nev := getstring;
      _elozo:= getstring;
      _anyja:= getstring;
      _leany := getstring;
      _szulhely := getstring;
      _szulido := getstring;
      _allamp := getstring;
      _lakcim:= getstring;
      _okmtip:= getstring;
      _azonosito:= getstring;
      _tarthely := getstring;
      _lcimcard := getstring;
      _kulf := getnum;
      _kozszerep :=getnum;
      _IRSZAM:= GETSTRING;
      _varos := getstring;
      _utca := getstring;
      _iso := getstring;

      Uzeno.Caption := _nev;
      Uzeno.repaint;

      _pcs := 'INSERT INTO ' + _uTablanev + ' (UGYFELSZAM,NEV,ELOZONEV,ANYJANEVE,LEANYKORI,';
      _pcs := _pcs + 'SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,LAKCIM,OKMANYTIPUS,';
      _pcs := _pcs + 'AZONOSITO,TARTOZKODASIHELY,LAKCIMKARTYA,KULFOLDI,';
      _pcs := _pcs + 'KOZSZEREPLO,IRSZAM,VAROS,UTCA,ISO)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_ugyfnum) + ',';
      _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _elozo + chr(39) + ',';
      _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
      _pcs := _pcs + chr(39) + _leany + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
      _pcs := _pcs + chr(39) + _allamp + chr(39) + ',';
      _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
      _pcs := _pcs + chr(39) + _okmtip + chr(39) + ',';
      _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tarthely + chr(39) + ',';
      _pcs := _pcs + chr(39) + _lcimcard + chr(39) + ',';
      _pcs := _pcs + inttostr(_kulf) + ',';
      _pcs := _pcs + inttostr(_kozszerep) + ',';
      _pcs := _pcs + chr(39) + _irszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _varos + chr(39) + ',';
      _pcs := _pcs + chr(39) + _utca + chr(39) + ',';
      _pcs := _pcs + chr(39) + _iso +  chr(39) + ')';
      UParancs(_pcs);
    end;
    Closefile(_olvas);

    // ---------------------------------------------

  _jtablanev := 'J' + _ptnums;

  Jdbase.Connected := true;
  Jtabla.close;
  Jtabla.TableName := _jtablanev;

  if not Jtabla.Exists then MakeJogi(_jTablanev);

//  Udbase.Connected := true;
//  if utranz.InTransaction then Utranz.commit;
//  utranz.StartTransaction;

  _pcs := 'DELETE FROM ' + _jtablanev;
  jparancs(_pcs);

  Assignfile(_olvas,_jTextPath);
  reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      _epp := length(_mondat);

      _pp := 1;
      _ugyfnum := GetNum;
      _nev := getstring;
      _telep := getstring;
      _okirat := getstring;
      _fotev := getstring;
      _kepvis := getstring;
      _mbnum := getNum;
      _mbnev := getstring;
      _mbbeo := getstring;
      _kepvisbeo := getstring;
      _iso := getstring;
      _orszag := getstring;
      _kulf := getnum;

      Uzeno.Caption := _nev;
      Uzeno.repaint;

      _pcs := 'INSERT INTO ' + _jTablanev + ' (UGYFELSZAM,JOGISZEMELYNEV,';
      _pcs := _pcs + 'TELEPHELYCIM,OKIRATSZAM,FOTEVEKENYSEG,KEPVISELONEV,';
      _PCS := _PCS + 'MEGBIZOTTSZAMA,MEGBIZOTTNEVE,MEGBIZOTTBEOSZTASA,';
      _pcs := _pcs + 'KEPVISBEO,ISO,ORSZAG,KULFOLDI)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_ugyfnum) + ',';
      _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telep + chr(39) + ',';
      _pcs := _pcs + chr(39) + _okirat + chr(39) + ',';
      _pcs := _pcs + chr(39) + _fotev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _kepvis + chr(39) + ',';
      _pcs := _pcs + inttostr(_mbnum) + ',';
      _pcs := _pcs + chr(39) + _mbnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _MBBEO + chr(39) + ',';
      _pcs := _pcs + chr(39) + _kepvisbeo + chr(39) + ',';
      _pcs := _pcs + chr(39) + _iso + chr(39) + ',';
      _pcs := _pcs + chr(39) + _orszag + chr(39) + ',';
      _pcs := _pcs + inttostr(_kulf) + ')';
      JParancs(_pcs);
    end;
  Closefile(_olvas);
  Sysutils.DeleteFile(_uTextPath);
  Sysutils.DeleteFile(_jTextPath);
end;

function TForm1.getstring: string;

begin
  result := '';
  while _pp<=_epp do
    begin
      _asc := ord(_mondat[_pp]);
      inc(_pp);
      if _asc=44 then exit;
      result := result + chr(_asc);
    end;
end;

function TForm1.Getnum: integer;

begin
  _nums := getstring;
  val(_nums,result,_code);
  if _code<>0 then result := 0;
end;

procedure TForm1.MakeUgyfel(_tNev: string);

begin
  _pcs := 'CREATE TABLE ' + _tnev + '(' + _sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,'+_sorveg;
  _pcs := _pcs + 'NEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'ELOZONEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'ANYJANEVE CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'LEANYKORI CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'SZULETESIHELY CHAR (50) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'SZULETESIIDO CHAR (11) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'ALLAMPOLGAR CHAR (45) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'LAKCIM CHAR (70) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'OKMANYTIPUS CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'AZONOSITO CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'TARTOZKODASIHELY CHAR (60) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'LAKCIMKARTYA CHAR (25) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'KULFOLDI SMALLINT,'+_sorveg;
  _pcs := _pcs + 'KOZSZEREPLO SMALLINT,'+_sorveg;
  _pcs := _pcs + 'IRSZAM CHAR (4) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VAROS CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'UTCA CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'ISO CHAR (2) CHARACTER SET WIN1250 COLLATE WIN1250)';
  Uparancs(_pcs);
end;

procedure TForm1.MakeJogi(_tnev: string);

begin
  _pcs := 'CREATE TABLE ' + _tnev + ' (' + _sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,' + _sorveg;
  _pcs := _pcs + 'JOGISZEMELYNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'TELEPHELYCIM CHAR (70) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'OKIRATSZAM CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'FOTEVEKENYSEG CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'KEPVISELONEV CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'MEGBIZOTTSZAMA INTEGER,' + _sorveg;
  _pcs := _pcs + 'MEGBIZOTTNEVE CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'MEGBIZOTTBEOSZTASA CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'KEPVISBEO CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'ISO CHAR (2) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'ORSZAG CHAR (45) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'KULFOLDI SMALLINT)';
  JParancs(_pcs);
end;


procedure TForm1.Uparancs(_ukaz: string);
begin
  Udbase.connected := true;
  if utranz.InTransaction then utranz.commit;
  utranz.StartTransaction;
  with uquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Utranz.commit;
  Udbase.close;
end;

procedure TForm1.Jparancs(_ukaz: string);
begin
  Jdbase.connected := true;
  if jtranz.InTransaction then Jtranz.commit;
  jtranz.StartTransaction;
  with Jquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  jtranz.commit;
  Jdbase.close;
end;





end.
