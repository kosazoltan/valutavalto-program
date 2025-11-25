unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, dateUtils, strutils, wininet,
  Printers,idGlobal, IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TATADOLAPFORM = class(TForm)
    ERTEKTARPANEL: TPanel;
    Label16: TLabel;
    Label17: TLabel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel27: TPanel;
    Panel31: TPanel;
    Panel35: TPanel;
    Panel39: TPanel;
    Panel43: TPanel;
    Panel50: TPanel;
    Panel54: TPanel;
    Panel55: TPanel;
    ETOKEGOMB: TBitBtn;
    ETMEGSEMGOMB: TBitBtn;
    Bevel17: TBevel;
    Bevel18: TBevel;
    ETATADPANEL: TPanel;
    ETSZAMEDIT: TEdit;
    Label8: TLabel;
    ETADVETDATUMEDIT: TEdit;
    ETATADOEDIT: TEdit;
    ETATVEVOEDIT: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    PENZKESZLETPANEL: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    EGYEZIKEDIT: TEdit;
    NEMEGYEZIKEDIT: TEdit;
    ELTERESEDIT: TEdit;
    TARTOZASOKPANEL: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel21: TPanel;
    TARTETSZAM1EDIT: TEdit;
    TARTETSZAM2EDIT: TEdit;
    TARTETSZAM3EDIT: TEdit;
    TARTDNEM1EDIT: TEdit;
    TARTDNEM2EDIT: TEdit;
    TARTDNEM3EDIT: TEdit;
    TARTSUM1EDIT: TEdit;
    TARTSUM2EDIT: TEdit;
    TARTSUM3EDIT: TEdit;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    KOVETELESPANEL: TPanel;
    Panel13: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    KOVERTSZAM1EDIT: TEdit;
    KOVERTSZAM2EDIT: TEdit;
    KOVERTSZAM3EDIT: TEdit;
    KOVDNEM1EDIT: TEdit;
    KOVDNEM2EDIT: TEdit;
    KOVDNEM3EDIT: TEdit;
    KOVSUM1EDIT: TEdit;
    KOVSUM2EDIT: TEdit;
    KOVSUM3EDIT: TEdit;
    Label15: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    WUAFAPANEL: TPanel;
    Panel25: TPanel;
    Panel26: TPanel;
    Panel28: TPanel;
    WUDATUM1EDIT: TEdit;
    WUDATUM2EDIT: TEdit;
    WUDNEM1EDIT: TEdit;
    WUSUM1EDIT: TEdit;
    WUDNEM2EDIT: TEdit;
    WUSUM2EDIT: TEdit;
    Label21: TLabel;
    Label22: TLabel;
    BANKIBEPANEL: TPanel;
    Panel24: TPanel;
    Panel29: TPanel;
    Panel30: TPanel;
    Panel32: TPanel;
    BBEDATUM1EDIT: TEdit;
    BBEDATUM2EDIT: TEdit;
    BBEDATUM3EDIT: TEdit;
    BBEDATUM4EDIT: TEdit;
    BBEDNEM1EDIT: TEdit;
    BBESUM1EDIT: TEdit;
    BBEARF1EDIT: TEdit;
    BBEDNEM2EDIT: TEdit;
    BBEDNEM3EDIT: TEdit;
    BBEDNEM4EDIT: TEdit;
    BBESUM2EDIT: TEdit;
    BBESUM3EDIT: TEdit;
    BBESUM4EDIT: TEdit;
    BBEARF2EDIT: TEdit;
    BBEARF3EDIT: TEdit;
    BBEARF4EDIT: TEdit;
    Label23: TLabel;
    Label24: TLabel;
    BANKIKIPANEL: TPanel;
    Panel33: TPanel;
    Panel34: TPanel;
    Panel36: TPanel;
    BKIDATUM1EDIT: TEdit;
    BKIDNEM1EDIT: TEdit;
    BKISUM1EDIT: TEdit;
    BKIDATUM2EDIT: TEdit;
    BKIDATUM3EDIT: TEdit;
    BKIDATUM4EDIT: TEdit;
    BKIDNEM2EDIT: TEdit;
    BKIDNEM3EDIT: TEdit;
    BKIDNEM4EDIT: TEdit;
    BKISUM2EDIT: TEdit;
    BKISUM3EDIT: TEdit;
    BKISUM4EDIT: TEdit;
    Label25: TLabel;
    Label26: TLabel;
    PENZTARIRENDELESPANEL: TPanel;
    Panel38: TPanel;
    RENDDATUM1EDIT: TEdit;
    RENDDATUM2EDIT: TEdit;
    RENDDATUM3EDIT: TEdit;
    RENDDATUM4EDIT: TEdit;
    Panel40: TPanel;
    Panel41: TPanel;
    Panel42: TPanel;
    Panel44: TPanel;
    RENDPT1EDIT: TEdit;
    RENDPT2EDIT: TEdit;
    RENDPT3EDIT: TEdit;
    RENDPT4EDIT: TEdit;
    RENDDNEM1EDIT: TEdit;
    RENDDNEM2EDIT: TEdit;
    RENDDNEM3EDIT: TEdit;
    RENDDNEM4EDIT: TEdit;
    RENDSUM1EDIT: TEdit;
    RENDSUM2EDIT: TEdit;
    RENDSUM3EDIT: TEdit;
    RENDSUM4EDIT: TEdit;
    RENDARF1EDIT: TEdit;
    RENDARF2EDIT: TEdit;
    RENDARF3EDIT: TEdit;
    RENDARF4EDIT: TEdit;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    ETKORLEVELPANEL: TPanel;
    Panel45: TPanel;
    Panel46: TPanel;
    Panel47: TPanel;
    KORDATUM1EDIT: TEdit;
    KORDATUM2EDIT: TEdit;
    KORDATUM3EDIT: TEdit;
    KORDATUM4EDIT: TEdit;
    IKTATO1EDIT: TEdit;
    IKTATO2EDIT: TEdit;
    IKTATO3EDIT: TEdit;
    IKTATO4EDIT: TEdit;
    TARGY1EDIT: TEdit;
    TARGY2EDIT: TEdit;
    TARGY3EDIT: TEdit;
    TARGY4EDIT: TEdit;
    EGYEBINFOPANEL: TPanel;
    ETINFO1EDIT: TEdit;
    ETINFO2EDIT: TEdit;
    Label31: TLabel;
    Label32: TLabel;
    PrintDialog1: TPrintDialog;
    MENUPANEL: TPanel;
    Shape2: TShape;
    KITOLTOGOMB: TBitBtn;
    LETOLTOGOMB: TBitBtn;
    KILEPESGOMB: TBitBtn;
    INDITO: TTimer;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;
    takaro: TPanel;
    BACKGOMB: TBitBtn;
    skiccpanel: TPanel;
    BitBtn1: TBitBtn;

    procedure TombBetolto;
    function Elokieg(_szo: string;_hh: integer):string;
    procedure FormActivate(Sender: TObject);
    procedure Dekodolas;
    procedure EtAdatfeliro;
    procedure EtDataKijelzo;
    procedure Puttext(_s: string);
    procedure ETSZAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ETOKEGOMBClick(Sender: TObject);
    function GetLapfilenev: string;
    function Nulele(_int: integer):string;

    procedure GetAlapaDAT;
  


    procedure KITOLTOGOMBClick(Sender: TObject);
    procedure KILEPESGOMBClick(Sender: TObject);
  
    procedure INDITOTimer(Sender: TObject);
 
    procedure EDITEnter(Sender: TObject);
    procedure EDITExit(Sender: TObject);

    procedure AllFilesErase;
    function Gettext: string;
    procedure ETMEGSEMGOMBClick(Sender: TObject);
    procedure LETOLTOGOMBClick(Sender: TObject);
    procedure BACKGOMBClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATADOLAPFORM: TATADOLAPFORM;

  _atadoDir   : string = 'c:\ertektar\atadolap';
  _archiveDir : string = 'c:\ertektar\atadolap\archive';
  _bytetomb   : array[1..4096] of byte;
  _etEdit     : array[1..93] of TEdit;
  _etData     : array[1..93] of string;
  _etPanel    : array[1..10] of TPanel;

  _LF5        : string  = #27#97#5;   // 5 sor emelés

  _aktEdit    : TEdit;
  
  _printer,_ertektar,_akteditSorszam,_ptkod: byte;
  
  _sorveg            : string = chr(13) + chr(10);
  _megnyitottnap     : string;
  _aktstring,_ptkods : string;
  _pp                : word;

  _olvas,_iras       : File of Byte;

  _height,_width,_left,_top: word;

   // -----------------------------------------------------

  _nyomtato : textFile;
  _code: integer;

  _LFile: textFile;


