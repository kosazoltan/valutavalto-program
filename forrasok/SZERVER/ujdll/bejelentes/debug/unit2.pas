unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, idglobal;

type
  TForm2 = class(TForm)
    CONFILISTPANEL: TPanel;
    Label1: TLabel;
    BEJELENTESLISTA: TListBox;
    KILEPO: TTimer;
    BitBtn1: TBitBtn;
    Label2: TLabel;
    Memo1: TMemo;
    Label3: TLabel;
    BitBtn2: TBitBtn;

    
    procedure FormActivate(Sender: TObject);
    procedure Memoclearing;

    function Confikereso: integer;
    procedure KilepoTimer(Sender: TObject);
    procedure BejelentesListaDblClick(Sender: TObject);
    function BejelentesDekodolo: String;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _sRec: TSearchrec;

  _bytetomb: array[1..4096] of byte;
  _confi: array[0..255] of string;
  _olvas: FILE of byte;

  _ascm_sor,_sordb,_sorlen,_asc: byte;
  _q,_listindex: integer;
  _bejelentesdb,_y,_meret,_bb,_pp: word;
  _minta,_aktconfifile,_aktconfiPath,_kodfile,_dekodfile,_kodstr: string;
  _source,_target: string;

  _sorveg: string = chr(13)+chr(10);
  _siker: boolean;

implementation

{$R *.dfm}

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _bejelentesdb := ConfiKereso;
  if _bejelentesdb=0 then
    begin
      ShowMessage('NEM ÉRKEZETT ÚJABB BEKEÉENTÉS');
      Kilepo.Enabled := True;
      Exit;
    end;

  BejelentesLista.Items.Clear;
  BejelentesLista.clear;

  Memo1.Lines.Clear;
  Memo1.Clear;

  _y := 0;
  while _y<_bejelentesDb do
    begin
      BejelentesLista.Items.Add(_confi[_y]);
      inc(_y);
    end;
  BejelentesLista.itemindex := 0;
  ConfilistPanel.Visible := True;
  Activecontrol := ConfilistPanel;
end;

// =============================================================================
                 function TForm2.Confikereso: integer;
// =============================================================================

var _q: integer;
    _srec: Tsearchrec;
    _minta: string;

begin
  _q := 0;
  _minta := 'c:\receptor\mail\conf\conf*.cof';
   if FindFirst(_minta, faAnyfile,_srec) = 0 then
    begin
      repeat
        _confi[_q] := _srec.Name;
        inc(_q);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
  result := _q;
end;

// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;

// =============================================================================
            procedure TForm2.BEJELENTESLISTADblClick(Sender: TObject);
// =============================================================================

begin
  _ListIndex := BejelentesLista.itemindex;
  _aktconfifile := _confi[_listIndex];
  _aktConfiPath := 'c:\receptor\mail\conf\' + _aktConfiFile;

  MemoClearing;

  AssignFile(_olvas,_aktCOnfiPath);
  reset(_olvas);
  _meret := filesize(_olvas);
  Blockread(_olvas,_bytetomb,_meret);
  Closefile(_olvas);

  _dekodfile := BejelentesDekodolo;
  Memo1.Lines.Add(_dekodfile);

end;

// =============================================================================
          function TForm2.BejelentesDekodolo: String;
// =============================================================================

var _sordb,_sor,_betu,_sorlen:byte;

begin
  result := '';
  _sordb := 255 - _bytetomb[1];
  _pp := 8;
  _sor := 1;
  while _sor<=_sordb do
    begin
      _sorlen := _bytetomb[_pp];
      _bb := 1;
      inc(_pp);

      while _bb<=_sorlen do
        begin
          _betu := 255-_bytetomb[_pp];
          result := result + chr(_betu);
          inc(_pp);
          inc(_bb);
        end;

      result := result + _sorveg;
      inc(_sor);
    end;
  _bb := _bytetomb[_pp];
  _bb := _bb+_bytetomb[_pp+1];
  _bb := _bb+_bytetomb[_pp+2];
  if _BB<>765 then
    begin
      result := 'HIBÁS KÓDOLÁSÚ ÜZENET';
      EXIT;
    end;
end;

// =============================================================================
                     procedure TForm2.MemoClearing;
// =============================================================================

begin
  Memo1.lines.clear;
  Memo1.Clear;
end;

// =============================================================================
           procedure TForm2.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
                 procedure TForm2.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  _source := _aktConfiPath;
  _target := 'c:\receptor\mail\conf\archive\' + _aktConfiFile;
  _siker  := copyfileto(_source,_target);

  if _siker then
    begin
      SysUtils.DeleteFile(_source);
      MemoClearing;
      _bejelentesdb := ConfiKereso;
      if _bejelentesdb=0 then
        begin
          ShowMessage('NINCS TÖBB BEJELENTÉS');
          Kilepo.Enabled := True;
          Exit;
        end;

      BejelentesLista.Items.Clear;
      BejelentesLista.clear;

      MemoClearing;

      _y := 0;
      while _y<_bejelentesDb do
        begin
          BejelentesLista.Items.Add(_confi[_y]);
          inc(_y);
        end;

      BejelentesLista.itemindex := 0;
      ConfilistPanel.Visible := True;
      Activecontrol := ConfilistPanel;
    end;
end;


end.
