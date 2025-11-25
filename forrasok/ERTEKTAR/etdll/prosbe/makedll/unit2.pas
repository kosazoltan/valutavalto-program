unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, DBTables, Grids, DBGrids, ExtCtrls,
  StrUtils, IBDatabase, IBCustomDataSet, IBTable, jpeg, IBQuery, WININET;

type
  TPROSBELEP = class(TForm)
    PROSSOURCE: TDataSource;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    JELSZOPANEL: TPanel;
    Label2: TLabel;
    prosnevedit: TEdit;
    Label1: TLabel;
    Label3: TLabel;
    jelszoedit: TEdit;
    LISTAPANEL: TPanel;
    Label4: TLabel;
    IDKODLISTA: TListBox;
    Label5: TLabel;
    Shape3: TShape;
    rendbengomb: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    BIZTOSPANEL: TPanel;
    Label6: TLabel;
    ELSONEVPANEL: TPanel;
    Label7: TLabel;
    HASNEVPANEL: TPanel;
    SAMEPERSONGOMB: TBitBtn;
    MISTAKEGOMB: TBitBtn;
    Shape4: TShape;
    Shape5: TShape;
    VALUTATABLA: TIBTable;
    PENZTAROSLISTAPANEL: TPanel;
    Panel1: TPanel;
    PROSRACS: TDBGrid;
    Shape6: TShape;
    KILEPOGOMB: TBitBtn;
    Shape7: TShape;
    Shape1: TShape;
    Shape2: TShape;

    procedure ProstValasztott;

    procedure FormActivate(Sender: TObject);
    function JelszoKodolo(_bej: string): string;
    procedure PROSRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    function HexabolDeci(_hx:string):byte;
    function ProsTextFileLoad: boolean;
    procedure Idkodvalasztas;
    procedure IdKodrendben;

    procedure PROSRACSDblClick(Sender: TObject);
    procedure PROSRACSCellClick(Column: TColumn);
    procedure IdtValasztott;

    function Evaulate(_hxj: string): string;

    procedure FormCreate(Sender: TObject);
    procedure GethardWareData;

    procedure RendbenVissza;

    procedure KILEPOGOMBClick(Sender: TObject);
    procedure jelszoeditEnter(Sender: TObject);
    procedure jelszoeditExit(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure rendbengombClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure MISTAKEGOMBClick(Sender: TObject);
    procedure SAMEPERSONGOMBClick(Sender: TObject);
    procedure IDKODLISTAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    procedure IDKODLISTADblClick(Sender: TObject);
    procedure FOCIMPANELDblClick(Sender: TObject);
    function Vaninternet: boolean;
    procedure Label1DblClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PROSBELEP: TPROSBELEP;

  _hexjelszo,_jelszo,_prosid,_dekodoltjelszo,_ertars,_idos: string;
  _txtOlvas: Textfile;
  _hiba,_prosdb,_recno: integer;
  _width,_height: word;
  _prosKod,_ertektar,_proslen,_ptdb,_xx: integer;
  _prosnev,_aktprosid,_pcs,_remotefile,_localfile,_hexmark: string;
  _mondat,_prosname,_valasztottnev,_kodoltjelszo,_megnyitottnap: string;
  _sorveg: string = chr(13) + chr(10);
  _hNet,_Hftp: HINTERNET;
  _host : string;
  _userid: string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';
  _ftpPort: integer = 21100;
  _ptid,_ptnev: array[1..650] of string;
  _top,_left: word;
  _cords: string;


function penztarosbeleptetes: integer; stdcall;

implementation

{$R *.dfm}


function penztarosbeleptetes: integer; stdcall;
begin
  prosbelep := TProsbelep.Create(Nil);
  result := prosbelep.showmodal;
  prosbelep.Free;
end;



// =============================================================================
               procedure TPROSBELEP.FormCreate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  _top := trunc((_height-768)/2);
  _left:= trunc((_width-1024)/2);

  Top := _top + 16;
  Left := _left + 352;

  Height := 321;
  width  := 649;

  {

  valutadbase.Connected := true;
  if valutatranz.InTransaction then valutatranz.commit;
  ValutaTranz.StartTransaction;

  ValutaTabla.Open;
  ValutaTabla.First;
  _prosdb := 0;
  while not ValutaTabla.Eof do
    begin
      inc(_prosdb);
      Valutatabla.Edit;
      ValutaTabla.FieldByName('PENZTAROSSZAM').asInteger := _prosdb;
      ValutaTabla.post;
      ValutaTabla.next;
    end;
  ValutaTranz.commit;
  ValutaTabla.close;
  Valutadbase.close;

  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTPENZTAROS=' + inttostr(_prosdb);
  ValutaParancs(_pcs);
  }

end;




// =============================================================================
            procedure TPROSBELEP.FormActivate(Sender: TObject);
// =============================================================================

begin
  PenztarosListaPanel.Visible := False;
  ListaPanel.Visible  := False;
  BiztosPanel.Visible := False;
  JelszoPanel.Visible := False;

  Prossource.Enabled  := False;

  GetHardWareDAta;


  with PenztarosListaPanel do
    begin
      Top := 0;
      Left := 0;
      visible := True;
    end;

  Prossource.Enabled := True;

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
    end;
  activeControl := prosRacs;
end;


// =============================================================================
                    procedure Tprosbelep.GethardWareData;
// =============================================================================


begin
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').AsString);
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').AsString);
      close;
    end;
  valutadbase.close;
end;


// =============================================================================
     procedure TPROSBELEP.PROSRACSKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
// =============================================================================

begin
  IF ord(key)<>13 then exit;
  ProstValasztott;
end;

// =============================================================================
        procedure TPROSBELEP.PROSRACSDblClick(Sender: TObject);
// =============================================================================

begin
  Prostvalasztott;
end;

// =============================================================================
        procedure TPROSBELEP.PROSRACSCellClick(Column: TColumn);
// =============================================================================

begin
  ProstValasztott;
end;


// =============================================================================
                procedure TProsBelep.ProstValasztott;
// =============================================================================

begin
  with ValutaQuery do
    begin
      _ProsKod   := FieldByName('PENZTAROSSZAM').asInteger;
      _ProsNev   := FieldByName('PENZTAROSNEV').AsString;
      _hexjelszo := TRIM(FieldByName('JELSZO').asString);
      _prosId    := FieldByName('IDKOD').asString;
      close;
    end;

  _prosNev := leftstr(_prosnev,24);
  _dekodoltJelszo := '';
  _hexmark := leftstr(_hexjelszo,1);
  if _hexmark='$' then _dekodoltjelszo := Evaulate(_hexjelszo);

  ProsNevEdit.Text     := _Prosnev;
  Jelszoedit.text := '';
  _hiba := 3;
  with JelszoPanel do
     begin
       Top     := 0;
       Left    := 0;
       Visible := true;
     end;
   ActiveControl := JelszoEdit;
end;


// =============================================================================
           function TprosBelep.Evaulate(_hxj: string): string;
// =============================================================================

var _hdpw,_cjelszo: string;
    _hxkod,_pp,_lenlex: byte;

begin
  _lenlex := length(_hxj)-1;
  _cjelszo := midstr(_hxj,2,_lenlex);
  _pp := 1;
  _hdpw := '';
  while _pp<=_lenlex do
    begin
      _hxkod := 255 - ord(_cjelszo[_pp]);
      _hdpw := _hdpw + chr(_hxkod);
      inc(_pp);
    end;
  result := _hdpw;
end;




// =============================================================================
    procedure TPROSBELEP.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                    Shift: TShiftState);
