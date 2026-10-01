defmodule Programa do
  @moduledoc """
  Programa principal del sistema de liquidación de recolectores.

  Coordina el flujo completo: carga los datos, permite ingresar un pesaje
  adicional por consola, separa los pesajes válidos de los rechazados, calcula
  las liquidaciones, imprime los reportes y muestra el desprendible de pago de
  un recolector.

  El programa se inicia con la llamada `Programa.main()` ubicada al final del
  archivo.

  - autor: juan manuel castaño buitrago,christian david lopera ,samuel mejia guerrero
  - fecha: Octubre del 2026
  """

  @doc """
  Punto de entrada del programa. Ejecuta el flujo completo en este orden:

  1. Carga los recolectores, lotes y pesajes desde `Datos`.
  2. Solicita por consola un pesaje adicional con el formato
     `recolector;lote;dia;kilos;verdes`.
     Si se presiona Enter sin escribir nada, se omite.
  3. Valida todos los pesajes con `Validacion.validar_pesaje/3` y los separa en
     válidos y rechazados. Cada rechazado se guarda junto con su motivo.
  4. Calcula las liquidaciones con `Liquidacion.liquidar_todos/2`, usando solo
     los pesajes válidos.
  5. Imprime  reportes principales .
  6. Imprime las pruebas del componente C.1 (`Reportes.ranking/2` con tres
     combinaciones de opciones) y del componente C.2
     (`Reportes.combinar_fincas/2` con los datos de una finca vecina).
  7. Solicita el código de un recolector e imprime su desprendible de pago.
  """
  def main do
    recolectores = Datos.recolectores()
    lotes = Datos.lotes()
    pesajes = Datos.pesajes()

    linea =
      Util.leer(
        "Ingrese un pesaje adicional (recolector;lote;dia;kilos;verdes) o Enter para omitir: "
      )

    pesajes_totales = procesar_linea(linea, pesajes, recolectores, lotes)

    # Separamos los pesajes en válidos y rechazados (estos últimos con su motivo)
    {pesajes_validos, pesajes_rechazados} =
      Enum.reduce(pesajes_totales, {[], []}, fn pesaje, {validos, rechazados} ->
        case Validacion.validar_pesaje(pesaje, recolectores, lotes) do
          {:ok, valido} -> {validos ++ [valido], rechazados}
          {:error, motivo} -> {validos, rechazados ++ [{motivo, pesaje}]}
        end
      end)

    liquidaciones = Liquidacion.liquidar_todos(recolectores, pesajes_validos)

    # Reportes principales
    Util.imprimir_mensaje("\n" <> Reportes.r1_rechazos(pesajes_rechazados))
    Util.imprimir_mensaje("\n" <> Reportes.r2_lotes(lotes, pesajes_validos))
    Util.imprimir_mensaje("\n" <> Reportes.r3_dias(pesajes_validos))
    Util.imprimir_mensaje("\n" <> Reportes.r4_liquidaciones(liquidaciones))
    Util.imprimir_mensaje("\n" <> Reportes.r5_mejores_dias(recolectores, pesajes_validos))
    Util.imprimir_mensaje("\n" <> Reportes.r6_mejor_calidad(recolectores, pesajes_validos))
    Util.imprimir_mensaje("\n" <> Reportes.r7_totales(liquidaciones))

    Util.imprimir_mensaje(
      "\n" <> Reportes.r8_todos_los_lotes(recolectores, lotes, pesajes_validos)
    )

    # Componente C.1: pruebas de la función ranking con distintas opciones
    Util.imprimir_mensaje("\n--- COMPONENTE C.1: Pruebas de ranking ---")

    Util.imprimir_mensaje("\nPrueba 1: Reportes.ranking(liquidaciones, [])")
    Util.imprimir_mensaje(inspect(Reportes.ranking(liquidaciones, []), pretty: true))

    Util.imprimir_mensaje("\nPrueba 2: Reportes.ranking(liquidaciones, campo: :kilos, limite: 3)")

    Util.imprimir_mensaje(
      inspect(Reportes.ranking(liquidaciones, campo: :kilos, limite: 3), pretty: true)
    )

    Util.imprimir_mensaje(
      "\nPrueba 3: Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto)"
    )

    Util.imprimir_mensaje(
      inspect(Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto), pretty: true)
    )

    # Componente C.2: combinar los kilos por día de esta finca con los de una finca vecina
    Util.imprimir_mensaje("\n--- COMPONENTE C.2: Combinar Fincas ---")
    mapa_finca = Reportes.mapa_kilos_por_dia(pesajes_validos)
    finca_vecina = %{1 => 520.5, 2 => 610, 3 => 480, 5 => 700, 7 => 300}

    mapa_combinado = Reportes.combinar_fincas(mapa_finca, finca_vecina)
    Util.imprimir_mensaje(inspect(mapa_combinado, pretty: true))
    # ------------------------------------------

    # Desprendible de pago del recolector elegido por el usuario
    codigo_rec = Util.leer("\nIngrese el código del recolector para ver su desprendible: ")
    imprimir_desprendible(codigo_rec, recolectores, liquidaciones)
  end

  # Procesa la línea escrita por el usuario y retorna la lista de pesajes
  # resultante.
  #
  # - Línea vacía: no agrega nada y retorna los pesajes sin cambios.
  # - Línea con formato `recolector;lote;dia;kilos;verdes`: convierte los
  #   campos numéricos, valida el pesaje y, si es válido, lo agrega al final de
  #   la lista. Si no es válido, imprime el motivo del rechazo y deja la lista
  #   igual.
  defp procesar_linea("", pesajes, _recolectores, _lotes), do: pesajes

  defp procesar_linea(linea, pesajes, recolectores, lotes) do
    partes = String.split(linea, ";") |> Enum.map(&String.trim/1)

    if length(partes) == 5 do
      [rec, lote, dia_str, kilos_str, verdes_str] = partes

      resultado =
        with {:ok, dia} <- parse_entero(dia_str),
             {:ok, kilos} <- parse_numero(kilos_str),
             {:ok, verdes} <- parse_numero(verdes_str) do
          pesaje = %{recolector: rec, lote: lote, dia: dia, kilos: kilos, verdes: verdes}

          case Validacion.validar_pesaje(pesaje, recolectores, lotes) do
            {:ok, p} ->
              Util.imprimir_mensaje(
                "Pesaje agregado: #{p.recolector} en #{p.lote}, día #{p.dia}, #{p.kilos} kg, #{p.verdes}% de verdes."
              )

              {:ok, p}

            {:error, motivo} ->
              Util.imprimir_mensaje("Pesaje rechazado: #{motivo}")
              {:error, motivo}
          end
        else
          _ ->
            Util.imprimir_mensaje("Pesaje rechazado: formato_invalido")
            {:error, :formato_invalido}
        end

      case resultado do
        {:ok, nuevo_pesaje} -> pesajes ++ [nuevo_pesaje]
        _ -> pesajes
      end
    else
      Util.imprimir_mensaje("Pesaje rechazado: formato_invalido")
      pesajes
    end
  end

  # Convierte un texto en un número entero.
  # Retorna `{:ok, numero}` si todo el texto es un entero ,
  # o `{:error, :invalido}` si no lo es.
  defp parse_entero(str) do
    case Integer.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> {:error, :invalido}
    end
  end

  # Convierte un texto en un número decimal.
  # Acepta decimales ("80.5") y enteros ("80"); estos últimos se convierten a
  # decimal. Retorna `{:ok, numero}` o `{:error, :invalido}`.
  defp parse_numero(str) do
    case Float.parse(str) do
      {num, ""} ->
        {:ok, num}

      _ ->
        case Integer.parse(str) do
          {num, ""} -> {:ok, num * 1.0}
          _ -> {:error, :invalido}
        end
    end
  end

  # Imprime el desprendible de pago del recolector con el código indicado:
  # su nombre, el detalle de cada día, la suma de pesajes, las bonificaciones,
  # el descuento por alimentación y el neto a pagar.
  # Si el código no corresponde a ningún recolector, imprime un aviso.
  defp imprimir_desprendible(codigo, recolectores, liquidaciones) do
    recolector_existe = Enum.find(recolectores, fn r -> r.codigo == codigo end)

    if recolector_existe do
      liq = Enum.find(liquidaciones, fn l -> l.recolector.codigo == codigo end)

      Util.imprimir_mensaje(
        "Desprendible de pago\n#{liq.recolector.nombre} (#{liq.recolector.codigo})"
      )

      Enum.each(liq.detalle_diario, fn d ->
        Util.imprimir_mensaje(
          "Día #{d.dia}: #{d.kilos} kg pesajes $#{Util.formatear_dinero(d.valor)} bonificación $#{Util.formatear_dinero(d.bonificacion)}"
        )
      end)

      Util.imprimir_mensaje("Suma de pesajes: $#{Util.formatear_dinero(liq.suma_pesajes)}")
      Util.imprimir_mensaje("Bonificaciones: $#{Util.formatear_dinero(liq.total_bonos)}")

      Util.imprimir_mensaje(
        "Alimentación (#{liq.dias_trabajados} días): -$#{Util.formatear_dinero(liq.descuento)}"
      )

      Util.imprimir_mensaje("Neto a pagar: $#{Util.formatear_dinero(liq.neto)}")
    else
      Util.imprimir_mensaje("No existe un recolector con el código #{codigo}.")
    end
  end
end

# Invoca la función principal para ejecutar el programa
Programa.main()
