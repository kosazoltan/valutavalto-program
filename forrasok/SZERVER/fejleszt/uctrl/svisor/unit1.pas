unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBQuery,
  IBCustomDataSet, IBTable, strutils,DateUtils;

type
  TForm1 = class(TForm)
    startgomb: TBitBtn;
    KILEPGOMB: TBitBtn;
    Panel1: TPanel;
    EVEDIT: TEdit;
    Label1: TLabel;
    UTABLA: TIBTable;
    UQUERY: TIBQuery;
    UDBASE: TIBDatabase;
    UTRANZ: TIBTransaction;
    hibaMemo: TMemo;
    PROCMEMO: TMemo;
    mainmemo: TMemo;
    hibapanel: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    nhibapanel: TPanel;
    JHIBAPANEL: TPanel;
    SHIBAPANEL: TPanel;
    Label6: TLabel;
    IGENGOMB: TBitBtn;
    NEMGOMB: TBitBtn;
    Shape1: TShape;
    NOERRPANEL: TPanel;
    Label7: TLabel;
    Label8: TLabel;
    SYXIGENGOMB: TBitBtn;
    SYXNEMGOMB: TBitBtn;
    Shape2: TShape;
    RENDBENPANEL: TPanel;
    evpanel: TPanel;
    Label9: TLabel;
    Label10: TLabel;
    FINALGOMB: TBitBtn;
    Shape3: TShape;
    SYXJAVPANEL: TPanel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    TSYXPANEL: TPanel;
    JSYXPANEL: TPanel;
    SSYXPANEL: TPanel;
    IGENSYXGOMB: TBitBtn;
    NEMSYXGOMB: TBitBtn;
    Label15: TLabel;
    Shape4: TShape;
    javitopanel: TPanel;
    Label16: TLabel;
    NATURJAVITOGOMB: TBitBtn;
    JOGIJAVITOGOMB: TBitBtn;
    SEMMITSEGOMB: TBitBtn;
    Shape5: TShape;
    tipuspanel: TPanel;
    HIBABOX: TListBox;
    MENDPANEL: TPanel;
    Label17: TLabel;
    MEZOPANEL: TPanel;
    Label18: TLabel;
    Label19: TLabel;
    AKTERTPANEL: TPanel;
    Label20: TLabel;
    MENDEDIT: TEdit;
    DATAOKEGOMB: TBitBtn;
    HELPGOMB: TBitBtn;
    BACKGOMB: TBitBtn;
    Shape6: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTATABLA: TIBTable;
    MUGYTABLA: TIBTable;
    MUGYQUERY: TIBQuery;
    MUGYDBASE: TIBDatabase;
    MUGYTRANZ: TIBTransaction;
    BIZQUERY: TIBQuery;
    BIZDBASE: TIBDatabase;
    BIZTRANZ: TIBTransaction;
    NEVQUERY: TIBQuery;
    NEVDBASE: TIBDatabase;
    NEVTRANZ: TIBTransaction;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    HIBALISTAPANEL: TPanel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    nd1: TPanel;
    nd11: TPanel;
    nd3: TPanel;
    nd5: TPanel;
    nd4: TPanel;
    nd2: TPanel;
    nd10: TPanel;
    nd9: TPanel;
    nd8: TPanel;
    nd7: TPanel;
    nd6: TPanel;
    Label33: TLabel;
    Panel3: TPanel;
    tovabbgomb: TBitBtn;
    Shape7: TShape;
    MEZOLISTAPANEL: TPanel;
    MEZOLISTA: TListBox;

    procedure KILEPGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure AllMemoclear;
    procedure JogiJavitas;
    procedure BizAndNevNyitas;
    procedure EVEDITClick(Sender: TObject);
    procedure EVEDITEnter(Sender: TObject);
    procedure EVEDITExit(Sender: TObject);
    procedure EVEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure startgombClick(Sender: TObject);
    procedure NaturSyntaxis;
    procedure GetNaturAdatok;

    function KellEzaBetu(_b: byte): boolean;
    function Nctrl(_s: string): boolean;
    function OkmTipCtrl(_s: string): String;
    function Nulele(_b: byte):string;

    procedure Naturjavitas;
    procedure HibaUzenet;
    function DatumCtrl(_ds: string): boolean;
    procedure NEMGOMBClick(Sender: TObject);
    procedure IGENGOMBClick(Sender: TObject);
    procedure XnHibauzenet(_hkod: word);
    procedure BitBtn1Click(Sender: TObject);
    procedure tovabbgombClick(Sender: TObject);
    procedure nd1Click(Sender: TObject);
 

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _nHibaByte: array[1..26] of byte;
  _nSyxKod: array[1..4096] of string;
  _sx: array[1..11] of word;
  _nxp: array[1..11] of TPanel;
  _mezo: array[1..11] of string;

  _evtizeds,_datums,_biztabla,_nevtabla,_evs,_pcs,_mm: string;
  _ugyfdir,_ugyffile,_ugyfPath,_ks,_vs: string;
  _nev,_anyja,_szulhely,_szulido,_allamp,_lakcim,_azonosito,_tarthely: string;
  _lcimCard,_iso,_okmtip,_syxsor,_aktstring: string;

  _sorveg: string = chr(13)+chr(10);

  _sumFt,_evimax,_hetiossz,_tranzdb,_aktFt,_code,_recno,_nSumFt,_jSumFt: integer;

  _aktev,_kertev,_nHibaDb,_jHibaDB,_sHibaDb,_ugyfDb,_ugyfss,_jTranzdb: word;
  _nTranzdb,_jTranzDv,_nSyxErrordb,_qq: word;

  _betu,_kulfoldi,_tag,_kb,_vb: byte;

implementation

{$R *.dfm}

