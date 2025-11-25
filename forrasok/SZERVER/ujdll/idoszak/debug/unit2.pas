unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, dATEuTILS,StrUtils;

type
  TIDOSZAKBEFORM = class(TForm)
    Shape1: TShape;
    Label1: TLabel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    TOLCOMBO: TComboBox;
    IGCOMBO: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    IDSZOKEGOMB: TBitBtn;
    IDSZCANCELGOMB: TBitBtn;
    AQUERY: TIBQuery;
    ADBASE: TIBDatabase;
    ATRANZ: TIBTransaction;

    procedure IDSZOKEGOMBClick(Sender: TObject);
    procedure IDSZCANCELGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure AParancs(_ukaz: string);

    procedure EVCOMBOChange(Sender: TObject);
    procedure TOLCOMBOChange(Sender: TObject);
    procedure IGCOMBOChange(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IDOSZAKBEFORM: TIDOSZAKBEFORM;
 _aktev,_aktho,_houtnap,_kertev,_kertho,_tolnap: word;
 _honapnev: array[1..12] of string = ('Január','Február','Március','Április',
               'Május','Junius','Július','Augusztus','Szeptember','Október',
               'November','December');

  _napnev: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK','PÉNTEK',
               'SZOMBAT','VASÁRNAP');

  _tols,_igs,_tolstring,_igstring,_datumtols,_datumigs,_pcs: string;
  _sorveg : string = chr(13)+chr(10);



function getidoszakrutin: integer; stdcall;

implementation

function getidoszakrutin: integer; stdcall;
begin
  IdoszakbeForm := TidoszakbeForm.create(Nil);
  result := IdoszakbeForm.ShowModal;
  Idoszakbeform.free;
end;



{$R *.dfm}



procedure TIDOSZAKBEFORM.FormActivate(Sender: TObject);

VAR I: INTEGER;

begin
  Top  := 380;
  Left := 330;

  _pcs := 'DELETE FROM IDOSZAK';
  Aparancs(_pcs);

  EVCombo.Clear;
  HoCombo.Clear;

  tolcombo.Clear;
  Igcombo.Clear;

  _aktev := yearof(date);
  _aktho := monthof(date);

  for i := -2 to 0 do  Evcombo.Items.add(inttostr(_aktev+i));
  for i := 1 to 12 do HoCombo.Items.Add(_honapnev[i]);

  _houtnap := daysinamonth(_aktev,_aktho);

  for i := 1 to _houtnap do
    begin
      tolcombo.Items.Add(inttostr(i));
      igCombo.Items.Add(inttostr(i));
    end;

  evcombo.ItemIndex  := 2;
  hocombo.ItemIndex  := _aktho-1;

  tolcombo.ItemIndex := 0;
  igCombo.ItemIndex  := _houtnap-1;
  Activecontrol := idszokegomb;

end;

// =============================================================================
            procedure TIdoszakBeForm.AParancs(_ukaz: string);
// =============================================================================

begin
  Adbase.Connected := True;
  if Atranz.InTransaction then Atranz.commit;
  Atranz.StartTransaction;
  with Aquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Atranz.commit;
  Adbase.close;
end;


// =============================================================================
          procedure TIdoszakBeForm.IdszOkeGombClick(Sender: TObject);
// =============================================================================

var _hos: string;
    _tolindex,_igindex: integer;

begin
  _tolindex := tolcombo.itemindex;
  _igIndex  := igCombo.ItemIndex;

  _kertev   := (_aktev-2)+ evcombo.itemindex;
  _kertho   := Hocombo.Itemindex + 1;

  _tols     := tolcombo.items[_tolindex];
  _igs      := Igcombo.Items[_igindex];

  if length(_tols)=1 then _tols := '0'+_tols;
  if length(_igs)=1 then _igs := '0'+_igs;

  _hos := inttostr(_kertho);

  if length(_hos)=1 then _hos := '0' + _hos;

  _tolstring := inttostr(_kertev)+'.'+ _hos + '.' + _tols;
  _igstring  := leftstr(_tolstring,8)+_igs;

  _pcs := 'INSERT INTO IDOSZAK (STARTDATE,ENDDATE)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _tolstring + chr(39) + ',';
  _PCS := _PCS + chr(39) + _igstring + chr(39) + ')';
  AParancs(_pcs);

  ModalResult := 1;
end;

// =============================================================================
         procedure TIDOSZAKBEFORM.IDSZCANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
          procedure TIDOSZAKBEFORM.EVCOMBOChange(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _kertev  := (_aktev-2)+ evcombo.Itemindex;
  _kertho  := Hocombo.Itemindex + 1;
  _houtnap := DAysInAMonth(_kertev,_kertho);

  tolcombo.clear;
  Igcombo.Clear;

  for i := 1 to _houtnap do
    begin
      tolcombo.Items.add(inttostr(i));
      igcombo.Items.Add(inttostr(i));
    end;
  Tolcombo.Itemindex := 0;
  Igcombo.ItemIndex := _houtnap-1;
  ActiveControl := IdszOkeGomb;
end;

// =============================================================================
           procedure TIDOSZAKBEFORM.TOLCOMBOChange(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _tolnap := tolcombo.itemindex +1;
  igcombo.Clear;
  for i := _tolnap to _houtnap do IgCombo.Items.add(inttostr(i));
  Igcombo.ItemIndex := 0;
  ActiveControl := IdszOkeGomb;
end;

// =============================================================================
           procedure TIDOSZAKBEFORM.IGCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := IdszokeGomb;
end;



end.
