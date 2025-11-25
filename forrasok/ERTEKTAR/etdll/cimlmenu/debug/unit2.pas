unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, Buttons;

type
  TCimletMenu = class(TForm)
    KilepGomb   : TButton;

    AxaQuery    : TIBQuery;
    AxaDbase    : TIBDatabase;
    AxaTranz    : TIBTransaction;

    eQuery      : TIBQuery;
    eDbase      : TIBDatabase;
    eTranz      : TIBTransaction;

    ValQuery    : TIBQuery;
    ValDbasE    : TIBDatabase;
    ValTranz    : TIBTransaction;

    Label1      : TLabel;

    AfaGomb     : TBitBtn;
    ETradeGomb  : TBitBtn;
    KezdijGomb  : TBitBtn;
    PTZarGomb   : TBitBtn;
    QuitGomb    : TBitBtn;
    WuGomb      : TBitBtn;

    Shape1      : TShape;

    procedure Cimletparancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure HardwareBeolvasas;
    procedure KilepGombClick(Sender: TObject);
    procedure PtZarGombClick(Sender: TObject);
    procedure QuitGombClick(Sender: TObject);

  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CimletMenu: TCimletMenu;

  _sorveg: string = chr(13)+ chr(10);


  _xx,_cimlettype: byte;
  _height,_width,_top,_left,_aktcimlet: word;
  _megnyitottnap,_aktdnem,_aktdnev,_pcs: string;


function cimletctrlrutin: integer; stdcall; external 'c:\ertektar\bin\cimlctrl.dll' name 'cimletctrlrutin';
function cimletezorutin:integer;stdcall; external 'c:\ertektar\bin\cimlet.dll' name 'cimletezorutin';
function cimletmenurutin: integer; stdcall;

implementation



{$R *.dfm}

// ============================================================================
                function cimletmenurutin: integer; stdcall;
// ============================================================================

begin
  CimletMenu := TCimletmenu.Create(Nil);
  result     := Cimletmenu.showmodal;
  Cimletmenu.Free;
end;

// =============================================================================
              procedure TCimletMenu.FormActivate(Sender: TObject);
// =============================================================================

begin

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  Top     := trunc((_height-390)/2);
  Left    := trunc((_width-550)/2);

  Hardwarebeolvasas;


end;

// =============================================================================
                   procedure TCimletMenu.HardwareBeolvasas;
// =============================================================================

begin
  valdbase.connected := true;
  with valquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := Trim(FieldByName('MEGNYITOTTNAP').AsString);

      Close;
    end;
  Valdbase.close;
end;

// =============================================================================
              procedure TCimletMenu.PtZarGombClick(Sender: TObject);
// =============================================================================

var  _cimletoke: integer;

begin
  _cimletType := TBitbtn(sender).Tag;
  _pcs := 'UPDATE HARDWARE SET MENETSZAM=' + inttostr(_cimletType);
  CimletParancs(_pcs);

  _cimletOke := cimletctrlrutin;
  if _cimletoke=3 then
    begin
      Showmessage('NINCS CIMLETEZENDÕ VALUTA');
      ModalResult := 1;
      exit;
    end;

  _cimletoke := cimletezorutin;
  ModalResult:= _CIMLETOKE;
end;



// =============================================================================
             procedure TCimletMenu.Cimletparancs(_ukaz: string);
// =============================================================================

begin
  valdbase.Connected := true;
  if valtranz.InTransaction then valtranz.Commit;
  valtranz.StartTransaction;
  with valquery do
    begin
      Close;
      sql.Clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  valtranz.Commit;
  valdbase.close;
end;


// =============================================================================
             procedure TCimletMenu.KILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult :=1;
end;


// =============================================================================
               procedure TCimletMenu.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

end.
