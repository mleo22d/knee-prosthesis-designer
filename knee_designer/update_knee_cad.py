import os
import win32com.client as win32

# Raíz del repositorio (rutas relativas, funcionan en cualquier computadora)
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def update_knee_prosthesis_assembly(
    d_hole, l_a, w_ab, t_ab, l_c, w_cd, t_cd,
    theta_4, l_d, phi_AD, theta_3, l_b,
    asm_path: str = os.path.join(REPO_ROOT, "cad", "knee_prosthesis_assembly.iam"),
    result_name: str = "run_001",
):
    """
    1) NO modifica el ensamblaje original.
    2) Crea una copia en results (iam + ipt) y SOLO esa copia se actualiza.
    """

    # ------------------------------------------
    # Iniciar Inventor y abrir ensamblaje base
    # ------------------------------------------
    inv = win32.Dispatch("Inventor.Application")
    inv.Visible = True
    # Suprime prompts (siempre acepta la opción por defecto)
    inv.SilentOperation = True

    asm_doc = inv.Documents.Open(asm_path)

    # ------------------------------------------
    # Crear carpeta en results y ruta de la copia
    # ------------------------------------------
    results_root = os.path.join(REPO_ROOT, "results")
    result_folder = os.path.join(results_root, result_name)
    os.makedirs(result_folder, exist_ok=True)

    new_asm_path = os.path.join(result_folder, f"{result_name}.iam")
    print(f"Guardando copia del ensamblaje en: {new_asm_path}")

    # Guardar directamente una COPIA del ensamblaje base
    asm_doc.SaveAs(new_asm_path, True)

    # Cerrar el ensamblaje original SIN guardar cambios
    asm_doc.Close(False)

    # ------------------------------------------
    # Abrir la copia y trabajar SOLO sobre ella
    # ------------------------------------------
    result_asm_doc = inv.Documents.Open(new_asm_path)
    result_asm_def = result_asm_doc.ComponentDefinition

    # ------------------------------------------
    # 1) Actualizar parámetros en las piezas de la copia
    # ------------------------------------------
    for occ in result_asm_def.Occurrences:
        part_doc = occ.Definition.Document
        name = part_doc.DisplayName.lower()

        if not name.endswith(".ipt"):
            continue

        params = part_doc.ComponentDefinition.Parameters

        if "bar_ab" in name:
            print(f"Actualizando {name} ...")
            try:
                params.Item("d_hole").Expression = f"{d_hole} mm"
                params.Item("l_a").Expression    = f"{l_a} mm"
                params.Item("w_ab").Expression   = f"{w_ab} mm"
                params.Item("t_ab").Expression   = f"{t_ab} mm"
                part_doc.Update()
                print("  -> bar_ab OK")
            except Exception as e:
                print("  [ERROR bar_ab]:", e)

        elif "bar_dc" in name:
            print(f"Actualizando {name} ...")
            try:
                params.Item("d_hole").Expression = f"{d_hole} mm"
                params.Item("l_c").Expression    = f"{l_c} mm"
                params.Item("w_cd").Expression   = f"{w_cd} mm"
                params.Item("t_cd").Expression   = f"{t_cd} mm"
                part_doc.Update()
                print("  -> bar_dc OK")
            except Exception as e:
                print("  [ERROR bar_dc]:", e)

        elif "base_ad" in name:
            print(f"Actualizando {name} ...")
            try:
                params.Item("d_hole").Expression  = f"{d_hole} mm"
                params.Item("phi_AD").Expression  = f"{phi_AD} deg"
                params.Item("l_d").Expression     = f"{l_d} mm"
                part_doc.Update()
                print("  -> base_ad OK")
            except Exception as e:
                print("  [ERROR base_ad]:", e)

        elif "bar_bc" in name:
            print(f"Actualizando {name} ...")
            try:
                params.Item("d_hole").Expression      = f"{d_hole} mm"
                params.Item("theta_3").Expression     = f"{theta_3} deg"
                params.Item("theta_4").Expression     = f"{theta_4} deg"
                params.Item("l_b").Expression         = f"{l_b} mm"
                params.Item("w_cd").Expression        = f"{w_cd} mm"
                part_doc.Update()
                print("  -> bar_bc OK")
            except Exception as e:
                print("  [ERROR bar_bc]:", e)

    # ------------------------------------------
    # 2) Copiar todas las piezas .ipt a la carpeta del resultado
    #    y hacer que el ensamblaje apunte a esas copias
    # ------------------------------------------
    original_to_copy = {}

    for occ in result_asm_def.Occurrences:
        part_doc = occ.Definition.Document
        full_name = part_doc.FullFileName
        ext = os.path.splitext(full_name)[1].lower()

        if ext != ".ipt":
            continue

        file_name = os.path.basename(full_name)

        # Si ya está en la carpeta de resultados, solo mapear y seguir
        if os.path.dirname(full_name) == result_folder:
            print(f"Pieza ya en carpeta de resultado, se reutiliza: {full_name}")
            original_to_copy[file_name] = full_name
            continue

        # Primera vez que vemos esta pieza -> crear copia
        if file_name not in original_to_copy:
            new_part_path = os.path.join(result_folder, file_name)
            print(f"Copiando pieza: {full_name} -> {new_part_path}")
            part_doc.SaveAs(new_part_path, True)
            original_to_copy[file_name] = new_part_path

        copy_path = original_to_copy[file_name]
        print(f"Reemplazando ocurrencia {occ.Name} con {copy_path}")
        occ.Replace(copy_path, True)

    result_asm_doc.Update()
    result_asm_doc.Save2(True)

    print("\nCopia completa (iam + ipt) actualizada y guardada.\n")
