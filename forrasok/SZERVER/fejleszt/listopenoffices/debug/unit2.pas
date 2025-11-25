unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase,strUtils, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, ComCtrls;

type
  TForm2 = class(TForm)

    RecQuery   : TibQuery;
    RecDbase   : TibDatabase;
    RecTranz   : TibTransaction;

    GyujtoQuery: TibQuery;
    GyujtoDbase: TibDatabase;
    GyujtoTranz: TibTransaction;

    NaploQuery : TibQuery;
    NaploDbase : TibDatabase;
    NaploTranz : TibTransaction;

    Kilepo     : TTimer;
    Alaplap    : TPanel;

    Label1     : TLabel;
    Label2     : TLabel;

    Csik       : TProgressBar;
    Shape1     : TShape;

    procedure FormActivate(Sender: TObject);
    procedure IdoszakBeolvasas;
    procedure InitParancs;
    procedure ParancsPart(_ukaz: string);
    procedure GyujtoParancs(_gypcs: string);
    procedure KilepoTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _penztarsor,_korzetszam: array[1..170] of byte;
  _penztarnev,_penztarcim,_bankkod,_status: array[1..170] of string;

  _farok,_starts,_ends,_startDatums,_endDatums,_daybooks,_pcs,_naps,_st: string;
  _ptnev,_ptcim,_bkod: string;

  _start,_end,_idb,_ptszam,_nap,_open,_cc,_pt,_korzet: byte;
  _code,_mResult: integer;
  _sorveg: string = chr(13) + chr(10);

  _top,_left,_height,_width: word;


function openofficelist: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function openofficelist: integer; stdcall;
// =============================================================================

begin
  Form2:= TForm2.Create(Nil);
  result := form2.showmodal;
  Form2.Free;
end;



// =============================================================================
               procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top  := round((_height-140)/2);
  _left := round((_width-380)/2);

  Top  := _top;
  Left := _left;

  Repaint;

  Recdbase.Connected := True;

  IdoszakBeolvasas;

  _farok := midStr(_startDatums,3,2)+midstr(_startDatums,6,2);
  _dayBooks := 'DAYB' + _farok;

  _starts := midStr(_startDatums,9,2);
  _ends   := midStr(_endDatums,9,2);

  val(_starts,_start,_code);
  val(_ends,_end,_code);

  RecDbase.Close;

  Naplodbase.Connected := True;
  _pcs := 'SELECT * FROM ' + _daybooks+ ' ORDER BY PENZTAR';

  with NaploQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  _iDb := 0;
  while not NaploQuery.Eof do
    begin
      _ptSzam := NaploQuery.FieldByName('PENZTAR').asInteger;
      _nap    := _start;
      _open   := 0;

      while _nap<=_end do
        begin
          _naps := 'N' + inttoStr(_nap);
          _st   := NaploQuery.FieldByNAme(_naps).asString;

          if _st='B' THEN
            begin
              _open := 1;
              break;
            end;

          inc(_nap);
        end;

      if _open=1 then
        begin
          inc(_iDb);
          _penztarSor[_iDb] := _ptSzam;
        end;

      NaploQuery.Next;
    end;

   NaploQuery.Close;
   Naplodbase.Close;

   if _iDb=0 then
     begin
       ShowMessage('A KÉRT IDÕSZAKBAN NEM VOLT NYITOTT PÉNZTÁR !');
       _mResult := -1;
       Kilepo.Enabled := True;
       Exit;
     end;

   Csik.Max := _iDb;

   Recdbase.Connected := True;

   _cc := 1;
   while _cc<=_iDb do
     begin
       csik.Position := _cc;

       _pt  := _penztarSor[_cc];
       _pcs := 'SELECT * FROM IRODAK WHERE UZLET='+ inttostr(_pt);
       with RecQuery do
         begin
           Close;
           Sql.clear;
           Sql.add(_pcs);
           Open;
           _penztarNev[_pt] := trim(RecQuery.FieldByNAme('KESZLETNEV').asString);
           _penztarCim[_pt] := trim(RecQuery.FieldByNAme('IRODACIM').asString);
           _korzetSzam[_pt] := RecQuery.FieldByNAme('ERTEKTAR').asInteger;
           _bankKod[_pt] := trim(RecQuery.FieldByNAme('BANKKOD').asString);
           _status[_pt] := RecQuery.FieldByNAme('STATUS').asString;
           Close;
         end;
       inc(_cc);
     end;
   RecDbase.Close;

   // ----------------------------

   _pcs := 'DELETE FROM OPENOFFICES';
   GyujtoParancs(_pcs);

   InitParancs;
   _cc := 1;
   while _cc<=_iDb do
     begin
       Csik.Position := _cc;
       _pt    := _penztarSor[_cc];
       _ptNev := _penztarNev[_pt];
       _ptCim := _penztarCim[_pt];

       _korzet:= _korzetSzam[_pt];

       _bKod := _bankKod[_pt];
       _st := _status[_pt];

       _pcs := 'INSERT INTO OPENOFFICES (PENZTARSZAM,PENZTARNEV,PENZTARCIM,';
       _pcs := _pcs + 'STATUS,ERTEKTAR,BANKKOD)' + _sorveg;
       _pcs := _pcs + 'VALUES (' +inttostr(_pt) + ',';
       _pcs := _pcs + chr(39) + _ptnev + chr(39) + ',';
       _pcs := _pcs + chr(39) + _ptcim + chr(39) + ',';
       _pcs := _pcs + chr(39) + _st + chr(39) + ',';
       _pcs := _pcs + inttostr(_korzet) + ',';
       _pcs := _pcs + chr(39) + _bkod + chr(39) + ')';

       ParancsPart(_pcs);
       inc(_cc);
     end;

   GyujtoTranz.commit;
   GyujtoDbase.close;
   _mResult := 1;
   Kilepo.Enabled := True;
end;

// =============================================================================
                          procedure TForm2.InitParancs;
// =============================================================================

begin
  GyujtoDbase.Connected := True;
  if GyujtoTranz.InTransaction then GyujtoTranz.Commit;
  GyujtoTranz.StartTransaction;
end;

// =============================================================================
                procedure TForm2.ParancsPart(_ukaz: string);
// =============================================================================

begin
  with GyujtoQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
end;

// =============================================================================
             procedure TForm2.GyujtoParancs(_gypcs: string);
// =============================================================================

begin
  InitParancs;
  ParancsPart(_gypcs);
  GyujtoTranz.Commit;
  GyujtoDbase.Close;
end;

// =============================================================================
                     procedure TForm2.IdoszakBeolvasas;
// =============================================================================

begin
  RecDbase.Connected := True;
  with recQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM IDOSZAK');
      Open;
      _startDatums := FieldByNAme('STARTDATE').asString;
      _endDatums   := FieldByNAme('ENDDATE').asString;
      Close;
    end;
  RecDbase.close;
end;

// =============================================================================
                procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ModalResult    := _mResult;
end;

end.
