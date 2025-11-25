unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1, dateUtils, strutils, wininet,
  Printers,idGlobal, IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TATADOLAPFORM = class(TForm)
    PENZTARPANEL: TPanel;
    Label1: TLabel;
    PTSZAMEDIT: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    PTATADOEDIT: TEdit;
    PTATVEVOEDIT: TEdit;
    Label5: TLabel;
    PTADVETDATUMEDIT: TEdit;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel12: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    PTOKEGOMB: TBitBtn;
    PTMEGSEMGOMB: TBitBtn;
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
    atadpanel: TPanel;
    KORLEVELPANEL: TPanel;
    Panel57: TPanel;
    Panel58: TPanel;
    Panel59: TPanel;
    PTKORDATUM1EDIT: TEdit;
    PTKORDATUM2EDIT: TEdit;
    PTKORDATUM3EDIT: TEdit;
    PTKORDATUM4EDIT: TEdit;
    PTKORDATUM5EDIT: TEdit;
    PTIKTATO1EDIT: TEdit;
    PTIKTATO2EDIT: TEdit;
    PTIKTATO3EDIT: TEdit;
    PTIKTATO4EDIT: TEdit;
    PTIKTATO5EDIT: TEdit;
    PTTARGY1EDIT: TEdit;
    PTTARGY2EDIT: TEdit;
    PTTARGY3EDIT: TEdit;
    PTTARGY4EDIT: TEdit;
    PTTARGY5EDIT: TEdit;
    UGYFRENDPANEL: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel56: TPanel;
    Panel60: TPanel;
    Panel61: TPanel;
    PTRENDDATUM1EDIT: TEdit;
    PTRENDDATUM2EDIT: TEdit;
    PTRENDDATUM3EDIT: TEdit;
    PTRENDDATUM4EDIT: TEdit;
    PTRENDDATUM5EDIT: TEdit;
    PTRENDDATUM6EDIT: TEdit;
    PTETROS1EDIT: TEdit;
    PTETROS2EDIT: TEdit;
    PTETROS3EDIT: TEdit;
    PTETROS4EDIT: TEdit;
    PTETROS5EDIT: TEdit;
    PTETROS6EDIT: TEdit;
    PTRENDDNEM1EDIT: TEdit;
    PTRENDDNEM2EDIT: TEdit;
    PTRENDDNEM3EDIT: TEdit;
    PTRENDDNEM4EDIT: TEdit;
    PTRENDDNEM5EDIT: TEdit;
    PTRENDDNEM6EDIT: TEdit;
    PTRENDSUM1EDIT: TEdit;
    PTRENDSUM2EDIT: TEdit;
    PTRENDSUM3EDIT: TEdit;
    PTRENDSUM4EDIT: TEdit;
    PTRENDSUM5EDIT: TEdit;
    PTRENDSUM6EDIT: TEdit;
    PTRENDUGYF1EDIT: TEdit;
    PTRENDUGYF2EDIT: TEdit;
    PTRENDUGYF3EDIT: TEdit;
    PTRENDUGYF4EDIT: TEdit;
    PTRENDUGYF5EDIT: TEdit;
    PTRENDUGYF6EDIT: TEdit;
    PTFON1EDIT: TEdit;
    PTFON2EDIT: TEdit;
    PTFON3EDIT: TEdit;
    PTFON4EDIT: TEdit;
    PTFON5EDIT: TEdit;
    PTFON6EDIT: TEdit;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    Label47: TLabel;
    Label48: TLabel;
    KESZRENDPANEL: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    KRENDDATUM1EDIT: TEdit;
    KRENDDATUM2EDIT: TEdit;
    KRENDDATUM3EDIT: TEdit;
    KRENDDATUM4EDIT: TEdit;
    KRENDDATUM5EDIT: TEdit;
    KRENDDATUM6EDIT: TEdit;
    KRENDDNEM1EDIT: TEdit;
    KRENDDNEM2EDIT: TEdit;
    KRENDDNEM3EDIT: TEdit;
    KRENDDNEM4EDIT: TEdit;
    KRENDDNEM5EDIT: TEdit;
    KRENDDNEM6EDIT: TEdit;
    KRENDSUM1EDIT: TEdit;
    KRENDSUM2EDIT: TEdit;
    KRENDSUM3EDIT: TEdit;
    KRENDSUM4EDIT: TEdit;
    KRENDSUM5EDIT: TEdit;
    KRENDSUM6EDIT: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    KONKURPANEL: TPanel;
    KONK1EDIT: TEdit;
    KONK2EDIT: TEdit;
    EGYEBPANEL: TPanel;
    EGYEB1EDIT: TEdit;
    EGYEB2EDIT: TEdit;
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
    NYOMTATOGOMB: TBitBtn;
    LETOLTOGOMB: TBitBtn;
    KILEPESGOMB: TBitBtn;
    FUGGONY: TPanel;
    SKICCPANEL: TPanel;
    GYUJTOPANEL: TPanel;
    Label33: TLabel;
    GYUJTOLIST: TListBox;
    KINYOMTATOGOMB: TBitBtn;
    BitBtn2: TBitBtn;
    MEMOPANEL: TPanel;
    MemoTabla: TMemo;
    Label34: TLabel;
    INDITO: TTimer;
    VALQUERY: TIBQuery;
    VALDBASE: TIBDatabase;
    VALTRANZ: TIBTransaction;

    procedure ptszamEDITEnter(Sender: TObject);
    procedure ptszamEDITExit(Sender: TObject);
    function Elokieg(_szo: string;_hh: integer):string;

    procedure PTEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AllPageErase;

    procedure FormActivate(Sender: TObject);
    procedure PanelEnter(Sender: TObject);
    procedure KovetkezoPtPanel;
    procedure KovetkezoPtEdit;
    procedure KovetkezoEtPanel;
    procedure KovetkezoEtEdit;
    procedure PTMEGSEMGOMBClick(Sender: TObject);
    procedure PTOKEGOMBClick(Sender: TObject);
    procedure Adatfeliro;
    procedure EtAdatfeliro;
    procedure PtDataKijelzo;
    procedure EtDataKijelzo;
    procedure PtDownLoad;
    procedure ErtekTarSkicc;
    procedure Penztarskicc;
    procedure StartNyomtatas;
    procedure FTPszerverbeBelep;

    function Getgepfunkcio: byte;
    function AdatBeolvaso: boolean;
    function Ftform(_instr: string):string;
    function EtAdatBeolvaso: boolean;
    procedure ETSZAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ETOKEGOMBClick(Sender: TObject);
    procedure ETATADPANELEnter(Sender: TObject);
    function EgyEtLapBeolvasasa(_fPath: string): boolean;
    function EgyPTLapBeolvasasa(_fpath:string): boolean;
    function Datumkodolo(_aktdatum: TDatetime):string;
    function GetLapfilenev(_lapdatum: TDateTime): string;
    function Arfform(_instr: string): string;

    function WordbolDatum(_word: word):string;
    function Nulele(_int: integer):string;
    procedure EtlapNyomtatas;
    function Forintform(_s: string): string;
    function Kieg(_s: string; _hh: byte): string;
    procedure TextKiiro;

    function LoadFromserver: integer;
    procedure KINYOMTATOGOMBClick(Sender: TObject);
    procedure AtadolapMenu;
    function StrtoHundate(_s: string): TDatetime;

    procedure KITOLTOGOMBClick(Sender: TObject);
    procedure KILEPESGOMBClick(Sender: TObject);
    procedure NYOMTATOGOMBClick(Sender: TObject);
    procedure LETOLTOGOMBClick(Sender: TObject);
    procedure GYUJTOLISTDblClick(Sender: TObject);
    procedure INDITOTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATADOLAPFORM: TATADOLAPFORM;

  _tranzLapNev: string;
  _atadoDir : string = 'c:\valuta\atadolap';
  _archiveDir: string = 'c:\valuta\atadolap\archive';

  _bytetomb: array[1..4096] of byte;


  _ptEdit : array[1..77] of TEdit;
  _ptPanel: array[1..6] of TPanel;
  _ptkezdoEdit: array[1..6] of integer = (1,5,20,56,74,76);
  _ptEditstatus: array[1..77] of integer = (3,3,3,2,
                1,0,0, 1,0,0, 1,0,0, 1,0,0, 1,0,2,
                1,0,0,0,0,0,  1,0,0,0,0,0,  1,0,0,0,0,0,
                1,0,0,0,0,0,  1,0,0,0,0,0,  1,0,0,0,0,2,
                1,0,0,  1,0,0,  1,0,0,  1,0,0,  1,0,0,
                1,0,2,  1,2, 1,2);
   _ptdata: array[1..77] of string;

    _LF5: string  = #27#97#5;   // 5 sor emelés

   // -----------------------------------------------------

   _etEdit : array[1..93] of TEdit;
   _etPanel: array[1..10] of TPanel;
   _etKezdoEdit: array[1..10] of integer = (1,5,8,17,26,32,
                                  48,60,80,92);
   _etEditStatus: array[1..93] of integer = (3,3,3,2,
                  1,0,2,
                  1,0,0, 1,0,0, 1,0,2,
                  1,0,0, 1,0,0, 1,0,2,
                  1,0,0, 1,0,2,
                  1,0,0,0,  1,0,0,0, 1,0,0,0,  1,0,0,2,
                  1,0,0,  1,0,0,  1,0,0,  1,0,2,
                  1,0,0,0,0,  1,0,0,0,0,  1,0,0,0,0, 1,0,0,0,2,
                  1,0,0, 1,0,0, 1,0,0, 1,0,2,
                  1,2);
  _etData: array[1..93] of string;
  _findData : WIN32_FIND_DATA;

  _aktPanel: TPanel;
  _aktedit: Tedit;
  _aktText: String;
  _homepenztarszam: string;

  _ftpPassword : string  = 'klc+45%';
  _host        : string;   
  _userid      : string  = 'ebc-10%';
  _ftpPort     : Integer = 21100;

  _controlszam: integer;

  _panelsorszam : integer;
  _editsorszam: integer;
  _aktstatusz: integer;
  _code: integer;
  _gepfunkcio: byte;
  _ertektar: byte;
  _printer: byte;
  _sorveg: string = chr(13) + chr(10);

   _olvas,_iras: File of Byte;

   _minta,_atadopath,_mamas: string;
   _srec: Tsearchrec;
  _nyomtato : textFile;
  _aktss,_sorokszama,_qq,_index: integer;
  _kezdosor,_darab,_talaltfile: integer;
  _szoveg,_aktfile: string;
  _hNet,_hFTP,_hsearch: HINTERNET;

  _xFilePath,_xMagyar: array of string;
  _sordarab : integer;
  _sor : string;
  _megnyitottnap,_homepenztarkod: string;
  _remotefile: string;
  _localPath: string;

  _height,_width,_left,_top: word;
  _aktev,_aktho,_aktnap: word;
  _sikeres,_eznapkezdes: boolean;

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

  _top := 0;
  _left := 0;

  if (_height>768) or (_width>1024) then
    begin
      _top  := trunc((_height-768)/2);
      _left := trunc((_width-1024)/2);
    end;

  Top    := _top;
  Left   := _Left;
  Height := 768;
  Width  := 1024;

  Menupanel.Visible     := False;
  GyujtoPanel.Visible   := False;
  Ertektarpanel.Visible := False;
  PenztarPanel.Visible  := False;
  Fuggony.Visible       := False;
  NyomtatoGomb.Enabled  := False;
  Skiccpanel.Visible    := False;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);

  _mamas := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);


  _gepfunkcio := GetGepfunkcio;

  if _gepfunkcio<>2 then LetoltoGomb.Enabled := False;

  if not DirectoryExists(_atadodir) then Createdir(_atadodir);
  if not DirectoryExists(_archiveDir) then CreateDir(_archiveDir);
  Indito.Enabled := True;
