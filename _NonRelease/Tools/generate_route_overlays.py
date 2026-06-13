from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Iterable

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi
from skimage.morphology import skeletonize


ROOT = r"E:\\Program\\YiboBeastPaths"
SOURCES_DIR = os.path.join(ROOT, "Assets", "ExtractedRoutes", "Sources")
OVERLAYS_DIR = os.path.join(ROOT, "Assets", "ExtractedRoutes", "Overlays")
BITMAP_MASTERS_DIR = os.path.join(ROOT, "Assets", "ExtractedRoutes", "Masters")
ROUTE_OVERLAYS_LUA = os.path.join(ROOT, "RouteOverlays.lua")


@dataclass
class AutoConfig:
    targets: list[tuple[int, int, int]]
    tolerance: int
    min_area: int = 14
    dilate: int = 1
    clear_rects: list[tuple[int, int, int, int]] = field(default_factory=list)


@dataclass
class EllipseConfig:
    fill: tuple[int, int, int, int]
    outline: tuple[int, int, int, int]
    width: int
    box: tuple[int, int, int, int]


@dataclass
class RouteConfig:
    pet_id: int
    slug: str
    map_id: int
    mode: str
    bitmap_master: str | None = None
    bitmap_color: tuple[int, int, int, int] | None = None
    bitmap_grow: int = 0
    bitmap_blur: float = 0.0
    endcap_trim: float = 0.0
    auto: AutoConfig | None = None
    ellipse: EllipseConfig | None = None


ROUTES: list[RouteConfig] = [
    RouteConfig(
        pet_id=50817,
        slug="bloodtooth",
        map_id=418,
        mode="auto",
        endcap_trim=0.50,
        auto=AutoConfig(targets=[(245, 232, 35)], tolerance=55),
    ),
    RouteConfig(
        pet_id=66522,
        slug="bombyx",
        map_id=418,
        mode="ellipse",
        ellipse=EllipseConfig(
            fill=(176, 84, 163, 150),
            outline=(196, 108, 184, 235),
            width=5,
            box=(192, 178, 404, 286),
        ),
    ),
    RouteConfig(
        pet_id=50816,
        slug="bristlespine",
        map_id=379,
        mode="bitmap_master",
        bitmap_master="50816_bristlespine_master.png",
        bitmap_color=(32, 241, 27, 235),
        bitmap_grow=0,
        bitmap_blur=0.0,
        endcap_trim=0.50,
    ),
    RouteConfig(
        pet_id=50822,
        slug="glimmer",
        map_id=371,
        mode="auto",
        endcap_trim=0.50,
        auto=AutoConfig(
            targets=[(240, 20, 18)],
            tolerance=65,
            min_area=35,
            clear_rects=[(0, 170, 210, 250)],
        ),
    ),
    RouteConfig(
        pet_id=50818,
        slug="hexapos",
        map_id=422,
        mode="bitmap_master",
        bitmap_master="50818_hexapos_master.png",
        bitmap_color=(224, 217, 255, 235),
        bitmap_grow=0,
        bitmap_blur=0.0,
        endcap_trim=0.50,
    ),
    RouteConfig(
        pet_id=50812,
        slug="patrannache",
        map_id=376,
        mode="bitmap_master",
        bitmap_master="50812_patrannache_master.png",
        bitmap_color=(217, 27, 210, 235),
        bitmap_grow=0,
        bitmap_blur=0.0,
        endcap_trim=0.50,
    ),
    RouteConfig(
        pet_id=50813,
        slug="portent",
        map_id=390,
        mode="bitmap_master",
        bitmap_master="50813_portent_master.png",
        bitmap_color=(150, 50, 131, 235),
        bitmap_grow=0,
        bitmap_blur=0.0,
        endcap_trim=0.50,
    ),
    RouteConfig(
        pet_id=50820,
        slug="rockhide",
        map_id=388,
        mode="bitmap_master",
        bitmap_master="50820_rockhide_master.png",
        bitmap_color=(230, 74, 164, 235),
        bitmap_grow=0,
        bitmap_blur=0.0,
        endcap_trim=0.50,
    ),
    RouteConfig(
        pet_id=50821,
        slug="savage",
        map_id=371,
        mode="auto",
        endcap_trim=0.50,
        auto=AutoConfig(targets=[(34, 235, 232)], tolerance=75),
    ),
    RouteConfig(
        pet_id=50811,
        slug="stompy",
        map_id=379,
        mode="bitmap_master",
        bitmap_master="50811_stompy_master.png",
        bitmap_color=(30, 32, 119, 235),
        bitmap_grow=0,
        bitmap_blur=0.0,
        endcap_trim=0.50,
    ),
]


def ensure_dirs() -> None:
    os.makedirs(OVERLAYS_DIR, exist_ok=True)
    os.makedirs(BITMAP_MASTERS_DIR, exist_ok=True)


def load_bitmap_master(name: str, color: tuple[int, int, int, int], grow: int = 0, blur: float = 0.0) -> Image.Image:
    path = os.path.join(BITMAP_MASTERS_DIR, name)
    master = Image.open(path).convert("RGBA")
    alpha = master.getchannel("A")

    if grow > 0:
        for _ in range(grow):
            alpha = alpha.filter(ImageFilter.MaxFilter(3))

    if blur > 0:
        alpha = alpha.filter(ImageFilter.GaussianBlur(radius=blur))

    tinted = Image.new("RGBA", master.size, color)
    tinted.putalpha(alpha)
    return tinted


