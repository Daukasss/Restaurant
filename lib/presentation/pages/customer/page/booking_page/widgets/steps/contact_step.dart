part of '../../view/booking_page.dart';

// ─────────────────────────────────────────────
//  ШАГ 3 — ЛИЧНЫЕ ДАННЫЕ (гости · имя · телефон)
// ─────────────────────────────────────────────
class _ContactStep extends StatelessWidget {
  final TextEditingController guestsController;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const _ContactStep({
    required this.guestsController,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BookingBloc>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Количество гостей
        TextFormField(
          controller: guestsController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 15, color: _textMain),
          decoration: _bookingInputDecoration(
            label: 'Количество гостей',
            hint: 'Введите количество',
            icon: Icons.people_alt_outlined,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Введите количество гостей';
            if ((int.tryParse(v) ?? 0) <= 0) return 'Введите корректное число';
            return null;
          },
          onChanged: (v) => bloc.add(UpdateGuestsEvent(v)),
        ),
        const SizedBox(height: 14),
        // Имя
        TextFormField(
          controller: nameController,
          style: const TextStyle(fontSize: 15, color: _textMain),
          decoration: _bookingInputDecoration(
            label: 'Имя',
            hint: 'Введите ваше имя',
            icon: Icons.person_outline_rounded,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Введите ваше имя' : null,
          onChanged: (v) => bloc.add(UpdateNameEvent(v)),
        ),
        const SizedBox(height: 14),
        // Телефон
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 15, color: _textMain),
          decoration: _bookingInputDecoration(
            label: 'Телефон',
            hint: '+7 (___) ___-__-__',
            icon: Icons.phone_outlined,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Введите номер телефона' : null,
          onChanged: (v) => bloc.add(UpdatePhoneEvent(v)),
        ),
      ],
    );
  }
}
