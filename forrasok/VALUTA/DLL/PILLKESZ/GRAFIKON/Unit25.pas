unit Unit25;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, jpeg, Grids, TeeProcs,
  TeEngine, Chart, StrUtils, Series, Psock, IDGlobal,ShellApi,WININET,
  OleCtrls, ComCtrls, DateUtils, IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  THAVITABLO = class(TForm)
  GrafikonPanel: TPanel;

       Grafikon: TChart;

      GroupBox1: TGroupBox;

      CsakVasar: TRadioButton;
     CsakEladas: TRadioButton;
 KorDiagramGomb: TBitBtn;
    Button1: TButton;
    ALSOCIMPANEL: TPanel;
    korforgalompanel: TPanel;
    KORDIAGRAM: TChart;
    NAPIKORFORGALOM: TPieSeries;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;

    // -------------------------------------------------------------------------

    procedure BitBtn1Click(Sender: TObject);


    procedure CsakVasarClick(Sender: TObject);
    procedure CsakEladasClick(Sender: TObject);
    procedure ErtekValtas;

    procedure F1GombClick(Sender: TObject);
    procedure F2GombClick(Sender: TObject);
    procedure F3GombClick(Sender: TObject);

    procedure FormActivate(Sender: TObject);



    procedure GrafikonDisplay;
    procedure GrafikonPanelExit(Sender: TObject);

    procedure KellErtekClick(Sender: TObject);
    procedure KordiagramGombClick(Sender: TObject);
    procedure KordiagramRutin;
    procedure MindkettoClick(Sender: TObject);
    procedure NemkellClick(Sender: TObject);

    procedure Pitetolto(_pitetipus: integer);

    procedure SerialFree;
    procedure Button1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var

  Havitablo    : THavitablo;
  _dnemdb      : integer = 22;
  _tablokszama : integer;

 // ------------------------- KONSTANSOK -----------------------------------

  _cmd         : pchar   = 'OPEN';
  _fil         : pchar   = 'rasdial.exe';
  _dir         : pchar   = 'C:';
  _host        : string  = '188.227.230.132';
  _userid      : string  = 'ebc-10%';
  _ftpPort     : integer = 21100;
  _ftpPassword : string  = 'klc+45%';
  _sorveg      : string  = #13#10;

  // ------------------- WININET ADATAI -------------------------------------

  _findData    : WIN32_FIND_DATA;

  _hNet,
  _hFtp,
  _hSearch,
  _hfile       : HInternet;

  _srec,
  _sttRec      : TsearchRec;

  // --------------------- GRAFIKON ADATAI --------------------------------

  Vasarlas,
  Eladas,
  Forgalom     : TBarSeries;

  _iras,
  _olvas       : File of byte;

 _tablofile,_datumTomb : array[0..300] of string;

  _pszin       : array[0..20] of TColor;

  _ftPanel,
  _bjPanel     : array[1..14] of TPanel;

  _honapnev    : array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS','JUNIUS',
                   'JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER','NOVEMBER','DECEMBER');

  _xDnem,
  _xdnev       : array[1..22] of string;

  _vnum,
  _vnam        : array[0..8] of string;


  _tBoltnev    : array[1..150] of string;

  _tValutanem,
  _tValutanev  : array[1..22] of string;

  _cimErtekek  : array[1..14] of integer = (20000,10000,5000,2000,1000,500,200,100,50,20,10,5,2,1);
  _puffer      : array[0..4095] of byte;
  _byteTomb    : array[1..127] of byte;

  _napivevodarab,_napieladodarab: array[1..35,1..31] of word;

   _ehvet,_akvet  : real;  // elöhavi,akthavi vétel és trend
   _ehelad,_akelad: real;  // elöhavi,akthavi eladás és trend


  _kijelzettStt: string;

  _buys,
  _sells: array[1..31] of integer;

  _multHaviMunkanapok,
  _akthaviMunkanapok,
  _multHaviVevodarab,
  _multHaviEladoDarab,
  _aktHaviVevodarab,
  _aktHaviEladoDarab,
  _penztarosDarab,
  _lastDay: array[1..35] of integer;

  _alcim,
  _remotefile,
  _localfile,
  _localpath,
  _pcs,
  _farok,
  _kapcsolatmod,
  _kapcsolatnev,
  _felhasznalonev,
  _ijelszo,
  _AktKorzetNev,
  _aktkorzetkod,
  _hptsz,
  _hsPath,
  _aname,
  _aktevs,
  _aktevhos,
  _puf,
  _newFile,
  _newfilePath,
  _oldFile,
  _oldFilePath,
  _minta,
  _aktsttpath,
  _cSor,
  _sCsor,
  _ujScimsor,
  _homePenztarszam,
  _hsminta,
  _aktsttfile: string;

  _ehnap,_aknap: integer;               // elözö havi és e-havi munkanapok

  _puffermeret,
  _beolvasva,
  _fileMeret,
  _wcc: dword;

  _hiword: lpdword;

  _akthavinap,
  _aktev,
  _elohavinap,
  _elad,
  _acode,
  _grafikontipus,
  _aktho,
  _au,
  _abraSorszam,
  _korzetindex,
  _mutato,
  _vugyf,
  _days,
  _eUgyf,
  _evindex,
  _hoindex,
  _pkod,
  _vUgyfDb,
  _eUgyfDb,
  _newHsDarab,
  _tabNap,
  _qq,
  _uplus,
  _ss,
  _dinemdb,
  _ujTablo,
  _xNap,
  _xPenztar,
  _tabloDb,
  _tabloDarab,
  _tabss,
  _pp,
  _upp,
  _oldHSDarab,
  _top,
  _left,
  _width,
  _height,
  _cc,
  _vanInternet,
  _mresult,
  _tombMeret,
  _tirodaDarab,
  _aktiroda,
  _txtHossz,
  _tValutaDarab,
  _valutaSorszam,
  _vevoDarab,
  _eladoDarab: integer;

  _mostev,
  _mostho: word;

  _lo,
  _hi,
  _slo,
  _shi,
  _cimletezesNapja,
  _naptariNap: byte;

  // ----------------------------------------------------------------------

  _csakvasarlas,
  _csakeladas,
  _mindaketto,

  _vanVasarlas,
  _vanEladas,
  _kellertek,
  _vancimletTabla,
  _vanOld,
  _kapcsolodva,
  _sikeres,
  _voltFrissites: boolean;

  // ----------------------------------------------------------------------

  _multHaviVetel,
  _multHaviEladas,
  _aktHaviVetel,
  _aktHaviEladas  : array[1..35] of real;

  _maiKeszlet,
  _tegnapiKeszlet,
  _egynapiVetel,
  _egynapiEladas: array[1..35,1..31] of real;


  _vetel,
  _eladas: real;

  _kellvasarlas,_kelleladas: boolean;
  _vanvasarlasTabla,_vanEladasTabla: boolean;

  _yeladas : array[0..20] of integer = (0,1500,2700,200,4400,9210,600,9900,2600,4600,8500,
                         1200,4500,100,8700,2900,3000,7700,8100,1500,7000);
  _yvetel  : array[0..20] of integer = (0,500,7400,3200,400,5510,2600,8900,7600,1600,3500,
                          5500,2300,8880,1050,9660,1250,7700,2800,500,5500);

  _ptsor: array[0..20] of string = (' ','23','10','45','66','125','120','50','51',
                            '67','18','19','72','74','80','129','45','65','43',
                            '80','150');