// =============================================================================
              procedure TForm1.KILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
            procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _aktev := yearof(date);
  _nxp[1] := Nd1;
  _nxp[2] := Nd2;
  _nxp[3] := Nd3;
  _nxp[4] := Nd4;
  _nxp[5] := Nd5;
  _nxp[6] := Nd6;
  _nxp[7] := Nd7;
  _nxp[8] := Nd8;
  _nxp[9] := Nd9;
  _nxp[10]:= Nd10;
  _nxp[11]:= Nd11;

  _mezo[1] := 'NEV';
  _mezo[2] := 'ANYJANEVE';
  _mezo[3] := 'SZULETESIHELY';
  _mezo[4] := 'SZULETESIIDO';
  _mezo[5] := 'ALLAMPOLGAR';
  _mezo[6] := 'LAKCIM';
  _mezo[7] := 'OKMANYTIP';
  _mezo[8] := 'AZONOSITO';
  _mezo[9] := 'LAKCIMKARTYA';
  _mezo[10]:= 'TARTOZKODASIHELY';
  _mezo[11]:= 'ISO';

  Evedit.Text := inttostr(_aktev);
  Activecontrol := Startgomb;
end;

// =============================================================================
              procedure TForm1.EVEDITClick(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Evedit;
end;

// =============================================================================
               procedure TForm1.EVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Evedit.Color := clYellow;
end;

// =============================================================================
                procedure TForm1.EVEDITExit(Sender: TObject);
// =============================================================================

begin
  Evedit.Color := clwindow;
end;

// =============================================================================
        procedure TForm1.EVEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := Startgomb;
end;

// =============================================================================
             procedure TForm1.StartGombClick(Sender: TObject);
// =============================================================================

begin
  StartGomb.Enabled := False;
  _evs := trim(evedit.Text);
  val(_evs,_kertev,_code);

  if _code<>0 then _kertev := 0;
  if (_kertev>_aktev) or (_kertev<2018) then _kertev := 0;
  if _kertev=0 then exit;

  _evtizeds := inttostr(_kertev-2000);

  _ugyfDir  := 'c:\receptor\database';
  _ugyffile := 'UGYFEL' + _evtizeds + '.FDB';
  _ugyfPath := _ugyfdir + '\' + _ugyfFile;

  Nevdbase.close;
  Nevdbase.DatabaseName := _ugyfPath;
  Nevdbase.Connected := true;

  Bizdbase.close;
  Bizdbase.DatabaseName := _ugyfPath;
  Bizdbase.Connected := true;

  _nHibadb := 0;
  _jHibaDb := 0;
  _betu    := 65;

  // ------------------

  while _betu<=90 do
    begin
      _biztabla := chr(_betu)+'BIZ';
      _nevtabla := chr(_betu)+'NEV';

      MainMemo.Lines.Add(_biztabla+': AdatEllenörzés');

      _pcs := 'SELECT * FROM '+ _biztabla + _sorveg;
      _pcs := _pcs + 'ORDER BY SORSZAM';

      with Bizquery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          Open;
          Last;
          _ugyfdb := FieldByNAme('SORSZAM').asInteger;
          Close;
        end;

      if _ugyfdb=0 then
        begin
          inc(_betu);
          Continue;
        end;

      _ugyfss := 1;
      while _ugyfss<=_ugyfdb do
        begin

          _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ugyfss);

          with BizQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
            end;

          _tranzDb := 0;
          _sumFt   := 0;

          while not Bizquery.Eof do
            begin
              _aktFt := BizQuery.FieldByNAme('FIZETENDO').asInteger;
              _sumFt := _sumFt + _aktFt;

              inc(_tranzDb);
              BizQuery.next;
            end;

          BizQuery.close;

          _mm := inttostr(_ugyfss)+' .'+inttostr(_tranzdb)+' db '+ inttostr(_sumFt)+' Ft';
          Procmemo.Lines.Add(_mm);

          _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ugyfss);

          with NevQuery do
            begin
              Close;
              Sql.Clear;
              Sql.Add(_pcs);
              Open;
              _recno := recno;
            end;

          _ntranzdb := 0;
          _nSumft   := 0;

          if _recno>0 then
            begin
              _ntranzdb := Nevquery.FieldByNAme('TRANZAKCIODB').asInteger;
              _nSumft   := NevQuery.FieldByNAme('FORINTOSSZEG').asInteger;
            end;
          Nevquery.close;

          if (_nTranzdb<>_tranzdb) or (_nSumFt<>_sumFt) then
            begin
              inc(_nHibadb);
              _nHibaByte[_nHibadb] := _betu;
              Hibauzenet;
            end;

          inc(_ugyfss);
        end;
      inc(_betu);
    end;

    // ------------------- JOGI SZEMÉLYEK ------------------------------------

  _biztabla := 'JOGIBIZ';
  _nevtabla := 'JOGI';

  MainMemo.Lines.Add('Jogi személyek adatEllenõrzése');

  _pcs := 'SELECT * FROM JOGIBIZ' +  _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  with Bizquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _ugyfdb := FieldByNAme('SORSZAM').asInteger;
    end;

  _ugyfss := 1;
  while _ugyfss<=_ugyfdb do
    begin
      _pcs := 'SELECT * FROM JOGIBIZ' + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ugyfss);

      with BizQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;

      _tranzDb := 0;
      _sumFt   := 0;

      while not Bizquery.Eof do
        begin
          _aktFt := Bizquery.FieldByNAme('FIZETENDO').asInteger;
          _sumFt := _sumFt + _aktft;

          inc(_tranzDb);
          BizQuery.next;
        end;

      BizQuery.close;

      _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ugyfss);

      with Nevquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      _jTranzdb := 0;
      _jSumFt   := 0;

      if _recno>0 then
        begin
          _jTranzdb := Nevquery.FieldByNAme('TRANZAKCIODB').asInteger;
          _jSumFt   := NevQuery.fieldByNAme('FORINTOSSZEG').asInteger;
        end;

      NevQuery.close;

      if (_jTranzdb<>_tranzDb) or (_jSumFt<>_sumFt) then
        begin
          inc(_jHibaDb);
          HibaUzenet;
        end;

      Nevquery.close;
      inc(_ugyfss);
    end;
  Nevdbase.close;
  Bizdbase.close;


  _sHibadb := _nHibadb+_jHibadb;
  if _sHibadb=0 then
    begin
      with NoerrPanel do
        begin
          top := 240;
          left := 240;
          Visible := True;
          repaint;
        end;
      Activecontrol := syxIgenGomb;
      exit;
    end;

    // -----------------------------------------------------

  NhibaPanel.caption := inttostr(_nHibadb)+' db';
  jhibaPanel.caption := inttostr(_JHibadb)+' db';
  shibaPanel.caption := inttostr(_SHibadb)+' db';

  with Hibapanel do
    begin
      top     := 250;
      left    := 270;
      Visible := True;
      Repaint;
    end;
  Activecontrol := IgenGomb;
