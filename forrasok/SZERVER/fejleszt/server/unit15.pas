unit Unit15;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, ExtCtrls, DB, IBQuery,
  IBDatabase, IBCustomDataSet, IBTable, unit1, strutils;

type
  TUGYFELFORGALOMPOTLO = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    IRODANEVPANEL: TPanel;
    Label3: TLabel;
    DATUMPANEL: TPanel;
    BitBtn1: TBitBtn;
    BLOKKDBASE: TIBDatabase;
    BLOKKTRANZ: TIBTransaction;
    ROGZITOGOMB: TBitBtn;
    VALUTALISTA: TListBox;
    Panel4: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    VETTVALEDIT: TEdit;
    VETTFORINTEDIT: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    ELADOTTVALEDIT: TEdit;
    ATVETTEDIT: TEdit;
    ATADOTTEDIT: TEdit;
    BANKIATVETEDIT: TEdit;
    BANKIATADASEDIT: TEdit;
    ELADOTTFORINTEDIT: TEdit;
    TOLPENZTAR: TEdit;
    NAKPENZTAR: TEdit;
    TOLBANK: TEdit;
    NAKBANK: TEdit;
    VALNEVPANEL: TPanel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    BLOKKQUERY: TIBQuery;
    
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure DataKijelzo(_valss: integer);
    procedure DataBeolvaso(_valss: integer);
    procedure Edit1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure VALUTALISTAClick(Sender: TObject);
    procedure ValutaChange(_ujvss: integer);
    procedure VETTVALEDITEnter(Sender: TObject);
    procedure VETTVALEDITExit(Sender: TObject);
    procedure VETTVALEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure VALUTALISTAEnter(Sender: TObject);
    procedure VALUTALISTAExit(Sender: TObject);
    procedure VALUTALISTAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ROGZITOGOMBClick(Sender: TObject);
    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UGYFELFORGALOMPOTLO: TUGYFELFORGALOMPOTLO;
  _oszlop,_utbetu,_ftertek,_bjegy,_tetel,_osszft,_ix: integer;
  _bizonylatszam,_tipus,_penztar,_blokknum: string;
  _arfolyam: real;
  _blokkfejnev,_blokktetelnev,_utbizszam,_aktbizszam: string;
  Pv,pvft,pe,peft,ppv,ppe,pbv,pbe: array[0..27] of integer;
  ppvn,ppen,pbvn,pben: array[0..27] of string;
  _utvalss: integer;
  _pedit: array[1..12] of TEDit;


implementation

{$R *.dfm}

