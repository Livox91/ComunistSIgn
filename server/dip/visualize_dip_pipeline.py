"""
Visualise the DIP pipeline step-by-step on an input image.

Usage:
    python visualize_dip_pipeline.py <path_to_image>
    python visualize_dip_pipeline.py hand.jpg

Outputs:
    pipeline_steps.png   — side-by-side comparison of all stages
    pipeline_histograms.png — intensity histograms at each stage
"""
import sys
from pathlib import Path
import cv2
import numpy as np
import matplotlib.pyplot as plt

# Import the same processors the live server uses
sys.path.insert(0, str(Path(__file__).parent))
from preprocessing.white_balance import WhiteBalanceProcessor
from preprocessing.gamma import AdaptiveGammaCorrection
from preprocessing.histogram_eq import CLAHEProcessor
from preprocessing.bilateral_filter import BilateralFilterProcessor


def run_pipeline(img_bgr: np.ndarray):
    """Apply each step and return a list of (name, image) tuples."""
    stages = [('1. Original', img_bgr.copy())]

    wb = WhiteBalanceProcessor()
    img = wb.process(img_bgr.copy())
    stages.append(('2. + White Balance', img.copy()))

    gamma = AdaptiveGammaCorrection(target_mean=128.0)
    img = gamma.process(img)
    stages.append(('3. + Gamma Correction', img.copy()))

    clahe = CLAHEProcessor(clip_limit=2.0, tile_grid=(8, 8))
    img = clahe.process(img)
    stages.append(('4. + CLAHE', img.copy()))

    bilateral = BilateralFilterProcessor(d=9, sigma_color=75, sigma_space=75)
    img = bilateral.process(img)
    stages.append(('5. + Bilateral (FINAL)', img.copy()))

    return stages


def plot_stages(stages, out_path: Path):
    """Side-by-side BGR images at each stage."""
    n = len(stages)
    fig, axes = plt.subplots(1, n, figsize=(5 * n, 5))
    for ax, (name, img) in zip(axes, stages):
        ax.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        ax.set_title(name, fontsize=11, fontweight='bold')
        ax.axis('off')
    plt.suptitle('DIP Pipeline — Stage by Stage', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f'Saved {out_path}')


def plot_histograms(stages, out_path: Path):
    """Grayscale intensity histograms at each stage with mean + std annotations."""
    n = len(stages)
    fig, axes = plt.subplots(1, n, figsize=(5 * n, 4))
    for ax, (name, img) in zip(axes, stages):
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        ax.hist(gray.ravel(), bins=64, range=(0, 255),
                color='steelblue', edgecolor='none', alpha=0.85)
        ax.axvline(gray.mean(), color='red', lw=1.5,
                   label=f'μ={gray.mean():.0f}')
        ax.set_xlim(0, 255)
        ax.set_title(name, fontsize=10, fontweight='bold')
        ax.set_xlabel('Pixel intensity')
        ax.set_ylabel('Count')
        ax.legend(fontsize=8)
    plt.suptitle('Intensity Histogram at Each Stage', fontsize=13, fontweight='bold')
    plt.tight_layout()
    plt.savefig(out_path, dpi=150, bbox_inches='tight')
    print(f'Saved {out_path}')


def print_stats(stages):
    """Print mean, std, and per-channel means for each stage."""
    print(f'\n{"Stage":<28} {"Gray μ":>8} {"Gray σ":>8} {"B μ":>8} {"G μ":>8} {"R μ":>8}')
    print('-' * 70)
    for name, img in stages:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        b, g, r = img[..., 0].mean(), img[..., 1].mean(), img[..., 2].mean()
        print(f'{name:<28} {gray.mean():>8.1f} {gray.std():>8.1f} '
              f'{b:>8.1f} {g:>8.1f} {r:>8.1f}')


def main():
    if len(sys.argv) < 2:
        print('Usage: python visualize_dip_pipeline.py <image_path>')
        sys.exit(1)

    img_path = Path(sys.argv[1])
    if not img_path.exists():
        print(f'Error: {img_path} does not exist')
        sys.exit(1)

    img = cv2.imread(str(img_path))
    if img is None:
        print(f'Error: could not read {img_path} as an image')
        sys.exit(1)

    print(f'Loaded {img_path}, shape {img.shape}')

    stages = run_pipeline(img)
    print_stats(stages)

    out_dir = img_path.parent
    plot_stages(stages, out_dir / 'pipeline_steps.png')
    plot_histograms(stages, out_dir / 'pipeline_histograms.png')

    # Also save each stage as its own image for inspection
    for name, img_stage in stages:
        slug = name.split('. ', 1)[1].replace(' ', '_').replace('+', '').replace('__', '_')
        cv2.imwrite(str(out_dir / f'stage_{slug}.png'), img_stage)
    print(f'\nDone. Drop your image into {out_dir} and re-run.')


if __name__ == '__main__':
    main()