def extract_auto_mask(rgb: np.ndarray, cfg: AutoConfig) -> np.ndarray:
    arr = rgb.astype(np.int32)
    mask = np.zeros(rgb.shape[:2], dtype=bool)

    for target in cfg.targets:
        diff = np.sqrt(((arr - np.array(target, dtype=np.int32)) ** 2).sum(axis=2))
        mask |= diff <= cfg.tolerance

    if cfg.dilate:
        mask = ndi.binary_dilation(mask, iterations=cfg.dilate)

    for left, top, right, bottom in cfg.clear_rects:
        mask[top:bottom, left:right] = False

    labels, n = ndi.label(mask)
    if not n:
        return mask

    areas = ndi.sum(mask, labels, range(1, n + 1))
    keep = np.zeros_like(mask)
    for idx, area in enumerate(areas, start=1):
        ys, xs = np.where(labels == idx)
        if not len(xs):
            continue
        span_x = xs.max() - xs.min()
        span_y = ys.max() - ys.min()
        if area >= cfg.min_area and (span_x >= 8 or span_y >= 8):
            keep |= labels == idx

    return keep


def draw_ellipse(size: tuple[int, int], cfg: EllipseConfig) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.ellipse(cfg.box, fill=cfg.fill, outline=cfg.outline, width=cfg.width)
    return image


def trim_endcaps(image: Image.Image, strength: float) -> Image.Image:
    if strength <= 0:
        return image

    rgba = np.array(image.convert("RGBA"), dtype=np.uint8)
    alpha = rgba[:, :, 3]
    mask = alpha > 0
    if not mask.any():
        return image

    skeleton = skeletonize(mask)
    if not skeleton.any():
        return image

    neighbors = ndi.convolve(skeleton.astype(np.uint8), np.ones((3, 3), dtype=np.uint8), mode="constant", cval=0)
    endpoints = np.argwhere(skeleton & (neighbors == 2))
    if len(endpoints) == 0:
        return image

    distance = ndi.distance_transform_edt(mask)
    trimmed = mask.copy()
    height, width = mask.shape

    for y, x in endpoints:
        radius = int(round(distance[y, x] * strength))
        radius = max(1, min(8, radius))
        if radius <= 0:
            continue

        y0 = max(0, y - 1)
        y1 = min(height, y + 2)
        x0 = max(0, x - 1)
        x1 = min(width, x + 2)
        local = skeleton[y0:y1, x0:x1].copy()
        local[y - y0, x - x0] = False
        neighbor_points = np.argwhere(local)

        dir_y = 0.0
        dir_x = 0.0
        if len(neighbor_points):
            ny, nx = neighbor_points[0]
            dir_y = float((y0 + ny) - y)
            dir_x = float((x0 + nx) - x)
            norm = max(1.0, (dir_y * dir_y + dir_x * dir_x) ** 0.5)
            dir_y /= norm
            dir_x /= norm

        yy, xx = np.ogrid[:height, :width]
        cut_disk = (yy - y) ** 2 + (xx - x) ** 2 <= radius * radius
        trimmed[cut_disk] = False

        restore_radius = max(1, int(round(radius * 0.38)))
        restore_shift = max(1, int(round(radius * 0.80)))
        cy = int(round(y + dir_y * restore_shift))
        cx = int(round(x + dir_x * restore_shift))
        restore_disk = (yy - cy) ** 2 + (xx - cx) ** 2 <= restore_radius * restore_radius
        trimmed[restore_disk] |= mask[restore_disk]

    rgba[:, :, 3] = np.where(trimmed, alpha, 0).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def auto_overlay(source_path: str, cfg: AutoConfig) -> Image.Image:
    image = Image.open(source_path).convert("RGB")
    rgb = np.array(image)
    mask = extract_auto_mask(rgb, cfg)
    rgba = np.zeros((rgb.shape[0], rgb.shape[1], 4), dtype=np.uint8)
    rgba[mask, :3] = rgb[mask]
    rgba[mask, 3] = 235
    return Image.fromarray(rgba)


def write_route_overlays_lua(routes: Iterable[RouteConfig]) -> None:
    lines = [
        "local addonName, ns = ...",
        "",
        "ns.routeOverlays = {",
    ]
    for route in routes:
        lines.append(f"    [{route.pet_id}] = {{")
        lines.append(f"        slug = \"{route.slug}\",")
        lines.append(f"        mapID = {route.map_id},")
        lines.append(f"        source = \"Assets\\\\ExtractedRoutes\\\\Sources\\\\{route.slug}.jpg\",")
        lines.append(
            f"        texture = \"Interface\\\\AddOns\\\\YiboBeastPaths\\\\Assets\\\\ExtractedRoutes\\\\Overlays\\\\{route.pet_id}_{route.slug}\","
        )
        lines.append("    },")
    lines.append("}")
    lines.append("")

    with open(ROUTE_OVERLAYS_LUA, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))

def main() -> None:
    ensure_dirs()

    for route in ROUTES:
        if route.mode == "auto" and route.auto:
            source_path = os.path.join(SOURCES_DIR, route.slug + ".jpg")
            overlay = auto_overlay(source_path, route.auto)
        elif route.mode == "bitmap_master" and route.bitmap_master:
            overlay = load_bitmap_master(
                route.bitmap_master,
                route.bitmap_color or (255, 255, 255, 235),
                grow=route.bitmap_grow,
                blur=route.bitmap_blur,
            )
        elif route.mode == "ellipse" and route.ellipse:
            source_path = os.path.join(SOURCES_DIR, route.slug + ".jpg")
            source = Image.open(source_path).convert("RGB")
            overlay = draw_ellipse(source.size, route.ellipse)
        else:
            raise ValueError(f"Unsupported mode for {route.slug}")

        overlay = trim_endcaps(overlay, route.endcap_trim)
        output_path = os.path.join(OVERLAYS_DIR, f"{route.pet_id}_{route.slug}.tga")
        overlay.save(output_path)

    write_route_overlays_lua(ROUTES)


if __name__ == "__main__":
    main()