function atadolaprutin: integer; stdcall;


implementation

{$R *.dfm}


// =============================================================================
              function atadolaprutin: integer; stdcall;
// =============================================================================//

begin
  atadolapform := TAtadolapForm.Create(Nil);
  result := atadolapForm.showmodal;
  AtadolapForm.Free;
end;

// =============================================================================
              procedure TATADOLAPFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := 0;
  _left := 0;

  if (_height>768) or (_width>1024) then
    begin
      _top  := trunc((_height-768)/2);
      _left := trunc((_width-810)/2);
    end;

  Top    := _top;
  Left   := _Left;
  Height := 768;
  Width  := 810;

  Ertektarpanel.Visible := False;

  if not DirectoryExists(_atadodir) then Createdir(_atadodir);
  if not DirectoryExists(_archiveDir) then CreateDir(_archiveDir);
  Indito.Enabled := True;
end;


// =============================================================================
            procedure TATADOLAPFORM.INDITOTimer(Sender: TObject);
// =============================================================================

begin
  indito.Enabled := False;
  GetAlapadat;
  TombBetolto;
end;


// =============================================================================
                    procedure TAtadolapForm.GetAlapadat;
// =============================================================================

begin
  Valdbase.Connected := true;
  with Valquery do
    begin
      close;
      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _ptKods := trim(FieldByNAme('PENZTARKOD').AsString);

      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldbyName('MEGNYITOTTNAP').asstring;
      _printer := FieldByNAme('PRINTER').asInteger;
      Close;

    end;
  Valdbase.close;

  Val(_ptkods,_ptkod,_code);

