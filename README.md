# Knee Prosthesis Designer

Herramienta en **Python** que genera automáticamente el **diseño CAD paramétrico** de una prótesis transfemoral de rodilla **policéntrica de 4 barras** a partir de la trayectoria deseada del **centro instantáneo de rotación (ICR)** entre 0° y 90° de flexión del ciclo de marcha.

El programa sintetiza el mecanismo, calcula las cargas según la norma **ISO 10328**, dimensiona los eslabones y pasadores, y actualiza un ensamblaje de **Autodesk Inventor** mediante su API. Un proceso de diseño que tomaba alrededor de **3 meses** se reduce a unos **30 minutos**.

> Proyecto de titulación de Ingeniería Mecánica — Universidad San Francisco de Quito (USFQ), 2025. Desarrollado en equipo como parte de la tesis *Desarrollo de Prótesis de Rodilla Policéntrica con Nivel de Movilidad K3*.

---

## Flujo de trabajo

```
Trayectoria ICR deseada (0–90° de flexión)
        │
        ▼
1. Síntesis del mecanismo de 4 barras ......... icr_synthesis.py
   (mínimos cuadrados IRLS con pérdida Huber y multistart)
        │
        ▼
2. Verificación de la trayectoria ICR lograda ... geometry_utils.py · plotting_utils.py
        │
        ▼
3. Reacciones según ISO 10328 ................... reaction_analysis.py
        │
        ▼
4. Cargas estáticas y de fatiga ................. forces_utils.py
        │
        ▼
5. Dimensionamiento de pasadores y eslabones .... pin_design.py · ab_bar_design.py · cd_bar_design.py
        │
        ▼
6. Actualización del CAD en Autodesk Inventor ... update_knee_cad.py  (API COM, pywin32)
        │
        ▼
results/<nombre>/   →  ensamblaje .iam + piezas .ipt listos
```

Todo el flujo se orquesta en `knee_designer/knee_pipeline.py` y se puede usar desde una **interfaz gráfica** (`ui/interface.py`, Tkinter + Matplotlib) donde el usuario ajusta la curva ICR y genera el diseño.

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `knee_designer/` | Paquete principal: síntesis, análisis de cargas, dimensionamiento y conexión con Inventor |
| `ui/` | Interfaz gráfica para definir la trayectoria ICR y ejecutar el flujo completo |
| `examples/` | Scripts de prueba de cada etapa (ICR, reacciones, fuerzas, diseño mecánico, CAD, flujo completo) |
| `cad/` | Ensamblaje paramétrico base de Inventor (`.iam` y piezas `.ipt`) |
| `results/knee_gui_E50_M50_C50/` | Ejemplo de un diseño generado por la herramienta |
| `matlab/` | Scripts de MATLAB usados en el diseño del mecanismo: ajuste ICR, métricas de error, animaciones, zona de estabilidad y fuerzas |
| `drawings/` | Planos técnicos en PDF de las piezas y del conjunto |

## Requisitos

- **Windows** con **Autodesk Inventor** instalado (necesario solo para la etapa de CAD)
- **Python 3.10+**

```bash
pip install -r requirements.txt
```

## Uso

```bash
# Interfaz gráfica
python ui/interface.py

# Flujo completo sin interfaz
python examples/pipeline_test.py
```

Los diseños generados se guardan en `results/<nombre_del_diseño>/`. El ensamblaje base de `cad/` nunca se modifica: la herramienta trabaja siempre sobre una copia.

## Resultados del proyecto

- Tiempo de diseño reducido de **~3 meses a ~30 minutos**.
- Validación estructural estática y de fatiga según **ISO 10328** con análisis por elementos finitos.
- Optimización topológica con **7.8 %** de reducción de masa sin comprometer la resistencia.
- Evaluación biomecánica con captura de movimiento **Vicon**: **4.9 %** de error frente a una prótesis comercial de referencia.

## Tecnologías

Python · NumPy · Matplotlib · Tkinter · Pillow · pywin32 · API de Autodesk Inventor · MATLAB · ANSYS · ISO 10328

## Autor

**Matías Loayza Correa** — Ingeniero Mecánico, USFQ  
[Portafolio](https://mleo22d.github.io) · [LinkedIn](https://www.linkedin.com/in/matias-loayza)
