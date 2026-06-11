object TRYAGAINFORM: TTRYAGAINFORM
  Left = 413
  Top = 364
  BorderStyle = bsNone
  Caption = 'TRYAGAINFORM'
  ClientHeight = 275
  ClientWidth = 486
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 270
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 480
      Height = 270
      Align = alClient
      Brush.Color = clRed
      Pen.Color = clYellow
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 24
      Top = 24
      Width = 436
      Height = 22
      Caption = 'NEM SIKER'#220'LT BEL'#201'PNI AZ OTP TERMIN'#193'LBA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 112
      Top = 64
      Width = 287
      Height = 24
      Caption = 'AZ OK A K'#214'VETKEZ'#336' LEHET.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 123
      Top = 96
      Width = 260
      Height = 18
      Caption = '- NINCS BEKAPCSOLVA A TERMIN'#193'L'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 120
      Top = 120
      Width = 133
      Height = 18
      Caption = '-NINCS INTERNET'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 120
      Top = 144
      Width = 272
      Height = 18
      Caption = '-FIZIKAILAG NINCS '#214'SSZEK'#214'TTET'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 88
      Top = 184
      Width = 336
      Height = 23
      Caption = 'PR'#211'B'#193'LJAM MEG M'#201'GEGYSZER ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object YESGOMB: TBitBtn
      Left = 48
      Top = 224
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'PR'#211'B'#193'LJAM M'#201'GEGYSZER'
      TabOrder = 0
      OnClick = YESGOMBClick
    end
    object NOGOMB: TBitBtn
      Left = 248
      Top = 224
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'T'#214'BBSZ'#214'R NEM PR'#211'B'#193'LOM'
      TabOrder = 1
      OnClick = NOGOMBClick
    end
  end
end