end;




// =============================================================================
          procedure TATADOLAPFORM.KitoltoGombClick(Sender: TObject);
// =============================================================================

var _z: byte;

begin

  _z := 1;
  while _z<=93 do
    begin
      _etedit[_z].Clear;
      inc(_z);
    end;

  Takaro.visible := False;
  with ErtektarPanel do
    begin
      Top := 0;
      Left := 0;
      Visible := true;
      repaint;
    end;

  EtSzamEdit.Text       := inttostr(_ptkod);
  EtAdvetDatumEdit.Text := _megnyitottnap;
  Activecontrol         := etAtadoEdit;

end;

// =============================================================================
           procedure TATADOLAPFORM.EDITEnter(Sender: TObject);
// =============================================================================

begin
   _aktEdit        := TEdit(sender);
   _aktEditSorszam := _aktEdit.Tag;
   _aktEdit.Color  := clYellow;
end;

// =============================================================================
              procedure TATADOLAPFORM.EDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clWhite;
end;


// =============================================================================
    procedure TATADOLAPFORM.ETSZAMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var
    _bill: byte;
    _aktedit: TEdit;

begin

  _bill := ord(key);
  if _bill<>13 then exit;

  _aktedit        := TEdit(sender);
  _akteditSorszam := _aktedit.Tag;

  // ----------- ENTER ---------------------

  if _akteditsorszam>92 then
    begin
      Activecontrol := EtOkeGomb;
      Exit;
    end;

  inc(_akteditSorszam);
  _aktedit := _etEdit[_akteditsorszam];

  ActiveControl := _aktEdit;