implementation


{$R *.dfm}




// =============================================================================
             procedure THAVITABLO.FormActivate(Sender: TObject);
// =============================================================================



begin
  _top := 0;
 _left := 0;

 KorForgalomPanel.Visible := False;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  if _height>768 then _top := trunc((_height-768)/2);
  if _width>1024 then _left := trunc((_width-1024)/2);


  Top    := _top;
  Left   := _left;
  Width  := 1024;
  Height := 768;

 

  _tIrodaDarab := 3;
  _tBoltnev[1] := 'NYÍREGYHÁZA INTERSPAR';
  _tboltnev[2] := 'KECSKEMÉTI TESCO';
  _tBoltnev[3] := 'KAPOSVÁRI CORSO';

  _kelleladas := fALSE;
  _kellvasarlas := True;

  _vanVasarlasTabla := False;
  _vanEladasTabla   := False;

   Grafikondisplay;


end;




// =============================================================================
                     procedure THAVITABLO.GrafikonDisplay;
// =============================================================================

var i:integer;
    _maxi,_sb,_se: real;

begin
  with GrafikonPanel do
    begin
      Top     := 68;
      Left    := 5;
      Visible := True;
    end;

  _xpenztar := 20;

  _maxi := 0;
  with Grafikon do
    begin
      Visible := False;
      Left    := 1;
      Top     := 0;
      Width   := 930;
      Height  := 500;

      AllowPanning      := pmNone;
      AnimatedZoom      := true;
      AnimatedZoomSteps := 10;

      // ------------------------- HÁTSÓ FAL -----------------------------------

      with BackWall do
        begin
          Brush.Color := clWhite;
          Brush.Style := bsClear;
          Color := clSilver;
        end;

      // --------------------------ALSÓ FAL ------------------------------------

      BottomWall.Dark3D := False;

      with Gradient do
        begin
          StartColor := clAqua;
          EndColor := clBlue;
          Visible := true;
        end;

      // -------------------  BAL FAL  -----------------------------------------

      LeftWall.Color := clWhite;
      BackColor := clSilver;

      // ------------------------------ALSÓ TENGELY ----------------------------



      with BottomAxis do
        begin
          Automatic        := False;
          AutomaticMaximum := False;
          AutomaticMinimum := False;
          Axis.Color       := clNavy;
          Axis.Mode        := pmBlack;
          Axis.Width       := 1;


          Grid.Color       := clSilver;
          Increment        := 1;
          Maximum          := 21;
          MinorTickCount   := 7;
          EndPosition      := 90;
          Labels := True;
          LabelStyle       := talText;

          with Title do
            begin
              Caption      := '';   // 'Pénztárak számai';
              Font.Charset := default_charset;
              Font.Color   := clBlack;
              Font.Height  := -16;
              Font.Name    := 'arial';
              Font.Style   := [fsBold];
            end;
        end;

      DepthAxis.Visible := true;

      // --------------------- BAL TENGELY -------------------------------------

      with LeftAxis do
        begin
          Automatic        := False;
          AutomaticMAximum := False;
          AutomaticMinimum := False;

          with Title do
            begin
              Caption      := 'MAI FORGALOM (Ft)';
              Font.Charset := default_charset;
              Font.Color   := clBlack;
              Font.Height  := -16;
              Font.Name    := 'arial';
              Font.Style   := [fsBold];
            end;
        end;

      // -------------------------- MEGJEGYZÉS  --------------------------------

      with Legend do
        begin
          Inverted    := True;
          ShadowColor := clNAvy;
          ShadowSize  := 0;
          Legendstyle := lsseries;
        end;

      // ----------------------------- JOBB TENGELY ----------------------------

      with RightAxis do
        begin
          Automatic        := False;
          AutomaticMaximum := False;
          AutomaticMinimum := False;
        end;

      view3dWalls := False;
    end;


  if _kellvasarlas then
    begin
      Vasarlas             := TBarSeries.Create(Grafikon);
      Vasarlas.ParentChart := Grafikon;
      _vanVasarlasTabla := true;
      Alsocimpanel.Caption := 'A MAI NAPI VÁSÁRLÁSOK (Ft)';
      AlsoCimpanel.repaint;

      with Vasarlas do
        begin
          for i := 0 to 20 do Add(i,_ptsor[i],clBlack);

          Marks.ArrowLength := 0;
          Marks.Visible := true;
          SeriesColor := clYellow;
          BarWidthPercent := 25;
          Name := 'VASARLAS';
          OffsetPercent := 15;

          with XValues do
            begin
              Name := 'X';
              MultiPlier := 1;
              Order := loAscending;
            end;

          with YValues do
            begin
              Name := 'Bar';
              MultiPlier := 1;
              Order := loNone;
            end;
        end;

      for i := 1 to _xPenztar do            // @@@@
         begin
           _sb := _yVetel[i];
           Vasarlas.AddXY(i,_sb);
           if _sb>_maxi then _maxi := _sb;
         end;
    end;

  if _kellEladas then
    begin
      Eladas := TBarSeries.Create(Grafikon);
      Eladas.ParentChart := Grafikon;
      _vaneladasTabla := true;
      Alsocimpanel.Caption := 'A MAI NAPI ELADÁSOK (Ft)';
      AlsoCimpanel.repaint;


      with Eladas do
         begin
           for i := 0 to 20 do Add(i,_ptsor[i],clBlack);
           Marks.ArrowLength := 0;
           Marks.Visible := True;
           SeriesColor := clRed;
           BarWidthPercent := 25;
           Name := 'ELADAS';
           OffsetPercent := 15;

           with XValues do
             begin
               Name := 'X';
               MultiPlier := 1;
               Order := loAscending;
             end;

           with YValues do
             begin
               Name := 'Bar';
               Multiplier := 1;
               Order := loNone;
             end;
         end;

      for i := 1 to _xPenztar do       // @@@@
        begin
          _se := _yeLADAS[i];
          Eladas.addxy(i,_se);
          if _se>_maxi then _maxi := _se;
        end;
    end;

