#!/bin/bash
# submit_gpu_jobs.sh
# Launch up to 2 GPU tests in parallel, cycling through:
#   A2      (vnc)
#   Titan   (gpu)
#   Quadro  (gpu)
#   3090    (gpu)
#   A5000   (gpu)
#   A5500   (gpu)
#
# Requires: train.py in same dir.

# Configuration
GPUS=(a2 titanrtx quadrortx geforce3090 a5000 a5500)
PARTS=(vnc gpu gpu gpu gpu gpu)
CPUS=(amd intel intel amd amd amd)
MAX_PARALLEL=2
POLL_INTERVAL=5

declare -a JOBIDS=()

# Prune JOBIDS by checking actual running jobs for $USER
_prune_running_jobs() {
  local running
  running=$(squeue -h -u "$USER" -o "%A")
  local newlist=()
  for jid in "${JOBIDS[@]}"; do
    if echo "$running" | grep -qx "$jid"; then
      newlist+=("$jid")
    fi
  done
  JOBIDS=("${newlist[@]}")
}

for i in "${!GPUS[@]}"; do
  gpu=${GPUS[$i]}
  part=${PARTS[$i]}
  cpu=${CPUS[$i]}

  # wait until we have a free slot
  while :; do
    _prune_running_jobs
    if (( ${#JOBIDS[@]} < MAX_PARALLEL )); then
      break
    fi
    sleep "$POLL_INTERVAL"
  done

  # create and submit the sbatch on the fly
  sbatch_id=$(sbatch --parsable <<EOF
#!/bin/bash
#SBATCH --job-name=test_${gpu}
#SBATCH --partition=${part}
#SBATCH --gres=gpu:${gpu}:1
#SBATCH --constraint=${cpu}
#SBATCH --cpus-per-task=1
#SBATCH --gres-flags=enforce-binding
#SBATCH --mem=50G
#SBATCH --time=03:00:00
#SBATCH -o ${gpu}-%j.out
#SBATCH -e ${gpu}-%j.err
#SBATCH -N 1

module load cuda python
python3 train.py
EOF
)
  echo "Submitted ${gpu} test as job ${sbatch_id}"
  JOBIDS+=("$sbatch_id")
done

# wait for remaining jobs
echo "Waiting for all ${#JOBIDS[@]} remaining jobs to finish..."
while (( ${#JOBIDS[@]} )); do
  _prune_running_jobs
  sleep "$POLL_INTERVAL"
done

echo "✅ All GPU tests done. Now ask yourself, did it work ... ?"

