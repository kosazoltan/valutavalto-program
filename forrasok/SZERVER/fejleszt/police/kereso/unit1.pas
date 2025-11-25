unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, Grids, DBGrids, IBDatabase,
  IBCustomDataSet, IBQuery, ExtCtrls, strutils, IBTable;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    kilepgomb: TBitBtn;
    SQUERY: TIBQuery;
    SDBASE: TIBDatabase;
    STRANZ: TIBTransaction;
    racs: TDBGrid;
    DSOURCE: TDataSource;
    FDBLIST: TListBox;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    fdbpanel: TPanel;
    DISPLAYGOMB: TBitBtn;
    nextpanel: TPanel;
    STABLA: TIBTable;
    datumpanel: TPanel;
    nevedit: TEdit;
    procedure kilepgombClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FDBLISTDblClick(Sender: TObject);

    procedure EVCOMBOChange(Sender: TObject);
    procedure HOCOMBOChange(Sender: TObject);
    procedure DISPLAYGOMBClick(Sender: TObject);
    procedure NEXTGOMBClick(Sender: TObject);





  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1 : TForm1;
  _minta: string;
  _srec : TSearchrec;
  _fdbnev,_path,_PCS,_farok,_bf,_next,_evs,_hos,_kernev: string;
  _sorveg: string = chr(13)+chr(10);
  _db,_ev,_ho: word;
  _index,_evindex,_hoindex,_fdbindex,_recno: integer;


implementation

{$R *.dfm}

procedure TForm1.kilepgombClick(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  SDBASE.CLOSE;

end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  fdbList.clear;
  fdblist.Items.clear;

  _minta := 'c:\_work\late\v*.fdb';
  if FindFirst(_minta, faanyfile, _srec) = 0 then
  begin
    _db := 0;
    repeat
      inc(_db);
      _fdbnev := _srec.Name;
      fdblist.Items.add(_fdbnev);
    until FindNext(_srec) <> 0;
    FindClose(_srec);
  end;

 evcombo.itemindex := 0;
 hocombo.itemindex := 0;

 FdbList.ItemIndex := 0;
 FdbList.SetFocus;
end;

procedure TForm1.FDBLISTDblClick(Sender: TObject);
begin
  _index := fdblist.itemindex;
  _fdbnev := fdblist.items[_index];
  _path := 'c:\_work\late\'+_fdbnev;
  fdbpanel.Caption := _path;
  fdbpanel.repaint;

  _evindex := 0;
  _hoindex := 0;

  Activecontrol := DisplayGomb;
end;


procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  Activecontrol := DisplayGomb;
end;

procedure TForm1.HOCOMBOChange(Sender: TObject);
begin
  Activecontrol := displaygomb;
end;

procedure TForm1.DISPLAYGOMBClick(Sender: TObject);
begin

  SQUERY.CLOSE;

  _fdbindex := fdblist.ItemIndex;
  _fdbnev := fdblist.Items[_fdbindex];
  _path := 'c:\_work\LATE\' + _fdbnev;

  FDBPanel.Caption := _path;
  fdbPanel.repaint;

  sdbase.close;
  sdbase.DatabaseName := _path;
  sdbase.Connected := true;

  _evindex  := evcombo.itemindex;
  _evs := evcombo.items[_evindex];
  _hoindex := hocombo.itemindex;
  _hos := Hocombo.items[_hoindex];
  _farok := midstr(_evs,3,2)+_hos;
  _bf := 'BF' + _farok;

  datumpanel.caption := '20'+leftstr(_farok,2)+'.'+midstr(_farok,3,2);
  Datumpanel.repaint;

  _kernev := trim(Nevedit.Text);
  if _kernev='' then
    begin
      Showmessage('NINCS NÉV MEGADVA');
      SDBASE.CLOSE;
      exit;
    end;

  STABLA.CLOSE;
  STABLA.TableName := _BF;
  if not stabla.Exists then
    begin
      sdbase.close;
      Nextgombclick(Nil);
      exit;
    end;  

  _pcs :=  'SELECT * FROM ' + _BF + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELNEV LIKE '+chr(39)+_kernev+'%'+CHR(39);
//  _pcs := _pcs + 'ORDER BY UGYFELNEV';

  with squery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _RECNO := recno;
    end;
  if _recno=0 then
    begin
      Nextgombclick(Nil);
      exit;
    end;

  sleep(400);
  squery.first;
  Racs.setfocus;

end;

procedure TForm1.NEXTGOMBClick(Sender: TObject);
begin
  _fdbindex := fdblist.itemindex;
  _HOINDEX := hocombo.itemindex;
  _evindex := evcombo.itemindex;
  inc(_hoindex);
  if _hoindex>11 then
    begin
      _hoindex := 0;
      inc(_evindex);
    end;
  if _evindex>1 then
    begin
   //   Showmessage('KÖVETKEZÖ PÉNZTÁR JÖN');
      inc(_fdbindex);
      _evindex := 0;
      _hoindex := 0;
      evcombo.ItemIndex :=0;
      hocombo.ItemIndex := 0;

      IF (_fdbindex=_db) then
        begin
          showmessage('NINCS TÖBB PÉNZTÁR');
          aCTIVECONTROL := KilepGomb;
          exit;
        end;
      fdblist.ItemIndex := _fdbindex;
    end;
  evcombo.ItemIndex := _evindex;
  hocombo.ItemIndex := _hoindex;
  Displaygombclick(Nil);

end;


end.
