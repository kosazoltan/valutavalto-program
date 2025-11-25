object Form1: TForm1
  Left = 192
  Top = 125
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = EASTEUROPE_CHARSET
  Font.Color = clWindowText
  Font.Height = -21
  Font.Name = 'Arial'
  Font.Style = [fsBold]
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 24
  object Label2: TLabel
    Left = 256
    Top = 40
    Width = 285
    Height = 24
    Caption = #233'vi forint adatok ellen'#337'rz'#233'se'
  end
  object startgomb: TBitBtn
    Left = 552
    Top = 40
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = startgombClick
  end
  object KILEPGOMB: TBitBtn
    Left = 696
    Top = 40
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = KILEPGOMBClick
  end
  object Panel1: TPanel
    Left = 56
    Top = 32
    Width = 193
    Height = 41
    Color = clRed
    TabOrder = 2
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 119
      Height = 24
      Caption = 'Aktu'#225'lis '#233'v:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object EVEDIT: TEdit
      Left = 128
      Top = 4
      Width = 57
      Height = 32
      TabOrder = 0
      Text = '2020'
      OnClick = EVEDITClick
      OnEnter = EVEDITEnter
      OnExit = EVEDITExit
      OnKeyDown = EVEDITKeyDown
    end
  end
  object hibaMemo: TMemo
    Left = 392
    Top = 90
    Width = 433
    Height = 457
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 3
  end
  object PROCMEMO: TMemo
    Left = 64
    Top = 200
    Width = 321
    Height = 345
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 4
  end
  object mainmemo: TMemo
    Left = 56
    Top = 88
    Width = 321
    Height = 105
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 5
  end
  object hibapanel: TPanel
    Left = -1560
    Top = 248
    Width = 409
    Height = 209
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 409
      Height = 209
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label3: TLabel
      Left = 32
      Top = 24
      Width = 230
      Height = 22
      Caption = 'Term'#233'szetes szem'#233'ly hiba:'
      Transparent = True
    end
    object Label4: TLabel
      Left = 104
      Top = 56
      Width = 156
      Height = 22
      Caption = 'Jogi szem'#233'ly hiba:'
      Transparent = True
    end
    object Label5: TLabel
      Left = 112
      Top = 88
      Width = 145
      Height = 22
      Caption = #214'sszes alaphiba:'
      Transparent = True
    end
    object Label6: TLabel
      Left = 64
      Top = 128
      Width = 294
      Height = 22
      Caption = 'JAVITSAM MEG AZ ADATOKAT ?'
      Transparent = True
    end
    object nhibapanel: TPanel
      Left = 272
      Top = 24
      Width = 97
      Height = 25
      Caption = ' '
      TabOrder = 0
    end
    object JHIBAPANEL: TPanel
      Left = 272
      Top = 56
      Width = 97
      Height = 25
      Caption = ' '
      TabOrder = 1
    end
    object SHIBAPANEL: TPanel
      Left = 272
      Top = 88
      Width = 97
      Height = 25
      Caption = ' '
      TabOrder = 2
    end
    object IGENGOMB: TBitBtn
      Left = 88
      Top = 168
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = IGENGOMBClick
    end
    object NEMGOMB: TBitBtn
      Left = 232
      Top = 168
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = NEMGOMBClick
    end
  end
  object NOERRPANEL: TPanel
    Left = -1850
    Top = 240
    Width = 425
    Height = 201
    BevelOuter = bvNone
    TabOrder = 7
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 425
      Height = 201
      Align = alClient
      Brush.Color = 11599871
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label7: TLabel
      Left = 80
      Top = 40
      Width = 293
      Height = 28
      Caption = 'A tranzakci'#243'k hib'#225'tlanok !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label8: TLabel
      Left = 48
      Top = 96
      Width = 350
      Height = 24
      Caption = 'V'#233'gezzek szintaktikai ellen'#246'rz'#233'st ?'
      Transparent = True
    end
    object SYXIGENGOMB: TBitBtn
      Left = 48
      Top = 144
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object SYXNEMGOMB: TBitBtn
      Left = 216
      Top = 144
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'NE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
  end
  object RENDBENPANEL: TPanel
    Left = -1240
    Top = 256
    Width = 449
    Height = 121
    TabOrder = 8
    Visible = False
    object Shape3: TShape
      Left = 1
      Top = 1
      Width = 447
      Height = 119
      Align = alClient
      Brush.Color = clLime
      Pen.Color = clGreen
      Pen.Width = 3
    end
    object Label9: TLabel
      Left = 48
      Top = 24
      Width = 15
      Height = 24
      Caption = 'A'
      Transparent = True
    end
    object Label10: TLabel
      Left = 128
      Top = 24
      Width = 293
      Height = 24
      Caption = #233'vi '#252'gyf'#233'ladatb'#225'zis hib'#225'tlan !'
      Transparent = True
    end
    object evpanel: TPanel
      Left = 72
      Top = 16
      Width = 49
      Height = 41
      BevelOuter = bvNone
      Color = clLime
      TabOrder = 0
    end
    object FINALGOMB: TBitBtn
      Left = 160
      Top = 72
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'Kil'#233'p'#233's'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
  end
  object SYXJAVPANEL: TPanel
    Left = -1264
    Top = 224
    Width = 369
    Height = 265
    BevelOuter = bvNone
    TabOrder = 9
    Visible = False
    object Shape4: TShape
      Left = 0
      Top = 0
      Width = 369
      Height = 265
      Align = alClient
      Brush.Color = clRed
      Pen.Color = clMaroon
      Pen.Width = 3
    end
    object Label12: TLabel
      Left = 40
      Top = 72
      Width = 196
      Height = 23
      Caption = 'Term'#233'szetes szem'#233'ly:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label13: TLabel
      Left = 112
      Top = 104
      Width = 121
      Height = 23
      Caption = 'Jogi szem'#233'ly:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label14: TLabel
      Left = 96
      Top = 136
      Width = 138
      Height = 23
      Caption = 'Az '#246'sszes hiba:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label15: TLabel
      Left = 80
      Top = 176
      Width = 236
      Height = 24
      Caption = 'Pr'#243'b'#225'ljuk megjav'#237'tani ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label11: TLabel
      Left = 48
      Top = 24
      Width = 286
      Height = 28
      Caption = 'Szintax hib'#225'kat tal'#225'ltam !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object TSYXPANEL: TPanel
      Left = 240
      Top = 72
      Width = 97
      Height = 25
      Color = clWhite
      TabOrder = 0
    end
    object JSYXPANEL: TPanel
      Left = 240
      Top = 104
      Width = 97
      Height = 25
      Color = clWhite
      TabOrder = 1
    end
    object SSYXPANEL: TPanel
      Left = 240
      Top = 136
      Width = 97
      Height = 25
      Color = clWhite
      TabOrder = 2
    end
    object IGENSYXGOMB: TBitBtn
      Left = 40
      Top = 216
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object NEMSYXGOMB: TBitBtn
      Left = 184
      Top = 216
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
    end
  end
  object javitopanel: TPanel
    Left = 2008
    Top = 56
    Width = 833
    Height = 529
    TabOrder = 10
    Visible = False
    object Label16: TLabel
      Left = 192
      Top = 24
      Width = 550
      Height = 24
      Caption = 'Melyik szem'#233'lyek szintaktikai hib'#225'it  szeretn'#233' jav'#237'tani ?'
    end
    object Shape5: TShape
      Left = 40
      Top = 64
      Width = 753
      Height = 41
      Shape = stRoundRect
    end
    object NATURJAVITOGOMB: TBitBtn
      Left = 48
      Top = 72
      Width = 241
      Height = 25
      Cursor = crHandPoint
      Caption = 'TERM'#201'SZETES SZEM'#201'LYEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object JOGIJAVITOGOMB: TBitBtn
      Left = 296
      Top = 72
      Width = 241
      Height = 25
      Cursor = crHandPoint
      Caption = 'JOGISZEM'#201'LYEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object SEMMITSEGOMB: TBitBtn
      Left = 544
      Top = 72
      Width = 241
      Height = 25
      Cursor = crHandPoint
      Caption = 'SEMELYIKET SEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object tipuspanel: TPanel
      Left = 160
      Top = 112
      Width = 521
      Height = 25
      Caption = 'Term'#233'szetes szem'#233'lyek szintaktikai hib'#225'i'
      TabOrder = 3
    end
    object HIBABOX: TListBox
      Left = 160
      Top = 152
      Width = 513
      Height = 329
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ItemHeight = 23
      ParentFont = False
      TabOrder = 4
    end
  end
  object MENDPANEL: TPanel
    Left = -1600
    Top = 232
    Width = 385
    Height = 201
    TabOrder = 11
    Visible = False
    object Shape6: TShape
      Left = 1
      Top = 1
      Width = 383
      Height = 199
      Align = alClient
      Pen.Width = 2
    end
    object Label17: TLabel
      Left = 40
      Top = 48
      Width = 144
      Height = 23
      Caption = 'Jav'#237'tand'#243' mez'#337':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label19: TLabel
      Left = 64
      Top = 80
      Width = 123
      Height = 23
      Caption = 'Aktu'#225'lis '#233'rt'#233'k:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label18: TLabel
      Left = 112
      Top = 8
      Width = 163
      Height = 29
      Caption = 'ADATJAV'#205'T'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label20: TLabel
      Left = 72
      Top = 116
      Width = 109
      Height = 23
      Caption = 'Re'#225'lis '#233'rt'#233'k:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object MEZOPANEL: TPanel
      Left = 192
      Top = 48
      Width = 177
      Height = 25
      Caption = ' '
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object AKTERTPANEL: TPanel
      Left = 192
      Top = 80
      Width = 177
      Height = 25
      Caption = ' '
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object MENDEDIT: TEdit
      Left = 192
      Top = 112
      Width = 177
      Height = 31
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object DATAOKEGOMB: TBitBtn
      Left = 40
      Top = 152
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'Adat rendben'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object HELPGOMB: TBitBtn
      Left = 160
      Top = 152
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'Help'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object BACKGOMB: TBitBtn
      Left = 264
      Top = 152
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'Vissza'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
    end
  end
  object BitBtn1: TBitBtn
    Left = 40
    Top = 560
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'SZINTAKTIKAI ELLEN'#336'RZ'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 12
    OnClick = BitBtn1Click
  end
  object HIBALISTAPANEL: TPanel
    Left = 472
    Top = 104
    Width = 297
    Height = 433
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 13
    Visible = False
    object Shape7: TShape
      Left = 0
      Top = 0
      Width = 297
      Height = 433
      Align = alClient
      Brush.Color = clBtnFace
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label21: TLabel
      Left = 32
      Top = 32
      Width = 247
      Height = 24
      Caption = 'Hibalista t'#237'pusok szerint:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label22: TLabel
      Left = 64
      Top = 80
      Width = 109
      Height = 23
      Caption = #220'gyf'#233'l neve:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label23: TLabel
      Left = 72
      Top = 104
      Width = 102
      Height = 23
      Caption = 'Anyja neve:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label24: TLabel
      Left = 48
      Top = 128
      Width = 128
      Height = 23
      Caption = 'Sz'#252'let'#233'si hely:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label25: TLabel
      Left = 56
      Top = 152
      Width = 118
      Height = 23
      Caption = 'Sz'#252'let'#233'si id'#337':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label26: TLabel
      Left = 32
      Top = 176
      Width = 143
      Height = 23
      Caption = #193'llampolg'#225'rs'#225'g:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label27: TLabel
      Left = 104
      Top = 200
      Width = 69
      Height = 23
      Caption = 'Lakc'#237'm:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label28: TLabel
      Left = 32
      Top = 224
      Width = 137
      Height = 23
      Caption = 'Okm'#225'ny t'#237'pusa:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label29: TLabel
      Left = 80
      Top = 248
      Width = 92
      Height = 23
      Caption = 'Azonos'#237't'#243':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label30: TLabel
      Left = 48
      Top = 272
      Width = 122
      Height = 23
      Caption = 'Lakc'#237'mk'#225'rtya:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label31: TLabel
      Left = 16
      Top = 296
      Width = 158
      Height = 23
      Caption = 'Tartozkod'#225'si hely:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label32: TLabel
      Left = 96
      Top = 320
      Width = 75
      Height = 23
      Caption = 'ISO k'#243'd:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label33: TLabel
      Left = 40
      Top = 352
      Width = 119
      Height = 24
      Caption = #214'SSZESEN:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object nd1: TPanel
      Tag = 1
      Left = 176
      Top = 82
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = nd1Click
    end
    object nd11: TPanel
      Tag = 11
      Left = 176
      Top = 322
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = nd1Click
    end
    object nd3: TPanel
      Tag = 3
      Left = 176
      Top = 130
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = nd1Click
    end
    object nd5: TPanel
      Tag = 5
      Left = 176
      Top = 178
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = nd1Click
    end
    object nd4: TPanel
      Tag = 4
      Left = 176
      Top = 154
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = nd1Click
    end
    object nd2: TPanel
      Tag = 2
      Left = 176
      Top = 106
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = nd1Click
    end
    object nd10: TPanel
      Tag = 10
      Left = 176
      Top = 298
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnClick = nd1Click
    end
    object nd9: TPanel
      Tag = 9
      Left = 176
      Top = 274
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = nd1Click
    end
    object nd8: TPanel
      Tag = 8
      Left = 176
      Top = 250
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
      OnClick = nd1Click
    end
    object nd7: TPanel
      Tag = 7
      Left = 176
      Top = 226
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
      OnClick = nd1Click
    end
    object nd6: TPanel
      Tag = 6
      Left = 176
      Top = 202
      Width = 50
      Height = 21
      Cursor = crHandPoint
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
      OnClick = nd1Click
    end
    object Panel3: TPanel
      Left = 168
      Top = 344
      Width = 57
      Height = 41
      Color = clWhite
      TabOrder = 11
    end
    object tovabbgomb: TBitBtn
      Left = 88
      Top = 392
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'TOV'#193'BB'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 12
      OnClick = tovabbgombClick
    end
  end
  object MEZOLISTAPANEL: TPanel
    Left = -1940
    Top = 80
    Width = 417
    Height = 505
    TabOrder = 14
    Visible = False
    object MEZOLISTA: TListBox
      Left = 16
      Top = 48
      Width = 281
      Height = 425
      ItemHeight = 24
      TabOrder = 0
    end
  end
  object UTABLA: TIBTable
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 432
    Top = 56
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 464
    Top = 56
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 496
    Top = 56
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 528
    Top = 56
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 664
    Top = 8
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V9.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 696
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 736
    Top = 8
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 632
    Top = 8
  end
  object MUGYTABLA: TIBTable
    Database = MUGYDBASE
    Transaction = MUGYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 672
    Top = 56
  end
  object MUGYQUERY: TIBQuery
    Database = MUGYDBASE
    Transaction = MUGYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 712
    Top = 56
  end
  object MUGYDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ALLUGYFEL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = MUGYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 744
    Top = 56
  end
  object MUGYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = MUGYDBASE
    AutoStopAction = saNone
    Left = 784
    Top = 56
  end
  object BIZQUERY: TIBQuery
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 352
  end
  object BIZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 384
  end
  object BIZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZDBASE
    AutoStopAction = saNone
    Left = 8
    Top = 416
  end
  object NEVQUERY: TIBQuery
    Database = NEVDBASE
    Transaction = NEVTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 448
  end
  object NEVDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NEVTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 480
  end
  object NEVTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NEVDBASE
    AutoStopAction = saNone
    Left = 8
    Top = 512
  end
end