end;

// =============================================================================
              procedure TForm1.HibaUzenet;
// =============================================================================

var _errmess: string;

begin
  _errmess := 'Tranzakció darab vagy forint nem egyezik';
  Hibamemo.Lines.Add(_nevtabla+'('+inttostr(_ugyfss)+'.) '+_errmess);

end;



// =============================================================================
                procedure TForm1.NEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
                 procedure TForm1.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin
  HibaPanel.Visible := False;
  AllMemoClear;

  if _nHibadb>0 then
    begin
      Mainmemo.Lines.add('TERMÉSZETES SZEMÉLYEK JAVÍTÁSA');
      Naturjavitas;
    end;
  if _jHibadb>0 then
    begin
      Mainmemo.Lines.add('JOGI SZEMÉLYEK JAVÍTÁSA');
      Jogijavitas;
    end;
end;

// =============================================================================
                         procedure TForm1.Naturjavitas;
// =============================================================================

begin

  if _nHibadb=0 then exit;

  BizAndNevNyitas;

  _betu := 65;
  while _betu<=90 do
    begin
      if not kellezabetu(_betu) then
        begin
          inc(_betu);
          Continue;
        end;

      _biztabla := chr(_betu) + 'BIZ';
      _nevtabla := chr(_betu) + 'NEV';
      Mainmemo.Lines.add(_biztabla);

      _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
      _pcs := _pcs + 'ORDER BY sorszam';

      with Bizquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          Last;
          _ugyfdb := FieldByNAme('SORSZAM').asInteger;
          close;
        end;

      _ugyfss := 1;
      while _ugyfss<=_ugyfDb do
        begin
          procMemo.Lines.add(_biztabla + '-' + inttostr(_ugyfSs));

          _pcs := 'SELECT * FROM ' + _BIZTABLA + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ugyfss)+_sorveg;
          _pcs := _pcs + 'ORDER BY DATUM';

          with BizQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
            end;

          _evimax  := 0;
          _sumFt   := 0;
          _tranzDb := 0;

          while not bizquery.Eof do
            begin
              inc(_tranzdb);
              _aktFt  := Bizquery.fieldByNAme('FIZETENDO').asInteger;
              _datums := Bizquery.FieldByNAme('DATUM').asString;

              _sumFt := _sumFt + _aktFt;

              if _aktFt>_evimax then _evimax := _aktFt;
              bizquery.next;
            end;
          Bizquery.close;

          _mm := _nevtabla+':'+inttostr(_tranzdb)+'-'+inttostr(_sumFt)+' Ft';
          Hibamemo.Lines.add(_mm);

          _pcs := 'UPDATE ' + _NEVTABLA + ' SET TRANZAKCIODB='+inttostr(_tranzdb);
          _pcs := _pcs + ',EVIMAX='+inttostr(_evimax);
          _pcs := _pcs + ',FORINTOSSZEG='+inttostr(_sumFt);
          _pcs := _pcs + ',HETIOSSZ='+inttostr(_aktFt);
          _pcs := _pcs + ',DATUM='+chr(39)+_datums+chr(39)+_sorveg;
          _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ugyfss);

          with Nevquery do
            begin
              Close;
              Sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          Nevquery.close;
          inc(_ugyfss);
        end;
      inc(_betu);
   end;

  Nevtranz.commit;
  Nevdbase.close;
  nevquery.close;

  Bizquery.close;
  Bizdbase.close;

  MainMemo.Lines.add('ADATOK FELJAVITVA');
  ShowMessage('Természetes személyek adatai megjavítva');
  AllMemoClear;

end;

// =============================================================================
             function TForm1.KellEzaBetu(_b: byte): boolean;
// =============================================================================

var _y,_hByte: byte;

begin
  result := True;
  _y := 1;
  while _y<=_nHibadb do
    begin
      _hbyte := _NhibaByte[_y];
      if _hByte=_b then exit;
      inc(_y);
    end;
  result := False;
end;


// =============================================================================
                    procedure TForm1.JogiJavitas;
// =============================================================================

