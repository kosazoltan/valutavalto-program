unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBQuery, IBDatabase, DB, IBCustomDataSet, IBTable,
  ExtCtrls, Buttons, DateUtils, Grids, DBGrids, DBCtrls, ComCtrls, jpeg;

type
  TPERMITCTRL = class(TForm)
    DATATABLA: TIBTable;
    REMOTETABLA: TIBTable;
    DATADBASE: TIBDatabase;
    REMOTEDBASE: TIBDatabase;
    DATATRANZ: TIBTransaction;
    REMOTETRANZ: TIBTransaction;
    DATAQUERY: TIBQuery;
    REMOTEQUERY: TIBQuery;
    ADATBAZIS: TIBDatabase;
    HONAPKEROPANEL: TPanel;
    KILEPO: TTimer;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    IRODAQUERY: TIBQuery;
    IRODADBASE: TIBDatabase;
    IRODATRANZ: TIBTransaction;
    EVCOMBO: TComboBox;
    HONAPCOMBO: TComboBox;
    STARTGOMB: TBitBtn;
    QUITGOMB: TBitBtn;
    Label1: TLabel;
    ALAPLAP: TPanel;
    ENGEDELYRACS: TDBGrid;
    DataSource: TDataSource;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Label2: TLabel;
    DBText1: TDBText;
    DBText2: TDBText;
    Label3: TLabel;
    DBText3: TDBText;
    Label4: TLabel;
    DBText4: TDBText;
    DBText5: TDBText;
    Label5: TLabel;
    DBText6: TDBText;
    DBText7: TDBText;
    Label6: TLabel;
    DBText8: TDBText;
    Label7: TLabel;
    DBText9: TDBText;
    Label8: TLabel;
    DBText10: TDBText;
    Label9: TLabel;
    DBText11: TDBText;
    Label10: TLabel;
    DBText12: TDBText;
    Label11: TLabel;
    DBText13: TDBText;
    STATUSPANEL: TPanel;
    MINDENGOMB: TBitBtn;
    NOPERMITGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    BitBtn1: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    MESSPANEL: TPanel;
    JOBBFUGGONY: TPanel;
    Label12: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Image1: TImage;
    CSIK: TProgressBar;
    Label13: TLabel;
    SCC: TPanel;
    AKTCC: TPanel;
    Label14: TLabel;


    procedure FormActivate(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure Startgombclick(Sender: Tobject);
    procedure IrodaBeolvasas;

    procedure DataParancs(_ukaz: string);
    procedure FDBControl;
    procedure MakeFdb;
    procedure MakeTabla;
    procedure Combotolto;
    procedure GetHaviPenztarAdat;
    procedure GetEngedelyAdat;


    function Nulele(_b: byte): string;
    procedure KILEPOTimer(Sender: TObject);
    function Getertektarszam: byte;
    function Scanetar(_et: byte): byte;
    procedure QUITGOMBClick(Sender: TObject);
    function Getengedonev(_eb: string): string;
    procedure HONAPCOMBOChange(Sender: TObject);
    procedure ENGEDELYRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ENGEDELYRACSDblClick(Sender: TObject);
    procedure ENGEDELYRACSCellClick(Column: TColumn);
    procedure StatusKontrol;
    procedure BitBtn1Click(Sender: TObject);
    procedure NOPERMITGOMBClick(Sender: TObject);
   
  


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PERMITCTRL: TPERMITCTRL;

  _height,_top,_left,_width: word;

  _etarnums: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _etarnames: array[1..8] of string = ('SZEKSZ¡RD','SZEGED','KECSKEM…T','DEBRECEN',
                   'NYÕREGYH¡ZA','B…K…SCSABA','P…CS','KAPOSV¡R');        

  _honev: array[1..12] of string = ('JANU¡R','FEBRU¡R','M¡RCIUS','¡PRILIS','M¡JUS',
                 'J⁄NIUS','J⁄LIUS','AUGUSZTUS','SZEPTEMBER','OKT”BER','NOVEMBER',
                                                            'DECEMBER');

  _irodadarab: byte;
  _irodaszam: array[1..36] of byte;
  _irodanev: array[1..36] of string;

  _pcs,_kertfarok,_arfeTablanev,_remotepath: string;
  _sorveg: string = chr(13)+chr(10);
  _y,_aktiroda: byte;

  _kertev,_kertho,_cc: word;
  _evindex,_hoindex: integer;


  _fdbPath : string = 'C:\ERTEKTAR\DATABASE\ENGEDELY.FDB';
  _host: string;

  _arfedatum,_arfednem,_arfebiz,_arfepros,_pengedo,_etnev,_engTablanev: string;
  _engFdbPath,_eDatum,_eIdo,_eTargy,_ednem,_eengedo,_ebiz,_condi: string;
  _pdnem,_status: string;

  _arfeujarf,_arfebjegy,_arfekdij,_code,_eBjegy,_ekezdij,_earfolyam: integer;
  _recno,_pbjegy,_pkezdij,_pArfolyam: integer;
  _arfeengkod,_maiev,_maiho: word;

  _arfehi,_arfelo,_ertektarszam,_etss,_ePenztar: byte;

  _engoke: boolean;


function ratecontrolrutin: integer; stdcall;  


implementation

{$R *.dfm}


// ============================================================================
                function ratecontrolrutin: integer; stdcall;
// ============================================================================

begin
  permitctrl := Tpermitctrl.Create(Nil);
  result := Permitctrl.showmodal;
  permitctrl.free;
end;


// =============================================================================
             procedure TPERMITCTRL.FormActivate(Sender: TObject);
// =============================================================================

begin

  MessPanel.Visible := false;

  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := trunc((_height-610)/2);
  _left:= trunc((_width-830)/2);

  Top   := _top;
  Left  := _left;
  Height:= 610;
  Width := 830;

  Alaplap.Visible := false;

  AlapadatBeolvasas;


  FdbControl;
  Datadbase.close;
  datadbase.DatabaseName := _fdbPath;

  _ertekTarszam := GetertekTarszam;
  if _ertekTarszam=0 then
    begin
      ShowMessage('EZ AZ IRODA NEM …RT…KT¡R !');
      Kilepo.enabled := true;
      exit;
    end;

  _etss  := Scanetar(_ertektarszam);
  _etnev := inttostr(_ertektarszam)+' '+_etarnames[_etss];

  Irodabeolvasas;
  if _irodaDarab=0 then
    begin
      Showmessage('NEM TUDOM EL…RNI A SZERVERT');
      Kilepo.Enabled := true;
      exit;
    end;

  _maiev  := yearof(date);
  _maiho  := monthof(date);
  Combotolto;

  ActiveControl := StartGomb;

end;


procedure TPermitCtrl.AlapadatBeolvasas;
begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').asstring);
      Close;
    end;
  Valutadbase.close;
end;




// =============================================================================
            procedure TPERMITCTRL.Startgombclick(Sender: Tobject);
// =============================================================================

begin

  with Messpanel do
    begin
      top := 152;
      left :=184;
      Visible := true;
      repaint;
    end;

  _evindex := evcombo.ItemIndex;
  _hoindex := honapcombo.ItemIndex;

  _kertev := _maiev-1+_evindex;
  _kertho := 1 + _hoindex;

  if (_kertev=_maiev) and (_kertho>_maiho) then
    begin
      ShowMessage('A K…RT H”NAP A J÷V’BEN LESZ');
      Messpanel.Visible := false;
      exit;
    end;

  _kertfarok := inttostr(_kertev-2000)+nulele(_kertho);
  _arfetablanev := 'ARFE' + _kertfarok;

  GetHaviPenztarAdat;
  GetEngedelyAdat;
  {
  if not _engoke then
    begin
      Showmessage('NEM VOLT ENGED…LY AD¡S A K…RT H
     exit;
  }

  _pcs := 'SELECT * FROM ENGEDELY' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR,PDATUM';
  DataDbase.Connected := true;
  with DataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  HonapkeroPanel.Visible := False;
  MessPanel.visible := false;
 
  Alaplap.Visible := true;
  StatusKontrol;

  NoPermitGomb.Enabled := true;
  MindenGomb.Enabled := False;
  Activecontrol := Engedelyracs;

end;

// =============================================================================
               function TPERMITCTRL.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
              procedure TPERMITCTRL.DataParancs(_ukaz: string);
// =============================================================================


begin
  datadbase.Connected := true;
  if datatranz.InTransaction then datatranz.Commit;
  datatranz.StartTransaction;
  with dataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Datatranz.Commit;
  datadbase.close;
end;


// =============================================================================
                         procedure TPERMITCTRL.MakeTabla;
// =============================================================================

begin
  Datadbase.close;
  Datadbase.DatabaseName := _fdbPath;
  DataTabla.close;
  dataTabla.TableName := 'ENGEDELY';
  Datadbase.connected := true;
  if not DataTabla.Exists then
    begin
      dataDbase.Close;

      _pcs := 'CREATE TABLE ENGEDELY (' + _sorveg;
      _pcs := _pcs + 'ENGEDELYTIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'BIZONYLATSZAM CHAR (7) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'PDATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'EDATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'PENZTAROSNEV CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
      _pcs := _pcs + 'PDNEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'EDNEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'PENZTAR INTEGER,' + _sorveg;
      _pcs := _pcs + 'PBANKJEGY INTEGER,' + _sorveg;
      _pcs := _pcs + 'EBANKJEGY INTEGER,' + _sorveg;
      _pcs := _pcs + 'PKEZDIJ INTEGER,' + _sorveg;
      _pcs := _pcs + 'EKEZDIJ INTEGER,' + _sorveg;
      _pcs := _pcs + 'PENGEDO CHAR (15) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'EENGEDO CHAR (15) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
      _pcs := _pcs + 'PARFOLYAM INTEGER,' + _sorveg;
      _pcs := _pcs + 'EARFOLYAM INTEGER,' + _sorveg;
      _pcs := _pcs + 'STATUS CHAR (2) CHARACTER SET WIN1250 COLLATE WIN1250)';

      DataParancs(_pcs);
    end;
end;


// =============================================================================
                             procedure TPERMITCTRL.MakeFdb;
// =============================================================================

begin
  if Fileexists(_fdbPath) then exit;

   WITH AdatBazis do
    begin
      databasename := _fdbPath;
      Params.add('USER ''SYSDBA''');
      Params.Add('PASSWORD ''dek@nySo''');
      Params.Add('PAGE_SIZE 4096');
      Params.Add('DEFAULT CHARACTER SET WIN1250');
      CreateDatabase;
    end;
end;

// =============================================================================
                        procedure TPERMITCTRL.FdbControl;
// =============================================================================

begin
  MakeFdb;
  MakeTabla;
end;

// =============================================================================
               procedure TPERMITCTRL.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;

// =============================================================================
                  function TPERMITCTRL.Getertektarszam: byte;
// =============================================================================

var _homePenztarkod: string;

begin
  result := 0;
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByName('PENZTARKOD').asString);
      Close;
    end;
  Valutadbase.close;
 
  val(_homepenztarkod,result,_code);
  if _code<>0 then result := 0;
end;


// =============================================================================
              function TPERMITCTRL.Scanetar(_et: byte): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _etarnums[_y]=_et then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                    procedure TPERMITCTRL.IrodaBeolvasas;
// =============================================================================

var _irodaPath,_ptnev: string;
    _uzlet: byte;

begin
  _irodaPath := _host + ':C:\receptor\database\receptor.fdb';
  _irodaDarab := 0;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (ERTEKTAR='+inttostr(_ertektarszam)+') AND (';
  _pcs := _pcs + 'CLOSED='+chr(39)+'N'+chr(39)+') AND (';
  _pcs := _pcs + 'STATUS='+chr(39)+'P'+chr(39)+')' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  IrodaDbase.close;

  TRY
    irodaDbase.databaseName := _irodaPath;
    irodaDbase.connected := true;
  except
    exit;
  end;

  with IrodaQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not IrodaQuery.eof do
    begin
      _uzlet := IrodaQuery.FieldByName('UZLET').asInteger;
      _ptnev := trim(irodaQuery.FieldbyName('KESZLETNEV').asString);
      inc(_irodaDarab);

      _irodaszam[_irodadarab] := _uzlet;
      _irodanev[_irodaDarab]  := _ptnev;

      IrodaQuery.next;
    end;
  IrodaQuery.close;
  IrodaDbase.close;
end;

// =============================================================================
                      procedure TPERMITCTRL.Combotolto;
// =============================================================================

begin
  evcombo.items.clear;
  evcombo.Items.Add(inttostr(_maiev-1));
  evcombo.Items.Add(inttostr(_maiev));
  evcombo.ItemIndex := 1;

  honapcombo.items.clear;
  _y := 1;
  while _y<=12 do
    begin
      honapcombo.items.add(_honev[_y]);
      inc(_y);
    end;
  honapcombo.itemindex := _maiho-1;
end;


// =============================================================================
             procedure TPERMITCTRL.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  DataQuery.close;
  DataDbase.close;
  ModalResult := 1;
end;

// =============================================================================
                     procedure TPERMITCTRL.GetHAviPenztarAdat;
// =============================================================================

begin
  _pcs := 'DELETE FROM ENGEDELY';
  DataParancs(_pcs);
  cSIK.Max := _irodadarab;
  Scc.Caption := inttostr(_irodadarab);
  scc.Repaint;

  _y := 1;
  while _y<= _irodadarab do
    begin
      Csik.Position := _y;
      Aktcc.caption := inttostr(_y);
      Aktcc.Repaint;
      _aktiroda := _irodaszam[_y];
      _remotepath := _host + ':C:\receptor\database\v' + inttostr(_aktiroda)+'.fdb';

      RemoteDbase.close;
      RemoteDbase.DatabaseName := _remotePath;
      RemoteDbase.Connected := true;

      RemoteTabla.close;
      RemoteTabla.TableName := _arfetablanev;
      if RemoteTabla.Exists then
        begin
          _pcs := 'SELECT * FROM ' + _arfetablanev + _sorveg;
          _pcs := _pcs + 'WHERE ENGEDMENYTIPUS>7';

          with RemoteQuery do
            begin
              close;
              sql.clear;
              sql.add(_PCS);
              Open;
              First;
            end;

          while not RemoteQuery.Eof do
            begin
              _arfedatum := RemoteQuery.FieldByName('DATUM').asString;
              _arfednem  := RemoteQuery.FieldByNAme('VALUTANEM').asstring;
              _arfeujarf := RemoteQuery.FieldByName('UJARFOLYAM').asInteger;
              _arfepros  := trim(RemoteQuery.fieldbyname('PENZTAROSNEV').asString);
              _arfeBiz   := RemoteQuery.FieldByNAme('BIZONYLATSZAM').asString;
              _arfeBjegy := RemoteQuery.FieldByNAme('BANKJEGY').asInteger;
              _arfekdij  := Remotequery.FieldByName('PENZTAROSIMAX').asInteger;
              _arfeengkod:= RemoteQuery.FieldByName('ENGEDMENYTIPUS').asInteger;

              _arfehi := trunc(_arfeengkod/256);
              _arfelo := _arfeengkod - trunc(256*_arfehi);

              if _arfelo>0 then
                begin
                  case _arfelo of
                     16: _pengedo := '…RT…KT¡ROS';
                     32: _pengedo := 'F’…RT…KT¡ROS';
                     64: _pengedo := '‹GYVEZET’';
                    128: _pengedo := 'JUTAL…KMENTES';
                  end;

                  _pcs := 'INSERT INTO ENGEDELY (BIZONYLATSZAM,PDATUM,PDNEM,';
                  _pcs := _pcs + 'PBANKJEGY,PARFOLYAM,PKEZDIJ,PENZTAR,PENZTAROSNEV,';
                  _pcs := _pcs + 'PENGEDO,ENGEDELYTIPUS,STATUS,EDATUM,IDO,';
                  _pcs := _pcs + 'EDNEM,EBANKJEGY,EKEZDIJ,EENGEDO,EARFOLYAM)'+_sorveg;

                  _pcs := _pcs + 'VALUES (' + chr(39)+ _arfebiz + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _arfedatum + chr(39) + ',';

                  _pcs := _pcs + chr(39) + _arfednem + chr(39) + ',';
                  _pcs := _pcs + inttostr(_arfeBjegy) + ',';
                  _pcs := _pcs + inttostr(_arfeujarf) + ',';

                  _pcs := _pcs + '0,';
                  _pcs := _pcs + inttostr(_aktiroda) + ',';
                  _pcs := _pcs + chr(39) + _arfepros + chr(39) + ',';

                  _pcs := _pcs + chr(39) + _pEngedo + chr(39) + ',';
                  _pcs := _pcs + chr(39) + 'A' + chr(39) + ',';
                  _pcs := _pcs + chr(39) + '?' + chr(39) + ',';

                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';
                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';
                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';

                  _pcs := _pcs + '0,';
                  _pcs := _pcs + '0,';

                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';
                  _pcs := _pcs + '0)';


                  DataParancs(_pcs);
                end;

              if _arfehi>0 then
                begin
                  _pengedo := '…RT…KT¡ROS';

                  if _arfehi=4 then _pengedo := '‹GYVEZET’';

                  _pcs := 'INSERT INTO ENGEDELY (BIZONYLATSZAM,PDATUM,PDNEM,';
                  _pcs := _pcs + 'PBANKJEGY,PARFOLYAM,PKEZDIJ,PENZTAR,PENZTAROSNEV,';
                  _pcs := _pcs + 'PENGEDO,ENGEDELYTIPUS,STATUS,EDATUM,IDO,';
                  _pcs := _pcs + 'EDNEM,EBANKJEGY,EKEZDIJ,EENGEDO,EARFOLYAM)'+_sorveg;

                  _pcs := _pcs + 'VALUES (' + chr(39)+ _arfebiz + chr(39) + ',';
                  _pcs := _pcs + chr(39) + _arfedatum + chr(39) + ',';

                  _pcs := _pcs + chr(39) + _arfednem + chr(39) + ',';
                  _pcs := _pcs + inttostr(_arfebjegy) + ',';
                  _pcs := _pcs + '0,';

                  _pcs := _pcs + inttostr(_arfekdij) + ',';
                  _pcs := _pcs + inttostr(_aktiroda) + ',';
                  _pcs := _pcs + chr(39) + _arfepros + chr(39) + ',';

                  _pcs := _pcs + chr(39) + _pengedo + chr(39) + ',';
                  _pcs := _pcs + chr(39) + 'K' + chr(39) + ',';
                  _pcs := _pcs + chr(39) + '?' + chr(39) + ',';

                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';
                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';
                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';

                  _pcs := _pcs + '0,';
                  _pcs := _pcs + '0,';

                  _pcs := _pcs + chr(39) + ' '+chr(39) + ',';
                  _pcs := _pcs + '0)';

                  DataParancs(_pcs);
                end;
              Remotequery.next;
            end;
          RemoteQuery.close;
          Remotedbase.close;
        end;
      Remotedbase.close;
      inc(_y);
    end;
end;


// =============================================================================
                    procedure TPERMITCTRL.GetEngedelyadat;
// =============================================================================

begin
  _engtablanev := 'ENG' + _kertfarok;

  RemoteDbase.close;
  RemoteTabla.close;
  RemoteTabla.TableName := _engTablaNev;

  _engFdbPath := _host + ':C:\receptor\database\engedely.fdb';
  // _engFdbPath := _host + ':C:\receptor\database\engtest.fdb';

  RemoteDbase.DatabaseName := _engFDbPath;
  RemoteDbase.Connected := true;

  _engOke := False;
  if not RemoteTabla.Exists then
    begin
      Remotedbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _engTablaNev;

  with RemoteQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _cc := recno;
      First;
    end;

  Csik.Max := _cc;  
  scc.caption := inttostr(_cc);
  Scc.repaint;
  _cc := 1;
  while not RemoteQuery.eof do
    begin
      Csik.Position := _cc;
      aktcc.Caption := inttostr(_cc);
      Aktcc.Repaint;
      inc(_cc);
      with RemoteQuery do
        begin
          _ePenztar  := FieldByName('PENZTAR').asInteger;
          _eDatum    := FieldByNAme('DATUM').asString;
          _eIdo      := FieldByName('IDO').asString;
          _eTargy    := FieldByNAme('ENGEDELYTARGYA').asString;
          _eDnem     := FieldByNAme('VALUTANEM').asString;
          _eBjegy    := FieldByName('OSSZEG').asInteger;
          _eEngedo   := FieldByName('ENGEDELYEZO').asString;
          _eKezdij   := FieldByNAme('KEDVKEZDIJ').asInteger;
          _eArfolyam := FieldByName('KEDVARFOLYAM').asInteger;
          _eBiz      := FieldByName('BIZONYLATSZAM').asString;
        end;

      if _eBiz='' then
        begin
          RemoteQuery.next;
          continue;
        end;

     _eengedo := getengedonev(_EENGEDO);

      _pcs := 'SELECT * FROM ENGEDELY' + _sorveg;
      _condi := 'WHERE (ENGEDELYTIPUS='+chr(39)+_eTargy+chr(39)+')';
      _condi := _condi + ' AND (BIZONYLATSZAM='+chr(39)+_eBiz+chr(39)+')';
      _condi := _condi + ' AND (PDNEM='+chr(39)+_eDnem+chr(39)+')';

      _pcs := _pcs + _condi;

      DataDbase.connected := true;
      with DataQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
          _recno := recno;
        end;

      if _recno>0 then
        begin
          _pdnem  := DataQuery.FieldByName('PDNEM').asString;
          _pBjegy := DataQuery.FieldByNAme('PBANKJEGY').asInteger;
          _pKezdij:= DataQuery.FieldByName('PKEZDIJ').asInteger;
          _pengedo:= TRIM(DataQuery.FieldByName('PENGEDO').asString);
          _pArfolyam := DataQuery.FieldByName('PARFOLYAM').asInteger;

          DataQuery.close;
          datadbase.close;

          _status := '?';
          If _eTargy='A' then
            begin
              if (_pdnem=_ednem) and (_earfolyam=_parfolyam) and (_eengedo=_pEngedo) and (_eBjegy=_pBjegy) then _status := 'OK';
            end;

          if _eTargy='K' then
            begin
              if (_ekezdij=_pkezdij) and (_eengedo=_pengedo) then _status := 'OK';
            end;

          _pcs := 'UPDATE ENGEDELY SET EDATUM='+chr(39)+_edatum+chr(39)+',';
          _pcs := _pcs + 'IDO=' + chr(39) + _eIdo + chr(39) + ',';
          _pcs := _pcs + 'EDNEM=' + chr(39) + _eDnem + chr(39) + ',';
          _pcs := _pcs + 'EBANKJEGY=' +  inttostr(_eBjegy) + ',';
          _pcs := _pcs + 'EKEZDIJ=' + inttostr(_ekezdij) + ',';
          _pcs := _pcs + 'EENGEDO=' + chr(39) + _eengedo + chr(39) + ',';
          _pcs := _pcs + 'EARFOLYAM=' + inttostr(_earfolyam)+',';
          _pcs := _pcs + 'STATUS=' + chr(39) + _status + chr(39) + _sorveg;
          _pcs := _pcs + _CONDI;

          Dataparancs(_pcs);
        end;
      RemoteQuery.next;
    end;
  RemoteQuery.close;
  Remotedbase.close;
  _engoke := true;
end;

function TPERMITCTRL.Getengedonev(_eb: string): string;

begin
  result := '…RT…KT¡ROS';
  if _eb='E' then exit;

  result := 'F’…RT…KT¡ROS';
  if _eb='F' then exit;

  result := '‹GYVEZET’';
  if _eb='U' then exit;

  result := '';
  if _eb='J' then result := 'JUTAL…KMENTES';
end;







procedure TPERMITCTRL.HONAPCOMBOChange(Sender: TObject);
begin
  Activecontrol := startGomb;
end;

procedure TPERMITCTRL.ENGEDELYRACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  StatusKontrol;
end;

procedure TPERMITCTRL.StatusKontrol;

begin
  _eengedo := trim(DataQuery.FieldByName('EENGEDO').asstring);

  if _eengedo='' then
    begin
      with Jobbfuggony do
        begin
          top := 0;
          Left := 0;
          Visible := true;
        end;
    end else Jobbfuggony.Visible := False;      

  _status := trim(Dataquery.FieldByName('STATUS').asString);
  if _status='OK' then
    begin
      StatusPanel.color := clLime;
      StatusPanel.caption := 'ENGED…LYEZVE';
      statuspanel.Font.Color := clGreen;
    end else
    begin
      StatusPanel.color := clred;
      Statuspanel.Font.color := clWhite;
      StatusPanel.caption := 'NINCS ENGED…LYEZVE';
    end;
  StatusPanel.repaint;
end;


procedure TPERMITCTRL.ENGEDELYRACSDblClick(Sender: TObject);
begin
  StatusKOntrol;
end;

procedure TPERMITCTRL.ENGEDELYRACSCellClick(Column: TColumn);
begin
  StatusKontrol;
end;

procedure TPERMITCTRL.BitBtn1Click(Sender: TObject);
begin
  Dataquery.close;
  Datadbase.close;
  Alaplap.Visible := False;
  HonapkeroPanel.visible := True;
  Activecontrol := Startgomb;
end;

procedure TPERMITCTRL.NOPERMITGOMBClick(Sender: TObject);
begin
  NoPermitGomb.Enabled := False;
  MindenGomb.Enabled := True;

  _pcs := 'SELECT * FROM ENGEDELY' + _sorveg;
  _pcs := _pcs + 'WHERE STATUS='+chr(39)+'?'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR,PDATUM';

  with DataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  StatusKontrol;
  ActiveControl :=  engedelyracs;
end;

end.