end;


// =============================================================================
                    procedure TAtadoLapForm.AtadolapMenu;
// =============================================================================

begin
  Fuggony.Visible := False;
  with MenuPanel do
    begin
      Top := 300;
      Left := 400;
      Visible := True;
    end;
end;

// =============================================================================
          procedure TATADOLAPFORM.KITOLTOGOMBClick(Sender: TObject);
// =============================================================================


begin
  Fuggony.Visible := true;
  MenuPanel.Visible := false;
 
  if _gepfunkcio <> 2 then
    begin
      _ptPanel[1]:= atadPanel;
      _ptPanel[2]:= korlevelpanel;
      _ptPanel[3]:= ugyfrendpanel;
      _ptPanel[4]:= keszrendPanel;
      _ptPanel[5]:= konkurPanel;
      _ptPanel[6]:= Egyebpanel;

      // -------------------------------

      _ptedit[1] := ptszamedit;
      _ptEdit[2] := ptadvetdatumedit;
      _ptEdit[3] := ptatadoedit;
      _ptEdit[4] := ptatvevoedit;

      _ptEdit[5] := ptkordatum1edit;
      _ptEdit[6] := ptiktato1edit;
      _ptEdit[7] := ptTargy1Edit;

      _ptEdit[8] := ptKorDatum2Edit;
      _ptEdit[9] := ptIktato2Edit;
      _ptEdit[10]:= ptTargy2Edit;

      _ptEdit[11]:= ptKorDatum3Edit;
      _ptEdit[12]:= ptIktato3Edit;
      _ptEdit[13]:= ptTargy3Edit;

      _ptEdit[14]:= ptKordatum4Edit;
      _ptEdit[15]:= ptIktato4Edit;
      _ptEdit[16]:= ptTargy4Edit;

      _ptEdit[17]:= ptKordatum5Edit;
      _ptEdit[18]:= ptIktato5Edit;
      _ptEdit[19]:= pttargy5edit;

      // ---------------------------

      _ptEdit[20]:= ptRendDatum1edit;
      _ptEdit[21]:= ptEtros1Edit;
      _ptEdit[22]:= ptRendDnem1Edit;
      _ptEdit[23]:= ptRendSum1edit;
      _ptEdit[24]:= ptRendUgyf1Edit;
      _ptEdit[25]:= ptFon1Edit;

      _ptEdit[26]:= ptRendDatum2Edit;
      _ptEdit[27]:= ptEtros2Edit;
      _ptEdit[28]:= ptRendDnem2Edit;
      _ptEdit[29]:= ptRendSum2edit;
      _ptEdit[30]:= ptRendUgyf2Edit;
      _ptEdit[31]:= ptFon2edit;

      _ptEdit[32]:= ptRendDatum3Edit;
      _ptEdit[33]:= ptEtros3Edit;
      _ptEdit[34]:= ptRendDnem3Edit;
      _ptEdit[35]:= ptRendSum3Edit;
      _ptEdit[36]:= ptRendUgyf3Edit;
      _ptEdit[37]:= ptFon3Edit;

      _ptEdit[38]:= ptRendDatum4Edit;
      _ptEdit[39]:= ptEtros4Edit;
      _ptEdit[40]:= ptRendDnem4Edit;
      _ptEdit[41]:= ptRendsum4Edit;
      _ptEdit[42]:= ptRendUgyf4Edit;
      _ptEdit[43]:= ptFon4Edit;

      _ptEdit[44]:= ptRendDatum5Edit;
      _ptEdit[45]:= ptEtros5Edit;
      _ptEdit[46]:= ptRendDnem5Edit;
      _ptEdit[47]:= ptRendSum5Edit;
      _ptEdit[48]:= ptRendUgyf5Edit;
      _ptEdit[49]:= ptFon5Edit;

      _ptEdit[50]:= ptRendDatum6Edit;
      _ptEdit[51]:= ptEtros6Edit;
      _ptEdit[52]:= ptRendDnem6Edit;
      _ptEdit[53]:= ptRendSum6Edit;
      _ptEdit[54]:= ptRendUgyf6Edit;
      _ptEdit[55]:= ptFon6Edit;

      // ---------------------------

      _ptEdit[56]:= kRendDatum1Edit;
      _ptEdit[57]:= krendDnem1edit;
      _ptEdit[58]:= kRendSum1Edit;

      _ptEdit[59]:= kRendDatum2Edit;
      _ptEdit[60]:= kRendDnem2Edit;
      _ptEdit[61]:= kRendSum2Edit;

      _ptEdit[62]:= kRendDatum3Edit;
      _ptEdit[63]:= kRendDnem3Edit;
      _ptEdit[64]:= kRendSum3edit;

      _ptEdit[65]:= kRendDatum4Edit;
      _ptEdit[66]:= kRendDnem4Edit;
      _ptEdit[67]:= kRendSum4Edit;

      _ptEdit[68]:= kRendDatum5Edit;
      _ptEdit[69]:= kRendDnem5Edit;
      _ptEdit[70]:= kRendsum5Edit;

      _ptEdit[71]:= kRendDatum6Edit;
      _ptEdit[72]:= kRendDnem6Edit;
      _ptEdit[73]:= kRendSum6Edit;

      // ---------------------------

      _ptEdit[74]:= Konk1Edit;
      _ptEdit[75]:= Konk2Edit;

      // ---------------------------

      _ptEdit[76]:= Egyeb1Edit;
      _ptEdit[77]:= Egyeb2edit;

      with Penztarpanel do
        begin
          Top := 8;
          Left := 110;
          Visible := true;
        end;
      Adatbeolvaso;
      PtDataKijelzo;
      ActiveControl := AtAdPanel;
      exit;
    end;

  if _gepfunkcio = 2 then
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

      // ---------------------------------------------

      _etEdit[92]:=  EtInfo1Edit;
      _etEdit[93]:=  EtInfo2Edit;

      with ErtektarPanel do
        begin
          Top := 8;
          Left := 110;
          Visible := true;
        end;

      EtAdatbeolvaso;
      EtDataKijelzo;
      ActiveControl := EtAtAdPanel;
      exit;
    end;