begin
  BizAndNevNyitas;

  MainMemo.Lines.Add(' ');
  MainMemo.Lines.Add('JOGI ADATOK JAVÍTÁSA');

  _pcs := 'SELECT * FROM JOGIBIZ ORDER BY SORSZAM';
  with Bizquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _ugyfdb := FieldByNAme('SORSZAM').asInteger;
      close;
    end;

  _ugyfss := 1;
  while _ugyfss<=_ugyfdb do
    begin
      ProcMemo.Lines.Add('SORSZAM: ' +inttostr(_ugyfss));

      _pcs := 'SELECT * FROM JOGIBIZ' + _sorveg;
      _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ugyfss) + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';

      with Bizquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      _tranzdb := 0;
      _sumFt   := 0;
      _evimax  := 0;

      while not Bizquery.Eof do
        begin
          _aktft  := Bizquery.FieldByNAme('FIZETENDO').asInteger;
          _datums := Bizquery.fieldbyname('DATUM').asString;

          inc(_tranzdb);

          _sumFt := _sumFt + _aktFt;
          if _aktFt>_evimax then _evimax := _aktFt;
          Bizquery.next;
        end;
      Bizquery.close;

      _pcs := 'UPDATE JOGI SET FORINTOSSZEG='+inttostr(_sumFt);
      _pcs := _pcs + ',DATUM=' + chr(39) + _datums + chr(39);
      _pcs := _pcs + ',EVIMAX=' + INTTOSTR(_evimax);
      _pcs := _pcs + ',TRANZAKCIODB='+inttostr(_tranzdb);
      _pcs := _pcs + ',HETIOSSZ=' + inttostr(_aktft)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' +inttostr(_ugyfss);

      Hibamemo.Lines.Add(_datums+': '+inttostr(_sumFt)+' Ft');

      with Nevquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      inc(_ugyfss);
    end;

  Nevtranz.commit;

  Nevdbase.close;
  nevquery.close;

  Bizquery.close;
  Bizdbase.close;

  MainMemo.Lines.add('ADATOK FELJAVITVA');

  Showmessage('A jogiszemélyek adatai megjavitva');
  AllMemoClear;

end;


// =============================================================================
                       procedure TForm1.BizandNevNyitas;
// =============================================================================

begin
  bizdbase.close;
  bizdbase.databasename := _ugyfPath;

  nevdbase.close;
  nevdbase.databasename := _ugyfPath;

  bizdbase.connected := True;
  nevdbase.connected := True;

  If nevtranz.InTransaction then nevtranz.commit;
  nevtranz.StartTransaction;
end;

// =============================================================================
                     procedure TForm1.Allmemoclear;
// =============================================================================

begin
  MainMemo.Lines.Clear;
  Mainmemo.Clear;
  Mainmemo.repaint;

  Procmemo.Lines.clear;
  procmemo.clear;
  Procmemo.repaint;

  HibaMemo.Lines.clear;
  Hibamemo.Clear;
  HibaMemo.repaint;
end;

// =============================================================================
                 procedure TForm1.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  NaturSyntaxis;
end;

// =============================================================================
                       procedure TForm1.NaturSyntaxis;
// =============================================================================

var i,_y: byte;
    _aktpanel: TPanel;
    _aktertek: word;

begin
  for i := 1 to 11 do _sx[i] := 0;

  Nevdbase.connected := true;
  _betu := 65;

  while _betu<=90 do
    begin
      _nevtabla := chr(_betu)+'NEV';
      MainMemo.Lines.add(_nevtabla+' ellenõrzése');

      with NevQuery do
        begin
          Close;
          sql.clear;
          sQL.Add('SELECT * FROM '+_nevtabla);
          Open;
        end;

      while not NevQuery.Eof do
        begin
          if _nSyxErrordb>4000 then break;

          GetNaturAdatok;
          ProcMemo.lines.add(_nev);

          if not nctrl(_nev) then xnHibauzenet(1);
          if not nctrl(_anyja) then xnHibaUzenet(2);
          if not nctrl(_szulhely) then xnHibaUzenet(3);
          if not Datumctrl(_szulido) then xnHibauzenet(4);
          if not nctrl(_allamp) then xnHibauzenet(5);
          if not nctrl(_lakcim) then xnHibauzenet(6);
          if not nctrl(_azonosito) then xnHibauzenet(8);

          if _kulfoldi=1 then
            begin
              if not nctrl(_tarthely) then xnHibauzenet(10);
            end else
            begin
              if not nctrl(_lcimcard) then xnHibauzenet(9);
            end;

          if length(_iso)<>2 then xnhibauzenet(11);
          Nevquery.next;
        end;
      Nevquery.close;
      if _NsyxErrordb<4000 then
      begin
        inc(_betu);
      end else
      begin
        Showmessage('TÚL SOK HIBÁT TALÁLTAM !!!');
        break;
      end;
    end;


  _y :=1;
  while _y<=11 do
    begin
      _aktpanel := _nxp[_y];
      _aktertek := _sx[_y];
      _aktpanel.Caption := inttostr(_aktertek);
      _aktpanel.repaint;
      inc(_y);
    end;
  with HibaListaPanel do
    begin
      top := 104;
      left := 522;
      Visible := true;
      repaint;
    end;
  Activecontrol := TovabbGomb;

end;

// =============================================================================
               procedure Tform1.XnHibauzenet(_hkod: word);
// =============================================================================

var _errmess,_syxsor: string;

begin
  inc(_NsyxErrordb);
  case _hkod of
     1: _errmess := 'Hibás ügyfélnév';
     2: _errmess := 'Hibás az anyja neve';
     3: _errmess := 'Hibás születési hely ('+_szulhely+')';
     4: _errmess := 'Születési idõ hibás ('+_szulido+')';
     5: _errmess := 'Hiányzó állampolgárság';
     6: _errmess := 'Hiányzó lakcim';
     7: _errmess := 'Hibás okmánytipus';
     8: _errmess := 'Hibás azonositó';
     9: _errmess := 'Hibás lakcimkártya';
    10: _errmess := 'Hibás tartozkodási hely';
    11: _errmess := 'Hiányzik az ISO kód ('+_allamp+')';
  end;

  _sx[_hkod] := _sx[_hkod] + 1;

  HibaMemo.Lines.add(_errmess);

  _syxsor := nulele(_hkod)+chr(_betu)+inttostr(_ugyfss);
  _nSyxKod[_nsyxErrordb] := _syxsor;
end;



// =============================================================================
                     procedure TForm1.GetNaturAdatok;
// =============================================================================