procedure TUGYFELFORGALOMPOTLO.BitBtn1Click(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TUGYFELFORGALOMPOTLO.FormActivate(Sender: TObject);
var i: integer;
begin
  Top := _TOP + 150;
  Left := _left + 220;

  _farok := midstr(_aktdatums,3,2)+midstr(_aktdatums,6,2);
  _aktfdbpath := 'c:\receptor\database\v'+inttostr(_aktpenztar)+'.fdb';
  _blokkfejnev := 'BF'+ _farok;
  _blokktetelNev := 'BT' + _farok;

  IrodaNevPanel.Caption := _irodanev[_aktpenztar];
  DAtumPanel.Caption := Form1.SetLongDstring(_aktdatums);


  ValutaLista.Clear;
  for i := 0 to _valutadarab-1 do
    begin
      ValutaLista.Items.Add('    '+_dnem[i+1]);
      pv[i] := 0;
      pvft[i] := 0;
      pe[i] := 0;
      peft[i] := 0;
      ppv[i] := 0;
      ppe[i] := 0;
      pbv[i] := 0;
      pbe[i] := 0;
      ppvn[i] := '';
      ppen[i] := '';
      pbvn[i] := '';
      pben[i] := '';
    end;

  _pedit[1] := Vettvaledit;
  _pedit[2] := vettforintedit;
  _pedit[3] := Eladottvaledit;
  _pedit[4] := Eladottforintedit;
  _pedit[5] := Atvettedit;
  _pedit[6] := Tolpenztar;
  _pedit[7] := Atadottedit;
  _pedit[8] := Nakpenztar;
  _pedit[9] := Bankiatvetedit;
  _pedit[10]:= Tolbank;
  _pedit[11]:= Bankiatadasedit;
  _pedit[12]:= Nakbank;

  Valutalista.ItemIndex := 0;
  _utvalss := 0;
  ActiveControl := ValutaLista;

end;


procedure TUgyfelForgalomPotlo.DataKijelzo(_valss: integer);

begin
  Valnevpanel.caption := _dnev[_valss];
  vettvaledit.text := inttostr(pv[_valss]);
  eladottvaledit.text := inttostr(pe[_valss]);
  atvettedit.text := inttostr(ppv[_valss]);
  atadottedit.text := inttostr(ppe[_valss]);
  bankiatvetedit.text := inttostr(pbv[_valss]);
  bankiatadasedit.text := inttostr(pbe[_valss]);
  vettforintedit.text := inttostr(pvft[_valss]);
  eladottforintedit.text := Inttostr(peft[_valss]);
  tolpenztar.text := ppvn[_valss];
  nakpenztar.text := ppen[_valss];
  tolbank.text := pbvn[_valss];
  nakbank.text := pben[_valss];
end;

procedure TUgyfelForgalomPotlo.DataBeolvaso(_valss: integer);
var _pv,_pvft,_pe,_peft,_ppv,_ppe,_pbv,_pbe: integer;

begin
  val(vettvaledit.text,_pv,_code);
  if _code<>0 then _pv := 0;

  val(eladottvaledit.text,_pe,_code);
  if _code<>0 then _pe := 0;

  val(vettforintedit.text,_pvft,_code);
  if _code<>0 then _pvft := 0;

  val(eladottforintedit.text,_peft,_code);
  if _code<>0 then _peft := 0;

  val(atvettedit.text,_ppv,_code);
  if _code<>0 then _ppv := 0;

  val(atadottedit.text,_ppe,_code);
  if _code<>0 then _ppe := 0;

  val(bankiatvetedit.text,_pbv,_code);
  if _code<>0 then _pbv := 0;

  val(bankiatadasedit.text,_pbe,_code);
  if _code<>0 then _pbe := 0;

  ppvn[_valss] := Tolpenztar.text;
  ppen[_valss] := NakPenztar.text;
  pbvn[_valss] := Tolbank.text;
  pben[_valss] := NakBank.text;

  pv[_valss] := _pv;
  pvft[_valss] := _pvft;
  pe[_valss] := _pe;
  peft[_valss] := _peft;
  ppv[_valss] := _ppv;
  ppe[_valss] := _ppe;
  pbv[_valss] := _pbv;
  pbe[_valss] := _pbe;
end;




procedure TUGYFELFORGALOMPOTLO.Edit1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  _ix := valutaLista.Itemindex;
  Valutachange(_ix);
end;

procedure TUGYFELFORGALOMPOTLO.VALUTALISTAClick(Sender: TObject);
begin
  _ix := valutaLista.Itemindex;
  ValutaChange(_ix);
end;

procedure TUgyfelForgalomPotlo.ValutaChange(_ujvss: integer);

begin
  Databeolvaso(_utvalss);
  DataKijelzo(_ujvss);
  _utvalss := _ujvss;
end;

procedure TUGYFELFORGALOMPOTLO.VETTVALEDITEnter(Sender: TObject);
begin
  TEdit(Sender).Color := clYellow;
end;

procedure TUGYFELFORGALOMPOTLO.VETTVALEDITExit(Sender: TObject);
begin
  TEdit(sender).Color := clWindow;
end;

procedure TUGYFELFORGALOMPOTLO.VETTVALEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);

var _bill,_tag: integer;
    _ujedit: TEdit;
begin
   _tag := TEdit(Sender).Tag;
  _bill := ord(key);
  if (_bill=13) or (_bill=40) then
    begin
      if _tag<12 then
        begin
           _ujedit := _pedit[_tag+1];
           ActiveControl := _ujedit;
        end else Activecontrol := ValutaLista;
      exit;
    end;

  if (_bill=38) and (_tag>1) then
    begin
      _ujedit := _pedit[_tag-1];
      ActiveControl := _ujedit;
      exit;
    end;
end;

procedure TUGYFELFORGALOMPOTLO.VALUTALISTAEnter(Sender: TObject);
begin
  ValutaLista.color := clYellow;