end;

// =============================================================================
              procedure TATADOLAPFORM.PanelEnter(Sender: TObject);
// =============================================================================

begin
  _panelsorszam := TPanel(Sender).Tag;
  _editsorszam := _ptKezdoEdit[_panelSorszam];
  ActiveControl := _ptedit[_editSorszam];
end;

// =============================================================================
     procedure TATADOLAPFORM.PTEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _ezkezdo: integer;
    _bill : byte;

begin
  _bill := ord(key);
  if (_bill<>13) and (_bill<>27) and (_bill<>38) then exit;
  _aktedit := TEdit(sender);

  _editSorszam := _aktedit.Tag;
  _aktStatusz := _ptEditstatus[_editSorszam];
  _aktText := _aktedit.text;

  // ----------- ENTER ---------------------

  if (_bill=27) then
    begin
      // Escape
      KovetkezoPtPanel;
      Exit;
    end;

   if _bill=38 then
     begin
       _ezkezdo := _ptKezdoEdit[_panelsorszam];
       if (_ezkezdo<>_editsorszam) THEN
         begin
           dec(_editsorszam);
           _aktEdit := _ptEdit[_editsorszam];
           ActiveControl := _aktedit;
           exit;
         end else
         begin
           if _ezkezdo>1 then
             begin
               _panelsorszam := _panelsorszam-2;
               KovetkezoPtEdit;
               exit;
             end;
         end;
     end;

   case _aktStatusz of
     0: KovetkezoPtEdit;  // Közbülsö oszlop
     1: begin           // Elsö oszlop
          if _aktText='' then KovetkezoPtPanel
          else KovetkezoPtedit;
        end;
     2: KovetkezoPtPanel;  // utolsó edit az utolsó oszlopban
     3: begin  // kötelezö kitöltés
          if _aktText<>'' then KovetkezoPtEdit;
        end;
   end;
end;

// =============================================================================
                         procedure TATADOLAPFORM.KovetkezoPtEdit;
// =============================================================================


begin
  inc(_editsorszam);
  _aktedit := _ptedit[_editSorszam];
  ActiveControl := _aktedit;
end;

// =============================================================================
                      procedure TATADOLAPFORM.KovetkezoPtPanel;
// =============================================================================


begin
  inc(_panelsorszam);
  if _panelsorszam>6 then
    begin
      ActiveControl := PtOkeGomb;
      Exit;
    end;

  _aktPanel := _ptPanel[_panelsorszam];
  ActiveControl := _aktPanel;
end;


// =============================================================================
                         procedure TATADOLAPFORM.KovetkezoEtEdit;
// =============================================================================


begin
  inc(_editsorszam);
  _aktedit := _etedit[_editSorszam];
  ActiveControl := _aktedit;
end;

// =============================================================================
                      procedure TATADOLAPFORM.KovetkezoEtPanel;
// =============================================================================


begin
  inc(_panelsorszam);
  if _panelsorszam>10 then
    begin
      ActiveControl := EtOkeGomb;
      Exit;
    end;

  _aktPanel := _etPanel[_panelsorszam];
  ActiveControl := _aktPanel;
end;



// =============================================================================
            procedure TATADOLAPFORM.PTSZAMEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := $B0FFFF;
end;

// =============================================================================
              procedure TATADOLAPFORM.PTSZAMEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clWindow;
end;

// =============================================================================
             procedure TATADOLAPFORM.PTMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  PenztarPanel.Visible := False;
  ErtekTarpanel.visible := False;
  GyujtoPanel.Visible := False;
  MemoPanel.Visible := false;
  AtadolapMenu;
end;

// =============================================================================
          procedure TATADOLAPFORM.PTOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  AdatFeliro;
  PenztarPanel.Visible := False;
  Nyomtatogomb.Enabled := true;
  AtadolapMenu;
end;


// =============================================================================
                           procedure TATADOLAPFORM.AllPageErase;
// =============================================================================

var _aktfile,_betujel: string;

