''' find_cells.py - Find cells in the ETL annotated dictionary needing values
'''
from collections import OrderedDict
from xlutils.copy import copy as xlcopy
import logging
import os
import sys
import xlrd
import xlwt


def get_indexes(log, file_path, sheet_name='Data Summary'):
    SECTION_NAMES = '''Demographics
    Enrollment
    Encounter
    Diagnosis
    Procedure
    Vitals'''

    DEFAULT_HEADER = 'summery'
    VALUE_HEADERS = ['Count', 'Percent']

    # Open the Excel file and get the first column of the relevant sheet.
    wb = xlrd.open_workbook(file_path, on_demand=True)
    ws = wb.sheet_by_name(sheet_name)
    colA = [str(c.value) for c in ws.col(0)]

    # Get the column index for each of the desired sections.
    section_idx = sorted([(s, colA.index(s))
                          for s in [sn.strip()
                                    for sn in SECTION_NAMES.split('\n')]
                          if s in colA], key=lambda tup: tup[1])

    field_keys = list()
    for tup_idx, (sec, sec_idx) in enumerate(section_idx):
        # for each section, find the column headers on the next row.
        cols = [(c, str(v).strip())
                for c, v in enumerate(ws.row_values(sec_idx+1))]

        # Find how many rows are dedicated to this section
        row_min = sec_idx + 1
        row_max = (section_idx[tup_idx + 1][1]
                   if tup_idx < len(section_idx) - 1
                   else ws.nrows - 1)

        # Column headers have something in them (except the first one so
        # we make one up).
        data_cols = ([(0, DEFAULT_HEADER)] +
                     [c for c in cols if c[1]])

        for col_idx, col in data_cols:
            if col not in VALUE_HEADERS:
                # For each column that's not a header for values
                for row_idx in range(row_min + 1, row_max):
                    # Go through all the rows for the section
                    cv = ws.cell_value(row_idx, col_idx).strip('*')
                    if cv:
                        # If the cell contains data, then it's a label.
                        if col == DEFAULT_HEADER:
                            # The first row only has one value column
                            idxs = ((row_idx, col_idx + 1),)
                            key_values = [sec, str(cv)]
                        else:
                            # The others have two
                            idxs = ((row_idx, col_idx + 1),
                                    (row_idx, col_idx + 2))
                            key_values = [sec, col, str(cv)]
                        # {Field:(row_to_fill_in, col_to_fill_in)}
                        # For example...
                        # Vitals.VITAL_SOURCE.PR {'Count': (69, 4), 'Percent': (69, 5)}  # noqa
                        fields = dict([(cols[ci][1], (_, ci))
                                       for _, ci in idxs])

                        field_keys += [('.'.join(
                            key_values + ([fld] if col != DEFAULT_HEADER
                                          else [])), fields[fld])
                                       for fld in fields.keys()]
    return wb, ws, OrderedDict(field_keys)


def update_xls(log, xl_infile, xl_outfile, keyed_values={}, default='0'):
    out_name, out_ext = os.path.splitext(xl_outfile)
    if out_ext.lower() == '.xlsx':
        raise NotImplementedError('Output must be .xls, not .xlsx.  Sorry.')

    # Get the key/cell indexes of interest
    wb_in, ws_in, field_keys = get_indexes(log, xl_infile)

    # Copy the Excel sheet to a write workbook
    wb_out = xlcopy(wb_in)
    ws_out = wb_out.get_sheet(ws_in.number)

    # Set the style to text
    style = xlwt.easyxf(num_format_str="0")
    for key in field_keys.keys():
        if key in keyed_values.keys():
            val = keyed_values[key]
            log.debug('Writing %s to %s' % (keyed_values[key], key))
        else:
            val = default
            log.warning('Spreadsheet field %s not found in results.' % key)
        ws_out.write(*field_keys[key], label=val, style=style)
    wb_out.save(xl_outfile)

if __name__ == '__main__':
    log = logging.getLogger(__name__)
    logging.basicConfig(level=logging.DEBUG)

    xl_infile, xl_outfile = sys.argv[1:3]
    log.info('Note that formatting won\'t be preserved.  Sorry.')
    update_xls(log, xl_infile, xl_outfile, default='test')