//  ErtekValtas;


  with Grafikon do
    begin
      LeftAxis.Maximum := (1.1*_maxi);
      BottomAxis.Maximum := _xPenztar;
      Visible := True;
    end;
  ActiveControl := Kordiagramgomb;
end;




// =============================================================================
                      procedure THAVITABLO.ErtekValtas;
// =============================================================================


begin
  if _kellErtek then
    begin
      if _grafikontipus<>1 then Eladas.Marks.Visible := True;
      if _grafikonTipus<>2 then Vasarlas.Marks.Visible := True;
    end else
    begin
      if _grafikontipus<>1 then Eladas.Marks.Visible := False;
      if _grafikonTipus<>2 then Vasarlas.Marks.Visible := False;
    end;
end;



// =============================================================================
                  procedure THAVITABLO.Kordiagramrutin;
// =============================================================================


begin
  with KorForgalomPanel do
    begin
      Top      := 0;
      Left     := 0;
      Visible  := true;
    end;

  _pszin[0]  := clGreen;
  _pszin[1]  := clYellow;
  _pszin[2]  := clRed;
  _pszin[3]  := clBlue;
  _pszin[4]  := clLime;
  _pszin[5]  := clFuchsia;
  _pszin[6]  := clwhite;
  _pszin[7]  := clBlack;
  _pszin[8]  := clPurple;
  _pszin[9]  := clAqua;
  _pszin[10] := clMoneyGreen;
  _pszin[11] := clNavy;
  _pszin[12] := clTeal;
  _pszin[13] := clOlive;
  _pszin[14] := clInactiveCaptiontext;
  _pszin[15] := clSilver;
  _pszin[16] := clSkyBlue;
  _pszin[17] := clScrollBar;
  _pszin[18] := $B0FFFF;
  _pszin[19] := $FFB0FF;
  _pszin[20] := $FFFFB0;

  KorDiagram.Title.Text.Text := 'A MAI NAPI VÁSÁRLÁSOK';
  Pitetolto(1);
