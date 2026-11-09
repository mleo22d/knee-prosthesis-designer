import tkinter as tk
from tkinter import ttk
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import numpy as np
from PIL import Image

import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from knee_designer.knee_pipeline import run_pipeline_from_icr

class RodillaInterface:
    def __init__(self, root):
        self.root = root
        self.root.title("Personalizador de Rodilla Policéntrica")
        self.root.geometry("1200x800")  # Ventana más grande
        
        # Parámetros iniciales
        self.estabilidad = 50
        self.movilidad = 50
        self.rotacion = 50
        
        # Puntos base del ICR en coordenadas LOCALES (proporcionados)
        self.x_icr_local = np.array([10.8400846674782, 62.3275300284005, 69.2773414748650, 70.0665600058893,
                                    69.2277898325509, 67.9184557589887, 66.4902659542730, 65.0489837353969,
                                    63.6171761217445, 62.1889643555652, 60.7501425224522, 59.2860659890371,
                                    57.7849720653416, 56.2395318852723, 54.6476628866937])-14.4
        
        self.y_icr_local = np.array([169.125206425539, 69.9871895391235, 41.1498656233414, 26.2069366952281,
                                    17.2139757273866, 11.3566148149569, 7.34016233171650, 4.48344598673585,
                                    2.39463173903149, 0.832182299983874, -0.361932853583941, -1.29696869022762,
                                    -2.05253412938474, -2.68954099091497, -3.25657359552798])-43.4
        
        # Guardar puntos originales para referencia
        self.x_icr_original = self.x_icr_local.copy()
        self.y_icr_original = self.y_icr_local.copy()
        
        # Origen del sistema local en coordenadas GLOBALES
        self.origen_local_global = (250/3, 500)  # (83.33, 500)
        
        # Parámetros de la imagen de fondo
        self.imagen_fondo_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "im_pierna2.png")  # Imagen de fondo opcional
        self.imagen_posicion = (-30, -10)  # (x, y) posición de la esquina inferior izquierda
        self.imagen_dimensiones = (300, 600)  # (ancho, alto) en mm
        self.imagen_opacidad = 0.2  # Opacidad de la imagen (0.0 a 1.0)
        
        # Configurar estilo de matplotlib con fuentes más grandes
        plt.rcParams.update({
            'font.size': 14,
            'axes.titlesize': 16,
            'axes.labelsize': 14,
            'xtick.labelsize': 12,
            'ytick.labelsize': 12,
            'legend.fontsize': 13,
            'font.family': 'DejaVu Sans'
        })
        
        self.setup_ui()
        self.update_plot()
    
    def convertir_local_a_global(self, x_local, y_local):
        """Convierte coordenadas locales a coordenadas globales"""
        x_global = x_local + self.origen_local_global[0]
        y_global = y_local + self.origen_local_global[1]
        return x_global, y_global
    
    def convertir_global_a_local(self, x_global, y_global):
        """Convierte coordenadas globales a coordenadas locales"""
        x_local = x_global - self.origen_local_global[0]
        y_local = y_global - self.origen_local_global[1]
        return x_local, y_local
    
    def setup_ui(self):
        # Frame principal
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configurar grid para centrar los paneles
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=2)  # Más peso para el gráfico
        main_frame.rowconfigure(0, weight=1)
        
        # Panel de parámetros (izquierda)
        self.setup_parameters_panel(main_frame)
        
        # Panel de visualización (derecha)
        self.setup_visualization_panel(main_frame)
    
    def setup_parameters_panel(self, parent):
        # Frame de parámetros - centrado verticalmente
        params_frame = ttk.LabelFrame(parent, text="Parámetros de Diseño", padding="25")
        params_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=(0, 20))
        
        # Configurar estilos personalizados
        self.configure_styles()
        
        # Título más prominente
        title_label = ttk.Label(params_frame, text="AJUSTE DE PARÁMETROS", style='Title.TLabel')
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 35))
        
        # Estabilidad: Controla el desplazamiento vertical con efecto no lineal
        ttk.Label(params_frame, text="ESTABILIDAD:", style='Parameter.TLabel').grid(row=1, column=0, sticky=tk.W, pady=18)
        self.estabilidad_var = tk.IntVar(value=self.estabilidad)
        estabilidad_scale = ttk.Scale(params_frame, from_=0, to=100, 
                                    variable=self.estabilidad_var,
                                    command=self.on_parameter_change,
                                    orient=tk.HORIZONTAL,
                                    length=240,
                                    style='GameSlider.Horizontal.TScale')
        estabilidad_scale.grid(row=1, column=1, sticky=(tk.W, tk.E), pady=18)
        self.estabilidad_label = ttk.Label(params_frame, text=f"{self.estabilidad}%", style='Value.TLabel')
        self.estabilidad_label.grid(row=1, column=2, padx=(20, 0))
        
        # Movilidad: Controla el desplazamiento horizontal y escala
        ttk.Label(params_frame, text="MOVILIDAD:", style='Parameter.TLabel').grid(row=2, column=0, sticky=tk.W, pady=18)
        self.movilidad_var = tk.IntVar(value=self.movilidad)
        movilidad_scale = ttk.Scale(params_frame, from_=0, to=100, 
                                  variable=self.movilidad_var,
                                  command=self.on_parameter_change,
                                  orient=tk.HORIZONTAL,
                                  length=240,
                                  style='GameSlider.Horizontal.TScale')
        movilidad_scale.grid(row=2, column=1, sticky=(tk.W, tk.E), pady=18)
        self.movilidad_label = ttk.Label(params_frame, text=f"{self.movilidad}%", style='Value.TLabel')
        self.movilidad_label.grid(row=2, column=2, padx=(20, 0))
        
        # Curvatura: Controla la forma de la trayectoria
        ttk.Label(params_frame, text="CURVATURA:", style='Parameter.TLabel').grid(row=3, column=0, sticky=tk.W, pady=18)
        self.rotacion_var = tk.IntVar(value=self.rotacion)
        rotacion_scale = ttk.Scale(params_frame, from_=0, to=100, 
                                 variable=self.rotacion_var,
                                 command=self.on_parameter_change,
                                 orient=tk.HORIZONTAL,
                                 length=240,
                                 style='GameSlider.Horizontal.TScale')
        rotacion_scale.grid(row=3, column=1, sticky=(tk.W, tk.E), pady=18)
        self.rotacion_label = ttk.Label(params_frame, text=f"{self.rotacion}%", style='Value.TLabel')
        self.rotacion_label.grid(row=3, column=2, padx=(20, 0))
        
        # Descripción de curvatura CORREGIDA
        curvatura_desc = ttk.Label(params_frame, 
                                 text="0%: Lineal | 50%: Original | 100%: Circular",
                                 style='Description.TLabel',
                                 foreground='#666666')
        curvatura_desc.grid(row=4, column=0, columnspan=3, pady=(15, 0))
        
        # Botones - grandes y con colores PERMANENTES
        button_frame = ttk.Frame(params_frame)
        button_frame.grid(row=5, column=0, columnspan=3, pady=50)
        
        # Botón ROJO permanente
        reset_button = tk.Button(button_frame, text="🔄 RESTABLECER", 
                               command=self.reset_parameters,
                               font=('Arial', 12, 'bold'),
                               bg='#e74c3c',  # Rojo permanente
                               fg='white',
                               activebackground='#c0392b',  # Rojo oscuro al hacer clic
                               activeforeground='white',
                               relief='raised',
                               bd=3,
                               padx=25,
                               pady=12)
        reset_button.pack(side=tk.LEFT, padx=20)
        
        # Botón VERDE permanente
        save_button = tk.Button(button_frame, text="💾 GUARDAR", 
                              command=self.guardar_configuracion,
                              font=('Arial', 12, 'bold'),
                              bg='#27ae60',  # Verde permanente
                              fg='white',
                              activebackground='#229954',  # Verde oscuro al hacer clic
                              activeforeground='white',
                              relief='raised',
                              bd=3,
                              padx=25,
                              pady=12)
        save_button.pack(side=tk.LEFT, padx=20)
        
        # Configurar pesos para centrar verticalmente
        params_frame.rowconfigure(0, weight=1)
        params_frame.rowconfigure(1, weight=0)
        params_frame.rowconfigure(2, weight=0)
        params_frame.rowconfigure(3, weight=0)
        params_frame.rowconfigure(4, weight=0)
        params_frame.rowconfigure(5, weight=1)
        params_frame.columnconfigure(1, weight=1)
    
    def configure_styles(self):
        """Configura los estilos personalizados para la interfaz"""
        style = ttk.Style()
        
        # Estilo para el título
        style.configure('Title.TLabel', 
                       font=('Arial', 16, 'bold'),
                       foreground='#2c3e50')
        
        # Estilo para las etiquetas de parámetros
        style.configure('Parameter.TLabel', 
                       font=('Arial', 12, 'bold'),
                       foreground='#34495e')
        
        # Estilo para los valores
        style.configure('Value.TLabel', 
                       font=('Arial', 12, 'bold'),
                       foreground='#2980b9')
        
        # Estilo para descripción
        style.configure('Description.TLabel', 
                       font=('Arial', 10),
                       foreground='#666666')
        
        # Estilo para sliders tipo juego
        style.configure('GameSlider.Horizontal.TScale',
                       background='#ecf0f1')
        
        # Configurar el trough (canal) del slider
        style.map('GameSlider.Horizontal.TScale',
                 background=[('active', '#bdc3c7'),
                           ('!active', '#ecf0f1')])
    
    def setup_visualization_panel(self, parent):
        # Frame de visualización
        viz_frame = ttk.LabelFrame(parent, text="Visualización de la Rodilla", padding="20")
        viz_frame.grid(row=0, column=1, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Crear figura de matplotlib más grande
        self.fig, self.ax = plt.subplots(figsize=(10, 8))
        self.canvas = FigureCanvasTkAgg(self.fig, viz_frame)
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
    
    def on_parameter_change(self, event=None):
        # Actualizar valores
        self.estabilidad = self.estabilidad_var.get()
        self.movilidad = self.movilidad_var.get()
        self.rotacion = self.rotacion_var.get()
        
        # Actualizar labels
        self.estabilidad_label.config(text=f"{self.estabilidad}%")
        self.movilidad_label.config(text=f"{self.movilidad}%")
        self.rotacion_label.config(text=f"{self.rotacion}%")
        
        # Actualizar gráfico
        self.update_plot()
    
    def suavizar_curva(self, x, y, num_puntos=50):
        """Suaviza la curva usando interpolación lineal simple"""
        if len(x) < 2:
            return x, y
            
        # Calcular distancia acumulada a lo largo de la curva
        distancias = np.zeros(len(x))
        for i in range(1, len(x)):
            distancias[i] = distancias[i-1] + np.sqrt((x[i]-x[i-1])**2 + (y[i]-y[i-1])**2)
        
        # Crear puntos equidistantes a lo largo de la curva
        dist_suave = np.linspace(0, distancias[-1], num_puntos)
        
        # Interpolación lineal
        x_suave = np.interp(dist_suave, distancias, x)
        y_suave = np.interp(dist_suave, distancias, y)
        
        return x_suave, y_suave
    
    def dibujar_imagen_fondo(self):
        """Dibuja la imagen de fondo con los parámetros configurados"""
        try:
            # Cargar la imagen
            img = Image.open(self.imagen_fondo_path)
            
            # Extraer posición y dimensiones
            x_pos, y_pos = self.imagen_posicion
            ancho, alto = self.imagen_dimensiones
            
            # Dibujar la imagen
            self.ax.imshow(img, 
                          extent=[x_pos, x_pos + ancho, y_pos, y_pos + alto], 
                          alpha=self.imagen_opacidad,
                          aspect='auto')
            
        except FileNotFoundError:
            print(f"Advertencia: No se pudo cargar la imagen {self.imagen_fondo_path}")
        except Exception as e:
            print(f"Error al cargar la imagen: {e}")
    
    def calcular_trayectoria_icr(self):
        """Calcula la trayectoria del ICR modificando la curva base en coordenadas LOCALES"""
        
        # Trabajar en coordenadas LOCALES
        x_local = self.x_icr_original.copy()
        y_local = self.y_icr_original.copy()
        
        # ESTABILIDAD: Controla el desplazamiento vertical con efecto no lineal
        desplazamiento_y = (self.estabilidad - 50) / 50.0 * 60  # -60 a +60 mm en Y local
        escala_y = 1.0 + (self.estabilidad - 50) / 100.0  # 0.5 a 1.5
        
        # Aplicar transformación vertical local con efecto no lineal
        centro_y_local = np.mean(y_local)
        y_local = (y_local - centro_y_local) * escala_y + centro_y_local + desplazamiento_y
        
        # MOVILIDAD: Controla el desplazamiento horizontal LOCAL y escala
        desplazamiento_x = (self.movilidad - 50) / 50.0 * 40  # -40 a +40 mm en X local
        escala_x = 1.0 + (self.movilidad - 50) / 100.0  # 0.5 a 1.5
        
        # Aplicar transformación horizontal local
        centro_x_local = np.mean(x_local)
        x_local = (x_local - centro_x_local) * escala_x + centro_x_local + desplazamiento_x
        
        # CURVATURA: Controla la forma de la trayectoria
        curvatura_factor = (self.rotacion - 50) / 50.0  # -1 a +1
        
        if curvatura_factor != 0:
            centro_curva = np.array([np.mean(x_local), np.mean(y_local)])
            
            # Convertir a coordenadas polares relativas al centro
            x_rel = x_local - centro_curva[0]
            y_rel = y_local - centro_curva[1]
            
            angulos = np.arctan2(y_rel, x_rel)
            radios = np.sqrt(x_rel**2 + y_rel**2)
            
            if curvatura_factor < 0:
                # 0% a 50%: Transición de LINEAL a ORIGINAL
                factor_lineal = abs(curvatura_factor)  # 1 a 0
                
                # Para hacerlo más lineal, reducimos la variación angular
                radios_modificados = radios * (1 - factor_lineal * 0.5 * np.sin(angulos))
                
            else:
                # 50% a 100%: Transición de ORIGINAL a CIRCULAR
                factor_circular = curvatura_factor  # 0 a 1
                
                # Para hacerlo circular, igualamos todos los radios al radio promedio
                radio_promedio = np.mean(radios)
                radios_modificados = radios * (1 - factor_circular) + radio_promedio * factor_circular
            
            # Convertir de vuelta a coordenadas cartesianas
            x_local = centro_curva[0] + radios_modificados * np.cos(angulos)
            y_local = centro_curva[1] + radios_modificados * np.sin(angulos)
        
        # Suavizar la curva en coordenadas locales
        x_local_suave, y_local_suave = self.suavizar_curva(x_local, y_local, 50)
        
        # Convertir a coordenadas globales para visualización
        x_global, y_global = self.convertir_local_a_global(x_local_suave, y_local_suave)
        x_puntos_global, y_puntos_global = self.convertir_local_a_global(x_local, y_local)
        
        return x_global, y_global, x_puntos_global, y_puntos_global, x_local, y_local
    
    def dibujar_lineas_fuerza(self):
        """Dibuja las líneas de fuerza desde el talón y la punta"""
        # Puntos de aplicación de fuerza
        talon_x, talon_y = 0, 0
        punta_x, punta_y = 250, 0
        
        # Ángulos biomecánicamente realistas para las líneas de fuerza (72.5° y 107.5°)
        angulo_talon = np.radians(72.5)   # 72.5 grados desde horizontal
        angulo_punta = np.radians(107.5)  # 107.5 grados desde horizontal
        
        # Extender las líneas hasta 600 mm de altura para asegurar que se crucen
        altura_max = 600
        
        # Calcular puntos finales de las líneas
        talon_final_x = talon_x + altura_max / np.tan(angulo_talon)
        talon_final_y = altura_max
        
        punta_final_x = punta_x - altura_max / np.tan(np.pi - angulo_punta)
        punta_final_y = altura_max
        
        # Calcular punto de intersección de las líneas
        m_talon = np.tan(angulo_talon)  # Pendiente línea talón
        m_punta = np.tan(angulo_punta)  # Pendiente línea punta
        
        # Resolver sistema de ecuaciones para encontrar intersección
        x_interseccion = (m_punta * punta_x - m_talon * talon_x) / (m_punta - m_talon)
        y_interseccion = m_talon * (x_interseccion - talon_x) + talon_y
        
        # Dibujar líneas de fuerza extendidas (verde claro con poca opacidad)
        self.ax.plot([talon_x, talon_final_x], [talon_y, talon_final_y], 
                    color='lightgreen', linewidth=2, alpha=0.4, label='Líneas de Fuerza')
        self.ax.plot([punta_x, punta_final_x], [punta_y, punta_final_y], 
                    color='lightgreen', linewidth=2, alpha=0.4)
        
        # Marcar puntos de aplicación de fuerza
        self.ax.plot(talon_x, talon_y, 'go', markersize=8, alpha=0.7, label='Talón')
        self.ax.plot(punta_x, punta_y, 'bo', markersize=8, alpha=0.7, label='Punta')
        
        return x_interseccion, y_interseccion
    
    def update_plot(self):
        self.ax.clear()
        
        # Dibujar imagen de fondo primero
        self.dibujar_imagen_fondo()
        
        # Dibujar líneas de fuerza
        centro_x, altura_x = self.dibujar_lineas_fuerza()
        
        # Calcular trayectoria del ICR (devuelve coordenadas globales y locales)
        x_icr_global, y_icr_global, x_puntos_global, y_puntos_global, x_local, y_local = self.calcular_trayectoria_icr()
        
        # Dibujar trayectoria suavizada del ICR en NEGRO
        self.ax.plot(x_icr_global, y_icr_global, 'k-', linewidth=4, alpha=0.7, label='Trayectoria ICR')
        
        # Dibujar puntos originales modificados en NEGRO (los 15 puntos)
        self.ax.scatter(x_puntos_global, y_puntos_global, c='black', s=40, alpha=0.6, label='Puntos ICR')
        
        # Marcar origen del sistema local en ROJO
        self.ax.plot(self.origen_local_global[0], self.origen_local_global[1], 'ro', 
                    markersize=10, label='Origen Local')
        
        # Configurar el gráfico en coordenadas globales
        self.ax.set_xlim(-50, 350)
        self.ax.set_ylim(-50, 800)
        self.ax.set_xlabel('X (mm)', fontsize=14)
        self.ax.set_ylabel('Y (mm)', fontsize=14)
        
        # Título dinámico basado en la curvatura
        if self.rotacion < 40:
            titulo_curvatura = "Lineal"
        elif self.rotacion < 60:
            titulo_curvatura = "Original" 
        else:
            titulo_curvatura = "Circular"
            
        self.ax.set_title(f'Trayectoria del ICR - Curvatura: {titulo_curvatura}', fontsize=16, pad=20)
        self.ax.grid(True, alpha=0.3)
        
        # Poner la leyenda FUERA del gráfico a la derecha
        self.ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', borderaxespad=0., fontsize=13)
        
        self.ax.set_aspect('equal')
        
        # Ajustar el layout para acomodar la leyenda fuera del gráfico
        self.fig.tight_layout()
        self.canvas.draw()
    
    def reset_parameters(self):
        self.estabilidad_var.set(50)
        self.movilidad_var.set(50)
        self.rotacion_var.set(50)
        self.on_parameter_change()
    
    def guardar_configuracion(self):
        # Calcular los puntos actuales (sin suavizar)
        x_icr_global, y_icr_global, x_puntos_global, y_puntos_global, x_local, y_local = self.calcular_trayectoria_icr()
        
        print("=" * 60)
        print("CONFIGURACIÓN GUARDADA")
        print("=" * 60)
        print(f"Parámetros de diseño:")
        print(f"  • Estabilidad: {self.estabilidad}%")
        print(f"  • Movilidad: {self.movilidad}%")
        print(f"  • Curvatura: {self.rotacion}%")
        print(f"  • Origen Sistema Local: {self.origen_local_global}")
        print()
        print("NUEVAS COORDENADAS LOCALES (15 puntos de referencia):")
        print("-" * 50)
        
        # Guardar los 15 puntos modificados en coordenadas LOCALES
        for i in range(len(x_local)):
            print(f"Punto {i+1:2d}: ({x_local[i]:8.2f}, {y_local[i]:8.2f})")
        
        print()
        print("COORDENADAS LOCALES PARA COPIAR:")
        print("x_icr_modificado = [", end="")
        for i, x in enumerate(x_local+14.4):
            print(f"{x:.6f}", end=", " if i < len(x_local)-1 else "")
        print("]")
        
        print("y_icr_modificado = [", end="")
        for i, y in enumerate(y_local+43.4):
            print(f"{y:.6f}", end=", " if i < len(y_local)-1 else "")
        print("]")
        
        print("=" * 60)

        x_icr_deseado = x_local + 14.4
        y_icr_deseado = y_local + 43.4

        result_name = f"knee_gui_E{self.estabilidad}_M{self.movilidad}_C{self.rotacion}"

        run_pipeline_from_icr(x_icr_deseado, y_icr_deseado, result_name=result_name)

if __name__ == "__main__":
    root = tk.Tk()
    app = RodillaInterface(root)
    root.mainloop()