begin
  _ugyfss   := Nevquery.Fieldbyname('SORSZAM').asInteger;
  _nev      := trim(NevQuery.Fieldbyname('NEV').asString);
  _szulhely := trim(NevQuery.FieldByNAme('SZULETESIHELY').asString);
  _szulido  := trim(NevQuery.FieldByNAme('SZULETESIIDO').asString);
  _lakcim   := trim(Nevquery.FieldByNAme('LAKCIM').asString);
  _okmtip   := trim(Nevquery.FieldByNAme('OKMANYTIP').asString);
  _azonosito:= trim(NevQuery.FieldByNAme('AZONOSITO').asString);
  _anyja    := trim(Nevquery.FieldByNAme('ANYJANEVE').asString);
  _allamp   := trim(NevQuery.FieldByNAme('ALLAMPOLGAR').asString);
  _tarthely := trim(NevQuery.FieldByNAme('TARTOZKODASIHELY').asString);
  _lcimcard := trim(Nevquery.FieldByName('LAKCIMKARTYA').asString);
  _kulfoldi := Nevquery.FieldByNAme('KULFOLDI').asInteger;
  _iso      := trim(Nevquery.FieldByNAme('ISO').asstring);

  _tranzdb  := NevQuery.FieldByNAme('TRANZAKCIODB').asInteger;
  _sumft    := NevQuery.FieldByNAme('FORINTOSSZEG').asInteger;
end;

// =============================================================================
              function TForm1.Nctrl(_s: string): boolean;
// =============================================================================

var _ww,_y,_h,_asc: byte;

begin
  result := False;
  _ww := length(_s);
  if _ww=0 then exit;

  _y :=1;
  _h := 0;
  while _y<=_ww do
    begin
      _asc := ord(_s[_y]);
      if ((_asc>64) and (_asc<91)) or ((_asc>47) and (_asc<58)) then inc(_h);
      inc(_y);
    end;
  if _h<3 then exit;
  result := true;
end;

// =============================================================================
                function TForm1.OkmTipCtrl(_s: string): String;
// =============================================================================

var _elsobetu: string;

begin
  result := 'UTLEVEL';
  _elsobetu := uppercase(leftstr(_s,1));
  if _elsobetu='J' then result := 'JOGOSITVANY';
  if _elsobetu='S' then result := 'SZIG';
end;

// =============================================================================
             function TForm1.DatumCtrl(_ds: string): boolean;
// =============================================================================

var _devs,_dhos,_dnps: string;
    _dev,_dho,_dnp,_homax,_dw: word;

begin
  result := False;

  _dw := length(_ds);
  if _dw<>8 then exit;

  _devs := leftstr(_ds,4);
  _dhos := midstr(_ds,5,2);
  _dnps := midstr(_ds,7,2);

  val(_devs,_dev,_code);
  if _code<>0 then _dev := 0;
  if (_dev<1920) or (_dev>2020) then exit;

  val(_dhos,_dho,_code);
  if _code<>0 then _dho := 0;
  if (_dho<1) or (_dho>12) then exit;

  _homax := daysinamonth(_dev,_dho);
  val(_dnps,_dnp,_code);
  if _code<>0 then exit;
  if _dnp>_homax then exit;
  result := True;
end;


// =============================================================================
              function TForm1.Nulele(_b: byte):string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


procedure TForm1.tovabbgombClick(Sender: TObject);
begin
  HibaListaPanel.Visible := False;
end;

procedure TForm1.nd1Click(Sender: TObject);

var _sss,_tags,_aktmezo: string;

begin
  _TAG := Tpanel(Sender).tag;
  _tags := nulele(_tag);
  AllMemoclear;

  Mezolista.Items.clear;
  Mezolista.clear;
  Nevdbase.Connected := true;

  _aktmezo := _mezo[_tag];

  _qq := 1;
  while _qq<=_nSyxErrordb do
    begin
      _syxsor := trim(_nSyxkod[_qq]);
      if leftstr(_syxsor,2)=_tags then
        begin
          _nevtabla := midstr(_syxsor,3,1)+'NEV';
          _sss := midstr(_SYXSOR,4,length(_syxsor)-3);
          val(_sss,_ugyfss,_Code);
          _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
          _pcs := _pcs + 'WHERE SORSZAM=' + INTTOSTR(_UGYFSS);
          with Nevquery do
            begin
              Close;
              Sql.clear;
              sql.add(_pcs);
              Open;
              _aktstring := trim(FieldByNAme(_aktmezo).AsString);
              Close;
            end;
          Mezolista.Items.Add(_aktstring);
        end;
      inc(_qq);
    end;
  with MezolistaPanel do
    begin
      top := 80;
      left := 40;
      Visible := True;
      repaint;
    end;


end;