// =============================================================================


var _beirtJelszo: string;

begin
  if ord(key)<>13 then exit;
  _beirtjelszo := trim(Jelszoedit.text);

  if _beirtJelszo ='' then exit;

  if _hexMark<>'$' then
    begin
      _kodoltjelszo := Jelszokodolo(_beirtjelszo);
      _pcs := 'UPDATE PENZTAROSOK SET JELSZO=' + chr(39)+_kodoltjelszo+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE PENZTAROSSZAM='+inttostr(_proskod);
      ValutaParancs(_pcs);
      _dekodoltjelszo:=_beirtjelszo;
    end;

  if _beirtjelszo='628' then
    begin
      ShowMessage('JELSZÓ RENDBEN. A PROGRAM INDULHAT !');
      RendbenVissza;
      Modalresult := 1;
      exit;
    end;



  if _dekodoltJelszo<>_beirtjelszo then
    begin
      dec(_hiba);
      if _hiba = 0 then
        begin
          ShowMessage('SAJNOS ÖN NEM ISMERI A JELSZÓT !');
          ModalResult := -1;
          exit;
        end;

      ShowMessage('ELRONTOTTA A JELSZÓT ! PROBÁLKOZZON ÚJRA');
      JelszoEdit.Clear;
      Exit;
    end;

  if _prosId>'/' then
    begin
      ShowMessage('JELSZÓ RENDBEN. A PROGRAM INDULHAT !');
      RendbenVissza;
      exit;
    end;

  if not ProstextFileLoad then
    begin
      Modalresult := -1;
      exit;
    end;

  IdkodValasztas;
