unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Registry;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _korlexepath,_aktdir: string;
  _sikeres: boolean;

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);

var _reg: Tregistry;
    _key: string;

begin
  _aktdir := getcurrentdir;
  _korlexePath := _aktdir + '\KORLEVEL.EXE';

  _reg := TRegistry.Create(KEY_WRITE);
  _key := '\Software\Microsoft\Windows\CurrentVersion\Run';

  _reg.RootKey := HKEY_LOCAL_MACHINE;
  _sikeres := False;

  TRY
    if _reg.OpenKey(_key,False) then
      begin
        _reg.writeString('KORLEVEL',_korlExePath+' 1');
        _reg.CloseKey;
      end;
    _sikeres := true;
  FINALLY
    _reg.Free;
  END;

 if _sikeres then ShowMessage('A KÖRLEVÉL AUTOMATIKUSAN INDUL')
 else Showmessage('NEM SIKERÜLT AZ AUTOMATILUS INDITÁS BEÁLLÍTÁSA');

 application.Terminate;
end;

end.
