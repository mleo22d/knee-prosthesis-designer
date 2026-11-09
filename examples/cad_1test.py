import os
import win32com.client as win32

def update_inventor_parameters():
    # Ruta completa del archivo IPT
    filepath = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "cad", "bar_ab.ipt")

    # Inicializar Inventor
    inv = win32.Dispatch("Inventor.Application")
    inv.Visible = True  # opcional: para ver actualización en vivo

    # Abrir el documento
    doc = inv.Documents.Open(filepath)

    # Acceso a parámetros
    params = doc.ComponentDefinition.Parameters

    print("=== Parámetros actuales ===")
    for p in params:
        try:
            print(p.Name, "=", p.Value)
        except:
            pass

    # ---- ACTUALIZAR PARÁMETROS ----
    # Aquí ajusta los valores como necesites
    new_values = {
        "d0": "80 mm",
        "d1": "70 mm",
        "d2": "12 mm",
        "d3": "20 mm",
    }

    for name, value in new_values.items():
        try:
            param = params.Item(name)
            param.Expression = value
            print(f"[OK] {name} actualizado a {value}")
        except Exception as e:
            print(f"[ERROR] No se pudo modificar {name}:", e)

    # Actualizar el modelo
    doc.Update()

    # Guardar el archivo actualizado
    output_path = filepath.replace(".ipt", "_updated.ipt")
    doc.SaveAs(output_path, True)

    print("\nArchivo guardado en:", output_path)

if __name__ == "__main__":
    update_inventor_parameters()