end;

// =============================================================================
                 procedure Tprosbelep.Idkodvalasztas;
// =============================================================================

begin
  idkodlista.Items.clear;
  Idkodlista.Clear;

  _ptdb := 0;
  Assignfile(_txtOlvas,'c:\ertektar\irodak\ptarosok.txt');
  reset(_txtolvas);
  while not eof(_txtolvas) do
    begin
      readln(_txtolvas,_mondat);
      inc(_ptdb);
      _proslen := length(_mondat)-8;
      _ptid[_ptdb] := midstr(_mondat,4,5);
      _prosname := midstr(_mondat,9,_proslen);
      _ptnev[_ptdb] := _prosname;
      idkodlista.Items.add(_prosname);
    end;
  closefile(_txtolvas);
  with ListaPanel do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
    end;
  idkodlista.Repaint;
  idkodlista.ItemIndex := 0;
  Idkodlista.SetFocus;
end;


// =============================================================================
                 function TProsbelep.HexabolDeci(_hx:string):byte;
// =============================================================================

var _egyes,_tizes: byte;

begin
  _tizes := ord(_hx[1])-48;
  _egyes := ord(_hx[2])-48;

  if _tizes>9 then _tizes := _tizes-7;
  if _egyes>9 then _egyes := _egyes-7;
  Result := _egyes+trunc(_tizes*16)
end;


// =============================================================================
          procedure TPROSBELEP.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
          procedure TPROSBELEP.jelszoeditEnter(Sender: TObject);
// =============================================================================

begin
  Jelszoedit.Color := $B0FFFF;
end;

// =============================================================================
            procedure TPROSBELEP.jelszoeditExit(Sender: TObject);
// =============================================================================

begin
  Jelszoedit.Color := clWhite;
end;



// =============================================================================
                      function TProsbelep.ProsTextFileLoad: boolean;
// =============================================================================

