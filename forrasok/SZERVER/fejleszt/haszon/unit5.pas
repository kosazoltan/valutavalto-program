unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, unit1, IBDatabase, DB, IBTable,
  IBCustomDataSet, IBQuery;

type
  THASZONFELVIVOFORM = class(TForm)
    ALAPPANEL: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    OSSZESEDIT: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    haszonkeszgomb: TBitBtn;
    HASZONMEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    Panel20: TPanel;
    HEDIT1: TEdit;
    HEDIT2: TEdit;
    HEDIT3: TEdit;
    HEDIT4: TEdit;
    HEDIT5: TEdit;
    HEDIT6: TEdit;
    HEDIT7: TEdit;
    HEDIT8: TEdit;
    HPANEL1: TPanel;
    HPANEL2: TPanel;
    HPANEL3: TPanel;
    HPANEL4: TPanel;
    HPANEL5: TPanel;
    HPANEL6: TPanel;
    HPANEL7: TPanel;
    HPANEL8: TPanel;
    BESZQUERY: TIBQuery;
    BESZTABLA: TIBTable;
    BESZDBASE: TIBDatabase;
    BESZTRANZ: TIBTransaction;
    KILEPO: TTimer;
    procedure HEDIT1Enter(Sender: TObject);
    procedure HEDIT1Exit(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HEDIT1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure haszonkeszgombClick(Sender: TObject);
    procedure HASZONMEGSEMGOMBClick(Sender: TObject);
    procedure Sumdisplay;
    procedure HEDIT1Change(Sender: TObject);
    procedure HPANEL1Enter(Sender: TObject);
    procedure HPANEL1Click(Sender: TObject);
    function MakeBeszTabla(_bsztnev: string): boolean;
    procedure Haszonbeolvasas;
    procedure HaszonFeliras;
    procedure KILEPOTimer(Sender: TObject);
    procedure BeszParancs(_ukaz: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HASZONFELVIVOFORM: THASZONFELVIVOFORM;
  _hedit: array[1..8] of Tedit;
  _hpanel: array[1..8] of TPanel;
  _aktertek,_ertek,_akthaszon: integer;
  _aktedit: Tedit;
  _text,_besztablanev: string;

implementation

uses Unit2;

{$R *.dfm}

procedure THASZONFELVIVOFORM.HEDIT1Enter(Sender: TObject);
begin
  _tag := Tedit(sender).Tag;
  _hpanel[_tag].Color := clYellow;
  _text := _hedit[_tag].text;
  val(_text,_ertek,_code);
  if _code<>0 then _ertek := 0;
  _hpanel[_tag].Caption := Kijelzes.ftform(_ertek);
end;

procedure THASZONFELVIVOFORM.HEDIT1Exit(Sender: TObject);
begin
  _tag := Tedit(sender).tag;
  _hpanel[_tag].Color := $FFB0FF;
end;

procedure THASZONFELVIVOFORM.FormActivate(Sender: TObject);

var i: integer;

begin
  Top := _top + 72;
  Left := _left +392;
  AlapPanel.Visible := false;
  _besztablanev := 'BESZ' + _farok;

  if MakeBeszTabla(_besztablanev) then
    begin
      Haszonbeolvasas;
      Kilepo.enabled := true;
      exit;
    end;

  _hedit[1] := Hedit1;
  _hedit[2] := Hedit2;
  _hedit[3] := Hedit3;
  _hedit[4] := Hedit4;
  _hedit[5] := Hedit5;
  _hedit[6] := Hedit6;
  _hedit[7] := Hedit7;
  _hedit[8] := Hedit8;

  _hpanel[1] := Hpanel1;
  _hpanel[2] := Hpanel2;
  _hpanel[3] := Hpanel3;
  _hpanel[4] := Hpanel4;
  _hpanel[5] := Hpanel5;
  _hpanel[6] := Hpanel6;
  _hpanel[7] := Hpanel7;
  _hpanel[8] := Hpanel8;

  for i := 1 to 8 do
    begin
      _pHaszon[i] := 0;
      _hpanel[i].caption := '';
      _hedit[i].clear;
    end;

  AlapPanel.visible := true;
  Sumdisplay;
  ActiveControl := Hedit1;
end;

procedure THASZONFELVIVOFORM.HEDIT1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _text: string;  

begin
  _tag := TEdit(sender).Tag;
  if ord(key)= 38 then
    begin
      if _tag=1 then exit;
      dec(_tag);
      ActiveControl := _hedit[_tag];
      exit;
    end;

  if (ord(key)<>13) AND (ord(key)<>40) then exit;
  _text := _hedit[_tag].text;
  val(_text,_aktertek,_code);
  if _code<>0 then _aktertek := 0;
  _phaszon[_tag] := _aktertek;

  Sumdisplay;

  if _tag=8 then
    begin
      ActiveControl := HaszonKeszGomb;
      exit;
    end;

  inc(_tag);
  ActiveControl := _hedit[_tag];

end;

procedure THASZONFELVIVOFORM.haszonkeszgombClick(Sender: TObject);
var _akts: string;
    _aktErtek,i,_irodanapiprofit,_aktertekTar: integer;
begin
  Alappanel.Visible := False;
  _qq := 1;
  while _qq<=8 do
    begin
      _aktEdit := _hedit[_qq];
      _akts := _aktedit.text;
      val(_akts,_aktertek,_code);
      if _code<>0 then _aktertek := 0;
      if _aktertek=0 then
        begin
          Showmessage('MINDEN ÉRTÉKET MEG KELL ADNI !');
          ActiveControl := _aktedit;
          exit;
        end;
      _pHaszon[_qq] := _aktertek;
      Sumdisplay;
      inc(_qq);
    end;

  for i := 1 to 8 do _pertekTar[i] := 0;

  _qq := 1;
  while _qq<=150 do
    begin
      _irodanapiProfit := _tProfit[_qq];
      _aktertektar := _hErtekTar[_qq];
      _xx := Form1.Scanetar(_aktertektar);
      _pertektar[_xx] := _pErtekTar[_xx]+_irodanapiprofit;
      inc(_qq);
    end;

  _qq := 1;
  while _qq<=8 do
    begin
      _korzArany[_qq] := _phaszon[_qq]/_pertektar[_qq];
      inc(_qq);
    end;

  _qq := 1;
  while _qq<=150 do
    begin
      _wprofit[_qq] := 0;
      _irodanapiprofit := _tProfit[_qq];
      if _irodanapiProfit>0 then
        begin
          _aktertektar := _hertekTar[_qq];
          _xx := form1.Scanetar(_aktertektar);
          _wprofit[_qq] := round(_irodanapiProfit*_korzarany[_xx]);
        end;
      inc(_qq);
    end;

  Haszonfeliras;
  ModalResult := 1;

end;

procedure THaszonfelvivoForm.Sumdisplay;

var _ss,i: integer;

begin
  _ss := 0;
  for i := 1 to 8 do _ss := _ss + _pHaszon[i];

  Osszesedit.text := inttostr(_ss);
end;

procedure THASZONFELVIVOFORM.HASZONMEGSEMGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure THASZONFELVIVOFORM.HEDIT1Change(Sender: TObject);
begin
  _tag := Tedit(sender).Tag;
  _text := _hedit[_tag].text;
  val(_text,_ertek,_code);
  if _code<>0 then _ertek := 0;
  _hpanel[_tag].Caption := Kijelzes.ftform(_ertek);
  _hPanel[_tag].Repaint;
end;

procedure THASZONFELVIVOFORM.HPANEL1Enter(Sender: TObject);
begin
  _TAG := tpANEL(SENDER).Tag;
  ActiveControl := _hedit[_tag];
end;

procedure THASZONFELVIVOFORM.HPANEL1Click(Sender: TObject);
begin
  _tag := TPanel(sender).Tag;
  ActiveControl := _hedit[_tag];
end;



function THaszonfelvivoForm.MakeBeszTabla(_bsztnev: string): boolean;

var _hh: integer;

begin
  result := True;
  Beszdbase.connected := True;
  Besztabla.close;
  besztabla.TableName := _bsztnev;
  if besztabla.Exists then
    begin
      Besztabla.Open;
      _hh := Besztabla.FieldByName('HASZON').asInteger;
      Besztabla.close;
      Beszdbase.close;
      if _hh=0 then result := false;
      exit;
    end;

  if Besztranz.InTransaction then Besztranz.commit;
  Besztranz.StartTransaction;

  _pcs := 'CREATE TABLE '+_bsztnev+' (' + _sorveg;
  _pcs := _pcs + 'PENZTAR SMALLINT,'+_sorveg;
  _pcs := _pcs + 'ERTEKTAR SMALLINT,'+_sorveg;
  _pcs := _pcs + 'PENZTARNEV CHAR (26) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'VUGYFEL SMALLINT,'+_sorveg;
  _pcs := _pcs + 'VETEL DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'EUGYFEL SMALLINT,'+_sorveg;
  _pcs := _pcs + 'ELADAS DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'WUUGYFEL SMALLINT,'+_sorveg;
  _pcs := _pcs + 'WUHUF DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'WUUSD DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'HASZON DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'KEZELESIDIJ DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'TRANZADO DOUBLE PRECISION)';

  with BeszQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Execsql;
    end;
  Besztranz.commit;
  Beszdbase.close;
  result := False;
end;

procedure THaszonfelvivoForm.Haszonfeliras;

begin
  _qq := 1;
  while _qq<=150 do
    begin
      _akthaszon := _wProfit[_qq];
      if _akthaszon>0 then
        begin
          _pcs := 'SELECT * FROM '+ _beszTablaNev + _sorveg;
          _pcs := _pcs + 'WHERE PENZTAR=' + inttostr(_qq);
          Beszdbase.Connected := true;
          with BeszQuery do
            begin
              Close;
              sql.clear;
              sql.Add(_pcs);
              Open;
              _recno := Recno;
              Close;
            end;

          Beszdbase.close;

          if _recno>0 then
            begin
              _pcs := 'UPDATE '+_besztablanev+' SET HASZON='+inttostr(_akthaszon)+_sorveg;
              _pcs := _pcs + 'WHERE PENZTAR=' + inttostr(_qq);
            end else
            begin
              _pcs := 'INSERT INTO ' + _BESZTABLANEV + ' (';
              _pcs := _pcs + 'PENZTAR,ERTEKTAR,PENZTARNEV,HASZON)'+_sorveg;
              _pcs := _pcs + 'VALUES (' + inttostr(_qq) + ',';
              _pcs := _pcs + inttostr(_hertektar[_qq]) + ',';
              _pcs := _pcs + chr(39) + _irodanev[_qq] + CHR(39) + ',';
              _pcs := _pcs + inttostr(_akthaszon)+')';
            end;
          BeszParancs(_pcs);
        end;
      inc(_qq);
    end;
end;


procedure THaszonfelvivoForm.BeszParancs(_ukaz: string);

begin
  Beszdbase.Connected := true;
  if BeszTranz.InTransaction then Besztranz.commit;
  Besztranz.StartTransaction;
  with Beszquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      execSql;
    end;
  Besztranz.commit;
  Beszdbase.close;
end;





procedure THaszonfelvivoForm.HaszonBeolvasas;

var i,_pt: integer;

begin
  for i := 1 to 150 do _wProfit[i] := 0;

  _pcs := 'SELECT * FROM '+ _besztablanev;
  Beszdbase.Connected := true;
  with BeszQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  while not BeszQuery.Eof do
    begin
      _pt := Beszquery.FieldByName('PENZTAR').asInteger;
      _akthaszon := Beszquery.FieldByName('HASZON').asInteger;
      _wprofit[_pt] := _akthaszon;
      BeszQuery.Next;
    end;
  BeszQuery.close;
  Beszdbase.close;

end;






procedure THASZONFELVIVOFORM.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Modalresult := 1;
end;

end.
