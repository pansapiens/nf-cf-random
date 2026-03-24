#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-cf-random
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Parallel CF-random runs from a samplesheet (one row per job).
----------------------------------------------------------------------------------------
*/

include { CF_RANDOM } from './modules/cf_random.nf'

def sstr(value) {
    if (value == null) {
        return ''
    }
    def t = value.toString().trim()
    return t ?: ''
}

/** CSV cell: missing column or empty cell → empty string (blank samplesheet fields are OK). */
def cell(row, String key) {
    if (!(row instanceof Map)) {
        return ''
    }
    return sstr(((Map) row).get(key))
}

/** True if the first character of the first field (CSV column order = header order) is # after trim — comment row. */
def samplesheet_row_is_comment(row) {
    if (!(row instanceof Map) || row.isEmpty()) {
        return false
    }
    def firstVal = sstr(((Map) row).entrySet().iterator().next().value)
    return firstVal.startsWith('#')
}

def fname_basename(path_str) {
    def p = path_str.replaceAll(/\/+$/, '')
    return new File(p).name
}

workflow {
    if (!params.samplesheet) {
        log.error('Missing required parameter --samplesheet')
        System.exit(1)
    }

    // Distinct placeholders so Nextflow does not collide on staged basename (blind mode uses all three).
    def dummy_pdb1 = file("${projectDir}/assets/NO_FILE_PDB1")
    def dummy_pdb2 = file("${projectDir}/assets/NO_FILE_PDB2")
    def dummy_fmname = file("${projectDir}/assets/NO_FILE_FMNAME")

    Channel.fromPath(params.samplesheet)
        .splitCsv(header: true)
        .filter { row -> !samplesheet_row_is_comment(row) }
        .map { row ->
            def option = cell(row, 'option')
            if (!option) {
                error("Samplesheet row missing required column 'option'")
            }
            def fname_str = cell(row, 'fname')
            if (!fname_str) {
                error("Samplesheet row missing required column 'fname'")
            }
            def pdb1_str = cell(row, 'pdb1')
            def pdb2_str = cell(row, 'pdb2')
            def fmname_str = cell(row, 'fmname')
            def pname = cell(row, 'pname')

            if (option in ['AC', 'FS'] && (!pdb1_str || !pdb2_str)) {
                error("option '${option}' requires non-empty pdb1 and pdb2")
            }
            if (option == 'FS' && (!pdb1_str || !pdb2_str)) {
                error("option FS requires non-empty pdb1 and pdb2")
            }

            def use_pdb1 = pdb1_str != ''
            def use_pdb2 = pdb2_str != ''
            def use_fmname = fmname_str != ''

            def fname = file(fname_str, checkIfExists: true)
            def fname_is_a3m_file = fname.isFile() && fname_str.trim().toLowerCase().endsWith('.a3m')
            def pdb1 = use_pdb1 ? file(pdb1_str, checkIfExists: true) : dummy_pdb1
            def pdb2 = use_pdb2 ? file(pdb2_str, checkIfExists: true) : dummy_pdb2
            def fmname = use_fmname ? file(fmname_str, checkIfExists: true) : dummy_fmname

            def fname_base = fname_basename(fname_str)
            def id = ''
            if (option == 'blind') {
                id = pname ?: fname_base
            } else {
                id = use_pdb1 ? pdb1.baseName : (pname ?: fname_base)
            }
            id = id.replaceAll(/[^A-Za-z0-9._-]+/, '_')

            def meta = [
                id          : id,
                option      : option,
                pname       : pname ?: null,
                fname_is_a3m_file : fname_is_a3m_file,
                nMSA        : cell(row, 'nMSA') ?: null,
                nENS        : cell(row, 'nENS') ?: null,
                type        : cell(row, 'type') ?: null,
                pdb1_range  : cell(row, 'pdb1_range') ?: null,
                pdb2_range  : cell(row, 'pdb2_range') ?: null,
                pred1_range : cell(row, 'pred1_range') ?: null,
                pred2_range : cell(row, 'pred2_range') ?: null,
                use_pdb1    : use_pdb1,
                use_pdb2    : use_pdb2,
                use_fmname  : use_fmname,
            ]

            tuple(meta, fname, pdb1, pdb2, fmname)
        }
        .set { ch_cf_random }

    CF_RANDOM(ch_cf_random)
}