// ??????????????????????????????????????
{

// =============================================================================
              function TForm1.MdssCtrl(_s: string): boolean;
// =============================================================================

begin
  result := False;
  if _s='' then exit;
  if (midstr(_s,2,3)<>'NEV') OR (length(_s)<5) then exit;
  result := True;
end;


// =============================================================================
             procedure TForm1.SYXIGENGOMBClick(Sender: TObject);
// =============================================================================

begin

  NoErrPanel.Visible := False;

  MainMemo.Lines.Clear;
  Mainmemo.Clear;
  mAINMEMO.REPAINT;

  Procmemo.Lines.clear;
  procmemo.clear;
  procmemo.repaint;

  HibaMemo.Lines.clear;
  Hibamemo.Clear;
  Hibamemo.repaint;

  Udbase.Connected := true;
  if utranz.InTransaction then utranz.commit;
  Utranz.StartTransaction;

  MainMemo.Lines.Add('TERMÉSZETES SZEMÉLYEK');

  _nSyxErrordb := 0;
  _betu := 65;
  while _betu<=90 do
    begin
      _nevtabla := chr(_betu) + 'NEV';
      Procmemo.Lines.add(_nevtabla+' ellenõrzése ...');

      Utabla.close;
      utabla.TableName := _nevtabla;
      Utabla.Open;
      UTabla.first;

      while not UTabla.Eof do
        begin
          with UTabla do
            begin
              _ss := fieldbyname('SORSZAM').asInteger;
              _nev := trim(FieldByNAme('NEV').AsString);
              _anyja := trim(FieldByNAme('ANYJANEVE').AsString);
              _szulhely := trim(FieldByNAme('SZULETESIHELY').AsString);
              _szulido := trim(FieldByNAme('SZULETESIIDO').asString);
              _allamp := trim(FieldByNAme('ALLAMPOLGAR').AsString);
              _lakcim := trim(FieldByNAme('LAKCIM').AsString);
              _okmtip := trim(FieldByNAme('OKMANYTIP').AsString);
              _azonosito := trim(FieldByNAme('AZONOSITO').asString);
              _tarthely := trim(FieldByNAme('TARTOZKODASIHELY').AsString);
              _lcimcard := trim(FieldByNAme('LAKCIMKARTYA').asString);
              _kulfoldi := FieldByNAme('KULFOLDI').asInteger;
              _iso := trim(FieldByNAme('ISO').AsString);
            end;

          _okmtip := okmtipctrl(_okmtip);
          Utabla.edit;
          Utabla.FieldByName('OKMANYTIP').asString := _okmtip;
          Utabla.Post;

          Procmemo.Lines.add(_nev);

          if not nctrl(_nev) then xnHibauzenet(1);
          if not nctrl(_anyja) then xnHibaUzenet(2);
          if not nctrl(_szulhely) then xnHibaUzenet(3);
          if not Datumctrl(_szulido) then xnHibauzenet(4);
          if not nctrl(_allamp) then xnHibauzenet(5);
          if not nctrl(_lakcim) then xnHibauzenet(6);
          if not nctrl(_azonosito) then xnHibauzenet(8);

          if _kulfoldi=1 then
            begin
              if not nctrl(_tarthely) then xnHibauzenet(10);
            end else
            begin
              if not nctrl(_lcimcard) then xnHibauzenet(9);
            end;

          if length(_iso)<>2 then xnhibauzenet(11);

          UTabla.next;
        end;
      Utabla.close;

      inc(_betu);
    end;
  Utranz.commit;
  Udbase.close;
  UTabla.close;

  // %%%%%%%%%%%%%%%%%%%  JOGI SYNTAX HIBÁK %%%%%%%%%%%%%%%%%%%%%%%%%%%%

  mainmemo.Lines.add('JOGI SZEMÉLYEK');

  Udbase.Connected := True;

  _jSyxErrordb := 0;
  with Uquery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM JOGI');
      Open;
    end;

  while not Uquery.Eof do
    begin
      inc(_jSyxErrordb);

      with Uquery do
        begin
          _ss := FieldByName('SORSZAM').AsInteger;
          _nev := trim(fieldByNAme('JOGISZEMELYNEV').AsString);
          _telep := trim(FieldByNAme('TELEPHELYCIM').AsString);
          _okirat := trim(FieldByNAme('OKIRATSZAM').AsString);
          _fotev := trim(FieldByNAme('FOTEVEKENYSEG').asString);
          _mbneve := trim(FieldByName('MEGBIZOTTNEVE').asString);
          _kepvisnev := trim(FieldByName('KEPVISELONEV').asString);
          _mbbeo := trim(FieldByNAme('MEGBIZOTTBEOSZTASA').AsString);
          _kepvisbeo := trim(FieldByName('KEPVISBEO').AsString);
          _mdss := trim(FieldByNAme('MBDATASORSZAM').asString);
          _iso := trim(FieldByName('ISO').asString);
        end;

      PROCMEMO.Lines.Add(_NEV);

      if not NCtrl(_nev) then xjHibauzenet(1);
      if not NCtrl(_telep) then xjHibauzenet(2);
      if not NCtrl(_okirat) then xjHibauzenet(3);
      if not NCtrl(_fotev) then xjHibauzenet(4);
      if not NCtrl(_mbneve) then xjHibauzenet(5);
      if not NCtrl(_kepvisnev) then xjHibauzenet(6);
      if not NCtrl(_mbbeo) then xjHibauzenet(7);
      if not NCtrl(_kepvisbeo) then xjHibauzenet(8);
      if length(_iso)<>2 then xjHibauzenet(9);
      if not mdssCtrl(_mdss) then xjHibauzenet(10);
      Uquery.next;
    end;
  Uquery.close;
  Udbase.close;

  _sHibadb := _nSyxErrordb+_jSyxErrordb;
  if _shibadb=0 then
    begin
      evpanel.caption := _evs;
      with RendbenPanel do
        begin
          Left := 240;
          Top  := 256;
          Visible := true;
          repaint;
        end;
      Activecontrol := Finalgomb;
      exit;
    end;

  TsyxPanel.Caption := inttostr(_nSyxErrorDb);
  Jsyxpanel.Caption := inttostr(_jsyxErrordb);
  SSyxPanel.Caption := inttostr(_sHibadb);

  with SyxJavPanel do
    begin
      top := 225;
      left:= 264;
      visible := True;
      repaint;
    end;
  Activecontrol := igensyxgomb;
end;







// =============================================================================
          procedure TForm1.FINALGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;



// =============================================================================
            procedure TForm1.IGENSYXGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tipuspanel.Caption := '';
  with JavitoPanel do
    begin
      top := 56;
      left := 8;
      visible := true;
      repaint;
    end;
  Activecontrol := naturjavitogomb;
end;

// =============================================================================
           procedure TForm1.NATURJAVITOGOMBClick(Sender: TObject);
// =============================================================================

var _hKods,_sors: string;
    _hkod : byte;

begin

  naturJavitogomb.enabled := False;
  JogiJavitogomb.Enabled := false;

  Tipuspanel.caption := 'Természetes személyek szintaktikai hibái';
  Tipuspanel.repaint;

  Hibabox.Items.clear;
  Hibabox.clear;
  Hibabox.repaint;

  _q := 1;
  while _q<=_nsyxErrordb do
    begin
      _syxsor := _nsyxKod[_q];
      _hkods := leftstr(_syxsor,2);
      val(_hkods,_hkod,_code);
      _betu := ord(_syxsor[3]);
      _sors := midstr(_syxsor,4,length(_syxsor)-3);
      Hibabox.Items.add(_thibas[_hKod]);
      inc(_q);
    end;

end;

// =============================================================================
               procedure TForm1.HIBABOXDblClick(Sender: TObject);
// =============================================================================

begin
  _row    := 1+Hibabox.ItemIndex;
  _syxsor := _nsyxKod[_row];
  _hkods  := leftstr(_syxsor,2);
  val(_hkods,_hkod,_code);

  _betu := ord(_syxsor[3]);
  _sors := midstr(_syxsor,4,length(_syxsor)-3);

  _nevtabla := chr(_betu)+'NEV';
  _bizTabla := chr(_betu)+'BIZ';
  val(_sors,_ss,_code);
  MendProcess;
end;

// =============================================================================
                         procedure TForm1.MendProcess;
// =============================================================================

begin
  _aktmezo := _mezo[_hkod];

  _pcs := 'SELECT * FROM '+ _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ss);

  Udbase.connected := True;
  with uquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktertek := trim(FieldByNAme(_AKTMEZO).asString);
      close;
    end;
  udbase.close;

  mezopanel.caption := _aktmezo;
  aktertpanel.caption := _aktertek;
  Mendedit.Text := _aktertek;

  with Mendpanel do
    begin
      top := 90;
      left := 300;
      Visible := True;
      repaint;
    end;
  Activecontrol := Mendedit;

