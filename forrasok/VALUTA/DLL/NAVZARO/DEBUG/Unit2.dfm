object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 302
  ClientWidth = 689
  Color = clMaroon
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object BEKEROPANEL: TPanel
    Left = 5
    Top = 5
    Width = 680
    Height = 290
    BevelOuter = bvNone
    Locked = True
    TabOrder = 0
    Visible = False
    object Label1: TLabel
      Left = 96
      Top = 16
      Width = 504
      Height = 36
      Caption = 'K'#233'rem a NAV-os p'#233'nzt'#225'rg'#233'p z'#225'r'#243
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 200
      Top = 64
      Width = 287
      Height = 36
      Caption = 'forint fi'#243'kk'#233'szlet'#233't'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object HIDEEDIT: TEdit
      Left = 312
      Top = 144
      Width = 49
      Height = 23
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial Narrow'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = 'HIDEEDIT'
      OnEnter = HIDEEDITEnter
      OnExit = HIDEEDITExit
      OnKeyDown = HIDEEDITKeyDown
    end
    object ZFTPANEL: TPanel
      Left = 232
      Top = 128
      Width = 257
      Height = 41
      BevelOuter = bvNone
      Caption = '500 000 000 Ft'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = ZFTPANELClick
    end
    object ZFTRENDBENGOMB: TBitBtn
      Left = 272
      Top = 208
      Width = 193
      Height = 33
      Cursor = crHandPoint
      Caption = 'FORINT RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = ZFTRENDBENGOMBClick
    end
    object ZOLDPANEL: TPanel
      Left = -1500
      Top = 0
      Width = 680
      Height = 290
      BevelOuter = bvNone
      Color = clLime
      TabOrder = 3
      Visible = False
      object Label3: TLabel
        Left = 32
        Top = 64
        Width = 622
        Height = 27
        Caption = 'A NAV-OS P'#201'NZT'#193'RG'#201'P Z'#193'R'#193'SA MEGEGYEZIK'
        Font.Charset = ANSI_CHARSET
        Font.Color = clGreen
        Font.Height = -21
        Font.Name = 'Elephant'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label4: TLabel
        Left = 216
        Top = 120
        Width = 262
        Height = 27
        Caption = 'A C'#205'MLETEZETTEL'
        Font.Charset = ANSI_CHARSET
        Font.Color = clGreen
        Font.Height = -21
        Font.Name = 'Elephant'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object NAVOKEGOMB: TBitBtn
        Left = 280
        Top = 200
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'TOV'#193'BB'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = NAVOKEGOMBClick
      end
    end
    object PIROSPANEL: TPanel
      Left = -1987
      Top = 0
      Width = 680
      Height = 290
      BevelOuter = bvNone
      Color = clRed
      TabOrder = 4
      Visible = False
      object Label5: TLabel
        Left = 40
        Top = 24
        Width = 583
        Height = 24
        Caption = 'A NAV-OS FORINT FI'#211'K'#201'RT'#201'KE ELT'#201'R A C'#205'MLETEZ'#201'ST'#336'L'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label6: TLabel
        Left = 144
        Top = 64
        Width = 426
        Height = 24
        Caption = 'A P'#201'NZT'#193'ROS MEGJEGYZ'#201'SE A T'#201'M'#193'HOZ'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object MEGJEGYZES: TMemo
        Left = 56
        Top = 104
        Width = 569
        Height = 113
        BorderStyle = bsNone
        Color = 16756991
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object PIROSTOVABBGOMB: TBitBtn
        Left = 202
        Top = 240
        Width = 273
        Height = 25
        Cursor = crHandPoint
        Caption = 'E-MAIL K'#220'LD'#201'SE '#201'S MEHET TOV'#193'BB A Z'#193'R'#193'S'
        TabOrder = 1
        OnClick = PIROSTOVABBGOMBClick
      end
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 216
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 216
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 96
    Top = 216
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 176
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 176
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 88
    Top = 176
  end
end
