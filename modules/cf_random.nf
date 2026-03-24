process CF_RANDOM {
    tag "${meta.id}"

    publishDir "${params.outdir}/${meta.id}", mode: 'copy'

    container 'https://bioinformatics.erc.monash.edu/home/andrewperry/containers/ghcr.io-australian-protein-design-initiative-containers-cf-random-ea076e3_weights.img'

    input:
    tuple val(meta), path(fname), path(pdb1), path(pdb2), path(fmname)

    output:
    path "blind_prediction", optional: true, emit: blind_prediction
    path "successed_prediction", optional: true, emit: successed_prediction
    path "failed_prediction", optional: true, emit: failed_prediction
    path "multimer_prediction", optional: true, emit: multimer_prediction
    path "*.csv", optional: true, emit: csv_top
    path "*.png", optional: true, emit: png_top
    path "**/*.csv", optional: true, emit: csv_nested
    path "**/*.png", optional: true, emit: png_nested

    script:
    def range_opts = ''
    if (meta.option == 'FS') {
        if (meta.pdb1_range) {
            range_opts += " --pdb1-range '${meta.pdb1_range}'"
        }
        if (meta.pdb2_range) {
            range_opts += " --pdb2-range '${meta.pdb2_range}'"
        }
        if (meta.pred1_range) {
            range_opts += " --pred1-range '${meta.pred1_range}'"
        }
        if (meta.pred2_range) {
            range_opts += " --pred2-range '${meta.pred2_range}'"
        }
    }

    def main_opts = ''
    if (meta.use_pdb1) {
        main_opts += " --pdb1 \"${pdb1}\""
    }
    if (meta.use_pdb2) {
        main_opts += " --pdb2 \"${pdb2}\""
    }
    if (meta.pname) {
        main_opts += " --pname ${meta.pname}"
    }
    if (meta.nMSA) {
        main_opts += " --nMSA ${meta.nMSA}"
    }
    if (meta.nENS) {
        main_opts += " --nENS ${meta.nENS}"
    }
    if (meta.type) {
        main_opts += " --type ${meta.type}"
    }
    if (meta.use_fmname) {
        main_opts += " --fmname \${CF_RANDOM_FM_REL}"
    }

    def wrap_msa_dir = (meta.pname ?: 'a3m').toString().replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def fname_setup = meta.get('fname_is_a3m_file', false) ? """
    # Single .a3m path: MSA-only folder for colabfold_batch (CF-random expects --fname as a directory name under cwd).
    _NXF_A3M_ABS=\$(readlink -f "${fname}")
    mkdir -p "${wrap_msa_dir}"
    ln -sf "\${_NXF_A3M_ABS}" "${wrap_msa_dir}/0.a3m"
    CF_RANDOM_FNAME_REL="${wrap_msa_dir}/"
""" : """
    # Directory path: cwd = parent of staged MSA folder; fname = folder basename + /
    _NXF_MSA_ABS=\$(readlink -f "${fname}")
    cd "\$(dirname "\${_NXF_MSA_ABS}")"
    CF_RANDOM_FNAME_REL="\$(basename "\${_NXF_MSA_ABS}")/"
"""

    """
    # CF-random uses os.getcwd() + args.fname; Apptainer/Slurm can leave cwd wrong (e.g. /fs04 -> /fs04input/).
    ${fname_setup}
    # main.py short-circuits if these dirs exist; resume/partial work dirs then hit blind_screening IndexError (empty or 1D files_count).
    rm -rf blind_prediction successed_prediction failed_prediction multimer_prediction
    rm -f range_fs_pairs_all.txt

    ${meta.use_fmname ? "_NXF_FM_ABS=\$(readlink -f \"${fmname}\")\n    CF_RANDOM_FM_REL=\"\$(basename \"\${_NXF_FM_ABS}\")/\"" : ''}

    ${meta.option == 'FS' ? "python3 \"${projectDir}/bin/generate_range_fs_pairs.py\" --pdb1 \"${pdb1}\" --pdb2 \"${pdb2}\"${range_opts}" : ''}

    python /opt/cf-random/code/main.py --fname \${CF_RANDOM_FNAME_REL} --option ${meta.option}${main_opts}
    """
}