end;

// =============================================================================
               procedure TATADOLAPFORM.ETOkeGombClick(Sender: TObject);
// =============================================================================

begin
  EtadatFeliro;
  ErtektarPanel.Visible := False;
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            procedure TATADOLAPFORM.LETOLTOGOMBClick(Sender: TObject);
// =============================================================================


var _minta,_aktfile,_aktPath: string;
    _byteDarab,_zz: word;
    _srec: TSearchRec;

begin
  _minta := 'c:\ertektar\atadolap\pp*.dat';
  if FindFirst(_minta, faAnyFile, _srec) <> 0 then
    begin
      ShowMessage('NINCS RÖGZITETT ÜZENET');
      exit;
    end;

  _aktFile := _srec.Name;
  _aktPath := 'c:\ertektar\atadolap\'+_aktfile;

  FindClose(_srec);

  AssignFile(_olvas,_aktpath);
  reset(_olvas);
  _bytedarab := filesize(_olvas);
  blockread(_olvas,_bytetomb,_byteDarab);
  CloseFile(_olvas);

  // -*---------------------------------------------

  Dekodolas;
  _zz := 1;
  while _zz<=93 do
    begin
      _aktedit := _etEdit[_zz];
      _aktedit.Text := _etData[_zz];
      inc(_zz);
    end;
  Takaro.Visible := true;
  takaro.repaint;
  with Ertektarpanel do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
      repaint;
    end;
end;




// =============================================================================
                           procedure TATADOLAPFORM.AllFilesErase;
// =============================================================================

var _delFile,_delPath,_minta: string;
    _srec: TSearchRec;

begin
  _minta := 'c:\ertektar\atadolap\pp*.dat';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _delFile := _srec.Name;
        _delPath := 'c:\ertektar\atadolap\'+_delfile;
        Sysutils.deleteFile(_delPath);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;



// =============================================================================
                     procedure TATADOLAPFORM.EtDataKijelzo;
// =============================================================================


var _zz     : byte;
    _aktEdit: TEdit;

begin
  _zz := 1;
  while _zz<=93 do
    begin
      _aktEdit      := _etedit[_zz];
      _aktString    := _etData[_zz];
      _aktedit.Text := _aktString;

      _aktedit.Repaint;

      inc(_zz);
    end;
end;


// =============================================================================
                function TAtadolapForm.GetLapfilenev: string;
// =============================================================================

var _MN: string;

begin
  _mn := _megnyitottnap;
  result := 'PP' + midstr(_mn,3,2)+midstr(_mn,6,2)+midstr(_mn,9,2)+'.DAT';
end;


// =============================================================================
        function TatadoLapForm.Elokieg(_szo: string;_hh: integer):string;
// =============================================================================


begin
  result := trim(_szo);
  while length(result)<>_hh do result := '0' + result;
end;


// =============================================================================
           function TAtadoLapform.Nulele(_int: integer):string;
// =============================================================================


begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


// =============================================================================
          procedure TATADOLAPFORM.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
                      procedure TATADOLAPFORM.TombBetolto;
// =============================================================================

