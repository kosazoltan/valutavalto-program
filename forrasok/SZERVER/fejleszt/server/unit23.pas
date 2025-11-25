unit Unit23;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, ExtCtrls, StdCtrls, DB, IBDatabase,
  IBCustomDataSet, IBTable, Buttons, unit1;

type
  TFORGALOMDISPLAY = class(TForm)
    Label1: TLabel;
    IRODAPANEL: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    FORGALOMRACS: TDBGrid;
    IDOSZAKPANEL: TPanel;
    
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    NYOMTATASGOMB: TBitBtn;
    Panel11: TPanel;
    BitBtn2: TBitBtn;
    FORGALOMTABLA: TIBTable;
    FORGALOMDBASE: TIBDatabase;
    FORGALOMTRANZ: TIBTransaction;
    FORGALOMSOURCE: TDataSource;
    SVETTFTPANEL: TPanel;
    SELADOTTFTPANEL: TPanel;
    FORGALOMTABLAERTEKTAR: TIntegerField;
    FORGALOMTABLAIRODASZAM: TIntegerField;
    FORGALOMTABLAVALUTANEM: TIBStringField;
    FORGALOMTABLAVETT: TFloatField;
    FORGALOMTABLAVETTERTEK: TFloatField;
    FORGALOMTABLAELADOTT: TFloatField;
    FORGALOMTABLAELADOTTERTEK: TFloatField;
    FORGALOMTABLAELSZAMOLASIARFOLYAM: TFloatField;
    procedure FormActivate(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FORGALOMDISPLAY: TFORGALOMDISPLAY;
  _svett,_seladott: real;
  _svettft,_seladottft,_vettft,_eladottft: integer;
  _egyseg : string;

implementation

{$R *.dfm}

procedure TFORGALOMDISPLAY.FormActivate(Sender: TObject);
var _ess: integer;
begin
  Top := _top + 195;
  Left := _left + 170;

  case _displaytipus of
    1: begin
          _szuro := '(IRODASZAM=0) AND (ERTEKTAR=0)';
          _egyseg := 'AZ IRODÁK ÖSSZESÍTETT ADATAI';
       end;

    2: begin
         _szuro := '(IRODASZAM=0) AND (ERTEKTAR='+chr(39)+inttostr(_aktkorzet)+chr(39)+')';
         _ESS := Form1.ertTarScan(_aktkorzet);
         _egyseg := _korzetnev[_ess]+'i körzet adatai';
       end;

    3: begin
         _szuro := 'IRODASZAM='+chr(39)+inttostr(_aktpenztar)+chr(39);
         _egyseg := _irodanev[_aktpenztar]+ ' pénztár adatai';
       end;

    4: begin
         _szuro := '(IRODASZAM=-1) AND (ERTEKTAR='+inttostr(_cbsors)+')';
         _egyseg := _subdir[_cbsors]+ ' CHANGE adatai';
       end;
  end;

  Irodapanel.Caption := 'Vizsgált egység: '+ _egyseg;
  IdoszakPanel.Caption := 'Vizsgált idöszak: '+ _idoszakLabel;

  ForgalomDBASE.Close;
  ForgalomDbase.Connected := true;
  if ForgalomTranz.InTransaction then forgalomTranz.Commit;
  ForgalomTranz.StartTransaction;
  with Forgalomtabla do
    begin
      Open;
      Refresh;
      Filtered := false;
      Filter := _szuro;
      Filtered := true;
      First;
    end;
  _seladottft := 0;
  _svettft := 0;

  while not ForgalomTabla.Eof do
    begin
      with ForgalomTabla do
        begin
          _vettFt := FieldByName('VETTERTEK').asInteger;
          _eladottft := FieldByName('ELADOTTERTEK').asInteger;
        end;
      _svettft := _svettft + _vettft;
      _seladottft := _seladottFt + _eladottft;
      ForgalomTabla.Next;
    end;

  ForgalomTabla.First;
  SvettFtPanel.Caption := FormatFloat('###,###,###',_svettft);
  SEladottFtPanel.Caption := FormatFloat('###,###,###',_seladottft);



end;

procedure TFORGALOMDISPLAY.BitBtn2Click(Sender: TObject);
begin
  ForGalomTabla.Close;
  ModalResult := 1;
end;

end.