end;

// =============================================================================
       procedure TForm1.MENDEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  _ujerteks := trim(mendedit.Text);
  ActiveControl := DAtaOkeGomb;
end;


procedure TForm1.DataokegombClick(Sender: TObject);

begin

  _pcs := 'UPDATE ' + _nevtabla + ' SET '+_aktmezo+'='+chr(39) + _ujerteks +chr(39)+ _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_SS);
  Uparancs(_pcs);

  MendPanel.Visible := False;
end;

// =============================================================================
             procedure TForm1.MENDEDITEnter(Sender: TObject);
// =============================================================================

begin
  Mendedit.color := clYellow;
end;

// =============================================================================
            procedure TForm1.MENDEDITExit(Sender: TObject);
// =============================================================================

begin
  Mendedit.Color := clwhite;
end;

// =============================================================================
            procedure TForm1.MENDEDITClick(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Mendedit;
end;

// =============================================================================
               procedure Tform1.XjHibauzenet(_hkod: word);
// =============================================================================

var _errmess: string;

begin
  inc(_JsyxErrordb);
  case _hkod of
    1: _errmess := 'Hibás jogiszemélynév';
    2: _errmess := 'Hibás telephelycim';
    3: _errmess := 'Hibás okiratszám';
    4: _errmess := 'Hiányzik a fõtevékenység';
    5: _errmess := 'Hiányzik a megbizott neve';
    6: _errmess := 'Hiányzik a képviselõ neve';
    7: _errmess := 'Hiányzik a megbizott beosztása';
    8: _errmess := 'Hiányzik a képviselõ beosztása';
    9: _errmess := 'Hiányzik az ISO kód';
  end;
  HibaMemo.Lines.add(_errmess);
  _syxsor := nulele(_hkod)+'@'+inttostr(_ss);
  _jSyxKod[_nsyxErrordb] := _syxsor;
end;













// =============================================================================
                       procedure TForm1.GetJogiadatok;
// =============================================================================

begin
  _ss        := Uquery.fieldbyname('SORSZAM').AsInteger;
  _nev       := trim(UQuery.Fieldbyname('JOGISZEMELYNEV').ASsTRING);
  _telep     := trim(Uquery.FieldByNAme('TELEPHELYCIM').asString);
  _okirat    := trim(Uquery.FieldByNAme('OKIRATSZAM').AsString);
  _iso       := trim(UQuery.FieldByNAme('ISO').asString);
  _fotev     := trim(Uquery.FieldByName('FOTEVEKENYSeG').AsString);
  _mbneve    := trim(Uquery.FieldByNAme('MEGBIZOTTNEVE').AsString);
  _kepvisnev := trim(Uquery.FieldByName('KEPVISELONEV').asstring);
  _mbbeo     := trim(Uquery.FieldByNAme('MEGBIZOTTBEOSZTASA').asString);
  _kepvisbeo := trim(Uquery.fieldbyname('KEPVISBEO').asString);
  _mbdsors   := trim(Uquery.FieldByNAme('MBDATASORSZAM').asString);
  _kulfoldi  := Uquery.FieldByNAme('KULFOLDI').asInteger;

  _bizdb    := UQuery.FieldByNAme('TRANZAKCIODB').asInteger;
  _sFiz     := UQuery.FieldByNAme('FORINTOSSZEG').asInteger;
end;




// =============================================================================
                function TForm1.OkmTipCtrl(_s: string): String;
// =============================================================================

var _elsobetu: string;

begin
  result := 'UTLEVEL';
  _elsobetu := uppercase(leftstr(_s,1));
  if _elsobetu='J' then result := 'JOGOSITVANY';
  if _elsobetu='S' then result := 'SZIG';
end;

 _tHibas[1] := 'Ügyfélnév javítása';
  _tHibas[2] := 'Anyja neve javítása';
  _tHibas[3] := 'Születési hely javítása';
  _tHibas[4] := 'Születési idõ javítása';
  _tHibas[5] := 'Állampolgárság pótlása';
  _tHibas[6] := 'Lakcím javítása';
  _tHibas[7] := 'Okmánytipus javítása';
  _tHibas[8] := 'Azonosító pótlása';
  _tHibas[9] := 'Lakcimkártya pótlása';
  _tHibas[10]:= 'Tartozkodási hely pótlása';
  _tHibas[11]:= 'ISO kód pótlása';

  _mezo[1] := 'NEV';
  _mezo[2] := 'ANYJANEVE';
  _mezo[3] := 'SZULETESIHELY';
  _mezo[4] := 'SZULETESIIDO';
  _mezo[5] := 'ALLAMPOLGAR';
  _mezo[6] := 'LAKCIM';
  _mezo[7] := 'OKMANYTIP';
  _mezo[8] := 'AZONOSITO';
  _mezo[9] := 'LAKCIMKARTYA';
  _mezo[10]:= 'TARTOZKODASIHELY';
  _mezo[11]:= 'ISO';





procedure TForm1.BACKGOMBClick(Sender: TObject);
begin
  Mendpanel.Visible := False;
end;

procedure TForm1.HELPGOMBClick(Sender: TObject);
begin
  _pcs := 'SELECT * FROM '+ _biztabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' +inttostr(_ss);
  Udbase.Connected := True;
  with Uquery do
    begin
      CLose;
      sql.clear;
      sql.add(_pcs);
      Open;
      _bizonylat := FieldByName('BIZONYAT').asString;
      _datums := FieldByName('DATUM').asString;
      Close;
    end;
   Udbase.close;

   _pts := midstr(_bizonylat,2,3);
   val(_pts,_penztar,_code);
   _farok := midstr(_datums,3,2)+midstr(_datums,6,2);
   _bf := 'BF' + _farok;
   _fdbPath := 'c:\receptor\database\v'+inttostr(_penztar)+'.fdb';

   Valutadbase.close;
   Valutadbase.databasename := _fdbPath;
   Valutadbase.connected := True;

   _ugyfelszam := 0;

   _pcs := 'SELECT * FROM ' + _bf + _sorveg;
   _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39);

   with valutaquery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _recno := recno;
     end;

   if _recno>0 then _ugyfelszam := ValutaQuery.FieldByNAme('UGYFELSZAM').asInteger;

  ValutaQuery.close;
  Valutadbase.close;
  if _ugyfelszam=0 then
    begin
      Showmessage('NINCS ADAT A KÉRT SZEMÉLYRE');
      exit;
    end;
  _mugytablanev := 'U' + inttostr(_penztar);

  Mugydbase.connected := true;
  Mugytabla.close;
  Mugytabla.tablename :=  _mugytablanev;
  if not Mugytabla.exists then
    begin
      Mugydbase.close;
      Showmessage('Nincsenek adatok a kért személyrõl');
      exit;
    end;
  _pcs := 'SELECT * FROM ' + _mugytablanev + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

  with mugyquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin






  _pcs := 'SELECT * FROM ' + _mugytablanev + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELDSZAM='+inttostr(_ugyfelszam);


  end;