begin
  _betujel := 'W';
  if _gepFunkcio=2 then _betujel := 'V';
  _minta := _atadoDir + '\' + _betujel + '*.*';
  if FindFirst(_minta,faAnyFile,_srec)=0 then
    begin
      repeat
        _aktfile := _ATADODIR + '\' +_srec.name;
        DeleteFile(_aktFile);
      Until Findnext(_srec)<>0;
      Findclose(_srec);
    end;
end;

// =============================================================================
                 function TATADOLAPFORM.AdatBeolvaso: boolean;
// =============================================================================

var i,_qq,_dhossz,_zz,_kod: integer;

begin
  Result := False;
  _minta := _atadodir + '\W*.*';
  for i := 1 to 77 do _ptData[i] := '';

  if FindFirst(_minta,faAnyFile,_srec)<>0 then
    begin
      _ptData[1] := _HomePenztarszam;
      _ptData[2] := _megnyitottnap;
      exit;
    end;

  _atadoPath := _atadoDir + '\' + _srec.name;
  Findclose(_srec);

  AssignFile(_olvas,_atadoPath);
  reset(_olvas);

  _qq := 1;
  while _qq<=77 do
    begin
      Blockread(_olvas,_bytetomb,1);
      _aktText := '';
      _dHossz := _bytetomb[1];
      if _dhossz>0 then
        begin
          Blockread(_olvas,_bytetomb,_dhossz);
          _zz := 1;
          while _zz<=_dhossz do
            begin
              _kod := 255 - _bytetomb[_zz];
              _aktText := _aktText + chr(_kod);
              inc(_zz);
            end;
        end;
      _ptData[_qq] := _aktText;
      inc(_qq);
    end;
  Blockread(_olvas,_bytetomb,2);
  _controlszam := _byteTomb[1] + _bytetomb[2];
  if _controlszam = 510 then result := True;
  CloseFile(_olvas);
  _ptData[1] := _Homepenztarszam;
  _ptData[2] := _megnyitottnap;
end;

// =============================================================================
                     procedure TATADOLAPFORM.PtDataKijelzo;
// =============================================================================


var _qq:integer;

begin
  _qq := 1;
  while _qq<=77 do
    begin
      _aktEdit := _ptedit[_qq];
      _aktText := _ptData[_qq];
      _aktedit.Text := _aktText;
      inc(_qq);
    end;
end;

// =============================================================================
                     procedure TATADOLAPFORM.EtDataKijelzo;
// =============================================================================


var _qq:integer;

begin
  _qq := 1;
  while _qq<=93 do
    begin
      _aktEdit := _etedit[_qq];
      _aktText := _etData[_qq];
      _aktedit.Text := _aktText;
      inc(_qq);
    end;
end;



// =============================================================================
                        procedure TATADOLAPFORM.AdatFeliro;
// =============================================================================


var _qq,_wt,_zz,_kod: integer;
    _lDatum: TdateTime;

begin
  AllPageErase;
  _aktedit := _ptedit[2];
  _akttext := trim(_aktedit.Text);
  IF _akttext='' then _aktText := _mamas;
  try
    _Ldatum := strtoHundate(_akttext);
  except
     ShowMessage('AZ ÁTADÓLAP DÁTUMA HIBÁS !');
     exit;
  end;

  _tranzLapnev := GetLapFileNev(_lDatum);

  _atadoPath := _atadodir + '\' + _tranzlapnev;
  AssignFile(_iras,_atadoPath);
  Rewrite(_iras);
  _qq :=1;
  while _qq<=77 do
    begin
      _aktEdit := _ptedit[_qq];
      _aktText := trim(_aktedit.Text);
      _wt := length(_aktText);
      _byteTomb[1] := _wt;
      BlockWrite(_iras,_bytetomb,1);
      _zz := 1;
      while _zz<=_wt do
        begin
          _kod := 255-ord(_aktText[_zz]);
          _bytetomb[_zz] := _kod;
          inc(_zz);
        end;
      BlockWrite(_iras,_bytetomb,_wt);
      inc(_qq);
    end;

  _bytetomb[1] := 255;
  _bytetomb[2] := 255;

  BlockWrite(_iras,_bytetomb,2);
  CloseFile(_iras);
end;

// =============================================================================
                        procedure TATADOLAPFORM.EtAdatFeliro;
// =============================================================================


var _qq,_wt,_zz,_kod: integer;
    _Ldatum: Tdatetime;
begin
  AllPageErase;
  _aktedit := _etedit[2];
  _akttext := trim(_aktedit.Text);
  try
    _Ldatum := strtoHundate(_akttext);
  except
     ShowMessage('AZ ÁTADÓLAP DÁTUMA HIBÁS !');
     exit;
  end;
  _tranzLapnev := GetLapFileNev(_lDatum);

  _atadoPath := _atadodir + '\' + _tranzlapnev;
  AssignFile(_iras,_atadoPath);
  Rewrite(_iras);
  _qq :=1;
  while _qq<=93 do
    begin
      _aktEdit := _etedit[_qq];
      _aktText := trim(_aktedit.Text);
      _wt := length(_aktText);
      _byteTomb[1] := _wt;
      BlockWrite(_iras,_bytetomb,1);
      _zz := 1;
      while _zz<=_wt do
        begin
          _kod := 255-ord(_aktText[_zz]);
          _bytetomb[_zz] := _kod;
          inc(_zz);
        end;
      BlockWrite(_iras,_bytetomb,_wt);
      inc(_qq);
    end;

  _bytetomb[1] := 255;
  _bytetomb[2] := 255;

  BlockWrite(_iras,_bytetomb,2);
  CloseFile(_iras);
end;






// =============================================================================
    procedure TATADOLAPFORM.ETSZAMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================


var _ezkezdo: integer;
    _bill: byte;

begin
  _bill := ord(key);
  if (_bill<>13) and (_bill<>27) and (_bill<>38) then exit;
  _aktedit := TEdit(sender);

  _editSorszam := _aktedit.Tag;
  _aktStatusz := _etEditstatus[_editSorszam];
  _aktText := _aktedit.text;

  // ----------- ENTER ---------------------

  if (_bill=27) then
    begin
      // Escape
      KovetkezoEtPanel;
      Exit;
    end;

   if _bill=38 then
     begin
       _ezkezdo := _etKezdoEdit[_panelsorszam];
       if (_ezkezdo<>_editsorszam) THEN
         begin
           dec(_editsorszam);
           _aktEdit := _etEdit[_editsorszam];
           ActiveControl := _aktedit;
           exit;
         end else
         begin
           if _ezkezdo>1 then
             begin
               _panelsorszam := _panelsorszam-2;
               KovetkezoEtEdit;
               exit;
             end;
         end;
     end;

   case _aktStatusz of
     0: KovetkezoEtEdit;  // Közbülsö oszlop
     1: begin           // Elsö oszlop
          if _aktText='' then KovetkezoEtPanel
          else KovetkezoEtedit;
        end;
     2: KovetkezoEtPanel;  // utolsó edit az utolsó oszlopban
     3: begin  // kötelezö kitöltés
          if _aktText<>'' then KovetkezoEtEdit;
        end;
   end;

end;

// =============================================================================
               procedure TATADOLAPFORM.ETOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  EtadatFeliro;
  ErtektarPanel.Visible := False;
  PenztarPanel.visible := False;
  NyomtatoGomb.Enabled := True;
  AtadoLapMenu;
