unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, jpeg, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)
    HUN1PANEL: TPanel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    GroupBox2: TGroupBox;
    Bevel19: TBevel;
    Bevel20: TBevel;
    Bevel21: TBevel;
    Bevel22: TBevel;
    Bevel23: TBevel;
    Bevel24: TBevel;
    Bevel25: TBevel;
    Bevel26: TBevel;
    Bevel27: TBevel;
    Bevel28: TBevel;
    Bevel29: TBevel;
    Bevel30: TBevel;
    Bevel31: TBevel;
    Bevel32: TBevel;
    Bevel33: TBevel;
    Bevel34: TBevel;
    Bevel35: TBevel;
    Bevel36: TBevel;
    Bevel37: TBevel;
    RH0: TRadioButton;
    RH1: TRadioButton;
    RH2: TRadioButton;
    RH3: TRadioButton;
    RH4: TRadioButton;
    RH5: TRadioButton;
    RH6: TRadioButton;
    RH7: TRadioButton;
    RH8: TRadioButton;
    HUNSTATUSZOKEGOMB: TBitBtn;
    Shape1: TShape;
    KUL1PANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    GroupBox1: TGroupBox;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel5: TBevel;
    Bevel6: TBevel;
    Bevel7: TBevel;
    Bevel8: TBevel;
    Bevel9: TBevel;
    Bevel10: TBevel;
    Bevel11: TBevel;
    Bevel12: TBevel;
    Bevel13: TBevel;
    Bevel14: TBevel;
    Bevel15: TBevel;
    Bevel16: TBevel;
    Bevel17: TBevel;
    Bevel18: TBevel;
    Bevel38: TBevel;
    rk0: TRadioButton;
    RK1: TRadioButton;
    RK2: TRadioButton;
    RK3: TRadioButton;
    RK4: TRadioButton;
    RK5: TRadioButton;
    RK6: TRadioButton;
    RK7: TRadioButton;
    RK8: TRadioButton;
    KULSTATUSZOKEGOMB: TBitBtn;
    Shape2: TShape;
    FOMENUPANEL: TPanel;
    Label16: TLabel;
    Image1: TImage;
    KULALCSOPORTPANEL: TPanel;
    HUNALCSOPORTPANEL: TPanel;
    ROKONPANEL: TPanel;
    feleseggomb: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    Label17: TLabel;
    ISMEROSPANEL: TPanel;
    Panel3: TPanel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Panel4: TPanel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Bevel39: TBevel;
    GroupBox3: TGroupBox;
    Bevel40: TBevel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Label39: TLabel;
    tovabbGOMB: TButton;
    KEZDOMENUPANEL: TPanel;
    NOOUTSTANDINGGOMB: TBitBtn;
    ITSOUTSTANDINGGOMB: TBitBtn;
    ITSRELATIVEGOMB: TBitBtn;
    ITSFRIENDGOMB: TBitBtn;
    
  
    procedure FormActivate(Sender: TObject);
    procedure NoOutstandingGombClick(Sender: TObject);
    procedure ItsOutstandingGombClick(Sender: TObject);
    procedure Rk0Click(Sender: TObject);
    procedure HunStatuszOkeGombClick(Sender: TObject);
    procedure FelesegGombClick(Sender: TObject);
    procedure ItsRelativeGombClick(Sender: TObject);
    procedure ItsFriendGombClick(Sender: TObject);
    procedure TovabbGombClick(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _height,_width,_top,_left: word;
  _kulfoldi,_alcsoport,_csoport,_mResult: integer;
  _alcsopneV: string;


function getkiemeltstatusz: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
             function getkiemeltstatusz: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.Free;
end;

// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Hun1Panel.visible    := False;
  Kul1Panel.Visible    := False;
  RokonPanel.Visible   := False;
  IsmerosPanel.Visible := False;

  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;
  _top    := round((_height-700)/2);
  _left   := round((_width-575)/2);

  Top     := _top;
  Left    := _left;

  _kulfoldi  := 1;
  _alcsoport := 0;
  _alcsopnev := '';
  _csoport   := -1;
  _mResult   := 0;

  with KezdoMenuPanel do
    begin
      Top := 104;
      Left := 48;
      Visible := true;
      Repaint;
    end;

  Activecontrol := NoOutstandingGomb;
end;

// =============================================================================
           procedure TForm2.NoOutstandingGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
          procedure TForm2.ItsOutstandingGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  kezdomenupanel.Visible := false;

  if _kulfoldi=1 then
    begin
      KulAlcsoportPanel.Caption := _alcsopnev;
      KulAlcsoportPanel.repaint;
      with Kul1Panel do
        begin
          top := 0;
          left := 0;
          Visible := True;
        end;
    end else
    begin
      HunalcsoportPanel.Caption := _alcsopnev;
      KulalcsoportPanel.repaint;
      with Hun1Panel do
        begin
          Top := 0;
          Left := 0;
          Visible := True;
        end;
     end;
end;

// =============================================================================
                procedure TForm2.Rk0Click(Sender: TObject);
// =============================================================================

begin
   _csoport := TradioButton(sender).Tag;
end;

// =============================================================================
          procedure TForm2.HUNSTATUSZOKEGOMBClick(Sender: TObject);
// =============================================================================



begin
  if _csoport<1 then
    begin
      Modalresult := 1;
      exit;
    end;
  Hun1Panel.Visible := false;
  Kul1Panel.Visible := False;
  ModalResult := _csoport + _alcsoport;
end;

// =============================================================================
            procedure TForm2.feleseggombClick(Sender: TObject);
// =============================================================================

begin
  RokonPanel.visible := False;
  _alcsoport := TBitbtn(sender).Tag;
  ItsOutstandingGombClick(Nil);
end;

// =============================================================================
          procedure TForm2.ItsRelativeGombClick(Sender: TObject);
// =============================================================================

begin
  KezdomenuPanel.Visible := False;
  _alcsoport := 10;
  _alcsopnev := '(közeli hozzátartozója)';
  with RokonPanel do
    begin
      top := 104;
      left := 48;
      Visible := true;
      Repaint;
    end;
  Activecontrol := FelesegGomb;
end;

// =============================================================================
            procedure TForm2.ItsFriendGombClick(Sender: TObject);
// =============================================================================

begin
  Kezdomenupanel.visible := False;
  _alcsoport := 6;
  _alcsopnev := '(hozzá közel álló személy)';
  with IsmerosPanel do
    begin
      top     := 104;
      left    := 48;
      Visible := true;
      Repaint;
    end;
  ActiveControl := Tovabbgomb;
end;

// =============================================================================
           procedure TForm2.TovabbGombClick(Sender: TObject);
// =============================================================================

begin
  IsmerosPanel.Visible := False;
  ItsOutstandingGombClick(NIL);
end;

// =============================================================================
           procedure TForm2.RadioButton2Click(Sender: TObject);
// =============================================================================

begin
  _alcsoport := TRadioButton(sender).Tag;
end;


end.