end;

// =============================================================================
              procedure THAVITABLO.Pitetolto(_pitetipus: integer);
// =============================================================================


var i,_ss:integer;
   _megnevezes: string;
   _sumVet,_sumElad,_sumForg: real;

begin

  NapiKorforgalom.Clear;
  _ss := -1;
  for i:= 1 to (_tIrodaDarab) do
    begin
      _megnevezes := trim(_tboltnev[i]);
      _sumVet  := _Yvetel[i];
      _sumElad := _Yeladas[i];
      _sumForg := _sumvet+_sumelad;

      case _piteTipus of
      1: begin
           if _sumvet>0 then
             begin
                inc(_ss);
                NapiKorforgalom.addpie(_sumvet,_megnevezes,_pszin[_ss]);
             end;
          end;

      2: begin
           if _sumElad>0 then
             begin
               inc(_ss);
               NapiKorforgalom.addpie(_sumElad,_megnevezes,_pszin[_ss]);
             end;
         end;

      3: begin
           if _sumforg>0 then
              begin
                inc(_ss);
                NapiKorforgalom.addpie(_sumForg,_megnevezes,_pszin[_ss]);
              end;
         end;
      end;
    end;
end;


// =============================================================================
              procedure THAVITABLO.F1GOMBClick(Sender: TObject);