end;

// =============================================================================
          procedure TATADOLAPFORM.ETATADPANELEnter(Sender: TObject);
// =============================================================================

begin
  _panelsorszam := TPanel(Sender).Tag;
  _editsorszam := _etKezdoEdit[_panelSorszam];
  ActiveControl := _etedit[_editSorszam];
end;


// =============================================================================
        function TATADOLAPFORM.EgyETLapBeolvasasa(_fPath: string): boolean;
// =============================================================================


var _qq,_dHossz,_zz,_kod: integer;

begin
  result := false;
  AssignFile(_olvas,_fPath);
  reset(_olvas);

  _qq := 1;
  while _qq<=93 do
    begin
      Blockread(_olvas,_bytetomb,1);
      _aktText := '';
      _dHossz := _bytetomb[1];
      if _dhossz>0 then
        begin
          Blockread(_olvas,_bytetomb,_dhossz);
          _zz := 1;
          while _zz<=_dhossz do
            begin
              _kod := 255 - _bytetomb[_zz];
              _aktText := _aktText + chr(_kod);
              inc(_zz);
            end;
        end;
      _etData[_qq] := _aktText;
      inc(_qq);
    end;
  Blockread(_olvas,_bytetomb,2);
  _controlszam := _byteTomb[1] + _bytetomb[2];
  if _controlszam = 510 then result := True;
  CloseFile(_olvas);
end;

// =============================================================================
      function TATADOLAPFORM.EgyPTLapBeolvasasa(_fpath:string): boolean;
// =============================================================================


var _qq,_dhossz,_zz,_kod: integer;

begin
  Result := False;
  AssignFile(_olvas,_fPath);
  reset(_olvas);

  _qq := 1;
  while _qq<=77 do
    begin
      Blockread(_olvas,_bytetomb,1);
      _aktText := '';
      _dHossz := _bytetomb[1];
      if _dhossz>0 then
        begin
          Blockread(_olvas,_bytetomb,_dhossz);
          _zz := 1;
          while _zz<=_dhossz do
            begin
              _kod := 255 - _bytetomb[_zz];
              _aktText := _aktText + chr(_kod);
              inc(_zz);
            end;
        end;
      _ptData[_qq] := _aktText;
      inc(_qq);
    end;
  Blockread(_olvas,_bytetomb,2);
  _controlszam := _byteTomb[1] + _bytetomb[2];
  if _controlszam = 510 then result := True;
  CloseFile(_olvas);
end;

// =============================================================================
       function TAtadolapForm.Datumkodolo(_aktdatum: TDatetime):string;
// =============================================================================

var _qev,_qho,_qnap,_word: word;

begin
  _qev := yearof(_aktdatum)-2010;
  _qho := monthof(_aktdatum);
  _qnap:= dayof(_aktdatum);
  _word := trunc(512*_qev)+(32*_qHo)+_qnap;
  result := inttostr(_word);
end;

// =============================================================================
     function TAtadolapForm.GetLapfilenev(_lapdatum:TDatetime): string;
// =============================================================================

var _bsz,_dsz,_exts: string;

begin
  _bsz := eloKieg(_homepenztarszam,3);
  _dsz := datumKodolo(_lapdatum);
  _dsz := elokieg(_dsz,4);
  if _gepfunkcio<>2 then
    begin
      _exts := inttostr(_ertektar);
      result := 'W' + _bsz + _dsz + '.' + _exts;
    end else
    begin
      _exts := trim(_homepenztarszam);
      result := 'V' + _bsz + _dsz + '.' + _exts;
    end;
end;


// =============================================================================
        function TatadoLapForm.Elokieg(_szo: string;_hh: integer):string;
// =============================================================================


begin
  result := trim(_szo);
  while length(result)<>_hh do result := '0' + result;
end;


 //=============================================================================
         function TAtadoLapform.WordbolDatum(_word: word):string;
// =============================================================================


var _nap,_ho,_hi,_lo: byte;
    _ev: word;

begin
  _hi := hi(_word);
  _lo := lo(_word);
  _ev := 2010 + trunc(_hi/2);
  _ho := trunc(128*_hi);
  _ho := trunc(_ho/15)+trunc(_lo/32);
  _nap := trunc(8*_lo);
  _nap := trunc(_nap/8);
  result := inttostr(_ev)+'.'+nulele(_ho)+'.'+nulele(_nap);
end;

// =============================================================================
           function TAtadoLapform.Nulele(_int: integer):string;
// =============================================================================


begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;



// =============================================================================
          procedure TATadoLapForm.KINYOMTATOGOMBClick(Sender: TObject);
// =============================================================================