begin

  _etPanel[1] := etAtadPanel;
  _etPanel[2] := penzKeszletPanel;
  _etPanel[3] := tartozasokPanel;
  _etPanel[4] := kovetelesPanel;
  _etPanel[5] := wuafaPanel;
  _etPanel[6] := bankibepanel;
  _etPanel[7] := bankikipanel;
  _etPanel[8] := penztarirendelesPanel;
  _etPanel[9] := etkorlevelpanel;
  _etPanel[10]:= egyebinfopanel;

  // ------------------------------------------

  _etEdit[1] := etszamedit;
  _etEdit[2] := etAdvetDatumEdit;
  _etEdit[3] := etAtadoEdit;
  _etEdit[4] := etAtvevoEdit;

  // -------------------------------------------

  _etEdit[5] := egyezikEdit;
  _etEdit[6] := nemEgyezikEdit;
  _etEdit[7] := elteresEdit;

  // --------------------------------------------

  _etEdit[8] := tartetszam1edit;
  _etEdit[9] := tartdnem1edit;
  _etEdit[10]:= tartsum1edit;

  _etEdit[11]:= tartetszam2Edit;
  _etEdit[12]:= tartDnem2Edit;
  _etEdit[13]:= tartSum2Edit;

  _etEdit[14]:= tartEtSzam3Edit;
  _etEdit[15]:= tartDnem3Edit;
  _etEdit[16]:= tartSum3Edit;

  // ----------------------------------------------

  _etEdit[17]:= kovertszam1Edit;
  _etEdit[18]:= kovdnem1edit;
  _etEdit[19]:= kovSum1Edit;

  _etEdit[20]:= kovertszam2Edit;
  _etEdit[21]:= kovDnem2Edit;
  _etEdit[22]:= kovSum2Edit;

  _etEdit[23]:= kovertSzam3Edit;
  _etEdit[24]:= kovDnem3Edit;
  _etEdit[25]:= kovSum3Edit;

  // ----------------------------------------------

  _etEdit[26]:= wuDatum1Edit;
  _etEdit[27]:= wuDnem1Edit;
  _etEdit[28]:= wuSum1edit;

  _etEdit[29]:= wuDatum2Edit;
  _etEdit[30]:= wuDnem2Edit;
  _etEdit[31]:= wuSum2Edit;

  // ----------------------------------------------

   _etEdit[32]:= bbeDatum1Edit;
   _etEdit[33]:= bbeDnem1Edit;
   _etEdit[34]:= bbeSum1Edit;
   _etEdit[35]:= bbeArf1Edit;

   _etEdit[36]:= bbeDatum2Edit;
   _etEdit[37]:= bbeDnem2Edit;
   _etEdit[38]:= bbeSum2Edit;
   _etEdit[39]:= bbeArf2Edit;

   _etEdit[40]:= bbeDatum3Edit;
   _etEdit[41]:= bbeDnem3Edit;
   _etEdit[42]:= bbesum3Edit;
   _etEdit[43]:= bbeArf3Edit;

   _etEdit[44]:= bbeDatum4Edit;
   _etEdit[45]:= bbeDnem4Edit;
   _etEdit[46]:= bbeSum4Edit;
   _etEdit[47]:= bbeArf4Edit;

   // ------------------------------------------------

   _etEdit[48]:= bkiDatum1Edit;
   _etEdit[49]:= bkiDnem1Edit;
   _etEdit[50]:= bkiSum1Edit;

   _etEdit[51]:= bkiDatum2Edit;
   _etEdit[52]:= bkiDnem2Edit;
   _etEdit[53]:= bkiSum2Edit;

   _etEdit[54]:= bkiDatum3Edit;
   _etEdit[55]:= bkiDnem3Edit;
   _etEdit[56]:= bkiSum3Edit;

   _etEdit[57]:= bkiDatum4Edit;
   _etEdit[58]:= bkiDnem4Edit;
   _etEdit[59]:= bkiSum4Edit;

   // ------------------------------------------------

   _etEdit[60]:= Renddatum1Edit;
   _etEdit[61]:= Rendpt1edit;
   _etEdit[62]:= RendDnem1Edit;
   _etEdit[63]:= RendSum1Edit;
   _etEdit[64]:= RendArf1Edit;

   _etEdit[65]:= RendDatum2Edit;
   _etEdit[66]:= RendPt2Edit;
   _etEdit[67]:= RendDnem2Edit;
   _etEdit[68]:= RendSum2Edit;
   _etEdit[69]:= RendArf2Edit;

   _etEdit[70]:= RendDatum3Edit;
   _etEdit[71]:= RendPt3Edit;
   _etEdit[72]:= RendDnem3Edit;
   _etEdit[73]:= RendSum3Edit;
   _etEdit[74]:= RendPt3Edit;

   _etEdit[75]:= RendDatum4Edit;
   _etEdit[76]:= RendPt4Edit;
   _etEdit[77]:= RendDnem4Edit;
   _etEdit[78]:= RendSum4Edit;
   _etEdit[79]:= RendPt4Edit;

   // ----------------------------------------

   _etEdit[80]:= KorDatum1Edit;
   _etEdit[81]:= Iktato1Edit;
   _etEdit[82]:= Targy1Edit;

   _etEdit[83]:= KorDatum2Edit;
   _etEdit[84]:= Iktato2Edit;
   _etEdit[85]:= Targy2Edit;

   _etEdit[86]:= KorDatum3Edit;
   _etEdit[87]:= Iktato3Edit;
   _etEdit[88]:= Targy3Edit;

   _etEdit[89]:= KorDatum4Edit;
   _etEdit[90]:= Iktato4Edit;
   _etEdit[91]:= Targy4Edit;

   _etEdit[92]:= EtInfo1Edit;
   _etEdit[93]:= EtInfo2Edit;