end;

procedure TUGYFELFORGALOMPOTLO.VALUTALISTAExit(Sender: TObject);
begin
  ValutaLista.Color := clWindow;
end;

procedure TUGYFELFORGALOMPOTLO.VALUTALISTAKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)=13 then
    begin
      _ix := valutaLista.Itemindex;
      ValutaChange(_ix);
      ActiveControl := Vettvaledit;
      Exit;
    end;
end;

procedure TUGYFELFORGALOMPOTLO.ROGZITOGOMBClick(Sender: TObject);

var _vanUj,_kelltorolni,_voltvetel,_volteladas,_voltpbe,_voltpki: Boolean;
    _voltbBe,_voltbKi: boolean;
    i: integer;
    _bnum: string;

begin
  _ix := valutaLista.Itemindex;
  DataBeolvaso(_ix);
  
  _vanUj := False;
  for i := 0 to _valutadarab-1 do
    begin
      if (pv[i]>0) or (pe[i]>0) or (ppv[i]>0) or (ppe[i]>0) or (pbv[i]>0) or (pbe[i]>0) then
        begin
          _vanuj := true;
          Break;
        end;
    end;

  if not _vanUj then
    begin
      Showmessage('NINCS MIT RÖGZITENI, MERT NEM IRT BE ADATOKAT');
      ModalResult := 2;
      Exit;
    end;

  BlokkDbase.Close;
  BlokkDbase.DatabaseName := _aktfdbpath;
  Blokkdbase.Connected := true;
  if BlokkTranz.InTransaction then BlokkTranz.Commit;
  BlokkTranz.StartTransaction;

   _pcs := 'DELETE FROM ' + _BLOKKFEJnev + ' WHERE DATUM='+CHR(39)+_aktdatums+chr(39);
   with BlokkQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_PCS);
       ExecSql;
     end;

   _pcs := 'DELETE FROM '+_BLOKKTETELnev+' WHERE DATUM='+CHR(39)+_aktdatums+chr(39);
   with BlokkQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       ExecSql;
     end;

  _voltvetel := False;
  _volteladas := false;
  _voltpBe := False;
  _voltpKi := False;
  _voltbBe := False;
  _voltBki := False;

  for i := 0 to _valutadarab-1 do
    begin
      if pv[i]>0 then _voltvetel := True;
      if pe[i]>0 then _volteladas := true;
      if ppv[i]>0 then _voltpbe := True;
      if ppe[i]>0 then _voltpki := true;
      if pbv[i]>0 then _voltbbe := True;
      if pbe[i]>0 then _voltbki := true;
    end;

  //------------------------------------

  if _voltvetel then
    begin
      _tetel := 0;
      _osszFt := 0;
      for i := 0 to _valutadarab-1 do
        begin
          if pv[i]>0 then
            begin
              _aktdnem := _dnem[i+1];
              _bjegy := pv[i];
              _ftertek := pvft[i];
              _arfolyam := 100*(_ftertek/_bjegy);
              inc(_tetel);
              _osszft := _osszft + _ftertek;

              _pcs := 'INSERT INTO '+_blokktetelnev+' (BIZONYLATSZAM,DATUM,VALUTANEM,BANKJEGY,';
              _pcs := _pcs + 'FORINTERTEK,ARFOLYAM,ELOJEL,STORNO)' + _sorveg;
              _pcs := _pcs + 'VALUES ('+chr(39)+ 'V999999' + chr(39)+',';
              _pcs := _pcs + chr(39) + _aktdatums + chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdnem + chr(39)+ ',';
              _pcs := _pcs + inttostr(_bjegy)+',';
              _pcs := _pcs + inttostr(_ftertek)+ ',';
              _pcs := _pcs + floattostr(int(_arfolyam))+',';
              _pcs := _pcs + chr(39)+'+'+chr(39)+',1)';

              with BlokkQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

      _pcs := 'INSERT INTO '+_BLOKKFEJnev+' (DATUM,BIZONYLATSZAM,TIPUS,OSSZESEN,TETEL,STORNO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39)+ _aktdatums + chr(39)+',';
      _pcs := _pcs + chr(39)+ 'V999999' + CHR(39) + ',';
      _pcs := _pcs + chr(39)+'V'+chr(39)+',';
      _pcs := _pcs + inttostr(_osszft)+',';
      _pcs := _pcs + inttostr(_tetel)+',1)';

      with BlokkQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;

  // --------------------------------------------------------

  if _voltEladas then
    begin
      _tetel := 0;
      _osszFt := 0;
      for i := 0 to _valutadarab-1 do
        begin
          if pv[i]>0 then
            begin
              _aktdnem := _dnem[i+1];
              _bjegy := pe[i];
              _ftertek := peft[i];
              _arfolyam := 100*(_ertek/_bjegy);
              inc(_tetel);
              _osszft := _osszft + _ftertek;

              _pcs := 'INSERT INTO '+_BLOKKTETELnev+' (BIZONYLATSZAM,DATUM,VALUTANEM,BANKJEGY,';
              _pcs := _pcs + 'FORINTERTEK,ARFOLYAM,ELOJEL,STORNO)'+_SORVEG;
              _pcs := _pcs + 'VALUES ('+chr(39)+'E999999'+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdatums+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdnem+chr(39)+',';
              _pcs := _pcs + inttostr(_bjegy)+',';
              _pcs := _pcs + inttostr(_ftertek)+',';
              _pcs := _pcs + floattostr(int(_arfolyam))+',';
              _pcs := _pcs + chr(39)+'-'+chr(39)+',1)';

               with BlokkQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

      _pcs := 'INSERT INTO '+_BLOKKFEJnev+' (DATUM,BIZONYLATSZAM,TIPUS,OSSZESEN,TETEL,STORNO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39)+ _aktdatums + chr(39)+',';
      _pcs := _pcs + chr(39)+ 'E999999' + CHR(39) + ',';
      _pcs := _pcs + chr(39)+'E'+chr(39)+',';
      _pcs := _pcs + inttostr(_osszft)+',';
      _pcs := _pcs + inttostr(_tetel)+',1)';

      with BlokkQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;

  // --------------------------------------------------------

  if _voltpBe then
    begin
      _tetel := 0;
      _osszFt := 0;

      for i := 0 to _valutadarab-1 do
        begin
          if ppv[i]>0 then
            begin
              _aktdnem := _dnem[i+1];
              _bjegy := ppv[i];
              _penztar := ppvn[i];
              inc(_tetel);

              _pcs := 'INSERT INTO '+_BLOKKTETELnev+' (BIZONYLATSZAM,DATUM,VALUTANEM,BANKJEGY,';
              _pcs := _pcs + 'ELOJEL,STORNO)'+_SORVEG;
              _pcs := _pcs + 'VALUES ('+chr(39)+'U999999'+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdatums+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdnem+chr(39)+',';
              _pcs := _pcs + inttostr(_bjegy)+',';
              _pcs := _pcs + chr(39)+'+'+chr(39)+',1)';

               with BlokkQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

      _pcs := 'INSERT INTO '+_BLOKKFEJnev+' (DATUM,BIZONYLATSZAM,TIPUS,TETEL,PENZTAR,STORNO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39)+ _aktdatums + chr(39)+',';
      _pcs := _pcs + chr(39)+ 'U999999' + CHR(39) + ',';
      _pcs := _pcs + CHR(39)+'U'+CHR(39)+',';
      _pcs := _pcs + inttostr(_TETEL)+',';
      _pcs := _pcs + chr(39)+_penztar+chr(39);
      _pcs := _pcs + ',1)';

      with BlokkQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;
  // --------------------------------------------------------

   if _voltpKi then
    begin
      _tetel := 0;
      _osszFt := 0;

      for i := 0 to _valutadarab-1 do
        begin
          if ppv[i]>0 then
            begin
              _aktdnem := _dnem[i+1];
              _bjegy := ppe[i];
              _penztar := ppen[i];
              inc(_tetel);

              _pcs := 'INSERT INTO '+_BLOKKTETELnev+' (BIZONYLATSZAM,DATUM,VALUTANEM,BANKJEGY,';
              _pcs := _pcs + 'ELOJEL,STORNO)'+_SORVEG;
              _pcs := _pcs + 'VALUES ('+chr(39)+'F999999'+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdatums+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdnem+chr(39)+',';
              _pcs := _pcs + inttostr(_bjegy)+',';
              _pcs := _pcs + chr(39)+'-'+chr(39)+',1)';

               with BlokkQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

      _pcs := 'INSERT INTO '+_BLOKKFEJnev+' (DATUM,BIZONYLATSZAM,TIPUS,TETEL,PENZTAR,STORNO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39)+ _aktdatums + chr(39)+',';
      _pcs := _pcs + chr(39)+ 'F999999' + CHR(39) + ',';
      _pcs := _pcs + CHR(39)+'F'+CHR(39)+',';
      _pcs := _pcs + inttostr(_TETEL)+',';
      _pcs := _pcs + chr(39)+_penztar+chr(39);
      _pcs := _pcs + ',1)';

      with BlokkQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;
  // --------------------------------------------------------

  if _voltbBe then
    begin
      _tetel := 0;
      _osszFt := 0;

      for i := 0 to _valutadarab-1 do
        begin
          if pbv[i]>0 then
            begin
              _aktdnem := _dnem[i+1];
              _bjegy := pbv[i];
              _penztar := pbvn[i];
              inc(_tetel);

              _pcs := 'INSERT INTO '+_BLOKKTETELnev+' (BIZONYLATSZAM,DATUM,VALUTANEM,BANKJEGY,';
              _pcs := _pcs + 'ELOJEL,STORNO)'+_SORVEG;
              _pcs := _pcs + 'VALUES ('+chr(39)+'U999998'+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdatums+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdnem+chr(39)+',';
              _pcs := _pcs + inttostr(_bjegy)+',';
              _pcs := _pcs + chr(39)+'+'+chr(39)+',1)';

               with BlokkQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

      _pcs := 'INSERT INTO '+_BLOKKFEJnev+' (DATUM,BIZONYLATSZAM,TIPUS,TETEL,PENZTAR,STORNO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39)+ _aktdatums + chr(39)+',';
      _pcs := _pcs + chr(39)+ 'U999998' + CHR(39) + ',';
      _pcs := _pcs + CHR(39)+'U'+CHR(39)+',';
      _pcs := _pcs + inttostr(_TETEL)+',';
      _pcs := _pcs + chr(39)+_penztar+chr(39);
      _pcs := _pcs + ',1)';

      with BlokkQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;

  // --------------------------------------------------------

  if _voltbKi then
    begin
      _tetel := 0;
      _osszFt := 0;

      for i := 0 to _valutadarab-1 do
        begin
          if pbe[i]>0 then
            begin
              _aktdnem := _dnem[i+1];
              _bjegy := pbe[i];
              _penztar := pben[i];
              inc(_tetel);

              _pcs := 'INSERT INTO '+_BLOKKTETELnev+' (BIZONYLATSZAM,DATUM,VALUTANEM,BANKJEGY,';
              _pcs := _pcs + 'ELOJEL,STORNO)'+_SORVEG;
              _pcs := _pcs + 'VALUES ('+chr(39)+'F999998'+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdatums+chr(39)+',';
              _pcs := _pcs + chr(39)+_aktdnem+chr(39)+',';
              _pcs := _pcs + inttostr(_bjegy)+',';
              _pcs := _pcs + chr(39)+'-'+chr(39)+',1)';

               with BlokkQuery do
                begin
                  Close;
                  Sql.Clear;
                  Sql.Add(_pcs);
                  ExecSql;
                end;
            end;
        end;

      _pcs := 'INSERT INTO '+_BLOKKFEJnev+' (DATUM,BIZONYLATSZAM,TIPUS,TETEL,PENZTAR,STORNO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39)+ _aktdatums + chr(39)+',';
      _pcs := _pcs + chr(39)+ 'F999998' + CHR(39) + ',';
      _pcs := _pcs + CHR(39)+'F'+CHR(39)+',';
      _pcs := _pcs + inttostr(_TETEL)+',';
      _pcs := _pcs + chr(39)+_penztar+chr(39);
      _pcs := _pcs + ',1)';

      with BlokkQuery do
        begin
          Close;
          Sql.clear;
          Sql.add(_pcs);
          ExecSql;
        end;
    end;
  // --------------------------------------------------------

  BlokkTranz.Commit;
  ModalResult := 1;
end;

end.
