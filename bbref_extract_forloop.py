import pandas as pd

dates = [
'2021-04-22',
'2021-04-23',
'2021-04-24',
'2021-04-25',
'2021-04-26',
'2021-04-27',
'2021-04-28',
'2021-04-29',
'2021-04-30'
]


for gmDate in dates:

# extract daily table based on game date
# gmDate = input("Game Date (yyyy-mm-dd): ")
    tables_bbref = pd.read_html(f"https://www.basketball-reference.com/friv/dailyleaders.fcgi?month={gmDate[5:7]}&day={gmDate[8:10]}&year={gmDate[0:4]}&type=all")

# set "mainTable" to original unedited table in DataFrame (index = 0)
    mainTable = pd.DataFrame(tables_bbref[0])

# identify rows with repeating headers and delete them
    header_rows = mainTable[mainTable['Rk'] == 'Rk']
    mainTable.drop(header_rows.index, inplace=True)


# delete columns with calculated percentages (FG%, 3P%, FT%)
    del mainTable['FG%']
    del mainTable['3P%']
    del mainTable['FT%']

# rename two columns with no labels in original
    mainTable.rename({'Unnamed: 3': 'Away', 'Unnamed: 5': 'Result'}, axis='columns', inplace=True)

# add a "Game_Date" column with value = gmDate
    mainTable.insert(1, 'Game_Date', gmDate, True)


# export to csv file
    mainTable.to_csv(f'bb-ref_exports/bbref_daily_{gmDate}.csv')