end;

// =============================================================================
                   procedure TATADOLAPFORM.Dekodolas;
// =============================================================================

var _z: byte;

begin
  _pp := 0;
  _z := 1;
  while _z<=93 do
    begin
      _etData[_z] := GetText;
      inc(_z);
    end;
end;


// =============================================================================
                 function TatadoLapForm.Gettext: string;
// =============================================================================

var _len,_z,_byte,_asc: byte;

begin
  result := '';

  inc(_pp);
  _len := _bytetomb[_pp];
  if _len=0 then exit;

  _z := 1;
  while _z<=_len do
    begin
      inc(_pp);
      _byte := _bytetomb[_pp];
      _asc := 255-_byte;
      result := result + chr(_asc);
      inc(_z);
    end;
end;

// =============================================================================
               procedure TAtadolapForm.Puttext(_s: string);
// =============================================================================

var _asc,_byte,_len,_z: byte;

begin
  _s := trim(_s);
  inc(_pp);
  _len := length(_s);
  _bytetomb[_pp] := _len;
  if _len=0 then exit;

  _z := 1;
  while _z<=_len do
    begin
      _asc := ord(_s[_z]);
      _byte := 255-_asc;
      inc(_pp);
      _bytetomb[_pp] := _byte;
      inc(_z);
    end;
end;

// =============================================================================
                        procedure TATADOLAPFORM.EtAdatFeliro;
// =============================================================================

var _zz: byte;
    _byteDarab: word;
    _tranzLapnev,_atadoPath: string;

begin
  _pp := 0;
  _zz := 1;
  while _zz<=93 do
    begin
      _aktedit := _etEdit[_zz];
      _aktstring := _aktedit.text;
      PutText(_aktstring);
      inc(_zz);
    end;

  inc(_pp);
  _bytetomb[_pp] := 255;

  inc(_pp);
  _bytetomb[_pp] := 255;

  inc(_pp);
  _bytetomb[_pp] := 255;

  _bytedarab := _pp;

  AllFilesErase;

  _tranzLapnev := GetLapFileNev;
  _atadoPath := _atadodir + '\' + _tranzlapnev;

  AssignFile(_iras,_atadoPath);
  Rewrite(_iras);
  Blockwrite(_iras,_bytetomb,_byteDarab);
  CloseFile(_iras);

  ShowMessage('Atadólap rögzítve');

end;

procedure TATADOLAPFORM.ETMEGSEMGOMBClick(Sender: TObject);
begin
  ErtektarPanel.Visible := False;
end;


procedure TATADOLAPFORM.BACKGOMBClick(Sender: TObject);
begin
   ErtektarPanel.Visible := False;
 
end;


procedure TATADOLAPFORM.BitBtn1Click(Sender: TObject);
begin
  IF PRINTdIALOG1.Execute then Print;
end;

end.