end;

// =============================================================================
                procedure TForm1.Uparancs(_ukaz: string);
// =============================================================================

begin
  udbase.connected := True;
  if utranz.InTransaction then utranz.Commit;
  utranz.StartTransaction;
  with Uquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Utranz.commit;
  udbase.close;
end;

  Udbase.Connected := True;
  if utranz.InTransaction then Utranz.Commit;
  utranz.StartTransaction;

  _nhss := 1;
  while _nhss<=_nHibadb do
    begin
      _hibas := _nHiba[_nhss];
      _betus := leftstr(_hibas,1);
      _nevtabla := _betus + 'NEV';
      _bk := ord(_nevtabla[1])-64;

      _sszams  := midstr(_hibas,2,length(_hibas)-1);
      val(_sszams,_sorszam,_code);

      Hibamemo.Lines.Add(_nevtabla+' '+_sszams+' sorszámú tétel javítása');

      _jodb := _sumdb[_bk,_sorszam];
      _joFt := _sumFt[_bk,_sorszam];

      _pcs := 'UPDATE ' +_nevtabla + ' SET TRANZAKCIODB='+inttostr(_joDb);
      _pcs := _pcs + ',FORINTOSSZEG='+inttostr(_joFt)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

      Procmemo.Lines.Add(lowercase(_pcs));
      with UQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;

      inc(_nhSS);
    end;
  UTranz.commit;
  Udbase.close;


  ProcMemo.Lines.add('TERM.SZEMÉLYEK TRANZAKCIÓI MEGJAVÍTVA');

  // ---------------------------------------------------------------------


  Mainmemo.Lines.Add('JOGI SZEMÉLYEK MEGJAVITÁSA');

  {
  Udbase.Connected := True;
  if utranz.InTransaction then Utranz.Commit;
  utranz.StartTransaction;

  _jhss := 1;
  while _jhss<=_jHibadb do
    begin
      _aktjss := _jHiba[_jhss];
      _aktjdb := _jSumdb[_aktjss];
      _aktjFt := _jSumft[_aktjss];

       Hibamemo.Lines.add(inttostr(_jhss)+'. hiba = '+inttostr(_aktjdb)+' db '+inttostr(_aktjFt)+' Ft');

      _pcs := 'UPDATE JOGI SET TRANZAKCIODB='+inttostr(_aktjdb);
      _pcs := _pcs + ',FORINTOSSZEG='+inttostr(_aktjft)+_sorveg;
      _pcs := _pcs + 'WHERE SORSZAM='+INTTOSTR(_AKTJSS);

      with Uquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;

      procmemo.Lines.add(lowercase(_pcs));

      inc(_jhss);
    end;
  Utranz.commit;
  Udbase.close;
  Uquery.close;


  ProcMemo.Lines.add('JOGISZEMÉLY TRANZAKCIÓK MEGJAVÍTVA');
end;






}


end.