var _aktpath: string;
begin
  _index := GyujtoList.ItemIndex;
  _aktpath := _xFilePath[_index];
  if not EgyPtlapBeolvasasa(_aktpath) then exit;
  _aktfile := extractfileName(_aktPath);
  eTLapNyomtatas;
  copyfileto(_aktpath,_archivedir+'\'+_aktfile);
  DeleteFile(_aktpath);
  PtMegsemGombClick(Nil);
end;


// =============================================================================
            function TAtadoLapForm.Forintform(_s: string): string;
// =============================================================================


var _float: real;

begin
  result := '   -     ';
  if _s='' then exit;

  val(_s,_float,_code);
  if _code<>0 then _float := 0;
  result := formatfloat('###,###,###',_float);
  while length(result)<9 do result := ' '+result;
end;



// =============================================================================
          procedure TATADOLAPFORM.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
             procedure TAtadoLapForm.ErtektarSkicc;
// =============================================================================

begin

  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  Rewrite(_Lfile);

  writeLN(_LFile,'ERTEKTARI ATADOLAP'+_sorveg);

  writeLn(_Lfile,'Ertektarszam: '+ _etData[1]);
  writeLn(_Lfile,'Datum : '+_etData[2]+_sorveg);

  writeLn(_LFile,'Atado : '+_etData[3]);
  writeLn(_Lfile,'Atvevo: '+_etData[4]+_sorveg);

  writeLn(_Lfile,'PENZKESZLET:'+_sorveg);

  writeLN(_LFile,'Egyezik    : '+_etData[5]);
  writeLN(_LFile,'Nem egyezik: '+_etData[6]);
  writeLN(_LFile,'Elteres    : '+_etData[7]+_sorveg);

  writeLN(_Lfile,'TARTOZASOK:' + _sorveg);

  _sordarab := 3;
  _aktss := 8;
  while _etData[_aktss]<>'' do
    begin
      _sor := ftform(_etData[_aktss+2])+' '+_etdata[_aktss+1]+' ('+_etData[_aktss]+' ertektarnak)';
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;
  writelN(_Lfile,_sorveg+'KOVETELES:'+_sorveg);

  _sordarab := 3;
  _aktss := 17;
  while _etData[_aktss]<>'' do
    begin
      _sor := ftform(_etdata[_aktss+2])+' '+_etData[_aktss+1]+' ('+_etData[_aktss]+' ertektartol)';
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;
  writeLn(_Lfile,_sorveg+'WESTERN UNION/AFA RENDELES:'+_sorveg);

  _sordarab := 2;
  _aktss := 26;
  while _etData[_aktss]<>'' do
    begin
      _sor := _etData[_aktss]+' '+ftform(_etdata[_aktss+2])+' '+_etData[_aktss+1];
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writelN(_Lfile,_sorveg+'BANKI BESZALLITAS:'+_sorveg);

  _sordarab := 4;
  _aktss := 32;
  while _etData[_aktss]<>'' do
    begin
      _sor := _etData[_aktss]+' ' + ftform(_etData[_aktss+2])+' '+_etdata[_aktss+1]+' ('+arfform(_etData[_aktss+3])+')';
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 4;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writelN(_Lfile,_sorveg+'BANKI KISZALLITAS:'+_sorveg);

  _sordarab := 4;
  _aktss := 48;
  while _etData[_aktss]<>'' do
    begin
      _SOR := '       ' + _etData[_aktss]+' '+ftform(_etData[_aktss+2])+' '+_etData[_aktss+1];
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writelN(_Lfile,_sorveg+'PENZTARI RENDELESEK:'+_sorveg);

  _sordarab := 4;
  _aktss := 60;
  while _etData[_aktss]<>'' do
    begin
      _sor := _etdata[_aktss]+' '+ftform(_etdata[_aktss+3])+' '+_etdata[_aktss+2]+' ('+_etdata[_aktss+1]+' ptar)';
      writeLn(_Lfile,_sor);
      _sor := '        (arfolyam: '+arfform(_etData[_aktss+4])+')';
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 5;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writelN(_Lfile,_sorveg+'KORLEVELEK:'+_sorveg);

  _sordarab := 4;
  _aktss := 80;
  WHILE _etData[_aktss]<>'' do
    begin
      _sor := _etdata[_aktss]+ ' '+kieg(_etdata[_aktss+1],12)+' '+kieg(_etData[_aktss+2],15);
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writeLn(_Lfile,_sorveg + 'EGYEB FONTOS INFORMACIOK:'+_sorveg);

  _sordarab := 2;
  _aktss := 92;
  WHILE _etData[_aktss]<>'' do
    begin
      _sor := trim(_etdata[_aktss]);
      if length(_sor)>38 then
        begin
          writeLn(_LFile,leftstr(_sor,38));
          _sor := midstr(_sor,39,length(_sor)-38);
        end;
      writeLN(_Lfile,_sor);
      dec(_sordarab);
      inc(_aktss);
      if _sordarab=0 then break;
    end;
end;


function TAtadoLapForm.Kieg(_s: string; _hh: byte): string;

begin
  while length(_s)<_hh do _s := ' ' + _s;
  result := _s;
end;



// =============================================================================
                      procedure TAtadolapForm.PenztarSkicc;
// =============================================================================

begin
  if not Adatbeolvaso then exit;

  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  Rewrite(_Lfile);

  writeLn(_LFile,'PENZTARI ATADOLAP:' + _sorveg);

  writeLn(_Lfile,'Penztarszam: '+ _ptData[1]);
  writeLn(_Lfile,'Datum : '+_ptData[2]+_sorveg);

  writeLn(_LFile,'Atado : '+_ptData[3]);
  writeLn(_Lfile,'Atvevo: '+_ptData[4]+_sorveg);

  writeLn(_Lfile,_sorveg + 'KORLEVELEK:'+_sorveg);

  _sordarab := 5;
  _aktss := 5;
  while _ptdata[_aktss]<>'' do
    begin
      _sor := _ptdata[_aktss]+'  Targy: '+ _ptData[_aktss+2];
      writeLn(_Lfile,_sor);
      _sor := '      (Iktatoszam: ' +trim(_ptData[_aktss+1])+')' + _sorveg;
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writeLn(_Lfile,_sorveg+'UGYFELEK RENDELESE:'+_sorveg);

  _sordarab := 6;
  _aktss := 20;
  while _ptdata[_aktss]<>'' do
    begin
      _sor := _ptdata[_aktss]+' = '+ftform(_ptdata[_aktss+3])+' '+_ptData[_aktss+2];
      writeLn(_Lfile,_sor);
      _sor := 'Engedelyezo: '+_ptData[_aktss+1];
      writeLn(_Lfile,_sor);
      _sor := 'Ugyfel: ' + _ptData[_aktss+4];
       writeLn(_Lfile,_sor);
      _sor := '  (Tel: '+_ptData[_aktss+5]+')' + _sorveg;
      writeLn(_Lfile,_sor);
      _aktss := _aktss + 6;
      dec(_sordarab);
      if _sordarab= 0 then break;
    end;

  writeln(_Lfile,_sorveg+'KESZLET RENDELESE ERTEKTAR FELE:'+_sorveg);

  _sordarab := 6;
  _aktss := 56;
  while _ptData[_aktss]<>'' do
    begin
      _sor := ftForm(_ptData[_aktss+2])+' '+_ptData[_aktss+1]+' '+_ptdata[_aktss]+'-RE';
      writeLn(_Lfile,_sor);
      _aktss := _aktss+3;
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writeln(_Lfile,_sorveg+'KONKURENCIAVAL KAPCS TUDNIVALOK:'+_sorveg);

  _sordarab := 2;
  _aktss := 74;
  while _ptData[_aktss]<>'' do
    begin
      writeLn(_lfile,trim(_ptData[_aktss]));
      inc(_aktss);
      dec(_sordarab);
      if _sordarab=0 then break;
    end;

  writeln(_Lfile,_sorveg+'EGYEB TUDNIVALOK:'+_sorveg);

  _sordarab := 2;
  _aktss := 76;
  while _ptData[_aktss]<>'' do
    begin
      writeLn(_lfile,trim(_ptData[_aktss]));
      inc(_aktss);
      dec(_sordarab);
      if _sordarab=0 then break;
    end;
end;

// =============================================================================
          function TatadolapForm.ftform(_instr: string):string;
// =============================================================================

var _integer: integer;

begin
  result := '         ';
  if _instr='' then exit;
  val(_instr,_integer,_code);
  if _code<>0 then _integer := 0;
  result := inttostr(_integer);
  while length(result)<>9 do result := ' '+result;
end;

// =============================================================================
         function TAtadolapForm.arfform(_instr: string): string;
// =============================================================================

var _float: real;
    _pos: integer;

begin
  result := '       ';
  if _instr='' then exit;
  _pos := pos(chr(44),_instr);
  if _pos>0 then _instr[_pos] := chr(46);

  val(_instr,_float,_code);
  IF _code<>0 then _float := 0;
  result := floattostr(_float);
end;



// =============================================================================
         procedure TATADOLAPFORM.NYOMTATOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Fuggony.Visible    := true;
  MenuPanel.Visible  := false;
  skiccPanel.Visible := True;
 
  if _gepfunkcio<>2 then Penztarskicc else ErtekTarskicc;

  StartNyomtatas;
  Skiccpanel.visible := False;
  AtadolapMenu;
end;

// =============================================================================
                 function TATADOLAPFORM.EtAdatBeolvaso: boolean;
// =============================================================================

var i: integer;

begin
  Result := False;
  _minta := _atadodir + '\V*.*';
  for i := 1 to 93 do _etData[i] := '';

  if FindFirst(_minta,faAnyFile,_srec)<>0 then
    begin
      _etData[1] := _Homepenztarszam;
      _etData[2] := _megnyitottnap;
      exit;
    end;

  _atadoPath := _atadoDir + '\' + _srec.name;
  Findclose(_srec);

  result := EgyEtLapBeolvasasa(_atadopath);
  if Result then
    begin
      _ptData[1] := _Homepenztarszam;
      _ptData[2] := _megnyitottnap;
    end;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
        procedure TATADOLAPFORM.LETOLTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _gepfunkcio<>2 then exit;
  
  Fuggony.Visible := True;
  MenuPanel.Visible := False;
  PtDownLoad;
end;

// =============================================================================
                         procedure TAtadoLapForm.PtDownLoad;
// =============================================================================


var _aktpath,_aktxpath,_aktxfile,_aktptszam,_koddatum: string;
    _aktword: word;
    _aktDatum: string;
begin
  GyujtoPanel.Visible := False;
  Memotabla.Lines.Clear;
  with MemoPanel do
    begin
      Top := 250;
      Left := 400;
      Visible := True;
      Repaint;
    end;

  _minta := 'W*.'+_homepenztarszam;

  _darab := LoadFromserver;

  if _darab>0 then
      Memotabla.Lines.Add(inttostr(_darab)+' ÁTADÓLAP LETÖLTVE')
  else Memotabla.Lines.add('NEM VOLT A SZERVEREN ÁTADÓLAP');

  MemoTabla.Repaint;
  Sleep(2500);
  MemoPanel.Visible := false;
  GyujtoList.items.clear;
  if findFirst(_atadodir + '\' + _minta,faAnyfile,_srec)=0 then
    begin
      repeat
        _aktPath := _atadodir + '\' + _srec.name;
        GyujtoList.items.add(_aktpath);
      until Findnext(_srec)<>0;
      FindClose(_srec);
    end;

  _darab := Gyujtolist.Count;
  if _darab=0 then
    begin
      ShowMessage('NINCS EGYETLEN KINYOMATLAN ÁTADÓLAP SEM');
      PtMegsemGombclick(nil);
      EXIT;
    end;

  Setlength(_xFilePath,_darab);
  Setlength(_xMagyar,_darab);

  _qq := 0;
  while _qq<_darab do
    begin
      _aktxPath := GyujtoList.Items[_qq];
      _xFilePath[_qq] := _aktxpath;
      _aktxfile := extractFileName(_aktxPath);
      _aktptszam := midstr(_aktxfile,2,3);
      _koddatum := midstr(_aktxfile,5,4);
      val(_koddatum,_aktword,_code);
      if _code<>0 then _aktword := 0;
      _aktdatum := wordboldatum(_aktword);
      _szoveg :='   '+ _aktPtszam + ' SZÁMU IRODA '+_aktdatum +'-I ÁTADÓLAPJA';
      _xMagyar[_qq] := _szoveg;
      inc(_qq);
    end;
  GyujtoList.Items.clear;
  _qq := 0;
  while _qq<_darab do
    begin
      GyujtoList.Items.Add(_xMagyar[_qq]);
      inc(_qq);
    end;

  with GyujtoPanel do
    begin
      Top := 230;
      Left := 250;
      Visible := True;
    end;

  GyujtoList.ItemIndex := 0;
  ActiveControl := GyujtoList;
end;

// =============================================================================
             function TAtadoLapform.LoadFromserver: integer;
// =============================================================================


var _lejott: boolean;

begin
  result := 0;
  Gyujtolist.iTEMS.Clear;
  _minta := 'W*.' + _homePenztarszam;

  _hnet := InternetOpen('Lapletolt',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet = nil then
    begin
      MemoTabla.Lines.Add('A WININET.DLL NEM ÉRHETÕ EL');
      MemoTabla.Repaint;
      SLEEP(2400);
      Exit;
    end;

  // --------  connect to the server  -----------------

  MemoTabla.Lines.Add('BELÉPEK A KÖZPONTI SZERVERBE');
  MemoTabla.Repaint;

  FTPSzerverbeBelep;
  IF _hFTP = nil then exit;

  // --------- Change directory -----------------

  Memotabla.Lines.Add('BELÉPEK AZ ÁTADÓLAP KÖNYVTÁRBA');
  Memotabla.Repaint;
  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\ATADOLAP'));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      MemoTabla.Lines.Add('NEM TUDTAM BELÉPNI AZ ÁTADÓLAP KÖNYVTÁRBA');
      Memotabla.Repaint;
      Sleep(2500);
      Exit;
    end;

  _hSearch := FtpFindFirstFile(_hFtp,pchar(_minta),_findData,0,0);
  if _hsearch<>NIL then
    begin
      repeat
        _aktfile := _findData.cFileName;
        Memotabla.Lines.Add(_aktfile);
        MemoTabla.Repaint;
        Gyujtolist.items.add(_aktfile);
      until not InternetFindNextFile(_hSearch,@_findData);
      InternetCloseHandle(_hSearch);
    end;

   _talaltFile := GyujtoList.Count;

   _qq := 0;
   while _qq<_talaltFile do
     begin
       _remoteFile := GyujtoList.items[_qq];
       Memotabla.Lines.add(_remotefile+' letöltése ..');
       _localPath := _atadodir + '\' + _remotefile;
       if FileExists(_localPath) then DeleteFile(_localPath);
       _lejott := FtpGetFile(_hFtp,pchar(_remoteFile),pchar(_localPath),False,
                                                 0,FTP_TRANSFER_TYPE_BINARY,0);
       if _lejott then Memotabla.Lines.Add('Letöltve ...');
       Memotabla.Repaint;

  //     if _lejott then FTPdeletefile(_hFtp,pchar(_remoteFile));
       inc(_qq);
     end;
   InternetClosehandle(_hFTP);
   InternetCloseHandle(_hNet);
   result := GyujtoList.Count;
end;


// =============================================================================
                    procedure TAtadolapForm.EtlapNyomtatas;
// =============================================================================


begin
  if not printDialog1.Execute then exit;

  Printer.BeginDoc;
  with Printer.Canvas do
    begin
      with Font do
        begin
          Name := 'COURIER NEW';
          Size := 16;
          Style := [fsbold];
        end;

      TextOut(1650,50,'PÉNZTÁROSI ÁTADÓLAP');
      Pen.Width := 6;
      Rectangle(50,400,4400,6200);

      Font.Size := 14;
      TextOut(1950,550,'ÁTADÁS - ÁTVÉTEL');

      Font.Style := [];
      Font.Size := 12;
      TextOut(1100,820,_ptdata[1] + '. SZÁMU PÉNZTÁR '+_ptData[2]+'-I ÁTADÓLAPJA');
      TextOut(1280,1000,'ÁTADÓ PÉNZTÁROS: '+_ptdata[3]);
      TextOut(1220,1100,'ÁTVEVÕ PÉNZTÁROS: '+_ptData[4]);

      Font.Size := 14;
      Font.Style := [fsbold];
      TextOut(2000,1500,'KÖRLEVELEK:');

      Font.Size := 12;
      TextOut(1180,1750,'DÁTUM     IKTATÓSZÁM        TÁRGY');
      Font.Style := [];
    end;

  _aktss := 5;
  _sorokszama := 5;
  _kezdosor := 1800;

  while _ptData[_aktss]<>'' do
    begin
      _kezdosor := _kezdosor + 100;
      _szoveg := _ptData[_aktss]+' - '+ KIEG(_ptdata[_aktss+1],16)+'  '+ _ptdata[_aktss+2];
      Printer.Canvas.TextOut(1000,_kezdosor,_szoveg);
      _aktss := _aktss + 3;
      dec(_sorokSzama);
      if _sorokSzama=0 then Break;
    end;

       //   TextOut(1000,2000,'2010.06.01 - ASDEFR-GTHZ-UJKI  ASDFGVFGBHZTRFDE');
       //   TextOut(1000,2100,'2010.06.01 - ASDEFR-GTHZ-UJKI  ASDFGVFGBHZTRFDE');
       //   TextOut(1000,2200,'2010.06.01 - ASDEFR-GTHZ-UJKI  ASDFGVFGBHZTRFDE');
       //   TextOut(1000,2300,'2010.06.01 - ASDEFR-GTHZ-UJKI  ASDFGVFGBHZTRFDE');

  with Printer.Canvas do
    begin
      Font.Size := 14;
      Font.Style := [fsbold];
      TextOut(1500,2650,'ÜGYFELEK RENDELÉSE:');

      Font.Size := 10;
      TextOut(210,2880,'DÁTUM      ENGEDÉLYEZÕ     VAL   ÖSSZEG  ÜGYFÉL NEVE               TELEFONSZÁM');
      Font.Style := [];
    end;

  _aktss := 20;
  _sorokszama := 6;
  _kezdosor := 2920;

  while _ptData[_aktss]<>'' do
    begin
      _kezdosor := _kezdosor + 80;
      _szoveg := _ptdata[_aktss]+' - '+ kieg(_ptdata[_aktss+1],16)+_ptdata[_aktss+2]+' ';
      _szoveg := _szoveg + forintform(_ptdata[_aktss+3])+' '+kieg(_ptData[_aktss+4],26);
      _szoveg := _szoveg + _ptData[_aktss+5];
      Printer.Canvas.textout(100,_kezdosor,_szoveg);
      _aktss := _aktss + 6;
      dec(_sorokszama);
      if _sorokszama=0 then break;
    end;


         // textout(100,3000,'2010.06.01 - ASDCDFV-BGT-NHZ USD 123456789 1234567890123456789012345 123456789012345');
         // textout(100,3080,'2010.06.01 - ASDCDFV-BGT-NHZ USD 123456789 1234567890123456789012345 123456789012345');
         // textout(100,3160,'2010.06.01 - ASDCDFV-BGT-NHZ USD 123456789 1234567890123456789012345 123456789012345');
         // textout(100,3240,'2010.06.01 - ASDCDFV-BGT-NHZ USD 123456789 1234567890123456789012345 123456789012345');
         // textout(100,3320,'2010.06.01 - ASDCDFV-BGT-NHZ USD 123456789 1234567890123456789012345 123456789012345');
         // textout(100,3400,'2010.06.01 - ASDCDFV-BGT-NHZ USD 123456789 1234567890123456789012345 123456789012345');

  with Printer.canvas do
    begin
      Font.Size := 14;
      Font.Style := [fsbold];
      TextOut(950,3700,'KÉSZLET RENDELÉSE ÉRTÉKTÁR FELÉ:');

      Font.Size := 12;
      TextOut(1330,3920,'  DÁTUM   DNEM     ÖSSZEG');
      Font.Style := [];
    end;

  _aktss := 56;
  _sorokszama := 6;
  _kezdosor := 4000;

  while _ptData[_aktss]<>'' do
    begin
      _kezdosor := _kezdosor + 100;
      _szoveg := kieg(_ptdata[_aktss],12)+kieg(_ptdata[_aktss+1],6)+forintform(_ptData[_aktss+2]);
      Printer.canvas.textout(1260,_kezdosor,_szoveg);
      _aktss := _aktss + 3;
      dec(_sorokszama);
      if _sorokszama=0 then break;
    end;

      //    TextOut(1260,4100,'2010.06.11  EUR   123456789');
      //    TextOut(1260,4200,'2010.06.11  NOK   123456789');
      //    TextOut(1260,4300,'2010.06.11  EUR   123456789');
      //    TextOut(1260,4400,'2010.06.11  USD   123456789');
      //    TextOut(1260,4500,'2010.06.11  CAD   123456789');
      //    TextOut(1260,4600,'2010.06.11  CHF   123456789');

  with Printer.canvas do
    begin
      Font.Size := 14;
      Font.Style := [fsbold];
      TextOut(850,4800,'KONKURENCIÁVAL KAPCSOLATOS TUDNIVALÓK:');
      Font.Style := [];
    end;

  if _ptData[74]<>'' then
    begin
      printer.Canvas.TextOut(400,5100,_ptData[74]);
      if _ptdata[75]<>'' then Printer.canvas.textout(400,5200,_ptData[75]);
    end;

  with Printer.canvas do
    begin
      Font.Size := 14;
      Font.Style := [fsbold];
      TextOut(1650,5500,'EGYÉB TUDNIVALÓK:');
      Font.Style := [];
    end;

  if _ptData[76]<>'' then
    begin
      printer.Canvas.TextOut(400,5800,_ptData[76]);
      if _ptdata[77]<>'' then Printer.canvas.textout(400,5900,_ptData[77]);
    end;

        //  TextOut(400,5800,'ASCDFVGTR FGTBHZUHZ REWERTZUI DESEDRFVB AWSEDRFGTV');
        //  TextOut(400,5900,'ASCDFVGTR FGTBHZUHZ REWERTZUI DESEDRFVB AWSEDRFGTV');

  Printer.EndDoc;
end;


procedure TATADOLAPFORM.GYUJTOLISTDblClick(Sender: TObject);
begin
  ActiveControl := kinyomtatoGomb;
end;

procedure TATADOLAPFORM.INDITOTimer(Sender: TObject);
begin
  iNDITO.Enabled := False;

  if not _eznapkezdes then
    begin
      AtadoLapMenu;
      exit;
    end;
  _eznapkezdes := False;
  KitoltoGombClick(Nil);
end;


function TAtadolapForm.Getgepfunkcio: byte;

begin
  Valdbase.Connected := true;
  with Valquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homePenztarKod := FieldByName('PENZTARKOD').asString;

      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      result := FieldByName('GEPFUNKCIO').asInteger;
      _megnyitottnap := FieldbyName('MEGNYITOTTNAP').asstring;
      _ertektar := FieldByNAme('ERTEKTAR').asInteger;
      _printer := FieldByNAme('PRINTER').asInteger;
      _HOST := trim(FieldByName('HOST').asString);
      Close;
    end;
  Valdbase.close;
end;


function TAtadolapForm.StrtoHundate(_s: string): TDatetime;

var _evs,_hos,_naps: string;

begin
  _evs := leftstr(_s,4);
  _hos := midstr(_s,6,2);
  _naps:= midstr(_s,9,2);

  val(_evs,_aktev,_code);
  val(_hos,_aktho,_code);
  val(_naps,_aktnap,_code);

  result := encodedate(_aktev,_aktho,_aktnap);
end;


// =============================================================================
                      procedure TAtadolapForm.StartNyomtatas;
// =============================================================================

begin
  Writeln(_LFile,_LF5);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);
  TextKiiro;

end;


// =============================================================================
                            procedure TAtadolapForm.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

// =============================================================================
                      procedure TAtadoLapForm.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      ShowMessage('NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT');
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then
    begin
      ShowMessage('A KÖZPONTI SZERVER NEM ÉRHETÕ EL');
      InternetCloseHandle(_hNet);
    end;
end;



end.