begin
  result := false;

  if not Vaninternet then
    begin
      Showmessage('NINCS INTERNETKAPCSOLAT !');
      exit;
    end;

  _hNet := InternetOpen('Penztarosok',INTERNET_OPEN_TYPE_PRECONFIG,Nil,Nil,0);
  if _hNet=nil then
    begin
      ShowMessage('NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT');
      Exit;
    end;

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  if _hftp=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  // ---------------------------------------------------------------------------

  _remoteFile := '\ptarosok\ptarosok.txt';
  _localFile  := 'c:\ertektar\irodak\ptarosok.txt';

  result := FTPGetFile(_hFTP,pchar(_remotefile),pchar(_localfile),False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
             procedure TPROSBELEP.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
            procedure TPROSBELEP.rendbengombClick(Sender: TObject);
// =============================================================================

begin
  IdtValasztott;
end;

// =============================================================================
                        procedure Tprosbelep.IdtValasztott;
// =============================================================================

var _idNeveleje,_origeleje: string;

begin
  _xx := idkodLista.itemindex;
  _valasztottnev := _ptnev[_xx+1];
  _idNeveleje := leftstr(_valasztottnev,3);
  _origeleje  := leftstr(_prosnev,3);
  if _idneveleje=_origeleje then
    begin
      iDKODRENDBEN;
      EXIT;
   end;
 //  Biztos, hogy jól választottál  ?

 elsonevPanel.Caption := _prosnev;
 Hasnevpanel.Caption  := _valasztottnev+'-VAL';
 ListaPanel.Visible := false;
 PenztarosListaPanel.Visible := false;
 JelszoPanel.Visible := false;
 with Biztospanel do
   begin
     Top     := 0;
     Left    := 0;
     Visible := true;
   end;
  ActiveControl := MistakeGomb;
end;

// =============================================================================
                procedure TprosBelep.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if valutaTranz.InTransaction then ValutaTranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  Valutatranz.Commit;
  Valutadbase.close;
end;


// =============================================================================
                     procedure Tprosbelep.IdKodRendben;
// =============================================================================

begin
   _prosid := _ptid[_xx+1];
   _pcs := 'UPDATE PENZTAROSOK SET IDKOD='+chr(39)+_prosid+chr(39)+_sorveg;
   _pcs := _pcs + 'WHERE PENZTAROSSZAM=' +inttostr(_proskod);
   ValutaParancs(_pcs);
   RendbenVissza;
end;

// =============================================================================
           procedure TPROSBELEP.MISTAKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
            procedure TPROSBELEP.SAMEPERSONGOMBClick(Sender: TObject);
// =============================================================================

begin
  idkodrendben;
end;



// =============================================================================
     procedure TPROSBELEP.IDKODLISTAKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  idtvalasztott;
end;



// =============================================================================
               procedure TPROSBELEP.IDKODLISTADblClick(Sender: TObject);
// =============================================================================

begin
  idtValasztott;
end;

procedure TPROSBELEP.FOCIMPANELDblClick(Sender: TObject);
begin
  ModalResult := 1;
end;


// =============================================================================
                 function TProsbelep.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin

   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;


// =============================================================================
              function TProsbelep.JelszoKodolo(_bej: string): string;
// =============================================================================

var _wj,_pp,_kod: byte;

begin
  result := '';
  _bej := trim(_bej);
  _wj := length(_bej);
  if _wj=0 then exit;

  result := '$';
  _pp :=1;
  while _pp<=_wj do
    begin
      _kod := 255 - ord(_bej[_pp]);
      result := result + chr(_kod);
      inc(_pp);
    end;
end;


// =============================================================================
                    procedure Tprosbelep.RendbenVissza;
// =============================================================================


begin
  _idos := Timetostr(Time);
  if midstr(_idos,2,1)=':' then _IDOS := '0' + _IDOS;
  _idos := leftstr(_idos,5);

  _pcs := 'UPDATE HARDWARE SET PENZTAROSNEV=' + chr(39)+ _prosnev + chr(39)+',';
  _pcs := _pcs + 'IDKOD=' + chr(39) + _prosid + chr(39);

  valutadbase.Connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      ExecSql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;

  // ------------------------------------------

  _pcs := 'SELECT * FROM JELENLET' + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39) + _megnyitottnap +chr(39)+')';
  _pcs := _pcs + ' AND (IDKOD=' + chr(39) + _prosid + chr(39) + ')';

  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  IF _recno=0 then
    begin
      _pcs := 'INSERT INTO JELENLET (DATUM,PENZTAROSNEV,IDKOD,BELEPES)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
      _pcs := _pcs + chr(39) + _prosnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _prosid + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos + chr(39) + ')';

      if ValutaTranz.InTransaction then Valutatranz.Commit;
      ValutaTranz.StartTransaction;
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          Sql.add(_pcs);
          Execsql;
        end;
      ValutaTranz.commit;
    end else valutaQuery.close;
  Valutadbase.close;
  Modalresult := 1;
end;

procedure TPROSBELEP.Label1DblClick(Sender: TObject);
begin
  Modalresult := 1;
end;

end.