// =============================================================================

begin
  KorDiagram.Title.Text.Text := 'MAI NAPI VÁSÁRLÁSOK';
  Pitetolto(1);
end;

// =============================================================================
              procedure THAVITABLO.F2GOMBClick(Sender: TObject);
// =============================================================================

begin
  KorDiagram.Title.Text.Text := 'MAI NAPI ELADÁSOK';
  Pitetolto(2);
end;

// =============================================================================
               procedure THAVITABLO.F3GOMBClick(Sender: TObject);
// =============================================================================

begin
  kORDIAGRAM.Title.Text.Text := 'MAI NAPI TELJES FORGALOM';
  Pitetolto(3);
end;


// =============================================================================
            procedure THAVITABLO.CSAKVASARClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  _kellvasarlas := True;
  _kelleladas   := false;
  GrafikonDisplay;
end;

// =============================================================================
              procedure THAVITABLO.CSAKELADASClick(Sender: TObject);
// =============================================================================

begin
   SerialFree;
  _kelleladas := true;
  _kellvasarlas := false;
  GrafikonDisplay;
end;

// =============================================================================
               procedure THAVITABLO.MINDKETTOClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  _kelleladas := True;
  _kellVasarlas := True;

  GrafikonDisplay;
end;

// =============================================================================
              procedure THAVITABLO.KELLERTEKClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  _kellertek := True;
  GrafikonDisplay;
end;

// =============================================================================
                procedure THAVITABLO.NEMKELLClick(Sender: TObject);
// =============================================================================

begin
  Serialfree;
  _kellertek := False;
  GrafikonDisplay;
end;

// =============================================================================
            procedure THAVITABLO.GRAFIKONPANELExit(Sender: TObject);
// =============================================================================

begin
   SerialFree;
end;


// =============================================================================
           procedure THAVITABLO.KORDIAGRAMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SerialFree;
  KordiagramRutin;
end;

// =============================================================================
             procedure THAVITABLO.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  KorForgalomPanel.Visible := False;
  GrafikonDisplay;
end;


// =============================================================================
                        procedure THAVITABLO.SerialFree;
// =============================================================================


begin
  if _vanVasarlasTabla then
    begin
      Vasarlas.Free;
      _vanVasarlasTabla := False;
    end;

  if _vanEladasTabla then
    begin
      Eladas.Free;
      _vanEladasTabla := False;
    end;
end;





procedure THAVITABLO.Button1Click(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure THAVITABLO.Button5Click(Sender: TObject);
begin
  KorForgalomPanel.visible := false;
end;

procedure THAVITABLO.Button9Click(Sender: TObject);
begin
  kORFORGALOMPANEL.Visible := FALSE;
  GrafikonDisplay;
end;



end.


